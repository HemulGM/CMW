unit WinSrvs;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Grids, Vcl.ValEdit;

type
  TFormSrvs = class(TForm)
    EditSrv: TEdit;
    EditName: TEdit;
    Panel1: TPanel;
    Bevel1: TBevel;
    ButtonClose: TButton;
    LabelPermission: TLabel;
    ValueListEditor1: TValueListEditor;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormSrvs: TFormSrvs;

 procedure ShowService(SrvRecord:TServiceObj);

implementation
 uses COCUtils, Utils;

{$R *.dfm}

procedure ShowService(SrvRecord: TServiceObj);
const SERVICE_RUNNING = $00000004;
var
 PBuf:array[0..128] of Char;
 ID:LongWord;
 Path:string;
 //Lib:THandle;
begin
 with FormSrvs do
  begin
   ValueListEditor1.Strings.Clear;
   EditName.Text:=SrvRecord.Name;
   AddToValueEdit(ValueListEditor1, '��������', SrvRecord.Name, '����������');
   EditSrv.Text:=SrvRecord.Name;
   if Length(SrvRecord.DisplayName) > 0 then
    if SrvRecord.DisplayName[1] <> '@' then EditSrv.Text:=SrvRecord.DisplayName;
   AddToValueEdit(ValueListEditor1, '��������', SrvRecord.DisplayName, '');
   AddToValueEdit(ValueListEditor1, '�������� �����', GetFileDescription(NormFileNameF(SrvRecord.ImagePath), '/'), '');
   if SrvRecord.Status.dwCurrentState = SERVICE_RUNNING then
    AddToValueEdit(ValueListEditor1, '�� ��������', IntToStr(SrvRecord.PID), '');

   if SrvRecord.Permission then
    begin
     AddToValueEdit(ValueListEditor1, '�����', SrvRecord.ImagePath, '');
     AddToValueEdit(ValueListEditor1, '���� �� �����', SrvRecord.ObjectName, '�/�');
     AddToValueEdit(ValueListEditor1, '��� �������', SrvStartType(SrvRecord.Start), '');
     AddToValueEdit(ValueListEditor1, '������', SrvRecord.Group, '�/�');
     AddToValueEdit(ValueListEditor1, '������� ��', SrvRecord.DependOnService, '<��� ��������� ��������>');
     AddToValueEdit(ValueListEditor1, '����������', SrvRecord.RequiredPrivileges, '<��� ������ ����������>');
     AddToValueEdit(ValueListEditor1, '�������� �������', ErrorControlToStr(SrvRecord.ErrorControl), '');
     AddToValueEdit(ValueListEditor1, '��������� ��������', SrvRecord.Description, '<�������� �����������>');
     if SrvRecord.Flags <> 0 then
      begin
       AddToValueEdit(ValueListEditor1, '����', IntToStr(SrvRecord.Flags), '');
      end;
     AddToValueEdit(ValueListEditor1, 'ID ������ ��������', SrvRecord.DriverPackageId, '');
    end;
   ValueListEditor1.Height:=ValueListEditor1.Strings.Count * ValueListEditor1.RowHeights[0] + 4;
   ClientHeight:=ValueListEditor1.Top + ValueListEditor1.Height + 50;
   LabelPermission.Visible:=not SrvRecord.Permission;
   LabelPermission.Hint:=SrvRecord.RollPath;
   ShowModal;
  end;
end;

end.
