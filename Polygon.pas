unit Polygon;

interface

uses RenderContext,Base3DTypes,Windows,Graphics;

type
  TTrianglePoints = array[0..2] of TPoint;


// Draw a filled triangle on a given rendering context
procedure DrawFilledTriangle(Points : TTrianglePoints; Context : TRenderContext; Color : TRGBPixel; M,N,K : TBasicFloat);


implementation

const
  MaxVerticesOfPoly = 3;
  MAX_SCAN_LINES = 4000;

type
 {Describes the beginning and ending X coordinates of a single
  horizontal line}
  THLine = record
    XStart,XEnd : integer;
  end;

  {Describes a Length-long series of horizontal lines, all assumed to
  be on contiguous scan lines starting at YStart and proceeding
  downward (used to describe a scan-converted polygon to the
  low-level hardware-dependent drawing code)}
  THLineList = record
    ListLength : integer; {Number of horizontal lines}
    YStart : integer;  {Y coordinate of topmost line}

    HLines : array[0..MAX_SCAN_LINES] of THLine; {List of horizontal lines}
  end;


{Advances an index by one vertex forward through the vertex list,
wrapping at the end of the list, return the new vertex index}
function IndexForward(Index{,MaxLength} : integer) : integer;
begin
  IndexForward := (Index + 1) mod {MaxLength} MaxVerticesOfPoly;
end;

{Advances an index by one vertex backward through the vertex list,
wrapping at the start of the list, return the new vertex index}
function IndexBackward(Index {,MaxLength} : integer) : integer;
begin
  IndexBackward := (Index - 1 + {MaxLength}MaxVerticesOfPoly) mod {MaxLength} MaxVerticesOfPoly;
end;

{Scan converts an edge from (X1,Y1) to (X2,Y2), not including the
point at (X2,Y2). This avoids overlapping the end of one line with
the start of the next, and causes the bottom scan line of the
polygon not to be drawn. If SkipFirst !!= 0, the point at (X1,Y1)
isn't drawn. For each scan line, the pixel closest to the scanned
line without being to the left of the scanned line is chosen}
procedure ScanEdge(X1,Y1,X2,Y2 : integer; SetXStart,SkipFirst : integer;
                   var EdgePointIndex : integer;
                   var Edges : THLineList; HalfHeight : integer);
var
  Y, DeltaX, DeltaY : integer;
  InverseSlope : real;
  WorkingEdgePointIndex : integer;
  StartY,EndY : integer;
begin
  {Calculate X and Y lengths of the line and the inverse slope}
  DeltaX := X2 - X1;

  {guard against 0-length and horizontal edges}
  DeltaY := Y2 - Y1;
  if DeltaY <= 0 then
    exit;

  InverseSlope := DeltaX / DeltaY;

  {Store the X coordinate of the pixel closest to but not to the
   left of the line for each Y coordinate between Y1 and Y2, not
   including Y2 and also not including Y1 if SkipFirst <> 0}

  WorkingEdgePointIndex := EdgePointIndex;

  StartY := Y1 + SkipFirst;
  EndY := Y2 - 1;

  {
  if EndY < -HalfHeight then
    EndY := -HalfHeight;

  if StartY >= HalfHeight then
    StartY := HalfHeight - 1;
  }

  for Y := StartY to EndY do
    begin
      {Store the X coordinate in the appropriate edge list}
      if SetXStart = 1 then
        Edges.HLines[WorkingEdgePointIndex].XStart := X1 + Trunc((Y-Y1) * InverseSlope + 1.0)
      else
        Edges.HLines[WorkingEdgePointIndex].XEnd := X1 + Trunc((Y-Y1) * InverseSlope + 1.0) + 1;

      Inc(WorkingEdgePointIndex);
    end;

  {advance caller's ptr}
  EdgePointIndex := WorkingEdgePointIndex;
end;

{Advances the index by one vertex either forward or backward through
the vertex list, wrapping at either end of the list}
function IndexMove(Index,Direction,MaxLength : integer) : integer;
begin
  if Direction > 0 then
    IndexMove := (Index + 1) mod MaxLength
      else IndexMove := (Index - 1 + MaxLength) mod MaxLength;
end;

procedure DrawFilledTriangle(Points : TTrianglePoints; Context : TRenderContext; Color : TRGBPixel; M,N,K : TBasicFloat);

procedure DrawHorizontalLineList(var HLineList : THLineList);
var
  i,x,y : integer;
  HalfWidth,HalfHeight : integer;
  DrawCanvas : TCanvas;
  XLineStart,XLineEnd,YLine : integer;
  OneDivZ : TBasicFloat;
  PixelPtr : PRGBPixel;
  ZBuffPtr : PBasicFloat;
  ScreenXStart,ScreenXEnd : integer;
begin
  HalfWidth := Context.Width div 2;
  HalfHeight := Context.Height div 2;

  DrawCanvas := Context.GetVScreenCanvas;

  DrawCanvas.Pen.Color:= RGB(Color.R,Color.G,Color.B);
  DrawCanvas.Pen.Style:= psSolid;

  with HLineList do
    for i := 0 to ListLength - 1 do
    begin
//      DrawCanvas.MoveTo(HLines[i].XStart + HalfWidth,HalfHeight - (i + YStart));
//      DrawCanvas.LineTo(HLines[i].XEnd + HalfWidth,HalfHeight - (i + YStart));

      XLineStart := HLines[i].XStart;
      XLineEnd := HLines[i].XEnd;
      y := i + YStart;
      YLine := HalfHeight - y;

      // Draw only lines that in the screen Y range
      if (YLine >= 0) and (YLine < Context.Height) then
      begin
        // Convert logical 2D coordinates to absolute 2D screen coordinates
        ScreenXStart := HalfWidth + XLineStart;
        ScreenXEnd := HalfWidth + XLineEnd;

        // Check if the line is outside the screen
        if (ScreenXStart >= Context.Width) or (ScreenXEnd < 0) then
          continue;

        // Clip the horizontal line
        if ScreenXStart < 0 then
          XLineStart := -HalfWidth;

        if ScreenXEnd >= Context.Width then
          XLineEnd := HalfWidth - 1;

        // Get pointers to the line start
        PixelPtr := Context.GetPixelPtr(HalfWidth + XLineStart,YLine);
        ZBuffPtr := Context.GetZBufferPtr(HalfWidth + XLineStart,YLine);

        for x := XLineStart to XLineEnd do
        begin
          OneDivZ := M * x + N * y + K;

          if OneDivZ < ZBuffPtr^ then
          begin
            PixelPtr^ := Color;
            ZBuffPtr^ := OneDivZ;
          end;

          Inc(PixelPtr);
          Inc(ZBuffPtr);
        end;
      end
    end;
end;

var
 i, MinIndexL, MaxIndex, MinIndexR, SkipFirst, Temp : integer;
  MinPoint_Y, MaxPoint_Y, LeftEdgeDir : integer;
  NextIndex, CurrentIndex, PreviousIndex : integer;
  TopIsFlat,DeltaXN, DeltaYN, DeltaXP, DeltaYP : integer;
  WorkingHLineList : THLineList;
  EdgePointPtr : integer;

begin
  {Scan the list to find the top and bottom of the polygon}
  MinIndexL := 0;
  MaxIndex := 0;
  MinPoint_Y := Points[0].Y;
  MaxPoint_Y := MinPoint_Y;

  for i := 1 to MaxVerticesOfPoly - 1 do
    begin
      if Points[i].Y < MinPoint_Y then
        begin
          {new top}
          MinPoint_Y := Points[i].Y;
          MinIndexL := i;
        end else
          if Points[i].Y > MaxPoint_Y then
            begin
              {new bottom}
              MaxPoint_Y := Points[i].Y;
              MaxIndex := i;
            end;
    end;

  if MinPoint_Y = MaxPoint_Y then
    {polygon is 0-height; avoid infinite loop below }
    exit;

  {Scan in ascending order to find the last top-edge point}
  MinIndexR := MinIndexL;
  while Points[MinIndexR].Y = MinPoint_Y do
    MinIndexR := IndexForward(MinIndexR {, MaxVerticesOfPoly});

  {back up to last top-edge point}
  MinIndexR := IndexBackward(MinIndexR {, MaxVerticesOfPoly});

  {Now scan in descending order to find the first top-edge point}
  while Points[MinIndexL].Y = MinPoint_Y do
    MinIndexL := IndexBackward(MinIndexL{, MaxVerticesOfPoly});

  {back up to first top-edge point}
  MinIndexL := IndexForward(MinIndexL {, MaxVerticesOfPoly});

  {Figure out which direction through the vertex list from the top
   vertex is the left edge and which is the right}
  LeftEdgeDir := -1; {assume left edge runs down thru vertex list}

  if Points[MinIndexL].X <> Points[MinIndexR].X then
    TopIsFlat := 1
  else TopIsFlat := 0;

  {If the top is flat, just see which of the ends is leftmost}
  if TopIsFlat = 1 then
    begin
      if Points[MinIndexL].X > Points[MinIndexR].X then
        begin
          LeftEdgeDir := 1; {left edge runs up through vertex list}
          Temp := MinIndexL; {swap the indices so MinIndexL}
          MinIndexL := MinIndexR; {points to the start of the left}
          MinIndexR := Temp;      {edge, similarly for MinIndexR}
        end;
    end else
      begin
        {Point to the downward end of the first line of each of the
         two edges down from the top}
        NextIndex := MinIndexR;
        NextIndex := IndexForward(NextIndex{,MaxVerticesOfPoly});
        PreviousIndex := MinIndexL;
        PreviousIndex := IndexBackward(PreviousIndex {,MaxVerticesOfPoly});

        {Calculate X and Y lengths from the top vertex to the end of
         the first line down each edge; use those to compare slopes
         and see which line is leftmost}
        DeltaXN := Points[NextIndex].X - Points[MinIndexL].X;
        DeltaYN := Points[NextIndex].Y - Points[MinIndexL].Y;
        DeltaXP := Points[PreviousIndex].X - Points[MinIndexL].X;
        DeltaYP := Points[PreviousIndex].Y - Points[MinIndexL].Y;

        if (DeltaXN * DeltaYP - DeltaYN * DeltaXP) < 0 then
          begin
            LeftEdgeDir := 1; {left edge runs up through vertex list}
            Temp := MinIndexL; {swap the indices so MinIndexL}
            MinIndexL := MinIndexR; {points to the start of the left}
            MinIndexR := Temp; {edge, similarly for MinIndexR}
          end;
      end;

  {Set the # of scan lines in the polygon, skipping the bottom edge
   and also skipping the top vertex if the top isn't flat because
   in that case the top vertex has a right edge component, and set
   the top scan line to draw, which is likewise the second line of
   the polygon unless the top is flat}

   WorkingHLineList.ListLength := MaxPoint_Y - MinPoint_Y - 1 + TopIsFlat;
   if WorkingHLineList.ListLength <= 0 then
     {there's nothing to draw, so we're done}
     exit;

   WorkingHLineList.YStart := MinPoint_Y + 1 - TopIsFlat;

   {Scan the left edge and store the boundary points in the list}

   {Initial pointer for storing scan converted left-edge coords}
   EdgePointPtr := 0;

   {Start from the top of the left edge}
   CurrentIndex := MinIndexL;
   PreviousIndex := MinIndexL;

   {Skip the first point of the first line unless the top is flat;
    if the top isn't flat, the top vertex is exactly on a right
    edge and isn't drawn}
   SkipFirst := 1 - TopIsFlat;

   {Scan convert each line in the left edge from top to bottom}
   repeat
     CurrentIndex := IndexMove(CurrentIndex,LeftEdgeDir,MaxVerticesOfPoly);
     ScanEdge(Points[PreviousIndex].X, Points[PreviousIndex].Y,
              Points[CurrentIndex].X,  Points[CurrentIndex].Y, 1,
              SkipFirst,EdgePointPtr, WorkingHLineList,Context.Height div 2);
     PreviousIndex := CurrentIndex;
     SkipFirst := 0; {scan convert the first point from now on}
   until CurrentIndex = MaxIndex;

   {Scan the right edge and store the boundary points in the list}
   EdgePointPtr := 0;
   CurrentIndex := MinIndexR;
   PreviousIndex := MinIndexR;
   SkipFirst := 1 - TopIsFlat;

   {Scan convert the right edge, top to bottom. X coordinates are
    adjusted 1 to the left, effectively causing scan conversion of
    the nearest points to the left of but not exactly on the edge}
   repeat
     CurrentIndex := IndexMove(CurrentIndex,-LeftEdgeDir,MaxVerticesOfPoly);
     ScanEdge(Points[PreviousIndex].X - 1, Points[PreviousIndex].Y,
              Points[CurrentIndex].X - 1,  Points[CurrentIndex].Y, 0,
              SkipFirst, EdgePointPtr, WorkingHLineList,Context.Height div 2);
     PreviousIndex := CurrentIndex;
     SkipFirst := 0; {scan convert the first point from now on}
   until CurrentIndex = MaxIndex;

   {Draw the line list representing the scan converted polygon}
   DrawHorizontalLineList(WorkingHLineList);
end;

end.
