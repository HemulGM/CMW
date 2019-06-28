unit CMW.ModuleStruct;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls,
  System.IniFiles, Dialogs, ComCtrls, TLHelp32, PSAPI, Vcl.StdCtrls, CMW.OSInfo,
  System.Win.Registry;

type
  TGlobalState = (gsNone, gsProcess, gsFinished, gsStopped, gsError);

  TGetState = (gsIsNotGetted, gsIsGetted, gsGetting, gsCantGet);

  TInformProc = procedure(Value: string) of object;

  TStateProc = procedure(Value: TGlobalState) of object;

  TOnSetCurElement = procedure(var Value: string) of object;

  TProc = procedure of object;

  TTypeOfItem = (tiNone, tiAutorun, tiApp, tiEvent, tiProcess, tiService, tiTask, tiWindow);

  TListItemData = record
    ItemType: TTypeOfItem;
    ItemData: Pointer;
  end;

  TMainThread = class(TThread)
  private
    FProc: TProc;
    FUpd: TProc;
    FEnable: Boolean;
    function FTermed: Boolean;
  public
    property Termed: Boolean read FTermed;
    procedure Execute; override;
    procedure ExecuteUpdate(Sender: TObject);
    property Proc: TProc read FProc write FProc;
    property Enable: Boolean read FEnable write FEnable;
  end;

  TSystemUnit = class
    Roll: TRegistry;
    FName: string;
    FRootAccess: Cardinal;
    //FHandler:TSmart
    FRestrictions: Boolean;
    FInform: TInformProc;
    FStateProc: TStateProc;
    FStop: Boolean;
    FState: TGlobalState;
    FLoadIcons: Boolean;
    FListView: TListView;
    FLabelCount: TLabel;
    FGrouping: Boolean;
    FCurrentOS: TCurrentOS;
    FColumnSort: Integer;
    FIncreasingSort: Boolean;
    //FMainThread:TMainThread;
    function Save(Ini: TIniFile): Boolean; virtual;
    function Load(Ini: TIniFile): Boolean; virtual;
    procedure Stop; virtual;
    procedure Inform(Value: string); virtual;
    procedure SetListView(Value: TListView); virtual;
    procedure OnChanged; virtual;
    function Stopping: Boolean; virtual;
    function FGet: TGlobalState; virtual; abstract;
    procedure ListViewColumnSortClick(Sender: TObject; Column: TListColumn);
    procedure OnListViewSort;
  private
    procedure FThreadGet;
    procedure SetLabelCount(const Value: TLabel);
  public
    procedure SetStateToPB;
    procedure SetGlState(Value: TGlobalState);
    procedure Initialize; virtual; abstract;
    procedure Get; virtual;
    constructor Create; virtual;
    destructor Destroy; override;
    property RootAccess: Cardinal read FRootAccess;
    property ListView: TListView read FListView write SetListView;
    property Restrictions: Boolean read FRestrictions;
    property HandleInform: TInformProc read FInform write FInform;
    property StateProc: TStateProc read FStateProc write FStateProc;
    property LabelCount: TLabel read FLabelCount write SetLabelCount;
    property State: TGlobalState read FState;
    property LoadIcons: Boolean read FLoadIcons write FLoadIcons default True;
    property CurrentOSLink: TCurrentOS read FCurrentOS write FCurrentOS;
    property Grouping: Boolean read FGrouping write FGrouping;
    property Name: string read FName write FName;
  end;

function SetListItemData(AType: TTypeOfItem; AData: Pointer): Pointer;

implementation

uses
  CMW.Utils, Forms;

function SetListItemData(AType: TTypeOfItem; AData: Pointer): Pointer;
begin
  Result := AllocMem(SizeOf(TListItemData));
  with TListItemData(Result^) do
  begin
    ItemType := AType;
    ItemData := AData;
  end;
end;

function TMainThread.FTermed: Boolean;
begin
  Result := Terminated;
end;

procedure TMainThread.ExecuteUpdate(Sender: TObject);
begin
  if FEnable then
    if Assigned(FProc) then
      FProc();
end;

procedure TMainThread.Execute;
begin
  Log(['mon init']);
end;

procedure TSystemUnit.FThreadGet;
begin
 //ShowMessage(Self.FName);
  if (FState = gsProcess) and (not FStop) then
    Exit;
  SetGlState(gsProcess);
  FState := gsProcess;
  FStop := False;
  try
    try
      FState := FGet;
    finally
      begin
        ListView.Items.EndUpdate;
    //Self.Suspend;
      end;
    end;
  except
    FState := gsError;
  end;
  if FState = gsProcess then
  begin
    Log(['Получен флаг о незавершенности процесса FState = gsProcess is', FState = gsProcess, GetLastError]);
    MessageBox(Application.Handle, 'Процесс небыл успешно завершён. Рекомендую повторить.', 'Внимание', MB_ICONWARNING or MB_OK);
    FState := gsError;
    FStop := True;
  end;
  if FState = gsStopped then
  begin
    Inform(LangText(-1, 'Процесс остановлен.'));
  end;
  SetGlState(FState);
 //if FMainThread <> nil then FMainThread.Terminate;
end;

procedure TSystemUnit.SetLabelCount(const Value: TLabel);
begin
  FLabelCount := Value;
  FLabelCount.Caption := 'Элементов: не известно';
end;

procedure TSystemUnit.SetListView(Value: TListView);
begin
  if Assigned(FListView) then
    FListView.Free;
  FListView := Value;
  FListView.OnColumnClick := ListViewColumnSortClick;
end;

procedure TSystemUnit.ListViewColumnSortClick(Sender: TObject; Column: TListColumn);
begin
  if Column.Index - 1 = FColumnSort then
    FIncreasingSort := not FIncreasingSort
  else
    FColumnSort := Column.Index - 1;
  OnListViewSort;
end;

procedure TSystemUnit.OnListViewSort;
begin
  if FIncreasingSort then
    FListView.Tag := 0
  else
    FListView.Tag := 1;
  FListView.CustomSort(@CustomUniSortProc, FColumnSort);
  if FListView.Groups.Count = 1 then
    FListView.Groups[0].State := FListView.Groups[0].State - [lgsCollapsed];

end;

function TSystemUnit.Save(Ini: TIniFile): Boolean;
begin
  Result := True;
end;

function TSystemUnit.Load(Ini: TIniFile): Boolean;
begin
  Result := True;
end;

function TSystemUnit.Stopping: Boolean;
begin
  Application.ProcessMessages;
  Result := FStop;
end;

procedure TSystemUnit.SetStateToPB;
begin
  if Assigned(FStateProc) then
    FStateProc(FState);
end;

procedure TSystemUnit.SetGlState(Value: TGlobalState);
begin
  FState := Value;
  if Assigned(FStateProc) then
    FStateProc(Value);
end;

procedure TSystemUnit.OnChanged;
begin
  if Assigned(FLabelCount) then
    FLabelCount.Caption := 'Элементов: ' + IntToStr(FListView.Items.Count);
end;

procedure TSystemUnit.Inform(Value: string);
begin
  if not Assigned(FInform) then
    Exit;
  FInform(Value);
end;

destructor TSystemUnit.Destroy;
begin
  if not Assigned(FListView.Owner) then FListView.Free;
  Roll.Free;
  inherited;
end;

constructor TSystemUnit.Create;
begin
  inherited Create;
  FState := gsNone;
  FRestrictions := True;
  FColumnSort := -1;
  FIncreasingSort := True;
  if (Info.Bits = x64) and (AppBits = x32) then
    FRootAccess := KEY_ALL_ACCESS or KEY_WOW64_64KEY
  else
    FRootAccess := KEY_ALL_ACCESS;
  try
    Roll := TRegistry.Create(FRootAccess);
    FRestrictions := False;
  except
    FRestrictions := True;
  end;
  if FRestrictions then
  try
    if (Info.Bits = x64) and (AppBits = x32) then
      FRootAccess := KEY_READ or KEY_WOW64_64KEY
    else
      FRootAccess := KEY_READ;
    Roll := TRegistry.Create(FRootAccess);
    FRestrictions := False;
  except
    FRestrictions := True;
  end;

  FListView := TListView.Create(nil);
  with FListView do
  begin
    Name := 'FListView';
    OnColumnClick := ListViewColumnSortClick;
  end;
end;

procedure TSystemUnit.Stop;
begin
  FStop := True;
end;

procedure TSystemUnit.Get;
begin
  FThreadGet;
end;

end.

