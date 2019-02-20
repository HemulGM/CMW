unit CleanerElements;

interface

 uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Vcl.ImgList,
  Dialogs, ExtCtrls, ComCtrls, System.Win.Registry, ShellAPI, Vcl.StdCtrls, IniFiles,
  //���� ������
  Utils, OSInfo, StructUnit, COCUtils, Cleaner;
  //

 type

  TTempFiles = class(TScanElement)
   private
    procedure AnalysisUserTemp(UserPath:string);
   public
    procedure FindFill; override;
    constructor Create(Collection: TCollection); override;
  end;

  TTempInetFiles = class(TScanElement)
   private
    procedure AnalysisTemporaryInternetFiles(UserPath:string);
   public
    procedure FindFill; override;
    constructor Create(Collection: TCollection); override;
  end;

  TRecentFiles = class(TScanElement)
   private
    procedure AnalysisWindowsRecent(UserPath:string);
   public
    procedure FindFill; override;
    constructor Create(Collection: TCollection); override;
  end;

  TPrefetcher = class(TScanElement)
   private
    procedure AnalysisPref;
   public
    procedure FindFill; override;
    constructor Create(Collection: TCollection); override;
  end;

  TSysFolder = class(TScanElement)
   private
    procedure AnalysisSysFolder;
   public
    procedure FindFill; override;
    constructor Create(Collection: TCollection); override;
  end;

  TRecycle = class(TScanElement)
   private
    procedure AnalysisRecycle;
   public
    procedure FindFill; override;
    constructor Create(Collection: TCollection); override;
  end;

  TDamnificFiles = class(TScanElement)
   private
    procedure AnalysisUserPath(UserPath:string);
   public
    procedure FindFill; override;
    constructor Create(Collection: TCollection); override;
  end;

implementation
 uses ShellRecycle;

//------------------------------------------------------------------------------

constructor TSysFolder.Create;
begin
 inherited;
 Name:='��������� ����� � ��������� �������';
 Description:='��������� ����� � ��������� �������';
 Enabled:=True;
end;

constructor TDamnificFiles.Create;
begin
 inherited;
 Name:='�������������� �����';
 Description:='����� ��������, ������� � �.�. � ��������� ������������';
 Enabled:=False;
end;

constructor TTempInetFiles.Create;
begin
 inherited;
 Name:='��������� ����� ���������';
 Description:='��������� ����� ���������';
 Enabled:=True;
end;

constructor TTempFiles.Create;
begin
 inherited;
 Name:='��������� ����� � ����� "Temp"';
 Description:='��������� ����� � ����� "Temp"';
 Enabled:=True;
end;

constructor TRecentFiles.Create;
begin
 inherited;
 Name:='������ ��������� �������������� ������';
 Description:='������ ��������� �������������� ������';
 Enabled:=True;
end;

constructor TPrefetcher.Create;
begin
 inherited;
 Name:='����� ����������� ����������� ������';
 Description:='����� ����������� ����������� ������ �������������� ����� 30 ����';
 Enabled:=True;
end;

constructor TRecycle.Create;
begin
 inherited;
 Name:='�����, ���������� � �������';
 Description:='�����, ���������� � �������';
 Enabled:=True;
end;

//------------------------------------------------------------------------------

procedure TDamnificFiles.AnalysisUserPath(UserPath:string);
var Temp:string;
    List:TStringList;
    i:Integer;
    SE:TListItem;
begin
 List:=TStringList.Create;
 try                    {
  case Owner.Owner.CurrentOSLink.Version of
   OSWXP:Temp:=UserPath+'\Local Settings\';
  else      Temp:=UserPath+'\AppData\';
  end;
  }

  Temp:=UserPath;          //.COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC
  Log([Temp, '.COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC']);
  ScanDirFiles(Temp, '', DamnificFilesExt, List); //.js.jse
  if List.Count > 0 then
   for i:=0 to List.Count - 1 do
    begin
     SE:=AddToList(List.Strings[i], ElementID, True);
     SE.GroupID:=GroupID;
     if Owner.Owner.Stopping then Break;
    end;
 finally
  List.Free;
 end;
end;

procedure TRecycle.AnalysisRecycle;
var List:TStringList;
    i:Integer;
    SE:TListItem;
begin
 List:=TStringList.Create;
 try
  GetFilesList(List);
  if List.Count > 0 then
   for i:=0 to List.Count - 1 do
    begin
     SE:=AddToList(List.Strings[i], ElementID);
     SE.GroupID:=GroupID;
     if Owner.Owner.Stopping then Break;
    end;
 finally
  List.Free;
 end;
end;

procedure TSysFolder.AnalysisSysFolder;
var List, TMPPaths:TStringList;
    i, j:Integer;
    SE:TListItem;
begin
 List:=TStringList.Create;
 TMPPaths:=TStringList.Create;
 AddToListW(GetFullPath(ReadRegString(HKEY_LOCAL_MACHINE, 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', 'TMP')), TMPPaths);
 AddToListW(C+'Temp', TMPPaths);            //��� ���� �� ���������
 AddToListW(Owner.Owner.CurrentOSLink.WindowsPath+'\Temp', TMPPaths);

 try
  if TMPPaths.Count > 0 then
   for j:= 0 to TMPPaths.Count - 1 do
    begin
     Log([TMPPaths.Strings[j]]);
     ScanDir(TMPPaths.Strings[j], '', List);
    end;

  Log([Owner.Owner.CurrentOSLink.WindowsPath+'\*.tmp,*.log']);
  ScanDir(Owner.Owner.CurrentOSLink.WindowsPath+'\', '*.tmp', List);            //������ ���� � ��������� ����� (.tmp) � ��������� �������
  ScanDir(Owner.Owner.CurrentOSLink.WindowsPath+'\', '*.log', List);
  Log([Owner.Owner.CurrentOSLink.WindowsPath+'\System32\*.tmp,*.log']);
  ScanDir(Owner.Owner.CurrentOSLink.WindowsPath+'\System32', '*.tmp', List);
  ScanDir(Owner.Owner.CurrentOSLink.WindowsPath+'\System32', '*.log', List);
  Log([Owner.Owner.CurrentOSLink.WindowsPath+'\SysWOW64\*.tmp,*.log']);
  ScanDir(Owner.Owner.CurrentOSLink.WindowsPath+'\SysWOW64', '*.tmp', List);
  ScanDir(Owner.Owner.CurrentOSLink.WindowsPath+'\SysWOW64', '*.log', List);

  if List.Count > 0 then
   for i:=0 to List.Count - 1 do
    begin
     SE:=AddToList(GetFullPath(List.Strings[i]), ElementID);
     SE.GroupID:=GroupID;
     if Owner.Owner.Stopping then Break;
    end;
 finally
  List.Free;
 end;
end;

procedure TPrefetcher.AnalysisPref;
var List:TStringList;
    i:Integer;
    SE:TListItem;
begin
 List:=TStringList.Create;
 try
  Log([Owner.Owner.CurrentOSLink.WindowsPath+'\Prefetch\*.pf']);
  ScanDir(Owner.Owner.CurrentOSLink.WindowsPath+'\Prefetch', '*.pf', List);
  if List.Count > 0 then
   for i:=0 to List.Count - 1 do
    begin
     if (Date - GetFileDateChg(List.Strings[i])) > 30 then
      begin
       SE:=AddToList(List.Strings[i], ElementID);
       SE.GroupID:=GroupID;
      end;
     if Owner.Owner.Stopping then Break;
    end;
 finally
  List.Free;
 end;
end;

procedure TTempFiles.AnalysisUserTemp(UserPath:string);
var Temp:string;
    List:TStringList;
    i:Integer;
    SE:TListItem;
begin
 List:=TStringList.Create;
 try
  case Owner.Owner.CurrentOSLink.Version of
   winXP:Temp:=UserPath+'\Local Settings\Temp\';
  else   Temp:=UserPath+'\AppData\Local\Temp\';
  end;
  Log([Temp]);
  ScanDir(Temp, '', List);
  if List.Count > 0 then
   for i:=0 to List.Count - 1 do
    begin
     SE:=AddToList(List.Strings[i], ElementID);
     SE.GroupID:=GroupID;
     if Owner.Owner.Stopping then Break;
    end;
 finally
  FreeAndNil(List);
 end;
end;
        {
procedure TCurUser.AnalysisCurUserTemp(UserPath:string);
var Temp:string;
    List:TStringList;
    i:Integer;
    SE:TListItem;
    TMPPaths:TStringList;
    j:Integer;
begin
 List:=TStringList.Create;
 TMPPaths:=TStringList.Create;
 List:=TStringList.Create;

 try
  AddToListWOR(GetFullPath(GetEnvironmentVariable('TEMP')), TMPPaths);                //���� �� ���������� ����
  AddToListWOR(GetFullPath(GetEnvironmentVariable('TMP')), TMPPaths);
  if TMPPaths.Count > 0 then                                                    //������ �� � TMP'��
   for j:= 0 to TMPPaths.Count - 1 do
    ScanDir(TMPPaths.Strings[j], '', List);
    //ScanDir(Temp, '', List);

  if List.Count > 0 then
   for i:=0 to List.Count - 1 do
    begin
     SE:=AddToList(List.Strings[i], ElementID);
     SE.GroupID:=GroupID;
     if Owner.Owner.Stopping then Break;
    end;
 finally
  FreeAndNil(List);
  FreeAndNil(TMPPaths);
 end;
end;    }

procedure TTempInetFiles.AnalysisTemporaryInternetFiles(UserPath:string);
var List:TStringList;
    i:Integer;
    SE:TListItem;
begin
 List:=TStringList.Create;
 try
  Log([UserPath+'\Local Settings\Temporary Internet Files\']);
  ScanDir(UserPath+'\Local Settings\Temporary Internet Files\', '', List);
  Log([UserPath+'\Local Settings\Microsoft\Feeds Cache\']);
  ScanDir(UserPath+'\Local Settings\Microsoft\Feeds Cache\', '', List);
  Log([UserPath+'\Local Settings\Microsoft\Internet Explorer\Recovery\High\Last Active']);
  ScanDir(UserPath+'\Local Settings\Microsoft\Internet Explorer\Recovery\High\Last Active', '', List);
  Log([UserPath+'\AppData\Local\Microsoft\Windows\Temporary Internet Files\']);
  ScanDir(UserPath+'\AppData\Local\Microsoft\Windows\Temporary Internet Files\', '', List);
  Log([UserPath+'\AppData\Local\Microsoft\Feeds Cache\']);
  ScanDir(UserPath+'\AppData\Local\Microsoft\Feeds Cache\', '', List);
  Log([UserPath+'\AppData\Local\Microsoft\Internet Explorer\Recovery\High\Last Active']);
  ScanDir(UserPath+'\AppData\Local\Microsoft\Internet Explorer\Recovery\High\Last Active', '', List);
  Log([UserPath+'\AppData\Roaming\Microsoft\Windows\Cookies\']);
  ScanDir(UserPath+'\AppData\Roaming\Microsoft\Windows\Cookies\', '', List);
  if List.Count > 0 then
   for i:=0 to List.Count - 1 do
    begin
     SE:=AddToList(List.Strings[i], ElementID);
     SE.GroupID:=GroupID;
     if Owner.Owner.Stopping then Break;
    end;
 finally
  List.Free;
 end;
end;

procedure TRecentFiles.AnalysisWindowsRecent(UserPath:string);
var Temp:string;
    List:TStringList;
    i:Integer;
    SE:TListItem;
begin
 List:=TStringList.Create;
 try
  case Owner.Owner.CurrentOSLink.Version of
   winXP:Temp:=UserPath+'\Recent\';
  else Temp:=UserPath+'\AppData\Roaming\Microsoft\Windows\Recent';
  end;
  Log([Temp]);
  ScanDir(Temp, 'nodir', List);
  if List.Count > 0 then
   for i:=0 to List.Count - 1 do
    begin
     SE:=AddToList(List.Strings[i], ElementID);
     SE.GroupID:=GroupID;
     if Owner.Owner.Stopping then Break;
    end;
 finally
  List.Free;
 end;
end;

//------------------------------------------------------------------------------

procedure TRecycle.FindFill;
begin
 Owner.Owner.Inform('������������ "'+Name+'"...');
 AnalysisRecycle;
end;

procedure TSysFolder.FindFill;
begin
 Owner.Owner.Inform('������������ "'+Name+'"...');
 AnalysisSysFolder;
end;

procedure TPrefetcher.FindFill;
begin
 Owner.Owner.Inform('������������ "'+Name+'"...');
 AnalysisPref;
end;

procedure TTempFiles.FindFill;
var List:TStrings;
    i:Integer;
begin
 Owner.Owner.Inform('������������ "'+Name+'"...');
 List:=GetUsersPaths(Owner.Owner.CurrentOSLink.UsersPath);
 if List.Count > 0 then
  for i:=0 to List.Count - 1 do
   begin
    AnalysisUserTemp(List.Strings[i]);
    if Owner.Owner.Stopping then Break;
   end;
 if Assigned(List) then List.Free;
end;
                  {
procedure TCurUser.FindFill;
var List:TStrings;
    i:Integer;
begin
 Owner.Owner.Inform('������������ "'+Name+'"...');
                  {
 Owner.Owner.CurrentOSLink.CurrentUserName
 List:=GetUsersPaths(Owner.Owner.CurrentOSLink.UsersPath);
 if List.Count > 0 then
  for i:=0 to List.Count - 1 do
   begin
    AnalysisUserTemp(List.Strings[i]);
    if Owner.Owner.Stopping then Break;
   end;
 if Assigned(List) then List.Free;
end;    }

procedure TRecentFiles.FindFill;
var List:TStrings;
    i:Integer;
begin
 Owner.Owner.Inform('������������ "'+Name+'"...');
 List:=GetUsersPaths(Owner.Owner.CurrentOSLink.UsersPath);
 if List.Count > 0 then
  for i:=0 to List.Count - 1 do
   begin
    AnalysisWindowsRecent(List.Strings[i]);
    if Owner.Owner.Stopping then Break;
   end;
 if Assigned(List) then List.Free;
end;

procedure TTempInetFiles.FindFill;
var List:TStrings;
    i:Integer;
begin
 Owner.Owner.Inform('������������ "'+Name+'"...');
 List:=GetUsersPaths(Owner.Owner.CurrentOSLink.UsersPath);
 if List.Count > 0 then
  for i:=0 to List.Count - 1 do
   begin
    AnalysisTemporaryInternetFiles(List.Strings[i]);
    if Owner.Owner.Stopping then Break;
   end;
 if Assigned(List) then List.Free;
end;

procedure TDamnificFiles.FindFill;
var List:TStrings;
    i:Integer;
begin  //HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList
 Owner.Owner.Inform('������������ "'+Name+'"...');
 List:=GetUsersPaths(Owner.Owner.CurrentOSLink.UsersPath);
 //ShowMessage(List.Text);
 if List.Count > 0 then
  for i:=0 to List.Count - 1 do
   begin
    AnalysisUserPath(List.Strings[i]);
    if Owner.Owner.Stopping then Break;
   end;
 if Assigned(List) then List.Free;
end;

//------------------------------------------------------------------------------

{

procedure TEngineScan.Recycle;
var Info:Integer;
begin
 CurrentElement:=LangText(24, '�������');
 Info:=RecycleInfo;
 if Info > 0 then AddItemToDel(LangText(25, '������� �������'), dtRecycle, True, LangText(63, '������� �� �����')+' ('+IntToStr(Info)+')');
end;

EmptyRecycle;

}

end.
