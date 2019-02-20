unit ShellRecycle;

interface

uses
 Windows, System.Classes, ShlObj, ActiveX, ComObj, Winapi.Messages;

type
 PSHQueryRBInfo64 = ^TSHQueryRBInfo64;
 TSHQueryRBInfo64 = packed record
  cbSize: TLargeInteger;
  i64Size: TLargeInteger;
  i64NumItems: TLargeInteger;
 end;

 PSHQueryRBInfo32 = ^TSHQueryRBInfo32;
 TSHQueryRBInfo32 = packed record
  cbSize: DWORD;
  i64Size: TLargeInteger;
  i64NumItems: TLargeInteger;
 end;

 TSHQueryRBInfo = packed record
  cbSize: Integer;
  i64Size: Integer;
  i64NumItems: Integer;
 end;

 PSHChangeNotifyEntry = ^TSHChangeNotifyEntry;
 TSHChangeNotifyEntry = packed record
    pidl: PItemIDList;
    fRecursive: BOOL;
  end;

const
  DETAIL_COUNT = 11;
  WM_SHELLNOTIFIER = WM_USER;

const
  SHERB_NOCONFIRMATION  =  $0001;
  SHERB_NOPROGRESSUI    =  $0002;
  SHERB_NOSOUND         =  $0004;

  SHCNF_ACCEPT_INTERRUPTS     = $0001;
  SHCNF_ACCEPT_NON_INTERRUPTS = $0002;
  SHCNRF_RECURSIVEINTERRUPT   = $0004;

function SHEmptyRecycleBinA(Wnd: HWND; pszRootPath: PANSIChar; dwFlags: DWORD): HRESULT; stdcall;
function SHEmptyRecycleBinW(Wnd: HWND; pszRootPath: PWideChar; dwFlags: DWORD): HRESULT; stdcall;
function SHEmptyRecycleBin (Wnd: HWND; pszRootPath: PChar;     dwFlags: DWORD): HRESULT; stdcall;

function SHQueryRecycleBinA(pszRootPath: PANSIChar; SHQueryRBInfo: PSHQueryRBInfo32): HRESULT; stdcall;
function SHQueryRecycleBinW(pszRootPath: PWideChar; SHQueryRBInfo: PSHQueryRBInfo32): HRESULT; stdcall;
function SHQueryRecycleBin (pszRootPath: PChar;     SHQueryRBInfo: PSHQueryRBInfo32): HRESULT; stdcall;

function SHQueryRecycleBinA64(pszRootPath: PANSIChar; SHQueryRBInfo: PSHQueryRBInfo64): HRESULT; stdcall;
function SHQueryRecycleBinW64(pszRootPath: PWideChar; SHQueryRBInfo: PSHQueryRBInfo64): HRESULT; stdcall;
function SHQueryRecycleBin64 (pszRootPath: PChar;     SHQueryRBInfo: PSHQueryRBInfo64): HRESULT; stdcall;

function SHChangeNotifyRegister(hwnd:HWND; fSources: Byte; fEvents: LongInt; wMsg: UINT; cEntries: Byte; pfsne: PSHChangeNotifyEntry): ULONG; stdcall;
function SHChangeNotifyDeregister(uiID:ULONG):BOOL; stdcall;
procedure SHGetSetSettings(var lpss: TShellFlagState; dwMask: DWORD; bState: BOOL); stdcall;

function GetFilesList(List:TStrings):Boolean;
function RecycleInfo(ForX64:Boolean):TSHQueryRBInfo;

//procedure WMShellNotifyer(var Message: TMessage); message WM_SHELLNOTIFIER;

implementation
 uses Winapi.ShellAPI, System.SysUtils;
 const Shell32='Shell32.dll';

function SHEmptyRecycleBinA; external Shell32 name 'SHEmptyRecycleBinA';
function SHEmptyRecycleBinW; external Shell32 name 'SHEmptyRecycleBinW';
function SHEmptyRecycleBin;  external Shell32 name 'SHEmptyRecycleBinA';

function SHQueryRecycleBinA; external Shell32 name 'SHQueryRecycleBinA';
function SHQueryRecycleBinW; external Shell32 name 'SHQueryRecycleBinW';
function SHQueryRecycleBin;  external Shell32 name 'SHQueryRecycleBinA';

function SHQueryRecycleBinA64; external Shell32 name 'SHQueryRecycleBinA';
function SHQueryRecycleBinW64; external Shell32 name 'SHQueryRecycleBinW';
function SHQueryRecycleBin64;  external Shell32 name 'SHQueryRecycleBinA';

function SHChangeNotifyRegister;   external Shell32 name 'SHChangeNotifyRegister';
function SHChangeNotifyDeregister; external Shell32 name 'SHChangeNotifyDeregister';
procedure SHGetSetSettings;        external Shell32 name 'SHGetSetSettings';

function RecycleInfo(ForX64:Boolean):TSHQueryRBInfo;
var SHQueryRBInfo32: TSHQueryRBInfo32;
    SHQueryRBInfo64: TSHQueryRBInfo64;
begin
 if ForX64 then
  begin
   ZeroMemory(@SHQueryRBInfo64, SizeOf(SHQueryRBInfo64));
   SHQueryRBInfo64.cbSize:= SizeOf(SHQueryRBInfo64);
   if SHQueryRecycleBinA64('', @SHQueryRBInfo64) = s_OK then
    begin
     with Result do
      begin
       i64NumItems:=SHQueryRBInfo64.i64NumItems;
       cbSize:=SHQueryRBInfo64.cbSize;
       i64Size:=SHQueryRBInfo64.i64Size;
      end;
    end;
  end
 else
  begin
   ZeroMemory(@SHQueryRBInfo32, SizeOf(SHQueryRBInfo32));
   SHQueryRBInfo32.cbSize:= SizeOf(SHQueryRBInfo32);
   if SHQueryRecycleBinA('', @SHQueryRBInfo32) = s_OK then
    begin
     with Result do
      begin
       i64NumItems:=SHQueryRBInfo32.i64NumItems;
       cbSize:=SHQueryRBInfo32.cbSize;
       i64Size:=SHQueryRBInfo32.i64Size;
      end;
    end;
  end;
end;

function GetFilesList(List:TStrings):Boolean;
var
  IIdL:PItemIdList;
  Desktop, ShFolder:IShellFolder;
  NPIDI:Cardinal;
  EnumL:IEnumiDList;
  StrR:StrRet;
  s:string;
begin
 try
  SHGetSpecialFolderLocation(0, CSIDL_BITBUCKET, IIdL);
  OleCheck(SHGetDesktopFolder(Desktop));
  OleCheck(Desktop.BindToObject(IIdL, nil, IID_IShellFolder, Pointer(ShFolder)));
  OleCheck(ShFolder.EnumObjects(0, SHCONTF_FOLDERS or SHCONTF_NONFOLDERS or SHCONTF_INCLUDEHIDDEN, EnumL));
  while EnumL.Next(1, IIdL, NPIDI) = S_OK do
   begin
    ShFolder.GetDisplayNameOf(IIdL, SHGDN_NORMAL, StrR);

    case StrR.uType of
     STRRET_CSTR: s:=StrR.cStr;
     STRRET_OFFSET: s:=StrR.pStr;
     STRRET_WSTR: s:=StrR.pOleStr;
    end;
    List.Add(s);
   end;
 except
  //ShowMessage('Error!');
 end;
 Result:=True;
end;

function StrRetToString(PIDL: PItemIDList; StrRet: TStrRet;
  Flag: String = ''): String;
var
  P: PChar;
begin
  case StrRet.uType of
    STRRET_CSTR:
      SetString(Result, StrRet.cStr, lStrLen(StrRet.pOleStr));
    STRRET_OFFSET:
      begin
        P := @PIDL.mkid.abID[StrRet.uOffset - SizeOf(PIDL.mkid.cb)];
        SetString(Result, P, PIDL.mkid.cb - StrRet.uOffset);
      end;
    STRRET_WSTR:
      if Assigned(StrRet.pOleStr) then
        Result := StrRet.pOleStr
      else
        Result := '';
  end;
  { This is a hack bug fix to get around Windows Shell Controls returning
    spurious "?"s in date/time detail fields }
  if (Length(Result) > 1) and (Result[1] = '?') and CharInSet(Result[2], ['0'..'9']) then
    Result:=StringReplace(Result, '?', '', [rfReplaceAll]);
end;

procedure DeleteToRecycle(FileName:string);
var Struct: TSHFileOpStruct;
begin
 with Struct do
  begin
   Wnd:=0;
   wFunc:=FO_DELETE;
   // Struct.pFrom - должен заканчиваться двумя терминирующими нулями!
   pFrom:=PChar(FileName + #0);
   pTo:= nil;
   fFlags := FOF_ALLOWUNDO;
   fAnyOperationsAborted := True;
   hNameMappings := nil;
   lpszProgressTitle := nil;
  end;
 OleCheck(SHFileOperation(Struct));
end;

procedure EmptyRecycle;
var Err: HRESULT;
    //I: Integer;
begin
 //Err:=S_FALSE;
 {if not cbDellFromAllDrives.Checked then
  begin
    // Очистка корзин выбранных дисков
   for I := 0 to clbDrives.Items.Count - 1 do
    if clbDrives.Checked[I] then
        if not (Err in [S_OK, S_FALSE]) then
          RaiseLastOSError
        else
          if Err = S_FALSE then
            Err := SHEmptyRecycleBin(Handle,
              PChar(clbDrives.Items.Strings[I]), SHERB_NOSOUND)
          else
            Err := SHEmptyRecycleBin(Handle,
              PChar(clbDrives.Items.Strings[I]), SHERB_NOCONFIRMATION or SHERB_NOSOUND);
  end
  else                    }
    // Очистка всех корзин
 Err:=SHEmptyRecycleBin(0, nil, SHERB_NOSOUND);
 OleCheck(Err);
end;
          {
function ExecuteVerb(const VerbIndex:Byte):Boolean;

  function GetLVItemText(const ItemIndex, SectionIndex: Integer): String;
  begin
    if SectionIndex = 0 then
      Result := lvData.Items.Item[ItemIndex].Caption
    else
      Result := lvData.Items.Item[ItemIndex].SubItems.Strings[SectionIndex - 1];
  end;

const
  VerbData: array [0..2] of String = ('undelete', 'delete', 'properties');

var
  ppidl, Item: PItemIDList;
  ResultItems: array of PItemIDList;
  Desktop: IShellFolder;
  RecycleBin: IShellFolder2;
  RecycleBinEnum: IEnumIDList;
  Fetched, I, Z, PIDLCount: Cardinal;
  Details: TShellDetails;
  Mallok: IMalloc;
  Valid: Boolean;
  Context: IContextMenu;
  AInvokeCommand: TCMInvokeCommandInfo;
begin
  Result := False;
  ResultItems := nil;
  PIDLCount := 0;
  // Получаем интерфейс при помощи которого будем освобождать занятую память
  OleCheck(SHGetMalloc(Mallok));
  // Получаем указатель на корзину
  OleCheck(SHGetSpecialFolderLocation(Handle, CSIDL_BITBUCKET, ppidl));
  // Получаем интерфейс на рабочий стол
  OleCheck(SHGetDesktopFolder(Desktop));
  // Получаем интерфейс на корзину
  OleCheck(Desktop.BindToObject(ppidl, nil, IID_IShellFolder2, RecycleBin));
  // Получаем интерфейс для перечисления элементов корзины
  OleCheck(RecycleBin.EnumObjects(Handle, SHCONTF_FOLDERS or SHCONTF_NONFOLDERS or SHCONTF_INCLUDEHIDDEN, RecycleBinEnum));
  // Перечиляем содержимое корзины
  for Z := 0 to lvData.Items.Count - 1 do
  begin
    RecycleBinEnum.Next(1, Item, Fetched);
    if Fetched = 0 then Break;
    Valid := False;
    // Перечесляем только выделенные элементы
    if lvData.Items.Item[Z].Selected then
      for I := 0 to DETAIL_COUNT - 1 do
        if RecycleBin.GetDetailsOf(Item, I, Details) = S_OK then
        try
          // Ищем нужный нам элемент
          Valid := GetLVItemText(Z, I) = StrRetToString(Item, Details.str);
          if not Valid then Break;
        finally
          Mallok.Free(Details.str.pOleStr);
        end;
    if Valid then
    begin
      SetLength(ResultItems, Length(ResultItems) + 1);
      ResultItems[Length(ResultItems) - 1] := Item;
      Inc(PIDLCount);
    end;
  end;
  // Если выделенный элемент найден
  if ResultItems <> nil then
  begin
    // Производим с ним операции при помощи интерфейса IContextMenu
    if RecycleBin.GetUIObjectOf(Handle, PIDLCount, ResultItems[0],
      IID_IContextMenu, nil, Pointer(Context)) = S_OK then
    begin
      FillMemory(@AInvokeCommand, SizeOf(AInvokeCommand), 0);
      with AInvokeCommand do
      begin
        cbSize := SizeOf(AInvokeCommand);
        hwnd := Handle;
        lpVerb := PAnsiChar(AnsiString(VerbData[VerbIndex])); // строковая константа для операции над элементом...
        fMask := CMIC_MASK_FLAG_NO_UI;
        nShow := SW_SHOWNORMAL;
      end;
      // Выполнение команды...
      Result := Context.InvokeCommand(AInvokeCommand) = S_OK;
    end;
  end;
end;

procedure RecycleFileList(List:TStrings);
var
  ppidl, Item: PItemIDList;
  Desktop: IShellFolder;
  RecycleBin: IShellFolder2;
  RecycleBinEnum: IEnumIDList;
  Fetched, I: Cardinal;
  Details: TShellDetails;
  Mallok: IMalloc;
  TmpStr: ShortString;
  FileInfo: TSHFileInfo;
begin
  lvData.Items.BeginUpdate;
  try
    // Устанавливаем параметры ListView
    lvData.Clear;
    lvData.Columns.Clear;
    lvData.ViewStyle := vsReport;
    // Получаем интерфейс при помощи которого будем освобождать занятую память
    OleCheck(SHGetMalloc(Mallok));
    // Получаем указатель на корзину
    OleCheck(SHGetSpecialFolderLocation(Handle, CSIDL_BITBUCKET, ppidl));
    // Получаем интерфейс на рабочий стол
    OleCheck(SHGetDesktopFolder(Desktop));
    // Получаем интерфейс на корзину
    OleCheck(Desktop.BindToObject(ppidl, nil, IID_IShellFolder2, RecycleBin));
    // Получаем интерфейс для перечисления элементов корзины
    OleCheck(RecycleBin.EnumObjects(Handle, SHCONTF_FOLDERS or SHCONTF_NONFOLDERS or SHCONTF_INCLUDEHIDDEN, RecycleBinEnum));
    // Создаем колонки
    for I := 0 to DETAIL_COUNT - 1 do
     if RecycleBin.GetDetailsOf(nil, I, Details) = S_OK then
      try
       with lvData.Columns.Add do
        begin
         Caption := StrRetToString(Item, Details.str);
         Width := lvData.Canvas.TextWidth(Caption) + 24;
        end;
      finally
       Mallok.Free(Details.str.pOleStr);
      end;

    // Перечиляем содержимое корзины
   while True do
    begin
     //Берем первый либо следующий элемент корзины
     RecycleBinEnum.Next(1, Item, Fetched);
     if Fetched = 0 then Break;
     // Получаем информацию о элементе
     if RecycleBin.GetDetailsOf(Item, 0, Details) = S_OK then
      begin
       try
        // Получаем имя элемента
        TmpStr := StrRetToString(Item, Details.str);
        // Получаем интекс иконки элемента в системном листе
        SHGetFileInfo(PChar(Item), 0, FileInfo, SizeOf(FileInfo), SHGFI_PIDL or SHGFI_SYSICONINDEX);
       finally
        // Освобождаем память
        Mallok.Free(Details.str.pOleStr);
       end;
       // Добавляем элемент и его параметры в список
       with lvData.Items.Add do
        begin
         Caption := TmpStr;
         ImageIndex := FileInfo.iIcon;
         for I := 1 to DETAIL_COUNT - 1 do
          if RecycleBin.GetDetailsOf(Item, I, Details) = S_OK then
           try
            SubItems.Add(StrRetToString(Item, Details.str));
           finally
            Mallok.Free(Details.str.pOleStr);
           end;
        end;
      end;
    end;
  finally
   lvData.Items.EndUpdate;
  end;
end;

procedure SetRecycleBinNotifyer(const Logged: Boolean);
var
  pidl: PItemIDList;
  Notifier: TSHChangeNotifyEntry;
begin
  OleCheck(SHGetSpecialFolderLocation(Handle, CSIDL_BITBUCKET, pidl));
  Notifier.fRecursive := True;
  Notifier.pidl := pidl;
  if Logged then
  begin
    HShellNotifyer := SHChangeNotifyRegister(Handle, SHCNF_ACCEPT_INTERRUPTS or
    SHCNF_ACCEPT_NON_INTERRUPTS or SHCNRF_RecursiveInterrupt, SHCNE_ALLEVENTS,
    WM_SHELLNOTIFIER, 1, @Notifier);
    if HShellNotifyer = 0 then RaiseLastOSError;
  end
  else
    if not SHChangeNotifyDeregister(HShellNotifyer) then
      RaiseLastOSError;
end;

procedure WMShellNotifyer(var Message: TMessage);
begin
  // Пришло уведомление о изменении корзины - перечитываеим ее элементы
  //ViewRecycleBin;
end;     }

end.
