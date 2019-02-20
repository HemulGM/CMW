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
   AddToValueEdit(ValueListEditor1, 'Название', SrvRecord.Name, 'Неизвестно');
   EditSrv.Text:=SrvRecord.Name;
   if Length(SrvRecord.DisplayName) > 0 then
    if SrvRecord.DisplayName[1] <> '@' then EditSrv.Text:=SrvRecord.DisplayName;
   AddToValueEdit(ValueListEditor1, 'Описание', SrvRecord.DisplayName, '');
   AddToValueEdit(ValueListEditor1, 'Описание файла', GetFileDescription(NormFileNameF(SrvRecord.ImagePath), '/'), '');
   if SrvRecord.Status.dwCurrentState = SERVICE_RUNNING then
    AddToValueEdit(ValueListEditor1, 'ИД процесса', IntToStr(SrvRecord.PID), '');

   if SrvRecord.Permission then
    begin
     AddToValueEdit(ValueListEditor1, 'Образ', SrvRecord.ImagePath, '');
     AddToValueEdit(ValueListEditor1, 'Вход от имени', SrvRecord.ObjectName, 'Н/Д');
     AddToValueEdit(ValueListEditor1, 'Тип запуска', SrvStartType(SrvRecord.Start), '');
     AddToValueEdit(ValueListEditor1, 'Группа', SrvRecord.Group, 'Н/Д');
     AddToValueEdit(ValueListEditor1, 'Зависит от', SrvRecord.DependOnService, '<нет зависимых сервисов>');
     AddToValueEdit(ValueListEditor1, 'Привелегии', SrvRecord.RequiredPrivileges, '<нет особых привелегий>');
     AddToValueEdit(ValueListEditor1, 'Контроль оошибок', ErrorControlToStr(SrvRecord.ErrorControl), '');
     AddToValueEdit(ValueListEditor1, 'Подробное описание', SrvRecord.Description, '<Описание отсутствует>');
     if SrvRecord.Flags <> 0 then
      begin
       AddToValueEdit(ValueListEditor1, 'Флаг', IntToStr(SrvRecord.Flags), '');
      end;
     AddToValueEdit(ValueListEditor1, 'ID пакета драйвера', SrvRecord.DriverPackageId, '');
    end;
   ValueListEditor1.Height:=ValueListEditor1.Strings.Count * ValueListEditor1.RowHeights[0] + 4;
   ClientHeight:=ValueListEditor1.Top + ValueListEditor1.Height + 50;
   LabelPermission.Visible:=not SrvRecord.Permission;
   LabelPermission.Hint:=SrvRecord.RollPath;
   ShowModal;
  end;
end;

end.
