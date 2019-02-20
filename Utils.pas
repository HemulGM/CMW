unit Utils;

interface

uses Windows, SysUtils, Classes, Registry;

type

  LPVOID = Pointer;

  EWin32Exception = class(Exception)
   FErrorCode: LongInt;
  public
   property ErrorCode: LongInt read FErrorCode write FErrorCode;
  end;

  // тип - список тегов информации о версии файла (MSDN 6.0)
  TFviTags = (
    fviComments,
    fviCompanyName,
    fviFileDescription,
    fviFileVersion,
    fviInternalName,
    fviLegalCopyright,
    fviLegalTrademarks,
    fviOriginalFilename,
    fviPrivateBuild,
    fviProductName,
    fviProductVersion,
    fviSpecialBuild
  );

  TFileVersionInfoRecord = record
    LangID:     Word;  // Windows language identifier
    LangCP:     Word;  // Code page for the language
    LangName:   array[0..255] of Char;  // Отображаемое Windows имя языка
    FieldDef:   array[TFviTags] of String; // имя параметра по-английски
    FieldRus:   array[TFviTags] of String; // имя параметра по-русски
    Value:      array[TFviTags] of String; // значение параметра
    FileVer:    String; // языко-независимое значение версии файла
    ProductVer: String; // языко-независимое значение версии продукта
    BuildType:  String; // языко-независимое - тип сборки
    FileType:   String; // языко-независимое - тип продукта
  end;

const // Имена полей (тегов) по-английски:
  cFviFieldsDef : array[TFviTags] of String = (
    'Comments',
    'CompanyName',
    'FileDescription',
    'FileVersion',
    'InternalName',
    'LegalCopyright',
    'LegalTrademarks',
    'OriginalFilename',
    'PrivateBuild',
    'ProductName',
    'ProductVersion',
    'SpecialBuild'
  );

const // Имена полей (тегов) по-русски:
  cFviFieldsRus : array[TFviTags] of String = (
    'Комментарий',
    'Производитель',
    'Описание',
    'Версия файла',
    'Внутреннее имя',
    'Авторские права',
    'Торговые знаки',
    'Исходное имя файла',
    'Приватная версия',
    'Название продукта',
    'Версия продукта',
    'Особая версия'
  );

const
  RusLangID = $0419;

function UnixDateTimeToDelphiDateTime(UnixDateTime: LongInt):TDateTime;
function GetRegValue(ARootKey: HKEY; AKey, Value: String): String;
function GetAccountName(const SID: PSID): string;
procedure RaiseWin32Error(Code : LongInt);
function GetDllVersion(FileName: string):Integer;
function ReadStringList(Roll:TRegistry; const name:string):String;
procedure ShowPropertiesDialog(FName:string);
function GetFileInfo(const strFilename: string):string;
function GetFileDescription(const FileName, ExceptText:string):string;
function GetFileTypeName(const strFilename: string):string;
procedure GetPathAndID(Input:string; var Path:string);
procedure GetPathID(Input:string; var Path:string; var ID:Cardinal);

implementation
 uses Vcl.Dialogs, ShellAPI, COCUtils;

procedure GetPathAndID(Input:string; var Path:string);
//@C:\Windows\system32\imageres.dll,-34 -> C:\Windows\system32\imageres.dll & 34
var p:Word;
begin                      //@C:\Windows\system32\imageres.dll,-34
 if Input.Length <=0 then Exit;
 Delete(Input, 1, 1);      //C:\Windows\system32\imageres.dll,-34
 p:=Pos(',', Input);       // p = 33
 Path:=Copy(Input, 1, p-1);//Path = C:\Windows\system32\imageres.dll
 {Delete(Input, 1, p+1);    //-34
 iID:=0;                   //
 TryStrToInt(Input, iID);  //iID = - 34
 ID:=Abs(iID);             //ID = 34      }
end;

procedure GetPathID(Input:string; var Path:string; var ID:Cardinal);
//@C:\Windows\system32\imageres.dll,-34 -> C:\Windows\system32\imageres.dll & 34
var p:Word;
    l:Integer;
begin                          //@C:\Windows\system32\imageres.dll,-34
 if Input.Length <=0 then Exit;
 Delete(Input, 1, 1);          //C:\Windows\system32\imageres.dll,-34
 p:=Pos(',', Input);           // p = 33
 Path:=Copy(Input, 1, p-1);    //Path = C:\Windows\system32\imageres.dll
 Delete(Input, 1, p+1);        //-34
 ID:=0;                        //
 TryStrToInt(Input, l);       //iID = - 34
 ID:=Abs(l);                  //ID = 34
end;

function GetFileInfo(const strFilename: string):string;
var FileInfo: TSHFileInfo;
begin
 FillChar(FileInfo, SizeOf(FileInfo), #0);
 SHGetFileInfoW(PWideChar(strFilename), 0, FileInfo, SizeOf(FileInfo), SHGFI_DISPLAYNAME);
 Result := StrPas(FileInfo.szDisplayName);
end;

function GetFileTypeName(const strFilename: string):string;
var FileInfo: TSHFileInfo;
begin
 FillChar(FileInfo, SizeOf(FileInfo), #0);
 SHGetFileInfoW(PWideChar(strFilename), 0, FileInfo, SizeOf(FileInfo), SHGFI_TYPENAME);
 Result:=StrPas(FileInfo.szTypeName);
end;

function GetFileDescription(const FileName, ExceptText:string):string;
type TLangRec = array[0..1] of Word;
var
  InfoSize, zero:Cardinal;
  pbuff: Pointer;
  pk: Pointer;
  nk: Cardinal;
  lang_hex_str: String;
  LangID:Word;
  LangCP:Word;
begin
 pbuff:=nil;
 Result:='';
 InfoSize:=GetFileVersionInfoSize(PChar(FileName), zero);
 if InfoSize <> 0 then
  try
   GetMem(pbuff, InfoSize);
   if GetFileVersionInfo(PChar(FileName), 0, InfoSize, pbuff) then
    begin
     if VerQueryValue(pbuff, '\VarFileInfo\Translation', pk, nk) then
      begin
       LangID:= TLangRec(pk^)[0];
       LangCP:= TLangRec(pk^)[1];
       lang_hex_str:= Format('%.4x',[LangID]) + Format('%.4x', [LangCP]);  //FileDescription
       if VerQueryValue(pbuff, PChar('\\StringFileInfo\\'+lang_hex_str+'\\FileDescription'), pk, nk)
       then Result:=String(PChar(pk))
       else
        if VerQueryValue(pbuff, PChar('\\StringFileInfo\\'+lang_hex_str+'\\CompanyName'), pk, nk)
        then Result:=String(PChar(pk));
      end;
    end;
  finally
   if pbuff <> nil then FreeMem(pbuff);
  end;
 if Result = '' then
  if (ExceptText <> '') then if (ExceptText <> '/') then Result:=ExceptText else Exit('')
  else Result:=GetFileNameWoE(FileName);
end;

procedure ShowPropertiesDialog(FName:string);
var ShellInfo:TSHELLEXECUTEINFO;
begin
 ZeroMemory(Addr(ShellInfo), SizeOf(ShellInfo));
 ShellInfo.cbSize:=SizeOf(ShellInfo);
 ShellInfo.lpFile:=PChar(FName);
 ShellInfo.lpVerb:='PROPERTIES';
 ShellInfo.fMask:=SEE_MASK_INVOKEIDLIST;
 ShellExecuteEx(Addr(ShellInfo));
end;

function ReadStringList(Roll:TRegistry; const name:string):String;
var BufSize,
    DataType: DWORD;
    i:Integer;
    Buffer: PChar;
begin
 Result:='';
 if not Roll.ValueExists(name) then Exit;
 BufSize:=Roll.GetDataSize(Name);
 if BufSize < 1 then Exit;
 Buffer:=nil;
 try
  DataType:=REG_NONE;
  Buffer:=AllocMem(BufSize);
  if RegQueryValueEx(Roll.CurrentKey, PChar(name), nil, @DataType, PByte(Buffer), @BufSize) <> ERROR_SUCCESS
  then Exit;
  if DataType <> REG_MULTI_SZ then Exit;
  for i:= 0 to (BufSize div 2) - 3 do
   begin
    if Buffer[i] = #0 then Buffer[i]:=' ';
   end;
  Result:=Buffer;
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
      if GetFileVersionInfo(PChar(FileName), Wnd, InfoSize, VerBuf) then
        if VerQueryValue(VerBuf, '\', Pointer(FI), VerSize) then
          Result := FI.dwFileVersionMS;
    finally
      FreeMem(VerBuf);
    end;
  end;
end;

function UnixDateTimeToDelphiDateTime(UnixDateTime:LongInt):TDateTime;
var lpTimeZoneInformation: TTimeZoneInformation;
    SystemTime:TSystemTime;
begin
 Result:=EncodeDate(1970, 1, 1) + (UnixDateTime / 86400);
 GetTimeZoneInformation(lpTimeZoneInformation);
 with SystemTime do
  begin
   DecodeDate(Result, wYear, wMonth, wDay);
   DecodeTime(Result, wHour, wMinute, wSecond, wMilliseconds);
   SystemTimeToTzSpecificLocalTime(@lpTimeZoneInformation, SystemTime, SystemTime);
   Result:=EncodeDate(wYear, wMonth, wDay) + EncodeTime(wHour, wMinute, wSecond, wMilliseconds);
  end;
end;

function GetRegValue(ARootKey: HKEY; AKey, Value: String): String;
var Reg: TRegistry;
begin
 Result:= '';
 Reg:= TRegistry.Create(KEY_READ);
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
 lpDomainName,
 lpUserName: string;
 szDomainName,
 szUserName: DWord;
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
   SetLength(lpUserName,szUserName);
   SetLength(lpDomainName,szDomainName);
   Result:=Format('%s\%s', [lpDomainName, lpUserName]);;
  end;
end;

procedure RaiseWin32Error(Code:LongInt);
var E:EWin32Exception;
begin
 E:=EWin32Exception.Create(SysErrorMessage(Code));
 E.ErrorCode:=Code;
 raise E;
end;

end.
