object FormAutorun: TFormAutorun
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = #1055#1086#1076#1088#1086#1073#1085#1086#1089#1090#1080
  ClientHeight = 343
  ClientWidth = 491
  Color = clWhite
  Constraints.MinHeight = 150
  Constraints.MinWidth = 497
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PrintScale = poNone
  Scaled = False
  ShowHint = True
  OnKeyUp = FormKeyUp
  DesignSize = (
    491
    343)
  PixelsPerInch = 96
  TextHeight = 13
  object EditDisplayName: TEdit
    Left = 8
    Top = 8
    Width = 475
    Height = 29
    AutoSelect = False
    AutoSize = False
    BorderStyle = bsNone
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -19
    Font.Name = 'Segoe UI Light'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    TabOrder = 0
    Text = 'EditDisplayName'
  end
  object Panel1: TPanel
    Left = -2
    Top = 299
    Width = 501
    Height = 50
    Anchors = [akLeft, akRight, akBottom]
    Ctl3D = True
    ParentBackground = False
    ParentCtl3D = False
    TabOrder = 1
    DesignSize = (
      501
      50)
    object Bevel1: TBevel
      Left = 1
      Top = 1
      Width = 499
      Height = 10
      Align = alTop
      Shape = bsTopLine
      ExplicitLeft = -10
      ExplicitTop = 20
      ExplicitWidth = 485
    end
    object LabelPermission: TLabel
      Left = 7
      Top = 25
      Width = 335
      Height = 14
      AutoSize = False
      Caption = #1053#1077#1090' '#1076#1086#1089#1090#1091#1087#1072' '#1082' '#1074#1077#1090#1082#1077' '#1088#1077#1077#1089#1090#1088#1072' '#1089' '#1086#1087#1080#1089#1072#1085#1080#1077#1084' '#1101#1090#1086#1075#1086' '#1101#1083#1077#1084#1077#1085#1090#1072
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 204
      Font.Height = -12
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object ButtonClose: TButton
      Left = 410
      Top = 11
      Width = 75
      Height = 25
      Anchors = [akRight, akBottom]
      Caption = #1047#1072#1082#1088#1099#1090#1100
      ModalResult = 8
      TabOrder = 0
      OnClick = ButtonCloseClick
    end
  end
  object ValueListEditor1: TValueListEditor
    Left = 8
    Top = 43
    Width = 475
    Height = 248
    Anchors = [akLeft, akTop, akRight, akBottom]
    DefaultColWidth = 130
    DisplayOptions = [doAutoColResize, doKeyColFixed]
    DoubleBuffered = True
    Options = [goVertLine, goColSizing, goEditing, goThumbTracking]
    ParentDoubleBuffered = False
    ScrollBars = ssVertical
    Strings.Strings = (
      '=')
    TabOrder = 2
    TitleCaptions.Strings = (
      #1055#1072#1088#1072#1084#1077#1090#1088
      #1047#1085#1072#1095#1077#1085#1080#1077)
    ColWidths = (
      130
      339)
    RowHeights = (
      18)
  end
end
