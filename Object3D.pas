unit Object3D;

interface

uses sysutils,Windows,graphics,Base3DTypes,Mat4x4,RenderContext,Polygon;

type

// Object render options
TObject3DOptions = (opDefault,opNoBackfaceCulling,opWireFrame,opOrthogonal,opNoLight);

TObject3DOptionsSet = set of TObject3DOptions;

// Exception class for TObject3D
EObject3D = class(Exception);

// 3D object class
TObject3D = class(TObject)
  private
    // Vertex table
    VertexTable : array of TVertex;

    // Number of vertices in the vertex table
    VertexNum : integer;

    // Faces table
    FaceTable : array of TFace3D;

    // Number of faces in the faces table
    FaceNum : integer;

    RefPoint : TVertex;

    ObjectMat : TMat4X4;
    CombinedMatrix : TMat4X4;

    // Current rendering context
    FCurrentContext : TRenderContext;

    // Current options set
    FOptions : TObject3DOptionsSet;

    // Array of child objects and their axes
    Children : array of TObject3D;
    ChildrenAxes : array of TVertex;
    ChildrenNum : integer;

    // Pointer to my father object
    Father : TObject3D;

    OriginalAxisPointA,OriginalAxisPointB : TVertex;
    TransformedAxisPointA,TransformedAxisPointB : TVertex;

    // Help function for converting a string with the format = (x,y,z) to a vertex type
    function ConvertCoordString(CoordStr : string) : TVertex;
    function ConvertFaceString(CoordStr : string) : TFace3D;

    // Verify faces indices against the vertex table
    procedure VerifyFaces;

    // Get the combined transformation matrix of the object
    function GetTransformMatrix(Context : TRenderContext) : TMat4X4;

    procedure DrawWireFramePolygon(Context : TRenderContext; FS : TTrianglePoints; Color : TRGBPixel;
                                   ScreenHalfWidth,ScreenHalfHeight : integer);

    procedure CalculatePolygonFactors(Normal,PointOnPlane : TVertex; PerspFactor : TBasicFloat; var M,N,K : TBasicFloat);

    function TestForBackClipping(V1,V2,V3 : TVertex) : boolean;

    procedure TransformAxis(Mat : TMat4x4);

  public
    // Empty object constructor
    constructor Create; overload;

    // Create an object an load from3D file
    constructor Create(FileName : string); overload;

    // Destructor
    destructor Destroy; override;

    // Load the object with data from a 3D file
    procedure LoadFromFile(FileName : string);

    // Assign data from a 3D object to myself
    procedure Assign(ObjToClone: TObject3D);

    procedure SetNewFacesColor(NewColor : TColor);

    // Perform rendering on a specific context
    procedure Render(Context : TRenderContext);

    // Set a new object matrix
    procedure SetMatrix(Mat : TMat4X4);

    // Get the current object matrix
    function GetMatrix : TMat4X4;

    // Get father matrix
    function GetFatherMatrix : TMat4X4;

    property Options : TObject3DOptionsSet read FOptions write FOptions;

    procedure AddChildObject(ChildObj : TObject3D; AxisPointA,AxisPointB : TVertex); overload;

    procedure RenderChildObjects(Context : TRenderContext);

    procedure RotateOnAxis(Angle : TBasicFloat);
end;

implementation

{ TObject3D }

uses IniFiles,classes;

const
  OBJECT_3D_FILE_SIGNATURE = '3D File Format';
  POLYGON_COORD_MAX_VALUE = 1000;
  POLYGON_Z_MIN_VALUE = 0.001;

// Empty object constructor
constructor TObject3D.Create;
var
  M : TMat4x4;
begin
  SetUnitMat(M);
  SetMatrix(M);
  FOptions := [opDefault];
  ChildrenNum := 0;
  Father := nil;
end;

// Create an object an load from3D file
constructor TObject3D.Create(FileName: string);
var
  M : TMat4x4;
begin
  SetUnitMat(M);
  SetMatrix(M);
  ChildrenNum := 0;
  LoadFromFile(FileName);
  FOptions := [opDefault];
  Father := nil;  
end;

destructor TObject3D.Destroy;
begin
  // Free dynamic arrays
  VertexTable := nil;
  FaceTable := nil;
  Children := nil;
  ChildrenAxes := nil;

  inherited;
end;

function TObject3D.ConvertCoordString(CoordStr : string) : TVertex;
var
  Num : TBasicFloat;
  StrNum:string;
begin
  delete(CoordStr,1,pos('=',CoordStr));

  if CoordStr <> '' then
   begin
    StrNum := copy (CoordStr,1, pos(',',CoordStr) - 1);
    delete(CoordStr,1,pos(',',CoordStr));

    Num := StrToFloat(StrNum);
    Result.X := Num;
   end;

  if CoordStr <> '' then
   begin
    StrNum := copy (CoordStr,1, pos(',',CoordStr) - 1);
    delete(CoordStr,1,pos(',',CoordStr));

    Num := StrToFloat(StrNum);
    Result.Y := Num;
   end;

  if CoordStr <>'' then
   begin
    Num := StrToFloat(CoordStr);
    Result.Z := Num;
   end;
end;

// Load the object with data from a 3D file
procedure TObject3D.LoadFromFile(FileName: string);
var
  IniFile : TIniFile;
  StrList : TStringList;
  i, k : integer;
  //StartPos : integer;
begin
  StrList := TStringList.Create;
  StrList.LoadFromFile(FileName);

  IniFile := TIniFile.Create(FileName);

  try
    // Check the file signature
    if IniFile.ReadString('Header','Signature','') <> OBJECT_3D_FILE_SIGNATURE then
      raise EObject3D.Create('Bad 3D file signature');

    // Read the file header
    RefPoint := ConvertCoordString(IniFile.ReadString('Header','RefPoint','0,0,0'));
    VertexNum := IniFile.ReadInteger('Header','VertexNum',0);
    FaceNum := IniFile.ReadInteger('Header','FaceNum',0);

    // Allocate the vertex and faces tables
    SetLength(VertexTable,VertexNum);
    SetLength(FaceTable,FaceNum);

    // Find the location of the vertex table start
    for i := 0 to StrList.Count - 1 do
      if StrList[i] = '[Vertex]' then
        break;

    //The index in the StrList array of the first vertex
    k:= i+1;

    // Read all vertices
    for i := 0 to VertexNum - 1 do
      VertexTable[i] := ConvertCoordString( StrList[k+i] );{IniFile.ReadString('Vertex','V' + IntToStr(i),'')}

    //Find the index in StrList of the string '[Vertex]'
    k:= k + VertexNum;

    // Find the location of the faces table start
    for i := k to StrList.Count - 1 do
      if StrList[i] = '[Faces]' then
        break;

    //The index in the StrList array of the first face
    k:= i+1;

    // Read all faces
    for i := 0 to FaceNum - 1 do
      FaceTable[i] := ConvertFaceString( StrList[k+i] );{(IniFile.ReadString('Faces','F' + IntToStr(i),'')};

    // Check that everything if Ok with the faces
    VerifyFaces;

  finally
    IniFile.Free;
    StrList.Free;
  end;
end;

procedure TObject3D.Assign(ObjToClone: TObject3D);
var
  i : integer;
begin
  RefPoint := ObjToClone.RefPoint;
  VertexNum := ObjToClone.VertexNum;
  FaceNum := ObjToClone.FaceNum;

  SetLength(VertexTable,VertexNum);
  SetLength(FaceTable,FaceNum);

  for i := 0 to VertexNum - 1 do
    VertexTable[i] := ObjToClone.VertexTable[i];

  for i := 0 to FaceNum - 1 do
    FaceTable[i] := ObjToClone.FaceTable[i];
end;

function TObject3D.ConvertFaceString(CoordStr: string): TFace3D;
var
  StrNum:string;
  RGBColor : TColor;
begin
  delete(CoordStr,1,pos('=',CoordStr));

  if CoordStr <> '' then
   begin
    StrNum := copy (CoordStr,1, pos(',',CoordStr) - 1);
    delete(CoordStr,1,pos(',',CoordStr));

    Result.AIndex := StrToInt(StrNum);
   end;

  if CoordStr <> '' then
   begin
    StrNum := copy (CoordStr,1, pos(',',CoordStr) - 1);
    delete(CoordStr,1,pos(',',CoordStr));

    Result.BIndex := StrToInt(StrNum);
   end;

  if CoordStr <>'' then
  begin
    StrNum := copy (CoordStr,1, pos(',',CoordStr) - 1);
    delete(CoordStr,1,pos(',',CoordStr));

    Result.CIndex := StrToInt(StrNum);
  end;

  if CoordStr <>'' then
  begin
    StrNum := copy (CoordStr,1, pos(',',CoordStr) - 1);
    delete(CoordStr,1,pos(',',CoordStr));

    Result.Normal.X := StrToFloat(StrNum);
  end;

  if CoordStr <>'' then
  begin
    StrNum := copy (CoordStr,1, pos(',',CoordStr) - 1);
    delete(CoordStr,1,pos(',',CoordStr));

    Result.Normal.Y := StrToFloat(StrNum);
  end;

  if CoordStr <>'' then
  begin
    StrNum := copy (CoordStr,1, pos(',',CoordStr) - 1);
    delete(CoordStr,1,pos(',',CoordStr));

    Result.Normal.Z := StrToFloat(StrNum);
  end;

  if CoordStr <>'' then
  begin
    RGBColor := TColor(StrToInt(CoordStr));

    Result.Color.R := GetRValue(RGBColor);
    Result.Color.G := GetGValue(RGBColor);
    Result.Color.B := GetBValue(RGBColor);
  end;
end;

// Verify faces indices against the vertex table
procedure TObject3D.VerifyFaces;
var
  i : integer;
begin
  for i := 0 to FaceNum - 1 do
    with FaceTable[i] do
    begin
      if (AIndex < 0) or (AIndex >= VertexNum) then
        raise EObject3D.Create('Invalid AIndex value in face ' + IntToStr(i));

      if (BIndex < 0) or (BIndex >= VertexNum) then
        raise EObject3D.Create('Invalid BIndex value in face ' + IntToStr(i));

      if (CIndex < 0) or (CIndex >= VertexNum) then
        raise EObject3D.Create('Invalid CIndex value in face ' + IntToStr(i));
    end;
end;

// Perform rendering on a specific context
procedure TObject3D.Render(Context : TRenderContext);
var
  i,j : integer;
  Mat : TMat4x4;
  Temp1 : TBasicFloat;

  InverseMat : TMat4x4;
  ViewDirection : TVertex;
  ViewerPosInObjCoords : TVertex;

  // Current face vertices
  {FV1,FV2,FV3 : TVertex;}
  FV :array[0..2] of TVertex;

  // Current face transformed vertices
  {FT1,FT2,FT3 : TVertex;}
  FT :array[0..2] of TVertex;

  // 2D polygon screen coordinates
  {FS1,FS2,FS3 : TPoint;}
  FS : TTrianglePoints;

  M,N,K : TBasicFloat;
  PerspectiveFactor : TBasicFloat;

  FaceNormal : TVertex;

  ScreenHalfWidth,ScreenHalfHeight : integer;

  FaceVisible,PolygonTooClose : boolean;

  FaceColor : TRGBPixel;
begin
  FCurrentContext := Context;

  // Calculate transform matrix
  Mat := GetTransformMatrix(Context);

  // Calculate the inverse matrix
  InverseMat := FindInverseMat(Mat);

  // Clear translation effect
  InverseMat[4,1] := 0.0;
  InverseMat[4,2] := 0.0;
  InverseMat[4,3] := 0.0;

  // Calculate the viewer position in object coordinates
  ViewDirection := Context.GetViewDirection;
  MulMatWithPoint3D(ViewDirection,ViewerPosInObjCoords,InverseMat);

  PerspectiveFactor := Context.GetPerspectiveFactor;

  ScreenHalfWidth := Context.Width div 2;
  ScreenHalfHeight := Context.Height div 2;

  // Process each face
  for i := 0 to FaceNum - 1 do
  begin
    if opNoBackfaceCulling in FOptions then
      FaceVisible := true
    else
      begin
        // Do backface culling
        Temp1 := DotProduct(ViewerPosInObjCoords,FaceTable[i].Normal);

        // Perspective mode
        if not(opOrthogonal in FOptions) then
          // Remember if the face is visible
          FaceVisible := (Temp1 > -0.4)
        else
          FaceVisible := (Temp1 > 0);
      end;

    if FaceVisible then
    begin
      // Get current face vertices
      FV[0] := VertexTable[FaceTable[i].AIndex];
      FV[1] := VertexTable[FaceTable[i].BIndex];
      FV[2] := VertexTable[FaceTable[i].CIndex];

      // Transform the face to world coordinates
      for j:=0 to 2 do
        MulMatWithPoint3D(FV[j],FT[j],Mat);

      if TestForBackClipping(FT[0],FT[1],FT[2]) then
      begin
        // Perspective mode
        if not(opOrthogonal in FOptions) then
        begin
          PolygonTooClose := false;

          // Transform the from world coordinates to screen coordinates
          for j:= 0 to 2 do
          begin
            if abs(FT[j].Z) < POLYGON_Z_MIN_VALUE then
            begin
              PolygonTooClose := true;
              break;
            end;

            FS[j].X := Trunc(FT[j].X * PerspectiveFactor / FT[j].Z);
            FS[j].Y := Trunc(FT[j].Y * PerspectiveFactor / FT[j].Z);

            if (abs(FS[j].X) > POLYGON_COORD_MAX_VALUE) or (abs(FS[j].Y) > POLYGON_COORD_MAX_VALUE) then
            begin
              PolygonTooClose := true;
              break;
            end
          end
        end
        else
          // Transform the from world coordinates to screen coordinates
          for j:= 0 to 2 do
          begin
            PolygonTooClose := false;

            FS[j].X := Trunc(FT[j].X /0.6);
            FS[j].Y := Trunc(FT[j].Y /0.6);
          end;

        if not PolygonTooClose then
        begin
          if opWireFrame in FOptions then
            DrawWireFramePolygon(Context,FS,FaceTable[i].Color,ScreenHalfWidth,ScreenHalfHeight)
          else
            begin
              if not(opNoLight in FOptions) then
                begin
                  Temp1 := Temp1 + 0.4;

                  if Temp1 > 1.0 then
                    Temp1 := 1.0;

                  // Calculate face color
                  FaceColor.R := TRunc(FaceTable[i].Color.R * Temp1);
                  FaceColor.G := TRunc(FaceTable[i].Color.G * Temp1);
                  FaceColor.B := TRunc(FaceTable[i].Color.B * Temp1);
                end else
                  FaceColor := FaceTable[i].Color;

              // Calculate factors for the polygon filling routine
              FaceNormal := CalcFaceNormal(FT[0],FT[1],FT[2]);

              CalculatePolygonFactors(FaceNormal,FT[1],PerspectiveFactor,M,N,K);
              DrawFilledTriangle(FS,Context,FaceColor,M,N,K);
            end;
          end;
        end;
      end;
  end;

  RenderChildObjects(Context);
end;

function TObject3D.GetTransformMatrix(Context: TRenderContext): TMat4X4;
var
  ViewMat : TMat4x4;
begin
  ViewMat := Context.GetViewMat;
  MulMat(CombinedMatrix,ViewMat,Result);
end;

procedure TObject3D.DrawWireFramePolygon(Context : TRenderContext; FS : TTrianglePoints; Color : TRGBPixel;
                                         ScreenHalfWidth,ScreenHalfHeight : integer);
var
  WorkCanvas : TCanvas;
begin
  WorkCanvas := Context.GetVScreenCanvas;

  WorkCanvas.Pen.Color := RGB(Color.R,Color.G,Color.B);

  WorkCanvas.MoveTo(FS[0].X + ScreenHalfWidth,ScreenHalfHeight - FS[0].Y);
  WorkCanvas.LineTo(FS[1].X + ScreenHalfWidth,ScreenHalfHeight - FS[1].Y);
  WorkCanvas.LineTo(FS[2].X + ScreenHalfWidth,ScreenHalfHeight - FS[2].Y);
  WorkCanvas.LineTo(FS[0].X + ScreenHalfWidth,ScreenHalfHeight - FS[0].Y);
end;

// Set a new object matrix
procedure TObject3D.SetMatrix(Mat : TMat4X4);
var
  FatherMat : TMat4x4;
  i : integer;
begin
  ObjectMat := Mat;

  // Transform myself
  FatherMat := GetFatherMatrix;
  MulMat(ObjectMat,FatherMat,CombinedMatrix);

  TransformAxis(ObjectMat);//FatherMat);

  // Transform all child objects
  if ChildrenNum > 0 then
    for i := 0 to ChildrenNum - 1 do
      Children[i].SetMatrix(Children[i].GetMatrix);
end;

procedure TObject3D.CalculatePolygonFactors(Normal, PointOnPlane: TVertex; PerspFactor : TBasicFloat;
  var M, N, K: TBasicFloat);
var
  A,B,C,D : TBasicFloat;
begin
  A := Normal.X;
  B := Normal.Y;
  C := Normal.Z;
  D := DotProduct(Normal,PointOnPlane);

  {
  if C <> 0 then
    begin
      z := (D - A * PointOnPlane.X - B * PointOnPlane.Y) / C;
      Writeln(z:5:2);
    end else
      Writeln('C = 0');

}

  if D <> 0 then
  begin
    M := A / (D * PerspFactor);
    N := B / (D * PerspFactor);
    K := C / D;
  end else
    begin
      M := 0;
      N := 0;
      K := 0;
    end;
end;

function TObject3D.TestForBackClipping(V1, V2, V3: TVertex): boolean;
begin
  Result := (V1.Z > 0) and (V2.Z > 0) and (V3.Z > 0);
  Result := not Result;
end;

procedure TObject3D.AddChildObject(ChildObj: TObject3D; AxisPointA,AxisPointB : TVertex);
begin
  Inc(ChildrenNum);

  SetLength(Children,ChildrenNum);
  SetLength(ChildrenAxes,ChildrenNum);

  Children[ChildrenNum - 1] := ChildObj;

  with ChildObj do
  begin
    Father := Self;
    OriginalAxisPointA    := AxisPointA;
    OriginalAxisPointB    := AxisPointB;
    TransformedAxisPointA := AxisPointA;
    TransformedAxisPointB := AxisPointB;
  end;
end;

procedure TObject3D.RenderChildObjects(Context: TRenderContext);
var
  i : integer;
begin
  if ChildrenNum > 0 then
    for i := 0 to ChildrenNum - 1 do
      Children[i].Render(Context);
end;

function TObject3D.GetMatrix : TMat4X4;
begin
  Result := ObjectMat;
end;

function TObject3D.GetFatherMatrix: TMat4X4;
begin
  if Father <> nil then
    Result := Father.CombinedMatrix
  else
    SetUnitMat(Result);
end;

procedure TObject3D.TransformAxis(Mat: TMat4x4);
begin
  MulMatWithPoint3D(OriginalAxisPointA,TransformedAxisPointA,Mat);
  MulMatWithPoint3D(OriginalAxisPointB,TransformedAxisPointB,Mat);
end;

procedure TObject3D.RotateOnAxis(Angle: TBasicFloat);
var
  ArbitraryMat : TMat4x4;
begin
  SetArbitraryRotMat(ArbitraryMat,TransformedAxisPointA,TransformedAxisPointB,Angle);
  SetMatrix(ArbitraryMat);
end;

procedure TObject3D.SetNewFacesColor(NewColor: TColor);
var
  i : integer;
begin
  for i := 0 to FaceNum - 1 do
    with FaceTable[i] do
    begin
      Color.R := GetRValue(NewColor);
      Color.G := GetGValue(NewColor);
      Color.B := GetBValue(NewColor);
    end;
end;

end.
