unit Mat4x4;

interface

uses Base3DTypes;

type
  T3DCoordType = TBasicFloat;

  {Basic 4x4 matrix type}
  TMat4X4 = array[1..4,1..4] of T3DCoordType;

{4x4 matrix operations
 *************************************************************}

{Find inverse matrix to Mat}
function FindInverseMat( var Mat : TMat4x4) : TMat4x4;

// The translation for the InverseMat of Mat
procedure TransposeInverseMat(var Mat,InverseMat : TMat4x4);

{Set each element to value}
procedure SetMat(var M : TMat4X4; Value : T3DCoordType);

{Set to unit matrix}
procedure SetUnitMat(var M : TMat4X4);

{Set translation matrix}
procedure SetTrans(var M : TMat4X4; X,Y,Z : T3DCoordType);

{Set inverse translation matrix}
procedure SetInverseTrans(var M : TMat4X4; X,Y,Z : T3DCoordType);

{Set rotation matrix around the X axis}
procedure SetRotationMatX(var M : TMat4X4; XAngle : TBasicFloat);

{Set inverse rotation matrix around the X axis}
procedure SetInverseRotationMatX(var M : TMat4X4; XAngle : TBasicFloat);

{Set rotation matrix around the Y axis}
procedure SetRotationMatY(var M : TMat4X4; YAngle : TBasicFloat);

{Set inverse rotation matrix around the Y axis}
procedure SetInverseRotationMatY(var M : TMat4X4; YAngle : TBasicFloat);

{Set rotation matrix around the Z axis}
procedure SetRotationMatZ(var M : TMat4X4; ZAngle : TBasicFloat);

{Set inverse rotation matrix around the Z axis}
procedure SetInverseRotationMatZ(var M : TMat4X4; ZAngle : TBasicFloat);

{Set inverse rotation matrix around the X,Y,Z axis}
procedure SetInverseRotationMat(var M : TMat4X4; Angle : TBasicFloat);

{Set scaling matrix}
procedure SetScaleMat(var M : TMat4X4; SX,SY,SZ : TBasicFloat);

{Set inverse scaling matrix}
procedure SetInverseScaleMat(var M : TMat4X4; SX,SY,SZ : TBasicFloat);

{Set XY mirror matrix}
procedure SetXYMirrorMat(var M : TMat4X4);

{Set XZ mirror matrix}
procedure SetXZMirrorMat(var M : TMat4X4);

{Set YZ mirror matrix}
procedure SetYZMirrorMat(var M : TMat4X4);

{Set rotation matrix around arbitrary axis}
procedure SetArbitraryRotMat(var M : TMat4X4; P1,P2 : TVertex; Angle : TBasicFloat);

{Transpose matrix}
function TransposeMat(var M : TMat4X4): TMat4x4;

{Matrix addition}
procedure AddMat(var M1,M2,R : TMat4X4);

{Matrix subtraction}
procedure SubMat(var M1,M2,R : TMat4X4);

{Matrix negation M = -M}
procedure NegMat(var M : TMat4X4);

{Matrix multiplication}
procedure MulMat(var M1,M2,R : TMat4X4);

{Multiply with a scalar value}
procedure MulMatScalar( M : TMat4X4; Scalar : T3DCoordType;  var R: TMat4X4);

{Multiply a 3D point with a 4X4 matrix}
procedure MulMatWithPoint3D(P : TVertex; var R : TVertex; var M : TMat4X4);

{Point3D vector operations
 *************************************************************}

function DotProduct(P1,P2 : TVertex) : TBasicFloat;

procedure CrossProduct(P1,P2 : TVertex; var P3 : TVertex);

{The distance from point P1 to P2 }
function PointDistance(P1,P2 : TVertex) : TBasicFloat;

procedure SetUnitPoint(var P : TVertex);

{Result = normalized  vector P  }
procedure CalcNormalizedVec(p1,p2 : TVertex; var Result : TVertex);
function NormalizeVertex(p : TVertex) : TVertex;

function Deg2Rad(D : TBasicFloat) : TBasicFloat;
function Rad2Deg(R : TBasicFloat) : TBasicFloat;

function ArcSin(X : TBasicFloat) : TBasicFloat;
function ArcCos(X : TBasicFloat) : TBasicFloat;

function SimpleRound(X : TBasicFloat) : integer;

function CalcFaceNormal(p1,p2,p3 : TVertex) : TVertex;

function RandomRange(A, B: integer) : integer;

function IsPointInRect(var Rect : T2DRect; X,Y : TBasicFloat) : boolean;

function IsRectsIntersect(var R1,R2 : T2DRect) : boolean;

IMPLEMENTATION  {%%%%%%%%%%%%%%%%%%%%%%%%%}


function FindInverseMat( var Mat : TMat4x4) : TMat4x4;
var
  i,j:integer;
  C : TMat4x4;
  Det: TBasicFloat;
begin

  C[1,1]:=   Mat[2,2]*(Mat[3,3]*Mat[4,4] - Mat[3,4]*Mat[4,3]) -
             Mat[2,3]*(Mat[3,2]*Mat[4,4] - Mat[3,4]*Mat[4,2]) +
             Mat[2,4]*(Mat[3,2]*Mat[4,3] - Mat[3,3]*Mat[4,2]);

  C[1,2]:=- (Mat[2,1]*(Mat[3,3]*Mat[4,4] - Mat[3,4]*Mat[4,3]) -
             Mat[2,3]*(Mat[3,1]*Mat[4,4] - Mat[3,4]*Mat[4,1]) +
             Mat[2,4]*(Mat[3,1]*Mat[4,3] - Mat[3,3]*Mat[4,1])) ;

  C[1,3]:=   Mat[2,1]*(Mat[3,2]*Mat[4,4] - Mat[3,4]*Mat[4,2]) -
             Mat[2,2]*(Mat[3,1]*Mat[4,4] - Mat[3,4]*Mat[4,1]) +
             Mat[2,4]*(Mat[3,1]*Mat[4,2] - Mat[3,2]*Mat[4,1]);

  C[1,4]:=0;
  C[2,1]:=- (Mat[1,2]*(Mat[3,3]*Mat[4,4] - Mat[3,4]*Mat[4,3]) -
             Mat[1,3]*(Mat[3,2]*Mat[4,4] - Mat[3,4]*Mat[4,2]) +
             Mat[1,4]*(Mat[3,2]*Mat[4,3] - Mat[3,3]*Mat[4,2]));

  C[2,2]:=   Mat[1,1]*(Mat[3,3]*Mat[4,4] - Mat[3,4]*Mat[4,3]) -
             Mat[1,3]*(Mat[3,1]*Mat[4,4] - Mat[3,4]*Mat[4,1]) +
             Mat[1,4]*(Mat[3,1]*Mat[4,3] - Mat[3,3]*Mat[4,1]);

  C[2,3]:=- (Mat[1,1]*(Mat[3,2]*Mat[4,4] - Mat[3,4]*Mat[4,2]) -
             Mat[1,2]*(Mat[3,1]*Mat[4,4] - Mat[3,4]*Mat[4,1]) +
             Mat[1,4]*(Mat[3,1]*Mat[4,2] - Mat[3,2]*Mat[4,1]));

  C[2,4]:=0;
  C[3,1]:=   Mat[1,2]*(Mat[2,3]*Mat[4,4] - Mat[2,4]*Mat[4,3]) -
             Mat[1,3]*(Mat[2,2]*Mat[4,4] - Mat[2,4]*Mat[4,2]) +
             Mat[1,4]*(Mat[2,2]*Mat[4,3] - Mat[2,3]*Mat[4,2]);

  C[3,2]:=- (Mat[1,1]*(Mat[2,3]*Mat[4,4] - Mat[2,4]*Mat[4,3]) -
             Mat[1,3]*(Mat[2,1]*Mat[4,4] - Mat[2,4]*Mat[4,1]) +
             Mat[1,4]*(Mat[2,1]*Mat[4,3] - Mat[2,3]*Mat[4,1]));

  C[3,3]:=   Mat[1,1]*(Mat[2,2]*Mat[4,4] - Mat[2,4]*Mat[4,2]) -
             Mat[1,2]*(Mat[2,1]*Mat[4,4] - Mat[2,4]*Mat[4,1]) +
             Mat[1,4]*(Mat[2,1]*Mat[4,2] - Mat[2,2]*Mat[4,1]);

  C[3,4]:=0;
  C[4,1]:=- (Mat[1,2]*(Mat[2,3]*Mat[3,4] - Mat[2,4]*Mat[3,3]) -
             Mat[1,3]*(Mat[2,2]*Mat[3,4] - Mat[2,4]*Mat[3,2]) +
             Mat[1,4]*(Mat[2,2]*Mat[3,3] - Mat[2,3]*Mat[3,2]));

  C[4,2]:=   Mat[1,1]*(Mat[2,3]*Mat[3,4] - Mat[2,4]*Mat[3,3]) -
             Mat[1,3]*(Mat[2,1]*Mat[3,4] - Mat[2,4]*Mat[3,1]) +
             Mat[1,4]*(Mat[2,1]*Mat[3,3] - Mat[2,3]*Mat[3,1]);

  C[4,3]:=- (Mat[1,1]*(Mat[2,2]*Mat[3,4] - Mat[2,4]*Mat[3,2]) -
             Mat[1,2]*(Mat[2,1]*Mat[3,4] - Mat[2,4]*Mat[3,1]) +
             Mat[1,4]*(Mat[2,1]*Mat[3,2] - Mat[2,2]*Mat[3,1]));

  C[4,4]:=   Mat[1,1]*(Mat[2,2]*Mat[3,3] - Mat[2,3]*Mat[3,2]) -
             Mat[1,2]*(Mat[2,1]*Mat[3,3] - Mat[2,3]*Mat[3,1]) +
             Mat[1,3]*(Mat[2,1]*Mat[3,2] - Mat[2,2]*Mat[3,1]);

  Det:=0;
  for i:= 1 to 3 do
    Det:= Det + Mat[1,i]*C[1,i] ;

  for i:= 1 to 3 do
    for j:= 1 to 3 do
      Result[i,j]:= C[j,i] / Det;

  Result[4,4]:=1;
  for i:= 1 to 3 do
  begin
    Result[i,4]:=0;

    Result[4,i]:=0;
    for j:= 1 to 3 do
      Result[4,i]:= Result[4,i] + Mat[4,j]*Result[j,i];

    Result[4,i]:= - Result[4,i];
  end;

end;


// The translation for the InverseMat of Mat
procedure TransposeInverseMat(var Mat,InverseMat : TMat4x4);
var
  i:integer;
begin
  for i:= 1 to 3 do
    InverseMat[4,i]:= -Mat[4,i]
end;

{Set each element to value}
procedure SetMat(var M : TMat4X4; Value : T3DCoordType) ;
var
  i,j : byte;
begin
  for i:=1 to 4 do
    for j:=1 to 4 do
      M[i,j]:= Value
end;

{Set to unit matrix}
procedure SetUnitMat(var M : TMat4X4);
var i:byte;
begin
    SetMat(M,0);   { M = 0 }
    for i:=1 to 4 do
      M[i,i]:=1    { The Left Diagonal = 1}
end;

{Set translation matrix}
procedure SetTrans(var M : TMat4X4; X,Y,Z : T3DCoordType);
begin
   SetUnitMat(M);
   M[4,1] := X;
   M[4,2] := Y;
   M[4,3] := Z;
end;

{Set inverse translation matrix}
procedure SetInverseTrans(var M : TMat4X4; X,Y,Z : T3DCoordType);
begin
   SetUnitMat(M);
   M[4,1] := -X;
   M[4,2] := -Y;
   M[4,3] := -Z;
end;

{Set rotation matrix around the X axis}
procedure SetRotationMatX(var M : TMat4X4; XAngle : TBasicFloat);
begin
    SetUnitMat(M);
    M[2,2] := cos(XAngle);
    M[3,3] := M[2,2];
    M[2,3] := sin(XAngle);
    M[3,2] := -M[2,3];
end;

{Set inverse rotation matrix around the X axis}
procedure SetInverseRotationMatX(var M : TMat4X4; XAngle : TBasicFloat);
begin
    SetUnitMat(M);
    M[2,2] := cos(XAngle);
    M[3,3] := M[2,2];
    M[3,2] := sin(XAngle);
    M[2,3] := -M[3,2];
end;

{Set rotation matrix around the Y axis}
procedure SetRotationMatY(var M : TMat4X4; YAngle : TBasicFloat);
begin
    SetUnitMat(M);
    M[1,1] := cos(YAngle);
    M[3,3] := M[1,1];
    M[3,1] := sin(YAngle);
    M[1,3] := -M[3,1];
 end;

{Set inverse rotation matrix around the Y axis}
procedure SetInverseRotationMatY(var M : TMat4X4; YAngle : TBasicFloat);
begin
    SetUnitMat(M);
    M[1,1] := cos(YAngle);
    M[3,3] := M[1,1];
    M[1,3] := sin(YAngle);
    M[3,1] := -M[1,3];
end;

{Set rotation matrix around the Z axis}
procedure SetRotationMatZ(var M : TMat4X4; ZAngle : TBasicFloat);
begin
  SetUnitMat(M);
  M[1,1] := cos(ZAngle);
  M[2,2] := M[1,1];
  M[1,2] := sin(ZAngle);
  M[2,1] := -M[1,2];
end;

{Set inverse rotation matrix around the Z axis}
procedure SetInverseRotationMatZ(var M : TMat4X4; ZAngle : TBasicFloat);
begin
  SetUnitMat(M);
  M[1,1] := cos(ZAngle);
  M[2,2] := M[1,1];
  M[2,1] := sin(ZAngle);
  M[1,2] := -M[2,1];
end;

{Set inverse rotation matrix around the X,Y,Z axis}
procedure SetInverseRotationMat(var M : TMat4X4; Angle : TBasicFloat);
var
  CosSin, Co, Si : TBasicFloat;
  i:integer;
begin
  CosSin:= sin(Angle) * cos(Angle);
  Co:= cos(Angle);
  Si := sin(Angle);
  M[1,1]:= Co * Co;
  M[1,2]:= -CosSin;
  M[1,3]:= Si;
  M[2,1]:= CosSin * ( Si + 1);
  M[2,2]:= - Si*Si*Si + Co*Co;
  M[2,3]:= -CosSin;
  M[3,1]:= -CosSin*Co + Si*Si;
  M[3,2]:= CosSin*(Si + 1);
  M[3,3]:= Co*Co;
  for i:= 1 to 3 do
    begin
      M[i,4]:=0;
      M[4,i]:=0;
    end;
  M[4,4]:=1;
end;
{Set scaling matrix}
procedure SetScaleMat(var M : TMat4X4; SX,SY,SZ : TBasicFloat);
begin
  SetUnitMat(M);
  M[1,1] := SX;
  M[2,2] := SY;
  M[3,3] := SZ;
end;

{Set inverse scaling matrix}
procedure SetInverseScaleMat(var M : TMat4X4; SX,SY,SZ : TBasicFloat);
begin
  SetUnitMat(M);
  M[1,1] := 1/SX;
  M[2,2] := 1/SY;
  M[3,3] := 1/SZ;
end;

{Set XY mirror matrix}
procedure SetXYMirrorMat(var M : TMat4X4);
begin
  SetUnitMat(M);
  M[3,3] := -1;
end;

{Set XZ mirror matrix}
procedure SetXZMirrorMat(var M : TMat4X4);
begin
  SetUnitMat(M);
  M[2,2] := -1;
end;

{Set YZ mirror matrix}
procedure SetYZMirrorMat(var M : TMat4X4);
begin
  SetUnitMat(M);
  M[1,1] := -1;
end;

{Set rotation matrix around arbitrary axis}
procedure SetArbitraryRotMat(var M : TMat4X4; P1,P2 : TVertex; Angle : TBasicFloat);
 {USING RIGHT FAND = Axis Z to out the monitor }
var
  C :TVertex;
  MTra, MRo_X, MRo_Y, MRo_Z, TempM : TMat4X4;
  D:TBasicFloat;

begin
   { Find the direction cosines of the arbitrary axis P1-->P2 .
     The direction cosines will be in C }

  CalcNormalizedVec(P1,P2,C);

  D := sqrt( C.y*C.y + C.z*C.z );

  // Special case for the X axis
  if D = 0 then
  begin
    SetTrans(MTra, -P1.x, -P1.y, -P1.z);
    SetRotationMatX(MRo_X,Angle);
    MulMat(MTra,MRo_X,TempM);
    SetTrans(MTra,P1.x,P1.y,P1.z);
    MulMat(TempM,MTra,M);
  end
    else
    begin
      SetTrans(MTra, -P1.x, -P1.y, -P1.z);

      {prepare matrix rotation about axis X with angle Alfa
       Cos(Alfa) = C.z / D     Sin(Alfa) = C.y / D }
      SetUnitMat(MRo_X);
      MRo_X[2,2] := C.z / D ;
      MRo_X[3,3] := MRo_X[2,2];
      MRo_X[2,3] := C.y / D ;
      MRo_X[3,2] := -MRo_X[2,3] ;

      {prepare matrix rotation about axis Y with angle Beta
       Cos(Beta) =  D     Sin(Beta) = -C.x }
      SetUnitMat(MRo_Y);
      MRo_Y[1,1] := D;
      MRo_Y[3,3] := MRo_Y[1,1];
      MRo_Y[1,3] := C.x;
      MRo_Y[3,1] := -MRo_Y[1,3];

      {M= Trans * Rot about axis X * Rot about axis Y }
      MulMat(MTra,MRo_X,TempM);
      MulMat(TempM,MRo_Y,M);

      {prepare matrix rotation about axis Z with angle Angle}
      SetRotationMatZ(MRo_z,Angle);

      {TempM= Trans * Rot axis X * Rot axis Y * Rot about axis Z by angle Angle}
      MulMat(M,MRo_Z,TempM);

      // Find inverse Y matrix
      MRo_Y[1,1] := D;
      MRo_Y[3,3] := D;
      MRo_Y[1,3] := -C.x;
      MRo_Y[3,1] := C.x;

      MulMat(TempM,MRo_Y,M);

      // Find inverse x matrix
      MRo_X[2,2] := C.z / D ;
      MRo_X[3,3] := MRo_X[2,2];
      MRo_X[3,2] := C.y / D;
      MRo_X[2,3] := -MRo_X[3,2];

      MulMat(M,MRo_X,TempM);

      // Find inverse translation matrix
      SetTrans(MTra,P1.x,P1.y,P1.z);

      MulMat(TempM,MTra,M);
    end;
end;

{Transpose matrix}
function TransposeMat(var M : TMat4X4): TMat4x4;
var
  i,j:integer;

begin
  //SetUnitMat(Result);

  for i:=1 to 4 do
   for j:=1 to 4 do
     Result[i,j] := M[j,i];
end;

{Matrix addition}
procedure AddMat(var M1,M2,R : TMat4X4);
var i,j:byte;
begin
    for i:= 1 to 4 do
     for j:= 1 to 4 do
       R[i,j] := M1[i,j] + M2[i,j]
end;

{Matrix subtraction}
procedure SubMat(var M1,M2,R : TMat4X4);
var i,j:byte;
begin
    for i:= 1 to 4 do
     for j:= 1 to 4 do
      R[i,j] := M1[i,j] - M2[i,j]
end;

{Matrix negation M = -M}
procedure NegMat(var M : TMat4X4);
var i,j:byte;
begin
    for i:= 1 to 4 do
     for j:= 1 to 4 do
      M[i,j] := -M[i,j]
end;

{Matrix multiplication}
procedure MulMat(var M1,M2,R : TMat4X4);
var i,j,k:byte;
    Sum:T3DCoordType;
begin
    for i := 1 to 4 do
     for j := 1 to 4 do
      begin
        Sum :=0;
        for k := 1 to 4 do
           Sum := Sum + M1[i,k] * M2[k,j];
        R[i,j] := Sum
      end
end;

{Multiply with a scalar value}
procedure MulMatScalar(M : TMat4X4; Scalar : T3DCoordType; var R : TMat4X4);
var i,j:byte;
begin
    for i := 1 to 4 do
     for j := 1 to 4 do
       R[i,j] := M[i,j] * Scalar
end;

{Multiply a 3D point with a 4X4 matrix}
procedure MulMatWithPoint3D(P : TVertex; var R : TVertex; var M : TMat4X4);
begin
  R.x := P.x * M[1,1] + P.y * M[2,1] + P.z * M[3,1] + M[4,1];
  R.y := P.x * M[1,2] + P.y * M[2,2] + P.z * M[3,2] + M[4,2];
  R.z := P.x * M[1,3] + P.y * M[2,3] + P.z * M[3,3] + M[4,3];
end;

function DotProduct(P1,P2 : TVertex) : TBasicFloat;
begin
    DotProduct := P1.x * P2.x + P1.y * P2.y + P1.z * P2.z
end;

procedure CrossProduct(P1,P2 : TVertex; var P3 : TVertex);
begin
   P3.x := P1.y * P2.z - P1.z * P2.y;
   P3.y := P1.z * P2.x - P1.x * P2.z;
   P3.z := P1.x * P2.y - P1.y * P2.x;
end;

{The distance from point P1 to P2 }
function PointDistance(P1,P2 : TVertex) : TBasicFloat;
begin
 PointDistance:=sqrt( sqr(P1.x-P2.x) + sqr(P1.y-P2.y) + sqr(P1.z-P2.z) );
end;

procedure SetUnitPoint(var P : TVertex);
begin
  P.x := 1;
  P.y := 1;
  P.z := 1;
end;

{Result = normalized  vector P  }
procedure CalcNormalizedVec(p1,p2 : TVertex; var Result : TVertex);
var  Mag:TBasicFloat;
begin
   Mag := sqrt(Sqr(p1.x - p2.x) + Sqr(p1.y - p2.y) + Sqr(p1.z - p2.z));
   Result.x := (p2.x - p1.x) / Mag;
   Result.y := (p2.y - p1.y) / Mag;
   Result.z := (p2.z - p1.z) / Mag;
end;

function NormalizeVertex(p : TVertex) : TVertex;
var
  Mag:TBasicFloat;
begin
 Mag := sqrt(Sqr(p.x) + Sqr(p.y) + Sqr(p.z));
 Result.x := p.x / Mag;
 Result.y := p.y / Mag;
 Result.z := p.z / Mag;
end;

function ArcSin(X : TBasicFloat) : TBasicFloat;
begin
  X := Frac(X);
  ArcSin := ArcTan (x/sqrt (1-sqr(x)))
end;

function ArcCos(X : TBasicFloat) : TBasicFloat;
begin
  X := Frac(X);
  ArcCos := ArcTan (sqrt (1-sqr (x)) /x);
end;

function Deg2Rad(D : TBasicFloat) : TBasicFloat;
begin
  Deg2Rad := D * (Pi / 180);
end;

function Rad2Deg(R : TBasicFloat) : TBasicFloat;
begin
  Rad2Deg := R * (180 / Pi);
end;

function SimpleRound(X : TBasicFloat) : integer;
begin
  Result := Trunc(X + 0.5);
end;

function CalcFaceNormal(p1,p2,p3 : TVertex) : TVertex;
begin
  p2.X := p2.X - p1.X;
  p2.Y := p2.Y - p1.Y;
  p2.Z := p2.Z - p1.Z;

  p3.X := p3.X - p1.X;
  p3.Y := p3.Y - p1.Y;
  p3.Z := p3.Z - p1.Z;

  CrossProduct(P2,P3,P1);

  Result := P1;
end;

function RandomRange(A, B: integer) : integer;
begin
  Result:= Random(B - A) + A;
end;

function IsPointInRect(var Rect : T2DRect; X,Y : TBasicFloat) : boolean;
var
  i,j : integer;
  c : boolean;
begin
  c := false;
  j := 3;
  i := 0;

  while i < 4 do
  begin
    if ( ( (Rect[i].Y <= Y) and (Y < Rect[j].Y) ) or
         ( (Rect[j].Y <= Y) and (Y < Rect[i].Y)) ) and
       (X < (Rect[j].X - Rect[i].X) * (Y - Rect[i].Y) / (Rect[j].Y - Rect[i].Y) + Rect[i].X) then
      c := not c;

    j := i;
    Inc(i);
  end;

  Result := c;
end;

function IsRectsIntersect(var R1,R2 : T2DRect) : boolean;
var
  i : integer;
begin
  for i := 0 to 3 do
    if IsPointInRect(R2,R1[i].X,R1[i].Y) then
    begin
      Result := true;
      Exit;
    end;

  for i := 0 to 3 do
    if IsPointInRect(R1,R2[i].X,R2[i].Y) then
    begin
      Result := true;
      Exit;
    end;

  Result := false;  
end;


end.

