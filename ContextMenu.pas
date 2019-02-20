unit ContextMenu;

interface
 uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Vcl.ImgList,
  Dialogs, ExtCtrls, ComCtrls, System.Win.Registry, ShellAPI, Vcl.StdCtrls, Winapi.ShlObj,
  Vcl.ValEdit,
  //Свои модули
  Utils, OSInfo, StructUnit, COCUtils, Vcl.Grids;
  //

 type
  PContextMenuUnit = ^TContextMenuUnit;
  TContextMenuData = record
   DisplayName:string;
   Cmd:string;
   Title:string;
   ShowIcon:Boolean;
   Path:string;
   RegPath:string;
   RegName:string;
   CLSID:string;
   ContextSub:string;
  end;

  TGetType = (gtContext, gtCLSIDs);

  TContextMenuUnit = class(TSystemUnit)
    SINAME:Word;
    SIELEM:Word;
    SITYPE:Word;
    SIINFO:Word;
    SIFLAG:Word;
    SIEXIS:Word;
    FRegKey:string;
   private
    FDisableIcon:TIcon;
    FGetType:TGetType;
    FPause:Boolean;
    ClassMax:Word;
   public
    function FGet:TGlobalState; override;
    function FGetContext:TGlobalState;
    function FGetCLSIDs:TGlobalState;
    procedure Get(GetType:TGetType); overload;
    function DeleteChecked:Boolean;
    function Delete(LI:TListItem):Boolean; overload;
    function Delete(AD:TContextMenuData):Boolean; overload;

    procedure OnChanged; override;
    procedure Initialize; override;
    procedure ShowInfo;
    procedure DeleteSel;
    procedure Stop; override;
    procedure Next;

    property RegKey:string read FRegKey write FRegKey;
    property DisableIcon:TIcon read FDisableIcon write FDisableIcon;

    constructor Create; override;
    destructor Destroy; override;
  end;

  TFormContextMenu = class(TForm)
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
   FormContextMenu:TFormContextMenu;

function IsCLSID(StrValue:string):Boolean;


implementation
 {$R *.dfm}

 uses Main;

{B298D29A-A6ED-11DE-BA8C-A68E55D89593}
function IsCLSID(StrValue:string):Boolean;
var i:Byte;
    AllowChar:set of Char;
begin
 Result:=False;
 AllowChar:=['0'..'9', 'a'..'f', 'A'..'F'];
 if Length(StrValue) <> 38 then Exit;
 if (StrValue[1] <> '{') or (StrValue[38] <> '}') or
    (StrValue[10] <> '-') or (StrValue[15] <> '-') or
    (StrValue[20] <> '-') or (StrValue[25] <> '-')
 then Exit;
 for i:= 2 to 37 do
  begin
   if (i = 10) or (i = 15) or (i = 20) or (i = 25) then Continue;
   if not (StrValue[i] in AllowChar) then Exit;
  end;
 Result:=True;
end;

procedure ShowData(AD:TContextMenuData);
var Old:Integer;
begin
 with FormContextMenu, AD do
  begin
   { IsRegType:Boolean;

   DisplayName:string;
   Cmd:string;
   RegPath:string;
   RegName:string;
   RegRoot:HKEY;
   Exists:Boolean}
   ValueListEditor1.Strings.Clear;
   AddToValueEdit(ValueListEditor1, 'Имя записи', Format('%s', [RegName]), '');
   AddToValueEdit(ValueListEditor1, 'Описание файла', Format('%s', [DisplayName]), '');
   AddToValueEdit(ValueListEditor1, 'Команда', Format('%s', [Cmd]), '');
   AddToValueEdit(ValueListEditor1, 'Полный путь', Format('%s', [AD.RegPath]), '');
   AddToValueEdit(ValueListEditor1, 'CLSID', Format('%s', [AD.CLSID]), '');
   AddToValueEdit(ValueListEditor1, 'ContextSub', Format('%s', [AD.ContextSub]), '');

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

procedure TContextMenuUnit.Get(GetType:TGetType);
begin
 FGetType:=GetType;
 inherited Get;
end;

procedure TFormContextMenu.ButtonCloseClick(Sender: TObject);
begin
 Close;
end;

procedure TContextMenuUnit.ShowInfo;
begin
 if FListView.Selected = nil then Exit;
 if FListView.Selected.Data = nil then Exit;
 ShowData(TContextMenuData(FListView.Selected.Data^));
end;

procedure TContextMenuUnit.Initialize;
begin
 //
end;

procedure TContextMenuUnit.DeleteSel;
begin
 if FListView.Selected = nil then Exit;
 if MessageBox(Application.Handle, 'Удалить из автозагрузки?', 'Вопрос', MB_ICONINFORMATION or MB_YESNO) <> ID_YES then Exit;
 if Delete(FListView.Selected) then FListView.Selected.Delete;
end;

function TContextMenuUnit.Delete(AD:TContextMenuData):Boolean;
var FRoll:TRegistry;
    FileStr:string;
begin

end;

function TContextMenuUnit.Delete(LI:TListItem):Boolean;
begin
 if LI = nil then Exit(False);
 if LI.Data = nil then Exit(False);
 Result:=Delete(TContextMenuData(LI.Data^));
end;

function TContextMenuUnit.DeleteChecked:Boolean;
var i:Word;
begin
 if ListView.Items.Count <= 0 then Exit(False);
 Inform('Удаление элементов автозагрузки...');

 Inform('Готово');
 Result:=True;
end;

procedure TContextMenuUnit.OnChanged;
begin
 inherited;
 OnListViewSort;
end;

procedure TContextMenuUnit.Next;
begin
 FListView.Clear;
 Application.ProcessMessages;
 if FPause then
  begin
   FPause:=False;

  end;
end;

procedure TContextMenuUnit.Stop;
begin
 inherited;
end;

function GetShellExData(CRoot:TRegistry; var Data:TContextMenuData):Boolean;
begin
 Result:=True;
 CRoot.RootKey:=HKEY_CLASSES_ROOT;
 CRoot.CloseKey;
 if not CRoot.OpenKeyReadOnly(Data.Path) then Exit(False);
 Data.CLSID:=CRoot.ReadString('');
 if not IsCLSID(Data.CLSID) then Data.CLSID:=Data.RegName;
 if not IsCLSID(Data.CLSID) then Exit(False);
 CRoot.CloseKey;
 if not CRoot.OpenKeyReadOnly('CLSID\'+Data.CLSID) then Exit(False);
 Data.DisplayName:=CRoot.GetDataAsString('');
 if not CRoot.OpenKeyReadOnly('InprocServer32') then Exit;
 Data.Cmd:=CRoot.GetDataAsString('');
end;

function GetClassData(CRoot:TRegistry; var Data:TContextMenuData):Boolean;
begin
 Result:=True;
 CRoot.RootKey:=HKEY_CLASSES_ROOT;
 Data.CLSID:=Data.RegName;
 if not IsCLSID(Data.CLSID) then Exit(False);
 CRoot.CloseKey;
 if not CRoot.OpenKeyReadOnly('CLSID\'+Data.CLSID) then Exit(False);
 Data.DisplayName:=CRoot.GetDataAsString('');
 if not CRoot.OpenKeyReadOnly('InprocServer32') then
  if not CRoot.OpenKeyReadOnly('LocalServer32') then Exit(False);
 Data.Cmd:=CRoot.GetDataAsString('');
 if Data.Cmd = '' then Exit(False);
 
 Data.Path:=CRoot.GetDataAsString('ServerExecutable');
end;

function TContextMenuUnit.FGetContext:TGlobalState;
var i, j, k, s: Integer;
    ListItem:TListItem;
    Elems:TStringList;
    DI:Integer;
    tmpData:TContextMenuData;
    ClassRoot:TRegistry;
    IconName, tmp, Included, pathin, shell:string;
    WillLoadIco:Boolean;
begin
 Inform(LangText(-1, 'Построение списка классов контекстного меню...'));
 Result:=gsProcess;
 ListView.Items.BeginUpdate;
 ListView.Items.Clear;
 ListView.Groups.Clear;
 ListView.Groups.Add.Header:='-';
 ListView.GroupView:=FGrouping;
 if not Assigned(ListView.SmallImages) then
  begin
   ListView.SmallImages:=TImageList.CreateSize(16, 16);
   ListView.SmallImages.ColorDepth:=cd32Bit;
  end
 else ListView.SmallImages.Clear;
 if not Assigned(FDisableIcon) then DI:=-1
 else DI:=ListView.SmallImages.AddIcon(FDisableIcon);

 Roll.RootKey:=HKEY_CLASSES_ROOT;
 Roll.CloseKey;
 if Roll.OpenKeyReadOnly(FRegKey) then
  begin
   Included:=Roll.GetDataAsString('');
  end;
 for s:= 0 to 1 do
 for k:= 0 to 25 do
 for j:= 0 to 1 do
  begin
   Roll.CloseKey;
   case j of
    0:tmp:=FRegKey;
    1:tmp:=Included;
   end;
   case s of
    0:shell:='shell';
    1:shell:='shellex';
   end;
   case k of
    0:pathin:='ContextMenuHandlers';
    1:pathin:='PropertySheetHandlers';
    2:pathin:='CopyHookHandler';
    3:pathin:='DropHandler';
    4:pathin:='IconHandler';
    5:pathin:='BrowserHelperObject';
    6:pathin:='ColumnHandler';
    7:pathin:='Thumbnail';
    8:pathin:='DiskCleanupHandler';
    9:pathin:='Drag&DropHandler';
    10:pathin:='IconOverlayHandler';
    11:pathin:='InfoTipHandler';
    12:pathin:='MetaData';
    13:pathin:='PreviewHandler';
    14:pathin:='MetaData';
    15:pathin:='PropertyHandler';
    16:pathin:='PropertySheet';
    17:pathin:='HTMLHandler';
    18:pathin:='XMLHandler';
    19:pathin:='SearchHandler';
    20:pathin:='ShellFolder';
    21:pathin:='System';
    22:pathin:='ShellExecute Hook';
    23:pathin:='PersistentHandler';
    24:pathin:='Thumbnail Handler';
    25:pathin:='URL Search Hook';
   end;
   //if tmp = '' then Continue;
   if Roll.OpenKeyReadOnly(tmp+'\'+shell+'\'+pathin) then
    begin
     ClassRoot:=TRegistry.Create(RootAccess);
     Elems:=TStringList.Create;
     Roll.GetKeyNames(Elems);
     if Elems.Count > 0 then
      begin
       for i:= 0 to Elems.Count - 1 do
        with ListView.Items do
         begin
          tmpData.Cmd:='';
          tmpData.Title:='';
          tmpData.ShowIcon:=False;
          tmpData.CLSID:='';
          //
          tmpData.RegName:=Elems.Strings[i];
          tmpData.Path:=tmp+'\'+shell+'\'+pathin+'\'+tmpData.RegName;
          if not GetShellExData(ClassRoot, tmpData) then Continue;

          ListItem:=Add;
          ListItem.GroupID:=0;

          tmpData.DisplayName:=Elems.Strings[i];
          tmpData.RegPath:=RootKeyToStr(Roll.RootKey)+'\'+tmp+'\'+shell+'\'+pathin+'\'+tmpData.RegName;
          tmpData.ContextSub:=pathin;

          ListItem.Data:=AllocMem(SizeOf(tmpData));
          TContextMenuData(ListItem.Data^):=tmpData;
          if tmpData.DisplayName <> '' then ListItem.Caption:=tmpData.DisplayName
          else ListItem.Caption:=tmpData.RegName;
          ListItem.SubItems.Add(pathin);
          ListItem.SubItems.Add(tmpData.Cmd);
          /////////////////////////////////////////////////////////////
          if FLoadIcons then
           begin
            WillLoadIco:=True;
            IconName:=NormFileNameF(tmpData.Path);
            if not FileExists(IconName) then
             begin
              IconName:=NormFileNameF(tmpData.Cmd);
              if not FileExists(IconName) then WillLoadIco:=False;
             end;
            if WillLoadIco then ListItem.ImageIndex:=GetFileIcon(IconName, is16, TImageList(FListView.SmallImages))
            else ListItem.ImageIndex:=DI;
           end
          else ListItem.ImageIndex:=DI;
          //////////////////////////////////////////////////////////////
         end;
      end;
     Elems.Free;
     ClassRoot.Free;
    end;
  end;
 Result:=gsFinished;
 Roll.CloseKey;
 ListView.Items.EndUpdate;
 case Result of
  gsError,
  gsNone,
  gsProcess: Inform(LangText(-1, 'Ошибка при получении списка классов.'));
  gsFinished: Inform(LangText(-1, 'Список классов контекстного меню успешно получен.'));
  gsStopped: Inform(LangText(-1, 'Получение списка классов остановлено.'));
 end;
 OnChanged;
end;

function TContextMenuUnit.FGetCLSIDs:TGlobalState;
var i: Integer;
    ListItem:TListItem;
    Elems:TStringList;
    DI:Integer;
    tmpData:TContextMenuData;
    IconName, tmp:string;
    WillLoadIco:Boolean;
    ClassRoot:TRegistry;
    Cnt:Word;
begin
 Inform(LangText(-1, 'Построение списка всех классов...'));
 Result:=gsProcess;
 ListView.Items.BeginUpdate;
 ListView.Items.Clear;
 ListView.Groups.Clear;
 ListView.Groups.Add.Header:='-';
 ListView.GroupView:=FGrouping;
 if not Assigned(ListView.SmallImages) then
  begin
   ListView.SmallImages:=TImageList.CreateSize(16, 16);
   ListView.SmallImages.ColorDepth:=cd32Bit;
  end
 else ListView.SmallImages.Clear;
 if not Assigned(FDisableIcon) then DI:=-1
 else DI:=ListView.SmallImages.AddIcon(FDisableIcon);

 Roll.RootKey:=HKEY_CLASSES_ROOT;
 Roll.CloseKey;
 if Roll.OpenKeyReadOnly('CLSID') then
  begin
   ClassRoot:=TRegistry.Create(RootAccess);
   Elems:=TStringList.Create;
   Roll.GetKeyNames(Elems);
   //ShowMessage(IntToStr(Elems.Count));
   Cnt:=0;
   if Elems.Count > 0 then
    begin
     for i:= 0 to Elems.Count - 1 do
      with ListView.Items do
       begin
        if Stopping then Exit(gsStopped);
        Inc(Cnt);
        if Cnt >= ClassMax then FPause:=True;
        if FPause then
         begin
          Cnt:=0;
          FListView.Items.EndUpdate;
         end;
        while FPause and (not Application.Terminated) do Application.ProcessMessages;

        tmpData.Cmd:='';
        tmpData.Title:='';
        tmpData.ShowIcon:=False;
        tmpData.CLSID:='';

        //
        tmpData.RegName:=Elems.Strings[i];
        tmpData.RegPath:=tmp;
        if not GetClassData(ClassRoot, tmpData) then Continue;

        ListItem:=Add;
        ListItem.GroupID:=0;
        ListItem.Data:=AllocMem(SizeOf(tmpData));
        TContextMenuData(ListItem.Data^):=tmpData;
        if tmpData.DisplayName <> '' then ListItem.Caption:=tmpData.DisplayName
        else ListItem.Caption:=tmpData.RegName;
        ListItem.SubItems.Add(tmpData.CLSID);
        ListItem.SubItems.Add(tmpData.Cmd);
        /////////////////////////////////////////////////////////////
        if FLoadIcons then
         begin
          WillLoadIco:=True;
          try
           IconName:=NormFileNameF(tmpData.Path);
          except
           ShowMessage(IconName);
          end;
          if not FileExists(IconName) then
           begin
            IconName:=NormFileNameF(tmpData.Cmd);
            if not FileExists(IconName) then WillLoadIco:=False;
           end;
          if WillLoadIco then ListItem.ImageIndex:=GetFileIcon(IconName, is16, TImageList(FListView.SmallImages))
          else ListItem.ImageIndex:=DI;
         end
        else ListItem.ImageIndex:=DI;
       //////////////////////////////////////////////////////////////
       end;
     FPause:=False;
     Result:=gsFinished;
    end;
   Elems.Free;
   ClassRoot.Free;
  end;
 Roll.CloseKey;
 ListView.Items.EndUpdate;
 case Result of
  gsError,
  gsNone,
  gsProcess: Inform(LangText(-1, 'Ошибка при получении списка классов.'));
  gsFinished: Inform(LangText(-1, 'Список классов контекстного меню успешно получен.'));
  gsStopped: Inform(LangText(-1, 'Получение списка классов остановлено.'));
 end;
 OnChanged;
end;

function TContextMenuUnit.FGet:TGlobalState;
begin
 case FGetType of
  gtContext:Result:=FGetContext;
  gtCLSIDs:Result:=FGetCLSIDs;
 end;
end;

constructor TContextMenuUnit.Create;
begin
 inherited;
 FRegKey:='*';
 FGetType:=gtContext;
 ClassMax:=1000;
 FPause:=False;
end;

destructor TContextMenuUnit.Destroy;
begin
 if Assigned(Roll) then Roll.Free;
 inherited;
end;

procedure TFormContextMenu.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 case Key of
  VK_ESCAPE: Close;
 end;
end;

end.
