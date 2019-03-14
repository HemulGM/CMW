object FormHDD: TFormHDD
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMaximize]
  Caption = #1054#1087#1080#1089#1072#1085#1080#1077' '#1072#1090#1088#1080#1073#1091#1090#1072
  ClientHeight = 362
  ClientWidth = 569
  Color = clBtnFace
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
    569
    362)
  PixelsPerInch = 96
  TextHeight = 13
  object MemoDesc: TMemo
    Left = 8
    Top = 39
    Width = 553
    Height = 314
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    Font.Quality = fqClearType
    ParentFont = False
    ParentShowHint = False
    ReadOnly = True
    ScrollBars = ssVertical
    ShowHint = False
    TabOrder = 0
    Visible = False
  end
  object RichEditDesc: TRichEdit
    Left = 8
    Top = 39
    Width = 553
    Height = 315
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
    Zoom = 100
  end
  object LabelAttr: TEdit
    Left = 8
    Top = 6
    Width = 553
    Height = 30
    Anchors = [akLeft, akTop, akRight]
    BorderStyle = bsNone
    Color = clBtnFace
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -19
    Font.Name = 'Segoe UI Light'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    Text = 'LabelAttr'
  end
end
