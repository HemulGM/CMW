object FormSrvs: TFormSrvs
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = #1054#1087#1080#1089#1072#1085#1080#1077' '#1089#1083#1091#1078#1073#1099
  ClientHeight = 333
  ClientWidth = 482
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  ShowHint = True
  DesignSize = (
    482
    333)
  PixelsPerInch = 96
  TextHeight = 13
  object EditSrv: TEdit
    Left = 8
    Top = 8
    Width = 457
    Height = 29
    AutoSelect = False
    AutoSize = False
    BorderStyle = bsNone
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clHotLight
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    TabOrder = 0
    Text = 'EditSrv'
  end
  object EditName: TEdit
    Left = 8
    Top = 43
    Width = 457
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
    TabOrder = 1
  end
  object Panel1: TPanel
    Left = -2
    Top = 289
    Width = 491
    Height = 50
    Anchors = [akLeft, akBottom]
    Ctl3D = True
    ParentBackground = False
    ParentCtl3D = False
    TabOrder = 2
    DesignSize = (
      491
      50)
    object Bevel1: TBevel
      Left = 1
      Top = 1
      Width = 489
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
      Left = 400
      Top = 11
      Width = 75
      Height = 25
      Anchors = [akLeft, akBottom]
      Caption = #1047#1072#1082#1088#1099#1090#1100
      ModalResult = 8
      TabOrder = 0
    end
  end
  object ValueListEditor1: TValueListEditor
    Left = 8
    Top = 67
    Width = 465
    Height = 214
    DefaultColWidth = 130
    DisplayOptions = [doAutoColResize, doKeyColFixed]
    DoubleBuffered = True
    FixedCols = 1
    Options = [goFixedVertLine, goVertLine, goColSizing, goEditing, goThumbTracking]
    ParentDoubleBuffered = False
    ScrollBars = ssVertical
    Strings.Strings = (
      '=')
    TabOrder = 3
    TitleCaptions.Strings = (
      #1055#1072#1088#1072#1084#1077#1090#1088
      #1047#1085#1072#1095#1077#1085#1080#1077)
    ColWidths = (
      130
      329)
    RowHeights = (
      18)
  end
end
