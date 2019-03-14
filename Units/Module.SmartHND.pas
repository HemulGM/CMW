unit Module.SmartHND;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls,
  CMW.Utils, FWEventLog, Module.WinProcesses, Module.Autoruns, Module.WinEvents, Module.Ports,
  CMW.ModuleStruct, CMW.OSInfo, Module.Applications, Module.Cleaner, Module.Tasks, Module.HDD, Module.WinServices, Module.Executting,
  CMW.ModuleProp, Subs, Vcl.Grids, Vcl.ValEdit, Module.WinFirewall, Module.Regeditor, Module.ContextMenu;

type
  TFormSmartHND = class(TForm)
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  TTweakMachine = class
   private
    FListView:TListView;
    FListLog:TListView;
    FInitDir:string;
    FOnDblClick:TNotifyEvent;
    procedure SetInitDir(Value:string);
    procedure OnDblClick(Sender:TObject);
    function Initialize(aInitDir:string):Boolean;
    function Execute(FileName:TFileName):DWORD;
   public
    constructor Create(aInitDir:string; aListView, aLogView:TListView);
    procedure Update;
    procedure Log(Value:string);
    property InitDir:string read FInitDir write SetInitDir;
    property ListView:TListView read FListView write FListView;
    property LogView:TListView read FListLog write FListLog;
    property OnDblClicked:TNotifyEvent read FOnDblClick write FOnDblClick;
  end;

  TSmartHandler = class
    DeleteItems:TListView;
    ScanItems:TListView;
    StartTime:Cardinal;
    Stop:Boolean;
    StopTime:Cardinal;

    ImPathsState:TGetState;
    TweaksState:TGetState;
    FOldCounterState:Integer;
    FProcessingCounter:Integer;
   private
    FForm:TForm;
    FNowWowRedirection:Boolean;
    FWOWSwitchState:Boolean;
    FProgressBarState:TProgressBar;
    FCurrentElement:string;
    FOnSetCurElement:TOnSetCurElement;
    FTweakMachine:TTweakMachine;
    procedure SetCurElement(Value:string);
    procedure SetState(Value:TGlobalState);
    function FProcessing:Boolean;
   public

    {0:Автозапуск}  AutorunsUnit:TAutorunUnit;
    {1:Приложения}  ApplicationsUnit:TApplicationUnit;
    {2:Очистка}     CleanerUnit:TCleanerUnit;
    {3:Планировщик} TasksUnit:TTasksUnit;
    {4:Хранилище}   HDDUnit:THDDUnit;
    {5:Службы}      ServicesUnit:TServicesUnit;
    {6:События}     EventsUnit:TEventsUnit;
    {7:Процессы}    ProcessesUnit:TProcessesUnit;
    {8:Порты}       PortsUnit:TPortsUnit;
    {9:Выполнение}  ExecuteUnit:TExecuteUnit;
    {10:Брандмауэр} FirewallUnit:TFirewallUnit;
    {11:Реестр}     RegeditUnit:TRegUnit;
    {12:Конт. меню} ContextMenuUnit:TContextMenuUnit;
    function WOWSwitch:Boolean;
    procedure GlobalStop;
    procedure GlobalStart;
    procedure AccessState(LV:TListView);
    procedure Cancel;
    procedure GetTweaks(LV:TListView);
    procedure Run;
    procedure AddToProcessing;
    procedure OpenHostsFile;
    constructor Create;
    property NowWowRedirection:Boolean read FNowWowRedirection;
    property TweakMachine:TTweakMachine read FTweakMachine;
    property CurrentElement:string read FCurrentElement write SetCurElement;
    property OnSetCurElement:TOnSetCurElement read FOnSetCurElement write FOnSetCurElement;
    property Processing:Boolean read FProcessing;
    property ProgressBarState:TProgressBar read FProgressBarState write FProgressBarState;
    property EngineForm:TForm read FForm write FForm;
  end;

var
  FormSmartHND: TFormSmartHND;

implementation

{$R *.dfm}

uses CMW.Main, Winapi.ShellAPI, System.IniFiles, System.Win.Registry;

//-----------------------------TSmartHandler--------------------------------------

procedure TSmartHandler.OpenHostsFile;
begin
 ShellExecute(Application.Handle, 'open', 'notepad.exe', PChar(Info.HostsFileName), nil, SW_NORMAL);
end;

procedure TSmartHandler.AddToProcessing;
begin
 FProcessingCounter:=FProcessingCounter + 1;
 SetState(gsNone);
end;

function TSmartHandler.WOWSwitch:Boolean;
begin
 if AppBits = x64 then
  begin
   MessageBox(Application.Handle, 'Смена режима не даст результатов т.к. версия приложения и ОС одинакова.', 'Внимание', MB_OK or MB_ICONWARNING);
   Exit(False);
  end;
 if @Wow64EnableWow64FsRedirection = nil then
  begin
   MessageBox(Application.Handle, 'Смена режима недоступна. Неудалось получить адрес функции "Wow64EnableWow64FsRedirection" из Kernel32.dll.', 'Внимание', MB_OK or MB_ICONWARNING);
   Exit(False);
  end;
 FWOWSwitchState:=not FWOWSwitchState;
 if not FWOWSwitchState then
  begin
   FNowWowRedirection:=False;
   Wow64EnableWow64FsRedirection(True);
   Exit(False);
  end
 else
  begin
   FNowWowRedirection:=True;
   Wow64EnableWow64FsRedirection(False);
   Exit(True);
  end;
end;

procedure TSmartHandler.GlobalStart;
begin
 Exit;      {
 ApplicationsUnit.Resume;
 AutorunsUnit.Resume;
 CleanerUnit.Resume;
 TasksUnit.Resume;
 HDDUnit.Resume;
 ServicesUnit.Resume;
 EventsUnit.Resume;
 ProcessesUnit.Resume;
 PortsUnit.Resume;
 ExecuteUnit.Resume;
 FirewallUnit.Resume;
 RegeditUnit.Resume;
 ContextMenuUnit.Resume}
 Application.ProcessMessages;
end;

procedure TSmartHandler.GlobalStop;
begin
 Stop:=True;
 ApplicationsUnit.Stop;
 AutorunsUnit.Stop;
 CleanerUnit.Stop;
 TasksUnit.Stop;
 HDDUnit.Stop;
 ServicesUnit.Stop;
 EventsUnit.Stop;
 ProcessesUnit.DisableMonitor;
 ProcessesUnit.Stop;
 PortsUnit.Stop;
 ExecuteUnit.Stop;
 FirewallUnit.Stop;
 RegeditUnit.Stop;
 ContextMenuUnit.Stop;
end;

function TSmartHandler.FProcessing:Boolean;
begin
 Result:=FProcessingCounter > 0;
end;

procedure TSmartHandler.SetState(Value:TGlobalState);
begin
 if not Assigned(FProgressBarState) then Exit;
 case Value of
  gsProcess: FProcessingCounter:=FProcessingCounter + 1;
  gsFinished: FProcessingCounter:=FProcessingCounter - 1;
  gsStopped: FProcessingCounter:=FProcessingCounter - 1;
  gsError: FProcessingCounter:=FProcessingCounter - 1;
 end;
 if FProcessingCounter > 0 then
  begin
   if FProgressBarState.Position <> 10 then
    begin
     FProgressBarState.Style:=pbstMarquee;
     FProgressBarState.Position:=10;
    end;
  end
 else
  if FProcessingCounter = 0 then
   begin
    FProgressBarState.Style:=pbstNormal;
    FProgressBarState.Position:=100;
    FProgressBarState.State:=pbsNormal;
   end
  else
   begin
    FProgressBarState.Style:=pbstNormal;
    FProgressBarState.Position:=50;
    FProgressBarState.State:=pbsError;
   end;
end;

procedure TSmartHandler.SetCurElement(Value:string);
begin
 if Value = FCurrentElement then Exit;
 if Assigned(FOnSetCurElement) then OnSetCurElement(Value);
 FCurrentElement:=Value;
end;

procedure TSmartHandler.AccessState(LV:TListView);
var RALvl:Byte;
begin
 LV.Clear;
 LV.Groups.Clear;
 LV.GroupView:=TRue;

 //---------------------Реестр--------------------------------------------------
 RALvl:=Info.RollAccessLevel;
 with LV.Items.Add do
  begin
   Caption:=LangText(26, 'Чтение HKCU');
   SubItems.Add(BoolStr(RALvl > 0, 'Да', 'Нет'));
   GroupID:=GetGroup(LV, LangText(32, 'Реестр'), True);
  end;
 with LV.Items.Add do
  begin
   Caption:=LangText(27, 'Запись HKCU');
   SubItems.Add(BoolStr(RALvl > 1, 'Да', 'Нет'));
   GroupID:=GetGroup(LV, LangText(32, 'Реестр'), True);
  end;
 with LV.Items.Add do
  begin
   Caption:=LangText(28, 'Полный доступ HKCU');
   SubItems.Add(BoolStr(RALvl > 2, 'Да', 'Нет'));
   GroupID:=GetGroup(LV, LangText(32, 'Реестр'), True);
  end;
 with LV.Items.Add do
  begin
   Caption:=LangText(29, 'Чтение HKLM');
   SubItems.Add(BoolStr(RALvl > 3, 'Да', 'Нет'));
   GroupID:=GetGroup(LV, LangText(32, 'Реестр'), True);
  end;
 with LV.Items.Add do
  begin
   Caption:=LangText(30, 'Запись HKLM');
   SubItems.Add(BoolStr(RALvl > 4, 'Да', 'Нет'));
   GroupID:=GetGroup(LV, LangText(32, 'Реестр'), True);
  end;
 with LV.Items.Add do
  begin
   Caption:=LangText(31, 'Полный доступ HKLM');
   SubItems.Add(BoolStr(RALvl > 5, 'Да', 'Нет'));
   GroupID:=GetGroup(LV, LangText(32, 'Реестр'), True);
  end;
 //-------------Права администратора   runas /trustlevel:0x20000 "D:\Debug\CWM.exe"
 with LV.Items.Add do
  begin
   Caption:=LangText(-1, 'Права администратора у пользователя');
   SubItems.Add(BoolStr(Info.UserIsAdmin, 'Да', 'Нет'));
   GroupID:=GetGroup(LV, LangText(-1, 'Общие права'), True);
  end;
 //-------------Права администратора
 with LV.Items.Add do
  begin
   Caption:=LangText(-1, 'Права администратора у программы');
   SubItems.Add(BoolStr(IsProgAdmin, 'Да', 'Нет'));
   GroupID:=GetGroup(LV, LangText(-1, 'Общие права'), True);
  end;
 //-------------Права администратора
 with LV.Items.Add do
  begin
   Caption:=LangText(-1, 'Перенаправление сред из-за не соответствия разрядности');
   SubItems.Add(BoolStr(IsWow64, 'Да', 'Нет'));
   GroupID:=GetGroup(LV, LangText(36, 'Другое'), True);
  end;
end;

constructor TSmartHandler.Create;
var IconN:TIcon;
begin
 inherited;
 FProcessingCounter:=0;
 FOldCounterState:=0;
 //Clr data of class

 FWOWSwitchState:=False;

 //end clr

 AutorunsUnit:=TAutorunUnit.Create;
 with AutorunsUnit do
  begin
   Name:='AutorunsUnit';
   ListView:=FormMain.ListViewAR;
   LabelCount:=FormMain.LabelCountAutorun;
   HandleInform:=SetCurElement;
   DisableIcon:=TIcon.Create;
   LoadIcons:=True;
   StateProc:=SetState;
   Grouping:=True;
   CurrentOSLink:=Info;
   FormMain.ImageListFiles32.GetIcon(11, DisableIcon);
   Initialize;
  end;

 ApplicationsUnit:=TApplicationUnit.Create;
 with ApplicationsUnit do
  begin
   Name:='ApplicationsUnit';
   ListView:=FormMain.ListViewWinApps;
   LabelCount:=FormMain.LabelCountInstall;
   HandleInform:=SetCurElement;
   StateProc:=SetState;
   LoadIcons:=True;
   DisableIcon:=TIcon.Create;
   Grouping:=True;
   CurrentOSLink:=Info;
   FormMain.ImageListToolBar.GetIcon(22, DisableIcon);
   Initialize;
  end;

 CleanerUnit:=TCleanerUnit.Create;
 with CleanerUnit do
  begin
   Name:='CleanerUnit';
   ListView:=FormMain.ListViewDelete;
   ParamList:=FormMain.ListViewParam;
   LabelCount:=FormMain.LabelCountClr;
   HandleInform:=SetCurElement;
   StateProc:=SetState;
   LoadIcons:=True;
   DisableIcon:=TIcon.Create;
   Grouping:=True;
   CurrentOSLink:=Info;
   ScanFiles:=True;
   FormMain.ImageListFiles32.GetIcon(10, DisableIcon);
   Initialize;
  end;

 TasksUnit:=TTasksUnit.Create;
 with TasksUnit do
  begin
   Name:='TasksUnit';
   ListView:=FormMain.ListViewSchedule;
   LabelCount:=FormMain.LabelCountTask;
   HandleInform:=SetCurElement;
   StateProc:=SetState;
   LoadIcons:=True;
   DisableIcon:=TIcon.Create;
   CurrentOSLink:=Info;
   Grouping:=True;
   FormMain.ImageListFiles.GetIcon(16, DisableIcon);

   IconN:=TIcon.Create;
   FormMain.ImageListFiles.GetIcon(16, IconN);
   ImageList.AddIcon(IconN);
   FormMain.ImageListFiles.GetIcon(11, IconN);
   ImageList.AddIcon(IconN);
   FormMain.ImageListFiles.GetIcon(18, IconN);
   ImageList.AddIcon(IconN);
   FormMain.ImageListFiles.GetIcon(19, IconN);
   ImageList.AddIcon(IconN);
   IconN.Free;
   Initialize;
  end;

 HDDUnit:=THDDUnit.Create;
 with HDDUnit do
  begin
   Name:='HDDUnit';
   ListView:=FormMain.ListViewHDD;
   LabelCount:=FormMain.LabelCountHDD;
   HandleInform:=SetCurElement;
   StateProc:=SetState;
   LoadIcons:=True;
   Grouping:=True;
   CurrentOSLink:=Info;
   GetAttrNames:=True;
   Initialize;
  end;

 ServicesUnit:=TServicesUnit.Create;
 with ServicesUnit do
  begin
   Name:='ServicesUnit';
   ListView:=FormMain.ListViewSrvs;
   LabelCount:=FormMain.LabelCountService;
   HandleInform:=SetCurElement;
   StateProc:=SetState;
   LoadIcons:=True;
   Grouping:=True;
   CurrentOSLink:=Info;
   SrvIcon:=TIcon.Create;
   FormMain.ImageListFiles.GetIcon(21, SrvIcon);
   DrvIcon:=TIcon.Create;
   FormMain.ImageListFiles.GetIcon(23, DrvIcon);
   Initialize;
  end;

 EventsUnit:=TEventsUnit.Create;
 with EventsUnit do
  begin
   Name:='EventsUnit';
   ListView:=FormMain.ListViewEvents;
   LabelCount:=FormMain.LabelCountEvent;
   HandleInform:=SetCurElement;
   StateProc:=SetState;
   LoadIcons:=True;
   Grouping:=True;
   CurrentOSLink:=Info;
   DisableIcon:=TIcon.Create;
   FormMain.ImageListFiles.GetIcon(15, DisableIcon);

   IconN:=TIcon.Create;
   FormMain.ImageListFiles.GetIcon(26, IconN);//info 0
   ImageList.AddIcon(IconN);
   FormMain.ImageListFiles.GetIcon(27, IconN);//warn 1
   ImageList.AddIcon(IconN);
   FormMain.ImageListFiles.GetIcon(28, IconN);//error 2
   ImageList.AddIcon(IconN);
   FormMain.ImageListFiles.GetIcon(29, IconN);//secur 3
   ImageList.AddIcon(IconN);
   FormMain.ImageListFiles.GetIcon(30, IconN);//apps 4
   ImageList.AddIcon(IconN);
   FormMain.ImageListFiles.GetIcon(31, IconN);//sys 5
   ImageList.AddIcon(IconN);
   FormMain.ImageListFiles.GetIcon(32, IconN);//sucs 6
   ImageList.AddIcon(IconN);
   FormMain.ImageListFiles.GetIcon(33, IconN);//fail 7
   ImageList.AddIcon(IconN);

   Initialize;
  end;

 ProcessesUnit:=TProcessesUnit.Create;
 with ProcessesUnit do
  begin
   Name:='ProcessesUnit';
   ListView:=FormMain.ListViewProc;
   TreeView:=FormMain.TreeViewPID;
   WinList:=FormMain.ListViewWindows;
   LabelCount:=FormMain.LabelCountProc;
   HandleInform:=SetCurElement;
   StateProc:=SetState;
   LoadIcons:=True;
   CurrentOSLink:=Info;
   Grouping:=False;
   OnlyVisableWnd:=True;
   OnlyMainWnd:=True;
   DisableIcon:=TIcon.Create;
   FormMain.ImageListFiles.GetIcon(34, DisableIcon);
   RootIcon:=TIcon.Create;
   FormMain.ImageListFiles.GetIcon(35, RootIcon);
   DefaultIcon:=TIcon.Create;
   FormMain.ImageListFiles.GetIcon(20, DefaultIcon);
   Initialize;
  end;

 PortsUnit:=TPortsUnit.Create;
 with PortsUnit do
  begin
   Name:='PortsUnit';
   ListView:=FormMain.ListViewPorts;
   LabelCount:=FormMain.LabelCountPorts;
   HandleInform:=SetCurElement;
   StateProc:=SetState;
   LoadIcons:=True;
   CurrentOSLink:=Info;
   Grouping:=True;
   IconN:=TIcon.Create;
   FormMain.ImageListFiles.GetIcon(24, IconN);
   FImageList.AddIcon(IconN);
   FormMain.ImageListFiles.GetIcon(25, IconN);
   FImageList.AddIcon(IconN);
   Initialize;
  end;

 ExecuteUnit:=TExecuteUnit.Create;
 with ExecuteUnit do
  begin
   Name:='ExecuteUnit';
   ListView:=FormMain.ListViewImPaths;
   //LabelCount:=FormMain.LabelCount;
   HandleInform:=SetCurElement;
   StateProc:=SetState;
   LoadIcons:=True;
   CurrentOSLink:=Info;
   Grouping:=True;
   DisableIcon:=TIcon.Create;
   FormMain.ImageListFiles.GetIcon(0, DisableIcon);
   DirIcon:=TIcon.Create;
   FormMain.ImageListFiles.GetIcon(1, DirIcon);
   Initialize;
  end;

 FirewallUnit:=TFirewallUnit.Create;
 with FirewallUnit do
  begin
   Name:='FirewallUnit';
   ListView:=FormMain.ListViewFW;
   //LabelCount:=FormMain.LabelCount;
   HandleInform:=SetCurElement;
   StateProc:=SetState;
   LoadIcons:=True;
   CurrentOSLink:=Info;
   Grouping:=False;
   DisableIcon:=TIcon.Create;
   FormMain.ImageListFiles.GetIcon(20, DisableIcon);
   ServiceIcon:=TIcon.Create;
   FormMain.ImageListFiles.GetIcon(21, ServiceIcon);
   Initialize;
  end;

 RegeditUnit:=TRegUnit.Create;
 with RegeditUnit do
  begin
   Name:='RegeditUnit';
   ListView:=FormMain.ListViewReg;
   TreeView:=FormMain.TreeViewReg;
   TreeView.Images:=FormMain.ImageListClearUnit;
   //LabelCount:=FormMain.LabelCount;
   HandleInform:=SetCurElement;
   StateProc:=SetState;
   LoadIcons:=True;
   CurrentOSLink:=Info;
   Grouping:=False;
   IconDir:=TIcon.Create;
   FormMain.ImageListFiles.GetIcon(1, IconDir);
   IconStr:=TIcon.Create;
   FormMain.ImageListFiles.GetIcon(36, IconStr);
   IconInt:=TIcon.Create;
   FormMain.ImageListFiles.GetIcon(37, IconInt);
   IconBin:=TIcon.Create;
   FormMain.ImageListFiles.GetIcon(37, IconBin);
   //DisableIcon:=TIcon.Create;
   //FormMain.ImageListFiles.GetIcon(20, DisableIcon);
   //ServiceIcon:=TIcon.Create;
   //FormMain.ImageListFiles.GetIcon(21, ServiceIcon);
   Initialize;
  end;

 ContextMenuUnit:=TContextMenuUnit.Create;
 with ContextMenuUnit do
  begin
   Name:='ContextMenuUnit';
   ListView:=FormMain.ListViewContext;
   //LabelCount:=FormMain.LabelCount;
   HandleInform:=SetCurElement;
   StateProc:=SetState;
   LoadIcons:=True;
   CurrentOSLink:=Info;
   Grouping:=False;
   DisableIcon:=TIcon.Create;
   FormMain.ImageListFiles.GetIcon(20, DisableIcon);
   //ServiceIcon:=TIcon.Create;
   //FormMain.ImageListFiles.GetIcon(21, ServiceIcon);
   Initialize;
  end;

 FreeAndNil(IconN);
 Stop:=False;
 StopTime:=0;
 ImPathsState:=gsIsNotGetted;

 FTweakMachine:=TTweakMachine.Create(CurrentDir+'data\fixs', FormMain.ListViewTweaks, FormMain.ListViewTweakLog);
 FormMain.ListViewTweaks.OnDblClick:=FTweakMachine.OnDblClick;
end;

procedure TSmartHandler.Cancel;
begin
 StopTime:=GetTickCount;
 with FormMain do
  begin
   TimerTick.Enabled:=False;
  end;
 //Отмена сканирования
end;

procedure TSmartHandler.Run;
//var i:Integer;
begin
 if Processing then Exit;
 Stop:=False;
 //Подготовка
 CurrentElement:=LangText(9, 'Подготовка к сканированию...');
 StartTime:=GetTickCount;

 //Начало сканирования ---------------------------------------------------------
 try

 except
  begin
   StopTime:=GetTickCount;
   with FormMain do
    begin
     CurrentElement:=LangText(8, 'Сканирование завершено не удачно.');
    end;
   Exit;
  end;
 end;

 //Сканирование завершено ------------------------------------------------------

 SmartHandler.Cancel;
end;

//------------------------------------------------------------------------------

procedure TSmartHandler.GetTweaks(LV:TListView);
begin
 if (TweaksState = gsGetting) or (TweaksState = gsCantGet) then Exit;
 TweaksState:=gsGetting;
 CurrentElement:='Получение доступных исправлений и решений...';
 LV.Clear;
 LV.Checkboxes:=True;
 LV.Groups.Clear;
 LV.Items.BeginUpdate;
 TweakMachine.Update;
 CurrentElement:='Исправления и решения получены.';
 LV.Items.EndUpdate;
 LV.ViewStyle:=vsReport;
 TweaksState:=gsIsGetted;
end;

///////////////////////
///
///

//------------------------TweakMachine------------------------------------------
// 0 - все норм
// 1 - не существует файл
// 2 - не открывается файл
// 3 - неверное кол-во действий
// 4 - неверное кол-во времени задержки
// 5 - не совпадает кол-во действий
// 6 - ошибка при выполнени команд
function TTweakMachine.Execute(FileName:TFileName):DWORD;
var FixFile:TIniFile;
    Acts, i:Word;
    TimeWait:Word;
    CMDType:string;
    cmd:string;

function QUERY(ActNo:Word):Boolean;
var QUERYSTR:string;
    DATASTR:string;
    Root:string;
    p:Word;
    Roll:TRegistry;
//12345678901234567
//QUERYREGPATHEXIST
//QUERYREGKEYEXIST
//QUERYREGKEYVALUE
begin
 Result:=False;
 if FixFile.ReadString('Act'+IntToStr(ActNo), 'QUERY', '') = '' then Exit(True);
 DATASTR:=FixFile.ReadString('Act'+IntToStr(ActNo), 'QUERY', '');
 p:=Pos('(', DATASTR);
 QUERYSTR:=Copy(DATASTR, 1, p - 1);
 DATASTR:=Copy(DATASTR, p+1, Length(DATASTR) - Length(QUERYSTR) - 2);
 p:=Pos('\', DATASTR);
 Root:=Copy(DATASTR, 1, p - 1);
 DATASTR:=Copy(DATASTR, p+1, Length(DATASTR) - Length(Root) - 1);
 if QUERYSTR = 'QUERYREGPATHEXIST' then
  begin
   Roll:=TRegistry.Create(KEY_READ);
   Roll.RootKey:=StrKeyToRoot(Root);
   Result:=Roll.OpenKey(DATASTR, False);
   Roll.Free;
   Exit;
  end;

 //Проверка запроса
end;

procedure ShowMSG(ActNo:Word);
begin
 if QUERY(ActNo) then
  begin
   if FixFile.ReadString('Act'+IntToStr(i), 'MessageWithTrue', '') <> '' then
    ShowMessage(FixFile.ReadString('Act'+IntToStr(i), 'MessageWithTrue', ''))
  end
 else
  begin
   if FixFile.ReadString('Act'+IntToStr(i), 'MessageWithFalse', '') <> '' then
    ShowMessage(FixFile.ReadString('Act'+IntToStr(i), 'MessageWithFalse', ''));
  end;
end;

begin
 Result:=0;
 LogView.Clear;
 if not FileExists(FileName) then Exit(1);
 try
  FixFile:=TIniFile.Create(FileName);
 except
  Exit(2);
 end;
 if FixFile.ReadInteger('info', 'Actions', 0) <= 0 then Exit(3);
 if FixFile.ReadInteger('info', 'TimeWait', 0) < 0 then Exit(4);
 Acts:=FixFile.ReadInteger('info', 'Actions', 1);
 TimeWait:=FixFile.ReadInteger('info', 'TimeWait', 1);
 for i:= 1 to Acts do if FixFile.ReadString('Act'+IntToStr(i), 'Type', 'none') = 'none' then Exit(5);
 //Проверка и загрузка окончена
 Log('Проверка и загрузка окончена успешно, идет выполнение...');
 for i:= 1 to Acts do
  begin
   Log('Действие №'+IntToStr(i)+': '+FixFile.ReadString('Act'+IntToStr(i), 'Info', 'нет описание действия'));
   CMDType:=FixFile.ReadString('Act'+IntToStr(i), 'Type', 'none');
   if CMDType = 'none' then
    begin
     Log('Тип команды №'+IntToStr(i)+' не указан!');
     Exit(6);
    end;
   cmd:=FixFile.ReadString('Act'+IntToStr(i), 'Command', '');
   if CMDType = 'cmd' then WinExec(cmd, SW_HIDE) else
    if CMDType = 'cmdt' then WinExec(cmd, SW_NORMAL) else
     if CMDType = 'msg' then ShowMSG(i) else
      begin
       Log('Тип команды №'+IntToStr(i)+' не распознан!');
       Exit(6);
      end;
   if TimeWait > 0 then Log('Ожидание указанной паузы выполнения ('+IntToStr(TimeWait)+' сек.)');
   Wait(TimeWait);
  end;
 Log('Код исправления выполнен успешно.');
end;

procedure TTweakMachine.OnDblClick(Sender:TObject);
var FN:string;
    MPos:TPoint;
begin
 if not (Sender is TListView) then Exit;
 with (Sender as TListView) do
  begin
   if SelCount <= 0 then Exit;
   MPos:=ScreenToClient(Mouse.CursorPos);
   if (GetItemAt(MPos.X, MPos.Y) = nil) then Exit;
   if Selected = nil then Exit;
   try
    FN:=Selected.SubItems[3];
   except
    Exit;
   end;
   if MessageBox(Application.Handle, PChar('Вы действительно хотите выполнить код исправления'#13#10' "'+Selected.Caption+'"'), 'Внимание', MB_ICONWARNING or MB_YESNO) <> ID_YES then EXIT;
  end;
 case Execute(FN) of
  1:Log('Исправление на выполнено: не существует файл');
  2:Log('Исправление на выполнено: не открывается файл');
  3:Log('Исправление на выполнено: неверное кол-во действий');
  4:Log('Исправление на выполнено: неверное кол-во времени задержки');
  5:Log('Исправление на выполнено: не совпадает кол-во действий');
  6:Log('Исправление на выполнено: ошибка при выполнении команд');
 end;
end;

procedure TTweakMachine.Log(Value:string);
begin
 LogView.Items.Add.Caption:=Value;
end;

procedure TTweakMachine.SetInitDir(Value:string);
begin
 if not Initialize(Value) then Exception.Create('Не могу сменить каталог TweakMachine на "'+Value+'"');
end;

procedure TTweakMachine.Update;
var FixFile:TIniFile;
    FixFiles:TStrings;
    LI:TListItem;
    i:Integer;
begin
 FixFiles:=TStringList.Create;
 ScanDir(FInitDir, '*.fix', FixFiles);
 FListView.Clear;
 if FixFiles.Count <= 0 then Exit;
 FListView.Items.BeginUpdate;
 for i:= 0 to FixFiles.Count - 1 do
  with FListView.Items do
   begin
    if not FileExists(FixFiles[i]) then Continue;
    try
     try
      FixFile:=TIniFile.Create(FixFiles[i]);
      LI:=Add;
      LI.Caption:=FixFile.ReadString('info', 'Name', 'не изветсно');
      LI.SubItems.Add(FixFile.ReadString('info', 'Problem', 'не известно'));
      LI.SubItems.Add(FixFile.ReadString('info', 'Desc', 'не известно'));
      LI.SubItems.Add(FixFile.ReadString('info', 'Actions', 'не известно'));
      LI.SubItems.Add(FixFiles[i]);
      LI.ImageIndex:=17;
      LI.GroupID:=GetGroup(FListView, FixFile.ReadString('info', 'GroupName', 'Нет группы'), False);
     finally
      FreeAndNil(FixFile);
     end;
    except
     CMW.Utils.Log(['Except with - FixFile:=TIniFile.Create(FixFiles[i]);']);
    end;
    Application.ProcessMessages;
    if Stopping then Exit;
   end;
 FListView.Items.EndUpdate;
end;

function TTweakMachine.Initialize(aInitDir:string):Boolean;
begin
 if not System.SysUtils.DirectoryExists(aInitDir) then Exit(False);
 ListView.Clear;
 FInitDir:=aInitDir;
 Result:=True;
end;

constructor TTweakMachine.Create(aInitDir:string; aListView, aLogView:TListView);
begin
 inherited Create;
 if Assigned(aListView) then FListView:=aListView else FListView:=TListView.Create(nil);
 if Assigned(aLogView) then FListLog:=aLogView else FListLog:=TListView.Create(nil);
 if not Initialize(aInitDir) then Exception.Create('Не могу инициализировать TweakMachine в "'+aInitDir+'"');
end;

procedure TFormSmartHND.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 case Key of
  VK_ESCAPE: Close;
 end;
end;

end.
