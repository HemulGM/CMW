////////////////////////////////////////////////////////////////////////////////
//
//  ****************************************************************************
//  * Unit Name : FWEventLog.pas
//  * Purpose   : Класс работающий с системным логом
//  * Author    : Александр (Rouse_) Багель
//  * Copyright : © Fangorn Wizards Lab 1998 - 2006 (Москва)
//  * Version   : 1.00
//  * HomePage  : http://rouse.front.ru
//  ****************************************************************************
//

unit FWEventLog;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Dialogs,
  Classes,
  Registry,
  ComCtrls;

type
  // Типы событий, вынес в виде перечислимого типа для удобства
  TFWEventLogRecordType = (rtSuccess, rtError, rtWarning, rtInformation, rtAuditSuccess, rtAuditFailed);

  // Типы открытих описатилей в классе
  TFSOpenState = (osRead, osWrite, osBackUp, osNotify);
  TFSOpenStates = set of TFSOpenState;

  // Типы веток системного лога
  TFWEventSources = (esUnknown, esApplication, esSecurity, esSystem, esBackup);
  TFWLocalEventSources = esApplication..esSystem;

  TStringArray = array of String;

  // Работа с отображением записей будет вестись посредством данной структуры
  TFWEventLogRecord = packed record
    Number        : DWORD;         // Абсолютный номер записи в списке
    EventID       : DWORD;         // ID события
    EventType     : TFWEventLogRecordType; // тип собычтия
    Category      : String;        // Категория
    SourceName    : String;        // источник
    ComputerName  : String;        // Имя компьютера
    Account       : String;        // Аккаунт
    Domain        : String;        // Домен
    TimeCreated   : TDateTime;     // Время создания
    TimeWritten   : TDateTime;     // Время добавления
    Description   : String;        // Описание
    BinData       : array of Byte; // Бинарные данные
  end;

  //ВНИМАНИЕ !!!
  // Полное строковое представление категории и описания,
  // из выше описанной структуры можно получить только при условии,
  // что приложение, заявленное как Источник, зарегестрированно
  // в системном реестре, т.е. выполненно TFWEventLog.RegisterApp()


  // Структуры для хранения описателей загруженных библиотек (приложений),
  // которые были заявленны как источники записей
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
  { Выдержка из MSDN

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

  // Декларации из WINNT.H

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

  // Различные собития класса
  // Разбиты на использование как объектных процедур, так и обычных калбэков
  TFWOnReadRecordEvent = procedure(Sender: TObject; EventRecord: TFWEventLogRecord; var Stop: Boolean) of object;
  TFWOnReadRecordCallback = procedure(Sender: TObject; EventRecord: TFWEventLogRecord; var Stop: Boolean);
  TFWOnChangeEvent = procedure(Sender: TObject; EventRecord: TFWEventLogRecord) of object;
  TFWOnChangeCallback = procedure(Sender: TObject; EventRecord: TFWEventLogRecord);

  TFWEventLog = class;

  // Поток, следящий за уведомлении о изменении лога
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
    // 4 различных описателя, позволяющие работать с логом в нескольких режимах
    FReadHandle,              // чтение
                              // Используется для чтения записей,
                              // получения кол-ва записей,
                              // создания файла бэкапа,
                              // очистки записей

    FWriteHandle,             // запись
                              // используется только для добавления записей

    FBackUpHandle,            // работа с бэкапом
                              // Используется для чтения записей из открытого файла,
                              // и получения кол-ва записей ф этом файле

    FNotifyHandle: THandle;   // хэндл изпользуемый для реализации нотификаций
                              // Помимо самих нотификаций используется для
                              // получения интекса текущей записи и
                              // чтения данной записи

    FSource,
    FRegisterKey: String;
    FReadSourceType,
    FWriteSourceType,
    FBackupSourceType,
    FNotifySourceType: TFWEventSources;
    FIsAdmin: Boolean;
    FState: TFSOpenStates;
    MessageTableLibraryes: TFWMessageTableLibraryes;
    FNotifyThread: TFWNotifyThread;
    FErrorWnd: HWND;
    FOnReadRecordCallback: TFWOnReadRecordCallback;
  protected
    procedure OnReadRecord(Sender: TObject;
      EventRecord: TFWEventLogRecord; var Stop: Boolean);
    procedure WndProc(var Message: TMessage); virtual;
    property ErrorWnd: HWND read FErrorWnd;
  protected
    function CustomOpen(const Source: TFWEventSources;
      const State: TFSOpenState; Backup: String = ''): Boolean;
    function CustomReadSequential(EventHandle: THandle;
      SourceType: TFWEventSources; const Forwards: Boolean;
      CallbackEvent: TFWOnReadRecordEvent): Boolean;
    function CustomReadListView(EventHandle: THandle;
      SourceType: TFWEventSources; const Groups: Boolean; const NeedDate:Word;
      const Filtered:Boolean; const EType:TFWEventLogRecordType;
      ListView:TListView): Boolean;
    function CustomReadSeek(EventHandle: THandle;
      SourceType: TFWEventSources; Index: DWORD;
      var EventRecord: TFWEventLogRecord): Boolean;
    procedure GetAccountAndDomainName(const SID: PSID;
      var Account, Domain: String);
    function GetCategoryString(Source: String;
      SourceType: TFWEventSources; CategoryID: DWORD): String;
    function GetEventString(Source: String; SourceType: TFWEventSources; 
      EventID: DWORD; Parameters: TStringArray): String;
    function GetWordTypeWromRecordType
      (const RecType: TFWEventLogRecordType): Word;
    function GetRecordTypeFromWordType(
      const WordType: Word): TFWEventLogRecordType;
    function IsAdmin: Boolean;
    function LoadStringFromMessageTable(Source, RegParam: String;
      SourceType: TFWEventSources; ID: DWORD; Parameters: Pointer): String;
    function ParseEventLogRecord(SourceType: TFWEventSources; 
      const EventLogRecord: TEventLogRecord): TFWEventLogRecord;
    procedure PrepareParameters(List: TList; Parameters: TStringArray);
    function UCTToDateTime(Value: DWORD): TDateTime;
  public
    constructor Create(const Source: String);
    destructor Destroy; override;

    function BackupOpen(FilePath: String;
      const Source: TFWLocalEventSources): Boolean;
    function CreateBackup(FilePath: String): Boolean;
    function Clear(BackupPath: String = ''): Boolean;
    procedure Close(const State: TFSOpenState);
    function DeregisterApp: Boolean;
    procedure DeRegisterChangeNotify;
    class function EventTypeToString(
      const EventType: TFWEventLogRecordType): String;
    function IsEventLogFull: Boolean;
    function IsRegistered: Boolean;
    function Open(const Source: TFWLocalEventSources;
      const State: TFSOpenState): Boolean;
    function Read(const Backup: Boolean; Index: DWORD;
      var EventRecord: TFWEventLogRecord): Boolean; overload;
    function Read(const Backup: Boolean; const Forwards: Boolean;
      CallbackEvent: TFWOnReadRecordEvent): Boolean; overload;
    function Read(const Backup: Boolean;
                          const Groups: Boolean;
                          const Date:Word;
                          const Filtered:Boolean;
                          const EType:TFWEventLogRecordType;
                          ListView:TListView): Boolean; overload;
    function Read(const Backup: Boolean; const Forwards: Boolean;
      lpfnCallback: TFWOnReadRecordCallback): Boolean; overload;
    function RecordCount(const Backup: Boolean; Oldest: Boolean = False): DWORD;
    function RegisterApp(CategoryCount: Integer = 1): Boolean;
    function RegisterChangeNotify(Event: TFWOnChangeEvent): Boolean; overload;
    function RegisterChangeNotify(Callback: TFWOnChangeCallback): Boolean; overload;
    function Write(RecType: TFWEventLogRecordType; Msg: String;
      RAWData: Pointer; RAWDataSize: Integer;
      Category: Word = 1; EventID: Word = 0): Boolean; overload;
    function Write(RecType: TFWEventLogRecordType;
      Msg: String; Category: Word = 1; EventID: Word = 0): Boolean; overload;
    property OpenState: TFSOpenStates read FState;
    property SourceName: String read FSource;
    property ReadSourceType: TFWEventSources read FReadSourceType;
    property WriteSourceType: TFWEventSources read FWriteSourceType;
    property BackupSourceType: TFWEventSources read FBackupSourceType;
  end;

  EFWEventLog = class(Exception);

  function EventTypeToStr(EventType: Word): String;

const
  RegEventSources: array [TFWEventSources] of String = ('', 'Application', 'Security', 'System', '');

implementation
 uses Main, COCUtils;

const
  // Константы из WINNT.H

  // The types of events that can be logged.
  EVENTLOG_SUCCESS          = $0000;
  EVENTLOG_ERROR_TYPE       = $0001;
  EVENTLOG_WARNING_TYPE     = $0002;
  EVENTLOG_INFORMATION_TYPE = $0004;
  EVENTLOG_AUDIT_SUCCESS    = $0008;
  EVENTLOG_AUDIT_FAILURE    = $0010;

  // Defines for the READ flags for Eventlogging
  EVENTLOG_SEQUENTIAL_READ  = $0001;
  EVENTLOG_SEEK_READ        = $0002;
  EVENTLOG_FORWARDS_READ    = $0004;
  EVENTLOG_BACKWARDS_READ   = $0008;

resourcestring

  ROOT_EVENTLOG_REGKEY = 'SYSTEM\CurrentControlSet\Services\EventLog\';
  STR_CATEGORY = 'CategoryMessageFile';
  STR_EVENT = 'EventMessageFile';
  STR_CATEGORY_COUNT = 'CategoryCount';
  STR_TYPE = 'TypesSupported';

  ERR_NOADMIN =
    'Для регистрации приложения в менеджере событий,' +
    ' программа должна быть запущена из под учетной записи администратора.';
  ERR_REGISTER =
    'Невозможно зарегистрировать приложение в менеджере событий.';
  ERR_WRONG_STATE =
    'Операция не может быть успешно выполненна в данный момент.' + sLineBreak +
    'Для выполнения операции менеджер событий должен быть открыт в режиме "%s"';
  ERR_RESLIB_NOT_FOUND =
    'Не найдено описание для события с кодом ( %d ) в источнике ( %s ). ' +
    'Возможно, на локальном компьютере нет нужных данных в реестре ' +
    'или файлов DLL сообщений для отображения сообщений удаленного компьютера. ' +
    'В записи события содержится следующая информация: %s';
  ERR_CALLBACK_NOT_FOUND = 'Не задана функция обратного вызова.';
  ERR_UNSAFE_OPERATION = 'Для выполнения операций в режиме osNotify, ' +
    'используйте методы RegisterChangeNotify/DeRegisterChangeNotify.';
  ERR_DOUBLE_REGISTER = 'Для выполнения повторной регистрации на событие ' +
    'оповещения, необходимо снять предыдущую регистрацию ' +
    'при помощи DeRegisterChangeNotify.';
  ERR_NOTIFY_THREAD =
    'Ошибка потока ожидания оповещений. Код ошибки %d, описание "%s"';
  ERR_TYPE_CONV = 'Ошибка преобразования типов';
  ERR_DOUBLE_OPEN = 'Менеджер событий уже открыт в данном режиме %s.';

const
  OFFSET_SIZE = SizeOf(DWORD) - 2;
  WM_THREAD_ERROR = WM_USER;

function EventTypeToStr(EventType: Word): String;
begin
 Case EventType of
  EVENTLOG_SUCCESS          : Result := 'Успех';
  EVENTLOG_ERROR_TYPE       : Result := 'Ошибка';
  EVENTLOG_WARNING_TYPE     : Result := 'Предупреждение';
  EVENTLOG_INFORMATION_TYPE : Result := 'Информация';
  EVENTLOG_AUDIT_SUCCESS    : Result := 'Успех аудита';
  EVENTLOG_AUDIT_FAILURE    : Result := 'Отказ аудита';
 else Result := 'Неизвестно';
 end;
end;

{ TFWNotifyThread }

//
//  Цикл ожидания уведомлений
// =============================================================================
procedure TFWNotifyThread.Execute;
var
  hEvent: THandle;
begin
  // Создаем эвент, состояние которого будет измененно при изменении лога
  hEvent := CreateEvent(nil, False, False, nil);
  try
    // Подписываемся на уведомления
    NotifyChangeEventLog(FNotifyHandle, hEvent);
    while not Terminated do
    begin
      // Ожидание уведомления
      case WaitForSingleObject(hEvent, 100) of
        WAIT_OBJECT_0:
          // Лог изменился
          Synchronize(OnChange);
        WAIT_FAILED:
        begin
          // произошла ошибка
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
//  Нотификация класса о изменении
// =============================================================================
procedure TFWNotifyThread.OnChange;
var
  EventRecord: TFWEventLogRecord;
  RecordIndex, Oldest: DWORD;
begin
  // Получаем индекс последней записи в логе
  GetNumberOfEventLogRecords(EventLog.FNotifyHandle, RecordIndex);
  GetOldestEventLogRecord(EventLog.FNotifyHandle, Oldest);
  Inc(RecordIndex, Oldest - 1);
  // Читаем данную запись
  if EventLog.CustomReadSeek(EventLog.FNotifyHandle,
    EventLog.FNotifySourceType, RecordIndex, EventRecord)
  then
  begin
    // Поднимаем событие о новой записи
    if Assigned(FOnChangeEvent) then
      FOnChangeEvent(EventLog, EventRecord)
    else
      if Assigned(FOnChangeCallback) then
        FOnChangeCallback(EventLog, EventRecord);
  end
  else
    OnError;
end;

//
//  Потоковый обработчик ошибок :)
// =============================================================================
procedure TFWNotifyThread.OnError;
begin
  // т.к. вызов происходит через Synchronize,
  // райзиться здесь не имеет смысла, потомучто сам
  // Synchronize обернут в SEH.
  // Посему асинхронно отправляем сообщение нашему классу,
  // и он уже у себя поднимет исключение
  PostMessage(EventLog.ErrorWnd, WM_THREAD_ERROR,
    EventLog.ErrorWnd, GetLastError);
end;

{ TFWEventLog }

//
//  Открытия файла бэкапа
// =============================================================================
function TFWEventLog.BackupOpen(FilePath: String;
  const Source: TFWLocalEventSources): Boolean;
begin
  Result := CustomOpen(Source, osBackUp, FilePath);
end;

//
//  Очистка списка событий
//  В качестве необязательного параметра указывается путь к файлу,
//  в который будут помещены все удаленные события.
//  Для успешного выполнения, менеджер событий должен быть открыт на чтение
// =============================================================================
function TFWEventLog.Clear(BackupPath: String): Boolean;
begin
  if not (osRead in OpenState) then
    raise EFWEventLog.Create(Format(ERR_WRONG_STATE, ['osRead']));
  Result := ClearEventLog(FReadHandle, PChar(BackupPath));
end;

//
//  Закрытие описателей
// =============================================================================
procedure TFWEventLog.Close(const State: TFSOpenState);
var
  I: Integer;
begin
  if not (State in FState) then Exit;
  case State of
    osRead: // Закрытие описателя на чтение
    begin
      CloseEventLog(FReadHandle);
      FReadHandle := 0;
      // Выгружаем все ранее подгруженные библиотеки
      for I := 0 to MessageTableLibraryes.Count - 1 do
      begin
        MessageTableLibraryes.Item[I].sLibName := '';
        if MessageTableLibraryes.Item[I].bLoaded then
          FreeLibrary(MessageTableLibraryes.Item[I].hLibHandle);
      end;
      MessageTableLibraryes.Count := 0;
      SetLength(MessageTableLibraryes.Item, 0);
    end;
    osWrite: // Закрытие описателя на запись
    begin
      DeregisterEventSource(FWriteHandle);
      FWriteHandle := 0;
    end;
    osBackUp: // Закрытие описателя работы с файлом бэкапа
    begin
      CloseEventLog(FBackUpHandle);
      FBackUpHandle := 0;
      // Если не используется режим  чтения,
      // выгружаем все ранее подгруженные библиотеки
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
//  Инициализация
// =============================================================================
constructor TFWEventLog.Create(const Source: String);
begin
  FSource := Source;
  FRegisterKey := ROOT_EVENTLOG_REGKEY +
    RegEventSources[esApplication] + '\' + Source;
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
//  Создание бэкапа текущей открытой ветви лога событий
//  Для успешного выполнения, менеджер событий должен быть открыт на чтение 
// =============================================================================
function TFWEventLog.CreateBackUp(FilePath: String): Boolean;
begin
  if not (osRead in OpenState) then
    raise EFWEventLog.Create(Format(ERR_WRONG_STATE, ['osRead']));
  Result := BackupEventLog(FReadHandle, PChar(FilePath));
end;

//
//  Чтение записи по ее индексу
//  Для успешного выполнения, менеджер событий должен быть открыт на чтение
// =============================================================================
function TFWEventLog.CustomOpen(const Source: TFWEventSources;
  const State: TFSOpenState; Backup: String): Boolean;
const
  States: array [TFSOpenState] of String = ('osRead', 'osWrite', 'osBackUp', '');
begin
  Result := False;
  if (State in FState) then
    raise EFWEventLog.Create(Format(ERR_DOUBLE_OPEN, [States[State]]));
  case State of
    osRead:
    begin
      FReadHandle := OpenEventLog(nil, PChar(RegEventSources[Source]));
      if FReadHandle = 0 then Exit;
      FReadSourceType := Source;
    end;
    osWrite:
    begin
      FWriteHandle := RegisterEventSource(nil, PChar(FSource));
      if FWriteHandle = 0 then Exit;
      FWriteSourceType := Source;
    end;
    osBackUp:
    begin
      FBackUpHandle := OpenBackupEventLog(nil, PChar(Backup));
      if FBackUpHandle = 0 then Exit;
      FBackupSourceType := Source;
    end;
  else
    raise EFWEventLog.Create(ERR_UNSAFE_OPERATION);
  end;
  Result := True;
  Include(FState, State);
end;

//
//  Чтение записи по ее индексу
//  Для успешного выполнения, менеджер событий должен быть открыт на чтение
// =============================================================================
function TFWEventLog.CustomReadSeek(EventHandle: THandle; SourceType: TFWEventSources; Index: DWORD;
  var EventRecord: TFWEventLogRecord): Boolean;
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
  // Выделяем память под пустую структуру
  GetMem(lpBuffer, NumberOfBytesToRead);
  try
    MinNumberOfBytesNeeded := 0;
    BytesRead := 0;
    // Узнаем, сколько памяти требуется под заполненныую структуру
    ReadEventLog(EventHandle, SeekFlags, Index, lpBuffer,
      NumberOfBytesToRead, BytesRead, MinNumberOfBytesNeeded);
    dwError := GetLastError;
    if dwError = ERROR_INSUFFICIENT_BUFFER then
    begin
      NumberOfBytesToRead := MinNumberOfBytesNeeded;
      // Выделяем необходимый объем памяти
      ReallocMem(lpBuffer, MinNumberOfBytesNeeded);
      // Получаем запись
      Result := ReadEventLog(EventHandle, SeekFlags, Index, lpBuffer,
        NumberOfBytesToRead, BytesRead, MinNumberOfBytesNeeded);
      if Result then
        // Преобразуем запись в читабельный вид
        EventRecord := ParseEventLogRecord(SourceType, lpBuffer^);
    end;
  finally
    FreeMem(lpBuffer);
  end;
end;

//
//  Чтение записей по порядку
//  В качестве функции обратного вызова используется объектная процедура
//  Для успешного выполнения, менеджер событий должен быть открыт на чтение
// =============================================================================
function TFWEventLog.CustomReadSequential(EventHandle: THandle; SourceType: TFWEventSources; const Forwards: Boolean;
  CallbackEvent: TFWOnReadRecordEvent): Boolean;
var
  lpBuffer, OutputBuffer: PEventLogRecord;
  NumberOfBytesToRead, OldestNumberRecordCount, NumberRecordCount: DWORD;
  BytesRead, MinNumberOfBytesNeeded, SeekFlags, SeekIndex, BytesLeft: DWORD;
  Data: TFWEventLogRecord;
  Stop, FirstCall: Boolean;
begin
  Result := False;

  // Проверяем наличие процедуры обратного вызова
  if not Assigned(CallbackEvent) then
    raise EFWEventLog.Create(ERR_CALLBACK_NOT_FOUND);

  // Получаем кол-во записей в логе
  if not GetNumberOfEventLogRecords(EventHandle,
    NumberRecordCount) then Exit;

  // Получаем кол-во устаревших записей в логе
  if not GetOldestEventLogRecord(EventHandle,
    OldestNumberRecordCount) then Exit;

  // Смотрим требуемое направление чтения
  FirstCall := True;
  if Forwards then
  begin
    // Читаем с первой по последнюю
    SeekFlags := EVENTLOG_SEEK_READ or EVENTLOG_FORWARDS_READ;
    // Устанавливаем индекс начальной записи (первая)
    SeekIndex := OldestNumberRecordCount;
  end
  else
  begin
    // Читаем с последней по первую
    SeekFlags := EVENTLOG_SEEK_READ or EVENTLOG_BACKWARDS_READ;
    // Устанавливаем индекс начальной записи (последняя)
    SeekIndex := OldestNumberRecordCount + NumberRecordCount - 1;
  end;

  lpBuffer := nil;
  NumberOfBytesToRead := SizeOf(TEventLogRecord);
  MinNumberOfBytesNeeded := 0;
  BytesRead := 0;
  // Выделяем память под пустую структуру
  GetMem(lpBuffer, NumberOfBytesToRead);
  try
    repeat
      // Попытка получить запись
      Result := ReadEventLog(EventHandle, SeekFlags, SeekIndex,
        lpBuffer, NumberOfBytesToRead, BytesRead, MinNumberOfBytesNeeded);

      if not Result then
        case GetLastError of
          ERROR_INSUFFICIENT_BUFFER:
          begin
            // Попытка неуспешна, но нам известно,
            // сколько памяти требуется под заполненныую структуру
            NumberOfBytesToRead := MinNumberOfBytesNeeded;
            // Выделяем необходимый объем памяти
            ReallocMem(lpBuffer, MinNumberOfBytesNeeded);
            // Получаем запись
            Result := ReadEventLog(EventHandle, SeekFlags,
              SeekIndex, lpBuffer, NumberOfBytesToRead,
              BytesRead, MinNumberOfBytesNeeded);
          end;
          ERROR_HANDLE_EOF:
          begin
            Result := True;
            Exit;
          end
        else
          Result := False;
        end;

      // Самый первый вызов происходи с флагом  EVENTLOG_SEEK_READ
      // Это необходимо для позиционирования курсора на необходимую запись
      // Все дальнейшие вызовы проиходят с флагом EVENTLOG_SEQUENTIAL_READ
      // (последовательное чтение)
      if FirstCall then
      begin
        FirstCall := False;
        SeekFlags := (SeekFlags or EVENTLOG_SEQUENTIAL_READ)
          and not EVENTLOG_SEEK_READ;
        SeekIndex := 0;
      end;

      if Result then
      // Запись прочитана успешно
      begin
        // Тут тонкий момент
        // Функция ReadEventLog помещает в выделенный буффер
        // столько записей, сколько туда может поместиться целиком.
        // Поэтому нужно проверять наличие нескольких записей ориентируясь
        // на размер выделенного буффера и длину текущей записи,
        // вычитая из первого второе и проверяя оставшийся размер.
        BytesLeft := BytesRead;
        OutputBuffer := lpBuffer;
        repeat
          Data := ParseEventLogRecord(SourceType, OutputBuffer^);
          Dec(BytesLeft, OutputBuffer^.Length);
          OutputBuffer := Pointer(DWORD(OutputBuffer) + OutputBuffer^.Length);
          CallbackEvent(Self, Data, Stop);
          if Stop then Exit;
        until BytesLeft <= 0;
      end;

    until not Result;
  finally
    FreeMem(lpBuffer);
  end;
end;

//
//  Чтение записей в ListView
//  Для успешного выполнения, менеджер событий должен быть открыт на чтение
// =============================================================================
function TFWEventLog.CustomReadListView(EventHandle: THandle;
      SourceType: TFWEventSources; const Groups: Boolean; const NeedDate:Word;
      const Filtered:Boolean; const EType:TFWEventLogRecordType;
      ListView:TListView): Boolean;
var
  lpBuffer, OutputBuffer: PEventLogRecord;
  NumberOfBytesToRead, OldestNumberRecordCount, NumberRecordCount: DWORD;
  BytesRead, MinNumberOfBytesNeeded, SeekFlags, SeekIndex, BytesLeft: DWORD;
  Data: TFWEventLogRecord;
  FirstCall: Boolean;
  LI:TListItem;
  DInt:PDWORD;
  Roll:TRegistry;
  RegOK:Boolean;
begin
  Result := False;

  // Проверяем наличие процедуры обратного вызова
  if not Assigned(ListView) then
    raise EFWEventLog.Create(ERR_CALLBACK_NOT_FOUND);

  // Получаем кол-во записей в логе
  if not GetNumberOfEventLogRecords(EventHandle,
    NumberRecordCount) then Exit;

  // Получаем кол-во устаревших записей в логе
  if not GetOldestEventLogRecord(EventHandle,
    OldestNumberRecordCount) then Exit;

  Roll:=TRegistry.Create(KEY_READ);
  Roll.RootKey:=HKEY_LOCAL_MACHINE;

  // Смотрим требуемое направление чтения
  FirstCall := True;

  // Читаем с первой по последнюю
  SeekFlags := EVENTLOG_SEEK_READ or EVENTLOG_FORWARDS_READ;
  // Устанавливаем индекс начальной записи (первая)
  SeekIndex := OldestNumberRecordCount;

  lpBuffer := nil;
  NumberOfBytesToRead := SizeOf(TEventLogRecord);
  MinNumberOfBytesNeeded := 0;
  BytesRead := 0;
  // Выделяем память под пустую структуру
  GetMem(lpBuffer, NumberOfBytesToRead);
  try
    repeat
      // Попытка получить запись
      Result := ReadEventLog(EventHandle, SeekFlags, SeekIndex,
        lpBuffer, NumberOfBytesToRead, BytesRead, MinNumberOfBytesNeeded);

      if not Result then
        case GetLastError of
          ERROR_INSUFFICIENT_BUFFER:
          begin
            // Попытка неуспешна, но нам известно,
            // сколько памяти требуется под заполненныую структуру
            NumberOfBytesToRead := MinNumberOfBytesNeeded;
            // Выделяем необходимый объем памяти
            ReallocMem(lpBuffer, MinNumberOfBytesNeeded);
            // Получаем запись
            Result := ReadEventLog(EventHandle, SeekFlags,
              SeekIndex, lpBuffer, NumberOfBytesToRead,
              BytesRead, MinNumberOfBytesNeeded);
          end;
          ERROR_HANDLE_EOF:
          begin
            Result := True;
            Exit;
          end
        else
          Result := False;
        end;

      // Самый первый вызов происходи с флагом  EVENTLOG_SEEK_READ
      // Это необходимо для позиционирования курсора на необходимую запись
      // Все дальнейшие вызовы проиходят с флагом EVENTLOG_SEQUENTIAL_READ
      // (последовательное чтение)
      if FirstCall then
      begin
        FirstCall := False;
        SeekFlags := (SeekFlags or EVENTLOG_SEQUENTIAL_READ)
          and not EVENTLOG_SEEK_READ;
        SeekIndex := 0;
      end;

      if Result then
      // Запись прочитана успешно
      begin
        // Тут тонкий момент
        // Функция ReadEventLog помещает в выделенный буффер
        // столько записей, сколько туда может поместиться целиком.
        // Поэтому нужно проверять наличие нескольких записей ориентируясь
        // на размер выделенного буффера и длину текущей записи,
        // вычитая из первого второе и проверяя оставшийся размер.
        BytesLeft := BytesRead;
        OutputBuffer := lpBuffer;
        repeat
          if Stopping then Break;
          Data := ParseEventLogRecord(SourceType, OutputBuffer^);
          Dec(BytesLeft, OutputBuffer^.Length);
          OutputBuffer := Pointer(DWORD(OutputBuffer) + OutputBuffer^.Length);
          if NeedDate > 0 then
           if Data.TimeCreated + NeedDate < Now then Continue;
          {if Filtered then
           if not CheckEventSel(Data.SourceName) then Continue;    }
          if Data.EventType = EType then
           begin
            with ListView.Items do
             begin
              LI:=Add;
              case Data.EventType of
               rtError:LI.StateIndex:=3;
               rtWarning:LI.StateIndex:=2;
               rtInformation:LI.StateIndex:=1;
               rtSuccess:LI.StateIndex:=7;
               rtAuditSuccess:LI.StateIndex:=7;
               rtAuditFailed:LI.StateIndex:=8;
              else LI.StateIndex:=1;
              end;
              case SourceType of
                esUnknown: LI.ImageIndex:=0;
                esApplication: LI.ImageIndex:=5;
                esSecurity: LI.ImageIndex:=4;
                esSystem: LI.ImageIndex:=6;
                esBackup: LI.ImageIndex:=0;
              else LI.ImageIndex:=0;
              end;

              DInt:=AllocMem(SizeOf(Data.Number));
              DInt^:=Data.Number;
              LI.Data:=DInt;
              LI.Caption:=DateTimeToStr(Data.TimeWritten); //
              LI.SubItems.Add(Data.SourceName);
              LI.SubItems.Add(Data.Category);
              LI.SubItems.Add(IntToStr(Data.EventID));
              if Data.Account = '' then LI.SubItems.Add('Н/Д') else
               LI.SubItems.Add(Data.Account);
              LI.SubItems.Add(Data.ComputerName);
              LI.SubItems.Add('');
              if SourceType in [esSystem, esApplication, esSecurity]  then
               begin
                Roll.CloseKey;
                if SourceType = esSystem then RegOK:=Roll.OpenKeyReadOnly('SYSTEM\CurrentControlSet\services\eventlog\System\'+Data.SourceName);
                if SourceType = esApplication then RegOK:=Roll.OpenKeyReadOnly('SYSTEM\CurrentControlSet\services\eventlog\Application\'+Data.SourceName);
                if SourceType = esSecurity then RegOK:=Roll.OpenKeyReadOnly('SYSTEM\CurrentControlSet\services\eventlog\Security\'+Data.SourceName);
                if RegOK then
                 begin
                  if Roll.ValueExists('EventMessageFile') then
                   LI.SubItems[5]:=Roll.GetDataAsString('EventMessageFile', False)
                  else
                  if Roll.ValueExists('providerGuid') then
                   LI.SubItems[5]:=Roll.GetDataAsString('providerGuid', False);
                 end;
               end;

              if Groups then LI.GroupID:=GetGroup(ListView, Data.SourceName, False)
              else LI.GroupID:=-1;
             end;
           end;
          //Stop:=Stopping;
          //CallbackEvent(Self, Data, Stop);
        until BytesLeft <= 0;
      end;
     if Stopping then Break;
    until not Result;
  finally
    FreeMem(lpBuffer);
  end;
end;

//
//  Снятие приложения с регистрации в качестве источника таблицы сообщений,
//  путем удаления соответствующей записи в реестре
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
//  Завершение потока следящего за изменением таблицы событий
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
//  Финализация
// =============================================================================
destructor TFWEventLog.Destroy;
var
  I: TFSOpenState;
begin
  for I := osRead to osBackUp do
    if I in FState then Close(I);
  DeRegisterChangeNotify;
  inherited;
end;

//
//  Вспомогательная функция
// =============================================================================
class function TFWEventLog.EventTypeToString(const EventType: TFWEventLogRecordType): String;
begin
  case EventType of
    rtSuccess, rtInformation: Result := 'Уведомление';
    rtError: Result := 'Ошибка';
    rtWarning: Result := 'Предупреждение';
    rtAuditSuccess: Result := 'Аудит успехов';
    rtAuditFailed: Result := 'Аудит отказов';
  end;
end;

//
//  Извлечение наименования аккаунта и домена из переданного
//  дескриптора безопасности
// =============================================================================
procedure TFWEventLog.GetAccountAndDomainName(const SID: PSID; var Account, Domain: String);
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
  Assert(SID <> nil, 'SID пустой');
  LookupAccountSid(nil, SID, @Account[1], cbName,
    @Domain[1], cbReferencedDomainName, peUse);
end;

//
//  Попытка получения строкового описания категории из ее идентификатора
// =============================================================================
function TFWEventLog.GetCategoryString(Source: String; SourceType: TFWEventSources; CategoryID: DWORD): String;
begin
  Result := LoadStringFromMessageTable(Source, STR_CATEGORY, SourceType,
    Word(CategoryID), nil);
  if Result = '' then
    Result := 'Отсутствует';
end;

//
//  Попытка получения строкового описания события из его идентификатора
// =============================================================================
function TFWEventLog.GetEventString(Source: String; SourceType: TFWEventSources; EventID: DWORD;
  Parameters: TStringArray): String;
var
  List: TList;
  Msg: String;
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
    Result := Format(ERR_RESLIB_NOT_FOUND,
      [Word(EventID), Source, PChar(Msg)]);
  end;
end;

//
//  Преобразование типа записи в формат компонента
// =============================================================================
function TFWEventLog.GetRecordTypeFromWordType(const WordType: Word): TFWEventLogRecordType;
begin
  case WordType of
    EVENTLOG_SUCCESS: Result := rtSuccess;
    EVENTLOG_ERROR_TYPE: Result := rtError;
    EVENTLOG_WARNING_TYPE: Result := rtWarning;
    EVENTLOG_INFORMATION_TYPE: Result := rtInformation;
    EVENTLOG_AUDIT_SUCCESS: Result := rtAuditSuccess;
    EVENTLOG_AUDIT_FAILURE: Result := rtAuditFailed;
  else
    raise EFWEventLog.Create(ERR_TYPE_CONV);
  end;
end;

//
//  Преобразование типа записи в формат необходимый АПИ
// =============================================================================
function TFWEventLog.GetWordTypeWromRecordType(const RecType: TFWEventLogRecordType): Word;
begin
  case RecType of
    rtSuccess       : Result := EVENTLOG_SUCCESS;
    rtError         : Result := EVENTLOG_ERROR_TYPE;
    rtWarning       : Result := EVENTLOG_WARNING_TYPE;
    rtInformation   : Result := EVENTLOG_INFORMATION_TYPE;
    rtAuditSuccess  : Result := EVENTLOG_AUDIT_SUCCESS;
    rtAuditFailed   : Result := EVENTLOG_AUDIT_FAILURE;
  else
    raise EFWEventLog.Create(ERR_TYPE_CONV);
  end;
end;

//
//  Проверка, запущено ли приложение из под учетной записи администратора
// =============================================================================
function TFWEventLog.IsAdmin: Boolean;
const
  SECURITY_NT_AUTHORITY: TSIDIdentifierAuthority =
    (Value: (0, 0, 0, 0, 0, 5));
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
  Result   := False;
  bSuccess := OpenThreadToken(GetCurrentThread, TOKEN_QUERY, True,
    hAccessToken);
  if not bSuccess then
  begin
    if GetLastError = ERROR_NO_TOKEN then
      bSuccess := OpenProcessToken(GetCurrentProcess, TOKEN_QUERY,
        hAccessToken);
  end;
  if bSuccess then
  begin
    GetMem(ptgGroups, 1024);
    bSuccess := GetTokenInformation(hAccessToken, TokenGroups,
      ptgGroups, 1024, dwInfoBufferSize);
    CloseHandle(hAccessToken);
    if bSuccess then
    begin
      AllocateAndInitializeSid(SECURITY_NT_AUTHORITY, 2,
        SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_ADMINS,
        0, 0, 0, 0, 0, 0, psidAdministrators);
      {$R-}
      for I := 0 to ptgGroups.GroupCount - 1 do
        if EqualSid(psidAdministrators, ptgGroups.Groups[I].Sid) then
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
//  Проверка заполненности лога
//  Для успешного выполнения, менеджер событий должен быть открыт на чтение
// =============================================================================
function TFWEventLog.IsEventLogFull: Boolean;
var
  GetEventLogInformation: function(hEventLog: THandle;
    dwInfoLevel: DWORD; lpBuffer: Pointer; cbBufSize: DWORD;
    var pcbBytesNeeded: DWORD): Boolean; stdcall;
  Info:EVENTLOG_FULL_INFORMATION;
  Dumme:DWORD;
begin
  Result:= False;
  if not (osRead in OpenState) then
    raise EFWEventLog.Create(Format(ERR_WRONG_STATE, ['osRead']));
  @GetEventLogInformation := GetProcAddress(
    GetModuleHandle(advapi32), 'GetEventLogInformation');
  if Assigned(@GetEventLogInformation) then
    if GetEventLogInformation(FReadHandle, EVENTLOG_FULL_INFO,
      @Info, SizeOf(EVENTLOG_FULL_INFORMATION), Dumme)
    then Result := Boolean(Info.dwFull);
end;

//
//  Проверка наличия ветки регистрации приложения в качестве ресурса
//  таблицы сообщений
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
//  Проверка заполненности лога
//  Для успешного выполнения, менеджер событий должен быть открыт на чтение
// =============================================================================
function TFWEventLog.LoadStringFromMessageTable(Source, RegParam: String;
  SourceType: TFWEventSources; ID: DWORD; Parameters: Pointer): String;
  
  function MAKELANGID(PrimaryLang, SubLang: Word): Word;
  begin
    Result := (SubLang shl 10) or PrimaryLang;
  end;

  function GetCategoryStringFromModule(hLibHandle: THandle): String;
  var
    CategoryData: PChar;
  begin
    CategoryData := nil;
    if FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER or
      FORMAT_MESSAGE_FROM_HMODULE or FORMAT_MESSAGE_ARGUMENT_ARRAY,
      Pointer(hLibHandle), ID,
      MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
      @CategoryData, 0, Parameters) <> 0
    then
    try
      Result := Trim(StrPas(CategoryData));
    finally
      LocalFree(DWORD(CategoryData));
    end;
  end;

var
  I: Integer;
  EnvLibPath, Key: String;
  EnvLibPathes: TStringList;
  FullLibPath: array [0..MAX_PATH - 1] of Char;
  LibItem: TFWMessageTableLibrary;
begin

  // Если источник события мы, получаем данные используя свой HInstance
  if Source = FSource then
  begin
    Result := GetCategoryStringFromModule(HInstance);
    Exit;
  end;

  // Ищем, не подгружен ли у нас уже данный источник
  for I := 0 to MessageTableLibraryes.Count - 1 do
    if string(MessageTableLibraryes.Item[I].sLibName) = Source then
    begin
      // Если подгружен - используем его описатель
      Result :=
        GetCategoryStringFromModule(MessageTableLibraryes.Item[I].hLibHandle);
      if Result <> '' then Exit;
    end;

  // В противном случае, пробуем найти путь к источнику в реестре
  with TRegistry.Create do
  try
    RootKey := HKEY_LOCAL_MACHINE;
    Key := ROOT_EVENTLOG_REGKEY +
      RegEventSources[SourceType] + '\' + Source;
    // Смотрим, есть ли регистрационная запись соответствующая источнику?
    if KeyExists(Key) then
      if OpenKey(Key, False) then
      try
        // Есть, вытаскиваем строку с перечислением возможных контейнеров,
        // содержащих в себе таблицу сообщений к данному событию
        EnvLibPath := ReadString(RegParam);
      finally
        CloseKey;
      end
      else
        // Просто так открыть ветку реестра Security не получиться,
        // поэтому обойдем прямым указыванием возможных путей
        if SourceType = esSecurity then
          EnvLibPath :=
            '%SystemRoot%\System32\MsAuditE.dll;%SystemRoot%\System32\xpsp2res.dll';
  finally
    Free;
  end;

  if EnvLibPath = '' then Exit;
  EnvLibPathes := TStringList.Create;
  try
    // Все пути помещаем в StringList
    EnvLibPathes.Text := StringReplace(EnvLibPath, ';', sLineBreak, [rfReplaceAll]);
    for I := 0 to EnvLibPathes.Count - 1 do
      if EnvLibPathes.Strings[I] <> '' then
      begin
        // В пути может быть переменная окружения - преобразовываем ее
        // в нормальный путь
        ExpandEnvironmentStrings(PChar(EnvLibPathes.Strings[I]),
          @FullLibPath[0], MAX_PATH);
        LibItem.bLoaded := False;
        // Смотрим, загружен ли уже данный модуль?
        LibItem.hLibHandle := GetModuleHandle(PChar(@FullLibPath[0]));
        if LibItem.hLibHandle <= HINSTANCE_ERROR then
        begin
          LibItem.bLoaded := True;
          // Не загружен - подгружаем его
          LibItem.hLibHandle :=
            LoadLibraryEx(PChar(@FullLibPath[0]), 0, LOAD_LIBRARY_AS_DATAFILE);
        end;
        if LibItem.hLibHandle > HINSTANCE_ERROR then
        begin
          // Если подгрузка успешна, добавляем описание модуля в таблицу
          LibItem.sLibName := ShortString(Source);
          Inc(MessageTableLibraryes.Count);
          SetLength(MessageTableLibraryes.Item, MessageTableLibraryes.Count);
          MessageTableLibraryes.Item[
            MessageTableLibraryes.Count - 1] := LibItem;
          // Получаем данные
          Result := GetCategoryStringFromModule(LibItem.hLibHandle);
          if Result <> '' then Exit;
        end;
      end;                          
  finally
    EnvLibPathes.Free;
  end;
end;

//
//  Служебное событие, используется для функционирования калбэка
// =============================================================================
procedure TFWEventLog.OnReadRecord(Sender: TObject;
  EventRecord: TFWEventLogRecord; var Stop: Boolean);
begin
  if Assigned(FOnReadRecordCallback) then
    FOnReadRecordCallback(Self, EventRecord, Stop);
end;

//
//  Открытие менеджера событий на чтение или запись
// =============================================================================
function TFWEventLog.Open(const Source: TFWLocalEventSources;
  const State: TFSOpenState): Boolean;
begin
  Result := CustomOpen(Source, State);
end;

//
//  Преобразование считанной структуры в читабельный вид
// =============================================================================
function TFWEventLog.ParseEventLogRecord(SourceType: TFWEventSources;
  const EventLogRecord: TEventLogRecord): TFWEventLogRecord;
var
  StrOffset: DWORD;
var
  Account, Domain: String;
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
  Result.Category := GetCategoryString(Result.SourceName, SourceType,
    EventLogRecord.EventCatagory);
  Inc(StrOffset, Length(Result.SourceName) + 1);
  Result.ComputerName := PChar(@EventLogRecord.DataOffset) + StrOffset;
  GetAccountAndDomainName(PSID(DWORD(@EventLogRecord) +
    EventLogRecord.UserSidOffset), Account, Domain);
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

  // Тонкий момент:
  // EventID события имеет тип WORD, но для верного получения
  // необходимо подгружать ресурс с полным идентификатором DWORD
  // Например EventLogRecord.EventID равен 12345678,
  // его реальный ID в данном случае будет 24910 (12345678 and $FFFF),
  // но FormatMessage долен получить в качестве идентификатора
  // именно 12345678, а не 24910

  Result.Description:= GetEventString(Result.SourceName, SourceType,
    EventLogRecord.EventID, AStrings);

  Result.Description :=
    StringReplace(Result.Description, #10, '', [rfReplaceAll]);
  Result.Description :=
    StringReplace(Result.Description, #13, sLineBreak, [rfReplaceAll]);

  if EventLogRecord.DataLength > 0 then
  begin
    SetLength(Result.BinData, EventLogRecord.DataLength);
    StrOffset := (DWORD(@EventLogRecord) + EventLogRecord.DataOffset);
    Move(Pointer(StrOffset)^, Result.BinData[0], EventLogRecord.DataLength);
  end;
end;

//
//  Подготавливаем параметры для форматирования, заносим их в список
// =============================================================================
procedure TFWEventLog.PrepareParameters(List: TList; Parameters: TStringArray);
var
  I: Integer;
begin
  for I := 0 to Length(Parameters) - 1 do
    List.Add(PChar(Parameters[I]));
end;

//
//  Чтение записи
//  Первый параметр указывает откуда будет производиться запись
//  Из бэкапа или из ситсемного лога
//  Второй параметр - номер записи
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

function TFWEventLog.Read(const Backup: Boolean;
                          const Groups: Boolean;
                          const Date:Word;
                          const Filtered:Boolean;
                          const EType:TFWEventLogRecordType;
                          ListView:TListView): Boolean;
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
//  Чтение всех записей
//  Первый параметр указывает откуда будет производиться чтение
//  Из бэкапа или из ситсемного лога
//  Второй параметр - направление чтения
//  Третий параметр объектная процедура, вызываемая при чтении каждой записи
// =============================================================================
function TFWEventLog.Read(const Backup: Boolean; const Forwards: Boolean;
  CallbackEvent: TFWOnReadRecordEvent): Boolean;
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
  Result := CustomReadSequential(EventHandle, SourceType,
    Forwards, CallbackEvent);
end;

//
//  Чтение всех записей
//  Первый параметр указывает откуда будет производиться чтение
//  Из бэкапа или из ситсемного лога
//  Второй параметр - направление чтения
//  Третий параметр процедура обратного вызова,
//  вызываемая при чтении каждой записи
// =============================================================================
function TFWEventLog.Read(const Backup: Boolean; const Forwards: Boolean;
  lpfnCallback: TFWOnReadRecordCallback): Boolean;
begin
  FOnReadRecordCallback := lpfnCallback;
  try
    Result := Read(Backup, Forwards, OnReadRecord);
  finally
    FOnReadRecordCallback := nil;
  end;
end;

//
//  Чтение количества всех записей
//  Первый параметр указывает откуда будет производиться чтение
//  Из бэкапа или из ситсемного лога
//  Второй параметр - какие записи будут рассматриваться, актуальные или устаревшие
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
//  Регистрация приложения в качестве источника, содержащего таблицу сообщений
// =============================================================================
function TFWEventLog.RegisterApp(CategoryCount: Integer = 1): Boolean;
const
  TypeSupport =
    EVENTLOG_SUCCESS or
    EVENTLOG_ERROR_TYPE or
    EVENTLOG_WARNING_TYPE or
    EVENTLOG_INFORMATION_TYPE or
    EVENTLOG_AUDIT_SUCCESS or
    EVENTLOG_AUDIT_FAILURE;
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
      end
      else
        Abort;
    finally
      Free;
    end;
  except
    ShowMessage(ERR_REGISTER);
  end;
end;

//
//  Запуск потока следящего за изменениями с списке событий
//  Вариант с объектной процедурой
// =============================================================================
function TFWEventLog.RegisterChangeNotify(Event: TFWOnChangeEvent): Boolean;
begin
  if not (osRead in OpenState) then
    raise EFWEventLog.Create(Format(ERR_WRONG_STATE, ['osRead']));
  Result := (osNotify in FState);
  if Result then
    raise EFWEventLog.Create(ERR_DOUBLE_REGISTER);
  // Слежение будет установленно за той ветвью,
  // которая сейчас открыта в режиме чтение
  FNotifyHandle := OpenEventLog(nil, PChar(RegEventSources[FReadSourceType]));
  FNotifySourceType := FReadSourceType;
  if FNotifyHandle = 0 then Exit;
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
//  Запуск потока следящего за изменениями с списке событий
//  Вариант с процедурой обратного вызова
// =============================================================================
function TFWEventLog.RegisterChangeNotify(Callback: TFWOnChangeCallback): Boolean;
begin
  if not (osRead in OpenState) then
    raise EFWEventLog.Create(Format(ERR_WRONG_STATE, ['osRead']));
  Result := (osNotify in FState);
  if Result then
    raise EFWEventLog.Create(ERR_DOUBLE_REGISTER);
  // Слежение будет установленно за той ветвью,
  // которая сейчас открыта в режиме чтение
  FNotifyHandle := OpenEventLog(nil, PChar(RegEventSources[FReadSourceType]));
  FNotifySourceType := FReadSourceType;
  if FNotifyHandle = 0 then Exit;
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
//  Преобразование времени из Universal Coordinated Time в стандартный TDateTime
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
  IntermediateData := EncodeDate(1970, 1, 1) +
    Days + EncodeTime(Hour, Min, Value, 0);

  DateTimeToSystemTime(IntermediateData, SystemTime);
  SystemTimeToFileTime(SystemTime, FileTime);
  FileTimeToLocalFileTime(FileTime, FileTime);
  FileTimeToSystemTime(FileTime, SystemTime);
  Result := SystemTimeToDateTime(SystemTime);
end;

//
//  Запись с лог событий новой записи
//  Вариант с бинартными данными
// =============================================================================
function TFWEventLog.Write(RecType: TFWEventLogRecordType; Msg: String;
  RAWData: Pointer; RAWDataSize: Integer; Category: Word; EventID: Word): Boolean;
var
  lpMsg: PPChar;
begin
  if not (osWrite in OpenState) then
    raise EFWEventLog.Create(Format(ERR_WRONG_STATE, ['osWrite']));
  New(lpMsg);
  try
    lpMsg^ := PChar(Msg);
    Result := ReportEvent(FWriteHandle, GetWordTypeWromRecordType(RecType),
      Category, EventID, nil, 1, RAWDataSize, lpMsg, RAWData);
  finally
    Dispose(lpMsg);
  end;
end;

//
//  Запись с лог событий новой записи
//  Вариант тлько с тектом события
// =============================================================================
function TFWEventLog.Write(RecType: TFWEventLogRecordType; Msg: String; Category: Word; EventID: Word): Boolean;
var
  lpMsg: PPChar;
begin
  if not (osWrite in OpenState) then
    raise EFWEventLog.Create(Format(ERR_WRONG_STATE, ['osWrite']));
  New(lpMsg);
  try
    lpMsg^ := PChar(Msg);
    Result := ReportEvent(FWriteHandle, GetWordTypeWromRecordType(RecType),
      Category, EventID, nil, 1, 0, lpMsg, nil);
  finally
    Dispose(lpMsg);
  end;
end;

//
//  Оконная процедура, необходима для получения уведомлений от потока о ошибке
// =============================================================================
procedure TFWEventLog.WndProc(var Message: TMessage);
begin
  case Message.Msg of
    WM_THREAD_ERROR:
      if Integer(Message.WParam) = Integer(FErrorWnd) then
      begin
        DeRegisterChangeNotify;
        raise EFWEventLog.Create(Format(ERR_NOTIFY_THREAD,
          [Error, SysErrorMessage(Error)]));
      end;
  end;
end;


end.
