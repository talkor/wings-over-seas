program WingsOverSeas;

uses
  Forms,
  MainUnit in 'MainUnit.pas' {MainForm},
  ViewControlDlg in 'ViewControlDlg.pas' {ViewControlForm},
  Polygon in 'Polygon.pas',
  Mat4x4 in 'Mat4x4.pas',
  Object3D in 'Object3D.pas',
  Base3DTypes in 'Base3DTypes.pas',
  RenderContext in 'RenderContext.pas',
  About in 'About.pas' {FormAbout},
  Instructions in 'Instructions.pas' {FormInstructions};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TViewControlForm, ViewControlForm);
  Application.CreateForm(TFormAbout, FormAbout);
  Application.CreateForm(TFormInstructions, FormInstructions);
  Application.Run;
end.
