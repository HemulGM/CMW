unit Module.Autoruns;

interface
 uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Vcl.ImgList,
  Dialogs, ExtCtrls, ComCtrls, System.Win.Registry, ShellAPI, Vcl.StdCtrls, Winapi.ShlObj,
  Vcl.ValEdit,
  //Свои модули
  CMW.Utils, CMW.OSInfo, CMW.ModuleStruct, Vcl.Grids;
  //

 type
  PAutorunData = ^TAutorunData;
  TAutorunData = record
   IsRegType:Boolean;

   DisplayName:string;
   Cmd:string;
   RegPath:string;
   RegName:string;
   RegRoot:HKEY;
   Exists:Boolean;
  end;

  TAutorunUnit = class(TSystemUnit)
    SINAME:Word;
    SIELEM:Word;
    SITYPE:Word;
    SIINFO:Word;
    SIFLAG:Word;
    SIEXIS:Word;
   private
    FDisableIcon:TIcon;
   public
    function FGet:TGlobalState; override;
    procedure OnChanged; override;
    procedure Initialize; override;
    function GetARDirectores:TStrings;
    procedure OpenFolderSelAR;
    procedure ShowInfo;
    procedure DeleteSel;
    function ShowARProc(LV:TListView):Boolean;
    function DeleteChecked:Boolean;
    function Delete(LI:TListItem):Boolean; overload;
    function Delete(AD:TAutorunData):Boolean; overload;
    procedure Stop; override;
    constructor Create; override;
    destructor Destroy; override;
    property DisableIcon:TIcon read FDisableIcon write FDisableIcon;
  end;

  TFormAutorun = class(TForm)
    EditDisplayName: TEdit;
    Panel1: TPanel;
    Bevel1: TBevel;
    ButtonClose: TButton;
    LabelPermission: TLabel;
    ValueListEditor1: TValueListEditor;
    procedure ButtonCloseClick(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    //FLastUnit:^TAutorunUnit;
  public
    { Public declarations }
  end;

var
   FormAutorun:TFormAutorun;


implementation
 {$R *.dfm}

 uses Module.WinProcesses, CMW.Main;


procedure ShowData(AD:TAutorunData);
var Old:Integer;
begin
 with FormAutorun, AD do
  begin
   { IsRegType:Boolean;

   DisplayName:string;
   Cmd:string;
   RegPath:string;
   RegName:string;
   RegRoot:HKEY;
   Exists:Boolean}
   ValueListEditor1.Strings.Clear;
   AddToValueEdit(ValueListEditor1, 'Имя записи/файла', Format('%s', [RegName]), '');
   AddToValueEdit(ValueListEditor1, 'Описание файла', Format('%s', [DisplayName]), '');
   AddToValueEdit(ValueListEditor1, 'Команда', Format('%s', [Cmd]), '');
   if IsRegType then
    AddToValueEdit(ValueListEditor1, 'Ключ реестра', Format('%s', [RootKeyToStr(RegRoot)+'\'+RegPath]), '')
   else AddToValueEdit(ValueListEditor1, 'Путь к файлу', Format('%s', [RegPath]), '');
   AddToValueEdit(ValueListEditor1, 'Файл существует', Format('%s', [BoolToLang(Exists)]), '');

   if ValueListEditor1.Strings.Count * ValueListEditor1.RowHeights[0] + 6 <= 400 then
    ValueListEditor1.Height:=ValueListEditor1.Strings.Count * ValueListEditor1.RowHeights[0] + 6
   else ValueListEditor1.Height:=400;
   Old:=ValueListEditor1.Height;
   ClientHeight:=ValueListEditor1.Top + ValueListEditor1.Height + 60;
   ValueListEditor1.Height:=Old+10;
   LabelPermission.Visible:=False;
   EditDisplayName.Text:=DisplayName;
   ShowModal;
  end;
end;

procedure TFormAutorun.ButtonCloseClick(Sender: TObject);
begin
 Close;
end;

procedure TAutorunUnit.ShowInfo;
begin
 if FListView.Selected = nil then Exit;
 if FListView.Selected.Data = nil then Exit;
 ShowData(TAutorunData(FListView.Selected.Data^));
end;

procedure TAutorunUnit.Initialize;
begin
 //
end;

procedure TAutorunUnit.DeleteSel;
begin
 if FListView.Selected = nil then Exit;
 if MessageBox(Application.Handle, 'Удалить из автозагрузки?', 'Вопрос', MB_ICONINFORMATION or MB_YESNO) <> ID_YES then Exit;
 if Delete(FListView.Selected) then FListView.Selected.Delete;
end;

function TAutorunUnit.ShowARProc;
var CMD:string;
begin
 if ListView.Selected = nil then Exit(False);
 CMD:=ListView.Selected.SubItems[SIELEM];
 Result:=SelectProcByCMD(LV, CMD);
end;

procedure TAutorunUnit.OpenFolderSelAR;
var Str:string;
begin
 if ListView.Selected = nil then Exit;
 if FListView.Selected.Data = nil then Exit;
 Str:=TAutorunData(FListView.Selected.Data^).Cmd;
 OpenFolderAndOrSelectFile(Str);
end;

function TAutorunUnit.Delete(AD:TAutorunData):Boolean;
var FRoll:TRegistry;
    FileStr:string;
begin
 if AD.IsRegType then
  begin
   try
    try
     FRoll:=TRegistry.Create(RootAccess);
     FRoll.RootKey:=AD.RegRoot;
     Log(['Автозагрузка: Удаляется ключ реестра', RootKeyToStr(AD.RegRoot)+'\'+AD.RegPath+'\'+AD.RegName]);
     Result:=FRoll.OpenKey(AD.RegPath, False) and FRoll.DeleteValue(AD.RegName);
     if Result then Log(['Ключ успешно удалён.']);
    finally
     FreeAndNil(FRoll);
    end;
   except
    Exit(False);
   end;
  end
 else
  begin
   FileStr:=NormFileNameF(AD.RegPath);
   if FileExists(FileStr) then
    begin
     if not DeleteFile(FileStr) then
      begin
       Log(['Автозагрузка: Не могу удалить файл автозагрузки', FileStr]);
       MessageBox(Application.Handle, PChar(LangText(67, 'Не могу удалить файл автозагрузки!')), PChar(LangText(41, 'Внимание')), MB_ICONASTERISK or MB_OK);
       Exit(False);
      end
     else
      begin
       if FileExists(FileStr) then
        begin
         Log(['Автозагрузка: Не получилось удалить файл автозагрузки', FileStr]);
         MessageBox(Application.Handle, PChar(LangText(67, 'Не смог удалить файл автозагрузки!')), PChar(LangText(41, 'Внимание')), MB_ICONASTERISK or MB_OK);
         Exit(False);
        end
       else Log(['Автозагрузка: Удалён элемент из папки Автозагрузки', FileStr]);
      end;
    end;
   Result:=True;
  end;
end;

function TAutorunUnit.Delete(LI:TListItem):Boolean;
begin
 if LI = nil then Exit(False);
 if LI.Data = nil then Exit(False);
 Result:=Delete(TAutorunData(LI.Data^));
end;

function TAutorunUnit.DeleteChecked:Boolean;
var i:Word;
begin
 if ListView.Items.Count <= 0 then Exit(False);
 Inform('Удаление элементов автозагрузки...');
 i:=0;
 while (ListView.Items.Count > 0) and (i < ListView.Items.Count) do
  begin
   if ListView.Items[i].Checked then
    begin
     Delete(ListView.Items[i]);
     Continue;
    end;
   if Stopping then Exit(False);
   Inc(i);
  end;
 Inform('Готово');
 Result:=True;
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

procedure SS;
begin
 FormMain.Caption:=IntToStr(Random(100));
end;

function TAutorunUnit.FGet:TGlobalState;
var ListAutoRun: TStringList;
    UsersPaths:TStrings;
    i, j: Integer;
    ListItem:TListItem;
    II:Word;
    Path, FullName:string;
    DI:Integer;
    GroupName:string;
    AData:TAutorunData;
begin
 Inform(LangText(-1, 'Построение списка элементов автозапуска...'));
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

 ListAutoRun:=TStringList.Create;
 ListAutoRun.Clear;

 for j:=0 to 11 do
  begin
   with Roll, ListView.Items do
    begin
     case j of
      0:
       begin
        RootKey:=HKEY_LOCAL_MACHINE;
        Path:='SOFTWARE\Microsoft\Windows\CurrentVersion\Run';
        GroupName:='Реестр: Текущий компьютер, постоянный запуск';
       end;
      1:
       begin
        RootKey:=HKEY_LOCAL_MACHINE;
        Path:='SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce';
        GroupName:='Реестр: Текущий компьютер, одноразовый запуск';
       end;
      8:
       begin
        RootKey:=HKEY_LOCAL_MACHINE;
        Path:='SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnceEx';
        GroupName:='Реестр: Текущий компьютер, одноразовый запуск (Ex)';
       end;
      2:
       begin
        if ((Info.Bits <> x64) or (AppBits <> x64) and (not SmartHandler.NowWowRedirection)) then Continue;
        RootKey:=HKEY_LOCAL_MACHINE;
        Path:='SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run';
        GroupName:='Реестр: Текущий компьютер, постоянный запуск, WOW64';
       end;
      3:
       begin
        if (Info.Bits <> x64) or (AppBits <> x64) then Continue;
        RootKey:=HKEY_LOCAL_MACHINE;
        Path:='SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce';
        GroupName:='Реестр: Текущий компьютер, одноразовый запуск, WOW64';
       end;
      11:
       begin
        if (Info.Bits <> x64) or (AppBits <> x64) then Continue;
        RootKey:=HKEY_LOCAL_MACHINE;
        Path:='SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnceEx';
        GroupName:='Реестр: Текущий компьютер, одноразовый запуск, WOW64 (Ex)';
       end;
      4:
       begin
        RootKey:=HKEY_CURRENT_USER;
        Path:='SOFTWARE\Microsoft\Windows\CurrentVersion\Run';
        GroupName:='Реестр: Текущий пользователь, постоянный запуск';
       end;
      5:
       begin
        RootKey:=HKEY_CURRENT_USER;
        Path:='SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce';
        GroupName:='Реестр: Текущий пользователь, одноразовый запуск';
       end;
      9:
       begin
        RootKey:=HKEY_CURRENT_USER;
        Path:='SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnceEx';
        GroupName:='Реестр: Текущий пользователь, одноразовый запуск (Ex)';
       end;
      6:
       begin
        if (Info.Bits <> x64) or (AppBits <> x64) then Continue;
        RootKey:=HKEY_CURRENT_USER;
        Path:='SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run';
        GroupName:='Реестр: Текущий пользователь, постоянный запуск, WOW64';
       end;
      7:
       begin
        if (Info.Bits <> x64) or (AppBits <> x64) then Continue;
        RootKey:=HKEY_CURRENT_USER;
        Path:='SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce';
        GroupName:='Реестр: Текущий пользователь, одноразовый запуск, WOW64';
       end;
      10:
       begin
        if (Info.Bits <> x64) or (AppBits <> x64) then Continue;
        RootKey:=HKEY_CURRENT_USER;
        Path:='SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnceEx';
        GroupName:='Реестр: Текущий пользователь, одноразовый запуск, WOW64 (Ex)';
       end;
     else
      begin
       Log(['Индекс цикла вышел за границы:', j, 'Сбой алгортима', SysErrorMessage(GetLastError)]);
      end;
     end;
     if not OpenKey(Path, False) then
      begin
       Log(['Не смог открыть ключ:', Path, SysErrorMessage(GetLastError)]);
       Continue;
      end;
     GetValueNames(ListAutoRun);
     if ListAutoRun.Count > 0 then
      for i:=0 to ListAutoRun.Count-1 do
       begin
        if ListAutoRun.Strings[i].Length <=0 then
         begin
          Log(['Пропущен элемент "По умолчанию", его значение: ', '"'+ReadString('')+'"', Roll.CurrentPath]);
          Continue;
         end;
        AData.IsRegType:=True;
        AData.Cmd:=ReadString(ListAutoRun[i]);
        AData.DisplayName:=GetFileDescription(NormFileNameF(AData.Cmd), '');
        AData.Exists:=FileExists(NormFileNameF(AData.Cmd));
        AData.RegName:=ListAutoRun[i];
        AData.RegPath:=Path;
        AData.RegRoot:=RootKey;

        ListItem:=Add;
        ListItem.Data:=AllocMem(SizeOf(AData));
        TAutorunData(ListItem.Data^):=AData;

        ListItem.Caption:=AData.DisplayName;
        SIELEM:=ListItem.SubItems.Add('');      //Элемент
        SIFLAG:=ListItem.SubItems.Add('');      //Сущ.

        try
         FullName:=AData.Cmd;
         NormFileName(FullName);
         if FileExists(FullName) then
          begin
           if GetFileIcon(FullName, is16, ListView.SmallImages, II) > 0 then ListItem.ImageIndex:=II
          end
         else ListItem.ImageIndex:=DI;
        except
         Log(['Не смог загрузить иконку из файла:', FullName, GetLastError]);
        end;

        ListItem.SubItems[SIELEM]:=AData.Cmd;
        ListItem.SubItems[SIFLAG]:=BoolToLang(AData.Exists);
        ListItem.Checked:=not AData.Exists;
        ListItem.GroupID:=GetGroup(ListView, GroupName, True);

        if Stopping then
         begin
          Log(['Загрузка элементов автозапуска прервана', GetLastError]);
          Exit(gsStopped);
         end;
       end;
     CloseKey;
    end;
  end;

 //------------------
 //------------------Анализ каталогов автозагрузки------------------------------

 UsersPaths:=GetARDirectores;
 if UsersPaths.Count > 0 then
   for i:=0 to UsersPaths.Count - 1 do
    begin
     ListAutoRun.Clear;
     ScanDir(UsersPaths[i], '*.*', ListAutoRun);
     if ListAutoRun.Count > 0 then
      for j:=0 to ListAutoRun.Count - 1 do
       with ListView.Items do
        begin
         if ExtractFileExt(ListAutoRun[j]) = '.ini' then
          begin
           Log(['Лишний файл в каталоге АЗ, пропущен', ListAutoRun[j], GetLastError]);
           Continue;
          end;
         AData.IsRegType:=False;
         AData.RegName:=GetFileNameWoE(ExtractFileName(ListAutoRun[j]));
         AData.Cmd:=ListAutoRun[j];
         if LowerCase(ExtractFileExt(AData.Cmd)) = '.lnk' then
          AData.Cmd:=NormFileNameF(GetFileNameFromLink(AData.Cmd));
         AData.DisplayName:=GetFileDescription(AData.Cmd, '');
         AData.Exists:=FileExists(AData.Cmd);
         AData.RegPath:=ListAutoRun[j];
         AData.RegRoot:=0;

         ListItem:=Add;
         ListItem.Data:=AllocMem(SizeOf(AData));
         TAutorunData(ListItem.Data^):=AData;

         ListItem.Caption:=AData.DisplayName;
         ListItem.Checked:=not AData.Exists;
         SIELEM:=ListItem.SubItems.Add(AData.Cmd);      //Элемент
         SIFLAG:=ListItem.SubItems.Add(BoolToLang(AData.Exists));      //Сущ.

         try
          FullName:=AData.Cmd;
          NormFileName(FullName);
          if FileExists(FullName) then
           begin
            if GetFileIcon(FullName, is16, ListView.SmallImages, II) > 0 then ListItem.ImageIndex:=II
           end
          else ListItem.ImageIndex:=DI;
         except
          Log(['Не смог загрузить иконку из файла:', FullName, GetLastError]);
         end;

         ListItem.GroupID:=GetGroup(ListView, 'Каталог: '+UsersPaths[i], True);
         if Stopping then
          begin
           Log(['Загрузка элементов автозапуска прервана', GetLastError]);
           Exit(gsStopped);
          end;
        end;
     //--------------------
     if Stopping then
      begin
       Log(['Загрузка элементов автозапуска прервана', GetLastError]);
       Exit(gsStopped);
      end;
    end;
 Inform(LangText(-1, 'Список элементов автозапуска успешно получен.'));
 OnChanged;
 try
  Result:=gsFinished;
 except
  Exit;
 end;
end;

constructor TAutorunUnit.Create;
begin
 inherited;
 
end;

destructor TAutorunUnit.Destroy;
begin
 if Assigned(Roll) then Roll.Free;
 inherited;
end;

function TAutorunUnit.GetARDirectores:TStrings;
var SFolder:PItemIDList;
    OBuf, OBuf2:array[0..2048] of WideChar;
begin
 Result:=TStringList.Create;
 if SUCCEEDED(SHGetSpecialFolderLocation(0, CSIDL_STARTUP, SFolder)) then
  begin
   if Assigned(SFolder) then
    if SHGetPathFromIDList(SFolder, @OBuf) then Result.Add(Trim(StrPas(OBuf)));
  end;

 if SUCCEEDED(SHGetSpecialFolderLocation(0, CSIDL_ALTSTARTUP, SFolder)) then
  begin
   if Assigned(SFolder) then
    if SHGetPathFromIDList(SFolder, @OBuf2) then
     if Trim(StrPas(OBuf)) <> Trim(StrPas(OBuf2)) then Result.Add(Trim(StrPas(OBuf2)));
  end;

 if SUCCEEDED(SHGetSpecialFolderLocation(0, CSIDL_COMMON_STARTUP, SFolder)) then
  begin
   if Assigned(SFolder) then
    if SHGetPathFromIDList(SFolder, @OBuf) then Result.Add(Trim(StrPas(OBuf)));
  end;

 if SUCCEEDED(SHGetSpecialFolderLocation(0, CSIDL_COMMON_ALTSTARTUP, SFolder)) then
  begin
   if Assigned(SFolder) then
    if SHGetPathFromIDList(SFolder, @OBuf2) then
     if Trim(StrPas(OBuf)) <> Trim(StrPas(OBuf2)) then Result.Add(Trim(StrPas(OBuf2)));
  end;

end;

procedure TFormAutorun.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 case Key of
  VK_ESCAPE: Close;
 end;
end;

end.
