unit RenderContext;

interface

uses graphics,Base3DTypes,Mat4x4;

const
  DEFAULT_BACKGROUND_COLOR = clWhite;

type

TRenderContext = class(TObject)
  private
    HasBackgroundImage:Boolean;
    BkgImage:TBitmap;

    FWidth,FHeight : integer;
    FBackgroundColor : TColor;

    VScreen : TBitmap;
    ZBuffer : array of array of TBasicFloat;

    FViewMatrix : TMat4x4;

    // Initialize internal variables
    procedure Init;

  public
    constructor Create; overload;
    constructor Create(Width,Height : integer); overload;

    destructor Destroy; override;

    // Set new buffers size
    procedure SetSize(Width,Height : integer);

    // Set a new background color
    procedure SetBackgroundColor(BackgroundColor : TColor);

    // Start a render operation
    procedure BeginRender;

    property Width : integer read FWidth;
    property Height : integer read FHeight;

    // Return a pointer to a specific pixel on the VScreen
    function GetPixelPtr(X,Y : integer) : PRGBPixel;

    // Return a pointer to a specific pixel on the ZBuffer
    function GetZBufferPtr(X,Y : integer) : PBasicFloat;

    // Set viewing matrix
    procedure SetViewMat(Mat : TMat4x4);

    // Return the current view matrix
    function GetViewMat : TMat4x4;

    function GetViewDirection : TVertex;

    function GetPerspectiveFactor : TBasicFloat;

    // Return the virtual-screen canvas
    function GetVScreenCanvas : TCanvas;

    // Clear all relavent buffers
    procedure ClearBuffers;

    // Copy VScreen to a new screen (canvas)
    procedure CopyToScreen(ScreenCanvas : TCanvas);
    procedure LoadBackgroundImage(f:string);

end;

implementation

uses Classes;

const
  MAX_Z_BUFFER_VALUE = 1e20;

{ TRenderContext }

// Initialize internal variables
procedure TRenderContext.Init;
begin
  VScreen := TBitmap.Create;
  BkgImage:=TBitmap.Create;
  VScreen.PixelFormat := pf24bit;
  FBackgroundColor := DEFAULT_BACKGROUND_COLOR;
  VScreen.Canvas.Brush.Color := FBackgroundColor;
  VScreen.Canvas.Pen.Color := FBackgroundColor;
  LoadBackgroundImage('.\sky.bmp');
  SetUnitMat(FViewMatrix);
end;

constructor TRenderContext.Create;
begin
  Init;
end;

constructor TRenderContext.Create(Width, Height: integer);
begin
  Init;
  SetSize(Width,Height);
end;

procedure TRenderContext.BeginRender;
begin
  ClearBuffers;
end;

destructor TRenderContext.Destroy;
begin
  VScreen.Free;
  ZBuffer := nil;
  inherited;
end;

procedure TRenderContext.SetSize(Width, Height: integer);
begin
  // Allocate image buffer
  VScreen.Width := Width;
  VScreen.Height := Height;

  // Allocate Z buffer
  SetLength(ZBuffer,Height,Width);

  FWidth := Width;
  FHeight := Height;

  ClearBuffers;
end;

procedure TRenderContext.ClearBuffers;
var
  i,j : integer;
begin

   // Clear Z Buffer
  for j := 0 to FHeight - 1 do
    for i := 0 to FWidth - 1 do
      ZBuffer[j,i] := MAX_Z_BUFFER_VALUE;

  if HasBackgroundImage then
  begin
     VScreen.Canvas.StretchDraw(Rect(0,0,Fwidth,FHeight),BkgImage); 
  end
  else
  begin
     VScreen.Canvas.Brush.Color := FBackgroundColor;
     VScreen.Canvas.Pen.Color := FBackgroundColor;
     VScreen.Canvas.FillRect(Rect(0,0,VScreen.Width,VScreen.Height));
  end;
end;

procedure TRenderContext.SetBackgroundColor(BackgroundColor: TColor);
begin
  FBackgroundColor := BackgroundColor;
end;

function TRenderContext.GetPixelPtr(X,Y: integer): PRGBPixel;
begin
  Result := VScreen.ScanLine[Y];
  Inc(Result,X);
end;

function TRenderContext.GetZBufferPtr(X,Y: integer): PBasicFloat;
begin
  Result := @ZBuffer[Y][X];
end;

function TRenderContext.GetViewMat: TMat4x4;
begin
  Result := FViewMatrix;
end;

procedure TRenderContext.SetViewMat(Mat: TMat4x4);
begin
  FViewMatrix := Mat;
end;

function TRenderContext.GetViewDirection : TVertex;
begin
  Result.X := 0;
  Result.Y := 0;
  Result.Z := 1;
end;

function TRenderContext.GetPerspectiveFactor: TBasicFloat;
begin
  Result := -500;
end;

function TRenderContext.GetVScreenCanvas: TCanvas;
begin
  Result := VScreen.Canvas;
end;

procedure TRenderContext.CopyToScreen(ScreenCanvas: TCanvas);
begin
  ScreenCanvas.Draw(0,0,VScreen);
end;


procedure TrenderContext.LoadBackgroundImage(f:string);
begin
  //  BkgImage:=TBitmap.Create;

    BkgImage.LoadFromFile(f);
    HasBackgroundImage:=True;
end;



end.
