unit Module.Regeditor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  System.Win.Registry, CMW.Utils, CMW.ModuleStruct, Vcl.ComCtrls, Vcl.ImgList;

type
  TFormReg = class(TForm)
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  TRegUnit = class(TSystemUnit)
    procedure OnChanged; override;
    procedure Initialize; override;
    function FGet: TGlobalState; override;
  private
    FTreeView: TTreeView;
    FRoll: TRegistry;
    FStrIcon: TIcon;
    FIntIcon: TIcon;
    FBinIcon: TIcon;
    FDirIcon: TIcon;
    FNonIcon: TIcon;
    FSI: Integer;
    FII: Integer;
    FBI: Integer;
    FDR: Integer;
    FNO: Integer;
    procedure TreeViewExpanded(Sender: TObject; Node: TTreeNode);
    procedure TreeViewChange(Sender: TObject; Node: TTreeNode);
    procedure TreeViewGetImageIndex(Sender: TObject; Node: TTreeNode);
    procedure ShowSubKeys(Node: TTreeNode; depth: Integer);
    function GetFullNodeName(Node: TTreeNode): string;
    function GetFirstParent(Node: TTreeNode): TTreeNode;
  public
    procedure Stop; override;
    constructor Create; override;
    destructor Destroy; override;
    property TreeView: TTreeView read FTreeView write FTreeView;
    property IconStr: TIcon read FStrIcon write FStrIcon;
    property IconInt: TIcon read FIntIcon write FIntIcon;
    property IconBin: TIcon read FBinIcon write FBinIcon;
    property IconDir: TIcon read FDirIcon write FDirIcon;
    property IconNon: TIcon read FNonIcon write FNonIcon;
  end;

const
  LoadedKey = 'CWM_LOAD';

var
  FormReg: TFormReg;

function RegDatLoad(FN: string): Boolean;

function RegDatUnload: Boolean;

implementation

uses
  Winapi.ShellAPI, Module.WinServices;

{$R *.dfm}

function RegDatLoad(FN: string): Boolean;
var
  Reg: TRegistry;
begin
  Result := False;
  try
    Reg := TRegistry.Create;
    Reg.RootKey := HKEY_USERS;
    if Reg.OpenKey(LoadedKey, False) then
    begin
      Reg.CloseKey;
      if Reg.Unloadkey(LoadedKey) then
      begin
        if Reg.Loadkey(LoadedKey, FN) then
        begin
          if Reg.OpenKey(LoadedKey, False) then
            Result := True;
        end;
      end;
    end;
  finally
    begin
      Reg.CloseKey;
      Reg.Free;
    end;
  end;
end;

function RegDatUnload: Boolean;
var
  Reg: TRegistry;
begin
  Result := False;
  try
    Reg := TRegistry.Create;
    Reg.RootKey := HKEY_USERS;
    if Reg.OpenKey(LoadedKey, False) then
    begin
      Reg.CloseKey;
      Result := Reg.Unloadkey(LoadedKey);
    end;
  finally
    Reg.Free;
  end;
end;

procedure TRegUnit.Initialize;
begin
  if Assigned(FTreeView) then
  begin
    FTreeView.OnExpanded := TreeViewExpanded;
    FTreeView.OnChange := TreeViewChange;
    FTreeView.OnGetImageIndex := TreeViewGetImageIndex;
  end;
end;

function TRegUnit.GetFirstParent(Node: TTreeNode): TTreeNode;
begin
  Result := Node;
  while Result.Parent <> nil do
    Result := Result.Parent;
end;

function TRegUnit.GetFullNodeName(Node: TTreeNode): string;
var
  CurNode: TTreeNode;
begin
  Result := '';
  CurNode := Node;
  while (CurNode.Parent <> nil) do
  begin
    Result := '\' + CurNode.Text + Result;
    CurNode := CurNode.Parent;
  end;
end;

procedure TRegUnit.ShowSubKeys(Node: TTreeNode; depth: Integer);
var
  ParentKey: string;
  KeyNames: TStringList;
  KeyInfo: TRegKeyInfo;
  CurNode: TTreeNode;
  i: Integer;
begin
  ParentKey := GetFullNodeName(Node);
  if ParentKey <> '' then
  begin
    CurNode := GetFirstParent(Node);
    if FRoll.RootKey <> StrKeyToRoot(CurNode.Text) then
      FRoll.RootKey := StrKeyToRoot(CurNode.Text);
    if not FRoll.OpenKeyReadOnly(ParentKey) then
      Exit;
  end
  else
  begin
    if FRoll.RootKey <> StrKeyToRoot(Node.Text) then
      FRoll.RootKey := StrKeyToRoot(Node.Text);
    if not FRoll.OpenKeyReadOnly('\') then
      Exit;
  end;
  FRoll.GetKeyInfo(KeyInfo);
  if KeyInfo.NumSubKeys <= 0 then
    Exit;
  if Assigned(FTreeView) then
  begin
    FTreeView.Items.BeginUpdate;
    KeyNames := TStringList.Create;
    FRoll.GetKeyNames(KeyNames);
    while Node.GetFirstChild <> nil do
      Node.GetFirstChild.Delete;
    if (KeyNames.Count > 0) then
      for i := 0 to KeyNames.Count - 1 do
      begin
        FRoll.OpenKeyReadOnly(ParentKey + '\' + KeyNames[i]);
        FRoll.GetKeyInfo(KeyInfo);
        CurNode := FTreeView.Items.AddChild(Node, KeyNames[i]);
        CurNode.SelectedIndex := 11;
        if KeyInfo.NumSubKeys > 0 then
        begin
          FTreeView.Items.AddChild(CurNode, '').SelectedIndex := 11; //
          CurNode.SelectedIndex := 11;
        end;
      end;
    KeyNames.Free;
    FTreeView.Items.EndUpdate;
  end;
end;

procedure TRegUnit.TreeViewGetImageIndex(Sender: TObject; Node: TTreeNode);
begin
  with Node do
  begin
    if Expanded then
      ImageIndex := 2
    else
      ImageIndex := 10;
  end;
end;

procedure TRegUnit.TreeViewChange(Sender: TObject; Node: TTreeNode);
var
  s, muis: string;
  KeyInfo: TRegKeyInfo;
  ValueNames: TStringList;
  i: Integer;
  DataType: DWORD;
  II: Word;
  FullName, DT: string;
  Tmp: string;
  NM: string;
  OBuf: array[0..2048] of WideChar;
  OSize: DWORD;
  Dir: PWideChar;
  MUIRes: Integer;
  MIcon: TIcon;
  FirstNode: TTreeNode;
begin
  FListView.Items.Clear;
  if Assigned(FListView.SmallImages) then
    FListView.SmallImages.Clear
  else
  begin
    FListView.SmallImages := TImageList.CreateSize(16, 16);
    FListView.SmallImages.ColorDepth := cd32Bit;
  end;
  if Assigned(FStrIcon) then
    FSI := FListView.SmallImages.AddIcon(FStrIcon)
  else
    FSI := -1;
  if Assigned(FIntIcon) then
    FII := FListView.SmallImages.AddIcon(FIntIcon)
  else
    FII := -1;
  if Assigned(FBinIcon) then
    FBI := FListView.SmallImages.AddIcon(FBinIcon)
  else
    FBI := -1;
  if Assigned(FDirIcon) then
    FDR := FListView.SmallImages.AddIcon(FDirIcon)
  else
    FDR := -1;
  if Assigned(FNonIcon) then
    FNO := FListView.SmallImages.AddIcon(FNonIcon)
  else
    FNO := -1;

  FirstNode := GetFirstParent(Node);
  if FRoll.RootKey <> StrKeyToRoot(FirstNode.Text) then
    FRoll.RootKey := StrKeyToRoot(FirstNode.Text);
  s := GetFullNodeName(Node) + '\';
  FRoll.CloseKey;
  if not FRoll.OpenKeyReadOnly(s) then
    Exit;
  Inform(FirstNode.Text + '\' + FRoll.CurrentPath);
  FRoll.GetKeyInfo(KeyInfo);
  if KeyInfo.NumValues <= 0 then
  begin
    with FListView.Items.Add do
    begin
      Caption := ' (ѕо умолчанию)';
      SubItems.Add('REG_SZ');
      SubItems.Add(' (значение не присвоено)');
      ImageIndex := FSI;
    end;
    Exit;
  end;
  ValueNames := TStringList.Create;
  FRoll.GetValueNames(ValueNames);
  for i := 0 to ValueNames.Count - 1 do
    with FListView.Items.Add do
    begin
      ImageIndex := -1;
      s := '';
      DT := '';
      Caption := ValueNames[i];
      RegQueryValueEx(FRoll.CurrentKey, PChar(ValueNames[i]), nil, @DataType, nil, nil);
      case DataType of
        REG_SZ, REG_EXPAND_SZ:
          begin
            if DataType = REG_EXPAND_SZ then
              DT := 'REG_EXPAND_SZ'
            else
              DT := 'REG_SZ';
            s := FRoll.ReadString(ValueNames[i]);
            try
              begin
                FullName := s;
                NormFileName(FullName);
                if FileExists(FullName) then
                begin
                  if GetFileIcon(FullName, is16, FListView.SmallImages, II) > 0 then
                    ImageIndex := II;
                end
                else if DirectoryExists(FullName) then
                  ImageIndex := FDR
                else
                  ImageIndex := FSI;
              end;
            except
              Log(['Ќе смог загрузить иконку из файла:', FullName, GetLastError]);
            end;
            if s.Length > 0 then
              if s[1] = '@' then
              begin
                case MUILoad(s, MIcon, muis) of
                  mtIcon:
                    ImageIndex := FListView.SmallImages.AddIcon(MIcon);
                  mtString:
                    s := muis + ' (' + s + ')';
                end;
              end;
          end;
        REG_DWORD, REG_DWORD_BIG_ENDIAN:
          begin
            if DataType = REG_DWORD then
              DT := 'REG_DWORD'
            else
              DT := 'REG_DWORD_BIG_ENDIAN';
            try
              s := '0x' + IntToHex(FRoll.ReadInteger(ValueNames[i]), 8) + ' (' + IntToStr(FRoll.ReadInteger(ValueNames[i])) + ')';
            except
              s := '(недопустимый параметр DWORD)';
            end;
            ImageIndex := FII;
          end;
        REG_BINARY:
          begin
            DT := 'REG_BINARY';
            try
              s := FRoll.GetDataAsString(ValueNames[i], False);
            except
              s := '(недопустимый параметр BINARY)';
            end;
            ImageIndex := FBI;
          end;
        REG_LINK:
          begin
            DT := 'REG_LINK';
            try
              s := FRoll.GetDataAsString(ValueNames[i], False);
            except
              s := '(недопустимый параметр LINK)';
            end;
            ImageIndex := FBI;
          end;
        REG_MULTI_SZ:
          begin
            DT := 'REG_MULTI_SZ';
            try
              s := ReadStringList(FRoll, Caption);
            except
              s := '(недопустимый параметр MULTI_SZ)';
            end;
            ImageIndex := FSI;
          end;
        REG_RESOURCE_LIST:
          begin
            DT := 'REG_RESOURCE_LIST';
            try
              s := FRoll.GetDataAsString(ValueNames[i], False);
            except
              s := '(недопустимый параметр RESOURCE_LIST)';
            end;
            ImageIndex := FBI;
          end;
        REG_FULL_RESOURCE_DESCRIPTOR:
          begin
            DT := 'REG_FULL_RESOURCE_DESCRIPTOR';
            try
              s := FRoll.GetDataAsString(ValueNames[i], False);
            except
              s := '(недопустимый параметр RESOURCE_DESCRIPTOR)';
            end;
            ImageIndex := FBI;
          end;
        REG_RESOURCE_REQUIREMENTS_LIST:
          begin
            DT := 'REG_RESOURCE_REQUIREMENTS_LIST';
            try
              s := FRoll.GetDataAsString(ValueNames[i], False);
            except
              s := '(недопустимый параметр REQUIREMENTS_LIST)';
            end;
            ImageIndex := FBI;
          end;
        REG_NONE:
          begin
            DT := 'REG_NONE';
            try
              s := FRoll.GetDataAsString(ValueNames[i], False);
            except
              s := '(недопустимый параметр NONE)';
            end;
            ImageIndex := FNO;
          end;
      else
        begin
          DT := '';
          ImageIndex := FNO;
          s := FRoll.GetDataAsString(ValueNames[i], False);
        end;
      end;
      if Caption = '' then
        Caption := ' (ѕо умолчанию)';
      if s = '' then
        s := ' (значение не присвоено)';
      if DT = '' then
        DT := ' (неизвестно)';
      SubItems.Add(DT);
      SubItems.Add(s);
    end;
  OnChanged;
  ValueNames.Free;
end;

procedure TRegUnit.OnChanged;
begin
  inherited;
  OnListViewSort;
end;

procedure TRegUnit.Stop;
begin
  inherited;
end;

procedure TRegUnit.TreeViewExpanded(Sender: TObject; Node: TTreeNode);
begin
  ShowSubKeys(Node, 1);
end;

constructor TRegUnit.Create;
begin
  inherited;
  FRoll := TRegistry.Create(FRootAccess);
  FIntIcon := TIcon.Create;
  FBinIcon := TIcon.Create;
  FStrIcon := TIcon.Create;
  FDirIcon := TIcon.Create;
end;

destructor TRegUnit.Destroy;
begin
  if Assigned(FListView.SmallImages) then
    FListView.SmallImages.Free;
  FRoll.Free;
  FIntIcon.Free;
  FBinIcon.Free;
  FStrIcon.Free;
  FDirIcon.Free;
  inherited;
end;

function TRegUnit.FGet: TGlobalState;
var
  Root: TTreeNode;
begin
  Inform(LangText(-1, '«агрузка элементов реестра...'));
  FRoll.RootKey := HKEY_CLASSES_ROOT;
  FListView.ViewStyle := vsReport;
  if Assigned(FTreeView) then
  begin
    FTreeView.Items.Clear;

    Root := FTreeView.Items.Add(nil, 'HKEY_CLASSES_ROOT');
    Root.SelectedIndex := 11;
    FTreeView.Items.AddChild(Root, '').SelectedIndex := 11;

    Root := FTreeView.Items.Add(nil, 'HKEY_CURRENT_USER');
    Root.SelectedIndex := 11;
    FTreeView.Items.AddChild(Root, '').SelectedIndex := 11;

    Root := FTreeView.Items.Add(nil, 'HKEY_LOCAL_MACHINE');
    Root.SelectedIndex := 11;
    FTreeView.Items.AddChild(Root, '').SelectedIndex := 11;

    Root := FTreeView.Items.Add(nil, 'HKEY_USERS');
    Root.SelectedIndex := 11;
    FTreeView.Items.AddChild(Root, '').SelectedIndex := 11;

    Root := FTreeView.Items.Add(nil, 'HKEY_CURRENT_CONFIG');
    Root.SelectedIndex := 11;
    FTreeView.Items.AddChild(Root, '').SelectedIndex := 11;
  end;
  {
 Root:=FTreeView.Items.Add(nil, 'HKEY_PERFORMANCE_DATA');
 Root.SelectedIndex:=11;
 FTreeView.Items.AddChild(Root, '').SelectedIndex:=11;  }

 //Root:=FTreeView.Items.Add(nil, 'HKEY_DYN_DATA');
 //Root.SelectedIndex:=11;
 //FTreeView.Items.AddChild(Root, '').SelectedIndex:=11;

  ListView.Items.BeginUpdate;
  ListView.Items.Clear;
  OnChanged;
  try
    Result := gsFinished;
  except
    Exit(gsError);
  end;
end;

procedure TFormReg.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE:
      Close;
  end;
end;

initialization
try
  SetPrivilege('SeRestorePrivilege', True);
  SetPrivilege('SeBackupPrivilege', True);
except
  Log(['ќшибка. ”становка привелегий SeRestorePrivilege, SeBackupPrivilege.', SysErrorMessage(GetLastError)]);
end;

end.

