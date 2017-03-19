unit Base3DTypes;

interface

uses Graphics;

const
  VIEW_X_DISTANCE = 0;
  VIEW_Y_DISTANCE = -120;
  VIEW_Z_DISTANCE = -400;

type

TBasicFloat = single;
PBasicFloat = ^TBasicFloat;

TVertex = record
  X,Y,Z : TBasicFloat;
end;

// A low-level pixel format (24Bit pixel)
TRGBPixel = record
  B : byte;
  G : byte;
  R : byte;
end;

PRGBPixel = ^TRGBPixel;

TFace3D = record
  // Indices to the vertex table
  AIndex,BIndex,CIndex : integer;

  // Face normal
  Normal : TVertex;

  // Face color
  Color : TRGBPixel;
end;

T2DPoint = record
  X,Y : TBasicFloat;
end;

T2DRect = array[0..3] of T2DPoint;

function MakeVertex(X,Y,Z : TBasicFloat) : TVertex;
function Make2DPoint(X,Y : TBasicFloat) : T2DPoint;

implementation

function MakeVertex(X,Y,Z : TBasicFloat) : TVertex;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Z := Z;    
end;

function Make2DPoint(X,Y : TBasicFloat) : T2DPoint;
begin
  Result.X := X;
  Result.Y := Y;
end;

end.
