unit Module.WinFirewall;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  CMW.ModuleStruct, Firewall, CMW.OSInfo, CMW.Utils, ActiveX, ComObj,
  Vcl.ComCtrls, Vcl.ImgList, Winapi.ShellAPI;

type
  TFormFirewall = class(TForm)
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  TFirewallUnit = class(TSystemUnit)
  private
    FMode: Word;
    FDisableIcon: TIcon;
    FServIcon: TIcon;
    //Roll:TRegistry;
    function FEnabled: Boolean;
    procedure SetEnable(Value: Boolean);
    procedure CheckNetService;
  public
    function FGet: TGlobalState; override;
    procedure OnChanged; override;
    procedure Get(Mode: Word); overload;
    procedure Disable;
    procedure Enable;
    property Enabled: Boolean read FEnabled write SetEnable;
    procedure Initialize; override;
    procedure Stop; override;
    property DisableIcon: TIcon read FDisableIcon write FDisableIcon;
    property ServiceIcon: TIcon read FServIcon write FServIcon;
    constructor Create; override;
    destructor Destroy; override;
  end;

const
  FWModeRules = 0;
  FWModeServices = 1;
  FWModeInfo = 2;

var
  FormFirewall: TFormFirewall;

implementation

uses
  Module.WinServices;

{$R *.dfm}

procedure TFirewallUnit.Get(Mode: Word);
begin
  FMode := Mode;
  inherited Get;
end;

procedure TFirewallUnit.Initialize;
begin
 //
end;

procedure TFirewallUnit.OnChanged;
begin
  inherited;
  OnListViewSort;
end;

procedure TFirewallUnit.Stop;
begin
  inherited;
end;

function TFirewallUnit.FGet: TGlobalState;
var
  ListItem: TListItem;
  DI: Integer;
  objFirewall, objPolicy, objApplication, colApplications: OleVariant;
  IEnum: IEnumVariant;
  Count: LongWord;
  objService, colServices: OleVariant;
  Count1: LongWord;
  FullName: string;
  II: Word;
  Icon: HICON;
  IconN: TIcon;
begin
  Inform(LangText(-1, 'Получение информации о брандмауэре Windows...'));
  Result := gsProcess;
  ListView.Items.BeginUpdate;
  ListView.Items.Clear;
  ListView.Groups.Clear;
  ListView.GroupView := FGrouping;
  ListView.Columns.Clear;
  if not Assigned(ListView.SmallImages) then
    ListView.SmallImages := TImageList.Create(nil)
  else
    ListView.SmallImages.Clear;
  ListView.SmallImages.Width := 16;
  ListView.SmallImages.Height := 16;
  ListView.SmallImages.ColorDepth := cd32Bit;
  if not Assigned(FDisableIcon) then
    DI := -1
  else
    DI := ListView.SmallImages.AddIcon(FDisableIcon);
 //
  case FMode of
    FWModeRules:
      begin
        try
          begin
            with ListView.Columns.Add do
            begin
              Caption := 'Приложение';
              Width := 200;
            end;
            with ListView.Columns.Add do
            begin
              Caption := 'Состояние';
              Width := 90;
            end;
            with ListView.Columns.Add do
            begin
              Caption := 'Протокол';
              Width := 90;
            end;
            with ListView.Columns.Add do
            begin
              Caption := 'Образ';
              Width := 250;
              AutoSize := True;
            end;
            with ListView.Columns.Add do
            begin
              Caption := 'Удалённый адрес';
              Width := 120;
            end;
            with ListView.Columns.Add do
            begin
              Caption := 'Scope';
              Width := 80;
            end;
            CoInitialize(nil);
            objFirewall := CreateOLEObject('HNetCfg.FwMgr');
            objPolicy := objFirewall.LocalPolicy.CurrentProfile;
            colApplications := objPolicy.AuthorizedApplications;
            IEnum := IUnKnown(colApplications._NewEnum) as IEnumVariant;
            while IEnum.Next(1, objApplication, Count) = S_OK do
              with ListView.Items do
              begin
                ListItem := Add;
                CreateSubItems(ListItem, 5);
                ListItem.Caption := objApplication.Name;
                FullName := objApplication.ProcessImageFileName;
                ListItem.SubItems[0] := BoolStr(objApplication.Enabled, 'Разрешено', 'Запрещено');
                ListItem.SubItems[1] := FW_IP_VERSION[integer(objApplication.IPVersion)];
                ListItem.SubItems[2] := FullName;
                ListItem.SubItems[3] := objApplication.RemoteAddresses;
                ListItem.SubItems[4] := BoolStr(objApplication.Scope, 'True', 'False');
                try
                  FullName := objApplication.ProcessImageFileName;
                  NormFileName(FullName);
                  if FileExists(FullName) then
                  begin
                    II := 0;
                    Icon := ExtractAssociatedIcon(hInstance, PChar(FullName), II);
                    IconN := TIcon.Create;
                    IconN.Handle := Icon;
                    ListItem.ImageIndex := ListView.SmallImages.AddIcon(IconN);
                    IconN.Free;
                  end
                  else
                    ListItem.ImageIndex := DI;
                except
                  Log(['Не смог загрузить иконку из файла:', FullName, GetLastError]);
                end;
                if Stopping then
                  Exit(gsStopped);
              end;
          end;
        except
          begin
            Log(['Ошибка при получении списка правил брандмауэра Windows.', SysErrorMessage(GetLastError)]);
            Exit(gsError);
          end;
        end;
      end;
    FWModeServices:
      begin
        try
          if Assigned(FServIcon) then
            DI := ListView.SmallImages.AddIcon(FServIcon);
          with ListView.Columns.Add do
          begin
            Caption := 'Служба';
            Width := 200;
          end;
          with ListView.Columns.Add do
          begin
            Caption := 'Состояние';
            Width := 90;
          end;
          with ListView.Columns.Add do
          begin
            Caption := 'Тип';
            Width := 100;
            AutoSize := True;
          end;
          with ListView.Columns.Add do
          begin
            Caption := 'Протокол';
            Width := 90;
          end;
          with ListView.Columns.Add do
          begin
            Caption := 'Удалённый адрес';
            Width := 120;
          end;
          with ListView.Columns.Add do
          begin
            Caption := 'Scope';
            Width := 80;
          end;
          with ListView.Columns.Add do
          begin
            Caption := 'Customized';
            Width := 90;
          end;
          CoInitialize(nil);
          objFirewall := CreateOLEObject('HNetCfg.FwMgr');  //CurrentProfile
          objPolicy := objFirewall.LocalPolicy.CurrentProfile;
          colServices := objPolicy.Services;

          IEnum := IUnKnown(colServices._NewEnum) as IEnumVariant;
          while IEnum.Next(1, objService, Count1) = S_OK do
            with ListView.Items do
            begin
              ListItem := Add;
              ListItem.SubItems.Add('');
              ListItem.SubItems.Add('');
              ListItem.SubItems.Add('');
              ListItem.SubItems.Add('');
              ListItem.SubItems.Add('');
              ListItem.SubItems.Add('');
              ListItem.ImageIndex := DI;
              ListItem.Caption := objService.Name;
              ListItem.SubItems[0] := BoolStr(objService.Enabled, 'Разрешено', 'Запрещено');
              ListItem.SubItems[1] := IntToStr(objService.type);
              ListItem.SubItems[2] := FW_IP_VERSION[integer(objService.IPVersion)];
              ListItem.SubItems[3] := objService.RemoteAddresses;
              ListItem.SubItems[4] := BoolStr(objService.Scope, 'True', 'False');
              ListItem.SubItems[5] := BoolStr(objService.Customized, 'True', 'False');
            end;
        except
          begin
            Log(['Ошибка при получении списка служб брандмауэра Windows.', SysErrorMessage(GetLastError)]);
            Exit(gsError);
          end;
        end;
      end;
    FWModeInfo:
      begin
        try
          CoInitialize(nil);
          objFirewall := CreateOLEObject('HNetCfg.FwMgr');
          objPolicy := objFirewall.LocalPolicy.CurrentProfile;
          with ListView.Columns.Add do
          begin
            Caption := ' ';
            Width := 200;
          end;
          with ListView.Columns.Add do
          begin
            Caption := ' ';
            Width := 250;
          end;

          with ListView.Items.Add do
          begin
            Caption := 'Тип текущего профиля';
            SubItems.Add(FW_PROFILE[Integer(objFirewall.CurrentProfileType)]);
            ImageIndex := DI;
          end;
          with ListView.Items.Add do
          begin
            Caption := 'Состояние брандмауэра';
            if Integer(objPolicy.FirewallEnabled) = VRAI then
              SubItems.Add('Включен')
            else
              SubItems.Add('Отключен');
            ImageIndex := DI;
          end;
          with ListView.Items.Add do
          begin
            Caption := 'Исключения разрешены';
            if Integer(objPolicy.ExceptionsNotAllowed) = VRAI then
              SubItems.Add('Нет')
            else
              SubItems.Add('Да');
            ImageIndex := DI;
          end;
          with ListView.Items.Add do
          begin
            Caption := 'Уведомления отключены';
            if Integer(objPolicy.NotificationsDisabled) = VRAI then
              SubItems.Add('Да')
            else
              SubItems.Add('Нет');
            ImageIndex := DI;
          end;
          with ListView.Items.Add do
          begin
            Caption := 'Unicast responses to multicast broadcast disabled';
            if Integer(objPolicy.UnicastResponsestoMulticastBroadcastDisabled) = VRAI then
              SubItems.Add('Да')
            else
              SubItems.Add('Нет');
            ImageIndex := DI;
          end;
        except
          begin
            Log(['Ошибка при получении информации о брандмауэре Windows.', SysErrorMessage(GetLastError)]);
            Exit(gsError);
          end;
        end;
      end;
  end;

  Inform(LangText(-1, 'Информация о брендмауэре Windows успешно получена.'));
  OnChanged;
  try
    Result := gsFinished;
  except
    Exit;
  end;
end;

constructor TFirewallUnit.Create;
begin
  inherited;
  FDisableIcon := TIcon.Create;
  FServIcon := TIcon.Create;
 {
 try
  Roll:=TRegistry.Create(KEY_ALL_ACCESS);
  FRestrictions:=False;
 except
  FRestrictions:=True;
 end;
 if FRestrictions then
  try
   Roll:=TRegistry.Create(KEY_READ);
   FRestrictions:=False;
  except
   FRestrictions:=True;
  end; }
end;

destructor TFirewallUnit.Destroy;
begin
  if Assigned(ListView.SmallImages) then
    ListView.SmallImages.Free;
  FDisableIcon.Free;
  FServIcon.Free;
  inherited;
end;

procedure TFirewallUnit.CheckNetService;
var
  ShellApplication: OleVariant;
  Freeze: Cardinal;
begin
  ShellApplication := CreateOleObject('Shell.Application');
  if not ShellApplication.IsServiceRunning('SharedAccess') then
  begin
    ShellApplication.ServiceStart('SharedAccess', True);
    Freeze := GetTickCount + 2000;
    while Freeze > GetTickCount do
      Application.ProcessMessages;
  end;
  FreeAndNil(ShellApplication);
end;

function TFirewallUnit.FEnabled: Boolean;
var
  objPolicy, objFirewall: OleVariant;
begin
  if not ServiceIsWorking('MpsSvc') then
    Exit(False);
  try
    CoInitialize(nil);
    objFirewall := CreateOLEObject('HNetCfg.FwMgr');
    objPolicy := objFirewall.LocalPolicy.CurrentProfile;
    Result := (Integer(objPolicy.FirewallEnabled) = VRAI);
  except
    begin
      Log(['Не смог запустить службу Брандмауэра Windows. objFirewall:=CreateOLEObject("HNetCfg.FwMgr");']);
      ShowMessage('Не смог запустить службу Брандмауэра Windows.');
      Result := False;
    end;
  end;
end;

procedure TFirewallUnit.SetEnable(Value: Boolean);
begin
  if Value then
    Enable
  else
    Disable;
end;

procedure TFirewallUnit.Disable;
begin
  try
    if not FirewallEnabled(FAUX) then
    begin
      ShowMessage('Не смог изменить состояние брандмауэра.');
      Exit;
    end;
  except
    Log(['Не смог изменить состояние брандмауэра.']);
  end;
end;

procedure TFirewallUnit.Enable;
begin
  try
    if not FirewallEnabled(VRAI) then
    begin
      ShowMessage('Не смог изменить состояние брандмауэра.');
      Exit;
    end;
  except
    Log(['Не смог изменить состояние брандмауэра.']);
  end;
end;

procedure TFormFirewall.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE:
      Close;
  end;
end;

end.

