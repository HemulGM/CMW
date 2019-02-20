unit WinProcesses;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, ExtCtrls, ComCtrls, TLHelp32, PSAPI, COCUtils,
  StructUnit, Winapi.ShellAPI, Vcl.StdCtrls, Vcl.Grids, Vcl.ValEdit;

type
  TFormProcess = class(TForm)
    ValueListEditorProc: TValueListEditor;
    EditProcDesc: TEdit;
    Panel1: TPanel;
    Bevel1: TBevel;
    ButtonClose: TButton;
    EditProcName: TEdit;
    procedure ButtonCloseClick(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  PROCESS_BASIC_INFORMATION = packed record
   Reserved1:UINT64;
   PebBaseAddress:UINT64;
   Reserved2:array[0..1] of UINT64;
   UniqueProcessId:UINT64;
   Reserved3:UINT64;
  end;

  PProcessData = ^TProcessData;
  TProcessData = record
   ProcessID:Cardinal;     //PID
   ProcessName:string;     //Имя процесса
   UseMemory:Cardinal;     //Исп. ОЗУ
   CntThreads:Word;        //Потоков
   ParentPID:Cardinal;     //Родитель
   PriClassB:Integer;      //Приоритет
   ExeCommand:string;      //Команда запуска
   ExePath:string;         //Модуль процесса
   FileDescription:string; //Описание файла модуля
   TimeCreate:TDateTime;   //Время создания процесса
   Dead:Boolean;           //Призрак

   NKTime:Int64;
   OKTime:Int64;
   NUTime:Int64;
   OUTime:Int64;

   CPUUse:Double;          //Использование ЦП
  end;

  TProcIdent = record
   ProcessID:Cardinal;     //PID
   TimeCreate:TDateTime;   //Время создания процесса
  end;

  NTStatus = integer;
  PPROCESS_BASIC_INFORMATION = ^PROCESS_BASIC_INFORMATION;
  TNtQueryInformationProcess = function(ProcessHandle:THandle; ProcessInformationClass:ULONG; ProcessInformation: Pointer; ProcessInformationLength: ULONG; ReturnLength: Pointer): NTStatus; stdcall;
  TNtReadVirtualMemory = function(ProcessHandle:THandle; BaseAddress:UINT64; Buffer:Pointer; BufferLength: UINT64; ReturnLength: Pointer): NTStatus; stdcall;
  TWow64DisableWow64FsRedirection = function():Boolean; stdcall;
  TWow64EnableWow64FsRedirection = function(State:Boolean):Boolean; stdcall;

  TProcessesUnit = class(TSystemUnit)
   private
    FUpdating:Boolean;
    FTreeRoot:TTreeNode;
    FColumnSortW:Integer;
    FIncreasingSortW:Boolean;
    FTreeView:TTreeView;
    FWinList:TListView;
    FDisableIcon:TIcon;
    FDefaultIcon:TIcon;
    FRootIcon:TIcon;
    FOnlyVisableWnd:Boolean;
    FOnlyMainWnd:Boolean;
    FMonitor:Boolean;
    FUpdateThread:TMainThread;
    FTimerMon:TTimer;
    function GetProcesses:Boolean;
    function GetProcessesTV:Boolean;
    function GetOpenWindows:Boolean;
    procedure SetWinList(Value:TListView);
    procedure SetTreeView(Value:TTreeView);
    procedure WinListColumnSortClick(Sender: TObject; Column: TListColumn);
    procedure OnWinListSort;
    procedure ListViewDblClick(Sender: TObject);
    procedure SetWLItemProc(LI:TListItem; Wnd:hWnd);
   public
    t1, t2, t3:Int64;
    function FGet:TGlobalState; override;
    procedure OnChanged; override;
    procedure Initialize; override;
    procedure SetListView(Value:TListView); override;
    procedure ShowInfo;
    procedure ShowProp;
    procedure Update;
    procedure EnableMonitor;
    procedure DisableMonitor;
    function Delete(LI:TListItem):Boolean;
    function DeleteSelected:Boolean;
    function DeleteChecked:Boolean;
    function HardDelete(LI:TListItem):Boolean;
    function HardDeleteSelected:Boolean;
    procedure Stop; override;
    procedure SelectFormUnderMouse;
    constructor Create; override;
    destructor Destroy; override;
    property MonitorIsEnable:Boolean read FMonitor;
    property DisableIcon:TIcon read FDisableIcon write FDisableIcon;
    property DefaultIcon:TIcon read FDefaultIcon write FDefaultIcon;
    property RootIcon:TIcon read FRootIcon write FRootIcon;
    property TreeView:TTreeView read FTreeView write SetTreeView;
    property WinList:TListView read FWinList write SetWinList;
    property OnlyVisableWnd:Boolean read FOnlyVisableWnd write FOnlyVisableWnd;
    property OnlyMainWnd:Boolean read FOnlyMainWnd write FOnlyMainWnd;
  end;

const
  ProcessBasicInformation = 0;

  siPID     = 0;
  siCPU     = 1;
  siMem     = 2;
  siThreads = 3;
  siPPID    = 4;
  siPri     = 5;
  siCmd     = 6;
  //siExe     = 7;
  siDesc    = 7;
  siTime    = 8;

var
  FormProcess: TFormProcess;
  NtQueryInformationProcess:TNtQueryInformationProcess;
  NtReadVirtualMemory:TNtReadVirtualMemory;
  Wow64DisableWow64FsRedirection:TWow64DisableWow64FsRedirection;
  Wow64EnableWow64FsRedirection:TWow64EnableWow64FsRedirection;
  hLibrary, Kernel32:HMODULE;
  IT, KT, UT:TFileTime;
  ITo, KTo, UTo:TFileTime;
  SysCPUDelta:Extended;

 function GetProcessPrioriName(Value:Integer):string;
 function AddCurrentProcessPrivilege(PrivilegeName: WideString): Boolean;
 function TerminateProcessID(PID:Cardinal):Boolean;
 function TerminateProcessIHandle(HND:THandle):Boolean;
 function GetCmdLineProc(ProcHND:THandle):string;
 function GetProcessData(PE:TProcessEntry32; hProcess:THandle):TProcessData;
 function GetProcessMiniData(PE:TProcessEntry32; hProcess:THandle):TProcessData;
 function SysProcessTerminatePID(dwPID:Cardinal):Boolean;
 function GetProcTimeCreate(hProcess:THandle):TDateTime;
 function SysProcessTerminateHandle(HND:THandle):Boolean;
 procedure SetItemData(LI:TListItem; PData:TProcessData);
 function FindPIDLV(LV:TListView; PID:Cardinal):Integer;
 function FindPIDTV(TV:TTreeView; PID:Cardinal):Integer;
 procedure SelectProcByPID(LV:TListView; PID:integer); overload;
 function SelectProcByCMD(LV:TListView; CMD:string):Boolean;
 procedure SelectWndByPID(LV:TListView; PID:integer);
 function SelectProcByPID(TV:TTreeView; PID:integer):Boolean; overload;
 function GetProcessName(PID:Integer):string;
 procedure UpdateItemProc(LI:TListItem; PE:TProcessEntry32; hP:THandle);
 procedure SetItemProc(LI:TListItem; PE:TProcessEntry32; hP:THandle);
 function ProcessExists(PID:Cardinal):Boolean;
 procedure ShowProc(PD:TProcessData);

implementation
 uses Vcl.ImgList, OSInfo, Utils;

{$R *.dfm}

procedure ShowProc(PD:TProcessData);
var Old:Integer;
begin
 with FormProcess, PD do
  begin
   { ProcessID:Cardinal;     //PID
   ProcessName:string;     //Имя процесса
   UseMemory:Cardinal;     //Исп. ОЗУ
   CntThreads:Word;        //Потоков
   ParentPID:Cardinal;     //Родитель
   PriClassB:Integer;      //Приоритет
   ExeCommand:string;      //Команда запуска
   ExePath:string;         //Модуль процесса
   FileDescription:string; //Описание файла модуля
   TimeCreate:TDateTime;   //Время создания процесса
   Dead:Boolean;           //Призрак}
   ValueListEditorProc.Strings.Clear;
   AddToValueEdit(ValueListEditorProc, 'PID', Format('%d', [ProcessID]), '');
   AddToValueEdit(ValueListEditorProc, 'Имя процесса', Format('%s', [ProcessName]), '');
   AddToValueEdit(ValueListEditorProc, 'Исп. ОЗУ', Format('%d КБайт', [UseMemory div 1024]), '');
   AddToValueEdit(ValueListEditorProc, 'Потоков', Format('%d', [CntThreads]), '');
   AddToValueEdit(ValueListEditorProc, 'Родитель', Format('%d', [ParentPID]), '');
   AddToValueEdit(ValueListEditorProc, 'Приоритет', Format('%s', [GetProcessPrioriName(PriClassB)]), '');
   AddToValueEdit(ValueListEditorProc, 'Команда запуска', Format('%s', [ExeCommand]), '');
   AddToValueEdit(ValueListEditorProc, 'Модуль процесса', Format('%s', [ExePath]), '');
   AddToValueEdit(ValueListEditorProc, 'Описание файла модуля', Format('%s', [FileDescription]), '');
   AddToValueEdit(ValueListEditorProc, 'Время создания процесса', FormatDateTime('DD.MM.YYYY HH:MM:SS:ZZZ', TimeCreate), '');
   AddToValueEdit(ValueListEditorProc, 'Убит', Format('%s', [BoolStr(Dead, 'Да', 'Нет')]), '');

   if ValueListEditorProc.Strings.Count * ValueListEditorProc.RowHeights[0] + 6 <= 400 then
    ValueListEditorProc.Height:=ValueListEditorProc.Strings.Count * ValueListEditorProc.RowHeights[0] + 6
   else ValueListEditorProc.Height:=400;
   Old:=ValueListEditorProc.Height;
   ClientHeight:=ValueListEditorProc.Top + ValueListEditorProc.Height + 60;
   ValueListEditorProc.Height:=Old+10;
   EditProcDesc.Text:=FileDescription;
   EditProcName.Text:=Format('%d:%s', [ProcessID, ProcessName]);
   ShowModal;
  end;
end;

function ProcessExists(PID:Cardinal):Boolean;
var hSnap:THandle;
    PE:TProcessEntry32;
begin
 Result:=False;
 PE.dwSize:=SizeOf(TProcessEntry32);
 hSnap:=CreateToolhelp32Snapshot(TH32CS_SNAPALL, 0); //TH32CS_SNAPPROCESS
 if Process32First(hSnap, PE) then
  repeat
   if PE.th32ProcessID = PID then Exit(True);
  until not(Process32Next(hSnap, PE));
 CloseHandle(hSnap);
end;

procedure TProcessesUnit.SetListView(Value:TListView);
begin
 inherited;
 FListView.OnDblClick:=ListViewDblClick;
end;

procedure TProcessesUnit.EnableMonitor;
begin
 if FMonitor then Exit;
 if FUpdateThread = nil then Exit;
 FUpdateThread.Enable:=True;
 FTimerMon.OnTimer(nil);
 FTimerMon.Enabled:=True;
 FMonitor:=True;
end;

procedure TProcessesUnit.DisableMonitor;
begin
 FMonitor:=False;
 FUpdateThread.Enable:=False;
 FTimerMon.Enabled:=False;
end;

procedure TProcessesUnit.Update;
begin
 if FUpdating then Exit;
 FUpdating:=True;
 if GetProcesses then //Inform(LangText(-1, 'Список запущеннх процессов получен.'));
  begin
   GetProcessesTV;// then //Inform(LangText(-1, 'Дерево запущеннх процессов построено.'));
   GetOpenWindows;//
  end;
 OnChanged;
 FUpdating:=False;
end;

procedure TProcessesUnit.ListViewDblClick(Sender: TObject);
begin
 ShowInfo;
end;

procedure TProcessesUnit.ShowInfo;
begin
 if FListView.Selected = nil then Exit;
 if FListView.Selected.Data = nil then Exit;
 ShowProc(TProcessData(FListView.Selected.Data^));
end;

procedure TProcessesUnit.ShowProp;
begin
 if FListView.Selected = nil then Exit;
 if FListView.Selected.Data = nil then Exit;
 try
  if TProcessData(FListView.Selected.Data^).ExePath = '' then Exit;
  ShowPropertiesDialog(TProcessData(FListView.Selected.Data^).ExePath);
 except
  Log(['if TProcessData(FListView.Selected.Data^).ExePath = '' then Exit; ShowPropertiesDialog(TProcessData(FListView.Selected.Data^).ExePath);']);
 end;
end;

procedure TProcessesUnit.SetTreeView(Value:TTreeView);
begin
 if Assigned(FTreeView) then FTreeView.Free;
 FTreeView:=Value;
end;

procedure TProcessesUnit.SetWinList(Value:TListView);
begin
 if Assigned(FWinList) then FWinList.Free;
 FWinList:=Value;
 FWinList.OnColumnClick:=WinListColumnSortClick;
end;

procedure TProcessesUnit.WinListColumnSortClick(Sender: TObject; Column: TListColumn);
begin
 if Column.Index - 1 = FColumnSortW then FIncreasingSortW:=not FIncreasingSortW
 else FColumnSortW:=Column.Index - 1;
 OnWinListSort;
end;

procedure TProcessesUnit.OnWinListSort;
begin
 if FIncreasingSortW then FWinList.Tag:=0 else FWinList.Tag:=1;
 FWinList.CustomSort(@CustomUniSortProc, FColumnSortW);
end;

procedure TProcessesUnit.Initialize;
begin
 ListView.Clear;
 ListView.SmallImages:=TImageList.CreateSize(16, 16);
 ListView.SmallImages.ColorDepth:=cd32Bit;

 ListView.SmallImages.AddIcon(DisableIcon);
 ListView.SmallImages.AddIcon(RootIcon);
 ListView.SmallImages.AddIcon(DefaultIcon);

 FWinList.Items.Clear;
 FWinList.SmallImages:=ListView.SmallImages;

 FTreeView.Items.Clear;
 FTreeView.Images:=ListView.SmallImages;

 FTreeRoot:=FTreeView.Items.AddFirst(nil, 'Дерево процессов');
 FTreeRoot.ImageIndex:=1;
 FTreeRoot.SelectedIndex:=1;
 FTreeRoot.Expanded:=True;
end;



constructor TProcessesUnit.Create;
begin
 inherited;
 t1:=0;
 t2:=0;
 t3:=0;
 FColumnSortW:=-1;
 FIncreasingSortW:=True;
 FColumnSort:=0;
 FMonitor:=False;

 FWinList:=TListView.Create(nil);
 with FWinList do
  begin
   Name:='FWinList';
   OnColumnClick:=WinListColumnSortClick;
  end;
 FTreeView:=TTreeView.Create(nil);
 with FTreeView do
  begin
   Name:='FTreeView';
  end;
 FUpdateThread:=TMainThread.Create(False);
 with FUpdateThread do
  begin
   FUpdateThread.Proc:=Update;
   FUpdateThread.Priority:=tpLowest;
  end;
 FTimerMon:=TTimer.Create(nil);
 with FTimerMon do
  begin
   Name:='FTimerMon';
   Enabled:=False;
   Interval:=2000;
   OnTimer:=FUpdateThread.ExecuteUpdate;
  end;
end;

destructor TProcessesUnit.Destroy;
begin
 inherited;
end;

procedure TProcessesUnit.SelectFormUnderMouse;
var UMHWND, ParentUMHWND:HWND;
    buf1, buf2:array[0..512] of Char;
 function Informer(H:HWND):Boolean;
 var i:Word;
 begin
  GetClassName(H, buf1, MAX_PATH+1);
  GetWindowText(H, buf2, MAX_PATH+1);
  Inform('Handle под курсором: '+IntToStr(H)+', класс "'+StrPas(buf1)+'", заголовок "'+StrPas(buf2)+'"');
  for i:= 0 to FWinList.Items.Count - 1 do
   begin
    FWinList.Items[i].Selected:=HWND(FWinList.Items[i].Data^) = H;
   end;
  if FWinList.Selected <> nil then
   begin
    FWinList.Selected.MakeVisible(True);
    FWinList.OnClick(nil);
    Exit(True);
   end;
  Result:=False;
 end;
begin
 UMHWND:=WindowFromPoint(Mouse.CursorPos);
 if UMHWND = 0 then
  begin
   Inform('Под курсором пусто, либо нет досутпа к дескриптору');
   Exit;
  end;
 if Informer(UMHWND) then Exit;

 ParentUMHWND:=GetParent(UMHWND);
 if ParentUMHWND <> 0 then Informer(ParentUMHWND);
end;

function TProcessesUnit.HardDeleteSelected:Boolean;
begin
 if ListView.Selected = nil then Exit(False);
 Result:=HardDelete(ListView.Selected);
end;

function TProcessesUnit.HardDelete(LI:TListItem):Boolean;
var PID:Integer;
    FID:Integer;
begin
 if LI = nil then Exit(False);
 if LI.Data = nil then Exit(False);
 PID:=TProcessData(LI.Data^).ProcessID;
 Result:=SysProcessTerminatePID(PID);
 if Result then
  begin
   try
    FID:=FindPIDLV(FWinList, PID);
    if FID >= 0 then FWinList.Items[FID].Delete;
   except
    Log(['Не смог удалить элемент процесса из cписка окон']);
   end;
   try
    FID:=FindPIDTV(FTreeView, PID);
    if FID >= 0 then FTreeView.Items[FID].Delete;
   except
    Log(['Не смог удалить элемент процесса из дерева процессов']);
   end;
   try
    LI.Delete;
   except
    Log(['Не смог удалить элемент процесса из списка процессов']);
   end;
  end;
end;

function TProcessesUnit.DeleteSelected:Boolean;
begin
 if ListView.Selected = nil then Exit(False);
 Result:=Delete(ListView.Selected);
end;

function TProcessesUnit.DeleteChecked:Boolean;
var i:Word;
begin
 i:=0;
 repeat
  try
   if ListView.Items[i].Checked then
    begin
     Delete(ListView.Items[i]);
     Continue;
    end;
  except

  end;
  Inc(i);
 until (ListView.Items.Count <= 0) or (i = ListView.Items.Count - 1);
 Result:=True;
end;

function TProcessesUnit.Delete(LI:TListItem):Boolean;
var PID:Integer;
    FID:Integer;
begin
 if LI = nil then Exit(False);
 if LI.Data = nil then Exit(False);
 PID:=TProcessData(LI.Data^).ProcessID;
 Result:=TerminateProcessID(PID);
 if Result then
  begin
   try
    FID:=FindPIDLV(FWinList, PID);
    if FID >= 0 then FWinList.Items[FID].Delete;
   except
    Log(['Не смог удалить элемент процесса из cписка окон']);
   end;
   try
    FID:=FindPIDTV(FTreeView, PID);
    if FID >= 0 then FTreeView.Items[FID].Delete;
   except
    Log(['Не смог удалить элемент процесса из дерева процессов']);
   end;
   try
    LI.Delete;
   except
    Log(['Не смог удалить элемент процесса из списка процессов']);
   end;
  end;
end;

procedure TProcessesUnit.OnChanged;
begin
 inherited;
 OnListViewSort;
 OnWinListSort;
end;

procedure TProcessesUnit.Stop;
begin
 inherited;
 DisableMonitor;
end;

function TProcessesUnit.FGet:TGlobalState;
var Rsm:Boolean;
begin
 if FMonitor then
  begin
   Rsm:=True;
   DisableMonitor;
  end
 else Rsm:=False;
 while FUpdating do Application.ProcessMessages;

 Result:=gsNone;
 Inform(LangText(-1, 'Построение списка запущенных процессов...'));

 FListView.Items.BeginUpdate;
 FListView.Items.Clear;

 FWinList.Items.BeginUpdate;
 FWinList.Items.Clear;
 FWinList.Items.EndUpdate;

 FTreeView.Items.BeginUpdate;
 FTreeView.Items.Clear;
 FTreeRoot:=FTreeView.Items.AddFirst(nil, 'Дерево процессов');
 FTreeRoot.ImageIndex:=1;
 FTreeRoot.SelectedIndex:=1;
 FTreeView.Items.EndUpdate;

 try
  Update;
 except
  Exit(gsError);
 end;

 if Rsm then EnableMonitor;
 OnChanged;
 try
  Inform(LangText(-1, 'Список процессов получен.'));
  Result:=gsFinished;
 except
  Exit;
 end;
end;

procedure TProcessesUnit.SetWLItemProc(LI:TListItem; Wnd:hWnd);
var buff:array[0..1023] of Char;
    pProcID:DWORD;
    Icon:TIcon;
    LIP:Integer;
    NoText:Boolean;
begin
 LI.Data:=AllocMem(SizeOf(HWND));
 HWND(LI.Data^):=Wnd;
 FillChar(buff, GetWindowTextLength(Wnd)+1, #0);
 GetWindowText(Wnd, buff, GetWindowTextLength(Wnd)+1);
 LI.Caption:=StrPas(buff);
 GetClassName(Wnd, buff, MAX_PATH+1);
 if LI.Caption <> '' then LI.Caption:=LI.Caption+' ';
 LI.Caption:=LI.Caption+StrPas(buff);
 NoText:=False;
 if LI.Caption.Length <= 0 then
  begin
   LI.Caption:=Format('Нет заголовка (%d)', [Wnd]);
   NoText:=True;
  end;
 GetWindowThreadProcessId(Wnd, @pProcID);
 while LI.SubItems.Count < 1 do LI.SubItems.Add('');

 LI.SubItems[0]:=(Format('%d', [pProcID]));
 //ListItem.GroupID:=GetGroup(FWinList, GetProcessName(pProcID)+'('+ListItem.SubItems[0]+')', False);

 LIP:=FindPIDLV(ListView, pProcID);
 if Stopping then Exit;
 if LIP >= 0 then
  begin
   if NoText then
    begin
     //ListItem.Caption:=GetFileNameWoE(FormMain.ListViewProc.Items[LIP].Caption);
     if TProcessData(ListView.Items[LIP].Data^).FileDescription <> '' then
      LI.Caption:=TProcessData(ListView.Items[LIP].Data^).FileDescription;
    end;
   LI.ImageIndex:=ListView.Items[LIP].ImageIndex;
  end;
 if LI.ImageIndex < 0 then
  begin
   Icon:=TIcon.Create;
   Icon.Handle:=CopyIcon(GetClassLong(Wnd, GCL_HICON));
   LI.ImageIndex:=FWinList.SmallImages.AddIcon(Icon);
   FreeAndNil(Icon);
  end;
 LI.Caption:=LI.Caption +' - '+ BoolStr(IsWindowVisible(Wnd), 'Вид.', 'Не вид.')+ ' - '+BoolStr(GetWindow(Wnd, GW_OWNER) <> 0, 'Не глав.', 'Глав.');
end;

function TProcessesUnit.GetOpenWindows:Boolean;
var Wnd:hWnd;
    ListItem:TListItem;
    LID:Integer;

function CheckList:Integer;
var i:Word;
begin
 if FWinList.Items.Count <=0 then Exit(-1);

 for i:=0 to FWinList.Items.Count - 1 do
  begin
   if HWND(FWinList.Items[i].Data^) = Wnd then Exit(i);
  end;
 Result:=-1;
end;

procedure ClearDead;
var i:Word;
begin
 if FWinList.Items.Count <=0 then Exit;
 i:=0;
 repeat
  begin
   if not IsWindow(HWND(FWinList.Items[i].Data^)) then
    begin
     FWinList.Items[i].Delete;
     Continue;
    end;
   Inc(i);
  end;
 until i = FWinList.Items.Count;
end;

begin
 //FWinList.Groups.Clear;
 //FWinList.GroupView:=True;
 Wnd:=GetWindow(Application.Handle, GW_HWNDFIRST);
 while Wnd <> 0 do
  begin
   if Stopping then Exit(False);
   if (not (FOnlyVisableWnd and (not IsWindowVisible(Wnd))) and
      (not (FOnlyMainWnd    and (GetWindow(Wnd, GW_OWNER) <> 0))))
   then
    begin
     with FWinList.Items do
      begin
       LID:=CheckList;
       if LID >= 0 then SetWLItemProc(FWinList.Items[LID], Wnd)
       else
        begin
         ListItem:=Add;
         ListItem.ImageIndex:=-1;
         SetWLItemProc(ListItem, Wnd);
        end;
      end;
    end;
   Wnd:=GetWindow(Wnd, GW_HWNDNEXT);
  end;
 ClearDead;
 Result:=True;
end;

function TProcessesUnit.GetProcessesTV:Boolean;
var Node:TTreeNode;
    i, Prnt:Integer;


function FindChild(LI:TListItem; Node:TTreeNode):TTreeNode;
var c:Integer;
    ND:TTreeNode;
begin
 for c:= 0 to FListView.Items.Count - 1 do
  begin
   if Stopping then Exit(nil);
   if FListView.Items[c].SubItems[siPID] = '0' then Continue;
   if LI.SubItems[0] = FListView.Items[c].SubItems[siPPID] then   //Нашли дочерний процесс
    begin
     //Log(['Добавим дочерний', FListView.Items[c].Caption]);
     if TProcessData(LI.Data^).TimeCreate > TProcessData(FListView.Items[c].Data^).TimeCreate then Continue;{ else
      if TProcessData(LI.Data^).TimeCreate <= TProcessData(ListView.Items[c].Data^).TimeCreate then
       if TProcessData(LI.Data^).TimeCreate > TProcessData(ListView.Items[c].Data^).TimeCreate.dwLowDateTime then Continue;}
     ND:=FTreeView.Items.AddChild(Node, FListView.Items[c].Caption);
     ND.Data:=FListView.Items[c].Data;
     ND.ImageIndex:=FListView.Items[c].ImageIndex;
     ND.StateIndex:=FListView.Items[c].ImageIndex;
     ND.SelectedIndex:=FListView.Items[c].ImageIndex;
     FindChild(FListView.Items[c], ND);
    end;
  end;
 Result:=nil;
end;

function HaveParent(LI:TListItem):Boolean;
var p:Word;
begin
 if TProcessData(FListView.Items[i].Data^).ProcessID = TProcessData(FListView.Items[i].Data^).ParentPID then Exit(False); //Сам себе родитель
 for p:= 0 to FListView.Items.Count - 1 do
  begin
   if TProcessData(FListView.Items[p].Data^).Dead then Continue;
   if TProcessData(FListView.Items[p].Data^).ProcessID = TProcessData(LI.Data^).ProcessID then Continue; //один и тот же элемент
   if TProcessData(FListView.Items[p].Data^).ProcessID = TProcessData(LI.Data^).ParentPID then
    begin
     //Если якобы дочерний процесс старше родительского, то пропускаем
     if TProcessData(LI.Data^).TimeCreate < TProcessData(FListView.Items[p].Data^).TimeCreate then Continue;
     //А так норм
     Exit(True);
    end;
  end;
 Result:=False;
end;

function AlreadyHaveTItem:Integer;
var t:Word;
begin
 if FTreeView.Items.Count <= 0 then Exit(-1);
 for t:=0 to FTreeView.Items.Count - 1 do
  begin
   if FTreeView.Items[t].Data = nil then Continue;
   if TProcessData(FTreeView.Items[t].Data^).Dead then Continue;
   if TProcessData(FTreeView.Items[t].Data^).ProcessID = TProcessData(FListView.Items[i].Data^).ParentPID then Exit(t);
  end;
 Result:=-1;
end;

function CheckList:Integer;
var t:Word;
begin
 if FTreeView.Items.Count <= 0 then Exit(-1);
 for t:=0 to FTreeView.Items.Count - 1 do
  begin
   if FTreeView.Items[t].Data = nil then Continue;
   if i < FListView.Items.Count then
    begin
     if FListView.Items[i].Data = nil then Continue;
     if TProcessData(FTreeView.Items[t].Data^).ProcessID = TProcessData(FListView.Items[i].Data^).ProcessID then
      begin
       //Log(['Уже есть -', FListView.Items[i].Caption]);
       Exit(t);
      end;
    end;
  end;
 Result:=-1;
end;

procedure ClearDead;
var d:Word;
begin
 if FTreeView.Items.Count <= 0 then Exit;
 d:=0;
 repeat
  begin
   if FTreeView.Items[d].Level <= 0  then
    begin
     Inc(d);
     Continue;
    end;
   if FTreeView.Items[d].Data = nil then
    begin
     FTreeView.Items[d].Delete;
     Continue;
    end
   else
    if TProcessData(FTreeView.Items[d].Data^).Dead then
     begin
      FTreeView.Items[d].Delete;
      Continue;
     end;
   Inc(d);
  end;
 until d = FTreeView.Items.Count;
end;

begin
 //Log(['-------------------------']);
 if FListView.Items.Count > 0 then
  begin
   if not FTreeRoot.Expanded then FTreeRoot.Expanded:=True;

   for i:= 0 to FListView.Items.Count - 1 do
    begin
     //Log([FListView.Items[i].Caption]);
     if TProcessData(FListView.Items[i].Data^).Dead then Continue;

     if CheckList >= 0 then
      begin
       //Log(['Уже есть. Пропускаем.']);
       Continue;
      end;
     if Stopping then Exit(False);
     if not HaveParent(FListView.Items[i]) then
      begin
       //Log(['Новый. Добавим в корень']);
       Node:=FTreeView.Items.AddChild(FTreeRoot, FListView.Items[i].Caption);

       Node.Data:=FListView.Items[i].Data;
       Node.ImageIndex:=FListView.Items[i].ImageIndex;
       Node.StateIndex:=FListView.Items[i].ImageIndex;
       Node.SelectedIndex:=FListView.Items[i].ImageIndex;
       FindChild(FListView.Items[i], Node);
      end
     else
      begin
       Prnt:=AlreadyHaveTItem;
       if Prnt >= 0 then
        begin
         //Log(['Новый. Добавим к ', FTreeView.Items[Prnt].Text]);

         Node:=FTreeView.Items.AddChild(FTreeView.Items[Prnt], FListView.Items[i].Caption);

         Node.Data:=FListView.Items[i].Data;
         Node.ImageIndex:=FListView.Items[i].ImageIndex;
         Node.StateIndex:=FListView.Items[i].ImageIndex;
         Node.SelectedIndex:=FListView.Items[i].ImageIndex;
         FindChild(FListView.Items[i], Node);
        end;
      end;
    end;
  end;
 ClearDead;
 //Log(['-------------------------']);
 Result:=True;
end;

function TProcessesUnit.GetProcesses:Boolean;
var hSnap:THandle;
    PE:TProcessEntry32;
    TC:TDateTime;
    hProcess:THandle;
    LID:Integer;


function CheckList:Integer;
var i:Word;
begin
 if ListView.Items.Count <=0 then Exit(-1);

 for i:=0 to ListView.Items.Count - 1 do
  begin
   if ListView.Items[i].Data = nil then Continue;
   if Stopping then Exit(-1);
   if TProcessData(ListView.Items[i].Data^).ProcessID = PE.th32ProcessID then
    if TProcessData(ListView.Items[i].Data^).TimeCreate = TC then Exit(i);
  end;
 Result:=-1;
end;

procedure ClearDead;
var i:Word;
begin
 if ListView.Items.Count <= 0 then Exit;
 i:=0;
 repeat
  if i >= FListView.Items.Count then Break;
  if FListView.Items[i].Data = nil then Continue;
  if not ProcessExists(TProcessData(ListView.Items[i].Data^).ProcessID) then
   begin
    TProcessData(ListView.Items[i].Data^).Dead:=True;
    if ListView.Items[i].SubItems[siPID] <> 'DEAD' then
     begin
      ListView.Items[i].SubItems[siPID]:='DEAD';
     end;
    //ListView.Items[i].Delete;
    //Continue;
   end;
  Inc(i);
 until i = ListView.Items.Count;
end;

begin
 Result:=False;
 //Расчет использования процессорного времени
 Winapi.Windows.GetSystemTimes(IT, KT, UT);
 t1:=Abs(CompareFileTimeOwn(ITo, IT));
 t2:=Abs(CompareFileTimeOwn(UTo, UT));
 t3:=Abs(CompareFileTimeOwn(KTo, KT));
 ITo:=IT;
 KTo:=KT;
 UTo:=UT;
 SysCPUDelta:=Abs(t3 + t2{ - t1});  //---
 //------------------------------------------
 hSnap:=CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
 PE.dwSize:=SizeOf(TProcessEntry32);
 if Process32First(hSnap, PE) then
  repeat
   hProcess:=OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, PE.th32ProcessID);
   TC:=GetProcTimeCreate(hProcess);

   LID:=CheckList;
   if LID >= 0 then UpdateItemProc(ListView.Items[LID], PE, hProcess)
   else SetItemProc(ListView.Items.Add, PE, hProcess);
   CloseHandle(hProcess);
   //OnChanged;
   //CloseHandle(hProcess);
   //ListItem:=TListItem.Create();
   if Stopping then Exit(False);
   //GetProccessItem(PE, ListItem);

   //Код сеанса
   //ProcessIdToSessionId(PE.Th32ProcessID, SID);
   //ListItem.SubItems.Add(IntToStr(SID));
  until not (Process32Next(hSnap, PE));
 ClearDead;
 Result:=True;
end;

function SelectProcByPID(TV:TTreeView; PID:integer):Boolean;
var ID:Integer;
begin
 Result:=True;
 ID:=FindPIDTV(TV, PID);
 if ID < 0 then Exit(False);
 TV.Selected:=TV.Items[ID];
end;

procedure SelectWndByPID(LV:TListView; PID:integer);
var i:Integer;
begin
 if LV.Items.Count <= 0 then Exit;
 for i:= 0 to LV.Items.Count - 1 do
  begin
   LV.Items[i].Selected:=LV.Items[i].SubItems[siPID] = IntToStr(PID);
  end;
 if LV.Selected <> nil then LV.Selected.MakeVisible(True);
end;

procedure SelectProcByPID(LV:TListView; PID:integer);
var i:Integer;
begin
 if LV.Items.Count <= 0 then Exit;
 for i:= 0 to LV.Items.Count - 1 do
  begin
   LV.Items[i].Selected:=LV.Items[i].SubItems[siPID] = IntToStr(PID);
  end;
 if LV.Selected <> nil then LV.Selected.MakeVisible(True);
end;

function SelectProcByCMD(LV:TListView; CMD:string):Boolean;
var i:Integer;
begin
 Result:=False;
 if LV.Items.Count <= 0 then Exit;
 for i:= 0 to LV.Items.Count - 1 do
  begin
   LV.Items[i].Selected:=DeleteStrQM(AnsiLowerCase(LV.Items[i].SubItems[siCmd])) = DeleteStrQM(AnsiLowerCase(CMD));
   if not Result then if LV.Items[i].Selected then Result:=True;
  end;
 if LV.Selected <> nil then LV.Selected.MakeVisible(True);
end;

function FindPIDLV(LV:TListView; PID:Cardinal):Integer;
var i:Word;
begin
 Result:=-1;
 if LV.Items.Count <= 0 then Exit;
 for i:= 0 to LV.Items.Count -1 do
  begin
   if LV.Items[i].Data = nil then Continue;
   if TProcessData(LV.Items[i].Data^).ProcessID = PID then Exit(i);
  end;
end;

function FindPIDTV(TV:TTreeView; PID:Cardinal):Integer;
var i:Word;
begin
 Result:=-1;
 if TV.Items.Count <= 0 then Exit;
 for i:= 0 to TV.Items.Count -1 do
  begin
   if TV.Items[i].Data = nil then Continue;
   if TProcessData(TV.Items[i].Data^).ProcessID = PID then Exit(i);
  end;
end;
            {
procedure GetProcInfo(LI:TListItem; TC:TFileTime);
var PI:TProcInfo;
    PPI:PProcInfo;
begin
 PI.PID:=LI.SubItems[0];
 PI.Name:=LI.Caption;
 PI.PPID:=LI.SubItems[3];
 PI.TimeCreate:=TC;
 PPI:=AllocMem(SizeOf(PI));
 PPI^:=PI;
 LI.Data:=PPI;
end;  }

procedure SetItemData(LI:TListItem; PData:TProcessData);
var PPD:PProcessData;
begin
 PPD:=AllocMem(SizeOf(PData));
 PPD^:=PData;
 LI.Data:=PPD;
end;

function SysProcessTerminateHandle(HND:THandle):Boolean;
var hToken:THandle;
    SeDebugNameValue:Int64;
    Token:TOKEN_PRIVILEGES;
    ReturnLength, Er:Cardinal;
begin
 Result:=False;
 if not OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, hToken) then
  begin
   Log(['SysProcessTerminateHandle. not OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, hToken)']);
   Exit;
  end;
 if not LookupPrivilegeValue(nil, 'SeDebugPrivilege', SeDebugNameValue) then
  begin
   Log(['SysProcessTerminateHandle. not LookupPrivilegeValue(nil, SeDebugPrivilege, SeDebugNameValue)']);
   CloseHandle(hToken);
   Exit;
  end;
 Token.PrivilegeCount:=1;
 Token.Privileges[0].Luid:=SeDebugNameValue;
 Token.Privileges[0].Attributes:=SE_PRIVILEGE_ENABLED;
 AdjustTokenPrivileges(hToken, False, Token, SizeOf(Token), Token, ReturnLength);
 Er:=GetLastError;
 if Er <> ERROR_SUCCESS then
  begin
   ShowMessage(SysErrorMessage(Er));
   Log(['SysProcessTerminateHandle. AdjustTokenPrivileges(hToken, False, Token, SizeOf(Token), Token, ReturnLength)']);
   Exit;
  end;
 if HND = 0 then
  begin
   Log(['SysProcessTerminateHandle. HND = 0']);
   Exit;
  end;
 {if not TerminateProcess(HND, DWORD(-1)) then
  begin
   Log(['SysProcessTerminateHandle.  not TerminateProcess(HND, DWORD(-1))']);
   Exit;
  end;  }
 CloseHandle(HND);
 Token.Privileges[0].Attributes:=0;
 AdjustTokenPrivileges(hToken, False, Token, SizeOf(Token), Token, ReturnLength);
 Er:=GetLastError;
 if Er <> ERROR_SUCCESS then
  begin
   Log(['']);
   Exit;
  end;
 Result:=True;
end;

function GetProcessName(PID:Integer):string;
var hProcess: THandle;
    hMod: HModule;
    needed: DWord;
    ModuleName:array [0..300] of Char;
begin
 hProcess:=OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, FALSE, PID);
 if hProcess <> 0 then
  begin
   EnumProcessModules(hProcess, @hMod, SizeOf(hMod), needed);
   ModuleName:=#0;
   GetModuleFileNameEx(hProcess, hMod, ModuleName, SizeOf(ModuleName));
   Result:=AnsiString(ModuleName);
   CloseHandle(hProcess);
  end
 else Result:= '<нет доступа>';
end;
                 {
function GetProcessName(PID:Integer):string;
var hSnap:THandle;
    PE:TProcessEntry32;
begin
 Result:='';
 PE.dwSize:=SizeOf(TProcessEntry32);
 hSnap:=CreateToolhelp32Snapshot(TH32CS_SNAPALL, 0);
 if Process32First(hSnap, PE) then
  repeat
   if PE.th32ProcessID = PID then
    begin
     Exit(PE.szExeFile);
    end;
  until not(Process32Next(hSnap, PE));
end; }

function SysProcessTerminatePID(dwPID:Cardinal):Boolean;
var hProcess:THandle;
begin
 hProcess:=OpenProcess(PROCESS_TERMINATE, False, dwPID);
 Result:=SysProcessTerminateHandle(hProcess);
 CloseHandle(hProcess);
end;

function GetProcTimeCreate(hProcess:THandle):TDateTime;
var ETime, KTime, UTime, CTime:TFileTime;
begin
 if (hProcess <> 0) then
  begin
   GetProcessTimes(hProcess, CTime, ETime, KTime, UTime);
   Result:=FileTimeToDateTime(CTime);
  end
 else Result:=0;
end;

procedure SetListItemData(LI:TListItem);
begin
 with TProcessData(LI.Data^) do
  begin
   LI.Caption:=ProcessName;
   LI.SubItems[siPID]:=IntToStr(ProcessID);
   LI.SubItems[siThreads]:=IntToStr(CntThreads); //
   LI.SubItems[siCPU]:=Format('%f', [CPUUse]);
   LI.SubItems[siPPID]:=IntToStr(ParentPID);
   LI.SubItems[siPri]:=GetProcessPrioriName(PriClassB);
   LI.SubItems[siCmd]:=ExeCommand;
   LI.SubItems[siMem]:=GetSpacedInt(IntToStr(UseMemory div 1024))+' КБ';
   //LI.SubItems[siExe]:=ExePath;
   LI.SubItems[siTime]:=FormatDateTime('dd.mm.yy hh:mm:ss:zzz', TimeCreate);
   LI.SubItems[siDesc]:=FileDescription;
  end;
end;

function PercentRound(Value:Extended):Extended;
begin
 if Value < 0 then Exit(0) else
  if Value > 100 then Exit(100) else Exit(Value);
end;

procedure UpdateItemProc(LI:TListItem; PE:TProcessEntry32; hP:THandle);
var PD:TProcessData;
    t1, t2:Cardinal;
begin
 if LI.Data = nil then SetItemData(LI, GetProcessData(PE, hP))
 else
  begin
   if TProcessData(LI.Data^).Dead then Exit;
   PD:=GetProcessMiniData(PE, hP);
   TProcessData(LI.Data^).UseMemory:=PD.UseMemory;
   TProcessData(LI.Data^).CntThreads:=PD.CntThreads;
   TProcessData(LI.Data^).PriClassB:=PD.PriClassB;
   TProcessData(LI.Data^).NUTime:=Abs(PD.NUTime);
   TProcessData(LI.Data^).NKTime:=Abs(PD.NKTime);

   t1:=Abs(TProcessData(LI.Data^).NKTime - TProcessData(LI.Data^).OKTime);
   t2:=Abs(TProcessData(LI.Data^).NUTime - TProcessData(LI.Data^).OUTime);
   TProcessData(LI.Data^).OUTime:=TProcessData(LI.Data^).NUTime;
   TProcessData(LI.Data^).OKTime:=TProcessData(LI.Data^).NKTime;
   try                                //
    TProcessData(LI.Data^).CPUUse:=PercentRound(Abs((100 / SysCPUDelta) * (t1+t2)));
   except
    TProcessData(LI.Data^).CPUUse:=0;
   end;
   SetListItemData(LI);
  end;
end;

procedure SetItemProc(LI:TListItem; PE:TProcessEntry32; hP:THandle);
var IconName:String;
    WillLoadIco:Boolean;
begin
 SetItemData(LI, GetProcessData(PE, hP));
 while LI.SubItems.Count < 9 do LI.SubItems.Add('');
 with TProcessData(LI.Data^) do
  begin
   LI.StateIndex:=0;
   LI.ImageIndex:=0;

   WillLoadIco:=True;

   if Length(ExePath) <= 2 then IconName:=ProcessName else IconName:=ExePath;
   if AnsiLowerCase(IconName) = 'system' then
    begin
     IconName:=Info.Sys32+'\ntoskrnl.exe';
     ExePath:=IconName;
     ExeCommand:=IconName;
    end;
   if AnsiLowerCase(IconName) = '[system process]' then
    begin
     ProcessName:='[Корневой процесс]';
     WillLoadIco:=False;
     ExePath:='';
    end;
   NormFileName(IconName);
   if WillLoadIco then
    begin
     if FileExists(IconName) then
      begin
       WillLoadIco:=True;
      end
     else
      if FileExists(Info.Sys32+'\'+IconName) then
       begin
        WillLoadIco:=True;
        IconName:=Info.Sys32+'\'+IconName;
       end
      else
       if FileExists(Info.Sys32+'\'+IconName+'.exe') then
        begin
         WillLoadIco:=True;
         IconName:=Info.Sys32+'\'+IconName+'.exe';
        end
       else WillLoadIco:=False;

     if WillLoadIco then
      begin
       LI.ImageIndex:=GetFileIcon(IconName, is16, TImageList(TListView(LI.Owner.Owner).SmallImages));
       if LI.ImageIndex < 0 then LI.ImageIndex:=2;
       ExePath:=IconName;
      end;
    end;
   FileDescription:=GetFileDescription(IconName, '');
   SetListItemData(LI);
  end;
end;

function GetProcessData(PE:TProcessEntry32; hProcess:THandle):TProcessData;
var hMod:HMODULE;
    cb:DWORD;
    ModuleName:array [0..300] of Char;
    ProcMem:PPROCESS_MEMORY_COUNTERS;
    CTime, ETime, KTime, UTime:TFileTime;
begin
 with Result do
  begin
   ProcessID:=PE.Th32ProcessID;
   ProcessName:=PE.szExeFile;
   CntThreads:=PE.cntThreads;
   ParentPID:=PE.th32ParentProcessID;
   PriClassB:=PE.pcPriClassBase;

   {}TimeCreate:=0;
   {}UseMemory:=0;
   {}CPUUse:=0;
                                                       //Процесс -1
   //hProcess:=OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, PE.th32ProcessID);
   if (hProcess <> 0) then
    begin
     GetProcessTimes(hProcess, CTime, ETime, KTime, UTime);
     {}TimeCreate:=FileTimeToDateTime(CTime);
     NKTime:=FileTimeToInt(KTime);
     NUTime:=FileTimeToInt(UTime);
     OKTime:=NKTime;
     OUTime:=NUTime;
     ///------------------------------------------------------------
     {}ExeCommand:=GetCmdLineProc(hProcess);

     //GetWindowThreadProcessId(hProcess, nil);
     EnumProcessModules(hProcess, @hMod, SizeOf(hMod), cb);
     ModuleName:=#0;
     GetModuleFileNameEx(hProcess, hMod, ModuleName, SizeOf(ModuleName));
     cb:=SizeOf(_PROCESS_MEMORY_COUNTERS);
     GetMem(ProcMem, cb);
     ProcMem^.cb:=cb;
     if GetProcessMemoryInfo(hProcess, ProcMem, cb) then
     {}UseMemory:=ProcMem^.PagefileUsage;
     FreeMem(ProcMem);

     {}ExePath:=NormFileNameF(AnsiString(ModuleName));
     if Length(ExePath) <= 1 then
     {}ExePath:=NormFileNameF(ExeCommand);
    end
   else
    begin
     //Log(['Нет доступа к процессу', StrPas(PE.szExeFile)]);
    end;
  end;
end;

function GetProcessMiniData(PE:TProcessEntry32; hProcess:THandle):TProcessData;
var hMod:HMODULE;
    cb:DWORD;
    ProcMem:PPROCESS_MEMORY_COUNTERS;
    CTime, ETime, KTime, UTime:TFileTime;
begin
 with Result do
  begin
   CntThreads:=PE.cntThreads;
   PriClassB:=PE.pcPriClassBase;

   {}TimeCreate:=0;
   {}UseMemory:=0;
   {}CPUUse:=0;

   //hProcess:=OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, PE.th32ProcessID);
   if (hProcess <> 0) then
    begin
     GetProcessTimes(hProcess, CTime, ETime, KTime, UTime);
     {}TimeCreate:=FileTimeToDateTime(CTime);
     NKTime:=FileTimeToInt(KTime);
     NUTime:=FileTimeToInt(UTime);
     //GetWindowThreadProcessId(hProcess, nil);
     EnumProcessModules(hProcess, @hMod, SizeOf(hMod), cb);
     cb:=SizeOf(_PROCESS_MEMORY_COUNTERS);
     GetMem(ProcMem, cb);
     ProcMem^.cb:=cb;
     if GetProcessMemoryInfo(hProcess, ProcMem, cb) then
     {}UseMemory:=ProcMem^.PagefileUsage;
     FreeMem(ProcMem);
    end;
  end;
end;

function GetCmdLineProc(ProcHND:THandle):string;
var PBI: PROCESS_BASIC_INFORMATION;
    ReturnLength: UINT64;
    Buffer: UINT64;
    Data:array[0..1023] of Char;
begin
 Result:='';
 if NtQueryInformationProcess(ProcHND, 0, @PBI, SizeOf(PBI), nil) = 0 then
  begin
   if NtReadVirtualMemory(ProcHND, PBI.PebBaseAddress + $20, @Buffer, SizeOf(Buffer), @ReturnLength) = 0 then
    begin
     if NtReadVirtualMemory(ProcHND, Buffer + $78, @Buffer, SizeOf(Buffer), @ReturnLength) = 0 then
      begin
       if NtReadVirtualMemory(ProcHND, Buffer, @Data, SizeOf(Data), @ReturnLength) = 0 then
        begin
         Result:=StrPas(Data);
        end
       else Log(['Step 3: NtReadVirtualMemory(ProcHND, Buffer, @Data, SizeOf(Data), @ReturnLength) is fail', ProcHND]);
      end
     else Log(['Step 2: NtReadVirtualMemory(ProcHND, Buffer + $78, @Buffer, SizeOf(Buffer), @ReturnLength) is fail', ProcHND]);
    end
   else Log(['Step 1: NtReadVirtualMemory(ProcHND, PBI.PebBaseAddress + $20, @Buffer, SizeOf(Buffer), @ReturnLength) is fail', ProcHND]);
  end
 else Log(['Step 0: NtQueryInformationProcess(ProcHND, 0, @PBI, SizeOf(PBI), nil) is fail', ProcHND]);
end;

function TerminateProcessID(PID:Cardinal):Boolean;
var HND:THandle;
begin
 HND:=OpenProcess(PROCESS_TERMINATE, False, PID);
 Result:=TerminateProcess(HND, 0);
 CloseHandle(HND);
end;

function TerminateProcessIHandle(HND:THandle):Boolean;
begin
 Result:=TerminateProcess(HND, 0);
end;

function AddCurrentProcessPrivilege(PrivilegeName: WideString): Boolean;
var
 TokenHandle: THandle;
 TokenPrivileges: TTokenPrivileges;
 ReturnLength: Cardinal;
begin
 Result:=False;
 if OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, TokenHandle) then
  begin
   try
    LookupPrivilegeValueW(nil, PWideChar(PrivilegeName), TokenPrivileges.Privileges[0].Luid);
    TokenPrivileges.PrivilegeCount := 1;
    TokenPrivileges.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
    if AdjustTokenPrivileges(TokenHandle, False, TokenPrivileges, 0, nil, ReturnLength) then Result := True;
   finally
    CloseHandle(TokenHandle);
   end;
  end
 else Log(['not OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, TokenHandle)', SysErrorMessage(GetLastError)]);
end;

function GetProcessPrioriName(Value:Integer):string;
begin
 if Value >= 24 then Exit('Реального времени') else
  if Value >= 11 then Exit('Высокий') else
   if Value >= 10 then Exit('Выше среднего') else
    if Value >=  8 then Exit('Средний') else
     if Value >=  6 then Exit('Ниже среднего') else
      if Value >=  4 then Exit('Низкий') else
       if Value >=  0 then Exit('Н/Д');
end;

procedure TFormProcess.ButtonCloseClick(Sender: TObject);
begin
 Close;
end;

procedure TFormProcess.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 case Key of
  VK_ESCAPE: Close;
 end;
end;

initialization
 Kernel32:=LoadLibrary('Kernel32.dll');
 if Kernel32 <> 0 then
  begin
   @Wow64DisableWow64FsRedirection:=GetProcAddress(Kernel32, 'Wow64DisableWow64FsRedirection');
   @Wow64EnableWow64FsRedirection:=GetProcAddress(Kernel32, 'Wow64EnableWow64FsRedirection');
  end
 else ShowMessage('Kernel32 = 0');
 hLibrary:=LoadLibrary('ntdll.dll');
 if hLibrary <> 0 then
  begin
   case WindowsBits = x64 of
    False:
     begin
      {$IFDEF WIN64}
       @NtQueryInformationProcess:=GetProcAddress(hLibrary, 'NtQueryInformationProcess');
       @NtReadVirtualMemory:=GetProcAddress(hLibrary, 'NtReadVirtualMemory');
      {$ELSE}
       @NtQueryInformationProcess:=GetProcAddress(hLibrary, 'NtQueryInformationProcess');
       @NtReadVirtualMemory:=GetProcAddress(hLibrary, 'NtReadVirtualMemory');
      {$ENDIF}
     end;
    True:
     begin
      {$IFDEF WIN64}
       @NtQueryInformationProcess:=GetProcAddress(hLibrary, 'NtQueryInformationProcess');
       @NtReadVirtualMemory:=GetProcAddress(hLibrary, 'NtReadVirtualMemory');
      {$ELSE}
       @NtQueryInformationProcess:=GetProcAddress(hLibrary, 'NtWow64QueryInformationProcess64');
       @NtReadVirtualMemory:=GetProcAddress(hLibrary, 'NtWow64ReadVirtualMemory64');
      {$ENDIF}
     end;
   end;
   //@NtQueryInformationProcess:=GetProcAddress(hLibrary, 'NtWow64QueryInformationProcess64'); //NtQueryInformationProcess NtWow64QueryInformationProcess64
   //@NtReadVirtualMemory:=GetProcAddress(hLibrary, 'NtWow64ReadVirtualMemory64'); //NtReadVirtualMemory NtWow64ReadVirtualMemory64
  end
 else Log(['Информация о процессах ожидается не полная.']);
 AddCurrentProcessPrivilege('SeDebugPrivilege');
end.
