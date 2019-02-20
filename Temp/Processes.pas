unit Processes;

interface

  uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls,
  Dialogs, ExtCtrls, ComCtrls, TLHelp32, PSAPI, COCUtils, MInfo;

 type

 PROCESS_BASIC_INFORMATION = packed record
   Reserved1:UINT64;
   PebBaseAddress:UINT64;
   Reserved2:array[0..1] of UINT64;
   UniqueProcessId:UINT64;
   Reserved3:UINT64;
 end;

 PProcInfo = ^TProcInfo;
 TProcInfo = record
  PID:string;
  PPID:string;
  Name:string;
 end;

 NTStatus = integer;
 PPROCESS_BASIC_INFORMATION = ^PROCESS_BASIC_INFORMATION;
 TNtQueryInformationProcess = function(ProcessHandle:THandle; ProcessInformationClass:ULONG; ProcessInformation: Pointer; ProcessInformationLength: ULONG; ReturnLength: Pointer): NTStatus; stdcall;
 TNtReadVirtualMemory = function(ProcessHandle:THandle; BaseAddress:UINT64; Buffer:Pointer; BufferLength: UINT64; ReturnLength: Pointer): NTStatus; stdcall;

var
 NtQueryInformationProcess:TNtQueryInformationProcess;
 NtReadVirtualMemory:TNtReadVirtualMemory;
 hLibrary:HMODULE;

 function GetProcessPrioriName(Value:Integer):string;
 function AddCurrentProcessPrivilege(PrivilegeName: WideString): Boolean;
 function TerminateProcessID(PID:Cardinal):Boolean;
 function TerminateProcessIHandle(HND:THandle):Boolean;
 function GetCmdLineProc(ProcHND:THandle):string;
 function GetProccessItem(PE:TProcessEntry32; IT:TListItem):TListItem;
 function SysProcessTerminatePID(dwPID:Cardinal):Boolean;
 procedure GetExeProc(LV:TListView);
 function SysProcessTerminateHandle(HND:THandle):Boolean;
 procedure GetProcInfo(LI:TListItem);
 function FindPIDLV(LV:TListView; PID:string):Integer;
 function FindPIDTV(TV:TTreeView; PID:string):Integer;
 procedure SelectProcByPID(LV:TListView; PID:integer); overload;
 function SelectProcByCMD(LV:TListView; CMD:string):Boolean;
 procedure SelectWndByPID(LV:TListView; PID:integer);
 function SelectProcByPID(TV:TTreeView; PID:integer):Boolean; overload;

implementation

function SelectProcByPID(TV:TTreeView; PID:integer):Boolean;
var ID:Integer;
begin
 Result:=True;
 ID:=FindPIDTV(TV, IntToStr(PID));
 if ID < 0 then Exit(False);
 TV.Selected:=TV.Items[ID];
end;

procedure SelectWndByPID(LV:TListView; PID:integer);
var i:Integer;
begin
 if LV.Items.Count <= 0 then Exit;
 for i:= 0 to LV.Items.Count - 1 do
  begin
   LV.Items[i].Selected:=LV.Items[i].SubItems[0] = IntToStr(PID);
  end;
 if LV.Selected <> nil then LV.Selected.MakeVisible(True);
end;

procedure SelectProcByPID(LV:TListView; PID:integer);
var i:Integer;
begin
 if LV.Items.Count <= 0 then Exit;
 for i:= 0 to LV.Items.Count - 1 do
  begin
   LV.Items[i].Selected:=LV.Items[i].SubItems[0] = IntToStr(PID);
  end;
 if LV.Selected <> nil then LV.Selected.MakeVisible(True);
end;

function SelectProcByCMD(LV:TListView; CMD:string):Boolean;
var i:Integer;
begin
 Result:=False;
 if LV.Items.Count <= 0 then Exit;
 for i:= 0 to LV.Items.Count - 1 do
  begin
   LV.Items[i].Selected:=DeleteStrQM(AnsiLowerCase(LV.Items[i].SubItems[5])) = DeleteStrQM(AnsiLowerCase(CMD));
   if not Result then if LV.Items[i].Selected then Result:=True;
  end;
 if LV.Selected <> nil then LV.Selected.MakeVisible(True);
end;

function FindPIDLV(LV:TListView; PID:string):Integer;
var i:Word;
begin
 Result:=-1;
 if LV.Items.Count <= 0 then Exit;
 for i:= 0 to LV.Items.Count -1 do
  if LV.Items[i].SubItems[0] = PID then Exit(i);
end;

function FindPIDTV(TV:TTreeView; PID:string):Integer;
var i:Word;
begin
 Result:=-1;
 if TV.Items.Count <= 0 then Exit;
 for i:= 0 to TV.Items.Count -1 do
  begin
   if TV.Items[i].Data = nil then Continue;
   if TProcInfo(TV.Items[i].Data^).PID =  PID then Exit(i);
  end;

end;

procedure GetProcInfo(LI:TListItem);
var PI:TProcInfo;
    PPI:PProcInfo;
begin
 PI.PID:=LI.SubItems[0];
 PI.Name:=LI.Caption;
 PI.PPID:=LI.SubItems[3];
 PPI:=AllocMem(SizeOf(PI));
 PPI^:=PI;
 LI.Data:=PPI;
end;

function SysProcessTerminateHandle(HND:THandle):Boolean;
var hToken:THandle;
    SeDebugNameValue:Int64;
    Token:TOKEN_PRIVILEGES;
    ReturnLength:Cardinal;
begin
 Result:=False;
 if not OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, hToken) then Exit;
 if not LookupPrivilegeValue(nil, 'SeDebugPrivilege', SeDebugNameValue) then
  begin
   CloseHandle(hToken);
   Exit;
  end;
 Token.PrivilegeCount:=1;
 Token.Privileges[0].Luid:=SeDebugNameValue;
 Token.Privileges[0].Attributes:=SE_PRIVILEGE_ENABLED;
 AdjustTokenPrivileges(hToken, False, Token, SizeOf(Token), Token, ReturnLength);
 if GetLastError <> ERROR_SUCCESS then Exit;
 if HND = 0 then Exit;
 if not TerminateProcess(HND, DWORD(-1)) then exit;
 CloseHandle(HND);
 Token.Privileges[0].Attributes:=0;
 AdjustTokenPrivileges(hToken, False, Token, SizeOf(Token), Token, ReturnLength);
 if GetLastError <> ERROR_SUCCESS then Exit;
 Result:=True;
end;

procedure GetExeProc(LV:TListView);
var hSnap:THandle;
    PE:TProcessEntry32;
begin
 if not Assigned(LV) then Exit;
 PE.dwSize:=SizeOf(TProcessEntry32);  //TH32CS_SNAPPROCESS
 hSnap:=CreateToolhelp32Snapshot(TH32CS_SNAPALL, 0);
 if Process32First(hSnap, PE) then
  repeat
   GetProccessItem(PE, LV.Items.Add);
  until not(Process32Next(hSnap, PE));
end;

function SysProcessTerminatePID(dwPID:Cardinal):Boolean;
var hProcess:THandle;
begin
 hProcess:=OpenProcess(PROCESS_TERMINATE, False, dwPID);
 Result:=SysProcessTerminateHandle(hProcess);
 CloseHandle(hProcess);
end;

function GetProccessItem(PE:TProcessEntry32; IT:TListItem):TListItem;
var hProcess:THandle;
    hMod:HMODULE;
    cb:DWORD;
    ModuleName:array [0..300] of Char;
    ProcMem:PPROCESS_MEMORY_COUNTERS;
    Mem:string;
    {ThreadID, SID:Cardinal; }
    Cmd:string;
    Wow64:BOOL;
begin
 with IT do
  begin
   hProcess:=OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, PE.th32ProcessID);
   Cmd:=GetCmdLineProc(hProcess);

   {ThreadID:=}GetWindowThreadProcessId(hProcess, nil);
   Mem:='none';
   if (hProcess <> 0) then
    begin
     EnumProcessModules(hProcess, @hMod, SizeOf(hMod), cb);
     GetModuleFileNameEx(hProcess, hMod, ModuleName, SizeOf(ModuleName));
     cb:=SizeOf(_PROCESS_MEMORY_COUNTERS);
     GetMem(ProcMem, cb);
     ProcMem^.cb:=cb;
     if GetProcessMemoryInfo(hProcess, ProcMem, cb) then Mem:=IntToStr(ProcMem^.PagefileUsage div 1024);
     FreeMem(ProcMem);
     CloseHandle(hProcess);
    end
   else Log(['Нет доступа к процессу', PE.szExeFile]);
   Caption:=PE.szExeFile;                                                       //Процесс -1
   SubItems.Add(IntToStr(PE.Th32ProcessID));                                    //PID      0
   SubItems.Add(GetSpacedInt(Mem)+' КБ');                                       //Выделен ОЗУ 1
   SubItems.Add(IntToStr(PE.cntThreads));                                       //Кол-во потоков 2
   SubItems.Add(IntToStr(PE.th32ParentProcessID));                              //Родит. процесс 3
   SubItems.Add(GetProcessPrioriName(PE.pcPriClassBase));                       //Приоритет 4
   SubItems.Add(Cmd);                                                           //Команда 5
   GetProcInfo(IT);
  end;
 Result:=IT;
end;

function GetCmdLineProc(ProcHND:THandle):string;
var PBI: PROCESS_BASIC_INFORMATION;
    ReturnLength: UINT64;
    Buffer: UINT64;
    Data:array[0..1023] of Char;
begin
 Result:='';
 if NtQueryInformationProcess(ProcHND, 0, @PBI, SizeOf(PBI), nil) = 0 then
  begin
   if NtReadVirtualMemory(ProcHND, PBI.PebBaseAddress + $20, @Buffer, SizeOf(Buffer), @ReturnLength) = 0 then
    begin
     if NtReadVirtualMemory(ProcHND, Buffer + $78, @Buffer, SizeOf(Buffer), @ReturnLength) = 0 then
      begin
       if NtReadVirtualMemory(ProcHND, Buffer, @Data, SizeOf(Data), @ReturnLength) = 0 then
        begin
         Result:=StrPas(Data);
        end
       else Log(['NtReadVirtualMemory(ProcHND, Buffer, @Data, SizeOf(Data), @ReturnLength)', ProcHND]);
      end
     else Log(['NtReadVirtualMemory(ProcHND, Buffer + $78, @Buffer, SizeOf(Buffer), @ReturnLength)', ProcHND]);
    end
   else Log(['NtReadVirtualMemory(ProcHND, PBI.PebBaseAddress + $20, @Buffer, SizeOf(Buffer), @ReturnLength)', ProcHND]);
  end
 else Log(['NtQueryInformationProcess(ProcHND, 0, @PBI, SizeOf(PBI), nil)', ProcHND]);
end;

function TerminateProcessID(PID:Cardinal):Boolean;
var HND:THandle;
begin
 HND:=OpenProcess(PROCESS_TERMINATE, False, PID);
 Result:=TerminateProcess(HND, 0);
end;

function TerminateProcessIHandle(HND:THandle):Boolean;
begin
 Result:=TerminateProcess(HND, 0);
end;

function AddCurrentProcessPrivilege(PrivilegeName: WideString): Boolean;
var
 TokenHandle: THandle;
 TokenPrivileges: TTokenPrivileges;
 ReturnLength: Cardinal;
begin
 Result:=False;
 if OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, TokenHandle) then
  begin
   try
    LookupPrivilegeValueW(nil, PWideChar(PrivilegeName), TokenPrivileges.Privileges[0].Luid);
    TokenPrivileges.PrivilegeCount := 1;
    TokenPrivileges.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
    if AdjustTokenPrivileges(TokenHandle, False, TokenPrivileges, 0, nil, ReturnLength) then Result := True;
   finally
    CloseHandle(TokenHandle);
   end;
  end
 else Log(['not OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, TokenHandle)', SysErrorMessage(GetLastError)]);
end;

function GetProcessPrioriName(Value:Integer):string;
begin
 if Value >= 24 then Exit('Реального времени') else
  if Value >= 11 then Exit('Высокий') else
   if Value >= 10 then Exit('Выше среднего') else
    if Value >=  8 then Exit('Средний') else
     if Value >=  6 then Exit('Ниже среднего') else
      if Value >=  4 then Exit('Низкий') else
       if Value >=  0 then Exit('Н/Д');
end;

initialization
 hLibrary:=LoadLibrary('ntdll.dll');
 if hLibrary <> 0 then
  begin
   case WindowsBits = x64 of
    False:
     begin
      {$IFDEF WIN64}
       @NtQueryInformationProcess:=GetProcAddress(hLibrary, 'NtQueryInformationProcess');
       @NtReadVirtualMemory:=GetProcAddress(hLibrary, 'NtReadVirtualMemory');
      {$ELSE}
       @NtQueryInformationProcess:=GetProcAddress(hLibrary, 'NtQueryInformationProcess');
       @NtReadVirtualMemory:=GetProcAddress(hLibrary, 'NtReadVirtualMemory');
      {$ENDIF}
     end;
    True:
     begin
      {$IFDEF WIN64}
       @NtQueryInformationProcess:=GetProcAddress(hLibrary, 'NtQueryInformationProcess');
       @NtReadVirtualMemory:=GetProcAddress(hLibrary, 'NtReadVirtualMemory');
      {$ELSE}
       @NtQueryInformationProcess:=GetProcAddress(hLibrary, 'NtWow64QueryInformationProcess64');
       @NtReadVirtualMemory:=GetProcAddress(hLibrary, 'NtWow64ReadVirtualMemory64');
      {$ENDIF}
     end;
   end;
   //@NtQueryInformationProcess:=GetProcAddress(hLibrary, 'NtWow64QueryInformationProcess64'); //NtQueryInformationProcess NtWow64QueryInformationProcess64
   //@NtReadVirtualMemory:=GetProcAddress(hLibrary, 'NtWow64ReadVirtualMemory64'); //NtReadVirtualMemory NtWow64ReadVirtualMemory64
  end
 else Log(['Информация о процессах ожидается не полная.']);
 AddCurrentProcessPrivilege('SeDebugPrivilege');
end.
