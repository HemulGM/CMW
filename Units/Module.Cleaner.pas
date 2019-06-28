unit Module.Cleaner;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Vcl.ImgList, Dialogs, ExtCtrls, ComCtrls, System.Win.Registry, ShellAPI,
  Vcl.StdCtrls, IniFiles,
  //���� ������
  CMW.Utils, CMW.OSInfo, CMW.ModuleStruct;
  //

type
  TScanElements = class;

  TCleanerUnit = class;

  TElementReason = (erToDel, erAction, erSysToDel, erRecommend, erAppToDel, erNotice);

  TOnAddToList = procedure(ListItem: TListItem);

  TScanElement = class(TCollectionItem)
  private
    FGroupID: Word;
    FName: string;
    FDescription: string;
    FEnabled: Boolean;
    FListID: Word;
    FElementID: Word;
    FWork: Boolean;
    FIconID: Integer;
    FOwner: TScanElements;
  public
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure Perform; virtual;
    procedure FindFill; virtual; abstract;
    function AddToList(FileName: string; EID: Word): TListItem; overload;
    function AddToList(FileName: string; EID: Word; NoChk: Boolean): TListItem; overload;
    function Owner: TScanElements;
    property Work: Boolean read FWork;
    property ListID: Word read FListID write FListID;
    property ElementID: Word read FElementID write FElementID;
    property GroupID: Word read FGroupID write FGroupID;
    property IconID: Integer read FIconID write FIconID;
    property Name: string read FName write FName;
    property Description: string read FDescription write FDescription;
    property Enabled: Boolean read FEnabled write FEnabled;
    constructor Create(Collection: TCollection); override;
  end;

  TScanElements = class(TCollection)
  private
    FOwner: TCleanerUnit;
    function GetItem(Index: Integer): TScanElement;
    procedure SetItem(Index: Integer; Value: TScanElement);
  public
    function Synchronize(LV: TListView): Boolean;
    function Add: TScanElement; overload;
    function Owner: TCleanerUnit;
    property Items[Index: Integer]: TScanElement read GetItem write SetItem; default;
    constructor Create(AOwner: TCleanerUnit);
  end;

  TCleanerUnit = class(TSystemUnit)
    StartTime: Cardinal;
    StopTime: Cardinal;
    Elements: TScanElements;
  private
    FParamListView: TListView;
    FDisableIcon: TIcon;
    FScanFiles: Boolean;
    function FPerformRemoval: TGlobalState;
    procedure FillScanList;
    function FGetByID(aID: Word): TGlobalState;
  public
    function FGet: TGlobalState; override;
    procedure OnChanged; override;
    procedure Initialize; override;
    procedure OpenSelected;
    procedure GetByID(aID: Word);
    function CheckFile(FN: string; var SignatureName: string): Integer;
    function PerformRemoval: Boolean;
    function Synchronize: Boolean;
    function Save(Ini: TIniFile): Boolean; override;
    function Load(Ini: TIniFile): Boolean; override;
    procedure Stop; override;
    constructor Create; override;
    destructor Destroy; override;
    property ParamList: TListView read FParamListView write FParamListView;
    property DisableIcon: TIcon read FDisableIcon write FDisableIcon;
    property ScanFiles: Boolean read FScanFiles write FScanFiles;
  end;

const
  //SItems
  SIDesc = 0;
  SINote = 1; //����������
  SIID1 = 2; //������ 1
  SIID2 = 3; //������ 2
  SIID3 = 4; //������ 3

  CF_FILE_SUCCESS_CHECK = 0;
  CF_SOURCE_FILE_MD5_ERROR = -1;
  CF_SIGNATURES_DB_LOAD_ERROR = -2;
  CF_DATABASE_IS_EMPTY = -3;
  CF_UNKNOWN_ERROR = -4;
  CF_SIGNATURE_IS_FOUND = 1;
  DamnificFilesExt = '.bat.cmd.com.dll.exe.msc.msi.msu.paf.pif.scr.vb.vbe.vbs.wsf.wsh.';
  DamnificFilesExtEx = DamnificFilesExt + 'js.jse.';
  MD5BaseFile = 'Data\Signatures.inf';
  MD5NameFile = 'Data\SignatName.inf';

implementation

uses
  ShellRecycle, Module.CleanerElements, MD5;

{
procedure TSmartHandler.EmptyRecycle;
var TrID:Cardinal;
procedure ER;
begin
 SHEmptyRecycleBin(Application.Handle, nil, SHERB_NOCONFIRMATION or SHERB_NOPROGRESSUI);
end;
begin
 CreateThread(nil, 0, @ER, nil, 0, TrID);
end;
}

function TCleanerUnit.CheckFile(FN: string; var SignatureName: string): Integer;
var
  FMD5: string;
  LMD5: string;
  ListOfMD5: TStrings;
  ListOfNames: TStrings;
  i: Cardinal;
  LoadNotNames: Boolean;
begin
  Result := CF_UNKNOWN_ERROR;
  if Pos(ExtractFileExt(FN), DamnificFilesExtEx) = 0 then
    Exit(CF_FILE_SUCCESS_CHECK);

  try
    FMD5 := MD5DigestToStr(MD5File(FN));
  except
    begin
      Log(['�� ���� �������� MD5-����� �����', FN]);
      Exit(CF_SOURCE_FILE_MD5_ERROR);
    end;
  end;
  ListOfMD5 := TStringList.Create;
  ListOfNames := TStringList.Create;
  try
    ListOfMD5.LoadFromFile(CurrentDir + MD5BaseFile);
    ListOfNames.LoadFromFile(CurrentDir + MD5NameFile);
    if ListOfMD5.Count <= 0 then
    begin
      ListOfMD5.Free;
      ListOfNames.Free;
      Exit(CF_DATABASE_IS_EMPTY);
    end;
    LoadNotNames := ListOfMD5.Count <= ListOfNames.Count;
  except
    begin
      ListOfMD5.Free;
      ListOfNames.Free;
      Exit(CF_SIGNATURES_DB_LOAD_ERROR);
    end;
  end;
  for i := 0 to ListOfMD5.Count - 1 do
  begin
    try
      LMD5 := ListOfMD5.Strings[i];
    except
      begin
        Log(['��������� ��������� � ���� ������ � ������', i]);
        Continue;
      end;
    end;
   //Log([FMD5, '=', LMD5]);
    if FMD5 = LMD5 then
    begin
      if LoadNotNames then
      try
        SignatureName := ListOfNames.Strings[i];
      except
        Log(['�� ���� ��������� ��� ��������� �� ������', i]);
      end
      else
        SignatureName := '';
      ListOfMD5.Free;
      ListOfNames.Free;
      Exit(CF_SIGNATURE_IS_FOUND);
    end;
  end;

  ListOfMD5.Free;
  ListOfNames.Free;
end;

function TScanElement.Owner: TScanElements;
begin
  Result := FOwner;
end;

procedure TScanElement.Perform;
begin
  if FWork then
  begin
    Log(['TScanElement.Perform - ��� ��� ����������:', Name]);
    Exit;
  end;
  FWork := True;
  try
    if Enabled then
      FindFill;
  finally
    FWork := False;
  end;
end;

destructor TScanElement.Destroy;
begin
  inherited Destroy;
end;

procedure TScanElement.Assign(Source: TPersistent);
var
  Element: TScanElement;
begin
  if Source is TScanElement then
  begin
    Element := TScanElement(Source);

    FGroupID := Element.FGroupID;
    FName := Element.FName;
    FDescription := Element.FDescription;
    FEnabled := Element.FEnabled;
    FListID := Element.FListID;
    FElementID := Element.FElementID;
    FWork := Element.FWork;
  end
  else
    inherited Assign(Source);
end;

function TScanElement.AddToList(FileName: string; EID: Word; NoChk: Boolean): TListItem;
var
  SignName: string;
  ScanRes: Integer;
begin
  with TScanElements(Collection).Owner.ListView.Items do
  begin
    Result := Add;
    Result.Caption := FileName;
   //Check for MD5 summ
    if FOwner.FOwner.ScanFiles then
    begin
      ScanRes := FOwner.FOwner.CheckFile(FileName, SignName);
      case ScanRes of
        CF_SIGNATURES_DB_LOAD_ERROR, CF_DATABASE_IS_EMPTY:
          begin
            Log(['��������� ������������, �.�. ���� ������ �� �������� ��� �����.']);
            FOwner.FOwner.ScanFiles := False;
          end;
      end;
    end
    else
      ScanRes := CF_FILE_SUCCESS_CHECK;
   {SIDesc:=}    Result.SubItems.Add(GetFileDescription(FileName, GetFileTypeName(FileName)));
   {SINote:=}    Result.SubItems.Add('');
   {SIID1:=}    Result.SubItems.Add('');
   {SIID2:=}    Result.SubItems.Add('');
   {SIID3:=}    Result.SubItems.Add('');
    Result.ImageIndex := 5;
    Result.Checked := False;
    if SysUtils.DirectoryExists(FileName) then
    begin
      Result.Checked := not NoChk;
      Result.SubItems[SINote] := '�������';
      Result.ImageIndex := 2;
    end
    else if FileExists(FileName) then
    begin
      if OccupiedFile(FileName) then
        Result.SubItems[SINote] := LangText(109, '����� ������ ���������')
      else
        Result.Checked := not NoChk;
      Result.ImageIndex := 4;
    end
    else
    begin
      Result.SubItems[SINote] := LangText(-1, '������� ������ �� ��������.');
    end;
    if ScanRes = CF_SIGNATURE_IS_FOUND then
    begin
      if SignName <> '' then
        Result.SubItems[SINote] := SignName;
      Result.ImageIndex := 9;
    end;
  end;
end;

function TScanElement.AddToList(FileName: string; EID: Word): TListItem;
begin
  Result := AddToList(FileName, EID, False);
end;

constructor TScanElement.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FOwner := TScanElements(Collection);
end;

//--------------------------------TCleanerUnit----------------------------------

procedure TCleanerUnit.OpenSelected;
begin
  if ListView.Selected = nil then
    Exit;
  OpenFolderAndSelectFile(ListView.Selected.Caption);
end;

function TCleanerUnit.Save(Ini: TIniFile): Boolean;
begin
  Result := True;
 //���������� �������
end;

function TCleanerUnit.Load(Ini: TIniFile): Boolean;
begin
  Result := True;
 //�������� �������
end;

function TCleanerUnit.Synchronize: Boolean;
begin
  Result := Elements.Synchronize(ParamList);
end;

procedure TCleanerUnit.Initialize;
begin
  ListView.Groups.Clear;
  ListView.GroupView := True;
  with TTempInetFiles.Create(Elements) do
  begin
    Enabled := False;
    ElementID := 0;
    IconID := 0;
    GroupID := GetGroup(ListView, Name, False);
    ListView.Groups[GroupID].TitleImage := IconID;
  end;
  with TRecentFiles.Create(Elements) do
  begin
    Enabled := False;
    ElementID := 1;
    IconID := 1;
    GroupID := GetGroup(ListView, Name, False);
    ListView.Groups[GroupID].TitleImage := IconID;
  end;
  with TTempFiles.Create(Elements) do
  begin
    ElementID := 2;
    IconID := 7;
    GroupID := GetGroup(ListView, Name, False);
    ListView.Groups[GroupID].TitleImage := IconID;
  end;
  with TPrefetcher.Create(Elements) do
  begin
    ElementID := 3;
    IconID := 3;
    GroupID := GetGroup(ListView, Name, False);
    ListView.Groups[GroupID].TitleImage := IconID;
  end;
  with TSysFolder.Create(Elements) do
  begin
    ElementID := 4;
    IconID := 6;
    GroupID := GetGroup(ListView, Name, False);
    ListView.Groups[GroupID].TitleImage := IconID;
  end;
  with TDamnificFiles.Create(Elements) do
  begin
    ElementID := 5;
    IconID := 7;
    GroupID := GetGroup(ListView, Name, False);
    ListView.Groups[GroupID].TitleImage := IconID;
  end;
 {with TCurUser.Create(Elements) do
  begin
   ElementID:=6;
   IconID:=8;
   GroupID:=GetGroup(ListView, Name, False);
   ListView.Groups[GroupID].TitleImage:=IconID;
  end;  }
  {
 with TRecycle.Create(Elements) do
  begin
   ElementID:=5;
   IconID:=8;
   GroupID:=GetGroup(ListView, Name, False);
   ListView.Groups[GroupID].TitleImage:=IconID;
  end; }
  FillScanList;
end;

procedure TCleanerUnit.GetByID(aID: Word);
begin
  if FState = gsProcess then
    Exit;
  SetGlState(gsProcess);
  FState := gsProcess;
  FStop := False;
  try
    try
      FState := FGetByID(aID);
    finally
      ListView.Items.EndUpdate;
    end;
  except
    FState := gsError;
  end;
  if FState = gsProcess then
  begin
    Log(['������� ���� � ��������������� �������� FState = gsProcess is', FState = gsProcess, GetLastError]);
    MessageBox(Application.Handle, '������� ����� ������� ��������. ���������� ���������.', '��������', MB_ICONWARNING or MB_OK);
    FState := gsError;
    FStop := True;
  end;
  if FState = gsStopped then
  begin
    Inform(LangText(-1, '������� ����������.'));
  end;
  SetGlState(FState);
end;

function TCleanerUnit.FGetByID(aID: Word): TGlobalState;
var
  i: Integer;
begin
  Result := gsProcess;
  Inform(LangText(9, '���������� � ������������...'));

 //����������
  StartTime := GetTickCount;
  ListView.Items.Clear;

 //������ ������������ ---------------------------------------------------------
  try
    begin
      if Elements.Count > 0 then
      begin
        for i := 0 to Elements.Count - 1 do
        begin
          if Stopping then
            Exit(gsStopped);
          if Elements.Items[i].ListID <> aID then
            Continue;
          ListView.Groups[Elements.Items[i].GroupID].State := ListView.Groups[Elements.Items[i].GroupID].State - [lgsCollapsed];
          try
            Elements.Items[i].FindFill;
          except
            Exit(gsError);
          end;
          if not FStop then
            Result := gsFinished
          else
            Exit(gsStopped);
        end;
      end
      else
      begin
        Log(['������ ��������� ������������ ����! Elements.Count <= 0']);
        Inform(LangText(-1, '������ ��������� ������������ ����!'));
        Result := gsError;
      end;
    end;
  except
    begin
      Log(['��������� ������ ��� ������������ ��.', GetLastError]);
      Inform(LangText(-1, '��������� ������ ��� ������������ ��.'));
      Result := gsError;
    end;
  end;
  StopTime := GetTickCount;
 //----------------
  Inform(LangText(-1, '������ ��������� �������.'));
  OnChanged;
end;

function TCleanerUnit.PerformRemoval: Boolean;
begin
  if FState = gsProcess then
    Exit(False);
  SetGlState(gsProcess);
  FState := gsProcess;
  FStop := False;
  try
    try
      FState := FPerformRemoval;
    finally
      ListView.Items.EndUpdate;
    end;
  except
    FState := gsError;
  end;
  if FState = gsProcess then
  begin
    Log(['������� ���� � ��������������� �������� FState = gsProcess is', FState = gsProcess, GetLastError]);
    MessageBox(Application.Handle, '������� ����� ������� ��������. ���������� ���������.', '��������', MB_ICONWARNING or MB_OK);
    FState := gsError;
    FStop := True;
  end;
  Result := True;
  SetGlState(FState);
end;

function TCleanerUnit.FPerformRemoval: TGlobalState;
var
  i: Integer;
  FileName: string;
begin
  Inform(LangText(-1, '����������� �������� ��������� ���������...'));
  Result := gsProcess;
  if ListView.Items.Count > 0 then
  begin
    ListView.Items.BeginUpdate;
    i := 0;
    while (ListView.Items.Count > 0) and (i < ListView.Items.Count) do
    begin
      if Stopping then
        Exit(gsStopped);
      if ListView.Items[i].Checked then
      begin
        FileName := ListView.Items[i].Caption;
        if DeleteForceFile(FileName) then
        begin
          ListView.Items[i].Delete;
          Continue;
        end
        else
        begin
          ListView.Items[i].Checked := False;
          ListView.Items[i].SubItems[SINOTE] := SysErrorMessage(GetLastError);
        end;
      end;
      Inc(i);
    end;
  end;
  Inform(LangText(-1, '������� ���������.'));
  OnChanged;
  try
    Result := gsFinished;
  except
    Exit;
  end;
end;

procedure TCleanerUnit.FillScanList;
var
  i: Integer;
  LI: TListItem;
begin
  ParamList.Items.BeginUpdate;
  ParamList.Items.Clear;
  if Elements.Count > 0 then
  begin
    for i := 0 to Elements.Count - 1 do
    begin
      with ParamList.Items do
      begin
        LI := Add;
        LI.Caption := Elements.Items[i].Name;
        LI.Checked := Elements.Items[i].Enabled;
        LI.ImageIndex := Elements.Items[i].IconID;
        Elements.Items[i].ListID := i;
      end;
    end;
  end;
  ParamList.Items.EndUpdate;
end;

procedure TCleanerUnit.OnChanged;
begin
  inherited;
  OnListViewSort;
end;

procedure TCleanerUnit.Stop;
begin
  inherited;
end;

function TCleanerUnit.FGet: TGlobalState;
var
  i: Integer;
begin
  Result := gsProcess;
  Inform(LangText(9, '���������� � ������������...'));

 //����������
  StartTime := GetTickCount;
  ListView.Items.Clear;
  Elements.Synchronize(ParamList);

 //������ ������������ ---------------------------------------------------------
  try
    begin
      if Elements.Count > 0 then
      begin
        for i := 0 to Elements.Count - 1 do
        begin
          if not Elements.Items[i].Enabled then
            Continue;
          Elements.Items[i].FindFill;
        end;
      end
      else
      begin
        Log(['������ ��������� ������������ ����!']);
      end;
    end;
  except
    begin
      StopTime := GetTickCount;
      Log(['��������� ������ ��� ������������ ��.', GetLastError]);
      Exit(gsError);
    end;
  end;
 //----------------
  Inform(LangText(-1, '������ ��������� �������.'));
  OnChanged;
  try
    Result := gsFinished;
  except
    Exit;
  end;
end;

constructor TCleanerUnit.Create;
begin
  Elements := TScanElements.Create(Self);
  FDisableIcon := TIcon.Create;
  inherited;
end;

destructor TCleanerUnit.Destroy;
begin
  Elements.Free;
  FDisableIcon.Free;
  inherited;
end;

//---------------------------TScanElements--------------------------------------

function TScanElements.GetItem(Index: Integer): TScanElement;
begin
  Result := TScanElement(inherited GetItem(Index));
end;

procedure TScanElements.SetItem(Index: Integer; Value: TScanElement);
begin
  inherited SetItem(Index, Value);
end;

function TScanElements.Add: TScanElement;
begin
  Result := TScanElement(inherited Add);
end;

function TScanElements.Owner: TCleanerUnit;
begin
  Result := FOwner;
end;

function TScanElements.Synchronize(LV: TListView): Boolean;
var
  i, j: Word;
begin
  Result := False;
  if LV.Items.Count <= 0 then
  begin
    ShowMessage('������. � ������ ������������ ��� ���������. ����!');
    Log(['������. � ������ ������������ ��� ���������. LV:', LV.Name, 'Count:', LV.Items.Count, GetLastError]);
    Exit;
  end;
  if Count <= 0 then
  begin
    ShowMessage('������. � ������ ������������ ��� ���������. ����!');
    Log(['������. � ������ ������������ ��� ���������. TScanElements.', 'Count:', Count, GetLastError]);
    Exit;
  end;
  for i := 0 to LV.Items.Count - 1 do
  begin
    for j := 0 to Count - 1 do
      if Items[j].ListID = i then
        Items[j].Enabled := LV.Items[i].Checked;
  end;
  Result := True;
end;

constructor TScanElements.Create(AOwner: TCleanerUnit);
begin
  inherited Create(TScanElement);
  FOwner := AOwner;
end;

//--------------------------------����� ������������----------------------------

end.

