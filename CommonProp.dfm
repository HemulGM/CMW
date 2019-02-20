object FormUnitProperties: TFormUnitProperties
  Left = 0
  Top = 0
  Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1080' '#1086#1090#1086#1073#1088#1072#1078#1077#1085#1080#1103
  ClientHeight = 241
  ClientWidth = 272
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PrintScale = poNone
  Scaled = False
  OnClose = FormClose
  OnKeyUp = FormKeyUp
  DesignSize = (
    272
    241)
  PixelsPerInch = 96
  TextHeight = 13
  object LabelUnit: TLabel
    Left = 8
    Top = 8
    Width = 256
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 'LabelUnit'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -19
    Font.Name = 'Segoe UI Light'
    Font.Pitch = fpVariable
    Font.Style = []
    ParentFont = False
    ExplicitWidth = 431
  end
  object Bevel1: TBevel
    Left = -5
    Top = 193
    Width = 283
    Height = 9
    Anchors = [akLeft, akRight, akBottom]
    Shape = bsTopLine
    ExplicitTop = 186
  end
  object CheckBoxGrouping: TCheckBox
    Left = 16
    Top = 48
    Width = 145
    Height = 17
    Caption = #1043#1088#1091#1087#1087#1080#1088#1086#1074#1072#1090#1100' '#1101#1083#1077#1084#1077#1085#1090#1099
    TabOrder = 0
    OnClick = CheckBoxGroupingClick
  end
  object CheckBoxIcons: TCheckBox
    Left = 16
    Top = 71
    Width = 145
    Height = 17
    Caption = #1055#1086#1076#1075#1088#1091#1078#1072#1090#1100' '#1080#1082#1086#1085#1082#1080
    TabOrder = 1
    OnClick = CheckBoxIconsClick
  end
  object ButtonClose: TButton
    Left = 189
    Top = 204
    Width = 75
    Height = 29
    Anchors = [akLeft, akRight, akBottom]
    Caption = #1047#1072#1082#1088#1099#1090#1100
    ModalResult = 1
    TabOrder = 2
  end
end
