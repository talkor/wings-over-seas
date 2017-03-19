unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, Object3D,
  StdCtrls,IniFiles, ExtCtrls,RenderContext, Menus, Mat4x4, Base3DTypes,
  Buttons, ComCtrls, jpeg, MPlayer, Psock, NMEcho, MMSystem, Grids,
  DBGrids, Db, DBTables;

const
  PLANE_Y = -100;

  AIRPLANE_X_POS = 0;
  AIRPLANE_START_Y_POS = 200;
  AIRPLANE_Z_POS = 150;

  MOVE_DELTA = 15;
  TURN_DELTA = 20;

  SPEED_DELTA = 20;

  NUM_GATES = 21;
  GATE_HEIGHT = 100;
  GATE_WIDTH = 300;

  GATE_COLLISION_DISTANCE = 90;
  GATE_PASS_DISTANCE = 300;

  ARROW_X = 0;
  ARROW_Y = 350;
  ARROW_Z = -200;

  AIRPLANE_HEIGHT = 42;
  AIRPLANE_NOSE_WIDTH = 32;
  AIRPLANE_WINGS_WIDTH = 35;
  AIRPLANE_TAIL_WIDTH = 64;

Type
  TGameStates = (gsAirplaneFly, gsAirplaneCrashes);

  TAirplane = record
    Obj: TObject3D;
    Pos: TVertex;
  end;

  TGameObject = record
    Obj: TObject3D;
    Pos: TVertex;
  end;

  TMainForm = class(TForm)
    MainMenu1: TMainMenu;
    OptionsMenuItem: TMenuItem;
    Backfaceculling1: TMenuItem;
    Wireframe1: TMenuItem;
    Nolightning1: TMenuItem;
    File1: TMenuItem;
    Exit1: TMenuItem;
    New1: TMenuItem;
    AltitudeBar: TProgressBar;
    SpeedBar: TProgressBar;
    LabelScoreText: TLabel;
    LabelScore: TLabel;
    LabelSpeed: TLabel;
    LabelSpeedText: TLabel;
    LabelAltitude: TLabel;
    LabelAltitudeText: TLabel;
    LabelGreetings: TLabel;
    LabelGatesPassed: TLabel;
    LabelGatesPassedText: TLabel;
    LabelWin: TLabel;
    LabelLose: TLabel;
    Timer1: TTimer;
    Help1: TMenuItem;
    About1: TMenuItem;
    UserGuide1: TMenuItem;
    Panel1: TPanel;
    Panel3: TPanel;
    ButtonStart: TButton;
    ButtonInstructions: TButton;
    ButtonAbout: TButton;
    ImageOpening: TImage;

    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure BackfaceCulling1Click(Sender: TObject);
    procedure Wireframe1Click(Sender: TObject);
    procedure Nolightning1Click(Sender: TObject);
    procedure Exit1Click(Sender: TObject);

    procedure Timer1Timer(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure New1Click(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure About1Click(Sender: TObject);
    procedure ButtonStartClick(Sender: TObject);
    procedure ButtonInstructionsClick(Sender: TObject);
    procedure UserGuide1Click(Sender: TObject);
    procedure ButtonAboutClick(Sender: TObject);


  private
    RenderContext : TRenderContext;

    Gate : Array[0..NUM_GATES - 1,0..1] of TGameObject;

    CurrentYDelta, CurrentXDelta, CurrentGate, CurrentSpeed : Integer;
    GatesPassed, CrashAngleY, Score : Integer;

    Airplane : TAirplane;
    Arrow : TGameObject;

    GameState : TGameStates;

    Procedure RefreshDisplay;
    Procedure Initialize;
    Procedure AirplaneFly;

    Procedure SetAirplanePos;
    Procedure SetGatePos(i:integer; X,Z : TBasicFloat);
    Procedure MoveGates;
    Procedure SetArrowAngle(AngleInRad : TBasicFloat);

    Procedure AirplaneCrashes;
    Procedure PlaceGates;
    Procedure ColorCurrentGate;
    Procedure EndOfGame;
    Procedure AirplanePassedGate;

    Function CalcDistanceToGate : Boolean;
    Function SeaCollision : Boolean;
    Function GatesCollision : Boolean;

    Procedure GameScore(PlayerStatus : Char);
    Procedure GameGreetings(GateState : Char);

   public
     procedure ChangeViewMat(var NewMat : TMat4x4);
  end;

var
  MainForm: TMainForm;

implementation    {**************************************}

uses  ViewControlDlg, About, Instructions;

{$R *.DFM}

procedure TMainForm.FormDestroy(Sender: TObject);
var
  i,j : Integer;
begin
  Airplane.Obj.Free;

  for i:=0 to NUM_GATES - 1 do
    for j:=0 to 1 do
      Gate[i,j].obj.Free;

  Arrow.obj.Free;
  RenderContext.Free;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  M : TMat4x4;
  i,j : Integer;
begin
  Randomize;
  Airplane.Obj := TObject3D.Create('.\Pitts.ini');

  for i:=0 to NUM_GATES - 1 do
    for j:=0 to 1 do
        Gate[i,j].Obj := TObject3D.Create('.\Cylinder.ini');

  Arrow.Obj := TObject3D.Create('.\Arrow.ini');

  RenderContext := TRenderContext.Create(ClientWidth,ClientHeight);
  SetTrans(M, VIEW_X_DISTANCE, VIEW_Y_DISTANCE, VIEW_Z_DISTANCE);
  RenderContext.SetViewMat(M);

  Initialize;
end;

procedure TMainForm.ChangeViewMat(var NewMat: TMat4x4);
begin
  RenderContext.SetViewMat(NewMat);
  RefreshDisplay;
end;

procedure TMainForm.RefreshDisplay;
var
  i,j : Integer;
begin
  RenderContext.ClearBuffers;

  for i:=0 to NUM_GATES - 1 do
    for j:=0 to 1 do
        Gate[i,j].Obj.Render(RenderContext);

  Airplane.Obj.Render(RenderContext);
  Arrow.Obj.Render(RenderContext);

  RenderContext.CopyToScreen(Canvas);
end;

Procedure TMainForm.FormPaint(Sender: TObject);
begin
  RefreshDisplay;
end;

Procedure TMainForm.Backfaceculling1Click(Sender: TObject);
begin
  BackfaceCulling1.Checked := not BackfaceCulling1.Checked;

  if not BackfaceCulling1.Checked then
    Airplane.Obj.Options:= Airplane.Obj.Options + [opNoBackfaceCulling]
  else
    Airplane.Obj.Options:= Airplane.Obj.Options - [opNoBackfaceCulling];

  RefreshDisplay;
end;

Procedure TMainForm.Wireframe1Click(Sender: TObject);
begin
  Wireframe1.Checked := not Wireframe1.Checked;

  if Wireframe1.Checked then
    Airplane.Obj.Options:= Airplane.Obj.Options + [opWireFrame]
  else
    Airplane.Obj.Options:= Airplane.Obj.Options - [opWireFrame];

  RefreshDisplay;
end;

Procedure TMainForm.Nolightning1Click(Sender: TObject);
begin
  Nolightning1.Checked := not Nolightning1.Checked;

  if Nolightning1.Checked then
    Airplane.Obj.Options:= Airplane.Obj.Options + [opNoLight]
  else
    Airplane.Obj.Options:= Airplane.Obj.Options - [opNoLight];

  RefreshDisplay;
end;

Procedure TMainForm.FormShow(Sender: TObject);
begin
  ViewControlForm.RotateTrackBarChange(Sender);
end;

Procedure TMainForm.Exit1Click(Sender: TObject);
begin
  Close;
end;

Procedure TMainForm.Initialize;
begin
  GameState:=gsAirplaneFly;
  PlaceGates;

  CurrentYDelta := 0;
  CurrentXDelta := 0;
  CrashAngleY:= 0;
  SetArrowAngle(0);

  CurrentGate:=0;
  GatesPassed:=0;
  CurrentSpeed:=SPEED_DELTA;

  Airplane.pos := MakeVertex(AIRPLANE_X_POS,Airplane_START_Y_POS,AIRPLANE_Z_POS);
  SetAirplanePos;

  AltitudeBar.Position:=180;
  LabelGreetings.Caption:=' ';
  LabelScore.Caption:=IntToStr(0);
  LabelWin.visible:=False;
  LabelLose.visible:=False;
  Score:=0;
end;

Procedure TMainForm.PlaceGates;
Var
  GateRangeX, GateRangeZ, i : Integer;
begin
  GateRangeZ:=-3500;

  For i:=0 to NUM_GATES - 1 do
  begin
      GateRangeX:=RandomRange(-2500,2500);
      SetGatePos(i,GateRangeX,GateRangeZ);
      GateRangeZ:=GateRangeZ-3200;

      Gate[i,0].Obj.SetNewFacesColor(clNavy);
      Gate[i,1].Obj.SetNewFacesColor(clNavy);
  end;
end;

Procedure TMainForm.Timer1Timer (Sender: TObject);
begin
  case GameState of
    gsAirplaneFly: AirplaneFly;
    gsAirplaneCrashes: AirplaneCrashes;
  end;

  RefreshDisplay;

  if SeaCollision or GatesCollision then
  Begin
    GameState:=gsAirplaneCrashes;
    GameGreetings('C');            //C = Crashed
  end;

  AirplanePassedGate;
  ColorCurrentGate;

  LabelGatesPassed.Caption:=IntToStr(GatesPassed);

  EndOfGame;
end;

Procedure TMainForm.ColorCurrentGate;
begin
   Gate[CurrentGate,0].Obj.SetNewFacesColor(clRed);
   Gate[CurrentGate,1].Obj.SetNewFacesColor(clRed);

   Gate[CurrentGate-1,0].Obj.SetNewFacesColor(clNavy);
   Gate[CurrentGate-1,1].Obj.SetNewFacesColor(clNavy);

   Gate[NUM_GATES-1,0].Obj.SetNewFacesColor(clBlack);
   Gate[NUM_GATES-1,1].Obj.SetNewFacesColor(clBlack);
end;

Procedure TMainForm.AirplanePassedGate;
begin
   if (Gate[CurrentGate,0].Pos.Z -80 > Airplane.Pos.Z) and (CurrentGate < NUM_GATES-1) then
   begin
     Inc(CurrentGate);
     if (Gate[CurrentGate,0].Pos.Y + GATE_HEIGHT > Airplane.Pos.Y ) and CalcDistanceToGate then
          begin
             Inc(GatesPassed);
             GameGreetings('P');  // P = Passed the gate
          end
          else
             GameGreetings('M');  // M = Missed the gate
   end;
end;

Function TMainForm.CalcDistanceToGate : Boolean;
Var
    DistToGate1,DistToGate2:TBasicFloat;
begin
    DistToGate1 := Sqrt(Sqr(Gate[CurrentGate-1,0].pos.X) + Sqr(Airplane.Pos.Z -
                                                                Gate[CurrentGate-1,0].Pos.Z));
    DistToGate2 := Sqrt(Sqr(Gate[CurrentGate-1,1].pos.X) + Sqr(Airplane.Pos.Z -
                                                                Gate[CurrentGate-1,1].Pos.Z));

    Result := (DistToGate1 < GATE_PASS_DISTANCE) and (DistToGate2 < GATE_PASS_DISTANCE);
end;

Procedure TMainForm.AirplaneFly;
var
    ArrowAngle : TBasicFloat;
begin
    SetAirplanePos;
    MoveGates;

    //Finds Arrow angle\\
    ArrowAngle := ArcTan(( - (Gate[CurrentGate,0].Pos.X + GATE_WIDTH div 2)) /
                                ((Airplane.pos.Z + 260) - Gate[CurrentGate,0].Pos.Z));
    SetArrowAngle(ArrowAngle);

    //Altitude\\
    AltitudeBar.Position:=AltitudeBar.position + CurrentYDelta;
    LabelAltitude.Caption:=IntToStr(AltitudeBar.Position);

    //Speed\\
    SpeedBar.Position:=CurrentSpeed;
    LabelSpeed.Caption:=IntToStr(SpeedBar.Position);
end;

Procedure TMainForm.New1Click(Sender: TObject);
begin
  Initialize;
  Timer1.Enabled := True;
  Panel1.Visible:=False;
end;

Procedure TMainForm.SetAirplanePos;
var
  M1,M2,M3,M4,ResultMat: Tmat4x4;
  AirplaneAngle : TBasicFloat;
begin
  SetRotationMatX(M1,Deg2Rad(CurrentYDelta mod 360));

  if CurrentXDelta > 0 then
    AirplaneAngle := -TURN_DELTA
  else
    AirplaneAngle := TURN_DELTA;

  SetRotationMatZ(M2,Deg2Rad(AirplaneAngle));

  if CurrentXDelta = 0 then
  begin
      if AirplaneAngle <> 0 then
      begin
        AirplaneAngle := 0;
	SetRotationMatZ(M2,Deg2Rad(AirplaneAngle));
      end;
  end;

  MulMat(M1,M2,M3);
  SetTrans(M4,Airplane.pos.x,Airplane.pos.y,Airplane.pos.z);
  MulMat(M3,M4,ResultMat);
  Airplane.obj.SetMatrix(ResultMat);
end;

Procedure TMainForm.SetGatePos(i : Integer; X, Z: TBasicFloat);
var
  M : TMat4X4;
  k : Integer;
begin
  Gate[i,0].Pos := MakeVertex(X - GATE_WIDTH div 2,0,Z);
  Gate[i,1].Pos := MakeVertex(X + GATE_WIDTH div 2,0,Z);

    for k:=0 to 1 do
    begin
        SetTrans(M,Gate[i,k].Pos.X,Gate[i,k].Pos.Y,Gate[i,k].Pos.Z);
        Gate[i,k].Obj.SetMatrix(M);
    end;
end;

Procedure TMainForm.SetArrowAngle(AngleInRad: TBasicFloat);
var
  TMat,YMat,ResultMat : TMat4X4;
begin
  SetTrans(TMat,ARROW_X,ARROW_Y,ARROW_Z);
  SetRotationMatY(YMat,AngleInRad);
  MulMat(YMat,TMat,ResultMat);

  Arrow.Obj.SetMatrix(ResultMat);
end;

Procedure TMainForm.MoveGates;
var
  TMat: TMat4X4;
  i,j: Integer;
begin
    for i:=0 to NUM_GATES - 1 do
      for j:=0 to 1 do
      begin
        Gate[i,j].Pos := MakeVertex(Gate[i,j].Pos.X - (2 * CurrentXDelta),
                                    Gate[i,j].Pos.Y - CurrentYDelta,
                                    Gate[i,j].Pos.Z + CurrentSpeed);
        SetTrans(TMat,Gate[i,j].Pos.X,Gate[i,j].Pos.Y,Gate[i,j].Pos.Z);

        Gate[i,j].obj.Setmatrix(Tmat);
      end;
end;

Function TMainForm.SeaCollision : Boolean;
begin
    if Airplane.Pos.Y - AIRPLANE_HEIGHT div 2 <= Gate[0,0].Pos.Y then
      Result:=True
   else
      Result:=False;
end;

Function TMainForm.GatesCollision : Boolean;
var
  DistToGate1,DistToGate2: TBasicFloat;
begin
  if Gate[CurrentGate,0].Pos.Y + GATE_HEIGHT > Airplane.Pos.Y - AIRPLANE_HEIGHT div 2  then
  begin
    DistToGate1 := Sqrt(Sqr(Gate[CurrentGate,0].pos.X) + Sqr(Airplane.Pos.Z -
                                                                Gate[CurrentGate,0].Pos.Z));
    DistToGate2 := Sqrt(Sqr(Gate[CurrentGate,1].pos.X) + Sqr(Airplane.Pos.Z -
                                                                Gate[CurrentGate,1].Pos.Z));

    Result:=(DistToGate1 < GATE_COLLISION_DISTANCE) or (DistToGate2 < GATE_COLLISION_DISTANCE);
  end
  else
    Result:=False;
end;

Procedure TMainForm.AirplaneCrashes;
var
    M1,M2,M3:TMat4x4;
begin
    CrashAngleY:= CrashAngleY + 20;
    Airplane.Pos:=MakeVertex(0,Airplane.Pos.Y - 15,Airplane.Pos.Z);

    SetRotationMatY(M1,Deg2Rad(CrashAngleY));
    SetTrans(M2,Airplane.Pos.X,Airplane.Pos.Y,Airplane.Pos.Z);
    MulMat(M1,M2,M3);

    Airplane.Obj.SetMatrix(M3);
end;


Procedure TMainForm.GameGreetings(GateState : Char);
var
        TextMessage:string;
begin
        Case GateState of
        'C': TextMessage:='You Crashed!   Game Over!';           //Crashed
        'P': begin                                               //Passed
                TextMessage:='Good!';
                GameScore('P');
             End;
        'M': begin                                               //Missed
                TextMessage:='Ooops. You missed the gate.';
                GameScore('M');
             end;
        'L': begin                                               //Loses
                TextMessage:='You lost. You missed some gates!';
                LabelLose.Visible:=True;
             end;
        'W': begin                                               //Wins
                TextMessage:='You WON! Great job!';
                LabelWin.Visible:=True;
             end;
        end;

        //Show Message\\
        LabelGreetings.Caption:=TextMessage;
end;

Procedure TMainForm.GameScore(PlayerStatus : Char);
begin
        Case PlayerStatus of
           'P': Score:=Score + (10 * CurrentSpeed);    //Passed the gate
           'M': Begin                                  //Missed the gate
                  if Score < 300 then
                     Score:= 0
                  else
                     if Score > 0 then
                        Score:= Score -300;
                End;
        End;

        LabelScore.Caption:=IntToStr(Score);
end;

Procedure TMainForm.EndOfGame;
begin
   //Checks when game is over if player wins or loses the game
   if Airplane.Pos.Z < Gate[NUM_GATES-1,0].Pos.Z then
      If GatesPassed + 1 = NUM_GATES then
      begin
         GameGreetings('W');     // W = Wins the game
         Timer1.Enabled:=False;
      end
      else
      begin
         GameGreetings('L');     // L = Loses the game
         Timer1.Enabled:=False;
      end;
end;

Procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_Right: CurrentXDelta :=  TURN_DELTA;
    VK_Left:  CurrentXDelta := -TURN_DELTA;
    VK_Down:  CurrentYDelta :=  MOVE_DELTA;
    VK_UP:    CurrentYDelta := -MOVE_DELTA;
  end;
end;

Procedure TMainForm.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_Right: CurrentXDelta := 0;
    VK_Left:  CurrentXDelta := 0;
    VK_Down:  CurrentYDelta := 0;
    VK_UP:    CurrentYDelta := 0;
  end;
end;

Procedure TMainForm.FormKeyPress(Sender: TObject; var Key: Char);
begin
    if Key='s' Then
        if CurrentSpeed < SPEED_DELTA * 5 then
              CurrentSpeed:=CurrentSpeed + SPEED_DELTA;
    if Key='a' Then
        if CurrentSpeed > SPEED_DELTA then
              CurrentSpeed:=CurrentSpeed - SPEED_DELTA;
end;

Procedure TMainForm.About1Click(Sender: TObject);
begin
        FormAbout.Show;
end;

Procedure TMainForm.ButtonStartClick(Sender: TObject);
begin
       Panel1.Visible:=false;
       Timer1.Enabled:=True;
end;

Procedure TMainForm.ButtonInstructionsClick(Sender: TObject);
begin
        FormInstructions.Show;
end;

Procedure TMainForm.ButtonAboutClick(Sender: TObject);
begin
        FormAbout.Show;
end;

Procedure TMainForm.UserGuide1Click(Sender: TObject);
begin
        FormInstructions.Show;
end;
end.
//End of MainUnit\\
