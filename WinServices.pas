unit WinServices;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Win.Registry, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ImgList,
  Winapi.WinSvc, Vcl.ExtCtrls, Vcl.ValEdit,
  //Мои модули
  StructUnit, COCUtils, Utils, Vcl.Grids
  ;

type
  TFormService = class(TForm)
    EditSrv: TEdit;
    EditName: TEdit;
    Panel1: TPanel;
    Bevel1: TBevel;
    ButtonClose: TButton;
    LabelPermission: TLabel;
    ValueListEditor1: TValueListEditor;
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
   private
   public
  end;

  TServiceObjParameters = record
   ServiceDll:string;
   ServiceDllUnloadOnStop:Integer;
  end;
  TServiceConfig = record
   ServiceType:Integer;
   StartType:Integer;
   dwErrorControl:Integer;
   BinaryPathName:string;
   LoadOrderGroup:string;
   TagId:Integer;
   Dependencies:string;
   ServiceStartName:string;
   lpDisplayName:string;
  end;

  PServiceObj = ^TServiceObj;
  TServiceObj = record
   Name:string;
   Start:Integer;
   DisplayName:string;
   Group:string;
   ImagePath:string;
   Cmd:string;
   Description:string;
   ObjectName:string;
   ErrorControl:Integer;
   SrvType:Integer;
   DependOnService:string;
   DriverPackageId:string;
   WOW64:Boolean;
   DelayedStart:Boolean;
   ServiceSidType:Integer;
   RequiredPrivileges:string;
   FailureActions:string;
   Parameters:TServiceObjParameters;
   PID:Cardinal;
   Flags:Cardinal;
   Permission:Boolean;
   RollKEY:HKEY;
   RollPath:string;
   Status:SERVICE_STATUS_PROCESS;
   Config:TServiceConfig;
  end;

  TServiceStatusProcess = ENUM_SERVICE_STATUS_PROCESS;
  TRegLoadMUIStringFunc = function(RegKey: HKEY;
                          pszValue: PWideChar;
                          pszOutBuf: PWideChar;
                          cbOutBuf: DWORD;
                          pcbData: LPDWORD;
                          Flags: DWORD;
                          pszDirectory: PWideChar):LongInt; stdcall;

  TServiceStatusProcessList = array of TServiceStatusProcess;

  TServicesUnit = class(TSystemUnit)
    function FGet:TGlobalState; override;
   private
    FServiceMode,
    FServiceStatus:Integer;
    FSrvIcon:TIcon;
    FDrvIcon:TIcon;
    function GetSelected:TListItem;
    procedure ShowService(SrvRecord: TServiceObj);
    procedure ListViewDblClick(Sender: TObject);
    function GetSrvDesc(SCManager:SC_HANDLE; Srv:TServiceStatusProcess):TServiceObj;
    function SrvExists(SrvName:string):Boolean;
    function DeleteSrvWithAPI(SrvName:string):Boolean;
    function DeleteSrvWithCMD(SrvName:string):Boolean;
   public
    procedure SetListView(Value:TListView); override;
    function StopSrv(SrvRecord: TListItem):Integer; overload;
    function StopSrv(SCManagerHandle:THandle; SrvName:string):Integer; overload;
    function StartSrv(SrvRecord:TListItem):Integer;
    function DeleteSrv(SrvRecord:TListItem):Integer;
    procedure OnChanged; override;
    procedure ShowSelected;
    procedure Select(PID:integer);
    procedure Initialize; override;
    procedure OpenFolderBinSelSrv;
    procedure OpenFolderDllSelSrv;
    procedure Stop; override;
    constructor Create; override;
    destructor Destroy; override;
    procedure SrvSTAuto;
    procedure SrvSTBoot;
    procedure SrvSTSys;
    procedure SrvSTAutoDelayed;
    procedure SrvSTDemand;
    procedure SrvSTDisable;
    procedure UpdateServiceListState(Snapshot:TServiceStatusProcessList);
    function ServiceControl(ServiceName:String; ServiceControlCode:DWORD):TServiceStatus;
    property SelectedItem:TListItem read GetSelected;
    property SrvIcon:TIcon read FSrvIcon write FSrvIcon;
    property DrvIcon:TIcon read FDrvIcon write FDrvIcon;
    property ServiceMode:Integer read FServiceMode write FServiceMode default SERVICE_WIN32 or SERVICE_DRIVER;
    property ServiceStatus:Integer read FServiceStatus write FServiceStatus default SERVICE_ACTIVE or SERVICE_INACTIVE;
  end;

const SERVICE_RUNNING = $00000004;

const
   DRIVER_INFORMATION = 11;


var
  hAdvAPI32:HMODULE;
  FormService:TFormService;
  RegLoadMUIString:TRegLoadMUIStringFunc;

 function SrvStartType(StartType:Integer; Delayed:Boolean):string;
 function ErrorControlToStr(EC:Integer):string;
 function SrvStateStr(dwCS:DWORD):string;
 function XPRegLoadMUIString(RegKey: HKEY;
                          pszValue: PWideChar;
                          pszOutBuf: PWideChar;
                          cbOutBuf: DWORD;
                          pcbData: LPDWORD;
                          Flags: DWORD;
                          pszDirectory: PWideChar):LongInt;
 function GetDriverInfo: string;
 function ServiceStop(SrvName: string):Integer;
 function ServiceStart(SrvName: string):Integer;
 function ServiceIsWorking(SrvName: string):Boolean;
 function SetSrvStartType(SrvName:string; StartType:Integer; DelayedAS:Boolean):Boolean; overload;
 function SetSrvStartType(SrvName:string; StartType:Integer):Boolean; overload;

implementation
 uses NativeAPI;

{$R *.dfm}

function SetSrvStartType(SrvName:string; StartType:Integer):Boolean;
begin
 Result:=SetSrvStartType(SrvName, StartType, False);
end;

function SetSrvStartType(SrvName:string; StartType:Integer; DelayedAS:Boolean):Boolean;
var FRoot:TRegistry;
begin
 Result:=False;
 FRoot:=TRegistry.Create(KEY_WRITE);
 FRoot.RootKey:=HKEY_LOCAL_MACHINE;
 SrvName:='SYSTEM\CurrentControlSet\services\'+SrvName;
 try
  begin
   if FRoot.OpenKey(SrvName, False) then
    begin
     FRoot.WriteInteger('Start', StartType);
     FRoot.WriteInteger('DelayedAutoStart', Integer(DelayedAS));
    end;
  end;
 except
  CreateMessage('Не смог изменить тип загрузки службы', mlError);
 end;
 FRoot.Free;
end;

function ServiceIsWorking(SrvName: string):Boolean; //SERVICE_RUNNING
var SCManagerHandle:THandle;
    scService:THandle;
    Status:TServiceStatus;
begin
 Result:=False;
 SCManagerHandle:=OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
 if SCManagerHandle = 0 then
  begin
   Log(['Нет доступа к менуджеру служб.']);
   Exit(False);
  end;
 scService:=OpenService(SCManagerHandle, PWideChar(SrvName), SERVICE_QUERY_STATUS); //SERVICE_STOP
 if scService = 0 then
  begin
   Log(['Нет доступа к выбранной службе.']);
   CloseServiceHandle(SCManagerHandle);
   Exit(False);
  end;
 try
  if (not QueryServiceStatus(scService, Status)) then
   begin
    Log(['Немогу получить доступ к службе', SrvName]);
    Exit(False);
   end
  else Result:=Status.dwCurrentState = SERVICE_RUNNING;
 finally
  begin
   CloseServiceHandle(SCManagerHandle);
   CloseServiceHandle(scService);
  end;
 end;
end;

function ServiceStart(SrvName: string):Integer;
var SCManagerHandle:THandle;
    scService:THandle;
    Status:TServiceStatus;
    Arg:PChar;
begin
 Result:=0;
 SCManagerHandle:=OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
 if SCManagerHandle = 0 then
  begin
   Log(['Нет доступа к менуджеру служб.']);
   Exit(1);
  end;
 scService:=OpenService(SCManagerHandle, PWideChar(SrvName), SERVICE_ALL_ACCESS); //SERVICE_STOP
 if scService = 0 then
  begin
   Log(['Нет доступа к выбранной службе.']);
   CloseServiceHandle(SCManagerHandle);
   Exit(2);
  end;
 try
  if not StartService(scService, 0, Arg) then
   begin
    Log(['Немогу запустить службу', SrvName]);
    Exit(4);
   end;
  if (not QueryServiceStatus(scService, Status)) then
   begin
    Log(['Немогу получить доступ к службе', SrvName]);
    Exit(5);
   end;
 finally
  begin
   CloseServiceHandle(SCManagerHandle);
   CloseServiceHandle(scService);
  end;
 end;
end;

function ServiceStop(SrvName: string):Integer;
var SCManagerHandle:THandle;
    scService:THandle;
    Status:TServiceStatus;
begin
 Result:=0;
 SCManagerHandle:=OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
 if SCManagerHandle = 0 then
  begin
   Log(['Нет доступа к выбранной службе.']);
   Exit(1);
  end;
 scService:=OpenService(SCManagerHandle, PWideChar(SrvName), SERVICE_ALL_ACCESS); //SERVICE_STOP
 if scService = 0 then
  begin
   Log(['Нет доступа к выбранной службе.']);
   CloseServiceHandle(SCManagerHandle);
   Exit(2);
  end;
 try
  if not ControlService(scService, SERVICE_CONTROL_STOP, Status) then
   begin
    Log(['Немогу остановить службу', SrvName]);
    Exit(4);
   end;
 finally
  begin
   CloseServiceHandle(scService);
   CloseServiceHandle(SCManagerHandle);
  end;
 end;
end;

function GetDriverInfo: string;
var
 mSize: dword;
 mPtr: PSYSTEM_MODULE_INFORMATION_EX;
 St: NTStatus;
begin
 mSize := $4000; //ia?aeuiue ?acia? aoooa?a
 repeat
   mPtr := VirtualAlloc(nil, mSize, MEM_COMMIT or MEM_RESERVE, PAGE_READWRITE);
   if mPtr = nil then Exit;
   St := ZwQuerySystemInformation(SystemModuleInformation, mPtr, mSize, nil);
   if St = STATUS_INFO_LENGTH_MISMATCH then
      begin //iaai aieuoa iaiyoe
        VirtualFree(mPtr, 0, MEM_RELEASE);
        mSize := mSize * 2;
      end;
 until St <> STATUS_INFO_LENGTH_MISMATCH;
 if St = STATUS_SUCCESS
   then
    begin
     //ShowMessage(IntToStr(mPtr.ModulesCount));
     //for i:=0 to mPtr.ModulesCount-1 do
      begin
       Result:=Result+#13#10+StrPas(mPtr.Modules[0].ImageName);
      end;
     Exit;
    end
   else VirtualFree(mPtr, 0, MEM_RELEASE);
end;

procedure TServicesUnit.SrvSTAuto;
begin
 if FListView.Selected = nil then Exit;
 if FListView.Selected.Data = nil then Exit;
 SetSrvStartType(TServiceObj(FListView.Selected.Data^).Name, SERVICE_AUTO_START, False);
end;

procedure TServicesUnit.SrvSTBoot;
begin
 if FListView.Selected = nil then Exit;
 if FListView.Selected.Data = nil then Exit;
 SetSrvStartType(TServiceObj(FListView.Selected.Data^).Name, SERVICE_BOOT_START, False);
end;

procedure TServicesUnit.SrvSTSys;
begin
 if FListView.Selected = nil then Exit;
 if FListView.Selected.Data = nil then Exit;
 SetSrvStartType(TServiceObj(FListView.Selected.Data^).Name, SERVICE_SYSTEM_START, False);
end;

procedure TServicesUnit.SrvSTAutoDelayed;
begin
 if FListView.Selected = nil then Exit;
 if FListView.Selected.Data = nil then Exit;
 SetSrvStartType(TServiceObj(FListView.Selected.Data^).Name, SERVICE_AUTO_START, True);
end;

procedure TServicesUnit.SrvSTDemand;
begin
 if FListView.Selected = nil then Exit;
 if FListView.Selected.Data = nil then Exit;
 SetSrvStartType(TServiceObj(FListView.Selected.Data^).Name, SERVICE_DEMAND_START, False);
end;

procedure TServicesUnit.SrvSTDisable;
begin
 if FListView.Selected = nil then Exit;
 if FListView.Selected.Data = nil then Exit;
 SetSrvStartType(TServiceObj(FListView.Selected.Data^).Name, SERVICE_DISABLED, False);
end;


procedure TServicesUnit.OpenFolderDllSelSrv;
var Str:string;
begin
 if FListView.Selected = nil then Exit;
 if FListView.Selected.Data = nil then Exit;
 Str:=NormFileNameF(TServiceObj(FListView.Selected.Data^).Parameters.ServiceDll);
 if not FileExists(Str) then
  begin
   Log(['Не смог обнаружить файл:', Str]);
   MessageBox(Application.Handle, PChar('Не смог обнаружить файл: "'+Str+'"'), 'Внимание', MB_OK or MB_ICONWARNING);
   Exit;
  end;
 OpenFolderAndSelectFile(Str);
end;

procedure TServicesUnit.OpenFolderBinSelSrv;
var Str:string;
begin
 if FListView.Selected = nil then Exit;
 if FListView.Selected.Data = nil then Exit;
 Str:=NormFileNameF(TServiceObj(FListView.Selected.Data^).Config.BinaryPathName);
 if not FileExists(Str) then
  begin
   Log(['Не смог обнаружить файл:', Str]);
   MessageBox(Application.Handle, PChar('Не смог обнаружить файл: "'+Str+'"'), 'Внимание', MB_OK or MB_ICONWARNING);
   Exit;
  end;
 OpenFolderAndSelectFile(Str);
end;

function TServicesUnit.GetSelected:TListItem;
begin
 Result:=nil;
 if not Assigned(FListView) then Exit;
 Result:=FListView.Selected;
end;

procedure TServicesUnit.SetListView(Value:TListView);
begin
 inherited;
 FListView.OnDblClick:=ListViewDblClick;
end;

procedure TServicesUnit.ListViewDblClick(Sender: TObject);
begin
 ShowSelected;
end;

procedure TServicesUnit.ShowService(SrvRecord: TServiceObj);
begin
 with FormService do
  begin
   ValueListEditor1.Strings.Clear;
   EditName.Text:=SrvRecord.Name;
   EditSrv.Text:=SrvRecord.Name;
   if Length(SrvRecord.DisplayName) > 0 then
    if SrvRecord.DisplayName[1] <> '@' then
    EditSrv.Text:=SrvRecord.DisplayName;

   AddToValueEdit(ValueListEditor1, 'Название', SrvRecord.Name, 'Неизвестно');
   AddToValueEdit(ValueListEditor1, 'Отображаемое имя', SrvRecord.DisplayName, '');
   AddToValueEdit(ValueListEditor1, 'Описание файла', GetFileDescription(NormFileNameF(SrvRecord.ImagePath), '/'), '');
   if SrvRecord.Status.dwCurrentState = SERVICE_RUNNING then
    AddToValueEdit(ValueListEditor1, 'ИД процесса', IntToStr(SrvRecord.PID), '');
   AddToValueEdit(ValueListEditor1, 'Исполнительный файл', SrvRecord.Config.BinaryPathName, '');
   AddToValueEdit(ValueListEditor1, 'Командная строка', SrvRecord.Cmd, '');
   if SrvRecord.Permission then
    begin
     AddToValueEdit(ValueListEditor1, 'Подгружаемая библиотека', SrvRecord.Parameters.ServiceDll, '');
     AddToValueEdit(ValueListEditor1, 'Подробное описание', SrvRecord.Description, '<описание отсутствует>');
     AddToValueEdit(ValueListEditor1, 'Тип запуска', SrvStartType(SrvRecord.Start, SrvRecord.DelayedStart), '');
     AddToValueEdit(ValueListEditor1, 'Зависимости', SrvRecord.DependOnService, '<нет зависимых сервисов>');
     AddToValueEdit(ValueListEditor1, 'Привелегии', SrvRecord.RequiredPrivileges, '<нет особых привелегий>');
     //AddToValueEdit(ValueListEditor1, 'Образ', SrvRecord.ImagePath, '');
     AddToValueEdit(ValueListEditor1, 'Вход от имени', SrvRecord.ObjectName, 'Н/Д');
     AddToValueEdit(ValueListEditor1, 'Группа', SrvRecord.Group, 'Н/Д');
     AddToValueEdit(ValueListEditor1, 'ID пакета драйвера', SrvRecord.DriverPackageId, '');
     AddToValueEdit(ValueListEditor1, 'Контроль ошибок', ErrorControlToStr(SrvRecord.ErrorControl), '');
     AddToValueEdit(ValueListEditor1, 'Выгрузка Dll после остановки', BoolStr(Boolean(SrvRecord.Parameters.ServiceDllUnloadOnStop)), '');
     if SrvRecord.Flags <> 0 then
      begin
       AddToValueEdit(ValueListEditor1, 'Флаг', IntToStr(SrvRecord.Flags), '');
      end;
     AddToValueEdit(ValueListEditor1, 'WOW64', BoolStr(SrvRecord.WOW64, 'Да', 'Нет'), '');
     AddToValueEdit(ValueListEditor1, 'Отложенный запуск', BoolStr(SrvRecord.DelayedStart, 'Да', 'Нет'), '');
    end;
   ValueListEditor1.Height:=ValueListEditor1.Strings.Count * ValueListEditor1.RowHeights[0] + 4;
   ClientHeight:=ValueListEditor1.Top + ValueListEditor1.Height + 50;
   LabelPermission.Visible:=not SrvRecord.Permission;
   LabelPermission.Hint:=SrvRecord.RollPath;
   ShowModal;
  end;
end;

procedure TServicesUnit.ShowSelected;
var MPos:TPoint;
    SrvObj:TServiceObj;
begin
 if ListView.ItemFocused = nil then Exit;
 if ListView.Selected = nil then Exit;
 MPos:=ListView.ScreenToClient(Mouse.CursorPos);
 if (ListView.GetItemAt(MPos.X, MPos.Y) <> nil)                        //Если под курсором запись
 then
  begin
   SrvObj:=TServiceObj(ListView.Selected.Data^);
   ShowService(SrvObj);
  end;
end;

function TServicesUnit.SrvExists(SrvName:string):Boolean;
var SCManagerHandle:THandle;
    scService:THandle;
begin
 SCManagerHandle:=OpenSCManager(nil, nil, SC_MANAGER_ENUMERATE_SERVICE);
 if SCManagerHandle = 0 then
  begin
   Log(['Нет доступа к менуджеру служб.']);
   Exit(False);
  end;
 scService:=OpenService(SCManagerHandle, PWideChar(SrvName), SERVICE_QUERY_STATUS);
 Result:=scService <> 0;
 CloseServiceHandle(scService);
 CloseServiceHandle(SCManagerHandle);
end;

function TServicesUnit.StopSrv(SCManagerHandle:THandle; SrvName:string):Integer;
var scService:THandle;
    Status:TServiceStatus;
begin
 Result:=0;
 if SCManagerHandle = 0 then
  begin
   Log(['Нет доступа к выбранной службе.']);
   Exit(1);
  end;
 scService:=OpenService(SCManagerHandle, PWideChar(SrvName), SERVICE_ALL_ACCESS); //SERVICE_STOP
 if scService = 0 then
  begin
   Log(['Нет доступа к выбранной службе.']);
   CloseServiceHandle(SCManagerHandle);
   Exit(2);
  end;
 try
  if not ControlService(scService, SERVICE_CONTROL_STOP, Status) then
   begin
    Log(['Немогу остановить службу', SrvName]);
    Exit(4);
   end;
 finally
  begin
   CloseServiceHandle(scService);
   CloseServiceHandle(SCManagerHandle);
  end;
 end;
end;

function TServicesUnit.StopSrv(SrvRecord: TListItem):Integer;
var SCManagerHandle:THandle;
    scService:THandle;
    Status:TServiceStatus;
    SrvName:string;
begin
 Result:=0;
 SCManagerHandle:=OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
 if SCManagerHandle = 0 then
  begin
   Log(['Нет доступа к выбранной службе.']);
   Exit(1);
  end;
 try
  SrvName:=TServiceObj(SrvRecord.Data^).Name;
 except
  begin
   Log(['Внутренняя ошибка при идентийикации записи службы.']);
   CloseServiceHandle(SCManagerHandle);
   Exit(3);
  end;
 end;
 scService:=OpenService(SCManagerHandle, PWideChar(SrvName), SERVICE_ALL_ACCESS); //SERVICE_STOP
 if scService = 0 then
  begin
   Log(['Нет доступа к выбранной службе.']);
   CloseServiceHandle(SCManagerHandle);
   Exit(2);
  end;
 try
  if not ControlService(scService, SERVICE_CONTROL_STOP, Status) then
   begin
    Log(['Немогу остановить службу', SrvName]);
    Exit(4);
   end
  else
   begin
    if Status.dwCurrentState <> SERVICE_STOPPED then
     SrvRecord.SubItems[0]:='0'//IntToStr(Status.dwProcessId)
    else SrvRecord.SubItems[0]:='';
    TServiceObj(SrvRecord.Data^).Status.dwCurrentState:=Status.dwCurrentState;
    SrvRecord.SubItems[1]:=SrvStateStr(Status.dwCurrentState);
   end;
 finally
  begin
   CloseServiceHandle(scService);
   CloseServiceHandle(SCManagerHandle);
  end;
 end;
end;

function SrvIsStopped(SCManagerHandle:THandle; SrvName:string):Boolean;
var scService:THandle;
    Status:TServiceStatus;
begin
 Result:=True;
 if SCManagerHandle <> 0 then
  begin
   scService:=OpenService(SCManagerHandle, PWideChar(SrvName), SERVICE_QUERY_STATUS);
   if scService <> 0 then
    begin
     if QueryServiceStatus(scService, Status) then Result:=Status.dwCurrentState = SERVICE_STOPPED;
    end;
  end;
end;

function TServicesUnit.DeleteSrvWithAPI(SrvName:string):Boolean;
var SCManagerHandle:THandle;
    scService:THandle;
    Status:TServiceStatus;
begin
 Result:=False;
 SCManagerHandle:=OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
 if SCManagerHandle <> 0 then
  begin
   scService:=OpenService(SCManagerHandle, PWideChar(SrvName), SERVICE_ALL_ACCESS); //SERVICE_STOP
   if scService <> 0 then
    begin
     if SrvIsStopped(SCManagerHandle, SrvName) or ControlService(scService, SERVICE_CONTROL_STOP, Status) then
      begin
       if DeleteService(scService) then Result:=True
       else Log(['Не могу удалить службу', SrvName]);
      end
     else Log(['Не могу остановить службу', SrvName]);
     CloseServiceHandle(scService);
    end
   else Log(['Нет доступа к выбранной службе.']);
   CloseServiceHandle(SCManagerHandle);
  end
 else Log(['Нет доступа к выбранной службе.']);
end;

function TServicesUnit.DeleteSrvWithCMD(SrvName:string):Boolean;
var SCManagerHandle:THandle;
    scService:THandle;
    Status:TServiceStatus;
begin
 Result:=False;
 SCManagerHandle:=OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
 if SrvIsStopped(SCManagerHandle, SrvName) or (StopSrv(SCManagerHandle, SrvName) = 0) then
  begin
   if ProcessMonitor.Execute('sc delete "'+SrvName+'"') then
    begin
     Sleep(1000);
     if SrvExists(SrvName) then
      begin
       Log(['Не смог удалить службу. Служба всё ещё существует.']);
      end
     else Result:=True;
    end
   else Log(['Несмог выполнить команду удаления службы.']);
  end
 else Log(['Не могу остановить службу', SrvName]);
end;

function TServicesUnit.DeleteSrv(SrvRecord:TListItem):Integer;
var SrvName:string;
begin
 Result:=0;
 SrvName:=SrvRecord.Caption;
 if MessageBox(Application.Handle, PWideChar('Удалить службу "'+SrvName+'"?'), 'Вопрос', MB_YESNO or MB_ICONQUESTION) <> ID_YES then Exit;
 Log(['Удаление службы:', SrvName]);
 if DeleteSrvWithAPI(SrvName) or DeleteSrvWithCMD(SrvName) then SrvRecord.Delete
 else Result:=2;
end;

function TServicesUnit.StartSrv(SrvRecord: TListItem):Integer;
var SCManagerHandle:THandle;
    scService:THandle;
    SrvName:string;
    Status:TServiceStatus;
    Arg:PChar;
begin
 Result:=0;
 SCManagerHandle:=OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
 if SCManagerHandle = 0 then
  begin
   Log(['Нет доступа к менуджеру служб.']);
   Exit(1);
  end;
 try
  SrvName:=TServiceObj(SrvRecord.Data^).Name;
 except
  begin
   Log(['Внутренняя ошибка при идентийикации записи службы.']);
   CloseServiceHandle(SCManagerHandle);
   Exit(3);
  end;
 end;
 scService:=OpenService(SCManagerHandle, PWideChar(SrvName), SERVICE_ALL_ACCESS); //SERVICE_STOP
 if scService = 0 then
  begin
   Log(['Нет доступа к выбранной службе.']);
   CloseServiceHandle(SCManagerHandle);
   Exit(2);
  end;
 try
  if not StartService(scService, 0, Arg) then
   begin
    Log(['Немогу запустить службу', SrvName]);
    Exit(4);
   end;
  if (not QueryServiceStatus(scService, Status)) then
   begin
    Log(['Немогу получить доступ к службе', SrvName]);
    Exit(5);
   end
  else
   begin
    if Status.dwCurrentState <> SERVICE_STOPPED then
     SrvRecord.SubItems[0]:='0'//IntToStr(Status.dwProcessId)
    else SrvRecord.SubItems[0]:='';
    TServiceObj(SrvRecord.Data^).Status.dwCurrentState:=Status.dwCurrentState;
    SrvRecord.SubItems[1]:=SrvStateStr(Status.dwCurrentState);
   end;
 finally
  begin
   CloseServiceHandle(SCManagerHandle);
   CloseServiceHandle(scService);
  end;
 end;
end;

procedure TServicesUnit.OnChanged;
begin
 inherited;
 OnListViewSort;
end;

procedure TServicesUnit.Stop;
begin
 inherited;
end;

function TServicesUnit.FGet:TGlobalState;
var //DI:Integer;
    IconN:TIcon;

    SCManagerHandle:THandle;
    lpServices:TServiceStatusProcessList;
    pcbBytesNeeded, lpServicesReturned, lpResumeHandle:DWORD;
    i:integer;
    ServiceType:string;
    LI:TListItem;
    SrvObj:TServiceObj;
    PSrv:PServiceObj;
    IconName:string;
    WillLoadIco:Boolean;
begin
 Inform(LangText(-1, 'Получение списка служб Windows...'));
 Result:=gsProcess;
 WillLoadIco:=False;
 //ShowMessage(GetDriverInfo);
 FListView.Items.Clear;
 FListView.Groups.Clear;
 FListView.GroupView:=True;
 FListView.Checkboxes:=True;
 //ListView.Columns.Clear;
 FListView.ViewStyle:=vsReport;

 if FListView.SmallImages <> nil then FListView.SmallImages.Clear
 else
  begin
   FListView.SmallImages:=TImageList.CreateSize(16, 16);
   FListView.SmallImages.ColorDepth:=cd32Bit;
  end;
 Log([FListView.SmallImages.AddIcon(FSrvIcon)]);
 Log([FListView.SmallImages.AddIcon(FDrvIcon)]);

 //-------


 Roll.RootKey:=HKEY_LOCAL_MACHINE;
 // 1. Подключениемся к менеджеру сервисов
 SCManagerHandle:=OpenSCManager(nil, nil, GENERIC_READ);
 if SCManagerHandle = 0 then
  begin
   Log(['Не смог получить доступ к службам. SCManagerHandle = 0']);
   Exit(gsError);
  end;

 {case rgServiceMode of
  0: ServiceMode:=SERVICE_WIN32;
  1: ServiceMode:=SERVICE_DRIVER;
  2: ServiceMode:=SERVICE_WIN32 or SERVICE_DRIVER;
 end;
 case rgServiceStatus of
  0: ServiceStatus:=SERVICE_ACTIVE;
  1: ServiceStatus:=SERVICE_INACTIVE;
  2: ServiceStatus:=SERVICE_ACTIVE or SERVICE_INACTIVE;
 end;       }
 try
  EnumServicesStatusExW(SCManagerHandle, SC_ENUM_PROCESS_INFO, FServiceMode, FServiceStatus,
                        nil, 0, @pcbBytesNeeded, @lpServicesReturned, nil, nil);
                        SetLength(lpServices, pcbBytesNeeded div SizeOf(ENUM_SERVICE_STATUS_PROCESS));
  lpResumeHandle:=0;
  EnumServicesStatusExW(SCManagerHandle, SC_ENUM_PROCESS_INFO, FServiceMode, FServiceStatus,
                        @lpServices[0], Length(lpServices) * SizeOf(ENUM_SERVICE_STATUS_PROCESS),
                        @pcbBytesNeeded, @lpServicesReturned, @lpResumeHandle, nil);
 except
  Exit;
 end;

 if Length(lpServices) > 0 then
 for i:=0 to lpServicesReturned - 1 do
  begin
   LI:=ListView.Items.Add;
   LI.Caption:=lpServices[i].lpServiceName;


   SrvObj:=GetSrvDesc(SCManagerHandle, lpServices[i]);
   {if Length(SrvObj.DisplayName) > 0 then
    if SrvObj.DisplayName[1] <> '@' then LI.Caption:=SrvObj.DisplayName;}
   {if lpServices[i].ServiceStatus.dwCurrentState <> SERVICE_STOPPED then
    LI.SubItems.Add(IntToStr(lpServices[i].ServiceStatus.dwProcessId))              //0
   else LI.SubItems.Add('');    }

   /////////////////////////////////////////////////////////////
   if FLoadIcons then
    begin
     WillLoadIco:=True;
     IconName:=NormFileNameF(SrvObj.Parameters.ServiceDll);
     if not FileExists(IconName) then
      begin
       IconName:=NormFileNameF(SrvObj.Config.BinaryPathName);
       if not FileExists(IconName) then WillLoadIco:=False;
      end;
     if WillLoadIco then LI.ImageIndex:=GetFileIcon(IconName, is16, TImageList(FListView.SmallImages))
     else LI.ImageIndex:=-1;
    end
   else LI.ImageIndex:=-1;
   //////////////////////////////////////////////////////////////

   LI.SubItems.Add(SrvStateStr(lpServices[i].ServiceStatus.dwCurrentState));        //1
   LI.SubItems.Add(SrvStartType(SrvObj.Start, SrvObj.DelayedStart));     //---                           //2
   LI.SubItems.Add(SrvObj.Description); //lpServices[i].lpDisplayName               //3
   LI.SubItems.Add(SrvObj.Config.BinaryPathName);
   LI.SubItems.Add(SrvObj.Parameters.ServiceDll);
   PSrv:=AllocMem(SizeOf(SrvObj));
   PSrv^:=SrvObj;
   LI.Data:=PSrv;
   //   1 2 \ 16 32 272

   case lpServices[i].ServiceStatus.dwServiceType of
    1  :begin if LI.ImageIndex = -1 then LI.ImageIndex:=1; ServiceType:='Драйвер ядра'; end;
    2  :begin if LI.ImageIndex = -1 then LI.ImageIndex:=1; ServiceType:='Драйвер файловой системы'; end;
    4  :begin if LI.ImageIndex = -1 then LI.ImageIndex:=1; ServiceType:='Драйвер установки параметров устройств'; end;
   else begin if LI.ImageIndex = -1 then LI.ImageIndex:=0; ServiceType:='Служба'; end;
   end;
   LI.GroupID:=GetGroup(ListView, ServiceType, False);
  end;
 CloseServiceHandle(SCManagerHandle);

 Inform(LangText(-1, 'Список служб Windows получен.'));

 //-------

 OnChanged;
 Result:=gsFinished;
end;

constructor TServicesUnit.Create;
begin
 inherited;
 FServiceMode:=SERVICE_WIN32 or SERVICE_DRIVER;
 FServiceStatus:=SERVICE_ACTIVE or SERVICE_INACTIVE;
end;

destructor TServicesUnit.Destroy;
begin
 if Assigned(Roll) then Roll.Free;
 inherited;
end;

procedure TServicesUnit.Initialize;
begin
 //
end;

procedure TServicesUnit.Select(PID:integer);
var i:Integer;
begin
 if ListView.Items.Count <= 0 then Exit;
 for i:= 0 to ListView.Items.Count - 1 do
  begin
   ListView.Items[i].Selected:=ListView.Items[i].SubItems[0] = IntToStr(PID);
  end;
 if ListView.Selected <> nil then ListView.Selected.MakeVisible(True);
end;

function GetServiceConfig(strServiceName:string):TServiceConfig;
var hSCManager,hSCService: SC_Handle;
    lpServiceConfig: LPQUERY_SERVICE_CONFIG;
    nSize, nBytesNeeded: DWord;
begin
 hSCManager:= OpenSCManager(nil, nil, SC_MANAGER_CONNECT);
 if (hSCManager > 0) then
  begin
   hSCService := OpenService(hSCManager, PChar(strServiceName), SERVICE_QUERY_CONFIG);
   if (hSCService > 0) then
    begin
     QueryServiceConfig(hSCService, nil, 0, nSize);
     lpServiceConfig:= AllocMem(nSize);
      try
       if not QueryServiceConfig(hSCService, lpServiceConfig, nSize, nBytesNeeded)
       then Exit;
       with Result do
        begin
         ServiceType:=lpServiceConfig^.dwServiceType;
         StartType:=lpServiceConfig^.dwStartType;
         dwErrorControl:=lpServiceConfig^.dwErrorControl;
         BinaryPathName:=NormFileNameF(lpServiceConfig^.lpBinaryPathName);
         LoadOrderGroup:=lpServiceConfig^.lpLoadOrderGroup;
         TagId:=lpServiceConfig^.dwTagId;
         Dependencies:=lpServiceConfig^.lpDependencies;
         ServiceStartName:=lpServiceConfig^.lpServiceStartName;
         lpDisplayName:=lpServiceConfig^.lpDisplayName;
        end;
      finally
       Dispose(lpServiceConfig);
      end;
     CloseServiceHandle(hSCService);
    end;
  end;
end;

function TServicesUnit.GetSrvDesc(SCManager:SC_HANDLE; Srv:TServiceStatusProcess):TServiceObj;
var Tmp:string;
    OBuf:array[0..2048] of WideChar;
    OSize:DWORD;
    Dir:PWideChar;
    MUIRes:Integer;
begin
 with Result, Roll do
  begin
   Status:=Srv.ServiceStatus;
   Config:=GetServiceConfig(Srv.lpServiceName);
   //ShowMessage(SrvConfig.lpServiceStartName);
   Start:=0;
   DisplayName:='';
   Group:='Н/Д';
   ImagePath:='';
   Cmd:='';
   Description:='';
   ObjectName:='Н/Д';
   ErrorControl:=0;
   SrvType:=0;
   DependOnService:='';
   ServiceSidType:=0;
   RequiredPrivileges:='';
   FailureActions:='';
   DriverPackageId:='';
   WOW64:=False;
   DelayedStart:=False;

   Name:='';
   PID:=0;
   Parameters.ServiceDll:='';
   Parameters.ServiceDllUnloadOnStop:=0;
   //Данные не получены
   Permission:=False;
   //Независимые данные
   Name:=Srv.lpServiceName;
   PID:=Status.dwProcessId;
   Flags:=Status.dwServiceFlags;
   DisplayName:=Srv.lpDisplayName;

   RollPath:=RootKeyToStr(Roll.RootKey)+'\SYSTEM\CurrentControlSet\services\'+Srv.lpServiceName;
   RollKEY:=Roll.CurrentKey;
   //Зависимые данные
   if OpenKey('\SYSTEM\CurrentControlSet\services\'+Srv.lpServiceName, False) then
    begin
     if GetDataType('Start')       = rdInteger then Start:=ReadInteger('Start');
     if GetDataType('Group')       = rdString  then Group:=ReadString('Group');
     if (GetDataType('ImagePath')  = rdString) or (GetDataType('ImagePath') = rdExpandString) then Cmd:=ReadString('ImagePath');
     ImagePath:=NormFileNameF(Cmd);
     if GetDataType('Description') = rdString then
      begin
       Description:=ReadString('Description');
       if Description.Length > 0 then
        if Description[1] = '@' then
         begin
          GetPathAndID(Description, Tmp);
          ReplaceSysVar(Tmp);
          if FileExists(Tmp) then Dir:=nil
          else
           begin
            NormFileName(Tmp);
            Tmp:=ExtractFilePath(Tmp);
            Dir:=PWideChar(Tmp);
           end;
          MUIRes:=RegLoadMUIString(Roll.CurrentKey,
                           PWideChar('Description'),
                           @OBuf,
                           SizeOf(OBuf),
                           @OSize,
                           0,
                           Dir);
          if MUIRes = ERROR_SUCCESS then
           begin
            RegLoadMUIString(Roll.CurrentKey,
                           PWideChar('Description'),
                           @OBuf,
                           OSize,
                           @OSize,
                           0,
                           Dir);
            Description:=Trim(StrPas(OBuf));
           end
          else
           begin
            FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_IGNORE_INSERTS, nil, MUIRes, 0, @OBuf, SizeOf(OBuf), nil);
            Description:=Trim(StrPas(OBuf))+' Адрес описания: '+Description;
           end;
         end;
      end;
     ObjectName:=GetDataAsString('ObjectName', False);
     if GetDataType('ErrorControl') = rdInteger then ErrorControl:=ReadInteger('ErrorControl');
     if GetDataType('Type')          = rdInteger then SrvType:=ReadInteger('Type');
     DependOnService:=ReadStringList(Roll, 'DependOnGroup');
     if DependOnService <> '' then DependOnService:=' ';
     DependOnService:=DependOnService+ReadStringList(Roll, 'DependOnService');
     
     if GetDataType('ServiceSidType')   = rdInteger then ServiceSidType:=ReadInteger('ServiceSidType');
     RequiredPrivileges:=ReadStringList(Roll, 'RequiredPrivileges');
     FailureActions:=GetDataAsString('FailureActions', False);
     DriverPackageId:=GetDataAsString('DriverPackageId', False);
     if GetDataType('WOW64') = rdInteger then WOW64:=Boolean(ReadInteger('WOW64'));
     if GetDataType('DelayedAutoStart') = rdInteger then DelayedStart:=Boolean(ReadInteger('DelayedAutoStart'));

     Parameters.ServiceDll:=NormFileNameF(GetDataAsString('Application', False));
     if Parameters.ServiceDll = '' then
      Parameters.ServiceDll:=NormFileNameF(GetDataAsString('ServiceDll', False));
     if GetDataType('ServiceDllUnloadOnStop')   = rdInteger then Parameters.ServiceDllUnloadOnStop:=ReadInteger('ServiceDllUnloadOnStop');

     //Дополнительные данные

     if OpenKeyReadOnly('\SYSTEM\CurrentControlSet\services\'+Srv.lpServiceName+'\Parameters') then
      begin
       Parameters.ServiceDll:=NormFileNameF(GetDataAsString('Application', False));
       if Parameters.ServiceDll = '' then
        Parameters.ServiceDll:=NormFileNameF(GetDataAsString('ServiceDll', False));
       if GetDataType('ServiceDllUnloadOnStop')   = rdInteger then Parameters.ServiceDllUnloadOnStop:=ReadInteger('ServiceDllUnloadOnStop');
      end
     else
      begin
       CloseKey;
      end;
     CloseKey;
     //Данные получены
     Permission:=True;
    end
   else Log(['Нет доступа к ветке реестра ', RollPath]);
   //Проверка
   if Group = '' then Group:='Н/Д';
   if ObjectName = '' then ObjectName:='Н/Д';
   if DisplayName = '' then DisplayName:=Name;
   if Description.Length <=0 then Description:=DisplayName;
   
  end;
end;

procedure TServicesUnit.UpdateServiceListState(Snapshot:TServiceStatusProcessList);
var i:Integer;
    SrvHandle:SC_HANDLE;
    SrvState:SERVICE_STATUS;
begin
 //Snapshot[i].ServiceStatus.dwCurrentState
 for i:= 0 to ListView.Items.Count - 1 do
  begin
   SrvHandle:=OpenService(OpenSCManager(nil, nil, GENERIC_READ), PWideChar(ListView.Items[i].Caption), SERVICE_QUERY_STATUS);
   if SrvHandle > 0 then
    if QueryServiceStatus(SrvHandle, SrvState) then
     begin
      ListView.Items[i].SubItems[2]:=SrvStateStr(SrvState.dwCurrentState);
     end;
  end;
end;

function TServicesUnit.ServiceControl(ServiceName:String; ServiceControlCode:DWORD):TServiceStatus;
var SCManagerHandle, SCHandle:THandle;
begin
 SCManagerHandle:=OpenSCManager(nil, nil, GENERIC_READ);
 SCHandle:=OpenService(SCManagerHandle, PChar(ServiceName), SERVICE_ALL_ACCESS);
 ControlService(SCHandle, ServiceControlCode, Result);
 //StartService(SCHandle, 0, Result);  Result:PChar;
 CloseServiceHandle(SCHandle);
 CloseServiceHandle(SCManagerHandle);
end;

function XPRegLoadMUIString;
begin
 Result:=ERROR_INVALID_FUNCTION;
end;

function SrvStateStr(dwCS:DWORD):string;
begin
 case dwCS of
  SERVICE_STOPPED          :Result:='';
  SERVICE_START_PENDING    :Result:='Запускается';
  SERVICE_STOP_PENDING     :Result:='Завершается';
  SERVICE_RUNNING          :Result:='Работает';
  SERVICE_CONTINUE_PENDING :Result:='Запускается после временной остановки';
  SERVICE_PAUSE_PENDING    :Result:='Останавливается';
  SERVICE_PAUSED           :Result:='Временно остановлен';
 else                       Result:='Неизвестно';
 end;
end;

function SrvStartType(StartType:Integer; Delayed:Boolean):string;
begin
 case StartType of
  SERVICE_BOOT_START:  Exit('Уровень ядра');
  SERVICE_SYSTEM_START:Exit('Система');
  SERVICE_AUTO_START:  if Delayed then Exit('Автоматически (Отложенный режим)') else Exit('Автоматически');
  SERVICE_DEMAND_START:Exit('Вручную');
  SERVICE_DISABLED:    Exit('Отключено');
 else Exit('Неизвестно');
 end;
end;

function ErrorControlToStr(EC:Integer):string;
begin
 case EC of
  0:Exit(Format('Игнорировать (%d)', [EC]));
  1:Exit(Format('Только сообщить (%d)', [EC]));
  2:Exit(Format('Игнорировать после LastKnownGood (%d)', [EC]));
  3:Exit(Format('Сообщить после LastKnownGood (%d)', [EC]));
 else
  Exit(Format('Неизвестно (%d)', [EC]));
 end;
end;

procedure TFormService.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 case Key of
  VK_ESCAPE: Close;
 end;
end;

initialization

 @RegLoadMUIString:=@XPRegLoadMUIString;
 if CurOSIsNewerXP then
  begin
   hAdvAPI32:=LoadLibrary('advapi32.dll');
   if hAdvAPI32 <> 0 then
    begin
     @RegLoadMUIString:=GetProcAddress(hAdvAPI32, 'RegLoadMUIStringW');
     //Log(['RegLoadMUIStringW загружена']);
    end
   else
    begin
     Log(['Функция RegLoadMUIStringW из библиотеки "advapi32.dll" не может быть загружена.']);
     Log(['Описание некоторых служб может быть недоступно.']);
     @RegLoadMUIString:=@XPRegLoadMUIString;
    end;
  end;

(*
Параметр dwDesiredAccess задает тип доступа. Это битовая маска:

  SC_MANAGER_ALL_ACCESS - полный доступ, включает STANDARD_RIGHTS_REQUIRED в дополнение ко типам доступа
  SC_MANAGER_CONNECT - разрешает подключение к менеджеру сервисов
  SC_MANAGER_CREATE_SERVICE - разрешает создание сервисов при помощи CreateService
  SC_MANAGER_ENUMERATE_SERVICE - разрешает перечисление сервисов при помощи функции EnumServicesStatus
  SC_MANAGER_LOCK - разрешает блокирование базы данных сервисов при помощи LockServiceDatabase
  SC_MANAGER_QUERY_LOCK_STATUS - разрешает запрос статуса блокировки базы при помощи QueryServiceLockStatus
  SC_MANAGER_MODIFY_BOOT_CONFIG - модификация параметров загрузки сервиса

При доступе можно использовать типовые наборы флагов, для которых имеются именованные константы:

  GENERIC_READ - чтение (перечисление сервисов и анализ статуса блокировки), является комбинацией STANDARD_RIGHTS_READ, SC_MANAGER_ENUMERATE_SERVICE, SC_MANAGER_QUERY_LOCK_STATUS
  GENERIC_WRITE - запись - комбинация STANDARD_RIGHTS_WRITE, SC_MANAGER_CREATE_SERVICE, C_MANAGER_MODIFY_BOOT_CONFIG
  GENERIC_EXECUTE - комбинация STANDARD_RIGHTS_EXECUTE, SC_MANAGER_CONNECT и SC_MANAGER_LOCK

При успешном вызове функция возвращает Handle менеджера сервисов. После завершения работы с менеджером сервисов Handle необходимо закрыть при помощи CloseServiceHandle. *)


end.
