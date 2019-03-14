unit CMW.ModuleProp;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, CMW.ModuleStruct;

type
  PSystemUnit = ^TSystemUnit;
  TFormUnitProperties = class(TForm)
    LabelUnit: TLabel;
    CheckBoxGrouping: TCheckBox;
    CheckBoxIcons: TCheckBox;
    Bevel1: TBevel;
    ButtonClose: TButton;
    procedure CheckBoxIconsClick(Sender: TObject);
    procedure CheckBoxGroupingClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    SUnit:PSystemUnit;
  public
    constructor Create(SysUnit:PSystemUnit);
  end;

var
  FormUnitProperties: TFormUnitProperties;

implementation

{$R *.dfm}

procedure TFormUnitProperties.CheckBoxGroupingClick(Sender: TObject);
begin
 SUnit^.Grouping:=CheckBoxGrouping.Checked;
end;

procedure TFormUnitProperties.CheckBoxIconsClick(Sender: TObject);
begin
 SUnit^.LoadIcons:=CheckBoxIcons.Checked;
end;

constructor TFormUnitProperties.Create(SysUnit:PSystemUnit);
begin
 inherited Create(nil);
 SUnit:=SysUnit;
 LabelUnit.Caption:=SysUnit.Name;
 CheckBoxGrouping.Checked:=SysUnit.Grouping;
 CheckBoxIcons.Checked:=SysUnit.LoadIcons;
end;

procedure TFormUnitProperties.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
 Action:=caFree;
end;

procedure TFormUnitProperties.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 case Key of
  VK_ESCAPE: Close;
 end;
end;

end.
