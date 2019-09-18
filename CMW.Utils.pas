unit CMW.Utils;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Dialogs,
  ExtCtrls, ComCtrls, taskSchd, taskSchdXP, TLHelp32, PSAPI, ShlObj, ValEdit,
  Vcl.StdCtrls, Vcl.ImgList, Registry,
  //
  CMW.OSInfo;
  //

type
  TMUIType = (mtNone, mtIcon, mtString);

  TFunctionStopping = function: Boolean;

  TCPUUseFunct = function: Double;

  TVersionInfo = record
    CompanyName: WideString;
    FileDescription: WideString;
    FileVersion: WideString;
    InternalName: WideString;
    LegalCopyright: WideString;
    LegalTradeMarks: WideString;
    OriginalFilename: WideString;
    ProductName: WideString;
    ProductVersion: WideString;
    Comments: WideString;
    Language: WideString;
    Translation: WideString;
    FileVersionMajor: Word;
    FileVersionMinor: Word;
    FileVersionRelease: Word;
    FileVersionBuild: Word;
    ProductVersionMajor: Word;
    ProductVersionMinor: Word;
    ProductVersionRelease: Word;
    ProductVersionBuild: Word;
    Debug: Boolean;
    Patched: Boolean;
    PreRelease: Boolean;
    PrivateBuild: Boolean;
    SpecialBuild: Boolean;
  end;

  TProcessMonitor = class
  private
    FPID: Cardinal;
    FStopping: Boolean;
    FWorking: Boolean;
    FExecuting: Boolean;
    function FindChildProcess(PID: Cardinal; var CPID: Cardinal): Boolean;
  public
    procedure Stop;
    function WaitStop(PID: Cardinal): Boolean;
    function Execute(cmdLine: string): Boolean;
    function ExecuteAndWait(cmdLine: string): Boolean;
    property Executing: Boolean read FExecuting;
    property ExePID: Cardinal read FPID;
  end;

  TIconSize = (is16, is32);

  TMessageLevel = (mlInfo, mlWarning, mlError);

  SYSTEM_INFORMATION_CLASS = (SystemBasicInformation, SystemProcessorInformation, SystemPerformanceInformation, SystemTimeOfDayInformation, SystemNotImplemented1, SystemProcessesAndThreadsInformation, SystemCallCounts, SystemConfigurationInformation, SystemProcessorTimes, SystemGlobalFlag, SystemNotImplemented2, SystemModuleInformation, SystemLockInformation, SystemNotImplemented3, SystemNotImplemented4, SystemNotImplemented5, SystemHandleInformation, SystemObjectInformation, SystemPagefileInformation,
    SystemInstructionEmulationCounts, SystemInvalidInfoClass1, SystemCacheInformation, SystemPoolTagInformation, SystemProcessorStatistics, SystemDpcInformation, SystemNotImplemented6, SystemLoadImage, SystemUnloadImage, SystemTimeAdjustment, SystemNotImplemented7, SystemNotImplemented8, SystemNotImplemented9, SystemCrashDumpInformation, SystemExceptionInformation, SystemCrashDumpStateInformation, SystemKernelDebuggerInformation, SystemContextSwitchInformation, SystemRegistryQuotaInformation,
    SystemLoadAndCallImage, SystemPrioritySeparation, SystemNotImplemented10, SystemNotImplemented11, SystemInvalidInfoClass2, SystemInvalidInfoClass3, SystemTimeZoneInformation, SystemLookasideInformation, SystemSetTimeSlipEvent, SystemCreateSession, SystemDeleteSession, SystemInvalidInfoClass4, SystemRangeStartInformation, SystemVerifierInformation, SystemAddVerifier, SystemSessionProcessesInformation);

  LPVOID = Pointer;

  EWin32Exception = class(Exception)
    FErrorCode: LongInt;
  public
    property ErrorCode: LongInt read FErrorCode write FErrorCode;
  end;

  // тип - список тегов информации о версии файла (MSDN 6.0)
  TFviTags = (fviComments, fviCompanyName, fviFileDescription, fviFileVersion, fviInternalName, fviLegalCopyright, fviLegalTrademarks, fviOriginalFilename, fviPrivateBuild, fviProductName, fviProductVersion, fviSpecialBuild);

  TFileVersionInfoRecord = record
    LangID: Word;  // Windows language identifier
    LangCP: Word;  // Code page for the language
    LangName: array[0..255] of Char;  // Отображаемое Windows имя языка
    FieldDef: array[TFviTags] of string; // имя параметра по-английски
    FieldRus: array[TFviTags] of string; // имя параметра по-русски
    Value: array[TFviTags] of string; // значение параметра
    FileVer: string; // языко-независимое значение версии файла
    ProductVer: string; // языко-независимое значение версии продукта
    BuildType: string; // языко-независимое - тип сборки
    FileType: string; // языко-независимое - тип продукта
  end;

const // Имена полей (тегов) по-английски:
  cFviFieldsDef: array[TFviTags] of string = ('Comments', 'CompanyName', 'FileDescription', 'FileVersion', 'InternalName', 'LegalCopyright', 'LegalTrademarks', 'OriginalFilename', 'PrivateBuild', 'ProductName', 'ProductVersion', 'SpecialBuild');

const // Имена полей (тегов) по-русски:
  cFviFieldsRus: array[TFviTags] of string = ('Комментарий', 'Производитель', 'Описание', 'Версия файла', 'Внутреннее имя', 'Авторские права', 'Торговые знаки', 'Исходное имя файла', 'Приватная версия', 'Название продукта', 'Версия продукта', 'Особая версия');

const
  RusLangID = $0419;

const
  OFASI_EDIT = $0001;
  OFASI_OPENDESKTOP = $0002;
  Shell32 = 'Shell32.dll';
  DONT_RESOLVE_DLL_REFERENCES = $00000001;
  {$EXTERNALSYM DONT_RESOLVE_DLL_REFERENCES}
  LOAD_IGNORE_CODE_AUTHZ_LEVEL = $00000010;
  {$EXTERNALSYM LOAD_IGNORE_CODE_AUTHZ_LEVEL}
  LOAD_LIBRARY_AS_DATAFILE = $00000002;
  {$EXTERNALSYM LOAD_LIBRARY_AS_DATAFILE}
  LOAD_LIBRARY_AS_DATAFILE_EXCLUSIVE = $00000040;
  {$EXTERNALSYM LOAD_LIBRARY_AS_DATAFILE_EXCLUSIVE}
  LOAD_LIBRARY_AS_IMAGE_RESOURCE = $00000020;
  {$EXTERNALSYM LOAD_LIBRARY_AS_IMAGE_RESOURCE}
  LOAD_LIBRARY_SEARCH_APPLICATION_DIR = $00000200;
  {$EXTERNALSYM LOAD_LIBRARY_SEARCH_APPLICATION_DIR}
  LOAD_LIBRARY_SEARCH_DEFAULT_DIRS = $00001000;
  {$EXTERNALSYM LOAD_LIBRARY_SEARCH_DEFAULT_DIRS}
  LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR = $00000100;
  {$EXTERNALSYM LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR}
  LOAD_LIBRARY_SEARCH_SYSTEM32 = $00000800;
  {$EXTERNALSYM LOAD_LIBRARY_SEARCH_SYSTEM32}
  LOAD_LIBRARY_SEARCH_USER_DIRS = $00000400;
  {$EXTERNALSYM LOAD_LIBRARY_SEARCH_USER_DIRS}
  LOAD_WITH_ALTERED_SEARCH_PATH = $00000008;
  {$EXTERNALSYM LOAD_WITH_ALTERED_SEARCH_PATH}

var
  LogBuf: string;
  ThreadLogID: DWORD;
  LogFile: TextFile;
  SLog: TStrings;
  NotUseLog: Boolean;
  LangH: THandle;
  LogList: ^TMemo;
  ProcessMonitor: TProcessMonitor;
  preIdleTime, preUserTime, preKrnlTime: TFileTime;

function GetSpacedInt(AText: string): string;

procedure NormFileName(var FN: string);

function NormFileNameF(FN: string): string;

function GetDirectores(Dir: string): TStringList;

function NormTime(Value: Cardinal): string;

procedure ScanDir(StartDir: string; Mask: string; List: TStrings);

procedure ScanDirFiles(StartDir: string; Mask, FileMask: string; List: TStrings);

function CustomStrSortProc(Item1, Item2: TListItem; ParamSort: integer): integer; stdcall;

function CustomDateSortProc(Item1, Item2: TListItem; ParamSort: integer): integer; stdcall;

function CustomIntSortProc(Item1, Item2: TListItem; ParamSort: integer): integer; stdcall;

function RootKeyToStr(RK: HKEY): string;

function StrKeyToRoot(RK: string): HKEY;

function GetDateForTask(Value: TDate): string;

procedure GetTasks(Folder: ITaskFolder; AllFolder: Boolean; var TL: TTasksList);

procedure GetTasksXP(const TaskSched: TTaskScheduleOld; var TL: TTasksListXP);

function GetFileNameWoE(FileName: TFileName): string;

procedure Log(Value: array of const);

procedure Logging;

function GetNetInfo(ServerName: PWideChar; Level: DWORD; Bufptr: Pointer): DWORD; stdcall; external 'netapi32.dll' name 'NetWkstaGetInfo';

function GetGroup(LV: TListView; GroupName: string; Expand: Boolean): Word;
 //function CheckEventSel(EventStr:string):Boolean;

function GetFileDateChg(FileName: string): TDateTime;

procedure Wait(Seconds: Cardinal);

function WinExec(lpCmdLine: string; uCmdShow: UINT): UINT; overload;

function StrToPAnsi(Str: string): PAnsiChar;

function DelFLSpace(str: string): string;

function DelFLDSpace(str: string): string;

function LoadString(sID: Cardinal): string; overload;

function LoadString(h: THandle; sID: Cardinal): string; overload;

function LangText(ID: Integer; Text: string): string;

function ByteToHexStr(Data: Pointer; Len: Integer): string;

function WordToHexStr(Data: Pointer; Len: Integer): string;

function GetHDDrives: string;

procedure RepVar(var Dest: string; Indent, VarInd: string);

function ILCreateFromPath(pszPath: PChar): PItemIDList stdcall; external shell32 name 'ILCreateFromPathW';

procedure ILFree(pidl: PItemIDList) stdcall; external shell32;

function SHOpenFolderAndSelectItems(pidlFolder: PItemIDList; cidl: Cardinal; apidl: pointer; dwFlags: DWORD): HRESULT; stdcall; external shell32;

function OpenFolderAndSelectFile(const FileName: string): boolean;

function OpenFolderAndOrSelectFile(const FileName: string): boolean;

function ReplaceSysVarF(Src: string): string;

procedure ReplaceSysVar(var Src: string);

procedure AddToValueEdit(VE: TValueListEditor; Key, Value, ValueBU: string);

function OccupiedFile(FN: string): Boolean;

procedure AddToLogList(Text: string);

function GetItemCount(LV: TListView; GID: Integer): Cardinal;

function ForceRemoveDir(sDir: string): Boolean;
 //function GetListLogicalDrives:TStrings;

function BoolToLang(Value: Boolean): string;

function DeleteStrQM(Value: string): string;

procedure Unload;

function InstallDateToNorm(InstDate: string; const Def: TDateTime): TDateTime;

function GetFileNameFromLink(LinkFileName: string): string;

function DeleteForceFile(const FileName: string): Boolean;

function CustomUniSortProc(Item1, Item2: TListItem; ParamSort: integer): integer; stdcall;

function FileTimeToDateTime(FileTime: TFileTime): TDateTime;

function ExistsFile(FileName: string): Boolean;

function CPUUsage: Extended;

function MixColors(FG, BG: TColor; T: byte): TColor;

procedure WuLine(ABitmap: TBitmap; Point1, Point2: TPoint; AColor: TColor);

function BoolStr(Value: Boolean; const VTrue, VFalse: string): string; overload;

function BoolStr(Value: Boolean): string; overload;

procedure CreateSubItems(var LI: TListItem; const Count: Word);

function GetUsersPaths(DefaultUP: string): TStrings;

function AddToListWOR(Item: string; List: TStrings): Boolean;

function AddToListW(Item: string; List: TStrings): Boolean;

function GetTempDir: string;

function GetFullPath(const ShortPath: string): string;

function ReadRegString(KEY: HKEY; Path, Item: string): string;

function SetPrivilege(aPrivilegeName: string; aEnabled: boolean): boolean;

function GetEnvironmentStrings1: string;

function CompareFileTimeOwn(t1, t2: FILETIME): Int64;

function FileTimeToInt(Value: TFileTime): Int64;

function GetFileIcon(const FileName: TFileName; Size: TIconSize; var destIcon: TIcon): Integer; overload;

function GetFileIcon(const FileName: TFileName; Size: TIconSize; var destIcon: HICON): Integer; overload;

function GetFileIcon(const FileName: TFileName; Size: TIconSize; IL: TCustomImageList): Integer; overload;

function GetFileIcon(const FileName: TFileName; Size: TIconSize; IL: TCustomImageList; var II: Word): Integer; overload;

procedure CreateMessage(Text: string; Level: TMessageLevel);

function CurOSIsNewerXP: Boolean;

function MUILoad(MUI: string; var Icon: TIcon; var Str: string): TMUIType;

function UnixDateTimeToDelphiDateTime(UnixDateTime: LongInt): TDateTime;

function GetRegValue(ARootKey: HKEY; AKey, Value: string): string;

function GetAccountName(const SID: PSID): string;

procedure RaiseWin32Error(Code: LongInt);

function GetDllVersion(FileName: string): Integer;

function ReadStringList(Roll: TRegistry; const name: string): string;

procedure ShowPropertiesDialog(FName: string);

function GetFileInfo(const strFilename: string): string;

function GetFileDescription(const FileName, ExceptText: string): string;

function GetFileTypeName(const strFilename: string): string;

procedure GetPathAndID(Input: string; var Path: string);

procedure GetPathID(Input: string; var Path: string; var ID: Cardinal);

 //function GetIcons(FileName: String; Image32: TImageList):Integer;

function CalcChecked(LV: TListView): Integer;

procedure CaptureConsoleOutput(const ACommand, AParameters: string; AMemo: TMemo);

function GetDosOutput(CommandLine: string; Work: string = 'C:\'): string;

implementation

uses
  CMW.Main, Forms, ShellAPI, CMW.ModuleStruct, Vcl.FileCtrl, System.Win.ComObj,
  Winapi.ActiveX;

type
  TRGBTripleArray = array[0..1000] of TRGBTriple;

  PRGBTripleArray = ^TRGBTripleArray;

function GetDosOutput(CommandLine: string; Work: string = 'C:\'): string;
var
  SecAtrrs: TSecurityAttributes;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  StdOutPipeRead, StdOutPipeWrite: THandle;
  WasOK: Boolean;
  pCommandLine: array[0..255] of AnsiChar;
  BytesRead: Cardinal;
  Handle: Boolean;
begin
  Result := '';
  with SecAtrrs do
  begin
    nLength := SizeOf(SecAtrrs);
    bInheritHandle := True;
    lpSecurityDescriptor := nil;
  end;
  CreatePipe(StdOutPipeRead, StdOutPipeWrite, @SecAtrrs, 0);
  try
    with StartupInfo do
    begin
      FillChar(StartupInfo, SizeOf(StartupInfo), 0);
      cb := SizeOf(StartupInfo);
      dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
      wShowWindow := SW_HIDE;
      hStdInput := GetStdHandle(STD_INPUT_HANDLE); // don't redirect stdin
      hStdOutput := StdOutPipeWrite;
      hStdError := StdOutPipeWrite;
    end;
    Handle := CreateProcess(nil, PChar('cmd.exe /C ' + CommandLine), nil, nil, True, 0, nil, PChar(Work), StartupInfo, ProcessInfo);
    CloseHandle(StdOutPipeWrite);
    if Handle then
    try
      repeat
        WasOK := windows.ReadFile(StdOutPipeRead, pCommandLine, 255, BytesRead, nil);
        if BytesRead > 0 then
        begin
          pCommandLine[BytesRead] := #0;
          OemToAnsi(pCommandLine, pCommandLine);
          Result := Result + pCommandLine;
        end;
      until not WasOK or (BytesRead = 0);
      WaitForSingleObject(ProcessInfo.hProcess, INFINITE);
    finally
      CloseHandle(ProcessInfo.hThread);
      CloseHandle(ProcessInfo.hProcess);
    end;
  finally
    CloseHandle(StdOutPipeRead);
  end;
end;

procedure CaptureConsoleOutput(const ACommand, AParameters: string; AMemo: TMemo);
const
  CReadBuffer = 2400;
var
  saSecurity: TSecurityAttributes;
  hRead: THandle;
  hWrite: THandle;
  suiStartup, si: TStartupInfo;
  piProcess: TProcessInformation;
  pBuffer: array[0..CReadBuffer] of AnsiChar;
  dRead: DWord;
  dRunning: DWord;
begin
  saSecurity.nLength := SizeOf(TSecurityAttributes);
  saSecurity.bInheritHandle := True;
  saSecurity.lpSecurityDescriptor := nil;

  if CreatePipe(hRead, hWrite, @saSecurity, 0) then
  begin
    FillChar(suiStartup, SizeOf(TStartupInfo), #0);
    suiStartup.cb := SizeOf(TStartupInfo);
    suiStartup.hStdInput := hRead;
    suiStartup.hStdOutput := hWrite;
    suiStartup.hStdError := hWrite;
    suiStartup.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
    suiStartup.wShowWindow := SW_SHOWNORMAL;
    if CreateProcess(nil, PChar(ACommand + ' ' + AParameters), @saSecurity, @saSecurity, True, NORMAL_PRIORITY_CLASS, nil, nil, suiStartup, piProcess) then
    begin
      repeat
        dRunning := WaitForSingleObject(piProcess.hProcess, 100);
        Application.ProcessMessages();
        repeat
          dRead := 0;
          ReadFile(hRead, pBuffer[0], CReadBuffer, dRead, nil);
          pBuffer[dRead] := #0;

          OemToAnsi(pBuffer, pBuffer);
          AMemo.Lines.Add(string(pBuffer));
        until (dRead < CReadBuffer);
      until (dRunning <> WAIT_TIMEOUT);
      CloseHandle(piProcess.hProcess);
      CloseHandle(piProcess.hThread);
    end;

    CloseHandle(hRead);
    CloseHandle(hWrite);
  end;
end;

function CalcChecked(LV: TListView): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to LV.Items.Count - 1 do
    if LV.Items[i].Checked then
      Inc(Result);
end;

function CurOSIsNewerXP: Boolean;
begin
  Result := Win32MajorVersion > 5;
end;

function MUILoad(MUI: string; var Icon: TIcon; var Str: string): TMUIType;
var
  hResModule: HMODULE;
  Path: string;
  ID: Cardinal;
  buffer: array[0..1023] of Char;
  ls: integer;
begin
  Result := mtNone;
  GetPathID(MUI, Path, ID);
  NormFileName(Path);
  hResModule := LoadLibraryEx(PWideChar(Path), 0, LOAD_LIBRARY_AS_DATAFILE or LOAD_LIBRARY_AS_IMAGE_RESOURCE);
  if hResModule <> 0 then
  begin
    ls := LoadStringW(hResModule, ID, buffer, SizeOf(buffer));
    if ls > 0 then
    begin
      Str := StrPas(buffer);
      Result := mtString;
    end
    else
    begin
     //;
     //if Integer(ExtractIconEx(PWideChar(Path), ID, Icon32, Icon16, 1)) > 0 then
      begin
        Icon := TIcon.Create;
        Icon.Handle := LoadImage(hResModule, MakeIntResource(ID), IMAGE_ICON, 16, 16, LR_COPYFROMRESOURCE);
        if Icon.Handle <> 0 then
          Result := mtIcon;
      end;
    end;
    FreeLibrary(hResModule);
  end;
 //DisposeStr(@buffer[1]);
{
 if MUI.Length > 0 then
        if MUI[1] = '@' then
         begin
          GetPathAndID(MUI, Tmp);
          ReplaceSysVar(Tmp);
          if FileExists(Tmp) then Dir:=nil
          else
           begin
            NormFileName(Tmp);
            Tmp:=ExtractFilePath(Tmp);
            Dir:=PWideChar(Tmp);
           end;
          NM:=Caption;
          OSize:=0;
          OBuf:=#0;
          MUIRes:=RegLoadMUIString(FRoll.CurrentKey,
                           PWideChar(NM),
                           @OBuf,
                           SizeOf(OBuf),
                           @OSize,
                           0,
                           Dir);
          if MUIRes = ERROR_SUCCESS then
           begin
            RegLoadMUIString(FRoll.CurrentKey,
                           PWideChar(NM),
                           @OBuf,
                           OSize,
                           @OSize,
                           0,
                           Dir);
            s:=Trim(StrPas(OBuf))+' ('+s+')';
           end;
         end;     }
end;

procedure CreateMessage(Text: string; Level: TMessageLevel);
var
  Cap: string;
  Icon: Integer;
begin
  case Level of
    mlInfo:
      begin
        Cap := 'Информация';
        Icon := MB_ICONINFORMATION;
      end;
    mlWarning:
      begin
        Cap := 'Внимание';
        Icon := MB_ICONWARNING;
      end;
    mlError:
      begin
        Cap := 'Ошибка';
        Icon := MB_ICONERROR;
      end;
  end;
  Log([Cap + ':', Text, SysErrorMessage(GetLastError)]);
  MessageBox(Application.Handle, PWideChar(Text), PWideChar(Cap), MB_OK or Icon);
end;

function GetFileIcon(const FileName: TFileName; Size: TIconSize; var destIcon: TIcon): Integer;
var
  Icon32, Icon16, IcEx: HICON;
  i, II: word;
begin
  Result := -1;
  try
    II := 0;
    IcEx := ExtractAssociatedIconEx(0, PChar(FileName), II, i);
    if IcEx > 0 then
    begin
      destIcon := TIcon.Create;
      if Integer(ExtractIconEx(PWideChar(FileName), i, Icon32, Icon16, 1)) > 0 then
        case Size of
          is16:
            IcEx := Icon16;
          is32:
            IcEx := Icon32;
        end;
      destIcon.Handle := IcEx;
      Result := IcEx;
    end;
  except
    on E: Exception do
      Exit;
  end;
end;

function GetFileIcon(const FileName: TFileName; Size: TIconSize; var destIcon: HICON): Integer;
var
  Icon32, Icon16, IcEx: HICON;
  i: word;
begin
  Result := -1;
  try
    IcEx := ExtractAssociatedIcon(0, PChar(FileName), i);
    if IcEx > 0 then
    begin
      if Integer(ExtractIconEx(PWideChar(FileName), i, Icon32, Icon16, 1)) > 0 then
        case Size of
          is16:
            IcEx := Icon16;
          is32:
            IcEx := Icon32;
        end;
      destIcon := IcEx;
      Result := IcEx;
    end;
  except
    on E: Exception do
      Exit;
  end;
end;

function GetFileIcon(const FileName: TFileName; Size: TIconSize; IL: TCustomImageList): Integer;
var
  Icon: TIcon;
  Icon32, Icon16, IcEx: HICON;
  i: word;
begin
  Result := -1;
  try
    IcEx := ExtractAssociatedIcon(0, PChar(FileName), i);
    if IcEx > 0 then
    begin
      Icon := TIcon.Create;
      if Integer(ExtractIconEx(PWideChar(FileName), i, Icon32, Icon16, 1)) > 0 then
        case Size of
          is16:
            IcEx := Icon16;
          is32:
            IcEx := Icon32;
        end;
      Icon.Handle := IcEx;
      Result := IL.AddIcon(Icon);
      FreeAndNil(Icon);
    end;
  except
    on E: Exception do
      Exit;
  end;
end;

function GetFileIcon(const FileName: TFileName; Size: TIconSize; IL: TCustomImageList; var II: Word): Integer;
var
  Icon: TIcon;
  Icon32, Icon16, IcEx: HICON;
  i: word;
begin
  Result := -1;
  try
    IcEx := ExtractAssociatedIcon(0, PChar(FileName), i);
    if IcEx > 0 then
    begin
      Icon := TIcon.Create;
      if Integer(ExtractIconEx(PWideChar(FileName), i, Icon32, Icon16, 1)) > 0 then
        case Size of
          is16:
            IcEx := Icon16;
          is32:
            IcEx := Icon32;
        end;
      Icon.Handle := IcEx;
      II := IL.AddIcon(Icon);
      Result := II;
      Icon.Free;
    end;
  except
    Exit;
  end;
end;

function GetFullPath(const ShortPath: string): string;
begin
  Result := ExpandFileName(ShortPath);
end;

function GetEnvironmentStrings1: string;
{Переменные среды}
var
  ptr: PChar;
  s: string;
  Done: boolean;
begin
  s := '';
  Result := '';
  Done := FALSE;
  ptr := windows.GetEnvironmentStrings;
  while Done = false do
  begin
    if ptr^ = #0 then
    begin
      inc(ptr);
      if ptr^ = #0 then
        Done := TRUE
      else
        Result := Result + s + #13#10;
      s := ptr^;
    end
    else
      s := s + ptr^;
    inc(ptr);
  end;
end;

function SetPrivilege(aPrivilegeName: string; aEnabled: boolean): boolean;
var
  TPPrev, TP: TTokenPrivileges;
  Token: THandle;
  dwRetLen: DWord;
begin
  Result := False;
  OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, Token);

  TP.PrivilegeCount := 1;
  if (LookupPrivilegeValue(nil, PChar(aPrivilegeName), TP.Privileges[0].LUID)) then
  begin
    if (aEnabled) then
      TP.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED
    else
      TP.Privileges[0].Attributes := 0;

    dwRetLen := 0;
    Result := AdjustTokenPrivileges(Token, False, TP, SizeOf(TPPrev), TPPrev, dwRetLen);
  end;
  CloseHandle(Token);
end;

function ReadRegString(KEY: HKEY; Path, Item: string): string;
var
  Roll: TRegistry;
begin
  try
    Roll := TRegistry.Create(KEY_READ);
    Roll.RootKey := KEY;
    if Roll.OpenKeyReadOnly(Path) then
    try
      Result := Roll.ReadString(Item);
    except
      begin
        Log(['Несмог прочесть', Path, 'из', Item]);
        Exit('');
      end;
    end;
  finally
    FreeAndNil(Roll);
  end;
end;

function GetTempDir: string;
var
  len: Cardinal;
begin
  SetLength(Result, MAX_PATH + 1);
  len := GetTempPath(MAX_PATH, PWideChar(Result));
  SetLength(Result, len);
end;

function AddToListWOR(Item: string; List: TStrings): Boolean;
var
  i: Word;
  tmp: string;
begin
  if not Assigned(List) then
    Exit(False);
  if List.Count <= 0 then
  begin
    try
      List.Add(Item);
      Result := True;
    except
      Result := False;
    end;
    Exit;
  end;
  tmp := AnsiLowerCase(Item);
  for i := 0 to List.Count - 1 do
    if tmp = AnsiLowerCase(List.Strings[i]) then
      Exit(False);
  try
    List.Add(Item);
    Result := True;
  except
    Result := False;
  end;
end;

function AddToListW(Item: string; List: TStrings): Boolean;
begin
  if not Assigned(List) then
    Exit(False);
  begin
    try
      List.Add(Item);
      Result := True;
    except
      Result := False;
    end;
    Exit;
  end;
end;

function GetUsersPaths(DefaultUP: string): TStrings;
var
  Roll: TRegistry;
  TMP: TStrings;
  ProfPath: string;
  i: Word;
begin
  Result := GetDirectores(DefaultUP);
  try
    Roll := TRegistry.Create(KEY_READ);
    Roll.RootKey := HKEY_LOCAL_MACHINE;
    if Roll.OpenKeyReadOnly('SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList') then
    begin
      TMP := TStringList.Create;
      Roll.GetKeyNames(TMP);
      if TMP.Count > 0 then
        for i := 0 to TMP.Count - 1 do
        begin
          Roll.CloseKey;
          if Roll.OpenKeyReadOnly('SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\' + TMP.Strings[i]) then
          begin
            ProfPath := ReplaceSysVarF(Roll.ReadString('ProfileImagePath'));
            AddToListWOR(ProfPath, Result);
          end;
        end;
    end;
  finally
    Roll.Free;
    TMP.Free;
  end;
end;

procedure CreateSubItems(var LI: TListItem; const Count: Word);
var
  i: Word;
begin
  if Count <= 0 then
    Exit;
  for i := 1 to Count do
    LI.SubItems.Add('');
end;

function BoolStr(Value: Boolean; const VTrue, VFalse: string): string;
begin
  if Value then
    Exit(VTrue)
  else
    Exit(VFalse);
end;

function BoolStr(Value: Boolean): string;
begin
  Result := BoolStr(Value, 'Да', 'Нет');
end;

procedure AlphaBlendPixel(ABitmap: TBitmap; X, Y: integer; R, G, B: byte; ARatio: Real);
var
  LBack, LNew: TRGBTriple;
  LMinusRatio: Real;
  LScan: PRGBTripleArray;
begin
  if (X < 0) or (X > ABitmap.Width - 1) or (Y < 0) or (Y > ABitmap.Height - 1) then
    Exit; // clipping
  LScan := ABitmap.Scanline[Y];
  LMinusRatio := 1 - ARatio;
  LBack := LScan[X];
  LNew.rgbtBlue := round(B * ARatio + LBack.rgbtBlue * LMinusRatio);
  LNew.rgbtGreen := round(G * ARatio + LBack.rgbtGreen * LMinusRatio);
  LNew.rgbtRed := round(R * ARatio + LBack.rgbtRed * LMinusRatio);
  LScan[X] := LNew;
end;

procedure WuLine(ABitmap: TBitmap; Point1, Point2: TPoint; AColor: TColor);
var
  deltax, deltay, loop, start, finish: integer;
  dx, dy, dydx: single; // fractional parts
  LR, LG, LB: byte;
  x1, x2, y1, y2: integer;
begin
  x1 := Point1.X;
  y1 := Point1.Y;
  x2 := Point2.X;
  y2 := Point2.Y;
  deltax := abs(x2 - x1); // Calculate deltax and deltay for initialisation
  deltay := abs(y2 - y1);
  if (deltax = 0) or (deltay = 0) then
  begin // straight lines
  {ABitmap.Canvas.Pen.Color := AColor;
   ABitmap.Canvas.MoveTo(x1, y1);
   ABitmap.Canvas.LineTo(x2, y2);   MixColors(clRed, clLime, PT);
   exit;}
    deltax := 1;
  end;                  {
 LR := (AColor and $000000FF);
 LG := (AColor and $0000FF00) shr 8;
 LB := (AColor and $00FF0000) shr 16;    }
  if deltax > deltay then
  begin // horizontal or vertical
    if y2 > y1 then
      dydx := -(deltay / deltax)
    else
      dydx := deltay / deltax;
    if x2 < x1 then
    begin
      start := x2; // right to left
      finish := x1;
      dy := y2;
    end
    else
    begin
      start := x1; // left to right
      finish := x2;
      dy := y1;
      dydx := -dydx; // inverse slope
    end;
    for loop := start to finish do
    begin
      AColor := MixColors(clLime, clRed, Round((trunc(dy) * 100) / ABitmap.Canvas.ClipRect.Height));
      LR := (AColor and $000000FF);
      LG := (AColor and $0000FF00) shr 8;
      LB := (AColor and $00FF0000) shr 16;
      AlphaBlendPixel(ABitmap, loop, trunc(dy), LR, LG, LB, 1 - frac(dy));
      AlphaBlendPixel(ABitmap, loop, trunc(dy) + 1, LR, LG, LB, frac(dy));
      dy := dy + dydx; // next point
    end;
  end
  else
  begin
    if x2 > x1 then
      dydx := -(deltax / deltay)
    else
      dydx := deltax / deltay;
    if y2 < y1 then
    begin
      start := y2; // right to left
      finish := y1;
      dx := x2;
    end
    else
    begin
      start := y1; // left to right
      finish := y2;
      dx := x1;
      dydx := -dydx; // inverse slope
    end;
    for loop := start to finish do
    begin
      AColor := MixColors(clLime, clRed, Round((loop * 100) / ABitmap.Canvas.ClipRect.Height));
      LR := (AColor and $000000FF);
      LG := (AColor and $0000FF00) shr 8;
      LB := (AColor and $00FF0000) shr 16;
      AlphaBlendPixel(ABitmap, trunc(dx), loop, LR, LG, LB, 1 - frac(dx));
      AlphaBlendPixel(ABitmap, trunc(dx) + 1, loop, LR, LG, LB, frac(dx));
      dx := dx + dydx; // next point
    end;
  end;
end;

function MixBytes(FG, BG, TRANS: byte): byte;
begin
  Result := Round(BG + (FG - BG) / 255 * TRANS);
end;

function MixColors(FG, BG: TColor; T: byte): TColor;
var
  r, g, b: byte;
begin
  T := Round((255 / 100) * T);
  if T = 0 then
    T := 1;

  r := MixBytes(FG and 255, BG and 255, T); // extracting and mixing Red
  g := MixBytes((FG shr 8) and 255, (BG shr 8) and 255, T); // the same with green
  b := MixBytes((FG shr 16) and 255, (BG shr 16) and 255, T); // and blue, of course
  Result := r + g * 256 + b * 65536; // finishing with combining all channels together
end;

function FileTimeToInt(Value: TFileTime): Int64;
begin
  Result := (Value.dwHighDateTime shl 32) or (Value.dwLowDateTime);
end;

function CompareFileTimeOwn(t1, t2: FILETIME): Int64;
var
  a, b: Int64;
begin
  a := (t1.dwHighDateTime shl 32) or (t1.dwLowDateTime);
  b := (t2.dwHighDateTime shl 32) or (t2.dwLowDateTime);
  Result := b - a;
end;

function CPUUsage: Extended;
var
  idle, user, krnl: TFileTime;
  i, u, k: int64;
begin
  GetSystemTimes(idle, krnl, user);
  i := CompareFileTimeOwn(idle, preIdleTime);
  u := CompareFileTimeOwn(user, preUserTime);
  k := CompareFileTimeOwn(krnl, preKrnlTime);
  Result := (k + u - i) * 100 / (k + u + 0.00001);
  if Result > 100 then
    Result := 100
  else if Result < 0 then
    Result := 0;
  preIdleTime := idle;
  preUserTime := user;
  preKrnlTime := krnl;
end;

function FindMatchingFile(var F: TSearchRec): Integer;
var
  LocalFileTime: TFileTime;
begin
  while F.FindData.dwFileAttributes and F.ExcludeAttr <> 0 do
    if not FindNextFile(F.FindHandle, F.FindData) then
    begin
      Result := GetLastError;
      Exit;
    end;
  FileTimeToLocalFileTime(F.FindData.ftLastWriteTime, LocalFileTime);
  //FileTimeToDosDateTime(LocalFileTime, LongRec(F.Time).Hi, LongRec(F.Time).Lo);
  F.Size := F.FindData.nFileSizeLow or Int64(F.FindData.nFileSizeHigh) shl 32;
  F.Attr := F.FindData.dwFileAttributes;
  F.Name := F.FindData.cFileName;
  Result := 0;
end;

function FindFirst1(const Path: string; Attr: Integer; var F: TSearchRec): Integer;
const
  faSpecial = faHidden or faSysFile or faDirectory;
begin
  F.ExcludeAttr := not Attr and faSpecial;
  F.FindHandle := FindFirstFile(PChar(Path), F.FindData);   //295 976
  Result := FindMatchingFile(F);
  FindClose(F);
end;

function ExistsFile(FileName: string): Boolean;
var
  SR: TSearchRec;
begin
  Result := FindFirst1(FileName, faAnyFile, SR) = 0;
  FindClose(SR);
end;

function FileTimeToDateTime(FileTime: TFileTime): TDateTime;
var
  ModifiedTime: TFileTime;
  SystemTime: TSystemTime;
begin
  Result := 0.1;
  if (FileTime.dwLowDateTime = 0) and (FileTime.dwHighDateTime = 0) then
    Exit;
  try
    FileTimeToLocalFileTime(FileTime, ModifiedTime);
    FileTimeToSystemTime(ModifiedTime, SystemTime);
    Result := SystemTimeToDateTime(SystemTime);
  except
    Result := 0.1;  // Something to return in case of error
  end;
end;

function DeleteForceFile(const FileName: string): Boolean;
var
  LastError: Cardinal;
begin
  Result := Windows.DeleteFile(PChar(FileName));
  if not Result then
  begin
    LastError := GetLastError;
    if SysUtils.DirectoryExists(FileName) then
    begin
      ForceRemoveDir(FileName);
      Exit(not SysUtils.DirectoryExists(FileName));
    end;
    SetLastError(LastError);
  end;
end;

function GetFileNameFromLink(LinkFileName: string): string;
var
  MyObject: IUnknown;
  MySLink: IShellLink;
  MyPFile: IPersistFile;
  FileInfo: TWin32FINDDATA;
  Buff: array[0..MAX_PATH] of Char;
begin
  Result := '';
  if not FileExists(LinkFileName) then
    Exit;
  MyObject := CreateComObject(CLSID_ShellLink);
  MyPFile := MyObject as IPersistFile;
  MySLink := MyObject as IShellLink;
  MyPFile.Load(PWideChar(LinkFileName), STGM_READ);
  MySLink.GetPath(Buff, MAX_PATH, FileInfo, SLGP_UNCPRIORITY);

  //FreeAndNil(MyObject);
  Result := Buff;
end;

function InstallDateToNorm(InstDate: string; const Def: TDateTime): TDateTime;
var
  Y, M, D: string;
begin
  if InstDate.Length < 8 then
    Exit(Def);
  if InstDate.Length > 8 then
        //1234567890
  begin //02/01/2015
    M := Copy(InstDate, 1, 2);
    D := Copy(InstDate, 4, 2);
    Y := Copy(InstDate, 7, 4); //2014
  end
  else
  begin
    Y := Copy(InstDate, 1, 4); //2014
    M := Copy(InstDate, 5, 2); //12
    D := Copy(InstDate, 7, 2); //13
  end;


 //Insert('.', InstDate, 5); //2014.1213
 //Insert('.', InstDate, 8); //2014.12.13
  InstDate := Format('%s.%s.%s', [D, M, Y]); //13.12.2014
 //if TryStrToDate(InstDate, Result) then
 //ShowMessage(InstDate);

  Result := StrToDateTimeDef(InstDate, Def);
end;

function DeleteStrQM(Value: string): string;
begin
  while Pos('"', Value) <> 0 do
    Delete(Value, Pos('"', Value), 1);

  Result := DelFLSpace(Value);
end;

function BoolToLang(Value: Boolean): string;
begin
  Result := 'Нет';
  if Value then
    Result := 'Да';
end;

procedure TProcessMonitor.Stop;
begin
  FStopping := True;
end;

function TProcessMonitor.FindChildProcess(PID: Cardinal; var CPID: Cardinal): Boolean;
var
  hSnap: THandle;
  PE: TProcessEntry32;
begin
  Result := False;
  PE.dwSize := SizeOf(TProcessEntry32);
  hSnap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if Process32First(hSnap, PE) then
    repeat
      if PE.th32ParentProcessID = PID then
      begin
        CPID := PE.th32ProcessID;
        Exit(True);
      end;
    until not (Process32Next(hSnap, PE));
end;

function TProcessMonitor.WaitStop(PID: Cardinal): Boolean;
var
  ExitCode: Cardinal;
  ProcessHandle: THandle;
begin
  Result := True;
  FWorking := True;
  ProcessHandle := OpenProcess(PROCESS_QUERY_INFORMATION, False, PID);
  while GetExitCodeProcess(ProcessHandle, ExitCode) and (ExitCode = STILL_ACTIVE) do
  begin
    Application.ProcessMessages;
    if Application.Terminated or FStopping then
    begin
      FWorking := False;
      FStopping := False;
      Exit(False);
    end;
  end;
  FWorking := False;
  FStopping := False;
end;

function TProcessMonitor.ExecuteAndWait(cmdLine: string): Boolean;
var
  SI: TStartupInfo;
  PI: TProcessInformation;
  CPID: Cardinal;
begin
  Result := False;
  FStopping := False;
  if Length(cmdLine) <= 0 then
  begin
    Log(['Создание процесса с нулевым значением команды: "', cmdLine, '"']);
    Exit;
  end;
  FillChar(SI, SizeOf(SI), 0);
  SI.cb := SizeOf(SI);
  Result := CreateProcess(nil, PChar(cmdLine), nil, nil, False, 0, nil, PChar(CurrentDir), SI, PI);
  if Result then
  begin
    FExecuting := True;
    FPID := PI.dwProcessId;
    if not WaitStop(FPID) then
      Exit(False);
    while FindChildProcess(FPID, CPID) do
    begin
      WaitStop(CPID);
      Application.ProcessMessages;
      if FStopping then
      begin
        FExecuting := False;
        Exit(False);
      end;
    end;
  end
  else
  begin
    Log(['Не смог создать процесс:', cmdLine, Result, ' Ошибка:', GetLastError]);
    ShowMessage('Не смог выполнить команду: ' + cmdLine);
  end;
  FExecuting := False;
end;

function TProcessMonitor.Execute(cmdLine: string): Boolean;
var
  SI: TStartupInfo;
  PI: TProcessInformation;
  CPID: Cardinal;
begin
  Result := False;
  FStopping := False;
  if Length(cmdLine) <= 0 then
  begin
    Log(['Создание процесса с нулевым значением команды: "', cmdLine, '"']);
    Exit;
  end;
  FillChar(SI, SizeOf(SI), 0);
  SI.cb := SizeOf(SI);
  Result := CreateProcess(nil, PChar(cmdLine), nil, nil, False, 0, nil, PChar(CurrentDir), SI, PI);
  if Result then
  begin
    FExecuting := True;
    FPID := PI.dwProcessId;
    if not WaitStop(FPID) then
      Exit(False);
    while FindChildProcess(FPID, CPID) do
    begin
      WaitStop(CPID);
      Application.ProcessMessages;
      if FStopping then
      begin
        FExecuting := False;
        Exit(False);
      end;
    end;
  end
  else
  begin
    Log(['Не смог создать процесс:', cmdLine, Result, ' Ошибка:', GetLastError]);
    ShowMessage('Не смог выполнить команду: ' + cmdLine);
  end;
  FExecuting := False;
end;

//Рекурсивное удаление каталогов
function ForceRemoveDir(sDir: string): Boolean;
var
  iIndex: Integer;
  SearchRec: TSearchRec;
  sFileName: string;
begin
  Result := True;
  sDir := sDir + '\*.*';
  iIndex := FindFirst(sDir, faAnyFile, SearchRec);
  while iIndex = 0 do
  begin
    if Stopping then
      Exit(False);
    sFileName := ExtractFileDir(sDir) + '\' + SearchRec.name;
    if (SearchRec.Attr and faDirectory = faDirectory) then
    begin
      if (SearchRec.name <> '') and (SearchRec.name <> '.') and (SearchRec.name <> '..') then
      begin
        if not ForceRemoveDir(sFileName) then
          Break;
        Result := False;
      end;
    end
    else
    begin
      if not DeleteFile(sFileName) then
        Result := False;
    end;
    iIndex := FindNext(SearchRec);
  end;
  FindClose(SearchRec);
  try
    RemoveDir(ExtractFileDir(sDir));
  except
    Result := False;
  end;
end;

//Кол-во элементов группы
function GetItemCount(LV: TListView; GID: Integer): Cardinal;
var
  i: Word;
begin
  Result := 0;
  if LV.Items.Count <= 0 then
    Exit;
  for i := 0 to LV.Items.Count - 1 do
  begin
    if LV.Items[i].GroupID = GID then
      Inc(Result);
    if Stopping then
      Exit;
  end;
end;

//Получение информации о файле
function GetFileVersionInfo(FileName: WideString; var VersionInfo: TVersionInfo): Boolean;
var
  Handle, Len, Size: Cardinal;
  Translation: WideString;
  Data: PWideChar;
  Buffer: Pointer;
  FixedFileInfo: PVSFixedFileInfo;
begin
  Result := False;
  Data := nil;
  Finalize(VersionInfo);
  try
    Size := GetFileVersionInfoSizeW(PWideChar(FileName), Handle);
    if Size > 0 then
    begin
      try
        GetMem(Data, Size);
        if GetFileVersionInfoW(PWideChar(FileName), Handle, Size, Data) then
        begin
          if VerQueryValue(Data, '\', Pointer(FixedFileInfo), Len) then
          begin
            VersionInfo.Debug := False;
            VersionInfo.Patched := False;
            VersionInfo.PreRelease := False;
            VersionInfo.PrivateBuild := False;
            VersionInfo.SpecialBuild := False;

            VersionInfo.FileVersionMajor := HiWord(FixedFileInfo^.dwFileVersionMS);
            VersionInfo.FileVersionMinor := LoWord(FixedFileInfo^.dwFileVersionMS);
            VersionInfo.FileVersionRelease := HiWord(FixedFileInfo^.dwFileVersionLS);
            VersionInfo.FileVersionBuild := LoWord(FixedFileInfo^.dwFileVersionLS);
            VersionInfo.ProductVersionMajor := HiWord(FixedFileInfo^.dwProductVersionMS);
            VersionInfo.ProductVersionMinor := LoWord(FixedFileInfo^.dwProductVersionMS);
            VersionInfo.ProductVersionRelease := HiWord(FixedFileInfo^.dwProductVersionLS);
            VersionInfo.ProductVersionBuild := LoWord(FixedFileInfo^.dwProductVersionLS);

            VersionInfo.FileVersion := IntToStr(HiWord(FixedFileInfo^.dwFileVersionMS)) + '.' + IntToStr(LoWord(FixedFileInfo^.dwFileVersionMS)) + '.' + IntToStr(HiWord(FixedFileInfo^.dwFileVersionLS)) + '.' + IntToStr(LoWord(FixedFileInfo^.dwFileVersionLS))
          end;

          if VerQueryValueW(Data, '\VarFileInfo\Translation', Buffer, Len) then
          begin
            Translation := IntToHex(PDWORD(Buffer)^, 8);
            Translation := Copy(Translation, 5, 4) + Copy(Translation, 1, 4);
            VersionInfo.Translation := '$' + Copy(Translation, 1, 4);
            SetLength(VersionInfo.Language, 64);
            SetLength(VersionInfo.Language, VerLanguageNameW(StrToIntDef('$' + Copy(Translation, 1, 4), $0409), PWideChar(VersionInfo.Language), 64));
          end;

          if VerQueryValueW(Data, PWideChar('\StringFileInfo\' + Translation + '\CompanyName'), Buffer, Len) then
            VersionInfo.CompanyName := PWideChar(Buffer);

          if VerQueryValueW(Data, PWideChar('\StringFileInfo\' + Translation + '\FileDescription'), Buffer, Len) then
            VersionInfo.FileDescription := PWideChar(Buffer);

          if VerQueryValueW(Data, PWideChar('\StringFileInfo\' + Translation + '\FileVersion'), Buffer, Len) then
            VersionInfo.FileVersion := PWideChar(Buffer);

          if VerQueryValueW(Data, PWideChar('\StringFileInfo\' + Translation + '\InternalName'), Buffer, Len) then
            VersionInfo.InternalName := PWideChar(Buffer);

          if VerQueryValueW(Data, PWideChar('\StringFileInfo\' + Translation + '\LegalCopyright'), Buffer, Len) then
            VersionInfo.LegalCopyright := PWideChar(Buffer);

          if VerQueryValueW(Data, PWideChar('\StringFileInfo\' + Translation + '\LegalTradeMarks'), Buffer, Len) then
            VersionInfo.LegalTradeMarks := PWideChar(Buffer);

          if VerQueryValueW(Data, PWideChar('\StringFileInfo\' + Translation + '\OriginalFilename'), Buffer, Len) then
            VersionInfo.OriginalFilename := PWideChar(Buffer);

          if VerQueryValueW(Data, PWideChar('\StringFileInfo\' + Translation + '\ProductName'), Buffer, Len) then
            VersionInfo.ProductName := PWideChar(Buffer);

          if VerQueryValueW(Data, PWideChar('\StringFileInfo\' + Translation + '\ProductVersion'), Buffer, Len) then
            VersionInfo.ProductVersion := PWideChar(Buffer);

          if VerQueryValueW(Data, PWideChar('\StringFileInfo\' + Translation + '\Comments'), Buffer, Len) then
            VersionInfo.Comments := PWideChar(Buffer);
          Result := True;
        end;
      finally
        FreeMem(Data);
      end;
    end;
  except
  end;
end;

//Занят ли файл кем-либо
function OccupiedFile(FN: string): Boolean;
var
  F: file;
begin
  Result := False;
  try
    AssignFile(F, FN);
    Reset(F);
    CloseFile(F);
  except
    Result := True;
  end;
end;

//Добавить элемент в список "Параметр-значение"
procedure AddToValueEdit(VE: TValueListEditor; Key, Value, ValueBU: string);
begin
  if Key = '' then
    Key := 'Неизвестный параметр';
  if Length(Value) < 1 then
    if ValueBU <> '' then
      Value := ValueBU;
  if Value <> '' then
    VE.Strings.Add(Key + '=' + Value);
end;

//Замена переменных сред
procedure ReplaceSysVar(var Src: string);
var
  FullPath: array[0..MAX_PATH - 1] of Char;
begin
  try
    RepVar(Src, 'systemroot\', '%SYSTEMROOT%\');
    RepVar(Src, 'msiexec ', 'msiexec.exe ');
    RepVar(Src, '%curpath%', CurrentDir);
    RepVar(Src, 'rundll32 ', C + 'Windows\System32\rundll32.exe ');
    ExpandEnvironmentStrings(PChar(Src), @FullPath[0], MAX_PATH);
  finally
    Src := FullPath;
  end;
end;

//Замена переменных сред
function ReplaceSysVarF(Src: string): string;
begin
  ReplaceSysVar(Src);
  Result := Src;
end;

//Выбор элемента в проводнике
function OpenFolderAndOrSelectFile(const FileName: string): boolean;
var
  Str: string;
  i: Integer;
begin
  Str := NormFileNameF(FileName);
  if not FileExists(Str) then
  begin
    Log(['Не смог обнаружить файл:', Str]);
    if MessageBox(Application.Handle, PChar('Не смог обнаружить файл: ' + Str + #13#10'Попробовать открыть каталог файла?'), 'Внимание', MB_YESNO or MB_ICONWARNING) <> ID_YES then
      Exit;
    repeat
      i := Str.LastDelimiter(PathDelim + DriveDelim);
      Str := ExtractFilePath(Str).Substring(0, i);
    until DirectoryExists(Str) or (Pos(':', Str) = 0) or (Str.Length <= 1);
    ShellExecute(Application.Handle, 'open', PWideChar(Str), nil, nil, SW_NORMAL);
    Exit;
  end;
  OpenFolderAndSelectFile(Str);
end;

//Выбор элемента в проводнике
function OpenFolderAndSelectFile(const FileName: string): boolean;
var
  IIDL: PItemIDList;
begin
  Result := False;
  IIDL := ILCreateFromPath(PChar(FileName));
  if IIDL <> nil then
  try
    Result := SHOpenFolderAndSelectItems(IIDL, 0, nil, 0) = S_OK;
  finally
    ILFree(IIDL);
  end
  else
    Log(['ILCreateFromPath(PChar(FileName)) = nil. FileName=', FileName]);
end;

//Получить метки ЖД по порядку в строке
function GetHDDrives: string;
const
  DRIVE_FIXED = 3;
var
  HResult: Cardinal;
  Buffer: array[0..128] of Char;
  Drive: PChar;
begin
  Result := '';
  HResult := GetLogicalDriveStrings(SizeOf(Buffer), Buffer);
  if HResult = 0 then
    Exit;
  if HResult > SizeOf(Buffer) then
    raise Exception.Create(SysErrorMessage(ERROR_OUTOFMEMORY));
  Drive := Buffer;
  while Drive^ <> #0 do
  begin
    if GetDriveType(Drive) = DRIVE_FIXED then
      Result := Result + Drive[0];
    Inc(Drive, DRIVE_FIXED + 1);
  end;
end;

//Byte в Hex
function ByteToHexStr(Data: Pointer; Len: Integer): string;
var
  I, Octets, PartOctets: Integer;
  DumpData: string;
begin
  if Len = 0 then
    Exit;
  I := 0;
  Octets := 0;
  PartOctets := 0;
  Result := '';
  while I < Len do
  begin
    case PartOctets of
      0:
        Result := Result + Format('%.4d: ', [Octets]);
      9:
        begin
          Inc(Octets, 10);
          PartOctets := -1;
          Result := Result + '    ' + DumpData + sLineBreak;
          DumpData := '';
        end;
    else
      begin
        Result := Result + Format('%s ', [IntToHex(TByteArray(Data^)[I], 2)]);
        if TByteArray(Data^)[I] in [$19..$FF] then
          DumpData := DumpData + Chr(TByteArray(Data^)[I])
        else
          DumpData := DumpData + '.';
        Inc(I);
      end;
    end;
    Inc(PartOctets);
  end;
  if PartOctets <> 0 then
  begin
    PartOctets := (8 - Length(DumpData)) * 3;
    Inc(PartOctets, 4);
    Result := Result + StringOfChar(' ', PartOctets) + DumpData
  end;
end;

//Word в Hex
function WordToHexStr(Data: Pointer; Len: Integer): string;
var
  I, Octets, PartOctets: Integer;
  ByteCount: Byte;
  OutputValue: DWORD;
begin
  if Len = 0 then
    Exit;
  I := 0;
  Octets := 0;
  PartOctets := 0;
  Result := '';
  while I < Len do
  begin
    case PartOctets of
      0:
        Result := Result + Format('%.4d: ', [Octets]);
      5:
        begin
          PartOctets := -1;
          Inc(Octets, 10);
          Result := Result + sLineBreak;
        end
    else
      ByteCount := 0;
      OutputValue := 0;
      if I < Len then
      begin
        OutputValue := TByteArray(Data^)[I];
        Inc(ByteCount, 2);
      end;
      if I + 1 < Len then
      begin
        OutputValue := OutputValue + (TByteArray(Data^)[I + 1] shl 8);
        Inc(ByteCount, 2);
      end;
      if I + 2 < Len then
      begin
        OutputValue := OutputValue + (TByteArray(Data^)[I + 2] shl 16);
        Inc(ByteCount, 2);
      end;
      if I + 3 < Len then
      begin
        OutputValue := OutputValue + (TByteArray(Data^)[I + 3] shl 24);
        Inc(ByteCount, 2);
      end;
      Result := Result + Format('%s ', [IntToHex(OutputValue, ByteCount)]);
      Inc(I, 4);
    end;
    Inc(PartOctets);
  end;
end;

//Языковой идентификатор
function LangText(ID: Integer; Text: string): string;
begin
  if LangH <= 0 then
    Result := Text
  else
    Result := LoadString(64000 + ID);
  if Result = '' then
    Result := Text;
end;

//Строка из LangDll
function LoadString(sID: Cardinal): string;
begin
  try
    Result := LoadString(LangH, sID);
  finally

  end;
end;

//Строка из модуля
function LoadString(h: THandle; sID: Cardinal): string;
var
  buffer: array[0..255] of Char;
begin
  Windows.LoadString(h, sID, @buffer, 256);
  Result := StrPas(buffer);
end;

//Удаление лишних пробелов (в начале и в конце)
function DelFLSpace(str: string): string;
begin
  if str = '' then
    Exit(str);
  while str[1] = ' ' do
    str := Copy(str, 2, Length(str) - 1);
  while str[Length(str)] = ' ' do
    str := Copy(str, 1, Length(str) - 1);

  Result := str;
end;

//Удаление лишних пробелов (в начале, в конце и двойных)
function DelFLDSpace(str: string): string;
begin
  if str = '' then
    Exit(str);
  while str[1] = ' ' do
    str := Copy(str, 2, Length(str) - 1);
  while str[Length(str)] = ' ' do
    str := Copy(str, 1, Length(str) - 1);
  while Pos('  ', str) > 0 do
    Delete(str, Pos('  ', str), 1);

  Result := str;
end;

//Str в PAnsi
function StrToPAnsi(Str: string): PAnsiChar;
begin
  Result := PAnsiChar(AnsiString(Str));
end;

//WinExec
function WinExec(lpCmdLine: string; uCmdShow: UINT): UINT;
begin
  Result := Windows.WinExec(StrToPAnsi(lpCmdLine), uCmdShow);
end;

//Дата изменения файла
function GetFileDateChg(FileName: string): TDateTime;
var
  FHandle: Integer;
begin
  FHandle := FileOpen(FileName, OF_READ);
  if FHandle <= 0 then
    Exit(Now);
  try
    Result := FileDateToDateTime(FileGetDate(FHandle));
  finally
    FileClose(FHandle);
  end;
end;

//Получить ИД группы по названию (если нет - добавить)
function GetGroup(LV: TListView; GroupName: string; Expand: Boolean): Word;
var
  i: Word;
  NewGroup: TListGroup;
begin
  if GroupName = '' then
    GroupName := 'Без группы';
  if LV.Groups.Count > 0 then
    for i := 0 to LV.Groups.Count - 1 do
      if LV.Groups.Items[i].Header = GroupName then
      begin
        Result := i;
        Exit;
      end;
  NewGroup := LV.Groups.Add;
  with NewGroup do
  begin
    Header := GroupName;
    Result := GroupID;
    if not Expand then
      NewGroup.State := [lgsNormal, lgsCollapsible, lgsCollapsed]
    else
      NewGroup.State := [lgsNormal, lgsCollapsible];
  end;
end;

//Лог
procedure Log(Value: array of const); overload;
var
  i: Integer;
  Result: string;
begin
  for i := Low(Value) to High(Value) do
    case Value[i].VType of
      vtInteger:
        Result := Result + IntToStr(Value[i].VInteger) + ' ';
      vtString:
        Result := Result + AnsiString(Value[i].VPWideChar) + ' ';
      vtBoolean:
        Result := Result + IntToStr(Ord(Value[i].VBoolean)) + ' ';
      vtChar:
        Result := Result + AnsiString(Value[i].VPWideChar) + ' ';
      vtExtended:
        Result := Result + FloatToStr(Value[i].VExtended^) + ' ';
      vtPointer:
        Result := Result + IntToStr(Integer(@Value[i].VPointer)) + ' ';
      vtPChar:
        Result := Result + AnsiString(Value[i].VPWideChar) + ' ';
      vtObject:
        if Value[i].VObject <> nil then
          Result := Result + Value[i].VObject.ClassName + ' '
        else
          Result := Result + 'Object is nil ';
      vtClass:
        if Value[i].VClass <> nil then
          Result := Result + Value[i].VClass.ClassName + ' '
        else
          Result := Result + 'Class is nil ';
      vtWideChar:
        Result := Result + AnsiString(Value[i].VWideChar) + ' ';
      vtPWideChar:
        Result := Result + AnsiString(Value[i].VWideChar) + ' ';
      vtAnsiString:
        Result := Result + AnsiString(Value[i].VPWideChar) + ' ';
      vtCurrency:
        Result := Result + FloatToStr(Currency(Value[i].VCurrency^)) + ' ';
      vtVariant:
        Result := Result + '@Variant@ ';
      vtInterface:
        Result := Result + '@Interface@ ';
      vtWideString:
        Result := Result + AnsiString(Value[i].VPWideChar) + ' ';
      vtInt64:
        Result := Result + IntToStr(Integer(Value[i].VInt64^)) + ' ';
      vtUnicodeString:
        Result := Result + AnsiString(Value[i].VPWideChar) + ' ';
    end;
  LogBuf := Result;
  AddToLogList(LogBuf);
  if NotUseLog then
    Exit;
  Logging;
 //CreateThread(nil, 0, @Logging, nil, 0, ThreadLogID);
end;

//Выгрузить из внутреннего лога
procedure Unload;
begin
  if not Assigned(SLog) then
    Exit;
  if not Assigned(LogList) then
    Exit;
  if SLog.Count > 0 then
  begin
    LogList^.Lines.AddStrings(SLog);
    if Assigned(SLog) then
      SLog.Free;
  end;
end;

//Добавить в лог
procedure AddToLogList(Text: string);
begin
  if not Assigned(LogList) then
  begin
    try
      if not Assigned(SLog) then
        SLog := TStringList.Create;
      SLog.Add(Format('[%.6d] %s - %s', [0, FormatDateTime('c', Now), Text]));
    except
      Exit;
    end;
  end
  else
  begin
    Unload;
    LogList^.Lines.Insert(0, Format('[%.6d] %s - %s', [LogList^.Lines.Count, FormatDateTime('c', Now), Text]));
   //LogList^.Lines.Add();
  end;
end;

//Лог в файл
procedure Logging;
begin
  try
    Append(LogFile);
    writeln(LogFile, DateTimeToStr(Date + Time) + ': ' + LogBuf);
    Append(LogFile);
  except
    begin
      AddToLogList('cwm.log: ' + SysErrorMessage(GetLastError));
      NotUseLog := True;
    end;
  end;
 //writeln(LogFile, 'ggg');
end;

//Перевернуть строку
function Reverse(s: string): string;
var
  i: Word;
begin
  if Length(s) <= 1 then
    Exit(s);
  for i := Length(s) downto 1 do
    Result := Result + s[i];
end;

//Имя файла без разширения
function GetFileNameWoE(FileName: TFileName): string;
var
  PPos: Integer;
  str: string;
begin
  str := ExtractFileName(FileName);
  if Length(str) < 3 then
    Exit;
  PPos := Pos('.', Reverse(str));
  if PPos > 0 then
    Result := Copy(str, 1, Length(str) - PPos);
end;

//Получить задачи 2.0
procedure GetTasks(Folder: ITaskFolder; AllFolder: Boolean; var TL: TTasksList);
var
  i: integer;
  TaskFolder: ITaskFolderCollection;
  TaskCollection: IRegisteredTaskCollection;
begin
  if Application.Terminated then
    Exit;
  TaskCollection := Folder.GetTasks(1);
  for i := 1 to TaskCollection.Count do
    TL.Add(TaskCollection.Item[i]);
  if AllFolder then
  begin
    TaskFolder := Folder.GetFolders(0);
    for i := 1 to TaskFolder.Count do
      GetTasks(TaskFolder.Item[i], AllFolder, TL);
  end;
end;

//Получить задачи 1.0
procedure GetTasksXP(const TaskSched: TTaskScheduleOld; var TL: TTasksListXP);
var
  i: integer;
begin
  if Application.Terminated then
    Exit;
  if TaskSched.TaskCount > 0 then
    for i := 0 to TaskSched.TaskCount - 1 do
      TL.Add(TaskSched.Tasks[i]);
end;

//Раздел реесра в строку
function RootKeyToStr(RK: HKEY): string;
begin
  case RK of
    HKEY_CLASSES_ROOT:
      Result := 'HKCR';
    HKEY_CURRENT_USER:
      Result := 'HKCU';
    HKEY_LOCAL_MACHINE:
      Result := 'HKLM';
    HKEY_USERS:
      Result := 'HKUR';
    HKEY_PERFORMANCE_DATA:
      Result := 'HKPD';
    HKEY_CURRENT_CONFIG:
      Result := 'HKCC';
    HKEY_DYN_DATA:
      Result := 'HKDD';
  else
    Result := 'HKCU';
  end;
end;

//Строка в раздел реестра
function StrKeyToRoot(RK: string): HKEY;
begin
  Result := HKEY_CURRENT_USER;
  if (RK = 'HKCR') or (RK = 'HKEY_CLASSES_ROOT') then
    Exit(HKEY_CLASSES_ROOT);
  if (RK = 'HKCU') or (RK = 'HKEY_CURRENT_USER') then
    Exit(HKEY_CURRENT_USER);
  if (RK = 'HKLM') or (RK = 'HKEY_LOCAL_MACHINE') then
    Exit(HKEY_LOCAL_MACHINE);
  if (RK = 'HKUR') or (RK = 'HKEY_USERS') then
    Exit(HKEY_USERS);
  if (RK = 'HKPD') or (RK = 'HKEY_PERFORMANCE_DATA') then
    Exit(HKEY_PERFORMANCE_DATA);
  if (RK = 'HKCC') or (RK = 'HKEY_CURRENT_CONFIG') then
    Exit(HKEY_CURRENT_CONFIG);
  if (RK = 'HKDD') or (RK = 'HKEY_DYN_DATA') then
    Exit(HKEY_DYN_DATA);
end;

//Исключение для дат задач
function GetDateForTask(Value: TDate): string;
begin
  if Value = 0 then
    Result := LangText(69, 'Никогда')
  else
    Result := DateTimeToStr(Value);
end;

//Универсальный сортировщик
function CustomUniSortProc(Item1, Item2: TListItem; ParamSort: integer): integer;
var
  Atom1, Atom2: string;
  Int1, Int2: Integer;
  Flt1, Flt2: Extended;
  Dte1, Dte2: TDateTime;
  M1, M2: SmallInt;
begin
  Result := 0;
  M1 := 1;
  M2 := -1;
  if Assigned(Item1.ListView) then
    case Item1.ListView.Tag of
      1:
        begin
          M1 := -1;
          M2 := 1;
        end;
    end;
  if ParamSort < 0 then
  begin
    Atom1 := Item1.Caption;
    Atom2 := Item2.Caption;
  end
  else
  begin
    if ParamSort > Item1.SubItems.Count - 1 then
      Exit;
    if ParamSort > Item2.SubItems.Count - 1 then
      Exit;

    Atom1 := Item1.SubItems[ParamSort];
    Atom2 := Item2.SubItems[ParamSort];
  end;

  if TryStrToInt(Atom1, Int1) then
    if TryStrToInt(Atom2, Int2) then
    begin
      if Int1 > Int2 then
        Result := M1
      else if Int1 < Int2 then
        Result := M2;
      Exit;
    end;
  if TryStrToFloat(Atom1, Flt1) then
    if TryStrToFloat(Atom2, Flt2) then
    begin
      if Flt1 > Flt2 then
        Result := M1
      else if Flt1 < Flt2 then
        Result := M2;
      Exit;
    end;
  if TryStrToDateTime(Atom1, Dte1) then
    if TryStrToDateTime(Atom2, Dte2) then
    begin
      if Dte1 > Dte2 then
        Result := M1
      else if Dte1 < Dte2 then
        Result := M2;
      Exit;
    end;

  if AnsiLowerCase(Atom1) > AnsiLowerCase(Atom2) then
    Result := M1
  else if AnsiLowerCase(Atom1) < AnsiLowerCase(Atom2) then
    Result := M2;
end;

//Сортировка строк
function CustomStrSortProc(Item1, Item2: TListItem; ParamSort: integer): integer; stdcall;
begin
  Result := 0;
  case ParamSort of
    -1:
      begin
        try
          if AnsiLowerCase(Item1.Caption) > AnsiLowerCase(Item2.Caption) then
            Result := 1
          else if AnsiLowerCase(Item1.Caption) < AnsiLowerCase(Item2.Caption) then
            Result := -1;
        except
          Exit;
        end;
      end;
  else
    try
      if AnsiLowerCase(Item1.SubItems[ParamSort]) > AnsiLowerCase(Item2.SubItems[ParamSort]) then
        Result := 1
      else if AnsiLowerCase(Item1.SubItems[ParamSort]) < AnsiLowerCase(Item2.SubItems[ParamSort]) then
        Result := -1;
    except
      Exit;
    end;
  end;
end;

//Сортировка чисел
function CustomIntSortProc(Item1, Item2: TListItem; ParamSort: integer): integer; stdcall;
var
  I1, I2: Integer;
begin
  Result := 0;
  case ParamSort of
    -1:
      begin
        try
          if not TryStrToInt(Item1.Caption, I1) then
            Exit;
          if not TryStrToInt(Item2.Caption, I2) then
            Exit;
        except
          Exit;
        end;
      end;
  else
    try
      if not TryStrToInt(Item1.SubItems[ParamSort], I1) then
        Exit;
      if not TryStrToInt(Item2.SubItems[ParamSort], I2) then
        Exit;
    except
      Exit;
    end;
  end;
  if I1 > I2 then
    Result := 1
  else if I1 < I2 then
    Result := -1;
end;

//Сортировка дат
function CustomDateSortProc(Item1, Item2: TListItem; ParamSort: integer): integer; stdcall;
var
  Str1, Str2: TDateTime;
begin
  Result := 0;
  case ParamSort of
    -1:
      begin
        try
          Str1 := StrToDateTime(Item1.Caption);
          Str2 := StrToDateTime(Item2.Caption);
        except
          Exit;
        end;
      end;
  else
    try
      Str1 := StrToDateTime(Item1.SubItems[ParamSort]);
      Str2 := StrToDateTime(Item2.SubItems[ParamSort]);
    except
      Exit;
    end;
  end;
  if Str1 > Str2 then
    Result := -1
  else if Str1 < Str2 then
    Result := 1;
end;

//Подождать * секунд
procedure Wait(Seconds: Cardinal);
begin
  Seconds := (Seconds * 1000) + GetTickCount;
  while Seconds > GetTickCount do
    Application.ProcessMessages;
end;

//Получить список файлов из каталога
procedure ScanDir(StartDir: string; Mask: string; List: TStrings);
var
  SearchRec: TSearchRec;
  Attr: Integer;
begin
  if StartDir = '' then
    Exit;
  Attr := faAnyFile;
  if Copy(AnsiLowerCase(Mask), 1, 5) = 'nodir' then
  begin
    Delete(Mask, 1, 5);
    Attr := faAnyFile and not faDirectory;
  end;
  if Mask = '' then
    Mask := '*.*';
  if StartDir[Length(StartDir)] <> '\' then
    StartDir := StartDir + '\';
  if FindFirst(StartDir + Mask, Attr, SearchRec) = 0 then
  begin
    repeat
      if (SearchRec.Name <> '..') and (SearchRec.Name <> '.') then
      begin
        List.Add(StartDir + SearchRec.Name);
      end;
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;
end;

//Получить список файлов из каталога и его подкаталогов
procedure ScanDirFiles(StartDir: string; Mask, FileMask: string; List: TStrings);
var
  SearchRec: TSearchRec;
  Attr: Integer;
  Ext: string;
begin
  Attr := faAnyFile and not faSymLink;
  if Copy(AnsiLowerCase(Mask), 1, 5) = 'nodir' then
  begin
    Delete(Mask, 1, 5);
    Attr := faAnyFile and not faDirectory;
  end;
  if Mask = '' then
    Mask := '*.*';
  if StartDir = '' then
    StartDir := '\';
  if StartDir[Length(StartDir)] <> '\' then
    StartDir := StartDir + '\';
  if FindFirst(StartDir + Mask, Attr, SearchRec) = 0 then
  begin
    repeat
      Application.ProcessMessages;
      if (SearchRec.Name <> '..') and (SearchRec.Name <> '.') then
      begin     {
      if Pos('Application Data', StartDir) <> 0 then
       begin
        if (SearchRec.Attr and faInvalid = faInvalid) then ShowMessage('faInvalid');
        if (SearchRec.Attr and faReadOnly = faReadOnly) then ShowMessage('faReadOnly');
        if (SearchRec.Attr and faHidden = faHidden) then ShowMessage('faHidden');
        if (SearchRec.Attr and faSysFile = faSysFile) then ShowMessage('faSysFile');
        if (SearchRec.Attr and faVolumeID = faVolumeID) then ShowMessage('faVolumeID');
        if (SearchRec.Attr and faDirectory = faDirectory) then ShowMessage('faDirectory');
        if (SearchRec.Attr and faArchive = faArchive) then ShowMessage('faArchive');
        if (SearchRec.Attr and faNormal = faNormal) then ShowMessage('faNormal');
        if (SearchRec.Attr and faTemporary = faTemporary) then ShowMessage('faTemporary');
        if (SearchRec.Attr and faSymLink = faSymLink) then ShowMessage('faSymLink');
        if (SearchRec.Attr and faCompressed = faCompressed) then ShowMessage('faCompressed');
        if (SearchRec.Attr and faEncrypted = faEncrypted) then ShowMessage('faEncrypted');
        if (SearchRec.Attr and faVirtual = faVirtual) then ShowMessage('faVirtual');
        if (SearchRec.Attr and faAnyFile = faAnyFile) then ShowMessage('faAnyFile');
       end;              }
        if (SearchRec.Attr and faSysFile) = faSysFile then
          Continue;
        if (SearchRec.Attr and faDirectory) = faDirectory then
          ScanDirFiles(StartDir + SearchRec.Name, Mask, FileMask, List)
        else
        begin
          Ext := ExtractFileExt(StartDir + SearchRec.Name);
          if Ext.Length > 0 then
            if (Pos(Ext + '.', FileMask) <> 0) then
              List.Add(StartDir + SearchRec.Name);
        end;
      end;
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;
end;

//Получить список подкаталогов
function GetDirectores(Dir: string): TStringList;
var
  SR: TSearchRec;
begin
  Result := TStringList.Create;
  if Length(Dir) <= 0 then
    Exit;
  if Dir[Length(Dir)] <> '\' then
    Dir := Dir + '\';

  Dir := Dir + '*.*';
  if FindFirst(Dir, faAnyFile, SR) = 0 then
    repeat
      begin
        if (SR.name <> '') and (SR.name <> '.') and (SR.name <> '..') and (SR.Attr and faDirectory = faDirectory) then
          Result.Add(ExtractFileDir(Dir) + '\' + SR.name);
      end;
    until FindNext(SR) <> 0;
  FindClose(SR);
end;

//Нормализация времени
function NormTime(Value: Cardinal): string;
var
  H, M, S: Word;
begin
  H := Value div 3600;
  M := Round(Value - H * 3600) div 60;
  S := Round(Value - (H * 3600 + M * 60));
  Result := IntToStr(H) + ' час. ' + IntToStr(M) + ' мин. ' + IntToStr(S) + ' сек.';
end;

//Расстановка пробелов в числе
function GetSpacedInt(AText: string): string;
var
  i, st: Word;
  InsMinus: Boolean;
begin
  if Length(AText) <= 3 then
  begin
    if AText = '' then
      AText := '0';

    Result := AText;
    Exit;
  end;
  Result := '';
  st := 0;
  InsMinus := False;
  if AText[1] = '-' then
  begin
    InsMinus := True;
    Delete(AText, 1, 1);
  end;
  for i := Length(AText) downto 1 do
  begin
    Result := AText[i] + Result;
    Inc(st);
    if (st = 3) and (i <> 1) then
    begin
      Result := ' ' + Result;
      st := 0;
    end;
  end;
  if InsMinus then
    Result := '-' + Result;
end;

//Нормализация имени файла
function NormFileNameF(FN: string): string;
begin
  NormFileName(FN);
  Result := FN;
end;

//Замена подстрок
procedure RepVar(var Dest: string; Indent, VarInd: string);
var
  p: Word;
begin
  repeat
    p := Pos(Indent, AnsiLowerCase(Dest));
    if p <> 0 then
    begin
      if p = 1 then
        Dest := VarInd + Copy(Dest, p + Length(Indent), Length(Dest) - (p + Length(Indent)) + 1)
      else
        Dest := Copy(Dest, 1, p - 1) + VarInd + Copy(Dest, p + Length(Indent), Length(Dest) - (p + Length(Indent)) + 1)
    end;
  until p = 0;
end;

//Добавление системного каталога файлу
function SetSysPath(FileN: string): string;
var
  path0: string;
  path1: string;
  path2: string;
  path3: string;
  path4: string;
  path5: string;
  path6: string;
  path7: string;
begin
  path0 := C[1] + ':\';
  path1 := C[1] + ':\Windows\';
  path2 := C[1] + ':\Windows\System32\';
  path3 := C[1] + ':\Windows\SysWOW64\';
  path4 := C[1] + ':';
  path5 := C[1] + ':\Windows';
  path6 := C[1] + ':\Windows\System32';
  path7 := C[1] + ':\Windows\SysWOW64';
  Result := FileN;
  if FileExists(path0 + FileN) then
    Exit(path0 + FileN);
  if FileExists(path1 + FileN) then
    Exit(path1 + FileN);
  if FileExists(path2 + FileN) then
    Exit(path2 + FileN);
  if FileExists(path3 + FileN) then
    Exit(path3 + FileN);
  if FileExists(path4 + FileN) then
    Exit(path4 + FileN);
  if FileExists(path5 + FileN) then
    Exit(path5 + FileN);
  if FileExists(path6 + FileN) then
    Exit(path6 + FileN);
  if FileExists(path7 + FileN) then
    Exit(path7 + FileN);
end;

//Нормализация имени файла
procedure NormFileName(var FN: string);
var
  p: Word;
  backup: string;
begin
  backup := FN;

  if Length(FN) < 3 then
  begin
   //ShowMessage(FN);
    Exit;
  end;
  while Pos(#13, FN) <> 0 do
    Delete(FN, Pos(#13, FN), 1);
  while Pos(#10, FN) <> 0 do
    Delete(FN, Pos(#10, FN), 1);
  while Pos(#0, FN) <> 0 do
    Delete(FN, Pos(#0, FN), 1);
  if (FN[1] = '"') then
  begin
    if (Pos('"', FN, 2) = Length(FN)) then
    begin
      FN := Copy(FN, 2, Length(FN) - 2);
      NormFileName(FN);
      Exit;
    end
    else
    begin
      FN := Copy(FN, 2, Pos('"', FN, 2) - 2);
      NormFileName(FN);
      Exit;
    end;
  end;
  ReplaceSysVar(FN);
  if FileExists(FN) then
    Exit;
  p := Pos(',', FN);
  if p <> 0 then
  begin
    FN := Copy(FN, 1, p - 1);
  end;
  if FN.Length < 3 then
    Exit;

  if FN[1] = '@' then
    FN := Copy(FN, 2, Length(FN) - 1);

  RepVar(FN, '/', '\');
  if ExtractFilePath(FN) = '' then
    FN := SetSysPath(FN);
  if FN.Length < 3 then
    Exit;
  if (FN[1] = '\') or (FN[1] = '/') then
    Delete(FN, 1, 1);

  p := Pos(':', FN);
  if p <> 0 then
  begin
    if p <> 2 then
    begin
      Delete(FN, 1, p - 2);
     //while Pos(':', FN) <> 2 do Delete(FN, 1, 1);
    end;
  end
  else
    FN := SetSysPath(FN);
 //ShowMessage(FN);
  if FileExists(FN) then
    Exit;
  while (Length(FN) > 2) and (not FileExists(FN)) and (Pos(' ', FN) <> 0) do
  begin
    if ExtractFilePath(FN) = '' then
      FN := SetSysPath(FN);
    if FileExists(FN) then
      Exit;

    Delete(FN, Length(FN), 1);
  end;
  if FileExists(FN) then
    Exit;
  FN := backup;
 //ShowMessage(FN);
end;

//Инициализация поддержки языка
function InitLang(Lang: string): Boolean;
begin
  Result := True;
  LangH := LoadLibrary(PChar(Lang));
  if LangH <= 0 then
  begin
    MessageBox(Application.Handle, 'Ошибка при загрузке указанной языковой библиотеки.', 'Ошибка', MB_ICONERROR or MB_OK);
    FreeLibrary(LangH);
    Exit(False);
  end;
  if LoadString(LangH, 63000) <> 'CWMLANG' then
    MessageBox(Application.Handle, 'Возможно загружена неверная языковая библиотека.', 'Внимание', MB_ICONASTERISK or MB_OK);
end;

procedure GetPathAndID(Input: string; var Path: string);
//@C:\Windows\system32\imageres.dll,-34 -> C:\Windows\system32\imageres.dll & 34
var
  p: Word;
begin                      //@C:\Windows\system32\imageres.dll,-34
  if Input.Length <= 0 then
    Exit;
  Delete(Input, 1, 1);      //C:\Windows\system32\imageres.dll,-34
  p := Pos(',', Input);       // p = 33
  Path := Copy(Input, 1, p - 1); //Path = C:\Windows\system32\imageres.dll
 {Delete(Input, 1, p+1);    //-34
 iID:=0;                   //
 TryStrToInt(Input, iID);  //iID = - 34
 ID:=Abs(iID);             //ID = 34      }
end;

procedure GetPathID(Input: string; var Path: string; var ID: Cardinal);
//@C:\Windows\system32\imageres.dll,-34 -> C:\Windows\system32\imageres.dll & 34
var
  p: Word;
  l: Integer;
begin                          //@C:\Windows\system32\imageres.dll,-34
  if Input.Length <= 0 then
    Exit;
  Delete(Input, 1, 1);          //C:\Windows\system32\imageres.dll,-34
  p := Pos(',', Input);           // p = 33
  Path := Copy(Input, 1, p - 1);    //Path = C:\Windows\system32\imageres.dll
  Delete(Input, 1, p + 1);        //-34
  ID := 0;                        //
  TryStrToInt(Input, l);       //iID = - 34
  ID := Abs(l);                  //ID = 34
end;

function GetFileInfo(const strFilename: string): string;
var
  FileInfo: TSHFileInfo;
begin
  FillChar(FileInfo, SizeOf(FileInfo), #0);
  SHGetFileInfoW(PWideChar(strFilename), 0, FileInfo, SizeOf(FileInfo), SHGFI_DISPLAYNAME);
  Result := StrPas(FileInfo.szDisplayName);
end;

function GetFileTypeName(const strFilename: string): string;
var
  FileInfo: TSHFileInfo;
begin
  FillChar(FileInfo, SizeOf(FileInfo), #0);
  SHGetFileInfoW(PWideChar(strFilename), 0, FileInfo, SizeOf(FileInfo), SHGFI_TYPENAME);
  Result := StrPas(FileInfo.szTypeName);
end;

function GetFileDescription(const FileName, ExceptText: string): string;
type
  TLangRec = array[0..1] of Word;
var
  InfoSize, zero: Cardinal;
  pbuff: Pointer;
  pk: Pointer;
  nk: Cardinal;
  lang_hex_str: string;
  LangID: Word;
  LangCP: Word;
begin
  pbuff := nil;
  Result := '';
  InfoSize := Windows.GetFileVersionInfoSize(PChar(FileName), zero);
  if InfoSize <> 0 then
  try
    GetMem(pbuff, InfoSize);
    if Windows.GetFileVersionInfo(PChar(FileName), 0, InfoSize, pbuff) then
    begin
      if VerQueryValue(pbuff, '\VarFileInfo\Translation', pk, nk) then
      begin
        LangID := TLangRec(pk^)[0];
        LangCP := TLangRec(pk^)[1];
        lang_hex_str := Format('%.4x', [LangID]) + Format('%.4x', [LangCP]);  //FileDescription
        if VerQueryValue(pbuff, PChar('\\StringFileInfo\\' + lang_hex_str + '\\FileDescription'), pk, nk) then
          Result := string(PChar(pk))
        else if VerQueryValue(pbuff, PChar('\\StringFileInfo\\' + lang_hex_str + '\\CompanyName'), pk, nk) then
          Result := string(PChar(pk));
      end;
    end;
  finally
    if pbuff <> nil then
      FreeMem(pbuff);
  end;
  if Result = '' then
    if (ExceptText <> '') then
      if (ExceptText <> '/') then
        Result := ExceptText
      else
        Exit('')
    else
      Result := GetFileNameWoE(FileName);
end;

procedure ShowPropertiesDialog(FName: string);
var
  ShellInfo: TSHELLEXECUTEINFO;
begin
  ZeroMemory(Addr(ShellInfo), SizeOf(ShellInfo));
  ShellInfo.cbSize := SizeOf(ShellInfo);
  ShellInfo.lpFile := PChar(FName);
  ShellInfo.lpVerb := 'PROPERTIES';
  ShellInfo.fMask := SEE_MASK_INVOKEIDLIST;
  ShellExecuteEx(Addr(ShellInfo));
end;

function ReadStringList(Roll: TRegistry; const name: string): string;
var
  BufSize, DataType: DWORD;
  i: Integer;
  Buffer: PChar;
begin
  Result := '';
  if not Roll.ValueExists(name) then
    Exit;
  BufSize := Roll.GetDataSize(name);
  if BufSize < 1 then
    Exit;
  Buffer := nil;
  try
    DataType := REG_NONE;
    Buffer := AllocMem(BufSize);
    if RegQueryValueEx(Roll.CurrentKey, PChar(name), nil, @DataType, PByte(Buffer), @BufSize) <> ERROR_SUCCESS then
      Exit;
    if DataType <> REG_MULTI_SZ then
      Exit;
    for i := 0 to (BufSize div 2) - 3 do
    begin
      if Buffer[i] = #0 then
        Buffer[i] := ' ';
    end;
    Result := Buffer;
  finally
    FreeMem(Buffer);
  end;
end;

function GetDllVersion(FileName: string): Integer;
var
  InfoSize, Wnd: DWORD;
  VerBuf: Pointer;
  FI: PVSFixedFileInfo;
  VerSize: DWORD;
begin
  Result := 0;
  InfoSize := GetFileVersionInfoSize(PChar(FileName), Wnd);
  if InfoSize <> 0 then
  begin
    GetMem(VerBuf, InfoSize);
    try
      if Windows.GetFileVersionInfo(PChar(FileName), Wnd, InfoSize, VerBuf) then
        if VerQueryValue(VerBuf, '\', Pointer(FI), VerSize) then
          Result := FI.dwFileVersionMS;
    finally
      FreeMem(VerBuf);
    end;
  end;
end;

function UnixDateTimeToDelphiDateTime(UnixDateTime: LongInt): TDateTime;
var
  lpTimeZoneInformation: TTimeZoneInformation;
  SystemTime: TSystemTime;
begin
  Result := EncodeDate(1970, 1, 1) + (UnixDateTime / 86400);
  GetTimeZoneInformation(lpTimeZoneInformation);
  with SystemTime do
  begin
    DecodeDate(Result, wYear, wMonth, wDay);
    DecodeTime(Result, wHour, wMinute, wSecond, wMilliseconds);
    SystemTimeToTzSpecificLocalTime(@lpTimeZoneInformation, SystemTime, SystemTime);
    Result := EncodeDate(wYear, wMonth, wDay) + EncodeTime(wHour, wMinute, wSecond, wMilliseconds);
  end;
end;

function GetRegValue(ARootKey: HKEY; AKey, Value: string): string;
var
  Reg: TRegistry;
begin
  Result := '';
  Reg := TRegistry.Create(KEY_READ);
  try
    with Reg do
    begin
      RootKey := ARootKey;
      OpenKey(AKey, False);
      Result := ReadString(Value);
    end;
  finally
    Reg.Free;
  end;
end;

function GetAccountName(const SID: PSID): string;
var
  lpDomainName, lpUserName: string;
  szDomainName, szUserName: DWord;
  peUse: DWord;
begin
  Result := EmptyStr;
  szDomainName := 0;
  szUserName := 0;
  LookupAccountSid(nil, SID, nil, szUserName, nil, szDomainName, peUse);
  SetLength(lpUserName, szUserName);
  SetLength(lpDomainName, szDomainName);
  if LookupAccountSid(nil, SID, PChar(lpUserName), szUserName, PChar(lpDomainName), szDomainName, peUse) then
  begin
    SetLength(lpUserName, szUserName);
    SetLength(lpDomainName, szDomainName);
    Result := Format('%s\%s', [lpDomainName, lpUserName]);
    ;
  end;
end;

procedure RaiseWin32Error(Code: LongInt);
var
  E: EWin32Exception;
begin
  E := EWin32Exception.Create(SysErrorMessage(Code));
  E.ErrorCode := Code;
  raise E;
end;

initialization
   {
 case Info.Bits of
  x32:InitLang('LangRus32.dll');
  x64:InitLang('LangRus64.dll');
 end;  }

  ProcessMonitor := TProcessMonitor.Create;

finalization
  ProcessMonitor.Free;

end.

