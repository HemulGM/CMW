unit Module.WinEvents;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, FWEventLog, Vcl.ExtCtrls, Vcl.StdCtrls, System.Win.Registry,
  Vcl.ComCtrls, Vcl.ImgList,
  CMW.ModuleStruct;

type
  TFormEventInfo = class(TForm)
    MemoData: TMemo;
    EditEvent: TEdit;
    EditDate: TEdit;
    Label1: TLabel;
    EditLvl: TEdit;
    Label2: TLabel;
    EditUser: TEdit;
    Label3: TLabel;
    EditComp: TEdit;
    Label4: TLabel;
    EditSrc: TEdit;
    Label5: TLabel;
    EditCateg: TEdit;
    Label6: TLabel;
    EditError: TEdit;
    Label7: TLabel;
    MemoDesc: TMemo;
    MemoData2: TMemo;
    Panel1: TPanel;
    Bevel1: TBevel;
    ButtonClose: TButton;
    ButtonChg: TButton;
    procedure ButtonChgClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  TEventsUnit = class(TSystemUnit)
    SIDATE:Word;       //дата
    SITYPE:Word;       //категория
    SICODE:Word;       //код события
    SIUSER:WORD;       //юзер
    SICOMP:WORD;       //ПК
   private
    FEventLog:TFWEventLog;
    FDisableIcon:TIcon;
    FBackupFile:string;
    //FSourceName:string;
    FEventSources:TFWLocalEventSources;
    FBackup:Boolean;
    FEventType:TFWEventLogRecordType;
    FFiletred:Boolean;
    FDateData:Integer; //date
   public
    ImageList:TImageList;
    function FGet:TGlobalState; override;
    procedure OnChanged; override;
    procedure Initialize; override;
    procedure Stop; override;
    procedure ShowEvent(EventRecord:TFWEventLogRecord); overload;
    procedure ShowEvent(EventRecord:Integer); overload;
    procedure ShowSelectedEvent;
    constructor Create; override;
    destructor Destroy; override;
    property DisableIcon:TIcon read FDisableIcon write FDisableIcon;
    property BackupFile:string read FBackupFile write FBackupFile;
    //property SourceName:string read FSourceName write FSourceName;
    property EventSources:TFWLocalEventSources read FEventSources write FEventSources;
    property DateData:Integer read FDateData write FDateData;
    property EventLog:TFWEventLog read FEventLog;
    property Backup:Boolean read FBackup;
    property Filetred:Boolean read FFiletred write FFiletred;
    property EventType:TFWEventLogRecordType read FEventType write FEventType;
  end;

implementation
 uses CMW.Utils;

{$R *.dfm}

procedure TFormEventInfo.ButtonChgClick(Sender: TObject);
begin
 MemoData.Visible:=not MemoData.Visible;
 MemoData2.Visible:=not MemoData2.Visible;
end;

procedure TFormEventInfo.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 //Action:=caFree;
end;

procedure TEventsUnit.Initialize;
begin
 FEventLog:=TFWEventLog.Create('CWM_ENGINE_EVENTS');
end;

procedure TEventsUnit.OnChanged;
begin
 inherited;
 OnListViewSort;
end;

procedure TEventsUnit.Stop;
begin
 inherited;
end;
      {
procedure ShowSelected;
var EventRecord: TFWEventLogRecord;
    LV:TListView;
begin
 LV:=Sender as TListView;
 if LV.Selected = nil then Exit;
  try
   if not SmartHandler.EventLog.Read(False, Integer(LV.Selected.Data), EventRecord) then Abort;
  except
   ShowMessage('Не могу прочесть журнал событий Windows.');
   Exit;
  end;
 ShowEvent(EventRecord);
end;    }

procedure TEventsUnit.ShowEvent(EventRecord:TFWEventLogRecord);
var AccountAndUser:string;
    BinDataLength:integer;
begin
 with TFormEventInfo.Create(nil) do
  begin
   EditEvent.Text:=EventRecord.SourceName+' ('+IntToStr(EventRecord.EventID)+')';
   EditDate.Text:=DateTimeToStr(EventRecord.TimeWritten);
   EditLvl.Text:=TFWEventLog.EventTypeToString(EventRecord.EventType);
   AccountAndUser:=EventRecord.Domain+'\'+EventRecord.Account;
   if AccountAndUser = '\' then AccountAndUser:='Н/Д';
   EditUser.Text:=AccountAndUser;
   EditComp.Text:=EventRecord.ComputerName;
   EditSrc.Text:=EventRecord.SourceName;
   EditCateg.Text:=EventRecord.Category;
   EditError.Text:=IntToStr(EventRecord.EventID);
   MemoDesc.Text:=EventRecord.Description;
   BinDataLength:=Length(EventRecord.BinData);
   if BinDataLength > 0 then
    begin
     MemoData.Text:=ByteToHexStr(EventRecord.BinData, BinDataLength);
     MemoData2.Text:=WordToHexStr(EventRecord.BinData, BinDataLength);
    end;
   ShowModal;
  end;
end;

procedure TEventsUnit.ShowSelectedEvent;
begin
 ShowEvent(ListView.ItemIndex);
end;

procedure TEventsUnit.ShowEvent(EventRecord:Integer);
var ID:DWORD;
    AEvent:TFWEventLogRecord;
begin
 if (EventRecord > (ListView.Items.Count - 1)) or (EventRecord < 0) then
  begin
   Log(['Внешняя ошибка. Не смог получить данные о записи', ID]);
   Exit;
  end;

 try
  ID:=DWORD(ListView.Items[EventRecord].Data^);
  if FEventLog.Read(FBackup, ID, AEvent) then ShowEvent(AEvent) else Abort;
 except
  begin
   ShowMessage('Внутренняя ошибка. Не смог получить запись журнала событий.');
   Log(['Внутренняя ошибка. Не смог получить запись журнала событий с идентификатором', ID]);
  end;
 end;
end;

function TEventsUnit.FGet:TGlobalState;
var IconN:TIcon;
    DI:Integer;
begin
 Inform(LangText(20, 'Получение списка событий Windows...'));
 Result:=gsProcess;
 ListView.Items.BeginUpdate;
 ListView.Items.Clear;
 ListView.Groups.Clear;
 ListView.GroupView:=FGrouping;

 ListView.SmallImages:=TImageList.Create(nil);
 ListView.SmallImages.Width:=16;
 ListView.SmallImages.Height:=16;
 ListView.SmallImages.ColorDepth:=cd32Bit;
 if not Assigned(FDisableIcon) then DI:=-1
 else DI:=ListView.SmallImages.AddIcon(FDisableIcon);

 IconN:=TIcon.Create;
 ImageList.GetIcon(0, IconN);
 ListView.SmallImages.AddIcon(IconN);
 ImageList.GetIcon(1, IconN);
 ListView.SmallImages.AddIcon(IconN);
 ImageList.GetIcon(2, IconN);
 ListView.SmallImages.AddIcon(IconN);
 ImageList.GetIcon(3, IconN);
 ListView.SmallImages.AddIcon(IconN);
 ImageList.GetIcon(4, IconN);
 ListView.SmallImages.AddIcon(IconN);
 ImageList.GetIcon(5, IconN);
 ListView.SmallImages.AddIcon(IconN);
 ImageList.GetIcon(6, IconN);
 ListView.SmallImages.AddIcon(IconN);
 ImageList.GetIcon(7, IconN);
 ListView.SmallImages.AddIcon(IconN);
 IconN.Free;
 ListView.StateImages:=ListView.SmallImages;

 if (osRead in FEventLog.OpenState) then FEventLog.Close(osRead);
 if (osBackUp in FEventLog.OpenState) then FEventLog.Close(osBackUp);
 if FBackupFile <> '' then
  begin
   FBackup:=True;
   if not FEventLog.BackupOpen(FBackupFile, FEventSources) then
    begin
     ShowMessage('not FEventLog.BackupOpen(FBackupFile, FEventSources)');
     Log(['Невозможно получить список событий. Ошибка при открытии журнала.', SysErrorMessage(GetLastError)]);
     Exit(gsError);
    end;
  end
 else
  begin
   FBackup:=False;
   if not FEventLog.Open(FEventSources, osRead) then
    begin
     ShowMessage('not EventLog.Open(FEventSources, osRead)');
     Log(['Невозможно получить список событий. Ошибка при открытии журнала.', SysErrorMessage(GetLastError)]);
     Exit(gsError);
    end;
  end;
 try
  begin
   FEventLog.Read(FBackup, FGrouping, FDateData, FFiletred, FEventType, ListView);
  end;
 except
  Log(['Ошибка при чтении журнала.', SysErrorMessage(GetLastError)]);
 end;

 Inform(LangText(-1, 'Список событий Windows успешно получен.'));
 OnChanged;
 try
  Result:=gsFinished;
 except
  Exit;
 end;
end;

constructor TEventsUnit.Create;
begin
 inherited;
 ImageList:=TImageList.CreateSize(16, 16);
 ImageList.ColorDepth:=cd32Bit;
 FBackup:=False;
 FEventSources:=esSystem;
 FDateData:=1;
 FEventType:=rtError;
end;

destructor TEventsUnit.Destroy;
begin
 if Assigned(Roll) then Roll.Free;
 FreeAndNil(FEventLog);
 inherited;
end;



{

function TSmartHandler.Events:Boolean;
begin
 CurrentElement:=LangText(14, 'События Windows');
 Result:=False;
 try
  if EventsState = gsIsNotGetted then GetEvents(FormMain.ListViewEvents);
  if FormMain.ListViewEvents.Items.Count > EvtCountlot then
   AddItemToDel(LangText(43, 'Требующих внимание событии Windows более')+' '+IntToStr(EvtCountlot), dtEvents, False, LangText(44, 'Всего событий:')+' '+IntToStr(FormMain.ListViewEvents.Items.Count));
 except
  begin
   MessageBox(Application.Handle, 'function TSmartHandler.Events:Word;', 'Error', MB_ICONERROR and MB_OK);
   Exit;
  end;
 end;
 Result:=True;
end;
}

end.
