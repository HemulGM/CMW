unit OSInfo;

interface
 uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls,
  Dialogs, ExtCtrls, ComCtrls, taskSchd, taskSchdXP, TLHelp32, PSAPI,
  ShlObj, ValEdit, Vcl.StdCtrls, Utils;

 type

  TOSVersion = (winUnknown, winOld, win2000, winXP, winServer2003, winCE, winVista, win7, win8, win8p1, win10, winNewer);
  TOSBits = (x32, x64);

 PNetInfo = ^TNetInfo;
  TNetInfo = record
    PlatformID  :DWORD;
    Computername:PWideChar;
    Langroup    :PWideChar;
    VerMajor    :DWORD;
    VerMinor    :DWORD;
  end;

 TDriveSpaceInfoType = record
   FreeBytesAvailableToCaller:Int64;
   FreeSize:Int64;
   TotalSize:Int64;
  end;

 TCurrentOS = class
   private
    FVersion:TOSVersion;
    FBits:TOSBits;
    FCurrentUserName:string;
    FWinVersionStr:string;
    FUsers:TStringList;
    FUsersPath:string;
    FWindowsPath:string;
    FSys32:string;
    FSys64:string;
    FHostsFileName:string;
    FOSVersionInfo:OSVERSIONINFO;
    FLicStstus:string;
    function GetUser(index:Integer):string;
    function FMemoryInfo:string;
    function FUserCount:Word;
    function FCPU:string;
    function FWindowsTimeWork:string;
    function FMachineName:string;
    function FLanGroup:string;
    function FWinUpdate:string;
    function FWinActivateStatus:string;
    function FSysDriveInfo:string;
    function FUserIsAdmin:Boolean;
    function FGetRollAccessLvl:Byte;
   public
    constructor Create;
    function GetAppExe:string;
    property Version:TOSVersion read FVersion;
    property Bits:TOSBits read FBits;
    property CurrentUserName:string read FCurrentUserName;
    property UsersPath:string read FUsersPath;
    property WindowsPath:string read FWindowsPath;
    property Sys32:string read FSys32;
    property Sys64:string read FSys64;
    property WinVersion:string read FWinVersionStr;
    property HostsFileName:string read FHostsFileName;
    property Users[index:Integer]:string read GetUser;
    property UserCount:Word read FUserCount;
    property MemoryInfo:string read FMemoryInfo;
    property MachineName:string read FMachineName;
    property LanGroup:string read FLanGroup;
    property WinUpdate:string read FWinUpdate;
    property WinActivateStatus:string read FLicStstus;
    property SysDriveInfo:string read FSysDriveInfo;
    property CPU:string read FCPU;
    property UserIsAdmin:Boolean read FUserIsAdmin;
    property RollAccessLevel:Byte read FGetRollAccessLvl;
    property OSVInfo:OSVERSIONINFO read FOSVersionInfo;
    property WindowsTimeWork:string read FWindowsTimeWork;
  end;



 const
  VER_PLATFORM_WIN32_NT = 2;
  ErGetStr = '<не доступно>';

 var
  OSVersion:TOSVersion;
  CurrentDir:string;
  WindowsBits:TOSBits;
  AppBits:TOSBits;
  LogFileName:string;
  C:string;

 var
  Info:TCurrentOS;

  function GetDriveSpaceInfo(Drive:string = ''):TDriveSpaceInfoType;
  function BitsToStr(V:TOSBits):string;
  procedure Init;

implementation
 uses Main, System.Win.Registry, Forms, COCUtils, System.Win.ComObj, WbemScripting_TLB, Winapi.ActiveX;

//--------------------------------TCurrentOS------------------------------------

function TCurrentOS.FUserCount:Word;
begin
 Result:=FUsers.Count;
end;

function TCurrentOS.GetAppExe:string;
begin
 case Bits of
  x32:Result:=App32;
  x64:Result:=App64;
 else
  Result:=App32;
 end;
end;

constructor TCurrentOS.Create;
var a:array[0..254] of char;
    lenBuf:Cardinal;
    FRoll:TRegistry;
    NoUserPlace:Boolean;
begin
 GetWindowsDirectory(a, sizeof(a));
 FWindowsPath:=StrPas(a);
 lenBuf:=255;
 GetUserName(a, lenBuf);
 FCurrentUserName:=StrPas(a);
 FVersion:=OSVersion;
 FSys32:=FWindowsPath+'\System32';
 FSys64:=FWindowsPath+'\SysWOW64';
 try
  try
   FRoll:=TRegistry.Create(KEY_READ);
   FRoll.RootKey:=HKEY_LOCAL_MACHINE;
   if FRoll.OpenKeyReadOnly('SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList') then
    begin
     FUsersPath:=FRoll.ReadString('ProfilesDirectory');
     ReplaceSysVar(FUsersPath);
    end
   else NoUserPlace:=True;
  finally
   FreeAndNil(FRoll);
  end;
  NoUserPlace:=False;
 except
  NoUserPlace:=True;
 end;
 if NoUserPlace then
  begin
   Log(['Каталог пользователей выбран исходя из значений "По умолчанию". Нет доступа к HKLM.']);
   case FVersion of
    winXP: FUsersPath:=Copy(FWindowsPath, 1, 3)+'Documents and Settings\';
    winOld:
     begin
      FUsersPath:=Copy(FWindowsPath, 1, 3)+'Documents and Settings\';
      MessageBox(Application.Handle, PChar(LangText(104, 'Программа пока не имеет возможности работать с Windows')+' '+WinVersion), PChar(LangText(103, 'Прошу прощения')), MB_ICONSTOP or MB_OK);
     end;
   else FUsersPath:=Copy(FWindowsPath, 1, 3)+'Users\';
   end;
  end;
 Log(['Каталог пользователей', FUsersPath]);
 
 FHostsFileName:=FSys32+'\drivers\etc\hosts';
 FBits:=WindowsBits;
 FUsers:=GetDirectores(FUsersPath);
 case FVersion of
  winXP:        FWinVersionStr:='Windows XP/Embedded';
  winServer2003:FWinVersionStr:='Windows Server 2003';
  winCE:        FWinVersionStr:='Windows Compact Edition';
  winVista:     FWinVersionStr:='Windows Vista/Server 2008';
  win7:         FWinVersionStr:='Windows 7/Server 2008 R2';
  win8:         FWinVersionStr:='Windows 8/Server 2012';
  win8p1:       FWinVersionStr:='Windows 8.1';
  win10:        FWinVersionStr:='Windows 10';
 else
  FWinVersionStr:='Windows '+WinVersion;
 end;
 FWinVersionStr:=FWinVersionStr + ' ('+
                 IntToStr(Win32MajorVersion)+'.'+
                 IntToStr(Win32MinorVersion)+'.'+
                 IntToStr(Win32BuildNumber)+') ' + BitsToStr(Bits);
 GetVersionEx(FOSVersionInfo);
 FLicStstus:=FWinActivateStatus;
end;

function TCurrentOS.FMemoryInfo:string;
var lpMemoryStatus : TMemoryStatus;
begin
 try
  lpMemoryStatus.dwLength:=SizeOf(lpMemoryStatus);
  GlobalMemoryStatus(lpMemoryStatus);
  with lpMemoryStatus do
   begin
    Result:=Result+
     'Всего: '+Format('%0.0f Мбайт', [dwTotalPhys div 1024 / 1024])+' | '+
     'Файл подкачки: '+Format('%0.0f Мбайт', [dwTotalPageFile div 1024 / 1024]);
   end;
 except
  begin
   Log(['Не смог получить информацию об оперативной памяти.', SysErrorMessage(GetLastError)]);
   Exit(ErGetStr);
  end;
 end;
end;

function TCurrentOS.FUserIsAdmin:Boolean;
const
    SECURITY_NT_AUTHORITY: TSIDIdentifierAuthority = (Value: (0, 0, 0, 0, 0, 5));
    SECURITY_BUILTIN_DOMAIN_RID = $00000020;
    DOMAIN_ALIAS_RID_ADMINS = $00000220;
var hAccessToken: THandle;
    ptgGroups: PTokenGroups;
    dwInfoBufferSize: DWORD;
    psidAdministrators: PSID;
    x: Integer;
    bSuccess: BOOL;
begin
 Result:=False;
 try
  begin
   bSuccess:=OpenThreadToken(GetCurrentThread, TOKEN_QUERY, True, hAccessToken);
   if not bSuccess then
    begin
     if GetLastError = ERROR_NO_TOKEN then
      bSuccess:=OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, hAccessToken);
    end;
   if bSuccess then
    begin
     GetMem(ptgGroups, 1024);
     bSuccess := GetTokenInformation(hAccessToken, TokenGroups, ptgGroups, 1024, dwInfoBufferSize);
     CloseHandle(hAccessToken);
     if bSuccess then
      begin
       AllocateAndInitializeSid(SECURITY_NT_AUTHORITY, 2, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0, psidAdministrators);
       {$R-}
       for x := 0 to ptgGroups.GroupCount - 1 do
        if EqualSid(psidAdministrators, ptgGroups.Groups[x].Sid) then
         begin
          Result:=True;
          Break;
         end;
       {$R+}
       FreeSid(psidAdministrators);
      end;
     FreeMem(ptgGroups);
    end;
  end;
 except
  begin
   Log(['Не смог получить информацию о правах пользователя.', SysErrorMessage(GetLastError)]);
   Exit(False);
  end;
 end;
end;

function TCurrentOS.FGetRollAccessLvl:Byte;
var Roll:TRegistry;
begin
 //---------------------Реестр--------------------------------------------------
 try
  begin
   Result:=0;
   Roll:=TRegistry.Create(KEY_READ);
   try
    Roll:=TRegistry.Create(KEY_READ);
    if Roll.OpenKey('Software', False) then Result:=1;
   except Result:=0;
   end;

   if Result > 0 then
    begin
     try
      Roll:=TRegistry.Create(KEY_WRITE);
      Roll.RootKey:=HKEY_CURRENT_USER;
      if Roll.OpenKey('Software', False) then Result:=2;
     except Result:=1;
     end;
    end;
   if Result > 1 then
    begin
     try
      Roll:=TRegistry.Create(KEY_ALL_ACCESS);
      Roll.RootKey:=HKEY_CURRENT_USER;
      if Roll.OpenKey('Software', False) then Result:=3;
     except Result:=2;
     end;
    end;
   if Result > 2 then
    begin
     try
      Roll:=TRegistry.Create(KEY_READ);
      Roll.RootKey:=HKEY_LOCAL_MACHINE;
      if Roll.OpenKey('Software', False) then Result:=4;
     except Result:=3;
     end;
    end;
   if Result > 3 then
    begin
     try
      Roll:=TRegistry.Create(KEY_WRITE);
      Roll.RootKey:=HKEY_LOCAL_MACHINE;
      if Roll.OpenKey('Software', False) then Result:=5;
     except Result:=4;
     end;
    end;
   if Result > 4 then
    begin
     try
      Roll:=TRegistry.Create(KEY_ALL_ACCESS);
      Roll.RootKey:=HKEY_LOCAL_MACHINE;
      if Roll.OpenKey('Software', False) then Result:=6;
     except Result:=5;
     end;
    end;
   if Assigned(Roll) then Roll.Free;
  end;
 except
  begin
   Log(['Не смог получить информацию об уровне доступа к реестру.', SysErrorMessage(GetLastError)]);
   //Exit(ErGetStr);
  end;
 end;
end;

function TCurrentOS.FWindowsTimeWork:string;
const DivSec = 1000;
      DivMin = DivSec * 60;
      DivHur = DivMin * 60;
      DivDay = DivHur * 24;
var SysTime:UInt64;
    D, H, M, S:Integer;
begin
 try
  SysTime:=GetTickCount;
  D:=SysTime div DivDay; Dec(SysTime, D * DivDay);
  H:=SysTime div DivHur; Dec(SysTime, H * DivHur);
  M:=SysTime div DivMin; Dec(SysTime, M * DivMin);
  S:=SysTime div DivSec; Dec(SysTime, S * DivSec);
  Result:=IntToStr(D)+' дн. '+IntToStr(H)+' час. '+IntToStr(M)+' мин. '+IntToStr(S)+' сек. '+IntToStr(SysTime)+' мсек.';
 except
  begin
   Log(['Не смог получить информацию о времени работы системы.', SysErrorMessage(GetLastError)]);
   Exit(ErGetStr);
  end;
 end;
end;

function TCurrentOS.FCPU:string;
var lpSystemInfo:TSystemInfo;
    Roll:TRegistry;
begin
 try
  Roll:=TRegistry.Create(KEY_READ);
  Roll.RootKey:=HKEY_LOCAL_MACHINE;
  FillChar(lpSystemInfo, SizeOf(TSystemInfo), '#');
  GetSystemInfo(lpSystemInfo);
  if Roll.OpenKey('HARDWARE\DESCRIPTION\System\CentralProcessor\0', False) then
   begin
    Result:=Roll.ReadString('ProcessorNameString')+' Количество логичесих процессоров: '+IntToStr(lpSystemInfo.dwNumberOfProcessors);
   end
  else Result:='Класс x'+IntToStr(lpSystemInfo.dwProcessorType);
  Roll.CloseKey;
  Roll.Destroy;
 except
  begin
   Log(['Не смог получить информацию о процессоре.', SysErrorMessage(GetLastError)]);
   Exit(ErGetStr);
  end;
 end;
end;

function TCurrentOS.FMachineName:string;
var Size:Cardinal;
    PRes:PChar;
    BRes:Boolean;
begin
 try
  Result:='Не определено';
  Size:=MAX_COMPUTERNAME_LENGTH + 1;
  PRes:=StrAlloc(Size);
  BRes:=GetComputerName(PRes, Size);
  if BRes then Result:=StrPas(PRes);
 except
  begin
   Log(['Не смог получить информацию об имени компьютера.', SysErrorMessage(GetLastError)]);
   Exit(ErGetStr);
  end;
 end;
end;

function TCurrentOS.FLanGroup:string;
var Info:PNetInfo;
    Error:DWORD;
begin
 try
  Error:=GetNetInfo(PChar(FMachineName), 100, @Info);
  if Error <> 0 then
   raise Exception.Create(SysErrorMessage(Error));
  Result:= Info^.LanGroup;
 except
  begin
   Log(['Не смог получить информацию о названии текущей группы.', SysErrorMessage(GetLastError)]);
   Exit(ErGetStr);
  end;
 end;
end;

function TCurrentOS.FWinUpdate:string;
var Roll:TRegistry;
begin
 try
  Roll:=TRegistry.Create(KEY_READ or KEY_WOW64_64KEY);
  Roll.RootKey:=HKEY_LOCAL_MACHINE;
  if Roll.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update', False) then
   begin
    try
     case Roll.ReadInteger('AUOptions') of
      1:Result:='Отключено';
      2:Result:='Включено частично (Поиск обновлений)';
      3:Result:='Включено частично (Поиск и загрузка обновлений)';
      4:Result:='Автоматически';
     end;
    except
     Result:='Не определено';
    end;
   end
  else Result:='Не определено';
  Roll.CloseKey;
  Roll.Destroy;
 except
  begin
   Log(['Не смог получить информацию о состоянии автоматического обновления.', SysErrorMessage(GetLastError)]);
   Exit(ErGetStr);
  end;
 end;
end;

function TCurrentOS.FWinActivateStatus:string;
var
  Service:ISWbemServices;
  SObject:ISWbemObject;
  ls:Integer;
  ENum:IEnumVariant;
  TempObj:OleVariant;
  Value:Cardinal;
  ObjectSet:ISWbemObjectSet;
  SWbemLocator:TSWbemLocator;
  sQuery, sValue:string;
begin
 try
  if OSVersion = winXP then
       begin sQuery:='win32_WindowsProductActivation'; sValue:='ActivationRequired' end
  else begin sQuery:='SoftwareLicensingProduct';       sValue:='LicenseStatus'      end;
  SWbemLocator:=TSWbemLocator.Create(nil);
  Service:=SWbemLocator.ConnectServer('', 'root\CIMV2', '', '', '', '', 0, nil);
  SObject:=Service.Get(sQuery, wbemFlagUseAmendedQualifiers, nil); //win32_WindowsProductActivation
  ObjectSet:=SObject.Instances_(0, nil);
  Enum:=(ObjectSet._NewEnum) as IEnumVariant;
  Enum.Next(1, TempObj, Value);
  SObject:=IUnknown(TempObj) as SWBemObject;
  ls:=SObject.Properties_.Item(sValue, 0).Get_Value;    //ActivationRequired
  SWbemLocator.Free;
  if ls = 0 then Result:='Активация Windows выполнена' else Result:='Активация Windows не выполнена';
 except
  begin
   Log(['Не удалось определить статус активации Windows', SysErrorMessage(GetLastError)]);
   Result:=ErGetStr;
  end;
 end;
end;

function TCurrentOS.FSysDriveInfo:string;
begin
 try
  Result:='Диск "'+C+'", свободно '+GetSpacedInt(IntToStr(GetDriveSpaceInfo(C[1]+':').FreeSize div (1024 * 1024)))+' из '+GetSpacedInt(IntToStr(GetDriveSpaceInfo(C[1]+':').TotalSize div (1024 * 1024)))+' '+LangText(48, 'Мбайт');
 except
  Result:=ErGetStr;
 end;
end;

function TCurrentOS.GetUser(index:Integer):string;
begin
 Result:='';
 if FUsers.Count <= 0 then
  begin
   Log(['Список пользователей не доступен.']);
   Exit;
  end;
 if (index < 0) or (index > FUsers.Count - 1) then
  begin
   Log([index, 'выходит за границы масива пользователей.']);
   Exit;
  end;
 try
  Result:=FUsers[index];
 except
  Log(['Не смог получить пользователя под индексом', index]);
 end;
end;


procedure GetOSVersion;
begin
 OSVersion:=winUnknown;
 if Win32Platform = VER_PLATFORM_WIN32_NT then//Win NTx
  begin
   case Win32MajorVersion of
    5:                                        //Win NT5x
     begin
      case Win32MinorVersion of
       0:OSVersion:=win2000;                   //Windows 2000 (Win2k) Professional, Server, Advanced Server, Datacenter Server
       1:OSVersion:=winXP;                     //Windows XP Home, Professional, Tablet PC Edition, Media Center Edition, Embedded
       2:OSVersion:=winServer2003;             //Windows Server 2003, Compute Cluster Server 2003
      end;
     end;
    6:                                        //Win NT6x
     begin
      case Win32MinorVersion of
       0:OSVersion:=winVista;                  //Windows Vista, Server 2008, HPC Server 2008, Home Server, Vista for Embedded Systems
       1:OSVersion:=win7;                      //Windows 7, Server 2008 R2
       2:OSVersion:=win8;                      //Windows 8, Server 2012
       3:OSVersion:=win8p1;                    //Windows 8.1
      end;
     end;
    7:                                        //Win NT7x
     begin
      case Win32MinorVersion of
       0:OSVersion:=winCE;                     //Windows Compact Edition
      end;
     end;
    10:                                       //Win NT10x
     begin
      case Win32MinorVersion of
       0:OSVersion:=win10;                     //Windows 10
      else
       OSVersion:=winNewer;
      end;
     end;
   else
    if Win32MajorVersion < 5 then OSVersion:=winOld else
     if Win32MajorVersion > 10 then OSVersion:=winNewer;
   end;
  end
 else OSVersion:=winOld;                      //Более ранние операционные системы (программа всё равно на них не будет работать)
end;

procedure GetCurrentDir;
begin
 CurrentDir:=ExtractFilePath(ParamStr(0));
 LogFileName:=CurrentDir+'cwm.log';
end;

procedure GetWindowsBits;
function FIs64BitWindows:Boolean;
var Wow64Process1:Bool;
begin
 Result:=False;
 {$IF Defined(Win64)}
 Result:=True;
 Exit;
 {$ELSEIF Defined(CPU16)}
 Result:=False;
 {$ELSE}
 Wow64Process1:=False;
 Result:=IsWow64Process(GetCurrentProcess, Wow64Process1) and Wow64Process1;
 {$ENDIF}
end;
begin
 if FIs64BitWindows then WindowsBits:=x64 else WindowsBits:=x32;
end;

procedure GetApplicationBits;
begin
 {$IFDEF WIN64}
 AppBits:=x64;
 {$ELSE}
 AppBits:=x32;
 {$ENDIF}
end;

procedure InitLog;
begin
 NotUseLog:=False;
 try
  if not FileExists(LogFileName) then FileClose(FileCreate(LogFileName));
  AssignFile(LogFile, LogFileName);
  Append(LogFile);
 except
  NotUseLog:=True;
 end;
end;

function GetC:string;
var Buffer:array[0..254] of Char;
begin
 GetWindowsDirectory(Buffer, SizeOf(Buffer));
 Result:=Copy(StrPas(Buffer), 1, 3);
end;

function GetDriveSpaceInfo(Drive:string):TDriveSpaceInfoType;
var FreeBytesAvailableToCaller:TLargeInteger;
    FreeSize:TLargeInteger;
    TotalSize:TLargeInteger;
begin
 if Drive = '' then Drive:=GetC;
 GetDiskFreeSpaceEx(PChar(Drive), FreeBytesAvailableToCaller, Totalsize, @FreeSize);
 Result.FreeBytesAvailableToCaller:=FreeBytesAvailableToCaller;
 Result.FreeSize:=FreeSize;
 Result.TotalSize:=TotalSize;
end;

function BitsToStr(V:TOSBits):string;
begin
 if V = x32 then Result:='x32' else Result:='x64';
end;

procedure Init;
begin
 //Loading...
 GetCurrentDir;                  //Установка текущего каталога
 InitLog;
 GetOSVersion;                   //Установка версии ОС
 GetWindowsBits;                 //Установка разрядности ОС
 GetApplicationBits;             //Установка разрядности приложения
 C:=GetC;
 Info:=TCurrentOS.Create;
end;

end.
