unit Tasks;

interface
 uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Vcl.ImgList,
  Dialogs, ExtCtrls, ComCtrls, System.Win.Registry, ShellAPI, Vcl.StdCtrls, Vcl.ValEdit,
  //Свои модули
  Utils, OSInfo, StructUnit, COCUtils, taskSchd, taskSchdXP, Vcl.Grids;
  //

 type
  TTaskVersion = (tvOld, tvNew); //tvOld - XP; tvNew - Vista, 7, 8, 8.1, 10 и новее
  TTaskData = record
   Version:TTaskVersion;
   Name:string;
   TaskID:Integer;
   FilePath:string;
  end;

  TTasksUnit = class;
  TFormTask = class(TForm)
    EditDisplayName: TEdit;
    Panel1: TPanel;
    Bevel1: TBevel;
    ButtonClose: TButton;
    ValueListEditor1: TValueListEditor;
    ButtonDelRKEY: TButton;
    ButtonOff: TButton;
    ButtonOn: TButton;
    procedure ButtonCloseClick(Sender: TObject);
    procedure ButtonDelRKEYClick(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ButtonOffClick(Sender: TObject);
    procedure ButtonOnClick(Sender: TObject);
  private
    FLastData:TTaskData;
    FLastUnit:^TTasksUnit;
    FLastItem:^TListItem;
  public
    { Public declarations }
  end;

  TTasksUnit = class(TSystemUnit)

    TaskList:TTasksList;
    TaskListXP:TTasksListXP;
    TaskService:ITaskService;
    TaskFolder:ITaskFolder;

   private
    AllFolder:Boolean;
    FDisableIcon:TIcon;
    procedure ListViewScheduleDblClick(Sender: TObject);
   public
    ImageList:TImageList;
    function FillValueList(VList:TValueListEditor; Task:TScheduledTask):Boolean; overload;
    function FillValueList(VList:TValueListEditor; Task:IRegisteredTask):Boolean; overload;
    function SetEnable(LI:TListItem; Value:Boolean):Boolean;
    function Delete(LI:TListItem):Boolean;
    function FGet:TGlobalState; override;
    procedure OnChanged; override;
    procedure Initialize; override;
    procedure Get(AllGroup:Boolean); overload;
    procedure OffSelectedTasks;
    procedure ShowSelected;
    procedure Stop; override;
    constructor Create; override;
    destructor Destroy; override;
    property DisableIcon:TIcon read FDisableIcon write FDisableIcon;
  end;

 const
  TaskStateNames:array[TTaskState] of string = ('неизвестно', 'отключено', 'в очереди', 'готово', 'выполняется');
  siLastDate = 0;
  siNextDate = 1;
  siState = 2;
  siFile = 3;

var
  FormTask:TFormTask;
  procedure ShowTaskInfo(TasksUnit:TTasksUnit; TaskData:TTaskData; LI:TListItem);

implementation

{$R *.dfm}

procedure ShowTaskInfo(TasksUnit:TTasksUnit; TaskData:TTaskData; LI:TListItem);
var res:Boolean;
    Old:Integer;
begin
 with FormTask do
  begin
   FLastUnit:=@TasksUnit;
   FLastData:=TaskData;
   FLastItem:=@LI;
   case TaskData.Version of
    tvOld:res:=TasksUnit.FillValueList(ValueListEditor1, TasksUnit.TaskListXP[TaskData.TaskID]);
    tvNew:res:=TasksUnit.FillValueList(ValueListEditor1, TasksUnit.TaskList[TaskData.TaskID]);
   else Exit;
   end;
   if res then
    begin
     if ValueListEditor1.Strings.Count * ValueListEditor1.RowHeights[0] + 4 <= 400 then
      ValueListEditor1.Height:=ValueListEditor1.Strings.Count * ValueListEditor1.RowHeights[0] + 4
     else ValueListEditor1.Height:=400;
     Old:=ValueListEditor1.Height;
     ClientHeight:=ValueListEditor1.Top + ValueListEditor1.Height + 50;
     ValueListEditor1.Height:=Old;
     EditDisplayName.Text:=TaskData.Name;
     ShowModal;
    end;
  end;
end;

function TTasksUnit.SetEnable(LI:TListItem; Value:Boolean):Boolean;
begin
 Result:=False;
 try
  case TTaskData(LI.Data^).Version of
   tvOld:
    begin
     if Value then
      TaskListXP[TTaskData(LI.Data^).TaskID].Flags:=TaskListXP[TTaskData(LI.Data^).TaskID].Flags - [tfDisabled]
     else TaskListXP[TTaskData(LI.Data^).TaskID].Flags:=TaskListXP[TTaskData(LI.Data^).TaskID].Flags + [tfDisabled];
     LI.SubItems[siState]:=TaskListXP[TTaskData(LI.Data^).TaskID].State;
    end;
   tvNew:
    begin
     TaskList[TTaskData(LI.Data^).TaskID].Enabled:=Value;
     LI.SubItems[siState]:=TaskStateNames[TaskList[TTaskData(LI.Data^).TaskID].State];
    end;
  end;
  Result:=True;
 except
  Log(['Ошибка. TTasksUnit.SetEnable. Смена состояния.', SysErrorMessage(GetLastError)]);
 end;
end;

function TTasksUnit.Delete(LI:TListItem):Boolean;
var TID:Integer;
    DelPath:string;
begin
 Result:=False;
 try
  TID:=TTaskData(LI.Data^).TaskID;
  case TTaskData(LI.Data^).Version of
   tvOld:
    begin
     TaskListXP[TID].Flags:=TaskListXP[TID].Flags + [tfDisabled];
     LI.SubItems[siState]:=TaskListXP[TID].State;
     try
      DeleteFile(Info.WindowsPath+'\Tasks\'+TTaskData(LI.Data^).FilePath);
      Log(['Удаляется задача:', Info.WindowsPath+'\Tasks\'+TTaskData(LI.Data^).FilePath]);
      if not FileExists(Info.WindowsPath+'\Tasks\'+TTaskData(LI.Data^).FilePath) then LI.Delete;
     except
      Log(['Несмог удалить задачу планировщика.']);
      Exit;
     end;
    end;
   tvNew:
    begin
     TaskList[TID].Enabled:=False;
     LI.SubItems[siState]:=TaskStateNames[TaskList[TID].State];
     DelPath:=TTaskData(LI.Data^).FilePath;
     try
      TaskFolder.DeleteTask(DelPath, 0);
      Log(['Удаляется задача:', TTaskData(LI.Data^).FilePath]);
     except
      begin
       Log(['Несмог удалить задачу планировщика.']);
       Exit;
      end;
     end;
     try
      TaskFolder.GetTask(DelPath);
     except
      LI.Delete;
     end;
     end;
  end;
  Result:=True;
 except
  Log(['Ошибка. TTasksUnit.SetEnable. Смена состояние.', SysErrorMessage(GetLastError)]);
 end;
end;

function TTasksUnit.FillValueList(VList:TValueListEditor; Task:IRegisteredTask):Boolean;
var TaskAction:IActionCollection;
    execAction:IExecAction;
    msgAction:IShowMessageAction;
    comAction:IComHandlerAction;
    mailAction:IEmailAction;
    i, j:integer;
    Roll:TRegistry;
    tmp, Trigger:string;
begin
 with VList, Task do
  begin
   Strings.Clear;
   AddToValueEdit(VList, 'Описание', Definition.RegistrationInfo.Description, '');
   AddToValueEdit(VList, 'Полный путь', Path, '');
   AddToValueEdit(VList, 'Автор', Definition.RegistrationInfo.Author, '');
   AddToValueEdit(VList, 'Версия', Definition.RegistrationInfo.Version, '');
   AddToValueEdit(VList, 'Посл. запуск', GetDateForTask(LastRunTime), '');
   AddToValueEdit(VList, 'След. запуск', GetDateForTask(NextRunTime), '');
   AddToValueEdit(VList, 'Состояние', TaskStateNames[State], '');


   TaskAction:=Definition.Actions;
   if TaskAction.Count > 0 then
    for i:=1 to TaskAction.Count do
     begin
      Trigger:='';
      if Definition.Triggers.Count > 0 then
       for j:= 1 to Definition.Triggers.Count do
        begin
         case Definition.Triggers.Item[j].triggerType of
          ttEvent:Trigger:=Trigger+LangText(72, 'по событию');
          ttTime:Trigger:=Trigger+LangText(73, 'один раз');
          ttDaily:Trigger:=Trigger+LangText(74, 'ежедневно');
          ttWeekly:Trigger:=Trigger+LangText(75, 'еженедельно');
          ttMonthly:Trigger:=Trigger+LangText(76, 'ежемесячно');
          ttMonthlyDOW:Trigger:=Trigger+LangText(77, 'ежемесячно (в определенный день недели)');
          ttIdle:Trigger:=Trigger+Trigger+LangText(78, 'во время бездействия');
          ttRegistration:Trigger:=Trigger+LangText(79, 'при создании или изменении задачи');
          ttBoot:Trigger:=Trigger+Trigger+LangText(80, 'при каждой загрузке');
          ttLogin:Trigger:=Trigger+Trigger+LangText(81, 'при входе в систему');
          ttSessionStateChange:Trigger:=Trigger+LangText(82, 'при блокировке/разблокировке раб. станции');
         end;
         if j <> Definition.Triggers.Count then Trigger:=Trigger+', ';
        end;
      if Trigger <> '' then
       begin
        Trigger[1]:=AnsiUpperCase(Trigger[1])[1];
        Trigger:=Trigger+'.';
       end
      else Trigger:=LangText(83, 'Отсутствуют');
      AddToValueEdit(VList, 'Тригеры', Trigger, '');

      case TaskAction.Item[i].ActionType of
       taExec:
        begin
         execAction:=TaskAction.item[i] as IExecAction;
         AddToValueEdit(VList, 'Тип события', 'Запуск программы', '');
         AddToValueEdit(VList, 'Команда', execAction.Path+' '+execAction.Arguments, '');
        end;
       taShowMessage:
        begin
         msgAction:=TaskAction.item[i] as IShowMessageAction;
         AddToValueEdit(VList, 'Тип события', 'Оповещение сообщением', '');
         AddToValueEdit(VList, 'Данные сообщения', msgAction.Title+': '+msgAction.MessageBody, '');
        end;
       taCOMHandler:
        begin
         comAction:=TaskAction.item[i] as IComHandlerAction;
         AddToValueEdit(VList, 'Тип события', 'Сторонний обработчик', '');
         Roll:=TRegistry.Create(KEY_READ);
         Roll.RootKey:=HKEY_CLASSES_ROOT;
         Roll.OpenKey('CLSID', False);
         if Roll.KeyExists(comAction.ClassId) then
          begin
           Roll.OpenKey(comAction.ClassId, False);
           tmp:=Roll.ReadString('')+' - '+comAction.ClassId;
           if Roll.OpenKey('LocalServer32', False) then AddToValueEdit(VList, 'Local Server 32', Roll.ReadString(''), '');
           if Roll.OpenKey('InprocServer32', False) then AddToValueEdit(VList, 'InProc Server 32', Roll.ReadString(''), '');
          end
         else tmp:=comAction.ClassId;
         AddToValueEdit(VList, 'Данные о классе', tmp, '');
         Roll.Free;
        end;
       taSendEMail:
        begin
         mailAction:=TaskAction.Item[i] as IEmailAction;
         AddToValueEdit(VList, 'Тип события', 'Отправка электронной почты', '');
         AddToValueEdit(VList, 'Данные сообщения', mailAction.To_+': '+mailAction.Subject, '');
        end;
      else
       AddToValueEdit(VList, 'Тип события', 'Не известно', '');
      end;
     end;
  end;
 Result:=True;
end;

function TTasksUnit.FillValueList(VList:TValueListEditor; Task:TScheduledTask):Boolean;
begin
 with VList, Task do
  begin
   Strings.Clear;
   AddToValueEdit(VList, 'Название задачи', TaskName, '');
   AddToValueEdit(VList, 'Комментарии', Comment, '');
   AddToValueEdit(VList, 'Автор', Creator, '');
   AddToValueEdit(VList, 'Приложение', ApplicationName, '');
   AddToValueEdit(VList, 'Параметры', Parameters, '');
   AddToValueEdit(VList, 'Рабочий каталог', WorkingDirectory, '');
   AddToValueEdit(VList, 'Состояние', State, '');
   AddToValueEdit(VList, 'Посл. запуск', GetDateForTask(MostRecentRunTime), '');
   AddToValueEdit(VList, 'След. запуск', GetDateForTask(NextRunTime), '');
  end;
 Result:=True;
end;

procedure TFormTask.ButtonCloseClick(Sender: TObject);
begin
 Close;
end;

procedure TFormTask.ButtonDelRKEYClick(Sender: TObject);
begin
 if MessageBox(Application.Handle, 'Вы уверены, что хотите удалить задачу из списка?', 'Внимание', MB_ICONINFORMATION or MB_YESNO) <> ID_YES then Exit;
 TTasksUnit(FLastUnit^).Delete(TListItem(FLastItem^));
 Close;
end;

procedure TFormTask.ButtonOffClick(Sender: TObject);
begin
 if MessageBox(Application.Handle, 'Вы уверены, что хотите отключить задачу?', 'Внимание', MB_ICONINFORMATION or MB_YESNO) <> ID_YES then Exit;
 TTasksUnit(FLastUnit^).SetEnable(TListItem(FLastItem^), False);
end;

procedure TFormTask.ButtonOnClick(Sender: TObject);
begin
 if MessageBox(Application.Handle, 'Вы уверены, что хотите включить задачу?', 'Внимание', MB_ICONINFORMATION or MB_YESNO) <> ID_YES then Exit;
 TTasksUnit(FLastUnit^).SetEnable(TListItem(FLastItem^), True);
end;

procedure TFormTask.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 case Key of
  VK_ESCAPE: Close;
 end;
end;

procedure TTasksUnit.Initialize;
begin
 ListView.OnDblClick:=ListViewScheduleDblClick;
end;

procedure TTasksUnit.ListViewScheduleDblClick(Sender: TObject);
begin
 ShowSelected;
end;

procedure TTasksUnit.Get(AllGroup:Boolean);
begin
 AllFolder:=AllGroup;
 inherited Get;
end;

procedure TTasksUnit.ShowSelected;
begin
 if ListView.Selected = nil then Exit;
 if ListView.Selected.Data = nil then Exit;
 ShowTaskInfo(Self, TTaskData(ListView.Selected.Data^), ListView.Selected);
end;

procedure TTasksUnit.OffSelectedTasks;
var i:Word;
    TID:Integer;
begin
 if ListView.Items.Count <= 0 then Exit;
 Inform('Отключение задач планировщика...');
 for i:= 0 to ListView.Items.Count -1 do
  begin
   if ListView.Items[i].Checked then
    begin
     if ListView.Items[i].Data = nil then Continue;
     TID:=TTaskData(ListView.Items[i].Data^).TaskID;
     ListView.Items[i].Checked:=False;
     TaskList[TID].Enabled:=not TaskList[TID].Enabled;
     ListView.Items[i].SubItems[siState]:=TaskStateNames[TaskList[TID].State];
    end;
   if Stopping then Exit;
  end;
 Inform('Готово');
end;

procedure TTasksUnit.OnChanged;
begin
 inherited;
 OnListViewSort;
end;

procedure TTasksUnit.Stop;
begin
 inherited;
end;

function TTasksUnit.FGet:TGlobalState;
var DI:Integer;
    Task:IRegisteredTask;
    TaskX:TScheduledTask;
    TaskXP:TTaskScheduleOld;
    j:Integer;
    II:Word;
    IconN:TIcon;
    IName:String;
    tmpData:TTaskData;
begin
 Inform(LangText(-1, 'Получение списка задач Планировщика задач Windows...'));
 Result:=gsProcess;
 ListView.Items.Clear;
 ListView.Groups.Clear;
 ListView.GroupView:=FGrouping;
 //ListView.Checkboxes:=True;
 //ListView.Columns.Clear;
 //ListView.ViewStyle:=vsReport;

 if not Assigned(ListView.SmallImages) then
  begin
   ListView.SmallImages:=TImageList.CreateSize(16, 16);
   ListView.SmallImages.ColorDepth:=cd32Bit;
  end
 else ListView.SmallImages.Clear;
 if not Assigned(FDisableIcon) then DI:=0
 else DI:=ListView.SmallImages.AddIcon(FDisableIcon);

 //-------
 TaskList.Clear;
 TaskListXP.Clear;

 IconN:=TIcon.Create;
 ImageList.GetIcon(0, IconN);
 ListView.SmallImages.AddIcon(IconN);
 ImageList.GetIcon(1, IconN);
 ListView.SmallImages.AddIcon(IconN);
 ImageList.GetIcon(2, IconN);
 ListView.SmallImages.AddIcon(IconN);
 ImageList.GetIcon(3, IconN);
 ListView.SmallImages.AddIcon(IconN);
 IconN.Free;

 //LV.SmallImages
 //with ListView.Columns.Add do begin Caption:=LangText(95, 'Задача'); AutoSize:=True; MinWidth:=200; Width:=250; end;
 //with ListView.Columns.Add do begin Caption:=LangText(96, 'Последний запуск'); Width:=150; end;
 //with ListView.Columns.Add do begin Caption:=LangText(97, 'Следующий запуск'); Width:=150; end;
 //with ListView.Columns.Add do begin Caption:=LangText(98, 'Состояние'); Width:=100; end;
 //with ListView.Columns.Add do begin Caption:=LangText(-1, 'Описание'); AutoSize:=True; Width:=250; end;
 if Info.Version <> winXP then
  begin
   try
    TaskService:=CoTaskScheduler.Create('');
    TaskService.Connect('', '', '', '');
    TaskFolder:=TaskService.GetFolder('\');
    GetTasks(TaskFolder, AllFolder, TaskList);
   except
    begin
     ShowMessage('Невозможно получить список задач');
     Exit(gsError);
    end;
   end;
   //Добавление задач Task Scheduler 2.0
   if TaskList.Count > 0 then
    begin
     for j:=0 to TaskList.Count-1 do
      begin
       with ListView.Items.Add do
        begin
         Task:=TaskList.Items[j];
         //Task.

         Caption:=Task.Name;                                                    //Заголовок
     {0} SubItems.Add(GetDateForTask(Task.LastRunTime));                        //Последний запуск
     {1} SubItems.Add(GetDateForTask(Task.NextRunTime));                        //След. запуск
     {2} SubItems.Add(TaskStateNames[Task.State]);                              //Состояние
     {3} SubItems.Add(Task.Path);                                               //Полный путь до файла

         tmpData.Version:=tvNew;
         tmpData.TaskID:=j;
         tmpData.Name:=Task.Name;
         tmpData.FilePath:=Task.Path;
         Data:=AllocMem(SizeOf(tmpData));

         TTaskData(Data^):=tmpData;

         ImageIndex:=DI;
         if Task.Definition.Actions.Count > 0 then
         case Task.Definition.Actions.Item[1].ActionType of
          taExec:
           begin
            ImageIndex:=1;
            if FLoadIcons then
             begin
              IName:=(Task.Definition.Actions.Item[1] as IExecAction).Path;
              IName:=NormFileNameF(IName);
              SubItems[siFile]:=IName+' '+(Task.Definition.Actions.Item[1] as IExecAction).Arguments;
              if FileExists(IName) then
               begin
                if GetFileIcon(IName, is16, TListView(ListView).SmallImages, II) > 0 then ImageIndex:=II;
               end;
             end;
           end;
          taCOMHandler:
           begin
            ImageIndex:=1;
            if FLoadIcons then
             begin
              Log(['loading icon com']);
              IName:=(Task.Definition.Actions.Item[1] as IComHandlerAction).ClassId;
              Roll.RootKey:=HKEY_CLASSES_ROOT;
              Roll.CloseKey;
              if Roll.OpenKeyReadOnly('CLSID') and Roll.KeyExists(IName) then
               begin
                Roll.OpenKey(IName, False);
                if Roll.OpenKey('InprocServer32', False) then IName:=Roll.ReadString('');
                if Roll.OpenKey('LocalServer32', False) then IName:=Roll.ReadString('');
               end;
              IName:=NormFileNameF(IName);
              SubItems[siFile]:=IName;
              if FileExists(IName) then
               begin
                if GetFileIcon(IName, is16, TListView(ListView).SmallImages, II) > 0 then ImageIndex:=II;
                Log(['load icon com succees']);
               end;
             end;
           end;
          taSendEMail:ImageIndex:=2;
          taShowMessage:ImageIndex:=3;
         else
          ImageIndex:=0;
         end;                                                        //Иконка
         GroupID:=GetGroup(TListView(ListView), Copy(Task.Path, 2, Length(Task.Path) - Length(Task.Name) - 2), False);
        end;
       if Stopping then
        begin
         Log(['Получение списка задач прервано', GetLastError]);
         Exit(gsStopped);
        end;
      end;
    end;
  end
 else
  begin
   try
    TaskXP:=TTaskScheduleOld.Create('');
    TaskXP.Refresh;
    GetTasksXP(TaskXP, TaskListXP);
   except
    begin
     Log(['Невозможно получить список задач', GetLastError]);
     ShowMessage('Невозможно получить список задач');
     Exit(gsError);
    end;
   end;
   //Добавление задач Task Scheduler 1.0
   if TaskListXP.Count > 0 then
    begin
     for j:=0 to TaskListXP.Count-1 do
      begin
       with ListView.Items.Add do
        begin
         //TaskXP
         TaskX:=TaskListXP.Items[j];
         Caption:=TaskX.Name;                                                   //Заголовок
     {0} SubItems.Add(GetDateForTask(TaskX.MostRecentRunTime));                 //Последний запуск
     {1} SubItems.Add(GetDateForTask(TaskX.NextRunTime));                       //След. запуск
     {2} SubItems.Add(TaskX.State);                                             //Состояние
     {3} SubItems.Add(TaskX.ApplicationName);                                   //Полный путь до файла

         tmpData.Version:=tvOld;
         tmpData.TaskID:=j;
         tmpData.Name:=TaskX.Name;
         tmpData.FilePath:=TaskX.TaskName;
         Data:=AllocMem(SizeOf(tmpData));
         TTaskData(Data^):=tmpData;

         ImageIndex:=0;
         IName:=NormFileNameF(TaskX.ApplicationName);
         try
          begin
           if FLoadIcons then
            begin
             if FileExists(IName) then
              begin
               if GetFileIcon(IName, is16, TListView(ListView).SmallImages, II) > 0 then ImageIndex:=II;
              end;
            end;
          end;
         except
          begin
           Log(['Не смог загрузить иконку из файла:', IName, GetLastError]);
          end;
         end;                                                      //Иконка
         GroupID:=GetGroup(TListView(ListView), '', True);
        end;
       if Stopping then
        begin
         Log(['Получение списка задач прервано', GetLastError]);
         Exit(gsStopped);
        end;
      end;
    end;
  end;
 Inform(LangText(12, 'Список задач Планировщика Windows получен.'));

 //-------

 OnChanged;
 try
  Result:=gsFinished;
 except
  Exit;
 end;
end;

constructor TTasksUnit.Create;
begin
 inherited;
 TaskList:=TTasksList.Create;
 TaskListXP:=TTasksListXP.Create;
 ImageList:=TImageList.CreateSize(16, 16);
 ImageList.ColorDepth:=cd32Bit;
end;

destructor TTasksUnit.Destroy;
begin
 if Assigned(Roll) then Roll.Free;
 inherited;
end;

end.
