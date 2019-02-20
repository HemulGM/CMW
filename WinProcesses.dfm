object FormProcess: TFormProcess
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = #1055#1086#1076#1088#1086#1073#1085#1086#1089#1090#1080
  ClientHeight = 356
  ClientWidth = 482
  Color = clWindow
  Constraints.MinHeight = 70
  Constraints.MinWidth = 465
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PrintScale = poNone
  Scaled = False
  OnKeyUp = FormKeyUp
  DesignSize = (
    482
    356)
  PixelsPerInch = 96
  TextHeight = 13
  object ValueListEditorProc: TValueListEditor
    Left = 8
    Top = 67
    Width = 465
    Height = 231
    Anchors = [akLeft, akTop, akRight, akBottom]
    DisplayOptions = [doAutoColResize, doKeyColFixed]
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goEditing, goThumbTracking]
    TabOrder = 0
    TitleCaptions.Strings = (
      #1069#1083#1077#1084#1077#1085#1090
      #1047#1085#1072#1095#1077#1085#1080#1077)
    ColWidths = (
      150
      309)
  end
  object EditProcDesc: TEdit
    Left = 8
    Top = 8
    Width = 465
    Height = 26
    BorderStyle = bsNone
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -19
    Font.Name = 'Segoe UI Light'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    Text = #1054#1087#1080#1089#1072#1085#1080#1077' '#1092#1072#1081#1083#1072
  end
  object Panel1: TPanel
    Left = 0
    Top = 308
    Width = 483
    Height = 50
    Anchors = [akLeft, akRight, akBottom]
    Ctl3D = True
    ParentBackground = False
    ParentCtl3D = False
    TabOrder = 2
    DesignSize = (
      483
      50)
    object Bevel1: TBevel
      Left = 1
      Top = 1
      Width = 481
      Height = 10
      Align = alTop
      Shape = bsTopLine
      ExplicitLeft = 10
      ExplicitTop = 42
      ExplicitWidth = 366
    end
    object ButtonClose: TButton
      Left = 392
      Top = 11
      Width = 75
      Height = 25
      Anchors = [akRight, akBottom]
      Caption = #1047#1072#1082#1088#1099#1090#1100
      ModalResult = 8
      TabOrder = 0
      OnClick = ButtonCloseClick
      ExplicitLeft = 359
    end
  end
  object EditProcName: TEdit
    Left = 8
    Top = 43
    Width = 465
    Height = 17
    AutoSelect = False
    AutoSize = False
    BorderStyle = bsNone
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    TabOrder = 3
    Text = '722:winlogon.exe'
  end
end
