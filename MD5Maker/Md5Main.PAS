unit Md5Main;

interface

uses Winapi.Windows, System.Classes, Vcl.Graphics, Vcl.Forms, Vcl.Controls,
  Vcl.Menus, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.ImgList, Vcl.StdActns, Vcl.ActnList, Vcl.ToolWin, System.Actions, System.SysUtils,
  NameDialog;

type
  TFormMain = class(TForm)
    OpenDialog: TOpenDialog;
    ActionList1: TActionList;
    FileOpen1: TAction;
    FileSave1: TAction;
    FileExit1: TAction;
    StatusBar: TStatusBar;
    ImageList1: TImageList;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    FileOpenItem: TMenuItem;
    FileSaveItem: TMenuItem;
    N1: TMenuItem;
    FileExitItem: TMenuItem;
    GridPanel1: TGridPanel;
    ListBox1: TListBox;
    ListBox2: TListBox;
    Edit1: TEdit;
    Edit2: TEdit;
    ToolBar1: TToolBar;
    ToolBar2: TToolBar;
    ToolButtonAdd: TToolButton;
    ToolButtonAdd1: TToolButton;
    ToolButtonDelete: TToolButton;
    ToolButtonDelete1: TToolButton;
    ToolButtonApply: TToolButton;
    ToolButtonApply1: TToolButton;
    ActionAdd: TAction;
    ActionDelete: TAction;
    ActionApply: TAction;
    Panel1: TPanel;
    ButtonMD5: TButton;
    Edit3: TEdit;
    ButtonOpen: TButton;
    ToolButtonFileSave1: TToolButton;
    ToolButtonFileSave2: TToolButton;
    ActionSort: TAction;
    ToolButtonSort1: TToolButton;
    ToolButtonSort: TToolButton;
    ActionDelMir: TAction;
    ToolButtonDelMir1: TToolButton;
    ToolButtonDelMir: TToolButton;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ActionSort2: TAction;
    ActionMerger: TAction;
    N2: TMenuItem;
    N3: TMenuItem;
    procedure FileOpen1Execute(Sender: TObject);
    procedure FileSave1Execute(Sender: TObject);
    procedure FileExit1Execute(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure ListBox2Click(Sender: TObject);
    procedure ActionAddExecute(Sender: TObject);
    procedure ActionDeleteExecute(Sender: TObject);
    procedure ActionApplyExecute(Sender: TObject);
    procedure Edit1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ButtonMD5Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ActionSortExecute(Sender: TObject);
    procedure ActionDelMirExecute(Sender: TObject);
    procedure ActionSort2Execute(Sender: TObject);
    procedure ActionMergerExecute(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormMain: TFormMain;

implementation

uses MD5;

{$R *.dfm}

function FindStr(List:TListBox; Str:string):Integer;
var i:word;
begin
 if List.Count <= 0 then Exit(-1);
 for i:= 0 to List.Count - 1 do
  begin
   Application.ProcessMessages;
   if Str = List.Items[i] then Exit(i);
  end;
 Result:=-1;
end;

procedure TFormMain.FileOpen1Execute(Sender: TObject);
var i, mir, adds:Word;
    MD5, FName:string;
begin
 mir:=0;
 adds:=0;
 if OpenDialog.Execute then
  begin
   if OpenDialog.Files.Count <= 1 then
    Edit3.Text:=OpenDialog.FileName
   else
    begin
     for i:=0 to OpenDialog.Files.Count - 1 do
      begin
       Application.ProcessMessages;
       try
        FName:=OpenDialog.Files[i];
        MD5:=MD5DigestToStr(MD5File(FName));
        if FindStr(ListBox1, MD5) >= 0 then
         begin
          Inc(mir);
          Continue;
         end;
       except
        Continue;
       end;
       Inc(adds);
       ListBox1.Items.Add(MD5);
       ListBox2.Items.Add(ExtractFileName(FName));
      end;
     ShowMessage('Добавлено: '+IntToStr(adds)+#13#10+'Уже существют: '+IntToStr(mir));
    end;
  end;
end;

procedure TFormMain.FileSave1Execute(Sender: TObject);
begin
 ListBox1.Items.SaveToFile(ExtractFilePath(ParamStr(0))+'Signatures.inf');
 ListBox2.Items.SaveToFile(ExtractFilePath(ParamStr(0))+'SignatName.inf');
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
 if FileExists(ExtractFilePath(ParamStr(0))+'Signatures.inf') then
   ListBox1.Items.LoadFromFile(ExtractFilePath(ParamStr(0))+'Signatures.inf');
 if FileExists(ExtractFilePath(ParamStr(0))+'Signatures.inf') then
   ListBox2.Items.LoadFromFile(ExtractFilePath(ParamStr(0))+'SignatName.inf');
 //ShowMessage('Всего элементов: '+IntToStr(ListBox1.Count));
 if FileExists(ParamStr(1)) then Edit3.Text:=ParamStr(1);
end;

procedure TFormMain.ListBox1Click(Sender: TObject);
var Sel:Integer;
begin
 if ListBox1.ItemIndex < 0 then Exit;
 Sel:=ListBox1.ItemIndex;
 Edit1.Text:=ListBox1.Items[Sel];
 while ListBox2.Count - 1 < Sel do
  begin
   ListBox2.Items.Add('');
  end;
 ListBox2.ItemIndex:=Sel;
 Edit2.Text:=ListBox2.Items[Sel];
end;

procedure TFormMain.ListBox2Click(Sender: TObject);
var Sel:Integer;
begin
 if ListBox2.ItemIndex < 0 then Exit;
 Sel:=ListBox2.ItemIndex;
 Edit2.Text:=ListBox2.Items[Sel];
 while ListBox1.Count - 1 < Sel do
  begin
   ListBox1.Items.Add('');
  end;
 ListBox1.ItemIndex:=Sel;
 Edit1.Text:=ListBox1.Items[Sel];
end;

procedure TFormMain.ActionAddExecute(Sender: TObject);
begin
 ListBox1.Items.Add('');
 ListBox1.ItemIndex:=ListBox1.Count - 1;
 ListBox1Click(nil);
end;

procedure TFormMain.ActionApplyExecute(Sender: TObject);
var sel:Integer;
begin
 if ListBox1.ItemIndex < 0 then Exit;
 Sel:=ListBox1.ItemIndex;
 ListBox1.Items[sel]:=Edit1.Text;
 ListBox2.Items[sel]:=Edit2.Text;
 ActionApply.Enabled:=False;
end;

procedure TFormMain.ActionDeleteExecute(Sender: TObject);
var sel:Integer;
begin
 if ListBox1.ItemIndex < 0 then Exit;
 Sel:=ListBox1.ItemIndex;
 ListBox1.Items.Delete(sel);
 ListBox2.Items.Delete(sel);
 if ListBox1.Count > 0 then
  begin
   if Sel - 1 < 0 then Sel:=0 else sel:=sel - 1;
   ListBox1.ItemIndex:=sel;
   ListBox1Click(nil);
  end;

 ActionApply.Enabled:=False;
end;

procedure TFormMain.ActionDelMirExecute(Sender: TObject);
var i, dels:Word;
begin
 if ListBox1.Count <= 1 then Exit;
 ListBox1.Items.BeginUpdate;
 ListBox2.Items.BeginUpdate;
 i:=0;
 dels:=0;
 repeat
  Application.ProcessMessages;
  if ListBox1.Items[i] = ListBox1.Items[i+1] then
   begin
    ListBox1.Items.Delete(i+1);
    ListBox2.Items.Delete(i+1);
    Inc(dels);
    Continue;
   end;
  Inc(i);
 until i = ListBox1.Count - 1;
 ListBox1.Items.EndUpdate;
 ListBox2.Items.EndUpdate;
 ShowMessage('Удалено дубликатов: '+IntToStr(dels));
end;

function Merger(FName, FName1:string; FNisFile:Boolean):Cardinal;
var MD5List:TStringList;
    NamList:TStringList;
    i:Cardinal;
begin
 Result:=0;
 MD5List:=TStringList.Create;
 if FNisFile then NamList:=TStringList.Create;
 try
  MD5List.LoadFromFile(FName);
 except
  begin
   ShowMessage('Невозможно загрузить файл '+FName);
   Exit(0);
  end;
 end;
 try
  if FNisFile then NamList.LoadFromFile(FName1);
 except
  begin
   ShowMessage('Невозможно загрузить файл '+FName1);
   Exit(0);
  end;
 end;
 if MD5List.Count <=0 then Exit(0);
 for i:=0 to MD5List.Count - 1 do
  begin
   Application.ProcessMessages;
   if Length(MD5List.Strings[i]) <> 32 then Continue;
   if FindStr(FormMain.ListBox1, MD5List.Strings[i]) < 0 then
    begin
     FormMain.ListBox1.Items.Add(MD5List.Strings[i]);
     try
      if FNisFile then FormMain.ListBox2.Items.Add(NamList.Strings[i])
      else FormMain.ListBox2.Items.Add(FName1);
     except
      begin
       ShowMessage('Ошибка при загрузке имён из файла '+FName1);
       Exit;
      end;
     end;
     Inc(Result);
    end;
  end;

end;

procedure TFormMain.ActionMergerExecute(Sender: TObject);
 var i, adds:Word;
    MD5, FName, FName1:string;
    Files:TStringList;
    FNisFile:Boolean;
begin
 adds:=0;
 OpenDialog.Title:='Выбери файл с MD5-суммами...';
 if not OpenDialog.Execute(Self.Handle) then Exit;
 Files:=TStringList.Create;
 Files.AddStrings(OpenDialog.Files);
 for i:=0 to Files.Count - 1 do
  begin
   Application.ProcessMessages;
   FormMD5Name.EditSrc.Text:=Files[i];
   case FormMD5Name.ShowModal of
    mrOk: begin FName1:=FormMD5Name.Edit1.Text; FNisFile:=False; end;
    mrYes:
     begin
      OpenDialog.Title:='Выбери параллельный файл имен MD5-сумм...';
      if not OpenDialog.Execute then Break;
      FName1:=OpenDialog.FileName;
      FNisFile:=True;
     end;
    mrCancel:Break;
   end;
   Inc(adds, Merger(Files[i], FName1, FNisFile));
  end;
 FreeAndNil(Files);
 ShowMessage('Добавлено: '+IntToStr(adds));
end;

procedure TFormMain.ActionSort2Execute(Sender: TObject);
var i, j:Word;
    buf:string;
begin
 if ListBox1.Count <= 1 then Exit;
 ListBox1.Items.BeginUpdate;
 ListBox2.Items.BeginUpdate;
 for i:=0 to ListBox1.Count - 1 do
  begin
   Application.ProcessMessages;
   for j:=0 to ListBox2.Count - 2 do
    begin

     if ListBox2.Items[j] > ListBox2.Items[j+1] then
      begin
       buf:=ListBox2.Items[j+1];
       ListBox2.Items[j+1]:=ListBox2.Items[j];
       ListBox2.Items[j]:=buf;

       buf:=ListBox1.Items[j+1];
       ListBox1.Items[j+1]:=ListBox1.Items[j];
       ListBox1.Items[j]:=buf;
      end;
    end;
  end;
 ShowMessage('Всего элементов: '+IntToStr(ListBox2.Count));
 ListBox1.Items.EndUpdate;
 ListBox2.Items.EndUpdate;
end;

procedure TFormMain.ActionSortExecute(Sender: TObject);
var i, j:Word;
    buf:string;
begin
 if ListBox1.Count <= 1 then Exit;
 ListBox1.Items.BeginUpdate;
 ListBox2.Items.BeginUpdate;
 for i:=0 to ListBox1.Count - 1 do
  begin
   Application.ProcessMessages;
   for j:=0 to ListBox1.Count - 2 do
    begin

     if ListBox1.Items[j] > ListBox1.Items[j+1] then
      begin
       buf:=ListBox1.Items[j+1];
       ListBox1.Items[j+1]:=ListBox1.Items[j];
       ListBox1.Items[j]:=buf;

       buf:=ListBox2.Items[j+1];
       ListBox2.Items[j+1]:=ListBox2.Items[j];
       ListBox2.Items[j]:=buf;
      end;
    end;
  end;
 ShowMessage('Всего элементов: '+IntToStr(ListBox1.Count));
 ListBox1.Items.EndUpdate;
 ListBox2.Items.EndUpdate;
end;

procedure TFormMain.ButtonMD5Click(Sender: TObject);
var Ley:Word;
    It:Integer;
    MD5:string;
begin
 MD5:=MD5DigestToStr(MD5File(Edit3.Text));
 It:=FindStr(ListBox1, MD5);
 if IT >= 0 then
  begin
   ListBox1.ItemIndex:=It;
   ListBox2.ItemIndex:=It;
   ShowMessage('Сигнатура "'+MD5+'" уже существует!');
   Exit;
  end;
 ActionAdd.Execute;
 Edit1.Text:=MD5;
 Edit2.Text:=ExtractFileName(Edit3.Text);
 Edit1KeyDown(nil, Ley, []);
end;

procedure TFormMain.Edit1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 ActionApply.Enabled:=True;
end;

procedure TFormMain.FileExit1Execute(Sender: TObject);
begin
 Close;
end;

end.
