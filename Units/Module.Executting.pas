unit Module.Executting;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  CMW.ModuleStruct, Vcl.ExtCtrls, Vcl.ComCtrls, CMW.Utils, Vcl.ImgList,
  CMW.OSInfo;

type
  TFormExec = class(TForm)
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  TExecuteUnit = class(TSystemUnit)
  private
    FDisableIcon: TIcon;
    FDirIcon: TIcon;
    procedure ListViewImPathsDblClick(Sender: TObject);
  public
    function FGet: TGlobalState; override;
    procedure OnChanged; override;
    procedure Initialize; override;
    function Delete(LI: TListItem): Boolean;
    procedure Stop; override;
    constructor Create; override;
    destructor Destroy; override;
    property DisableIcon: TIcon read FDisableIcon write FDisableIcon;
    property DirIcon: TIcon read FDirIcon write FDirIcon;
  end;

const
  FPath = 1;
  FFile = 2;

var
  FormExec: TFormExec;

function RunCommand(Command, Parameters: string): Boolean;

implementation

uses
  System.IniFiles, Winapi.ShellAPI;


{$R *.dfm}

function RunCommand(Command, Parameters: string): Boolean;
var
  TryMore: Boolean;
  res: Integer;
begin
  Result := False;
  res := WinExec(PWideChar(Command + ' ' + Parameters), SW_NORMAL);
  case res of
    SE_ERR_FNF:
      begin
        TryMore := True;
        Log(['������� �1 - ���� �� ������.']);
      end;        { file not found }
    SE_ERR_PNF:
      begin
        TryMore := True;
        Log(['������� �1 - ���� �� ������.']);
      end;        { path not found }
    SE_ERR_ACCESSDENIED:
      begin
        TryMore := True;
        Log(['������� �1 - ��� �������.']);
      end;           { access denied  }
    SE_ERR_OOM:
      begin
        TryMore := True;
        Log(['������� �1 - �� ������� ������.']);
      end;     { out of memory  }
    SE_ERR_DLLNOTFOUND:
      begin
        TryMore := True;
        Log(['������� �1 - ���������� �� ��������.']);
      end; { dll not found  }
    0:
      begin
        TryMore := True;
        Log(['������� �1 - ������� �� ���������.']);
      end;
  else
    begin
      TryMore := False;
      Log(['������� �1 - ��������� �������:', Command + ' ' + Parameters, res]);
    end;
  end;
  if not TryMore then
    Exit(True);
  res := ShellExecute(0, 'open', PWideChar(Command), PWideChar(Parameters), '', SW_NORMAL);
  case res of
    SE_ERR_FNF:
      begin
        TryMore := True;
        Log(['������� �2 - ���� �� ������.']);
      end;        { file not found }
    SE_ERR_PNF:
      begin
        TryMore := True;
        Log(['������� �2 - ���� �� ������.']);
      end;        { path not found }
    SE_ERR_ACCESSDENIED:
      begin
        TryMore := True;
        Log(['������� �2 - ��� �������.']);
      end;           { access denied  }
    SE_ERR_OOM:
      begin
        TryMore := True;
        Log(['������� �2 - �� ������� ������.']);
      end;     { out of memory  }
    SE_ERR_DLLNOTFOUND:
      begin
        TryMore := True;
        Log(['������� �2 - ���������� �� ��������.']);
      end; { dll not found  }
    0:
      begin
        TryMore := True;
        Log(['������� �2 - ������� �� ���������.']);
      end;
    SE_ERR_SHARE:
      begin
        TryMore := True;
        Log(['������� �2 - SE_ERR_SHARE.']);
      end;
    SE_ERR_ASSOCINCOMPLETE:
      begin
        TryMore := True;
        Log(['������� �2 - SE_ERR_ASSOCINCOMPLETE.']);
      end;
    SE_ERR_DDETIMEOUT:
      begin
        TryMore := True;
        Log(['������� �2 - SE_ERR_DDETIMEOUT.']);
      end;
    SE_ERR_DDEFAIL:
      begin
        TryMore := True;
        Log(['������� �2 - SE_ERR_DDEFAIL.']);
      end;
    SE_ERR_DDEBUSY:
      begin
        TryMore := True;
        Log(['������� �2 - SE_ERR_DDEBUSY.']);
      end;
    SE_ERR_NOASSOC:
      begin
        TryMore := True;
        Log(['������� �2 - SE_ERR_NOASSOC.']);
      end;
  else
    begin
      TryMore := False;
      Log(['������� �2 - ��������� �������:', Command + ' ' + Parameters, res]);
    end;
  end;
  if TryMore then
  begin
    Log(['������� �� ���������. ', Command + ' ' + Parameters, res]);
    ShowMessage('������� �� ���������.');
    Result := False;
  end
  else
    Result := True;
end;

procedure TExecuteUnit.Initialize;
begin
  ListView.OnDblClick := ListViewImPathsDblClick;
  ListView.SmallImages := TImageList.CreateSize(16, 16);
  ListView.SmallImages.ColorDepth := cd32Bit;
end;

function TExecuteUnit.Delete(LI: TListItem): Boolean;
begin
  Result := True;
end;

procedure TExecuteUnit.OnChanged;
begin
  inherited;
  OnListViewSort;
end;

procedure TExecuteUnit.Stop;
begin
  inherited;
end;

function TExecuteUnit.FGet: TGlobalState;
var
  i, j: Integer;
  ListItem: TListItem;
  II: Word;
  Icon: HICON;
  IconN: TIcon;
  DI, FI: Integer;
  Ini: TIniFile;
  ListOfImP: TStrings;
  SPath, Section: string;
  SIndex: Word;
  IDGroup: Word;
begin
  Inform(LangText(-1, '���� �������� ������...'));
  Result := gsProcess;
  ListView.Items.BeginUpdate;
  ListView.Items.Clear;
  ListView.Groups.Clear;
  ListView.GroupView := FGrouping;
  ListView.SmallImages.Clear;
  if not Assigned(FDisableIcon) then
    DI := -1
  else
    DI := ListView.SmallImages.AddIcon(FDisableIcon);
  if not Assigned(FDisableIcon) then
    FI := -1
  else
    FI := ListView.SmallImages.AddIcon(FDirIcon);

  try
    Ini := TIniFile.Create(CurrentDir + '\Data\ImPaths.inf');
  except
    begin
      Inform(LangText(-1, '�� ���� ������� ���� "\Data\ImPaths.inf": ' + SysErrorMessage(GetLastError)));
      Log(['�� ���� ������� ���� "\Data\ImPaths.inf":', SysErrorMessage(GetLastError)]);
      Exit(gsError);
    end;
  end;
  ListOfImP := TStringList.Create;
  for j := 0 to 1 do
  begin
    case j of
      0:
        begin
          SIndex := FPath;
          Section := 'Paths';
          IDGroup := GetGroup(ListView, '��������', True);
        end;
    else
      begin
        SIndex := FFile;
        Section := 'Exec';
        IDGroup := GetGroup(ListView, '��������', True);
      end;

    end;
    ListOfImP.Clear;
    Ini.ReadSection(Section, ListOfImP);
    if ListOfImP.Count > 0 then
    begin
      for i := 0 to ListOfImP.Count - 1 do
        with ListView.Items do
        begin
          ListItem := Add;
          ListItem.Caption := ListOfImP.Strings[i];
          SPath := ReplaceSysVarF(Ini.ReadString(Section, ListOfImP.Strings[i], 'none'));
          ListItem.SubItems.Add(SPath);
          ListItem.ImageIndex := DI;
          if FLoadIcons then
          begin
            NormFileName(SPath);
            if FileExists(SPath) then
            begin
              try
                II := 0;
                Icon := ExtractAssociatedIcon(0, PWideChar(SPath), II);
                if Icon > 0 then
                begin
                  IconN := TIcon.Create;
                  IconN.Handle := Icon;
                  ListItem.ImageIndex := ListView.SmallImages.AddIcon(IconN);
                  FreeAndNil(IconN);
                end;
              except
                Log(['������ ��� �������� ������ ��� ��������', SPath]);
              end;
            end
            else if DirectoryExists(SPath) then
              ListItem.ImageIndex := FI;
          end;
          ListItem.StateIndex := SIndex;
          ListItem.GroupID := IDGroup;
          if Stopping then
            Exit(gsStopped);
        end;
    end;
  end;
  FreeAndNil(ListOfImP);

 //------------getting
  Inform(LangText(-1, '������ ��������� ������� �������.'));
  OnChanged;
  try
    Result := gsFinished;
  except
    Exit;
  end;
end;

procedure TExecuteUnit.ListViewImPathsDblClick(Sender: TObject);
var
  ImPath: string;
begin
  if ListView.Selected = nil then
    Exit;
  ImPath := ListView.Selected.SubItems[0];
  case ListView.Selected.StateIndex of
    FPath:
      begin
        if not DirectoryExists(ImPath) then
        begin
          if MessageBox(Application.Handle, PChar(LangText(107, '��������� ���� �� ����������! ���������� ���������� �������?')), PChar(LangText(41, '��������')), MB_ICONEXCLAMATION or MB_YESNO) <> ID_YES then
            Exit;
        end;
        RunCommand(ImPath, '');
      end;
    FFile:
      begin
        RunCommand(ImPath, '');
      end;
  end;
end;

constructor TExecuteUnit.Create;
begin
  inherited;
  FDisableIcon := TIcon.Create;
  FDirIcon := TIcon.Create;
end;

destructor TExecuteUnit.Destroy;
begin
  ListView.SmallImages.Free;
  //FDisableIcon.Free;
  //FDirIcon.Free;
  inherited;
end;

procedure TFormExec.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE:
      Close;
  end;
end;

end.

