object ViewControlForm: TViewControlForm
  Left = 765
  Top = 74
  BorderStyle = bsDialog
  Caption = 'View Control'
  ClientHeight = 260
  ClientWidth = 268
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Visible = True
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 14
    Top = 10
    Width = 42
    Height = 13
    Caption = 'X Rotate'
  end
  object Label2: TLabel
    Left = 14
    Top = 59
    Width = 42
    Height = 13
    Caption = 'Y Rotate'
  end
  object Label3: TLabel
    Left = 14
    Top = 109
    Width = 42
    Height = 13
    Caption = 'Z Rotate'
  end
  object Label4: TLabel
    Left = 14
    Top = 181
    Width = 27
    Height = 13
    Caption = 'Scale'
  end
  object XRotateTrackBar: TTrackBar
    Left = 6
    Top = 26
    Width = 257
    Height = 33
    Max = 180
    Min = -180
    Orientation = trHorizontal
    Frequency = 20
    Position = 20
    SelEnd = 0
    SelStart = 0
    TabOrder = 0
    TickMarks = tmBottomRight
    TickStyle = tsAuto
    OnChange = RotateTrackBarChange
  end
  object YRotateTrackBar: TTrackBar
    Left = 6
    Top = 75
    Width = 257
    Height = 33
    Max = 180
    Min = -180
    Orientation = trHorizontal
    Frequency = 20
    Position = 0
    SelEnd = 0
    SelStart = 0
    TabOrder = 1
    TickMarks = tmBottomRight
    TickStyle = tsAuto
    OnChange = RotateTrackBarChange
  end
  object ZRotateTrackBar: TTrackBar
    Left = 6
    Top = 125
    Width = 257
    Height = 33
    Max = 180
    Min = -180
    Orientation = trHorizontal
    Frequency = 20
    Position = 0
    SelEnd = 0
    SelStart = 0
    TabOrder = 2
    TickMarks = tmBottomRight
    TickStyle = tsAuto
    OnChange = RotateTrackBarChange
  end
  object ScaleTrackBar: TTrackBar
    Left = 6
    Top = 197
    Width = 257
    Height = 33
    Max = 200
    Min = 1
    Orientation = trHorizontal
    Frequency = 10
    Position = 50
    SelEnd = 0
    SelStart = 0
    TabOrder = 3
    TickMarks = tmBottomRight
    TickStyle = tsAuto
    OnChange = RotateTrackBarChange
  end
end
