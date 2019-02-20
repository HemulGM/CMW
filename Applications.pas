unit Applications;

interface
 uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Vcl.ImgList,
  Dialogs, ExtCtrls, ComCtrls, System.Win.Registry, ShellAPI, Vcl.StdCtrls, Vcl.ValEdit,
  //
  COCUtils, StructUnit, Utils, OSInfo, Vcl.Grids;
  //

 type
  TApplicationUnit = class;
  TFormApp = class(TForm)
    EditDisplayName: TEdit;
    Panel1: TPanel;
    Bevel1: TBevel;
    ButtonClose: TButton;
    LabelPermission: TLabel;
    ValueListEditor1: TValueListEditor;
    ButtonDelRKEY: TButton;
    procedure ButtonCloseClick(Sender: TObject);
    procedure ButtonDelRKEYClick(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FLastApp:^TApplicationUnit;
  public
    { Public declarations }
  end;

  TApplicationUnit = class(TSystemUnit)
    REGSI:Word;
    UNISI:Word;
    VERSI:Word;
    PATHSI:Word;
    SIDATE:Word;
    SIPUB:WORD;
    SISIZE:WORD;

   private
    DI:Integer;
    MSGr:Word;
    ListInstalls:TStringList;
    FDisableIcon:TIcon;
    function ExistsPathKey(Ident:string):Boolean;
    function GetUninstallInfo(Roll:TRegistry; RHKEY:HKEY; RollPath, Ident:string; Item:TListItem):Boolean;
    function GetAppKeyName(Name:string):string;
    procedure ListViewWinAppsDblClick(Sender: TObject);
   public
    function FGet:TGlobalState; override;
    procedure OnChanged; override;
    procedure Initialize; override;
    function SelectedName:string;
    function InsertInfo(ValueListEditor:TValueListEditor; WithEmpty:Boolean; var AccessError:Boolean):Boolean;
    procedure OpenInstalledPath;
    procedure OpenUninstalledFile;
    function DeleteSelected:Boolean;
    function DeleteItem(LI:TListItem):Boolean;
    function DeleteChecked:Boolean;
    function DeleteRollKey:Boolean; overload;
    function DeleteRollKey(RKEY:string):Boolean; overload;
    procedure CheckItems;
    procedure Stop; override;
    constructor Create; override;
    destructor Destroy; override;
    property DisableIcon:TIcon read FDisableIcon write FDisableIcon;
  end;

const
  RKEYName = 'Ключ реестра';

var
  FormApp:TFormApp;

  procedure ShowAppInfo(Apps:TApplicationUnit);

implementation
 uses Main;

{$R *.dfm}

procedure ShowAppInfo;
var Perm:Boolean;
    Old:Integer;
begin
 with FormApp do
  begin
   FLastApp:=@Apps;
   if Apps.InsertInfo(ValueListEditor1, True, Perm) then
    begin
     LabelPermission.Visible:=Perm;
     ButtonDelRKEY.Visible:=not LabelPermission.Visible;
     if ValueListEditor1.Strings.Count * ValueListEditor1.RowHeights[0] + 4 <= 400 then
      ValueListEditor1.Height:=ValueListEditor1.Strings.Count * ValueListEditor1.RowHeights[0] + 4
     else ValueListEditor1.Height:=400;
     Old:=ValueListEditor1.Height;
     ClientHeight:=ValueListEditor1.Top + ValueListEditor1.Height + 50;
     ValueListEditor1.Height:=Old;
     EditDisplayName.Text:=Apps.SelectedName;
     ShowModal;
    end;
  end;
end;

procedure TApplicationUnit.Initialize;
begin
 ListView.OnDblClick:=ListViewWinAppsDblClick;
end;

procedure TApplicationUnit.ListViewWinAppsDblClick(Sender: TObject);
begin
 ShowAppInfo(Self);
end;

function TApplicationUnit.DeleteRollKey(RKEY:string):Boolean;
var FRoll:TRegistry;
    Ident, StrKey:string;
begin
 Result:=False;
 if RKEY.Length < 2 then
  begin
   MessageBox(Application.Handle, 'Неверный ключ реестра', 'Ошибка', MB_ICONERROR or MB_OK);
   Exit;
  end;
 Ident:=RKEY;
 FRoll:=TRegistry.Create(RootAccess);
 StrKey:=Copy(Ident, 1, 4);
 FRoll.RootKey:=StrKeyToRoot(StrKey);
 Delete(Ident, 1, 4);
 if FRoll.OpenKey(Ident, False) then
  begin
   if MessageBox(Application.Handle, PWideChar(Format('Вы действительно хотите удалить следующий ключ реестра: %s\%s?', [RootKeyToStr(FRoll.RootKey), FRoll.CurrentPath])), 'Внимание', MB_ICONASTERISK or MB_YESNO) <> ID_YES then Exit;
   FRoll.CloseKey;
   //ShowMessage('deletting');
   Log(['Программы и компоненты: Удалён ключ программы удаления', Strkey+Ident]);
   Result:=FRoll.DeleteKey(Ident);
  end
 else
  begin
   Log(['Программы и компоненты: Ключ не смог быть удалён', Strkey+Ident]);
   if FRoll.KeyExists(Ident) then
    MessageBox(Application.Handle, PWideChar('Не могу получить доступ к нужной ветке реестра.'), 'Внимание', MB_ICONERROR or MB_OK)
   else MessageBox(Application.Handle, PWideChar('Ключ не существует, либо не хватает прав для доступка к ветке реестра.'), 'Внимание', MB_ICONINFORMATION or MB_OK);
  end;
 FRoll.Free;
end;

function TApplicationUnit.DeleteRollKey:Boolean;
begin
 if ListView.Selected = nil then Exit(False);
 Result:=DeleteRollKey(ListView.Selected.SubItems[REGSI]);
end;

function TApplicationUnit.GetAppKeyName(Name:string):string;
begin
 Result:=Name;
 if Name = 'Comments' then Exit('Комментарии');
 if Name = 'Contact' then Exit('Контакты');
 if Name = 'DisplayName' then Exit('Отображаемое имя');
 if Name = 'DisplayVersion' then Exit('Версия');
 if Name = 'EstimatedSize' then Exit('Размер (КБ)');
 if Name = 'Size' then Exit('Размер (КБ)');
 if Name = 'HelpLink' then Exit('Справка');
 if Name = 'HelpTelephone' then Exit('Тех. поддержка');
 if Name = 'InstallDate' then Exit('Дата установки');
 if Name = 'InstallLocation' then Exit('Каталог установки');
 if Name = 'InstallPath' then Exit('Каталог установки');

 if Name = 'InstallSource' then Exit('Каталог установщика');
 if Name = 'ModifyPath' then Exit('Исправление');
 if Name = 'NoModify' then Exit('Флаг исправления');
 if Name = 'NoRepair' then Exit('Флаг восстановления');
 if Name = 'Publisher' then Exit('Производитель');
 if Name = 'Language' then Exit('Язык');
 if Name = 'Readme' then Exit('Readme файл');
 if Name = 'UninstallString' then Exit('Удаление');

 if Name = 'URLInfoAbout' then Exit('Ссылка для справки');
 if Name = 'URLUpdateInfo' then Exit('Ссылка для обновления');
 if Name = 'Version' then Exit('Тех. версия');
 if Name = 'VersionMajor' then Exit('Тех. версия выс.');
 if Name = 'VersionMinor' then Exit('Тех. версия низ.');
 if Name = 'WindowsInstaller' then Exit('Флаг установщика Win.');
 if Name = 'SystemComponent' then Exit('Флаг сис. компонента');

 if Name = 'Inno Setup: App Path' then Exit('Каталог установки Inno Setup');
 if Name = 'Inno Setup: Deselected Components' then Exit('Искл. компоненты Inno Setup');
 if Name = 'Inno Setup: Icon Group' then Exit('Иконка Inno Setup');
 if Name = 'DisplayIcon' then Exit('Иконка');
 if Name = 'QuietUninstallString' then Exit('Скрытое удаление');
 if Name = 'UninstallDataFile' then Exit('Инф. удаления');
 if Name = 'Inno Setup: Language' then Exit('Язык Inno Setup');
 if Name = 'Inno Setup: Selected Components' then Exit('Выбран. компоненты Inno Setup');
 if Name = 'Inno Setup: Setup Type' then Exit('Тип установки Inno Setup');
 if Name = 'Inno Setup: Setup Version' then Exit('Версия установки Inno Setup');
 if Name = 'Inno Setup: User' then Exit('Пользователь Inno Setup');

 if Name = 'InstallSourceFile' then Exit('Файл установщика');
 if Name = 'SilentSettings' then Exit('Файл параметров уст.');
end;

function TApplicationUnit.SelectedName:string;
begin
 if ListView.Selected = nil then Exit('');
 Result:=ListView.Selected.Caption;
end;

function GetValueNames(Rl:TRegistry; Strings: TStrings):Boolean;
var
  Len: DWORD;
  I: Integer;
  Info: TRegKeyInfo;
  S: string;
begin
 Result:=False;
 Strings.Clear;
 if Rl.GetKeyInfo(Info) then
  begin
   SetString(S, nil, Info.MaxValueLen + 1);
   for I := 0 to Info.NumValues - 1 do
    begin
     Len := Info.MaxValueLen + 1;
     RegEnumValue(Rl.CurrentKey, I, PChar(S), Len, nil, nil, nil, nil);
     Strings.Add(PChar(S));
    end;
   Result:=True;
  end;
end;

function TApplicationUnit.InsertInfo(ValueListEditor:TValueListEditor; WithEmpty:Boolean; var AccessError:Boolean):Boolean;
var Ident:string;
    Values:TStrings;
    i:Word;
begin
 Result:=False;
 if ListView.Selected = nil then Exit;
 if ListView.Selected.SubItems.Count < 2 then
  begin
   Log(['Обращение к SubItem записи ListView вне границы', ListView, ListView.Selected.SubItems.Count, 1]);
   Exit;
  end;
 AccessError:=False;
 Ident:=ListView.Selected.SubItems[REGSI];
 Roll.RootKey:=StrKeyToRoot(Copy(Ident, 1, 4));
 Delete(Ident, 1, 4);
 ValueListEditor.Strings.Clear;
 if Roll.OpenKeyReadOnly(Ident) then
  begin
   Values:=TStringList.Create;
   if GetValueNames(Roll, Values) then
    begin
     if Values.Count > 0 then
      begin
       for i:=0 to Values.Count - 1 do
        begin
         AddToValueEdit(ValueListEditor, GetAppKeyName(Values[i]), Roll.GetDataAsString(Values[i], False), '');
        end;
      end;
    end
   else AccessError:=True;
   AddToValueEdit(ValueListEditor, RKEYName, RootKeyToStr(Roll.RootKey)+'\'+Roll.CurrentPath, '');
  end
 else AccessError:=True;
 Result:=True;
end;

procedure TApplicationUnit.OpenUninstalledFile;
var Ident:string;
begin
 if ListView.Selected = nil then Exit;
 if ListView.Selected.SubItems.Count < 2 then
  begin
   Log(['Обращение к SubItem записи ListView вне границы', ListView, ListView.Selected.SubItems.Count, 1]);
   Exit;
  end;
 Ident:=ListView.Selected.SubItems[UNISI];
 NormFileName(Ident);
 if Ident <> '' then OpenFolderAndSelectFile(Ident)
 else MessageBox(Application.Handle, 'Нет допустимого расположения для выбранного элемента.', 'Внимание', MB_ICONINFORMATION or MB_OK);
end;

procedure TApplicationUnit.OpenInstalledPath;
var Ident:string;
begin
 if ListView.Selected = nil then Exit;
 if ListView.Selected.SubItems.Count < 2 then
  begin
   Log(['Обращение к SubItem записи ListView вне границы', ListView, ListView.Selected.SubItems.Count, 1]);
   Exit;
  end;
 Ident:=ListView.Selected.SubItems[REGSI];
 Roll.RootKey:=StrKeyToRoot(Copy(Ident, 1, 4));
 Delete(Ident, 1, 4);
 if Roll.OpenKey(Ident, False) then
  begin
   if Roll.ValueExists('InstallLocation') then Ident:=Roll.ReadString('InstallLocation')
   else
   if Roll.ValueExists('InstallPath') then Ident:=Roll.ReadString('InstallPath')
   else
   if Roll.ValueExists('UninstallString') then Ident:=ExtractFilePath(NormFileNameF(Roll.ReadString('UninstallString')))
   else
   if Roll.ValueExists('DisplayIcon') then Ident:=ExtractFilePath(NormFileNameF(Roll.ReadString('DisplayIcon')))
   else Ident:='';
   if Ident <> '' then OpenFolderAndSelectFile(Ident)
   else MessageBox(Application.Handle, 'Нет допустимого расположения для выбранного элемента.', 'Внимание', MB_ICONINFORMATION or MB_OK);
  end;
end;

procedure TApplicationUnit.CheckItems;
var i:Integer;
begin
 if State <> gsFinished then Exit;
 if ListView.Items.Count <= 0 then Exit;
 i:=0;
 while (ListView.Items.Count > 0) and (i < ListView.Items.Count) do
  begin
   if not ExistsPathKey(ListView.Items[i].SubItems[REGSI]) then
    begin
     ListView.Items[i].Delete;
     Continue;
    end;
   Inc(i);
  end;
end;

function TApplicationUnit.ExistsPathKey(Ident:string):Boolean;
var HKeyRes:HKEY;
begin
 HKeyRes:=StrKeyToRoot(Copy(Ident, 1, 4));
 Delete(Ident, 1, 5);
 RegOpenKeyEx(HKeyRes, PChar(Ident), 0, RootAccess, HKeyRes);
 Result:=HKeyRes <> 0;
end;

function TApplicationUnit.DeleteItem(LI:TListItem):Boolean;
var Text:string;
begin
 Result:=False;
 if LI = nil then Exit;
 if LI.SubItems.Count < 2 then
  begin
   Log(['Обращение к SubItem записи ListView вне границы', ListView, LI.SubItems.Count, 1]);
   Exit(False);
  end;
 Text:=LI.SubItems[UNISI];
 if Length(Text) <= 1 then
  begin
   MessageBox(Application.Handle, 'Отсутствует команда удаления!', 'Ошибка', MB_ICONEXCLAMATION or MB_OK);
   Exit(False);
  end;
 Result:=ProcessMonitor.Execute(Text);
end;

function TApplicationUnit.DeleteSelected:Boolean;
begin
 Result:=False;
 if ListView.Selected = nil then Exit;
 Result:=DeleteItem(ListView.Selected);
end;

function TApplicationUnit.DeleteChecked:Boolean;
var i:Integer;
begin
 if ListView.Items.Count <= 0 then Exit(False);
 //while True do
 Inform(LangText(-1, 'Деинсталляция программ'));
 FState:=gsProcess;

 for i:= 0 to ListView.Items.Count - 1 do
  begin
   Application.ProcessMessages;
   if ListView.Items[i].Checked then
    begin
     ListView.Items[i].Checked:=False;
     DeleteItem(ListView.Items[i]);
     Application.ProcessMessages;
    end;
  end;

 FState:=gsFinished;
 OnChanged;
 Inform('Деинсталляция программ зевершена');
 Result:=True;
end;

procedure TApplicationUnit.OnChanged;
begin
 inherited;
 OnListViewSort;
end;

procedure TApplicationUnit.Stop;
begin
 inherited;
end;

constructor TApplicationUnit.Create;
begin
 inherited;
 {
 try
  Roll:=TRegistry.Create(KEY_READ);   //KEY_ALL_ACCESS
  Roll.RootKey:=HKEY_LOCAL_MACHINE;
  FRestrictions:=not Roll.OpenKey('\Software\Microsoft\Windows\CurrentVersion\Uninstall', False);
 except
  begin
   FRestrictions:=True;
   Log(['Нет доступа к ветке реестра HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall', SysErrorMessage(GetLastError)]);
  end;
 end;
 if FRestrictions then
  try
   Log(['Нет полного доступа к веткам реестра HKEY_LOCAL_MACHINE']);
   Roll:=TRegistry.Create(KEY_READ);
   Roll.RootKey:=HKEY_LOCAL_MACHINE;
   if not Roll.OpenKey('\Software\Microsoft\Windows\CurrentVersion\Uninstall', False) then
    begin
     Log(['Модуль программ и компонентов не может получить доступ к реестру. Список элементов может быть не полный.']);
    end
   else Log(['Модуль программ и компонентов работает в режиме "только чтение"']);
  except
   begin
    Log(['Модуль программ и компонентов не может получить доступ к реестру. Список элементов может быть не полный.', SysErrorMessage(GetLastError)]);
   end;
  end;  }
 ListInstalls:=TStringList.Create;
end;

destructor TApplicationUnit.Destroy;
begin
 if Assigned(Roll) then Roll.Free;
 inherited;
end;

function TApplicationUnit.GetUninstallInfo(Roll:TRegistry; RHKEY:HKEY; RollPath, Ident:string; Item:TListItem):Boolean;
var II, IiD:Word;
    Str:string;
    IconName, UnInstallPath, PubStr:string;
    WillLoadIco:Boolean;
    SZ:Extended;

function GetIconName(ProductName:string):Boolean;
var l:Integer;
    nRoll:TRegistry;
begin
 Result:=False;
 if ListInstalls.Count <= 0 then Exit(False);
 nRoll:=TRegistry.Create(KEY_READ);
 nRoll.RootKey:=HKEY_LOCAL_MACHINE;
 for l:= 0 to ListInstalls.Count - 1 do
  begin
   if nRoll.OpenKey('SOFTWARE\Classes\Installer\Products\'+ListInstalls.Strings[l], False) then
    if nRoll.ReadString('ProductName') = ProductName then
     if FileExists(nRoll.ReadString('ProductIcon')) then
      begin
       IconName:=nRoll.ReadString('ProductIcon');
       nRoll.CloseKey;
       nRoll.Free;
       Exit(True);
      end;
   if FStop then Exit;
   nRoll.CloseKey;
  end;
 nRoll.CloseKey;
 nRoll.Free;
end;

begin
 with Roll do
  begin
   RootKey:=RHKEY;
   Item.Caption:=Ident;             //Заголовок
   Item.ImageIndex:=DI;             //Иконка
   Item.GroupID:=1;                 //Группа
   SIPUB:=Item.SubItems.Add('');    //Издатель
   SIDATE:=Item.SubItems.Add('');   //Установлено
   SISIZE:=Item.SubItems.Add('');   //Размер
   VERSI:=Item.SubItems.Add('');    //Версия
   PATHSI:=Item.SubItems.Add('');    //Каталог установки
   UNISI:=Item.SubItems.Add('');    //Команда удаления
   REGSI:=Item.SubItems.Add('');    //Ключ реестра
   if OpenKeyReadOnly(RollPath+'\'+Ident) then //Log(['not OpenKeyReadOnly(RollPath+Ident)', RollPath+'\'+Ident]);
    begin
     try Str:=ReadString('DisplayName') except Str:=''; end;
     if Str = '' then Str:=Ident;
     Item.Caption:=Str;
     PubStr:=ReadString('Publisher');
     Item.SubItems[SIPUB]:=PubStr;
     Item.GroupID:=0;
     IconName:='';
     UnInstallPath:='';
     try
      if ValueExists('UninstallString') then
       begin
        UnInstallPath:=ReadString('UninstallString');
       end
      else
       if ValueExists('UninstallString_Hidden') then
        begin
         UnInstallPath:=ReadString('UninstallString_Hidden');
        end
       else
        if ValueExists('QuietUninstallString') then
         begin
          UnInstallPath:=ReadString('QuietUninstallString');
         end
        else
         if ValueExists('WindowsInstaller') then //msiexec.exe /uninstall {2706334C-1B77-41B8-8CAB-EB997D0CCA83}
          begin
           UnInstallPath:='msiexec.exe /uninstall '+Ident;
          end
         else
          begin
           Item.GroupID:=1;
          end;
      if FLoadIcons then
       begin
        IconName:=UnInstallPath;
        if FileExists(ReadString('DisplayIcon')) then
         begin
          WillLoadIco:=True;
          IconName:=ReadString('DisplayIcon');
         end
        else
         if FileExists(NormFileNameF(ReadString('DisplayIcon'))) then
          begin
           WillLoadIco:=True;
           IconName:=NormFileNameF(ReadString('DisplayIcon'));
          end
         else
          if GetIconName(ReadString('DisplayName')) then
           begin
            //IconName:=GetIconName(ReadString('DisplayName'));
            WillLoadIco:=True;
           end
          else
           if FileExists(IconName) then
            begin
             WillLoadIco:=True;
             //IconName:=self data
            end
           else
            if FileExists(NormFileNameF(IconName)) then
             begin
              WillLoadIco:=True;
              NormFileName(IconName);
             end
            else
             if FileExists(FCurrentOS.Sys32+'\'+IconName) then
              begin
               WillLoadIco:=True;
               IconName:=FCurrentOS.Sys32+'\'+IconName;
              end
             else
              if FileExists(FCurrentOS.Sys32+'\'+IconName+'.exe') then
               begin
                WillLoadIco:=True;
                IconName:=FCurrentOS.Sys32+'\'+IconName+'.exe';
               end
              else
               begin
                WillLoadIco:=False;
                //IconName:=self data
               end;
       end
      else WillLoadIco:=False;

      if WillLoadIco and FLoadIcons then
       begin
        II:=0;
        IiD:=2;
        if FileExists(IconName) then
         begin    {
          Icon:=ExtractAssociatedIconEx(hInstance, PChar(IconName), II, IiD);
          IconN:=TIcon.Create;
          IconN.Handle:=Icon;
          Item.ImageIndex:=ListView.SmallImages.AddIcon(IconN);
          Item.ImageIndex:=ListView.LargeImages.AddIcon(IconN);
          IconN.Free;  }

          Item.ImageIndex:=GetFileIcon(IconName, is16, TImageList(ListView.SmallImages));
          if Item.ImageIndex < 0 then Item.ImageIndex:=DI;
         end;
       end;
     except
      Log(['Ошибка чтения данных записи реестра:', Roll.CurrentPath, GetLastError]);
     end;
     if Pos('microsoft', AnsiLowerCase(PubStr)) <> 0 then Item.GroupID:=MSGr;
     try
      Item.SubItems[VERSI]:=ReadString('DisplayVersion');
     except
      begin
       Item.SubItems[VERSI]:=LangText(53, 'Неизвестно');
       Log(['Данные о версии не получены', Roll.CurrentPath, GetLastError]);
      end;
     end;
     //try ListItem.SubItems.Add(ReadString('Publisher')) except ListItem.SubItems.Add(LangText[53]) end;
     //Item.SubItems[UNISI]:=UnInstallPath;

     if ValueExists('InstallDate') then
      begin
       if GetDataType('InstallDate') = rdString then
        begin
         Item.SubItems[SIDATE]:=FormatDateTime('c', InstallDateToNorm(ReadString('InstallDate'), GetFileDateChg(NormFileNameF(UnInstallPath))))
        end
      end
     else
      if FileExists(NormFileNameF(UnInstallPath)) then Item.SubItems[SIDATE]:=FormatDateTime('c', GetFileDateChg(NormFileNameF(UnInstallPath)));
     if ValueExists('EstimatedSize') then
      begin
       SZ:=ReadInteger('EstimatedSize');
       Item.SubItems[SISIZE]:=Format('%n МБ', [SZ / 1024]);
      end;
     Item.SubItems[UNISI]:=UnInstallPath;
     Item.SubItems[REGSI]:=RootKeyToStr(RootKey)+'\'+RollPath+'\'+Ident;

     if ValueExists('InstallLocation') then
      Item.SubItems[PATHSI]:=ReadString('InstallLocation')
     else
      if ValueExists('InstallPath') then
       Item.SubItems[PATHSI]:=ReadString('InstallPath')
      else
       if ValueExists('DisplayIcon') then
        Item.SubItems[PATHSI]:=ExtractFilePath(NormFileNameF(ReadString('DisplayIcon')))
       else
         Item.SubItems[PATHSI]:=ExtractFilePath(UnInstallPath);


     Result:=True;
     CloseKey;
    end
   else
    begin
     Item.SubItems[REGSI]:=RootKeyToStr(RootKey)+'\'+RollPath+'\'+Ident;
     Result:=False;
    end;
   //Log([Item.Caption, '|', UnInstallPath, '|', RootKeyToStr(RootKey)+'\'+RollPath+'\'+Ident]);
  end;
end;

function TApplicationUnit.FGet:TGlobalState;
var ListUninst: TStringList;
    i:Integer;
    R:Byte;
    RollPath:string;
    //HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Installer\Products\7DC6881F37F9A714299EE7A00B0F0E99

begin
 Inform(LangText(-1, 'Построение списка установленных программ и компонентов...'));
 Result:=gsProcess;

 if Assigned(ListView.SmallImages) then ListView.SmallImages.Free;
 if Assigned(ListView.LargeImages) then ListView.LargeImages.Free;

 ListView.SmallImages:=TImageList.CreateSize(16, 16);
 ListView.SmallImages.ColorDepth:=cd32Bit;
 ListView.LargeImages:=TImageList.CreateSize(16, 16);
 ListView.LargeImages.ColorDepth:=cd32Bit;

 if not Assigned(DisableIcon) then DI:=-1 else
  begin
   DI:=ListView.SmallImages.AddIcon(DisableIcon);
       ListView.LargeImages.AddIcon(DisableIcon);
  end;

 ListUninst:=TStringList.Create;
 Roll.RootKey:=HKEY_LOCAL_MACHINE;
 Roll.OpenKey('SOFTWARE\Classes\Installer\Products', False);
 Roll.GetKeyNames(ListInstalls);
 Roll.CloseKey;
 ListView.Items.BeginUpdate;
 ListView.Items.Clear;
 ListView.GroupView:=FGrouping;
 MSGr:=ListView.Groups.Count - 1;
 for R:= 0 to 3 do
  with Roll, ListView.Items do
   begin
    if Stopping then
     begin
      Log(['Построение списка установленных программ и компонентов прервано', GetLastError]);
      Exit(gsStopped);
     end;
    case R of
     0:
      begin
       RootKey:=HKEY_LOCAL_MACHINE;
       RollPath:='Software\Microsoft\Windows\CurrentVersion\Uninstall';
      end;
     1:
      begin
       RootKey:=HKEY_LOCAL_MACHINE;
       RollPath:='Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall';
      end;
     2:
      begin
       RootKey:=HKEY_CURRENT_USER;
       RollPath:='Software\Microsoft\Windows\CurrentVersion\Uninstall';
      end;
     3:
      begin
       RootKey:=HKEY_CURRENT_USER;
       RollPath:='Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall';
      end;
    end;
    if (Info.Bits = x64) and (AppBits <> x64) and ((R = 1) or (R = 3)) and (not SmartHandler.NowWowRedirection) then
     begin
      Log(['Пропущен раздел реестра', RootKeyToStr(RootKey), RollPath, 'т.к. разрядность программы не соответствует разрядности ОС', Ord(AppBits), Ord(Info.Bits)]);
      Continue;
     end;
    if not KeyExists(RollPath) then
     begin
      Log(['Пропущен раздел реестра', RootKeyToStr(RootKey), RollPath, 'т.к. ветка не существует', Ord(AppBits), Ord(Info.Bits)]);
      Continue;
     end;
    if not OpenKey(RollPath, False) then
     begin
      Log(['Пропущен раздел реестра', RootKeyToStr(RootKey), RollPath, 'Не удалось открыть ветку.', Ord(AppBits), Ord(Info.Bits)]);
      Continue;
     end;
    GetKeyNames(ListUninst);
    CloseKey;
    if ListUninst.Count > 0 then
     for i:=0 to ListUninst.Count-1 do
      begin
       GetUninstallInfo(Roll, Roll.RootKey, RollPath, ListUninst[i], Add);
       OnChanged;
       if Stopping then
        begin
         ListUninst.Free;
         Log(['Построение списка установленных программ и компонентов прервано.', GetLastError]);
         Exit(gsStopped);
        end;
      end
    else Log(['Пропущен раздел реестра', RollPath, 'т.к. нет элементов в ветке', Ord(AppBits), Ord(Info.Bits)]);
   end;
 ListUninst.Free;
 OnChanged;
 Inform('Построение списка установленных программ и компонентов завершено.');
 try
  Result:=gsFinished;
 except
  Exit;
 end;
end;

procedure TFormApp.ButtonCloseClick(Sender: TObject);
begin
 Close;
end;

procedure TFormApp.ButtonDelRKEYClick(Sender: TObject);
var Row:string;
begin
 if MessageBox(Application.Handle, 'Вы уверены, что хотите удалить элемент из списка?', 'Внимание', MB_ICONINFORMATION or MB_YESNO) <> ID_YES then Exit;

 Row:=ValueListEditor1.Values[RKEYName];
 if Row.Length <= 0 then
  begin
   if not InputQuery('Небольшая ошибка', 'Пожалуйста укажите ключ самостоятельно:', Row) then
    Exit
   else if Row.Length <= 0 then Exit;
  end;

 if FLastApp.DeleteRollKey(Row) then
  begin
   ShowMessage('Элемент успешно удалён из реестра.');
   Close;
  end;

end;

procedure TFormApp.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 case Key of
  VK_ESCAPE: Close;
 end;
end;

{
function TSmartHandler.AnalysisApps(SourceLV:TListView):Boolean;
var InfData:TStrings;
    i, j:Integer;
function CheckItem(ItemText, CheckData:string):Boolean;
var one:string;
    p:Byte;
begin
 Result:=False;
 if Pos(';', CheckData) <> 0 then
  begin
   while Length(CheckData) > 1 do
    begin
     if Stopping then Exit;
     p:=Pos(';', CheckData);
     one:=Copy(CheckData, 0, p - 1);
     CheckData:=Copy(CheckData, p + 1, Length(CheckData) - (Length(one) + 1));
     //ShowMessage(one +'|'+CheckData);
     if Pos(one, ItemText) <> 0 then
      begin
       Result:=True;
       Exit;
      end;
    end;
  end
 else
  if Pos(',', CheckData) <> 0 then
   begin
    Result:=True;
    while Length(CheckData) > 1 do
     begin
      if Stopping then Exit;
      p:=Pos(',', CheckData);
      one:=Copy(CheckData, 0, p - 1);
      CheckData:=Copy(CheckData, p + 1, Length(CheckData) - (Length(one) + 1));
      //ShowMessage(one +'|'+CheckData);
      if Pos(one, ItemText) = 0 then
       begin
        Result:=False;
        Exit;
       end;
     end;
   end;
end;
begin
 Result:=False;
 CurrentElement:=LangText(17, 'Анализ установленных программ и компонентов');
 InfData:=TStringList.Create;
 InfData.LoadFromFile(CurDir+'\Data\WinApps.inf');
 if InfData.Count <= 0 then Exit;
 if SourceLV.Items.Count <= 0 then Exit;
 for j:=0 to SourceLV.Items.Count - 1 do
  begin
   if Stopping then Exit;
   for i:=0 to InfData.Count - 1 do
    begin
     if CheckItem(AnsiLowerCase(SourceLV.Items[j].Caption), AnsiLowerCase(InfData.Strings[i])) then
      begin
       SmartHandler.AddItemToDel(SourceLV.Items[j].Caption, dtApp, True, SourceLV.Items[j].SubItems[2]);
       if Stopping then Exit;
       Break;
      end
     else if Stopping then Exit;
    end;
  end;
 InfData.Free;
 //Удалить пробелы, выровнять регистр  cap, 2
 Result:=True;
end;
}
  {
function TSmartHandler.IgnoreApp(Pub:string):Boolean;
var Ini:TStrings;
    i:Word;
begin
 Result:=False;
 //if not Elements.Items[12].Enabled then Exit;
 if Pub = '' then Exit;
 Ini:=TStringList.Create;
 try
  Ini.LoadFromFile(CurDir+'\Data\IgnoreApps.inf');
 except
  Exit;
 end;
 if Ini.Count <= 0 then
  begin
   Ini.Free;
   Exit;
  end;
 for i:=0 to Ini.Count - 1 do
  begin
   if Pos(AnsiLowerCase(Ini.Strings[i]), AnsiLowerCase(Pub)) <> 0 then
    begin
     Result:=True;
     Ini.Free;
     Exit;
    end;
  end;
end;}

end.
