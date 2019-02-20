unit CPUUsageUnit;

interface

uses
  Windows, SysUtils, Dialogs;


procedure CollectCPUData;
function GetCPUCount: Integer;
function GetCPUUsage(Index: Integer): Extended;
procedure ReleaseCPUData;

implementation

uses COCUtils;

type
  PLargeInteger = ^TLargeInteger;

type
  TPERF_DATA_BLOCK = record
    Signature: array [0 .. 4 - 1] of WCHAR;
    LittleEndian: DWORD;
    Version: DWORD;
    Revision: DWORD;
    TotalByteLength: DWORD;
    HeaderLength: DWORD;
    NumObjectTypes: DWORD;
    DefaultObject: LONG;
    SystemTime: TSystemTime;
    Reserved: DWORD;
    PerfTime: TLargeInteger;
    PerfFreq: TLargeInteger;
    PerfTime100nSec: TLargeInteger;
    SystemNameLength: DWORD;
    SystemNameOffset: DWORD;
  end;

  PPERF_DATA_BLOCK = ^TPERF_DATA_BLOCK;

  TPERF_OBJECT_TYPE = record
    TotalByteLength: DWORD; //
    DefinitionLength: DWORD;
    HeaderLength: DWORD;
    ObjectNameTitleIndex: DWORD;
    ObjectNameTitle: PWideChar;
    ObjectHelpTitleIndex: DWORD;
    ObjectHelpTitle: PWideChar;
    DetailLevel: DWORD;
    NumCounters: DWORD;
    DefaultCounter: DWORD;
    NumInstances: DWORD;
    CodePage: DWORD;
    PerfTime: TLargeInteger;
    PerfFreq: TLargeInteger;
  end;

  PPERF_OBJECT_TYPE = ^TPERF_OBJECT_TYPE;

type
  TPERF_COUNTER_DEFINITION = record
    ByteLength: DWORD;
    CounterNameTitleIndex: DWORD;
    CounterNameTitle: PWideChar;
    CounterHelpTitleIndex: DWORD;
    CounterHelpTitle: PWideChar;
    DefaultScale: LONG;
    DetailLevel: DWORD;
    CounterType: DWORD;
    CounterSize: DWORD;
    CounterOffset: DWORD;
  end;

  PPERF_COUNTER_DEFINITION = ^TPERF_COUNTER_DEFINITION;

  TPERF_COUNTER_BLOCK = record
    ByteLength: DWORD;
  end;

  PPERF_COUNTER_BLOCK = ^TPERF_COUNTER_BLOCK;

  TPERF_INSTANCE_DEFINITION = record
    ByteLength: DWORD;
    ParentObjectTitleIndex: DWORD;
    ParentObjectInstance: DWORD;
    UniqueID: LONG;
    NameOffset: DWORD;
    NameLength: DWORD;
  end;

  PPERF_INSTANCE_DEFINITION = ^TPERF_INSTANCE_DEFINITION;

const
  Processor_IDX_Str = '238';
  Processor_IDX = 238;
  CPUUsageIDX = 6;

type
  ALargeInteger = array [0 .. $FFFF] of TLargeInteger;
  PALargeInteger = ^ALargeInteger;

var
  _PerfData: PPERF_DATA_BLOCK;
  _BufferSize: Integer;
  _POT: PPERF_OBJECT_TYPE;
  _PCD: PPERF_COUNTER_DEFINITION;
  _ProcessorsCount: Integer;
  _Counters: PALargeInteger;
  _PrevCounters: PALargeInteger;
  _SysTime: TLargeInteger;
  _PrevSysTime: TLargeInteger;
  _IsWinNT: Boolean;

  _W9xCollecting: Boolean;
  _W9xCpuUsage: DWORD;
  _W9xCpuKey: HKEY;

  // ------------------------------------------------------------------------------
function GetCPUCount: Integer;
begin
  if _IsWinNT then
  begin
    if _ProcessorsCount < 0 then
      CollectCPUData;
    result := _ProcessorsCount;
  end
  else
  begin
    result := 1;
  end;

end;

// ------------------------------------------------------------------------------
procedure ReleaseCPUData;
var
  H: HKEY;
  R: DWORD;
  dwDataSize, dwType: DWORD;
begin
  if _IsWinNT then
    exit;
  if not _W9xCollecting then
    exit;
  _W9xCollecting := False;

  RegCloseKey(_W9xCpuKey);

  R := RegOpenKeyEx(HKEY_DYN_DATA, 'PerfStats\StopStat', 0, KEY_ALL_ACCESS, H);

  if R <> ERROR_SUCCESS then
    exit;

  dwDataSize := sizeof(DWORD);

  RegQueryValueEx(H, 'KERNEL\CPUUsage', nil, @dwType, PBYTE(@_W9xCpuUsage),
    @dwDataSize);

  RegCloseKey(H);

end;

// ------------------------------------------------------------------------------
function GetCPUUsage(Index: Integer): Extended;
begin

  if _IsWinNT then
  begin
    if _ProcessorsCount < 0 then
      CollectCPUData;
    if (Index >= _ProcessorsCount) or (Index < 0) then
    begin
      // raise Exception.Create('CPU index out of bounds');
      // Log(['CPU index out of bounds']);
      exit(0);
    end;
    // ShowMessage(IntToStr(_Counters[index])+' '+IntToStr(_PrevCounters[index]));
    if _PrevSysTime = _SysTime then
      result := -5
    else
      result := 1 - (_Counters[index] - _PrevCounters[index]) /
        (_SysTime - _PrevSysTime);
  end
  else
  begin
    if Index <> 0 then
      raise Exception.Create('CPU index out of bounds');
    if not _W9xCollecting then
      CollectCPUData;
    result := _W9xCpuUsage / 100;
  end;
end;

//var
  //VI: TOSVERSIONINFO;

  // ------------------------------------------------------------------------------
procedure CollectCPUData;
var
  BS: Integer;
  i: Integer;
  _PCB_Instance: PPERF_COUNTER_BLOCK;
  _PID_Instance: PPERF_INSTANCE_DEFINITION;
  ST: TFileTime;
  //lpSystemInfo: TSystemInfo;

var
  H: HKEY;
  R: DWORD;
  dwDataSize, dwType: DWORD;
begin
  if _IsWinNT then
  begin
    BS := _BufferSize;
    while RegQueryValueEx(HKEY_PERFORMANCE_DATA, Processor_IDX_Str, nil, nil,
      PBYTE(_PerfData), @BS) = ERROR_MORE_DATA do
    begin
      ShowMessage('1 Get a buffer that is big enough.');
      INC(_BufferSize, $1000);
      BS := _BufferSize;
      ReallocMem(_PerfData, _BufferSize);
    end;
    // ShowMessage('2 Locate the performance object'+IntToSTR(BS));
    _POT := PPERF_OBJECT_TYPE(DWORD(_PerfData) + _PerfData.HeaderLength);
    Log([_POT.TotalByteLength, _POT.DefinitionLength, _POT.HeaderLength,
      _POT.ObjectNameTitleIndex,
      // _POT.ObjectNameTitle,
      _POT.ObjectHelpTitleIndex,
      // _POT.ObjectHelpTitle,
      _POT.DetailLevel, _POT.NumCounters, _POT.DefaultCounter,
      _POT.NumInstances, _POT.CodePage, _POT.PerfTime, _POT.PerfFreq

      ]);
    for i := 1 to _PerfData.NumObjectTypes do
    begin
      if _POT.ObjectNameTitleIndex = Processor_IDX then
      begin
        // ShowMessage('Break'+IntToStr(i));
        Break;
      end;
      _POT := PPERF_OBJECT_TYPE(DWORD(_POT) + _POT.TotalByteLength);
    end;

    // ShowMessage(IntToStr(_POT.NumInstances));
    // ShowMessage('3 Check for success');
    if _POT.ObjectNameTitleIndex <> Processor_IDX then
      raise Exception.Create
        ('Unable to locate the "Processor" performance object');

    if _ProcessorsCount < 0 then
    begin
      _ProcessorsCount := _POT.NumInstances;
      GetMem(_Counters, _ProcessorsCount * sizeof(TLargeInteger));
      GetMem(_PrevCounters, _ProcessorsCount * sizeof(TLargeInteger));
    end;
    // ShowMessage('4 Locate the "% CPU usage" counter definition'+IntToStr(_ProcessorsCount));
    _PCD := PPERF_COUNTER_DEFINITION(DWORD(_POT) + _POT.HeaderLength);
    for i := 1 to _POT.NumCounters do
    begin
      if _PCD.CounterNameTitleIndex = CPUUsageIDX then
      begin
        // ShowMessage('Break'+IntToStr(i));
        Break;
      end;
      _PCD := PPERF_COUNTER_DEFINITION(DWORD(_PCD) + _PCD.ByteLength);
    end;

    // ShowMessage('5 Check for success');
    if _PCD.CounterNameTitleIndex <> CPUUsageIDX then
      raise Exception.Create
        ('Unable to locate the "% of CPU usage" performance counter');

    // ShowMessage('6 Collecting coutners');
    _PID_Instance := PPERF_INSTANCE_DEFINITION
      (DWORD(_POT) + _POT.DefinitionLength);
    for i := 0 to _ProcessorsCount - 1 do
    begin
      _PCB_Instance := PPERF_COUNTER_BLOCK(DWORD(_PID_Instance) +
        _PID_Instance.ByteLength);
      _PrevCounters[i] := _Counters[i];
      _Counters[i] := TLargeInteger
        (Pointer(DWORD(_PCB_Instance) + _PCD.CounterOffset)^);
      _PID_Instance := PPERF_INSTANCE_DEFINITION(DWORD(_PCB_Instance) +
        _PCB_Instance.ByteLength);
    end;

    _PrevSysTime := _SysTime;
    SystemTimeToFileTime(_PerfData.SystemTime, ST);
    _SysTime := TLargeInteger(ST);
  end
  else
  begin
    if not _W9xCollecting then
    begin
      R := RegOpenKeyEx(HKEY_DYN_DATA, 'PerfStats\StartStat', 0,
        KEY_ALL_ACCESS, H);
      if R <> ERROR_SUCCESS then
        raise Exception.Create('Unable to start performance monitoring');

      dwDataSize := sizeof(DWORD);

      RegQueryValueEx(H, 'KERNEL\CPUUsage', nil, @dwType, PBYTE(@_W9xCpuUsage),
        @dwDataSize);

      RegCloseKey(H);

      R := RegOpenKeyEx(HKEY_DYN_DATA, 'PerfStats\StatData', 0, KEY_READ,
        _W9xCpuKey);

      if R <> ERROR_SUCCESS then
        raise Exception.Create('Unable to read performance data');

      _W9xCollecting := True;
    end;

    dwDataSize := sizeof(DWORD);
    RegQueryValueEx(_W9xCpuKey, 'KERNEL\CPUUsage', nil, @dwType,
      PBYTE(@_W9xCpuUsage), @dwDataSize);
  end;
end;

initialization

{ _ProcessorsCount:= -1;
  _BufferSize:= $2000;
  _PerfData := AllocMem(_BufferSize);

  VI.dwOSVersionInfoSize:=SizeOf(VI);
  if not GetVersionEx(VI) then raise Exception.Create('Can''t get the Windows version');

  _IsWinNT := VI.dwPlatformId = VER_PLATFORM_WIN32_NT; }
finalization

{ ReleaseCPUData;
  FreeMem(_PerfData); }
end.
