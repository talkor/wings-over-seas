unit Instructions;
{This unit shows the game's instructions}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls;

type
  TFormInstructions = class(TForm)
    LabelGameInstructions: TLabel;
    ScrollBox1: TScrollBox;
    ImageInstructions: TImage;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormInstructions: TFormInstructions;

implementation

{$R *.DFM}

end.
