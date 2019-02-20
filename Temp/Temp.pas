unit Temp;

interface

implementation

function SaveIconFromRes(Res:string; IconIndex:Integer; NewFile:string):Boolean;
var NumIcons: integer;
    pTheLargeIcons: phIconArray;
    Stream:TFileStream;

procedure WriteIcon32(Icon: HIcon; const Stream: TStream);
var
  IconInfo: TIconInfo;
  MonoInfoSize, ColorInfoSize: DWORD;
  MonoBitsSize, ColorBitsSize: DWORD;
  MonoInfo, MonoBits, ColorInfo, ColorBits: Pointer;
  CI: TCursorOrIcon;
  List: TIconRec;
begin
  FillChar(CI, SizeOf(CI), 0);
  FillChar(List, SizeOf(List), 0);
  if not GetIconInfo(Icon, IconInfo) then RaiseLastOSError;
  try
    GetDIBSizes(IconInfo.hbmMask, MonoInfoSize, MonoBitsSize);
    GetDIBSizes(IconInfo.hbmColor, ColorInfoSize, ColorBitsSize);
    MonoInfo := nil; MonoBits := nil; ColorInfo := nil; ColorBits := nil;

    try
      MonoInfo := AllocMem(MonoInfoSize);
      MonoBits := AllocMem(MonoBitsSize);
      ColorInfo := AllocMem(ColorInfoSize);
      ColorBits := AllocMem(ColorBitsSize);
      GetDIB(IconInfo.hbmMask, 0, MonoInfo^, MonoBits^);
      GetDIB(IconInfo.hbmColor, 0, ColorInfo^, ColorBits^);

      with CI do
      begin
        CI.wType := RC3_ICON;
        CI.Count := 1;
      end;
      Stream.Write(CI, SizeOf(CI));

      with List, PBitmapInfoHeader(ColorInfo)^ do
      begin
        Width := biWidth;
        Height := biHeight;
        Colors := biPlanes * biBitCount;
        DIBSize := ColorInfoSize + ColorBitsSize + MonoBitsSize;
        DIBOffset := SizeOf(CI) + SizeOf(List);
      end;
      Stream.Write(List, SizeOf(List));

      with PBitmapInfoHeader(ColorInfo)^ do
        Inc(biHeight, biHeight); // color height includes mono bits
      Stream.Write(ColorInfo^, ColorInfoSize);
      Stream.Write(ColorBits^, ColorBitsSize);
      Stream.Write(MonoBits^, MonoBitsSize);

    finally
      FreeMem(ColorInfo, ColorInfoSize);
      FreeMem(ColorBits, ColorBitsSize);
      FreeMem(MonoInfo, MonoInfoSize);
      FreeMem(MonoBits, MonoBitsSize);
    end;
  finally
    DeleteObject(IconInfo.hbmColor);
    DeleteObject(IconInfo.hbmMask);
  end;
end;

begin
 Result:=False;
 try
  begin
   NumIcons := ExtractIconEx(PChar(Res), -1, nil, nil, 0);
   if NumIcons > 0 then
    begin
     GetMem(pTheLargeIcons, NumIcons * sizeof(hIcon));
     ExtractIconEx(PChar(Res), 0, pTheLargeIcons, nil, NumIcons);
     Stream:=TFileStream.Create(NewFile, fmCreate);
     WriteIcon32(pTheLargeIcons^[IconIndex], Stream);
     Stream.Free;
     FreeMem(pTheLargeIcons, NumIcons * sizeof(hIcon));
    end;
  end;
 except
  Exit;
 end;
 Result:=True;
end;

//-------------------------------------------------------------------------
procedure FormCreate;
var ts : ITaskService;
    tf : ITaskFolder;
    tc : IRegisteredTaskCollection;
    task : IRegisteredTask;
    //list:

function getDate(date:TDate):string;
begin
  if date = 0 then result := ''
  else result := DateToStr(date);
end;

procedure getTasks(folder : ITaskFolder);
var  i : integer;
     tfc : ITaskFolderCollection;
begin
  tc := folder.GetTasks(1);
  //for i := 1 to tc.Count do taskList.Add(tc.Item[i]);

  tfc := folder.GetFolders(0);
  for i:=1 to tfc.Count do  getTasks(tfc.Item[i]);
end;

begin
 // taskList := TList<IRegisteredTask>.create();

  ts := CoTaskScheduler.Create();
  ts.Connect('', '', '', '');

  tf := ts.GetFolder('\');

  getTasks(tf);

  //taskListView.Items.BeginUpdate();
  //for task in taskList do
  begin
      with taskListView.Items.Add() do
      begin
          caption := task.Name;
          subItems.Add(getDate(task.LastRunTime));
          subItems.add(getDate(task.NextRunTime));
          subItems.Add(TaskStateNames[task.State]);
      end;
  end;
  //taskListView.Items.EndUpdate();
end;

procedure taskListViewSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
var index : integer;
    td : ITaskDefinition;
    regInfo : IRegistrationInfo;
    ac : IActionCollection;
    execAction : IExecAction;

    i:integer;

begin
    if not selected then exit;

    //td := taskList[taskListView.ItemIndex].Definition;
    regInfo := td.RegistrationInfo;
    with descriptionMemo.lines do
    begin
        text := regInfo.Description;
        add( regInfo.Author + '/' + regInfo.Version );
    end;

    ac := td.Actions;
    for i := 1 to ac.Count do begin
        if ac.Item[i].ActionType = taExec then begin
            execAction := ac.item[i] as IExecAction;

            descriptionMemo.Lines.Add('Путь:  ' + execAction.Path );
        end;
    end;
end;
//---------------------------------------------------------------------


end.
