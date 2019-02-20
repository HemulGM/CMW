unit Services;

interface
 uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls,
  Dialogs, ExtCtrls, ComCtrls, taskSchd, taskSchdXP, TLHelp32, PSAPI,
  ShlObj, WinSvc;

 type
  TServiceObjParameters = record
   ServiceDll:string;
   ServiceDllUnloadOnStop:Integer;
  end;

  PServiceObj = ^TServiceObj;
  TServiceObj = record
   Name:string;
   Start:Integer;
   DisplayName:string;
   Group:string;
   ImagePath:string;
   Description:string;
   ObjectName:string;
   ErrorControl:Integer;
   SrvType:Integer;
   DependOnService:string;
   DriverPackageId:string;
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

var
 RegLoadMUIString:TRegLoadMUIStringFunc;
 hAdvAPI32:HMODULE;

 function CreateServiceList(LV:TListView; rgServiceMode, rgServiceStatus:Integer):Boolean;
 function ExecuteControlService(ServiceName:String; ServiceControlCode:DWORD):TServiceStatus;
 function ExecuteStartService(ServiceName:String):PChar;
 function SrvStartType(StartType:Integer):string;
 procedure SelectSrvByPID(LV:TListView; PID:integer);
 function ErrorControlToStr(EC:Integer):string;
 function XPRegLoadMUIString(RegKey: HKEY;
                          pszValue: PWideChar;
                          pszOutBuf: PWideChar;
                          cbOutBuf: DWORD;
                          pcbData: LPDWORD;
                          Flags: DWORD;
                          pszDirectory: PWideChar):LongInt;
 function SrvStateStr(dwCS:DWORD):string;
 

implementation
 uses System.Win.Registry, Utils, COCUtils;

procedure SelectSrvByPID(LV:TListView; PID:integer);
var i:Integer;
begin
 if LV.Items.Count <= 0 then Exit;
 for i:= 0 to LV.Items.Count - 1 do
  begin
   LV.Items[i].Selected:=LV.Items[i].SubItems[0] = IntToStr(PID);
  end;
 if LV.Selected <> nil then LV.Selected.MakeVisible(True);
end;

function GetSrvDesc(Roll:TRegistry; SCManager:SC_HANDLE; Srv:TServiceStatusProcess):TServiceObj;
var Sz:Cardinal;
    Tmp:string;
    OBuf:array[0..2048] of WideChar;
    OBufSize:DWORD;
    OSize:DWORD;
    Dir:PWideChar;
    MUIRes:Integer;
    SrvConfig:QUERY_SERVICE_CONFIG;

begin
 with Result, Roll do
  begin
   Status:=Srv.ServiceStatus;
   if QueryServiceConfig(OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS), @SrvConfig, SizeOf(SrvConfig), Sz) then
    ShowMessage(SrvConfig.lpServiceStartName)
   else ShowMessage(SysErrorMessage(GetLastError));
   Start:=0;
   DisplayName:='';
   Group:='�/�';
   ImagePath:='';
   Description:='';
   ObjectName:='�/�';
   ErrorControl:=0;
   SrvType:=0;
   DependOnService:='';
   ServiceSidType:=0;
   RequiredPrivileges:='';
   FailureActions:='';
   DriverPackageId:='';

   Name:='';
   PID:=0;
   Parameters.ServiceDll:='';
   Parameters.ServiceDllUnloadOnStop:=0;
   //������ �� ��������
   Permission:=False;
   //����������� ������
   Name:=Srv.lpServiceName;
   PID:=Status.dwProcessId;
   Flags:=Status.dwServiceFlags;
   DisplayName:=Srv.lpDisplayName;

   RollPath:=RootKeyToStr(Roll.RootKey)+'\SYSTEM\CurrentControlSet\services\'+Srv.lpServiceName;
   RollKEY:=Roll.CurrentKey;
   //��������� ������
   if not OpenKey('\SYSTEM\CurrentControlSet\services\'+Srv.lpServiceName, False) then Exit;
   if GetDataType('Start')       = rdInteger then Start:=ReadInteger('Start');
   if GetDataType('Group')       = rdString  then Group:=ReadString('Group');
   if (GetDataType('ImagePath')  = rdString) or (GetDataType('ImagePath') = rdExpandString) then ImagePath:=ReadString('ImagePath');
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
          FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_IGNORE_INSERTS, nil, MUIRes, 0, @OBuf, SizeOf(OBuf), 0);
          Description:=Trim(StrPas(OBuf))+' ����� ��������: '+Description;
         end;
       end;
    end;
   if GetDataType('ObjectName')  = rdString then ObjectName:=ReadString('ObjectName');
   if GetDataType('ErrorControl') = rdInteger then ErrorControl:=ReadInteger('ErrorControl');
   if GetDataType('Type')          = rdInteger then SrvType:=ReadInteger('Type');
   DependOnService:=ReadStringList(Roll, 'DependOnGroup')+#13#10+ReadStringList(Roll, 'DependOnService');
   if GetDataType('ServiceSidType')   = rdInteger then ServiceSidType:=ReadInteger('ServiceSidType');
   RequiredPrivileges:=ReadStringList(Roll, 'RequiredPrivileges');
   if GetDataType('FailureActions')     = rdString then FailureActions:=ReadString('FailureActions');
   if GetDataType('DriverPackageId')    = rdString then DriverPackageId:=ReadString('DriverPackageId');
   //�������������� ������
   if OpenKey('Paramaters\', False) then
    begin
     if GetDataType('ServiceDll') = rdString then Parameters.ServiceDll:=ReadString('ServiceDll');
     if GetDataType('ServiceDllUnloadOnStop') = rdInteger then Parameters.ServiceDllUnloadOnStop:=ReadInteger('ServiceDllUnloadOnStop');
    end;
   CloseKey;
   //��������
   if Group = '' then Group:='�/�';
   if ObjectName = '' then ObjectName:='�/�';
   if DisplayName = '' then DisplayName:=Name;
   //������ ��������
   Permission:=True;
  end;
end;

function SrvStartType(StartType:Integer):string;
begin
 case StartType of
  1,
  2:Exit('�������������');
  3:Exit('�������');
  4:Exit('���������');
 end;
end;

function ErrorControlToStr(EC:Integer):string;
begin
 case EC of
  0:Exit(Format('������������ (%d)', [EC]));
  1:Exit(Format('������ �������� (%d)', [EC]));
  2:Exit(Format('������������ ����� LastKnownGood (%d)', [EC]));
  3:Exit(Format('�������� ����� LastKnownGood (%d)', [EC]));
 else
  Exit(Format('���������� (%d)', [EC]));
 end;
end;

procedure UpdateServiceListState(Snapshot:TServiceStatusProcessList; SrvList:TListView);
var i:Integer;
    SrvHandle:SC_HANDLE;
    SrvState:SERVICE_STATUS;
begin
 for i:= 0 to SrvList.Items.Count - 1 do
  begin
   SrvHandle:=OpenService(OpenSCManager(nil, nil, GENERIC_READ), PWideChar(SrvList.Items[i].Caption), SERVICE_QUERY_STATUS);
   if SrvHandle > 0 then
    if QueryServiceStatus(SrvHandle, SrvState) then
     begin
      SrvList.Items[i].SubItems[2]:=SrvStateStr(SrvState.dwCurrentState);
     end;
  end;
end;

function SrvStateStr(dwCS:DWORD):string;
begin
 case dwCS of
  SERVICE_STOPPED          :Result:='';
  SERVICE_START_PENDING    :Result:='�����������';
  SERVICE_STOP_PENDING     :Result:='�����������';
  SERVICE_RUNNING          :Result:='��������';
  SERVICE_CONTINUE_PENDING :Result:='����������� ����� ��������� ���������';
  SERVICE_PAUSE_PENDING    :Result:='���������������';
  SERVICE_PAUSED           :Result:='�������� ����������';
 else                       Result:='�� ��������';
 end;
end;

function CreateServiceList(LV:TListView; rgServiceMode, rgServiceStatus:Integer):Boolean;
var SCManagerHandle:THandle;
    lpServices:TServiceStatusProcessList;
    pcbBytesNeeded, lpServicesReturned, lpResumeHandle:DWORD;
    ServiceMode, ServiceStatus:integer;
    i:integer;
    S, ServiceType:string;
    LI:TListItem;
    Roll:TRegistry;
    SrvObj:TServiceObj;
    PSrv:PServiceObj;
    SrvPt:Pointer;
    Group:WideChar;
begin
 Roll:=TRegistry.Create(KEY_ALL_ACCESS);
 Roll.RootKey:=HKEY_LOCAL_MACHINE;
 // ������� ������
 LV.Items.Clear;
 LV.Groups.Clear;
 LV.GroupView:=True;
 // 1. �������������� � ��������� ��������
 SCManagerHandle:=OpenSCManager(nil, nil, GENERIC_READ);
 case rgServiceMode of
  0: ServiceMode:=SERVICE_WIN32;
  1: ServiceMode:=SERVICE_DRIVER;
  2: ServiceMode:=SERVICE_WIN32 or SERVICE_DRIVER;
 end;
 //ServiceMode:=SERVICE_WIN32;
 case rgServiceStatus of
  0: ServiceStatus:=SERVICE_ACTIVE;
  1: ServiceStatus:=SERVICE_INACTIVE;
  2: ServiceStatus:=SERVICE_ACTIVE or SERVICE_INACTIVE;
 end;
 EnumServicesStatusExW(SCManagerHandle, SC_ENUM_PROCESS_INFO, ServiceMode, ServiceStatus, nil, 0, @pcbBytesNeeded, @lpServicesReturned, nil, nil);
 SetLength(lpServices, pcbBytesNeeded div SizeOf(ENUM_SERVICE_STATUS_PROCESS));
 lpResumeHandle:=0;
 EnumServicesStatusExW(SCManagerHandle, SC_ENUM_PROCESS_INFO, ServiceMode, ServiceStatus,
                       @lpServices[0], Length(lpServices) * SizeOf(ENUM_SERVICE_STATUS_PROCESS),
                       @pcbBytesNeeded, @lpServicesReturned, @lpResumeHandle, nil);
 for i:=0 to lpServicesReturned - 1 do
  begin
   LI:=LV.Items.Add;
   LI.Caption:=lpServices[i].lpServiceName;


   SrvObj:=GetSrvDesc(Roll, SCManagerHandle, lpServices[i]);
   {if Length(SrvObj.DisplayName) > 0 then
    if SrvObj.DisplayName[1] <> '@' then LI.Caption:=SrvObj.DisplayName;}
   if lpServices[i].ServiceStatus.dwCurrentState <> SERVICE_STOPPED then
    LI.SubItems.Add(IntToStr(lpServices[i].ServiceStatus.dwProcessId))
   else LI.SubItems.Add('');


   LI.SubItems.Add(SrvObj.Description); //lpServices[i].lpDisplayName
   New(PSrv);
   PSrv:=AllocMem(SizeOf(SrvObj));
   PSrv^:=SrvObj;
   LI.Data:=PSrv;
   //   1 2 \ 16 32 272
   case lpServices[i].ServiceStatus.dwServiceType of
    1  :begin LI.ImageIndex:=23; ServiceType:='������� ����'; end;
    2  :begin LI.ImageIndex:=23; ServiceType:='������� �������� �������'; end;
    4  :begin LI.ImageIndex:=23; ServiceType:='������� ��������� ���������� ���������'; end;
   else begin LI.ImageIndex:=21; ServiceType:='������'; end;
   end;
   LI.SubItems.Add(SrvStateStr(lpServices[i].ServiceStatus.dwCurrentState));
   LI.SubItems.Add(SrvObj.Group);
   LI.GroupID:=GetGroup(LV, ServiceType, False);
  end;
 Roll.Free;
 CloseServiceHandle(SCManagerHandle);
end;

function ExecuteControlService(ServiceName:String; ServiceControlCode:DWORD):TServiceStatus;
var SCManagerHandle, SCHandle:THandle;
begin
 SCManagerHandle:=OpenSCManager(nil, nil, GENERIC_READ);
 SCHandle:=OpenService(SCManagerHandle, PChar(ServiceName), SERVICE_ALL_ACCESS);
 ControlService(SCHandle, ServiceControlCode, Result);
 CloseServiceHandle(SCHandle);
 CloseServiceHandle(SCManagerHandle);
end;

function ExecuteStartService(ServiceName:String):PChar;
var SCManagerHandle, SCHandle:THandle;
begin
 SCManagerHandle:=OpenSCManager(nil, nil, GENERIC_READ);
 SCHandle:=OpenService(SCManagerHandle, PChar(ServiceName), SERVICE_ALL_ACCESS);
 Result:=nil;

 StartService(SCHandle, 0, Result);
 CloseServiceHandle(SCHandle);
 CloseServiceHandle(SCManagerHandle);
end;

function XPRegLoadMUIString;
begin
 Result:=ERROR_INVALID_FUNCTION;
end;

(*
�������� dwDesiredAccess ������ ��� �������. ��� ������� �����:

  SC_MANAGER_ALL_ACCESS - ������ ������, �������� STANDARD_RIGHTS_REQUIRED � ���������� �� ����� �������
  SC_MANAGER_CONNECT - ��������� ����������� � ��������� ��������
  SC_MANAGER_CREATE_SERVICE - ��������� �������� �������� ��� ������ CreateService
  SC_MANAGER_ENUMERATE_SERVICE - ��������� ������������ �������� ��� ������ ������� EnumServicesStatus
  SC_MANAGER_LOCK - ��������� ������������ ���� ������ �������� ��� ������ LockServiceDatabase
  SC_MANAGER_QUERY_LOCK_STATUS - ��������� ������ ������� ���������� ���� ��� ������ QueryServiceLockStatus
  SC_MANAGER_MODIFY_BOOT_CONFIG - ����������� ���������� �������� �������

��� ������� ����� ������������ ������� ������ ������, ��� ������� ������� ����������� ���������:

  GENERIC_READ - ������ (������������ �������� � ������ ������� ����������), �������� ����������� STANDARD_RIGHTS_READ, SC_MANAGER_ENUMERATE_SERVICE, SC_MANAGER_QUERY_LOCK_STATUS
  GENERIC_WRITE - ������ - ���������� STANDARD_RIGHTS_WRITE, SC_MANAGER_CREATE_SERVICE, C_MANAGER_MODIFY_BOOT_CONFIG
  GENERIC_EXECUTE - ���������� STANDARD_RIGHTS_EXECUTE, SC_MANAGER_CONNECT � SC_MANAGER_LOCK

��� �������� ������ ������� ���������� Handle ��������� ��������. ����� ���������� ������ � ���������� �������� Handle ���������� ������� ��� ������ CloseServiceHandle. *)

initialization
 hAdvAPI32:=LoadLibrary('advapi32.dll');
 if hAdvAPI32 <> 0 then
  begin
   @RegLoadMUIString:=GetProcAddress(hAdvAPI32, 'RegLoadMUIStringW');
  end
 else
  begin
   Log(['������� RegLoadMUIStringW �� ������ "advapi32.dll" �� ���������!']);
   @RegLoadMUIString:=@XPRegLoadMUIString;
  end;

end.
