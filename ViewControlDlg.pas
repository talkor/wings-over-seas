unit ViewControlDlg;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, MainUnit;

type
  TViewControlForm = class(TForm)
    XRotateTrackBar: TTrackBar;
    Label1: TLabel;
    YRotateTrackBar: TTrackBar;
    Label2: TLabel;
    ZRotateTrackBar: TTrackBar;
    Label3: TLabel;
    Label4: TLabel;
    ScaleTrackBar: TTrackBar;
    procedure RotateTrackBarChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ViewControlForm: TViewControlForm;

implementation

uses Mat4x4, Base3DTypes;

{$R *.DFM}

procedure TViewControlForm.RotateTrackBarChange(Sender: TObject);
var
  rx,ry,rz,tmp1,tmp2,TransMat : TMat4x4;
  smat : TMat4x4;
  ScaleFactor : real;
begin
  //Writeln(XRotateTrackBar.Position);

  SetRotationMatX(rx,Deg2Rad(XRotateTrackBar.Position));
  SetRotationMatY(ry,Deg2Rad(YRotateTrackBar.Position));
  SetRotationMatZ(rz,Deg2Rad(ZRotateTrackBar.Position));

  ScaleFactor := ScaleTrackBar.Position / 50;
  SetScaleMat(smat,ScaleFactor,ScaleFactor,ScaleFactor);

  MulMat(rx,ry,tmp1);
  MulMat(tmp1,rz,tmp2);
  MulMat(tmp2,smat,tmp1);

  SetTrans(TransMat, VIEW_X_DISTANCE, VIEW_Y_DISTANCE, VIEW_Z_DISTANCE);
  MulMat(tmp1,TransMat,tmp2);

  MainForm.ChangeViewMat(tmp2);
end;

end.
