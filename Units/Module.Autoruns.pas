unit Module.Autoruns;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Vcl.ImgList, Dialogs, ExtCtrls, ComCtrls, System.Win.Registry, ShellAPI,
  Vcl.StdCtrls, Winapi.ShlObj, Vcl.ValEdit,
  //���� ������
  CMW.Utils, CMW.OSInfo, CMW.ModuleStruct, Vcl.Grids;
  //

type
  PAutorunData = ^TAutorunData;

  TAutorunData = record
    IsRegType: Boolean;
    DisplayName: string;
    Cmd: string;
    RegPath: string;
    RegName: string;
    RegRoot: HKEY;
    Exists: Boolean;
  end;

  TAutorunUnit = class(TSystemUnit)
    SINAME: Word;
    SIELEM: Word;
    SITYPE: Word;
    SIINFO: Word;
    SIFLAG: Word;
    SIEXIS: Word;
  private
    FDisableIcon: TIcon;
    procedure SetListView(Value: TListView); override;
  public
    function FGet: TGlobalState; override;
    procedure OnChanged; override;
    procedure Initialize; override;
    function GetARDirectores: TStringList;
    procedure OpenFolderSelAR;
    procedure ShowInfo;
    procedure DeleteSel;
    function ShowARProc(LV: TListView): Boolean;
    function DeleteChecked: Boolean;
    function Delete(LI: TListItem): Boolean; overload;
    function Delete(AD: TAutorunData): Boolean; overload;
    procedure Stop; override;
    procedure Clear;
    constructor Create; override;
    destructor Destroy; override;
    property DisableIcon: TIcon read FDisableIcon write FDisableIcon;
  end;

  TFormAutorun = class(TForm)
    EditDisplayName: TEdit;
    Panel1: TPanel;
    ButtonClose: TButton;
    LabelPermission: TLabel;
    ValueListEditor1: TValueListEditor;
    procedure ButtonCloseClick(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private

  public
    { Public declarations }
  end;

var
  FormAutorun: TFormAutorun;

implementation
 {$R *.dfm}

uses
  Module.WinProcesses, CMW.Main;

procedure ShowData(AD: TAutorunData);
var
  Old: Integer;
begin
  with FormAutorun, AD do
  begin
    ValueListEditor1.Strings.Clear;
    AddToValueEdit(ValueListEditor1, '��� ������/�����', Format('%s', [RegName]), '');
    AddToValueEdit(ValueListEditor1, '�������� �����', Format('%s', [DisplayName]), '');
    AddToValueEdit(ValueListEditor1, '�������', Format('%s', [Cmd]), '');
    if IsRegType then
      AddToValueEdit(ValueListEditor1, '���� �������', Format('%s', [RootKeyToStr(RegRoot) + '\' + RegPath]), '')
    else
      AddToValueEdit(ValueListEditor1, '���� � �����', Format('%s', [RegPath]), '');
    AddToValueEdit(ValueListEditor1, '���� ����������', Format('%s', [BoolToLang(Exists)]), '');

    if ValueListEditor1.Strings.Count * ValueListEditor1.RowHeights[0] + 6 <= 400 then
      ValueListEditor1.Height := ValueListEditor1.Strings.Count * ValueListEditor1.RowHeights[0] + 6
    else
      ValueListEditor1.Height := 400;
    Old := ValueListEditor1.Height;
    ClientHeight := ValueListEditor1.Top + ValueListEditor1.Height + 60;
    ValueListEditor1.Height := Old + 10;
    LabelPermission.Visible := False;
    EditDisplayName.Text := DisplayName;
    ShowModal;
  end;
end;

procedure TFormAutorun.ButtonCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TAutorunUnit.ShowInfo;
begin
  if FListView.Selected = nil then
    Exit;
  if FListView.Selected.Data = nil then
    Exit;
  ShowData(TAutorunData(FListView.Selected.Data^));
end;

procedure TAutorunUnit.Initialize;
begin
 //
end;

procedure TAutorunUnit.DeleteSel;
begin
  if FListView.Selected = nil then
    Exit;
  if MessageBox(Application.Handle, '������� �� ������������?', '������', MB_ICONINFORMATION or MB_YESNO) <> ID_YES then
    Exit;
  if Delete(FListView.Selected) then
  begin
    FreeMemory(FListView.Selected.Data);
    FListView.Selected.Delete;
  end;
end;

procedure TAutorunUnit.SetListView(Value: TListView);
begin
  inherited;
  ListView.SmallImages := TImageList.CreateSize(16, 16);
  ListView.SmallImages.ColorDepth := cd32Bit;
end;

function TAutorunUnit.ShowARProc;
var
  CMD: string;
begin
  if ListView.Selected = nil then
    Exit(False);
  CMD := ListView.Selected.SubItems[SIELEM];
  Result := SelectProcByCMD(LV, CMD);
end;

procedure TAutorunUnit.OpenFolderSelAR;
var
  Str: string;
begin
  if ListView.Selected = nil then
    Exit;
  if FListView.Selected.Data = nil then
    Exit;
  Str := TAutorunData(FListView.Selected.Data^).CMD;
  OpenFolderAndOrSelectFile(Str);
end;

function TAutorunUnit.Delete(AD: TAutorunData): Boolean;
var
  FRoll: TRegistry;
  FileStr: string;
begin
  if AD.IsRegType then
  begin
    try
      try
        FRoll := TRegistry.Create(RootAccess);
        FRoll.RootKey := AD.RegRoot;
        Log(['������������: ��������� ���� �������', RootKeyToStr(AD.RegRoot) + '\' + AD.RegPath + '\' + AD.RegName]);
        Result := FRoll.OpenKey(AD.RegPath, False) and FRoll.DeleteValue(AD.RegName);
        if Result then
          Log(['���� ������� �����.']);
      finally
        FRoll.Free;
      end;
    except
      Exit(False);
    end;
  end
  else
  begin
    FileStr := NormFileNameF(AD.RegPath);
    if FileExists(FileStr) then
    begin
      if not DeleteFile(FileStr) then
      begin
        Log(['������������: �� ���� ������� ���� ������������', FileStr]);
        MessageBox(Application.Handle, PChar(LangText(67, '�� ���� ������� ���� ������������!')), PChar(LangText(41, '��������')), MB_ICONASTERISK or MB_OK);
        Exit(False);
      end
      else
      begin
        if FileExists(FileStr) then
        begin
          Log(['������������: �� ���������� ������� ���� ������������', FileStr]);
          MessageBox(Application.Handle, PChar(LangText(67, '�� ���� ������� ���� ������������!')), PChar(LangText(41, '��������')), MB_ICONASTERISK or MB_OK);
          Exit(False);
        end
        else
          Log(['������������: ����� ������� �� ����� ������������', FileStr]);
      end;
    end;
    Result := True;
  end;
end;

function TAutorunUnit.Delete(LI: TListItem): Boolean;
begin
  if LI = nil then
    Exit(False);
  if LI.Data = nil then
    Exit(False);
  Result := Delete(TAutorunData(LI.Data^));
end;

function TAutorunUnit.DeleteChecked: Boolean;
var
  i: Word;
begin
  if ListView.Items.Count <= 0 then
    Exit(False);
  Inform('�������� ��������� ������������...');
  i := 0;
  while (ListView.Items.Count > 0) and (i < ListView.Items.Count) do
  begin
    if Stopping then
      Exit(False);
    if ListView.Items[i].Checked then
    begin
      Delete(ListView.Items[i]);
      Continue;
    end;
    Inc(i);
  end;
  Inform('������');
  Result := True;
end;

procedure TAutorunUnit.OnChanged;
begin
  inherited;
  OnListViewSort;
end;

procedure TAutorunUnit.Stop;
begin
  inherited;
end;

function TAutorunUnit.FGet: TGlobalState;
var
  ListAutoRun: TStringList;
  UsersPaths: TStringList;
  i, j: Integer;
  ListItem: TListItem;
  II: Word;
  Path, FullName: string;
  DI: Integer;
  GroupName: string;
  AData: TAutorunData;
begin
  Inform(LangText(-1, '���������� ������ ��������� �����������...'));
  Result := gsProcess;
  Clear;
  ListView.Items.BeginUpdate;
  ListView.Groups.Clear;
  ListView.GroupView := FGrouping;
  ListView.SmallImages.Clear;

  if not Assigned(FDisableIcon) then
    DI := -1
  else
    DI := ListView.SmallImages.AddIcon(FDisableIcon);

  ListAutoRun := TStringList.Create;

  for j := 0 to 11 do
  begin
    with Roll, ListView.Items do
    begin
      case j of
        0:
          begin
            RootKey := HKEY_LOCAL_MACHINE;
            Path := 'SOFTWARE\Microsoft\Windows\CurrentVersion\Run';
            GroupName := '������: ������� ���������, ���������� ������';
          end;
        1:
          begin
            RootKey := HKEY_LOCAL_MACHINE;
            Path := 'SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce';
            GroupName := '������: ������� ���������, ����������� ������';
          end;
        8:
          begin
            RootKey := HKEY_LOCAL_MACHINE;
            Path := 'SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnceEx';
            GroupName := '������: ������� ���������, ����������� ������ (Ex)';
          end;
        2:
          begin
            if ((Info.Bits <> x64) or (AppBits <> x64) and (not SmartHandler.NowWowRedirection)) then
              Continue;
            RootKey := HKEY_LOCAL_MACHINE;
            Path := 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run';
            GroupName := '������: ������� ���������, ���������� ������, WOW64';
          end;
        3:
          begin
            if (Info.Bits <> x64) or (AppBits <> x64) then
              Continue;
            RootKey := HKEY_LOCAL_MACHINE;
            Path := 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce';
            GroupName := '������: ������� ���������, ����������� ������, WOW64';
          end;
        11:
          begin
            if (Info.Bits <> x64) or (AppBits <> x64) then
              Continue;
            RootKey := HKEY_LOCAL_MACHINE;
            Path := 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnceEx';
            GroupName := '������: ������� ���������, ����������� ������, WOW64 (Ex)';
          end;
        4:
          begin
            RootKey := HKEY_CURRENT_USER;
            Path := 'SOFTWARE\Microsoft\Windows\CurrentVersion\Run';
            GroupName := '������: ������� ������������, ���������� ������';
          end;
        5:
          begin
            RootKey := HKEY_CURRENT_USER;
            Path := 'SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce';
            GroupName := '������: ������� ������������, ����������� ������';
          end;
        9:
          begin
            RootKey := HKEY_CURRENT_USER;
            Path := 'SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnceEx';
            GroupName := '������: ������� ������������, ����������� ������ (Ex)';
          end;
        6:
          begin
            if (Info.Bits <> x64) or (AppBits <> x64) then
              Continue;
            RootKey := HKEY_CURRENT_USER;
            Path := 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run';
            GroupName := '������: ������� ������������, ���������� ������, WOW64';
          end;
        7:
          begin
            if (Info.Bits <> x64) or (AppBits <> x64) then
              Continue;
            RootKey := HKEY_CURRENT_USER;
            Path := 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce';
            GroupName := '������: ������� ������������, ����������� ������, WOW64';
          end;
        10:
          begin
            if (Info.Bits <> x64) or (AppBits <> x64) then
              Continue;
            RootKey := HKEY_CURRENT_USER;
            Path := 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnceEx';
            GroupName := '������: ������� ������������, ����������� ������, WOW64 (Ex)';
          end;
      else
        begin
          Log(['������ ����� ����� �� �������:', j, '���� ���������', SysErrorMessage(GetLastError)]);
        end;
      end;
      if not OpenKey(Path, False) then
      begin
        Log(['�� ���� ������� ����: ', Path, SysErrorMessage(GetLastError)]);
        Continue;
      end;
      GetValueNames(ListAutoRun);
      if ListAutoRun.Count > 0 then
        for i := 0 to ListAutoRun.Count - 1 do
        begin
          if ListAutoRun.Strings[i].Length <= 0 then
          begin
            Log(['�������� ������� "�� ���������", ��� ��������: ', '"' + ReadString('') + '"', Roll.CurrentPath]);
            Continue;
          end;
          AData.IsRegType := True;
          AData.Cmd := ReadString(ListAutoRun[i]);
          AData.DisplayName := GetFileDescription(NormFileNameF(AData.Cmd), '');
          AData.Exists := FileExists(NormFileNameF(AData.Cmd));
          AData.RegName := ListAutoRun[i];
          AData.RegPath := Path;
          AData.RegRoot := RootKey;

          ListItem := Add;
          ListItem.Data := AllocMem(SizeOf(AData));
          TAutorunData(ListItem.Data^) := AData;

          ListItem.Caption := AData.DisplayName;
          SIELEM := ListItem.SubItems.Add('');      //�������
          SIFLAG := ListItem.SubItems.Add('');      //���.

          try
            FullName := AData.Cmd;
            NormFileName(FullName);
            if FileExists(FullName) then
            begin
              if GetFileIcon(FullName, is16, ListView.SmallImages, II) > 0 then
                ListItem.ImageIndex := II
            end
            else
              ListItem.ImageIndex := DI;
          except
            Log(['�� ���� ��������� ������ �� �����:', FullName, GetLastError]);
          end;

          ListItem.SubItems[SIELEM] := AData.Cmd;
          ListItem.SubItems[SIFLAG] := BoolToLang(AData.Exists);
          ListItem.Checked := not AData.Exists;
          ListItem.GroupID := GetGroup(ListView, GroupName, True);

          if Stopping then
          begin
            Log(['�������� ��������� ����������� ��������', GetLastError]);
            Result := gsStopped;
            Break;
          end;
        end;
      CloseKey;
    end;
  end;

 //------------------
 //------------------������ ��������� ������������------------------------------
  if not Stopping then
  begin
    UsersPaths := GetARDirectores;
    for i := 0 to UsersPaths.Count - 1 do
    begin
      ListAutoRun.Clear;
      ScanDir(UsersPaths[i], '*.*', ListAutoRun);
      for j := 0 to ListAutoRun.Count - 1 do
        with ListView.Items do
        begin
          if Stopping then
          begin
            Log(['�������� ��������� ����������� ��������', GetLastError]);
            Result := gsStopped;
            Break;
          end;
          if ExtractFileExt(ListAutoRun[j]) = '.ini' then
          begin
            Log(['������ ���� � �������� ��, ��������', ListAutoRun[j], GetLastError]);
            Continue;
          end;
          AData.IsRegType := False;
          AData.RegName := GetFileNameWoE(ExtractFileName(ListAutoRun[j]));
          AData.Cmd := ListAutoRun[j];
          if LowerCase(ExtractFileExt(AData.Cmd)) = '.lnk' then
            AData.Cmd := NormFileNameF(GetFileNameFromLink(AData.Cmd));
          AData.DisplayName := GetFileDescription(AData.Cmd, '');
          AData.Exists := FileExists(AData.Cmd);
          AData.RegPath := ListAutoRun[j];
          AData.RegRoot := 0;

          ListItem := Add;
          ListItem.Data := AllocMem(SizeOf(AData));
          TAutorunData(ListItem.Data^) := AData;

          ListItem.Caption := AData.DisplayName;
          ListItem.Checked := not AData.Exists;
          SIELEM := ListItem.SubItems.Add(AData.Cmd);      //�������
          SIFLAG := ListItem.SubItems.Add(BoolToLang(AData.Exists));      //���.

          try
            FullName := AData.Cmd;
            NormFileName(FullName);
            if FileExists(FullName) then
            begin
              if GetFileIcon(FullName, is16, ListView.SmallImages, II) > 0 then
                ListItem.ImageIndex := II
            end
            else
              ListItem.ImageIndex := DI;
          except
            Log(['�� ���� ��������� ������ �� �����: ', FullName, GetLastError]);
          end;

          ListItem.GroupID := GetGroup(ListView, '�������: ' + UsersPaths[i], True);
        end;
     //--------------------
      if Stopping then
      begin
        Log(['�������� ��������� ����������� ��������', GetLastError]);
        Result := gsStopped;
        Break;
      end;
    end;
    UsersPaths.Free;
  end;
  ListAutoRun.Free;
  ListView.Items.EndUpdate;
  Inform(LangText(-1, '������ ��������� ����������� ������� �������.'));
  OnChanged;
  if Result <> gsStopped then
    Result := gsFinished;
end;

procedure TAutorunUnit.Clear;
var
  i: Integer;
begin
  if Assigned(FListView) then
  begin
    for i := 0 to FListView.Items.Count - 1 do
    begin
      FreeMemory(FListView.Items[i].Data);
    end;
    FListView.Items.BeginUpdate;
    FListView.Items.Clear;
    FListView.Items.EndUpdate;
  end;
end;

constructor TAutorunUnit.Create;
begin
  FDisableIcon := TIcon.Create;
  inherited;
end;

destructor TAutorunUnit.Destroy;
begin
  Clear;
  if Assigned(FListView) then
  begin
    FListView.SmallImages.Free;
  end;
  FDisableIcon.Free;
  inherited;
end;

function TAutorunUnit.GetARDirectores: TStringList;
var
  SFolder: PItemIDList;
  OBuf, OBuf2: array[0..2048] of WideChar;
begin
  Result := TStringList.Create;
  if SUCCEEDED(SHGetSpecialFolderLocation(0, CSIDL_STARTUP, SFolder)) then
  begin
    if Assigned(SFolder) then
      if SHGetPathFromIDList(SFolder, @OBuf) then
        Result.Add(Trim(StrPas(OBuf)));
  end;

  if SUCCEEDED(SHGetSpecialFolderLocation(0, CSIDL_ALTSTARTUP, SFolder)) then
  begin
    if Assigned(SFolder) then
      if SHGetPathFromIDList(SFolder, @OBuf2) then
        if Trim(StrPas(OBuf)) <> Trim(StrPas(OBuf2)) then
          Result.Add(Trim(StrPas(OBuf2)));
  end;

  if SUCCEEDED(SHGetSpecialFolderLocation(0, CSIDL_COMMON_STARTUP, SFolder)) then
  begin
    if Assigned(SFolder) then
      if SHGetPathFromIDList(SFolder, @OBuf) then
        Result.Add(Trim(StrPas(OBuf)));
  end;

  if SUCCEEDED(SHGetSpecialFolderLocation(0, CSIDL_COMMON_ALTSTARTUP, SFolder)) then
  begin
    if Assigned(SFolder) then
      if SHGetPathFromIDList(SFolder, @OBuf2) then
        if Trim(StrPas(OBuf)) <> Trim(StrPas(OBuf2)) then
          Result.Add(Trim(StrPas(OBuf2)));
  end;
end;

procedure TFormAutorun.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE:
      Close;
  end;
end;

end.

