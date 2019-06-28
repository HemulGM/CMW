////////////////////////////////////////////////////////////////////////////////
//
//  ****************************************************************************
//  * Unit Name : FWEventLog.pas
//  * Purpose   : ����� ���������� � ��������� �����
//  * Author    : ��������� (Rouse_) ������
//  * Copyright : � Fangorn Wizards Lab 1998 - 2006 (������)
//  * Version   : 1.00
//  * HomePage  : http://rouse.front.ru
//  ****************************************************************************
//

unit FWEventLog;

interface

uses
  Windows, Messages, SysUtils, Dialogs, Classes, Registry, ComCtrls;

type
  // ���� �������, ����� � ���� ������������� ���� ��� ��������
  TFWEventLogRecordType = (rtSuccess, rtError, rtWarning, rtInformation, rtAuditSuccess, rtAuditFailed);

  // ���� �������� ���������� � ������
  TFSOpenState = (osRead, osWrite, osBackUp, osNotify);

  TFSOpenStates = set of TFSOpenState;

  // ���� ����� ���������� ����
  TFWEventSources = (esUnknown, esApplication, esSecurity, esSystem, esBackup);

  TFWLocalEventSources = esApplication..esSystem;

  TStringArray = array of string;

  // ������ � ������������ ������� ����� ������� ����������� ������ ���������
  TFWEventLogRecord = packed record
    Number: DWORD;         // ���������� ����� ������ � ������
    EventID: DWORD;         // ID �������
    EventType: TFWEventLogRecordType; // ��� ��������
    Category: string;        // ���������
    SourceName: string;        // ��������
    ComputerName: string;        // ��� ����������
    Account: string;        // �������
    Domain: string;        // �����
    TimeCreated: TDateTime;     // ����� ��������
    TimeWritten: TDateTime;     // ����� ����������
    Description: string;        // ��������
    BinData: array of Byte; // �������� ������
  end;

  //�������� !!!
  // ������ ��������� ������������� ��������� � ��������,
  // �� ���� ��������� ��������� ����� �������� ������ ��� �������,
  // ��� ����������, ���������� ��� ��������, �����������������
  // � ��������� �������, �.�. ���������� TFWEventLog.RegisterApp()


  // ��������� ��� �������� ���������� ����������� ��������� (����������),
  // ������� ���� ��������� ��� ��������� �������
  TFWMessageTableLibrary = packed record
    bLoaded: Boolean;
    hLibHandle: THandle;
    sLibName: ShortString;
  end;

  TFWMessageTableLibraryes = packed record
    Count: Integer;
    Item: array of TFWMessageTableLibrary;
  end;

  PEventLogRecord = ^TEventLogRecord;
  { �������� �� MSDN

  The defined members are followed by the replacement strings
  for the message identified by the event identifier,
  the binary information, some pad bytes to make sure
  the full entry is on a DWORD boundary,
  and finally the length of the log entry again.
  Because the strings and the binary information can be of any length,
  no structure members are defined to reference them.

  The declaration of this structure in Winnt.h
  describes these members as follows:

    // WCHAR SourceName[]
    // WCHAR Computername[]
    // SID   UserSid
    // WCHAR Strings[]
    // BYTE  Data[]
    // CHAR  Pad[]
    // DWORD Length;
  }

  // ���������� �� WINNT.H

  TEventLogRecord = packed record
    Length: DWORD;              // Length of full record
    Reserved: DWORD;            // Used by the service
    RecordNumber: DWORD;        // Absolute record number
    TimeGenerated: DWORD;       // Seconds since 1-1-1970
    TimeWritted: DWORD;         // Seconds since 1-1-1970
    EventID: DWORD;
    EventType: WORD;
    NumStrings: WORD;
    EventCatagory: WORD;
    ReservedFlags: WORD;        // For use with paired events (auditing)
    ClosingRecordNumber: DWORD; // For use with paired events (auditing)
    StringOffset: DWORD;        // Offset from beginning of record
    UserSidLength: DWORD;
    UserSidOffset: DWORD;
    DataLength: DWORD;
    DataOffset: DWORD;          // Offset from beginning of record
  end;

  // ��������� ������� ������
  // ������� �� ������������� ��� ��������� ��������, ��� � ������� ��������
  TFWOnReadRecordEvent = procedure(Sender: TObject; EventRecord: TFWEventLogRecord; var Stop: Boolean) of object;

  TFWOnReadRecordCallback = procedure(Sender: TObject; EventRecord: TFWEventLogRecord; var Stop: Boolean);

  TFWOnChangeEvent = procedure(Sender: TObject; EventRecord: TFWEventLogRecord) of object;

  TFWOnChangeCallback = procedure(Sender: TObject; EventRecord: TFWEventLogRecord);

  TFWEventLog = class;

  // �����, �������� �� ����������� � ��������� ����
  TFWNotifyThread = class(TThread)
  private
    EventLog: TFWEventLog;
    FNotifyHandle: THandle;
    FOnChangeEvent: TFWOnChangeEvent;
    FOnChangeCallback: TFWOnChangeCallback;
  protected
    procedure OnChange;
    procedure OnError;
    procedure Execute; override;
  end;

  TFWEventLog = class
  private
    // 4 ��������� ���������, ����������� �������� � ����� � ���������� �������
    FReadHandle,              // ������
                              // ������������ ��� ������ �������,
                              // ��������� ���-�� �������,
                              // �������� ����� ������,
                              // ������� �������
    FWriteHandle,             // ������
                              // ������������ ������ ��� ���������� �������
    FBackUpHandle,            // ������ � �������
                              // ������������ ��� ������ ������� �� ��������� �����,
                              // � ��������� ���-�� ������� � ���� �����
    FNotifyHandle: THandle;   // ����� ������������ ��� ���������� �����������
                              // ������ ����� ����������� ������������ ���
                              // ��������� ������� ������� ������ �
                              // ������ ������ ������

    FSource, FRegisterKey: string;
    FReadSourceType, FWriteSourceType, FBackupSourceType, FNotifySourceType: TFWEventSources;
    FIsAdmin: Boolean;
    FState: TFSOpenStates;
    MessageTableLibraryes: TFWMessageTableLibraryes;
    FNotifyThread: TFWNotifyThread;
    FErrorWnd: HWND;
    FOnReadRecordCallback: TFWOnReadRecordCallback;
  protected
    procedure OnReadRecord(Sender: TObject; EventRecord: TFWEventLogRecord; var Stop: Boolean);
    procedure WndProc(var Message: TMessage); virtual;
    property ErrorWnd: HWND read FErrorWnd;
  protected
    function CustomOpen(const Source: TFWEventSources; const State: TFSOpenState; Backup: string = ''): Boolean;
    function CustomReadSequential(EventHandle: THandle; SourceType: TFWEventSources; const Forwards: Boolean; CallbackEvent: TFWOnReadRecordEvent): Boolean;
    function CustomReadListView(EventHandle: THandle; SourceType: TFWEventSources; const Groups: Boolean; const NeedDate: Word; const Filtered: Boolean; const EType: TFWEventLogRecordType; ListView: TListView): Boolean;
    function CustomReadSeek(EventHandle: THandle; SourceType: TFWEventSources; Index: DWORD; var EventRecord: TFWEventLogRecord): Boolean;
    procedure GetAccountAndDomainName(const SID: PSID; var Account, Domain: string);
    function GetCategoryString(Source: string; SourceType: TFWEventSources; CategoryID: DWORD): string;
    function GetEventString(Source: string; SourceType: TFWEventSources; EventID: DWORD; Parameters: TStringArray): string;
    function GetWordTypeWromRecordType(const RecType: TFWEventLogRecordType): Word;
    function GetRecordTypeFromWordType(const WordType: Word): TFWEventLogRecordType;
    function IsAdmin: Boolean;
    function LoadStringFromMessageTable(Source, RegParam: string; SourceType: TFWEventSources; ID: DWORD; Parameters: Pointer): string;
    function ParseEventLogRecord(SourceType: TFWEventSources; const EventLogRecord: TEventLogRecord): TFWEventLogRecord;
    procedure PrepareParameters(List: TList; Parameters: TStringArray);
    function UCTToDateTime(Value: DWORD): TDateTime;
  public
    constructor Create(const Source: string);
    destructor Destroy; override;
    function BackupOpen(FilePath: string; const Source: TFWLocalEventSources): Boolean;
    function CreateBackup(FilePath: string): Boolean;
    function Clear(BackupPath: string = ''): Boolean;
    procedure Close(const State: TFSOpenState);
    function DeregisterApp: Boolean;
    procedure DeRegisterChangeNotify;
    class function EventTypeToString(const EventType: TFWEventLogRecordType): string;
    function IsEventLogFull: Boolean;
    function IsRegistered: Boolean;
    function Open(const Source: TFWLocalEventSources; const State: TFSOpenState): Boolean;
    function Read(const Backup: Boolean; Index: DWORD; var EventRecord: TFWEventLogRecord): Boolean; overload;
    function Read(const Backup: Boolean; const Forwards: Boolean; CallbackEvent: TFWOnReadRecordEvent): Boolean; overload;
    function Read(const Backup: Boolean; const Groups: Boolean; const Date: Word; const Filtered: Boolean; const EType: TFWEventLogRecordType; ListView: TListView): Boolean; overload;
    function Read(const Backup: Boolean; const Forwards: Boolean; lpfnCallback: TFWOnReadRecordCallback): Boolean; overload;
    function RecordCount(const Backup: Boolean; Oldest: Boolean = False): DWORD;
    function RegisterApp(CategoryCount: Integer = 1): Boolean;
    function RegisterChangeNotify(Event: TFWOnChangeEvent): Boolean; overload;
    function RegisterChangeNotify(Callback: TFWOnChangeCallback): Boolean; overload;
    function Write(RecType: TFWEventLogRecordType; Msg: string; RAWData: Pointer; RAWDataSize: Integer; Category: Word = 1; EventID: Word = 0): Boolean; overload;
    function Write(RecType: TFWEventLogRecordType; Msg: string; Category: Word = 1; EventID: Word = 0): Boolean; overload;
    property OpenState: TFSOpenStates read FState;
    property SourceName: string read FSource;
    property ReadSourceType: TFWEventSources read FReadSourceType;
    property WriteSourceType: TFWEventSources read FWriteSourceType;
    property BackupSourceType: TFWEventSources read FBackupSourceType;
  end;

  EFWEventLog = class(Exception);

function EventTypeToStr(EventType: Word): string;

const
  RegEventSources: array[TFWEventSources] of string = ('', 'Application', 'Security', 'System', '');

implementation

uses
  CMW.Main, CMW.Utils;

const
  // ��������� �� WINNT.H

  // The types of events that can be logged.
  EVENTLOG_SUCCESS = $0000;
  EVENTLOG_ERROR_TYPE = $0001;
  EVENTLOG_WARNING_TYPE = $0002;
  EVENTLOG_INFORMATION_TYPE = $0004;
  EVENTLOG_AUDIT_SUCCESS = $0008;
  EVENTLOG_AUDIT_FAILURE = $0010;

  // Defines for the READ flags for Eventlogging
  EVENTLOG_SEQUENTIAL_READ = $0001;
  EVENTLOG_SEEK_READ = $0002;
  EVENTLOG_FORWARDS_READ = $0004;
  EVENTLOG_BACKWARDS_READ = $0008;

resourcestring
  ROOT_EVENTLOG_REGKEY = 'SYSTEM\CurrentControlSet\Services\EventLog\';
  STR_CATEGORY = 'CategoryMessageFile';
  STR_EVENT = 'EventMessageFile';
  STR_CATEGORY_COUNT = 'CategoryCount';
  STR_TYPE = 'TypesSupported';
  ERR_NOADMIN = '��� ����������� ���������� � ��������� �������,' + ' ��������� ������ ���� �������� �� ��� ������� ������ ��������������.';
  ERR_REGISTER = '���������� ���������������� ���������� � ��������� �������.';
  ERR_WRONG_STATE = '�������� �� ����� ���� ������� ���������� � ������ ������.' + sLineBreak + '��� ���������� �������� �������� ������� ������ ���� ������ � ������ "%s"';
  ERR_RESLIB_NOT_FOUND = '�� ������� �������� ��� ������� � ����� ( %d ) � ��������� ( %s ). ' + '��������, �� ��������� ���������� ��� ������ ������ � ������� ' + '��� ������ DLL ��������� ��� ����������� ��������� ���������� ����������. ' + '� ������ ������� ���������� ��������� ����������: %s';
  ERR_CALLBACK_NOT_FOUND = '�� ������ ������� ��������� ������.';
  ERR_UNSAFE_OPERATION = '��� ���������� �������� � ������ osNotify, ' + '����������� ������ RegisterChangeNotify/DeRegisterChangeNotify.';
  ERR_DOUBLE_REGISTER = '��� ���������� ��������� ����������� �� ������� ' + '����������, ���������� ����� ���������� ����������� ' + '��� ������ DeRegisterChangeNotify.';
  ERR_NOTIFY_THREAD = '������ ������ �������� ����������. ��� ������ %d, �������� "%s"';
  ERR_TYPE_CONV = '������ �������������� �����';
  ERR_DOUBLE_OPEN = '�������� ������� ��� ������ � ������ ������ %s.';

const
  OFFSET_SIZE = SizeOf(DWORD) - 2;
  WM_THREAD_ERROR = WM_USER;

function EventTypeToStr(EventType: Word): string;
begin
  case EventType of
    EVENTLOG_SUCCESS:
      Result := '�����';
    EVENTLOG_ERROR_TYPE:
      Result := '������';
    EVENTLOG_WARNING_TYPE:
      Result := '��������������';
    EVENTLOG_INFORMATION_TYPE:
      Result := '����������';
    EVENTLOG_AUDIT_SUCCESS:
      Result := '����� ������';
    EVENTLOG_AUDIT_FAILURE:
      Result := '����� ������';
  else
    Result := '����������';
  end;
end;

{ TFWNotifyThread }

//
//  ���� �������� �����������
// =============================================================================
procedure TFWNotifyThread.Execute;
var
  hEvent: THandle;
begin
  // ������� �����, ��������� �������� ����� ��������� ��� ��������� ����
  hEvent := CreateEvent(nil, False, False, nil);
  try
    // ������������� �� �����������
    NotifyChangeEventLog(FNotifyHandle, hEvent);
    while not Terminated do
    begin
      // �������� �����������
      case WaitForSingleObject(hEvent, 100) of
        WAIT_OBJECT_0:
          // ��� ���������
          Synchronize(OnChange);
        WAIT_FAILED:
          begin
          // ��������� ������
            Synchronize(OnError);
            Exit;
          end;
      end;
    end;
  finally
    CloseHandle(hEvent);
  end;
end;

//
//  ����������� ������ � ���������
// =============================================================================
procedure TFWNotifyThread.OnChange;
var
  EventRecord: TFWEventLogRecord;
  RecordIndex, Oldest: DWORD;
begin
  // �������� ������ ��������� ������ � ����
  GetNumberOfEventLogRecords(EventLog.FNotifyHandle, RecordIndex);
  GetOldestEventLogRecord(EventLog.FNotifyHandle, Oldest);
  Inc(RecordIndex, Oldest - 1);
  // ������ ������ ������
  if EventLog.CustomReadSeek(EventLog.FNotifyHandle, EventLog.FNotifySourceType, RecordIndex, EventRecord) then
  begin
    // ��������� ������� � ����� ������
    if Assigned(FOnChangeEvent) then
      FOnChangeEvent(EventLog, EventRecord)
    else if Assigned(FOnChangeCallback) then
      FOnChangeCallback(EventLog, EventRecord);
  end
  else
    OnError;
end;

//
//  ��������� ���������� ������ :)
// =============================================================================
procedure TFWNotifyThread.OnError;
begin
  // �.�. ����� ���������� ����� Synchronize,
  // ��������� ����� �� ����� ������, ��������� ���
  // Synchronize ������� � SEH.
  // ������ ���������� ���������� ��������� ������ ������,
  // � �� ��� � ���� �������� ����������
  PostMessage(EventLog.ErrorWnd, WM_THREAD_ERROR, EventLog.ErrorWnd, GetLastError);
end;

{ TFWEventLog }

//
//  �������� ����� ������
// =============================================================================
function TFWEventLog.BackupOpen(FilePath: string; const Source: TFWLocalEventSources): Boolean;
begin
  Result := CustomOpen(Source, osBackUp, FilePath);
end;

//
//  ������� ������ �������
//  � �������� ��������������� ��������� ����������� ���� � �����,
//  � ������� ����� �������� ��� ��������� �������.
//  ��� ��������� ����������, �������� ������� ������ ���� ������ �� ������
// =============================================================================
function TFWEventLog.Clear(BackupPath: string): Boolean;
begin
  if not (osRead in OpenState) then
    raise EFWEventLog.Create(Format(ERR_WRONG_STATE, ['osRead']));
  Result := ClearEventLog(FReadHandle, PChar(BackupPath));
end;

//
//  �������� ����������
// =============================================================================
procedure TFWEventLog.Close(const State: TFSOpenState);
var
  I: Integer;
begin
  if not (State in FState) then
    Exit;
  case State of
    osRead: // �������� ��������� �� ������
      begin
        CloseEventLog(FReadHandle);
        FReadHandle := 0;
      // ��������� ��� ����� ������������ ����������
        for I := 0 to MessageTableLibraryes.Count - 1 do
        begin
          MessageTableLibraryes.Item[I].sLibName := '';
          if MessageTableLibraryes.Item[I].bLoaded then
            FreeLibrary(MessageTableLibraryes.Item[I].hLibHandle);
        end;
        MessageTableLibraryes.Count := 0;
        SetLength(MessageTableLibraryes.Item, 0);
      end;
    osWrite: // �������� ��������� �� ������
      begin
        DeregisterEventSource(FWriteHandle);
        FWriteHandle := 0;
      end;
    osBackUp: // �������� ��������� ������ � ������ ������
      begin
        CloseEventLog(FBackUpHandle);
        FBackUpHandle := 0;
      // ���� �� ������������ �����  ������,
      // ��������� ��� ����� ������������ ����������
        if not (osRead in FState) then
        begin
          for I := 0 to MessageTableLibraryes.Count - 1 do
          begin
            MessageTableLibraryes.Item[I].sLibName := '';
            if MessageTableLibraryes.Item[I].bLoaded then
              FreeLibrary(MessageTableLibraryes.Item[I].hLibHandle);
          end;
          MessageTableLibraryes.Count := 0;
          SetLength(MessageTableLibraryes.Item, 0);
        end;
      end;
  else
    raise EFWEventLog.Create(ERR_UNSAFE_OPERATION);
  end;
  Exclude(FState, State);
end;

//
//  �������������
// =============================================================================
constructor TFWEventLog.Create(const Source: string);
begin
  FSource := Source;
  FRegisterKey := ROOT_EVENTLOG_REGKEY + RegEventSources[esApplication] + '\' + Source;
  FIsAdmin := IsAdmin;
  FReadHandle := 0;
  FWriteHandle := 0;
  FBackUpHandle := 0;
  FNotifyHandle := 0;
  FOnReadRecordCallback := nil;
  FNotifyThread := nil;
  FReadSourceType := esUnknown;
  FWriteSourceType := esUnknown;
end;

//
//  �������� ������ ������� �������� ����� ���� �������
//  ��� ��������� ����������, �������� ������� ������ ���� ������ �� ������
// =============================================================================
function TFWEventLog.CreateBackUp(FilePath: string): Boolean;
begin
  if not (osRead in OpenState) then
    raise EFWEventLog.Create(Format(ERR_WRONG_STATE, ['osRead']));
  Result := BackupEventLog(FReadHandle, PChar(FilePath));
end;

//
//  ������ ������ �� �� �������
//  ��� ��������� ����������, �������� ������� ������ ���� ������ �� ������
// =============================================================================
function TFWEventLog.CustomOpen(const Source: TFWEventSources; const State: TFSOpenState; Backup: string): Boolean;
const
  States: array[TFSOpenState] of string = ('osRead', 'osWrite', 'osBackUp', '');
begin
  Result := False;
  if (State in FState) then
    raise EFWEventLog.Create(Format(ERR_DOUBLE_OPEN, [States[State]]));
  case State of
    osRead:
      begin
        FReadHandle := OpenEventLog(nil, PChar(RegEventSources[Source]));
        if FReadHandle = 0 then
          Exit;
        FReadSourceType := Source;
      end;
    osWrite:
      begin
        FWriteHandle := RegisterEventSource(nil, PChar(FSource));
        if FWriteHandle = 0 then
          Exit;
        FWriteSourceType := Source;
      end;
    osBackUp:
      begin
        FBackUpHandle := OpenBackupEventLog(nil, PChar(Backup));
        if FBackUpHandle = 0 then
          Exit;
        FBackupSourceType := Source;
      end;
  else
    raise EFWEventLog.Create(ERR_UNSAFE_OPERATION);
  end;
  Result := True;
  Include(FState, State);
end;

//
//  ������ ������ �� �� �������
//  ��� ��������� ����������, �������� ������� ������ ���� ������ �� ������
// =============================================================================
function TFWEventLog.CustomReadSeek(EventHandle: THandle; SourceType: TFWEventSources; Index: DWORD; var EventRecord: TFWEventLogRecord): Boolean;
const
  SeekFlags = EVENTLOG_SEEK_READ or EVENTLOG_FORWARDS_READ;
var
  lpBuffer: PEventLogRecord;
  NumberOfBytesToRead, dwError: DWORD;
  BytesRead, MinNumberOfBytesNeeded: DWORD;
begin
  Result := False;
  lpBuffer := nil;
  NumberOfBytesToRead := SizeOf(TEventLogRecord);
  // �������� ������ ��� ������ ���������
  GetMem(lpBuffer, NumberOfBytesToRead);
  try
    MinNumberOfBytesNeeded := 0;
    BytesRead := 0;
    // ������, ������� ������ ��������� ��� ������������ ���������
    ReadEventLog(EventHandle, SeekFlags, Index, lpBuffer, NumberOfBytesToRead, BytesRead, MinNumberOfBytesNeeded);
    dwError := GetLastError;
    if dwError = ERROR_INSUFFICIENT_BUFFER then
    begin
      NumberOfBytesToRead := MinNumberOfBytesNeeded;
      // �������� ����������� ����� ������
      ReallocMem(lpBuffer, MinNumberOfBytesNeeded);
      // �������� ������
      Result := ReadEventLog(EventHandle, SeekFlags, Index, lpBuffer, NumberOfBytesToRead, BytesRead, MinNumberOfBytesNeeded);
      if Result then
        // ����������� ������ � ����������� ���
        EventRecord := ParseEventLogRecord(SourceType, lpBuffer^);
    end;
  finally
    FreeMem(lpBuffer);
  end;
end;

//
//  ������ ������� �� �������
//  � �������� ������� ��������� ������ ������������ ��������� ���������
//  ��� ��������� ����������, �������� ������� ������ ���� ������ �� ������
// =============================================================================
function TFWEventLog.CustomReadSequential(EventHandle: THandle; SourceType: TFWEventSources; const Forwards: Boolean; CallbackEvent: TFWOnReadRecordEvent): Boolean;
var
  lpBuffer, OutputBuffer: PEventLogRecord;
  NumberOfBytesToRead, OldestNumberRecordCount, NumberRecordCount: DWORD;
  BytesRead, MinNumberOfBytesNeeded, SeekFlags, SeekIndex, BytesLeft: DWORD;
  Data: TFWEventLogRecord;
  Stop, FirstCall: Boolean;
begin
  Result := False;

  // ��������� ������� ��������� ��������� ������
  if not Assigned(CallbackEvent) then
    raise EFWEventLog.Create(ERR_CALLBACK_NOT_FOUND);

  // �������� ���-�� ������� � ����
  if not GetNumberOfEventLogRecords(EventHandle, NumberRecordCount) then
    Exit;

  // �������� ���-�� ���������� ������� � ����
  if not GetOldestEventLogRecord(EventHandle, OldestNumberRecordCount) then
    Exit;

  // ������� ��������� ����������� ������
  FirstCall := True;
  if Forwards then
  begin
    // ������ � ������ �� ���������
    SeekFlags := EVENTLOG_SEEK_READ or EVENTLOG_FORWARDS_READ;
    // ������������� ������ ��������� ������ (������)
    SeekIndex := OldestNumberRecordCount;
  end
  else
  begin
    // ������ � ��������� �� ������
    SeekFlags := EVENTLOG_SEEK_READ or EVENTLOG_BACKWARDS_READ;
    // ������������� ������ ��������� ������ (���������)
    SeekIndex := OldestNumberRecordCount + NumberRecordCount - 1;
  end;

  lpBuffer := nil;
  NumberOfBytesToRead := SizeOf(TEventLogRecord);
  MinNumberOfBytesNeeded := 0;
  BytesRead := 0;
  // �������� ������ ��� ������ ���������
  GetMem(lpBuffer, NumberOfBytesToRead);
  try
    repeat
      // ������� �������� ������
      Result := ReadEventLog(EventHandle, SeekFlags, SeekIndex, lpBuffer, NumberOfBytesToRead, BytesRead, MinNumberOfBytesNeeded);

      if not Result then
        case GetLastError of
          ERROR_INSUFFICIENT_BUFFER:
            begin
            // ������� ���������, �� ��� ��������,
            // ������� ������ ��������� ��� ������������ ���������
              NumberOfBytesToRead := MinNumberOfBytesNeeded;
            // �������� ����������� ����� ������
              ReallocMem(lpBuffer, MinNumberOfBytesNeeded);
            // �������� ������
              Result := ReadEventLog(EventHandle, SeekFlags, SeekIndex, lpBuffer, NumberOfBytesToRead, BytesRead, MinNumberOfBytesNeeded);
            end;
          ERROR_HANDLE_EOF:
            begin
              Result := True;
              Exit;
            end
        else
          Result := False;
        end;

      // ����� ������ ����� ��������� � ������  EVENTLOG_SEEK_READ
      // ��� ���������� ��� ���������������� ������� �� ����������� ������
      // ��� ���������� ������ ��������� � ������ EVENTLOG_SEQUENTIAL_READ
      // (���������������� ������)
      if FirstCall then
      begin
        FirstCall := False;
        SeekFlags := (SeekFlags or EVENTLOG_SEQUENTIAL_READ) and not EVENTLOG_SEEK_READ;
        SeekIndex := 0;
      end;

      if Result then
      // ������ ��������� �������
      begin
        // ��� ������ ������
        // ������� ReadEventLog �������� � ���������� ������
        // ������� �������, ������� ���� ����� ����������� �������.
        // ������� ����� ��������� ������� ���������� ������� ������������
        // �� ������ ����������� ������� � ����� ������� ������,
        // ������� �� ������� ������ � �������� ���������� ������.
        BytesLeft := BytesRead;
        OutputBuffer := lpBuffer;
        repeat
          Data := ParseEventLogRecord(SourceType, OutputBuffer^);
          Dec(BytesLeft, OutputBuffer^.Length);
          OutputBuffer := Pointer(DWORD(OutputBuffer) + OutputBuffer^.Length);
          CallbackEvent(Self, Data, Stop);
          if Stop then
            Exit;
        until BytesLeft <= 0;
      end;

    until not Result;
  finally
    FreeMem(lpBuffer);
  end;
end;

//
//  ������ ������� � ListView
//  ��� ��������� ����������, �������� ������� ������ ���� ������ �� ������
// =============================================================================
function TFWEventLog.CustomReadListView(EventHandle: THandle; SourceType: TFWEventSources; const Groups: Boolean; const NeedDate: Word; const Filtered: Boolean; const EType: TFWEventLogRecordType; ListView: TListView): Boolean;
var
  lpBuffer, OutputBuffer: PEventLogRecord;
  NumberOfBytesToRead, OldestNumberRecordCount, NumberRecordCount: DWORD;
  BytesRead, MinNumberOfBytesNeeded, SeekFlags, SeekIndex, BytesLeft: DWORD;
  Data: TFWEventLogRecord;
  FirstCall: Boolean;
  LI: TListItem;
  DInt: PDWORD;
  Roll: TRegistry;
  RegOK: Boolean;
begin
  Result := False;

  // ��������� ������� ��������� ��������� ������
  if not Assigned(ListView) then
    raise EFWEventLog.Create(ERR_CALLBACK_NOT_FOUND);

  // �������� ���-�� ������� � ����
  if not GetNumberOfEventLogRecords(EventHandle, NumberRecordCount) then
    Exit;

  // �������� ���-�� ���������� ������� � ����
  if not GetOldestEventLogRecord(EventHandle, OldestNumberRecordCount) then
    Exit;

  Roll := TRegistry.Create(KEY_READ);
  Roll.RootKey := HKEY_LOCAL_MACHINE;

  // ������� ��������� ����������� ������
  FirstCall := True;

  // ������ � ������ �� ���������
  SeekFlags := EVENTLOG_SEEK_READ or EVENTLOG_FORWARDS_READ;
  // ������������� ������ ��������� ������ (������)
  SeekIndex := OldestNumberRecordCount;

  lpBuffer := nil;
  NumberOfBytesToRead := SizeOf(TEventLogRecord);
  MinNumberOfBytesNeeded := 0;
  BytesRead := 0;
  // �������� ������ ��� ������ ���������
  GetMem(lpBuffer, NumberOfBytesToRead);
  try
    repeat
      // ������� �������� ������
      Result := ReadEventLog(EventHandle, SeekFlags, SeekIndex, lpBuffer, NumberOfBytesToRead, BytesRead, MinNumberOfBytesNeeded);

      if not Result then
        case GetLastError of
          ERROR_INSUFFICIENT_BUFFER:
            begin
            // ������� ���������, �� ��� ��������,
            // ������� ������ ��������� ��� ������������ ���������
              NumberOfBytesToRead := MinNumberOfBytesNeeded;
            // �������� ����������� ����� ������
              ReallocMem(lpBuffer, MinNumberOfBytesNeeded);
            // �������� ������
              Result := ReadEventLog(EventHandle, SeekFlags, SeekIndex, lpBuffer, NumberOfBytesToRead, BytesRead, MinNumberOfBytesNeeded);
            end;
          ERROR_HANDLE_EOF:
            begin
              Result := True;
              Break;
            end
        else
          Result := False;
        end;

      // ����� ������ ����� ��������� � ������  EVENTLOG_SEEK_READ
      // ��� ���������� ��� ���������������� ������� �� ����������� ������
      // ��� ���������� ������ ��������� � ������ EVENTLOG_SEQUENTIAL_READ
      // (���������������� ������)
      if FirstCall then
      begin
        FirstCall := False;
        SeekFlags := (SeekFlags or EVENTLOG_SEQUENTIAL_READ) and not EVENTLOG_SEEK_READ;
        SeekIndex := 0;
      end;

      if Result then
      // ������ ��������� �������
      begin
        // ��� ������ ������
        // ������� ReadEventLog �������� � ���������� ������
        // ������� �������, ������� ���� ����� ����������� �������.
        // ������� ����� ��������� ������� ���������� ������� ������������
        // �� ������ ����������� ������� � ����� ������� ������,
        // ������� �� ������� ������ � �������� ���������� ������.
        BytesLeft := BytesRead;
        OutputBuffer := lpBuffer;
        repeat
          if Stopping then
            Break;
          Data := ParseEventLogRecord(SourceType, OutputBuffer^);
          Dec(BytesLeft, OutputBuffer^.Length);
          OutputBuffer := Pointer(DWORD(OutputBuffer) + OutputBuffer^.Length);
          if NeedDate > 0 then
            if Data.TimeCreated + NeedDate < Now then
              Continue;
          {if Filtered then
           if not CheckEventSel(Data.SourceName) then Continue;    }
          if Data.EventType = EType then
          begin
            with ListView.Items do
            begin
              LI := Add;
              case Data.EventType of
                rtError:
                  LI.StateIndex := 3;
                rtWarning:
                  LI.StateIndex := 2;
                rtInformation:
                  LI.StateIndex := 1;
                rtSuccess:
                  LI.StateIndex := 7;
                rtAuditSuccess:
                  LI.StateIndex := 7;
                rtAuditFailed:
                  LI.StateIndex := 8;
              else
                LI.StateIndex := 1;
              end;
              case SourceType of
                esUnknown:
                  LI.ImageIndex := 0;
                esApplication:
                  LI.ImageIndex := 5;
                esSecurity:
                  LI.ImageIndex := 4;
                esSystem:
                  LI.ImageIndex := 6;
                esBackup:
                  LI.ImageIndex := 0;
              else
                LI.ImageIndex := 0;
              end;

              DInt := AllocMem(SizeOf(Data.Number));
              DInt^ := Data.Number;
              LI.Data := DInt;
              LI.Caption := DateTimeToStr(Data.TimeWritten); //
              LI.SubItems.Add(Data.SourceName);
              LI.SubItems.Add(Data.Category);
              LI.SubItems.Add(IntToStr(Data.EventID));
              if Data.Account = '' then
                LI.SubItems.Add('�/�')
              else
                LI.SubItems.Add(Data.Account);
              LI.SubItems.Add(Data.ComputerName);
              LI.SubItems.Add('');
              if SourceType in [esSystem, esApplication, esSecurity] then
              begin
                Roll.CloseKey;
                if SourceType = esSystem then
                  RegOK := Roll.OpenKeyReadOnly('SYSTEM\CurrentControlSet\services\eventlog\System\' + Data.SourceName);
                if SourceType = esApplication then
                  RegOK := Roll.OpenKeyReadOnly('SYSTEM\CurrentControlSet\services\eventlog\Application\' + Data.SourceName);
                if SourceType = esSecurity then
                  RegOK := Roll.OpenKeyReadOnly('SYSTEM\CurrentControlSet\services\eventlog\Security\' + Data.SourceName);
                if RegOK then
                begin
                  if Roll.ValueExists('EventMessageFile') then
                    LI.SubItems[5] := Roll.GetDataAsString('EventMessageFile', False)
                  else if Roll.ValueExists('providerGuid') then
                    LI.SubItems[5] := Roll.GetDataAsString('providerGuid', False);
                end;
              end;

              if Groups then
                LI.GroupID := GetGroup(ListView, Data.SourceName, False)
              else
                LI.GroupID := -1;
            end;
          end;
          //Stop:=Stopping;
          //CallbackEvent(Self, Data, Stop);
        until BytesLeft <= 0;
      end;
      if Stopping then
        Break;
    until not Result;
  finally
    begin
      Roll.Free;
      FreeMem(lpBuffer);
    end;
  end;
end;

//
//  ������ ���������� � ����������� � �������� ��������� ������� ���������,
//  ����� �������� ��������������� ������ � �������
// =============================================================================
function TFWEventLog.DeregisterApp: Boolean;
begin
  if not FIsAdmin then
  begin
    ShowMessage(ERR_REGISTER);
    Result := False;
    Exit;
  end;
  Result := True;
  try
    with TRegistry.Create do
    try
      RootKey := HKEY_LOCAL_MACHINE;
      DeleteKey(FRegisterKey);
    finally
      Free;
    end;
  except
    Result := False;
  end;
end;

//
//  ���������� ������ ��������� �� ���������� ������� �������
// =============================================================================
procedure TFWEventLog.DeRegisterChangeNotify;
begin
  if (osNotify in FState) then
  begin
    if FNotifyThread <> nil then
    begin
      FNotifyThread.Terminate;
      FNotifyThread := nil;
    end;
    CloseEventLog(FNotifyHandle);
    FNotifyHandle := 0;
    Exclude(FState, osNotify);
  end;
end;

//
//  �����������
// =============================================================================
destructor TFWEventLog.Destroy;
var
  I: TFSOpenState;
begin
  for I := osRead to osBackUp do
    if I in FState then
      Close(I);
  DeRegisterChangeNotify;
  inherited;
end;

//
//  ��������������� �������
// =============================================================================
class function TFWEventLog.EventTypeToString(const EventType: TFWEventLogRecordType): string;
begin
  case EventType of
    rtSuccess, rtInformation:
      Result := '�����������';
    rtError:
      Result := '������';
    rtWarning:
      Result := '��������������';
    rtAuditSuccess:
      Result := '����� �������';
    rtAuditFailed:
      Result := '����� �������';
  end;
end;

//
//  ���������� ������������ �������� � ������ �� �����������
//  ����������� ������������
// =============================================================================
procedure TFWEventLog.GetAccountAndDomainName(const SID: PSID; var Account, Domain: string);
var
  cbName, cbReferencedDomainName, peUse: DWORD;
begin
  cbName := MAX_PATH;
  cbReferencedDomainName := MAX_PATH;
  peUse := 0;
  SetLength(Account, cbName);
  SetLength(Domain, cbReferencedDomainName);
  ZeroMemory(@Account[1], MAX_PATH);
  ZeroMemory(@Domain[1], MAX_PATH);
  Assert(SID <> nil, 'SID ������');
  LookupAccountSid(nil, SID, @Account[1], cbName, @Domain[1], cbReferencedDomainName, peUse);
end;

//
//  ������� ��������� ���������� �������� ��������� �� �� ��������������
// =============================================================================
function TFWEventLog.GetCategoryString(Source: string; SourceType: TFWEventSources; CategoryID: DWORD): string;
begin
  Result := LoadStringFromMessageTable(Source, STR_CATEGORY, SourceType, Word(CategoryID), nil);
  if Result = '' then
    Result := '�����������';
end;

//
//  ������� ��������� ���������� �������� ������� �� ��� ��������������
// =============================================================================
function TFWEventLog.GetEventString(Source: string; SourceType: TFWEventSources; EventID: DWORD; Parameters: TStringArray): string;
var
  List: TList;
  Msg: string;
  I: Integer;
begin
  List := TList.Create;
  try
    PrepareParameters(List, Parameters);
    Result := LoadStringFromMessageTable(Source, STR_EVENT, SourceType, EventID, List.List);
  finally
    List.Free;
  end;

  if Result = '' then
  begin
    for I := 0 to Length(Parameters) - 1 do
      Msg := Msg + Parameters[I] + sLineBreak;
    Result := Format(ERR_RESLIB_NOT_FOUND, [Word(EventID), Source, PChar(Msg)]);
  end;
end;

//
//  �������������� ���� ������ � ������ ����������
// =============================================================================
function TFWEventLog.GetRecordTypeFromWordType(const WordType: Word): TFWEventLogRecordType;
begin
  case WordType of
    EVENTLOG_SUCCESS:
      Result := rtSuccess;
    EVENTLOG_ERROR_TYPE:
      Result := rtError;
    EVENTLOG_WARNING_TYPE:
      Result := rtWarning;
    EVENTLOG_INFORMATION_TYPE:
      Result := rtInformation;
    EVENTLOG_AUDIT_SUCCESS:
      Result := rtAuditSuccess;
    EVENTLOG_AUDIT_FAILURE:
      Result := rtAuditFailed;
  else
    raise EFWEventLog.Create(ERR_TYPE_CONV);
  end;
end;

//
//  �������������� ���� ������ � ������ ����������� ���
// =============================================================================
function TFWEventLog.GetWordTypeWromRecordType(const RecType: TFWEventLogRecordType): Word;
begin
  case RecType of
    rtSuccess:
      Result := EVENTLOG_SUCCESS;
    rtError:
      Result := EVENTLOG_ERROR_TYPE;
    rtWarning:
      Result := EVENTLOG_WARNING_TYPE;
    rtInformation:
      Result := EVENTLOG_INFORMATION_TYPE;
    rtAuditSuccess:
      Result := EVENTLOG_AUDIT_SUCCESS;
    rtAuditFailed:
      Result := EVENTLOG_AUDIT_FAILURE;
  else
    raise EFWEventLog.Create(ERR_TYPE_CONV);
  end;
end;

//
//  ��������, �������� �� ���������� �� ��� ������� ������ ��������������
// =============================================================================
function TFWEventLog.IsAdmin: Boolean;
const
  SECURITY_NT_AUTHORITY: TSIDIdentifierAuthority = (
    Value: (0, 0, 0, 0, 0, 5)
  );
  SECURITY_BUILTIN_DOMAIN_RID = $00000020;
  DOMAIN_ALIAS_RID_ADMINS = $00000220;
var
  hAccessToken: THandle;
  ptgGroups: PTokenGroups;
  dwInfoBufferSize: DWORD;
  psidAdministrators: PSID;
  I: Integer;
  bSuccess: BOOL;
begin
  Result := False;
  bSuccess := OpenThreadToken(GetCurrentThread, TOKEN_QUERY, True, hAccessToken);
  if not bSuccess then
  begin
    if GetLastError = ERROR_NO_TOKEN then
      bSuccess := OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, hAccessToken);
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
      for I := 0 to ptgGroups.GroupCount - 1 do
        if EqualSid(psidAdministrators, ptgGroups.Groups[I].SID) then
        begin
          Result := True;
          Break;
        end;
      {$R+}
      FreeSid(psidAdministrators);
    end;
    FreeMem(ptgGroups);
  end;
end;

const
  EVENTLOG_FULL_INFO = 0;

type
  EVENTLOG_FULL_INFORMATION = packed record
    dwFull: DWORD;
  end;

//
//  �������� ������������� ����
//  ��� ��������� ����������, �������� ������� ������ ���� ������ �� ������
// =============================================================================
function TFWEventLog.IsEventLogFull: Boolean;
var
  GetEventLogInformation: function(hEventLog: THandle; dwInfoLevel: DWORD; lpBuffer: Pointer; cbBufSize: DWORD; var pcbBytesNeeded: DWORD): Boolean; stdcall;
  Info: EVENTLOG_FULL_INFORMATION;
  Dumme: DWORD;
begin
  Result := False;
  if not (osRead in OpenState) then
    raise EFWEventLog.Create(Format(ERR_WRONG_STATE, ['osRead']));
  @GetEventLogInformation := GetProcAddress(GetModuleHandle(advapi32), 'GetEventLogInformation');
  if Assigned(@GetEventLogInformation) then
    if GetEventLogInformation(FReadHandle, EVENTLOG_FULL_INFO, @Info, SizeOf(EVENTLOG_FULL_INFORMATION), Dumme) then
      Result := Boolean(Info.dwFull);
end;

//
//  �������� ������� ����� ����������� ���������� � �������� �������
//  ������� ���������
// =============================================================================
function TFWEventLog.IsRegistered: Boolean;
begin
  with TRegistry.Create do
  try
    RootKey := HKEY_LOCAL_MACHINE;
    Result := KeyExists(FRegisterKey);
  finally
    Free;
  end;
end;

//
//  �������� ������������� ����
//  ��� ��������� ����������, �������� ������� ������ ���� ������ �� ������
// =============================================================================
function TFWEventLog.LoadStringFromMessageTable(Source, RegParam: string; SourceType: TFWEventSources; ID: DWORD; Parameters: Pointer): string;

  function MAKELANGID(PrimaryLang, SubLang: Word): Word;
  begin
    Result := (SubLang shl 10) or PrimaryLang;
  end;

  function GetCategoryStringFromModule(hLibHandle: THandle): string;
  var
    CategoryData: PChar;
  begin
    CategoryData := nil;
    if FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER or FORMAT_MESSAGE_FROM_HMODULE or FORMAT_MESSAGE_ARGUMENT_ARRAY, Pointer(hLibHandle), ID, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), @CategoryData, 0, Parameters) <> 0 then
    try
      Result := Trim(StrPas(CategoryData));
    finally
      LocalFree(DWORD(CategoryData));
    end;
  end;

var
  I: Integer;
  EnvLibPath, Key: string;
  EnvLibPathes: TStringList;
  FullLibPath: array[0..MAX_PATH - 1] of Char;
  LibItem: TFWMessageTableLibrary;
begin

  // ���� �������� ������� ��, �������� ������ ��������� ���� HInstance
  if Source = FSource then
  begin
    Result := GetCategoryStringFromModule(HInstance);
    Exit;
  end;

  // ����, �� ��������� �� � ��� ��� ������ ��������
  for I := 0 to MessageTableLibraryes.Count - 1 do
    if string(MessageTableLibraryes.Item[I].sLibName) = Source then
    begin
      // ���� ��������� - ���������� ��� ���������
      Result := GetCategoryStringFromModule(MessageTableLibraryes.Item[I].hLibHandle);
      if Result <> '' then
        Exit;
    end;

  // � ��������� ������, ������� ����� ���� � ��������� � �������
  with TRegistry.Create do
  try
    RootKey := HKEY_LOCAL_MACHINE;
    Key := ROOT_EVENTLOG_REGKEY + RegEventSources[SourceType] + '\' + Source;
    // �������, ���� �� ��������������� ������ ��������������� ���������?
    if KeyExists(Key) then
      if OpenKey(Key, False) then
      try
        // ����, ����������� ������ � ������������� ��������� �����������,
        // ���������� � ���� ������� ��������� � ������� �������
        EnvLibPath := ReadString(RegParam);
      finally
        CloseKey;
      end
      else
        // ������ ��� ������� ����� ������� Security �� ����������,
        // ������� ������� ������ ����������� ��������� �����
    if SourceType = esSecurity then
      EnvLibPath := '%SystemRoot%\System32\MsAuditE.dll;%SystemRoot%\System32\xpsp2res.dll';
  finally
    Free;
  end;

  if EnvLibPath = '' then
    Exit;
  EnvLibPathes := TStringList.Create;
  try
    // ��� ���� �������� � StringList
    EnvLibPathes.Text := StringReplace(EnvLibPath, ';', sLineBreak, [rfReplaceAll]);
    for I := 0 to EnvLibPathes.Count - 1 do
      if EnvLibPathes.Strings[I] <> '' then
      begin
        // � ���� ����� ���� ���������� ��������� - ��������������� ��
        // � ���������� ����
        ExpandEnvironmentStrings(PChar(EnvLibPathes.Strings[I]), @FullLibPath[0], MAX_PATH);
        LibItem.bLoaded := False;
        // �������, �������� �� ��� ������ ������?
        LibItem.hLibHandle := GetModuleHandle(PChar(@FullLibPath[0]));
        if LibItem.hLibHandle <= HINSTANCE_ERROR then
        begin
          LibItem.bLoaded := True;
          // �� �������� - ���������� ���
          LibItem.hLibHandle := LoadLibraryEx(PChar(@FullLibPath[0]), 0, LOAD_LIBRARY_AS_DATAFILE);
        end;
        if LibItem.hLibHandle > HINSTANCE_ERROR then
        begin
          // ���� ��������� �������, ��������� �������� ������ � �������
          LibItem.sLibName := ShortString(Source);
          Inc(MessageTableLibraryes.Count);
          SetLength(MessageTableLibraryes.Item, MessageTableLibraryes.Count);
          MessageTableLibraryes.Item[MessageTableLibraryes.Count - 1] := LibItem;
          // �������� ������
          Result := GetCategoryStringFromModule(LibItem.hLibHandle);
          if Result <> '' then
            Exit;
        end;
      end;
  finally
    EnvLibPathes.Free;
  end;
end;

//
//  ��������� �������, ������������ ��� ���������������� �������
// =============================================================================
procedure TFWEventLog.OnReadRecord(Sender: TObject; EventRecord: TFWEventLogRecord; var Stop: Boolean);
begin
  if Assigned(FOnReadRecordCallback) then
    FOnReadRecordCallback(Self, EventRecord, Stop);
end;

//
//  �������� ��������� ������� �� ������ ��� ������
// =============================================================================
function TFWEventLog.Open(const Source: TFWLocalEventSources; const State: TFSOpenState): Boolean;
begin
  Result := CustomOpen(Source, State);
end;

//
//  �������������� ��������� ��������� � ����������� ���
// =============================================================================
function TFWEventLog.ParseEventLogRecord(SourceType: TFWEventSources; const EventLogRecord: TEventLogRecord): TFWEventLogRecord;
var
  StrOffset: DWORD;
var
  Account, Domain: string;
  I: Integer;
  AStrings: TStringArray;
begin

  ZeroMemory(@Result, SizeOf(TFWEventLogRecord));
  Result.Number := EventLogRecord.RecordNumber;
  Result.EventID := Word(EventLogRecord.EventID and $FFFF);
  Result.EventType := GetRecordTypeFromWordType(EventLogRecord.EventType);
  if (SourceType = esSystem) and (Result.EventType = rtError) and (EventLogRecord.NumStrings > 0) then
  begin
    SetLength(AStrings, 0);
  end;
  StrOffset := OFFSET_SIZE;
  Result.SourceName := PChar(@EventLogRecord.DataOffset) + StrOffset;
  Result.Category := GetCategoryString(Result.SourceName, SourceType, EventLogRecord.EventCatagory);
  Inc(StrOffset, Length(Result.SourceName) + 1);
  Result.ComputerName := PChar(@EventLogRecord.DataOffset) + StrOffset;
  GetAccountAndDomainName(PSID(DWORD(@EventLogRecord) + EventLogRecord.UserSidOffset), Account, Domain);
  Result.Account := PChar(Account);
  Result.Domain := PChar(Domain);
  Result.TimeCreated := UCTToDateTime(EventLogRecord.TimeGenerated);
  Result.TimeWritten := UCTToDateTime(EventLogRecord.TimeWritted);

  if EventLogRecord.NumStrings > 0 then
  begin
    SetLength(AStrings, EventLogRecord.NumStrings);
    StrOffset := DWORD(@EventLogRecord) + EventLogRecord.StringOffset;
    for I := 0 to EventLogRecord.NumStrings - 1 do
    begin
      AStrings[I] := StrPas(PChar(StrOffset));
      //ShowMessage(AStrings[I]+'|'+IntToStr(Length(AStrings[I])));
      Inc(StrOffset, Length(AStrings[I]) * 2 + 2);
    end;
  end;

  // ������ ������:
  // EventID ������� ����� ��� WORD, �� ��� ������� ���������
  // ���������� ���������� ������ � ������ ��������������� DWORD
  // �������� EventLogRecord.EventID ����� 12345678,
  // ��� �������� ID � ������ ������ ����� 24910 (12345678 and $FFFF),
  // �� FormatMessage ����� �������� � �������� ��������������
  // ������ 12345678, � �� 24910

  Result.Description := GetEventString(Result.SourceName, SourceType, EventLogRecord.EventID, AStrings);

  Result.Description := StringReplace(Result.Description, #10, '', [rfReplaceAll]);
  Result.Description := StringReplace(Result.Description, #13, sLineBreak, [rfReplaceAll]);

  if EventLogRecord.DataLength > 0 then
  begin
    SetLength(Result.BinData, EventLogRecord.DataLength);
    StrOffset := (DWORD(@EventLogRecord) + EventLogRecord.DataOffset);
    Move(Pointer(StrOffset)^, Result.BinData[0], EventLogRecord.DataLength);
  end;
end;

//
//  �������������� ��������� ��� ��������������, ������� �� � ������
// =============================================================================
procedure TFWEventLog.PrepareParameters(List: TList; Parameters: TStringArray);
var
  I: Integer;
begin
  for I := 0 to Length(Parameters) - 1 do
    List.Add(PChar(Parameters[I]));
end;

//
//  ������ ������
//  ������ �������� ��������� ������ ����� ������������� ������
//  �� ������ ��� �� ���������� ����
//  ������ �������� - ����� ������
// =============================================================================
function TFWEventLog.Read(const Backup: Boolean; Index: DWORD; var EventRecord: TFWEventLogRecord): Boolean;
var
  EventHandle: THandle;
  SourceType: TFWLocalEventSources;
begin
  if Backup then
  begin
    EventHandle := FBackUpHandle;
    if not (osBackUp in OpenState) then
      raise EFWEventLog.Create(Format(ERR_WRONG_STATE, ['osBackUp']));
    SourceType := FBackupSourceType;
  end
  else
  begin
    EventHandle := FReadHandle;
    if not (osRead in OpenState) then
      raise EFWEventLog.Create(Format(ERR_WRONG_STATE, ['osRead']));
    SourceType := FReadSourceType;
  end;
  Result := CustomReadSeek(EventHandle, SourceType, Index, EventRecord);
end;

function TFWEventLog.Read(const Backup: Boolean; const Groups: Boolean; const Date: Word; const Filtered: Boolean; const EType: TFWEventLogRecordType; ListView: TListView): Boolean;
var
  EventHandle: THandle;
  SourceType: TFWLocalEventSources;
begin
  if Backup then
  begin
    EventHandle := FBackUpHandle;
    if not (osBackUp in OpenState) then
      raise EFWEventLog.Create(Format(ERR_WRONG_STATE, ['osBackUp']));
    SourceType := FBackupSourceType;
  end
  else
  begin
    EventHandle := FReadHandle;
    if not (osRead in OpenState) then
      raise EFWEventLog.Create(Format(ERR_WRONG_STATE, ['osRead']));
    SourceType := FReadSourceType;
  end;
  Result := CustomReadListView(EventHandle, SourceType, Groups, Date, Filtered, EType, ListView);
end;

//
//  ������ ���� �������
//  ������ �������� ��������� ������ ����� ������������� ������
//  �� ������ ��� �� ���������� ����
//  ������ �������� - ����������� ������
//  ������ �������� ��������� ���������, ���������� ��� ������ ������ ������
// =============================================================================
function TFWEventLog.Read(const Backup: Boolean; const Forwards: Boolean; CallbackEvent: TFWOnReadRecordEvent): Boolean;
var
  EventHandle: THandle;
  SourceType: TFWLocalEventSources;
begin
  if Backup then
  begin
    EventHandle := FBackUpHandle;
    if not (osBackUp in OpenState) then
      raise EFWEventLog.Create(Format(ERR_WRONG_STATE, ['osBackUp']));
    SourceType := FBackupSourceType;
  end
  else
  begin
    EventHandle := FReadHandle;
    if not (osRead in OpenState) then
      raise EFWEventLog.Create(Format(ERR_WRONG_STATE, ['osRead']));
    SourceType := FReadSourceType;
  end;
  Result := CustomReadSequential(EventHandle, SourceType, Forwards, CallbackEvent);
end;

//
//  ������ ���� �������
//  ������ �������� ��������� ������ ����� ������������� ������
//  �� ������ ��� �� ���������� ����
//  ������ �������� - ����������� ������
//  ������ �������� ��������� ��������� ������,
//  ���������� ��� ������ ������ ������
// =============================================================================
function TFWEventLog.Read(const Backup: Boolean; const Forwards: Boolean; lpfnCallback: TFWOnReadRecordCallback): Boolean;
begin
  FOnReadRecordCallback := lpfnCallback;
  try
    Result := Read(Backup, Forwards, OnReadRecord);
  finally
    FOnReadRecordCallback := nil;
  end;
end;

//
//  ������ ���������� ���� �������
//  ������ �������� ��������� ������ ����� ������������� ������
//  �� ������ ��� �� ���������� ����
//  ������ �������� - ����� ������ ����� ���������������, ���������� ��� ����������
// =============================================================================
function TFWEventLog.RecordCount(const Backup: Boolean; Oldest: Boolean): DWORD;
var
  EventHandle: THandle;
begin
  Result := 0;
  if Backup then
  begin
    if not (osBackUp in OpenState) then
      raise EFWEventLog.Create(Format(ERR_WRONG_STATE, ['osBackUp']));
    EventHandle := FBackUpHandle
  end
  else
  begin
    if not (osRead in OpenState) then
      raise EFWEventLog.Create(Format(ERR_WRONG_STATE, ['osRead']));
    EventHandle := FReadHandle;
  end;

  if Oldest then
    GetOldestEventLogRecord(EventHandle, Result)
  else
    GetNumberOfEventLogRecords(EventHandle, Result);
end;

//
//  ����������� ���������� � �������� ���������, ����������� ������� ���������
// =============================================================================
function TFWEventLog.RegisterApp(CategoryCount: Integer = 1): Boolean;
const
  TypeSupport = EVENTLOG_SUCCESS or EVENTLOG_ERROR_TYPE or EVENTLOG_WARNING_TYPE or EVENTLOG_INFORMATION_TYPE or EVENTLOG_AUDIT_SUCCESS or EVENTLOG_AUDIT_FAILURE;
begin
  Result := False;
  if not FIsAdmin then
  begin
    ShowMessage(ERR_REGISTER);
    Exit;
  end;
  try
    with TRegistry.Create do
    try
      RootKey := HKEY_LOCAL_MACHINE;
      if OpenKey(FRegisterKey, True) then
      try
        WriteString(STR_CATEGORY, ParamStr(0));
        WriteString(STR_EVENT, ParamStr(0));
        WriteInteger(STR_CATEGORY_COUNT, CategoryCount);
        WriteInteger(STR_TYPE, TypeSupport);
        Result := True;
      finally
        CloseKey;
      end;
    finally
      Free;
    end;
  except
    ShowMessage(ERR_REGISTER);
  end;
end;

//
//  ������ ������ ��������� �� ����������� � ������ �������
//  ������� � ��������� ����������
// =============================================================================
function TFWEventLog.RegisterChangeNotify(Event: TFWOnChangeEvent): Boolean;
begin
  if not (osRead in OpenState) then
    raise EFWEventLog.Create(Format(ERR_WRONG_STATE, ['osRead']));
  Result := (osNotify in FState);
  if Result then
    raise EFWEventLog.Create(ERR_DOUBLE_REGISTER);
  // �������� ����� ������������ �� ��� ������,
  // ������� ������ ������� � ������ ������
  FNotifyHandle := OpenEventLog(nil, PChar(RegEventSources[FReadSourceType]));
  FNotifySourceType := FReadSourceType;
  if FNotifyHandle = 0 then
    Exit;
  FErrorWnd := AllocateHWnd(WndProc);
  if FErrorWnd = 0 then
  begin
    DeRegisterChangeNotify;
    Exit;
  end;
  FNotifyThread := TFWNotifyThread.Create(True);
  FNotifyThread.EventLog := Self;
  FNotifyThread.FNotifyHandle := FNotifyHandle;
  FNotifyThread.FreeOnTerminate := True;
  FNotifyThread.FOnChangeEvent := Event;
  Include(FState, osNotify);
  FNotifyThread.Resume;
  Result := True;
end;

//
//  ������ ������ ��������� �� ����������� � ������ �������
//  ������� � ���������� ��������� ������
// =============================================================================
function TFWEventLog.RegisterChangeNotify(Callback: TFWOnChangeCallback): Boolean;
begin
  if not (osRead in OpenState) then
    raise EFWEventLog.Create(Format(ERR_WRONG_STATE, ['osRead']));
  Result := (osNotify in FState);
  if Result then
    raise EFWEventLog.Create(ERR_DOUBLE_REGISTER);
  // �������� ����� ������������ �� ��� ������,
  // ������� ������ ������� � ������ ������
  FNotifyHandle := OpenEventLog(nil, PChar(RegEventSources[FReadSourceType]));
  FNotifySourceType := FReadSourceType;
  if FNotifyHandle = 0 then
    Exit;
  FErrorWnd := AllocateHWnd(WndProc);
  if FErrorWnd = 0 then
  begin
    DeRegisterChangeNotify;
    Exit;
  end;
  FNotifyThread := TFWNotifyThread.Create(True);
  FNotifyThread.EventLog := Self;
  FNotifyThread.FNotifyHandle := FNotifyHandle;
  FNotifyThread.FreeOnTerminate := True;
  FNotifyThread.FOnChangeCallback := Callback;
  Include(FState, osNotify);
  FNotifyThread.Resume;
  Result := True;
end;

//
//  �������������� ������� �� Universal Coordinated Time � ����������� TDateTime
// =============================================================================
function TFWEventLog.UCTToDateTime(Value: DWORD): TDateTime;
const
  SecInDay = 60 * 60 * 24;
  SecInHour = 60 * 60;
  SecInMin = 60;
var
  Days, Hour, Min: DWORD;
  IntermediateData: TDateTime;
  SystemTime: TSystemTime;
  FileTime: TFileTime;
begin

  // MSDN:
  // This time is measured in the number of seconds
  // elapsed since 00:00:00 January 1, 1970, Universal Coordinated Time.

  Days := Value div SecInDay;
  Value := Value mod SecInDay;
  Hour := Value div SecInHour;
  Value := Value mod SecInHour;
  Min := Value div SecInMin;
  Value := Value mod SecInMin;
  IntermediateData := EncodeDate(1970, 1, 1) + Days + EncodeTime(Hour, Min, Value, 0);

  DateTimeToSystemTime(IntermediateData, SystemTime);
  SystemTimeToFileTime(SystemTime, FileTime);
  FileTimeToLocalFileTime(FileTime, FileTime);
  FileTimeToSystemTime(FileTime, SystemTime);
  Result := SystemTimeToDateTime(SystemTime);
end;

//
//  ������ � ��� ������� ����� ������
//  ������� � ���������� �������
// =============================================================================
function TFWEventLog.Write(RecType: TFWEventLogRecordType; Msg: string; RAWData: Pointer; RAWDataSize: Integer; Category: Word; EventID: Word): Boolean;
var
  lpMsg: PPChar;
begin
  if not (osWrite in OpenState) then
    raise EFWEventLog.Create(Format(ERR_WRONG_STATE, ['osWrite']));
  New(lpMsg);
  try
    lpMsg^ := PChar(Msg);
    Result := ReportEvent(FWriteHandle, GetWordTypeWromRecordType(RecType), Category, EventID, nil, 1, RAWDataSize, lpMsg, RAWData);
  finally
    Dispose(lpMsg);
  end;
end;

//
//  ������ � ��� ������� ����� ������
//  ������� ����� � ������ �������
// =============================================================================
function TFWEventLog.Write(RecType: TFWEventLogRecordType; Msg: string; Category: Word; EventID: Word): Boolean;
var
  lpMsg: PPChar;
begin
  if not (osWrite in OpenState) then
    raise EFWEventLog.Create(Format(ERR_WRONG_STATE, ['osWrite']));
  New(lpMsg);
  try
    lpMsg^ := PChar(Msg);
    Result := ReportEvent(FWriteHandle, GetWordTypeWromRecordType(RecType), Category, EventID, nil, 1, 0, lpMsg, nil);
  finally
    Dispose(lpMsg);
  end;
end;

//
//  ������� ���������, ���������� ��� ��������� ����������� �� ������ � ������
// =============================================================================
procedure TFWEventLog.WndProc(var Message: TMessage);
begin
  case Message.Msg of
    WM_THREAD_ERROR:
      if Integer(Message.WParam) = Integer(FErrorWnd) then
      begin
        DeRegisterChangeNotify;
        raise EFWEventLog.Create(Format(ERR_NOTIFY_THREAD, [Error, SysErrorMessage(Error)]));
      end;
  end;
end;

end.

