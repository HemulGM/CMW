unit taskSchdXP;

interface

uses
 Winapi.ActiveX, Winapi.Windows, System.Classes, System.SysUtils, System.Contnrs,
 System.Generics.Collections;

//+----------------------------------------------------------------------------
//
//  Task Scheduler
//
//  Microsoft Windows
//  Copyright (C) Microsoft Corporation, 1992 - 1999.
//
//  File:       mstask.idl
//
//  Contents:   ITaskTrigger, ITask, ITaskScheduler, IEnumWorkItems
//              interfaces and related definitions
//
//  History:    06-Sep-95 EricB created
//
//-----------------------------------------------------------------------------


// import "oaidl.idl";

// import "oleidl.idl";

// 148BD520-A2AB-11CE-B11F-00AA00530503 - Task object class ID
// 148BD52A-A2AB-11CE-B11F-00AA00530503 - Task Scheduler class ID
// A6B952F0-A4B1-11D0-997D-00AA006887EC - IScheduledWorkItem interface ID
// 148BD524-A2AB-11CE-B11F-00AA00530503 - ITask interface ID
// 148BD527-A2AB-11CE-B11F-00AA00530503 - ITaskScheduler interface ID
// 148BD528-A2AB-11CE-B11F-00AA00530503 - IEnumWorkItems interface ID
// 148BD52B-A2AB-11CE-B11F-00AA00530503 - ITaskTrigger interface ID

//+----------------------------------------------------------------------------
//
//  Datatypes
//
//-----------------------------------------------------------------------------

const
{$EXTERNALSYM TASK_SUNDAY}
  TASK_SUNDAY = $1;
const
{$EXTERNALSYM TASK_MONDAY}
  TASK_MONDAY = $2;
const
{$EXTERNALSYM TASK_TUESDAY}
  TASK_TUESDAY = $4;
const
{$EXTERNALSYM TASK_WEDNESDAY}
  TASK_WEDNESDAY = $8;
const
{$EXTERNALSYM TASK_THURSDAY}
  TASK_THURSDAY = $10;
const
{$EXTERNALSYM TASK_FRIDAY}
  TASK_FRIDAY = $20;
const
{$EXTERNALSYM TASK_SATURDAY}
  TASK_SATURDAY = $40;
const
{$EXTERNALSYM TASK_FIRST_WEEK}
  TASK_FIRST_WEEK = 1;
const
{$EXTERNALSYM TASK_SECOND_WEEK}
  TASK_SECOND_WEEK = 2;
const
{$EXTERNALSYM TASK_THIRD_WEEK}
  TASK_THIRD_WEEK = 3;
const
{$EXTERNALSYM TASK_FOURTH_WEEK}
  TASK_FOURTH_WEEK = 4;
const
{$EXTERNALSYM TASK_LAST_WEEK}
  TASK_LAST_WEEK = 5;
const
{$EXTERNALSYM TASK_JANUARY}
  TASK_JANUARY = $1;
const
{$EXTERNALSYM TASK_FEBRUARY}
  TASK_FEBRUARY = $2;
const
{$EXTERNALSYM TASK_MARCH}
  TASK_MARCH = $4;
const
{$EXTERNALSYM TASK_APRIL}
  TASK_APRIL = $8;
const
{$EXTERNALSYM TASK_MAY}
  TASK_MAY = $10;
const
{$EXTERNALSYM TASK_JUNE}
  TASK_JUNE = $20;
const
{$EXTERNALSYM TASK_JULY}
  TASK_JULY = $40;
const
{$EXTERNALSYM TASK_AUGUST}
  TASK_AUGUST = $80;
const
{$EXTERNALSYM TASK_SEPTEMBER}
  TASK_SEPTEMBER = $100;
const
{$EXTERNALSYM TASK_OCTOBER}
  TASK_OCTOBER = $200;
const
{$EXTERNALSYM TASK_NOVEMBER}
  TASK_NOVEMBER = $400;
const
{$EXTERNALSYM TASK_DECEMBER}
  TASK_DECEMBER = $800;

const
{$EXTERNALSYM TASK_FLAG_INTERACTIVE}
  TASK_FLAG_INTERACTIVE = $1;
const
{$EXTERNALSYM TASK_FLAG_DELETE_WHEN_DONE}
  TASK_FLAG_DELETE_WHEN_DONE = $2;
const
{$EXTERNALSYM TASK_FLAG_DISABLED}
  TASK_FLAG_DISABLED = $4;
const
{$EXTERNALSYM TASK_FLAG_START_ONLY_IF_IDLE}
  TASK_FLAG_START_ONLY_IF_IDLE = $10;
const
{$EXTERNALSYM TASK_FLAG_KILL_ON_IDLE_END}
  TASK_FLAG_KILL_ON_IDLE_END = $20;
const
{$EXTERNALSYM TASK_FLAG_DONT_START_IF_ON_BATTERIES}
  TASK_FLAG_DONT_START_IF_ON_BATTERIES = $40;
const
{$EXTERNALSYM TASK_FLAG_KILL_IF_GOING_ON_BATTERIES}
  TASK_FLAG_KILL_IF_GOING_ON_BATTERIES = $80;
const
{$EXTERNALSYM TASK_FLAG_RUN_ONLY_IF_DOCKED}
  TASK_FLAG_RUN_ONLY_IF_DOCKED = $100;
const
{$EXTERNALSYM TASK_FLAG_HIDDEN}
  TASK_FLAG_HIDDEN = $200;
const
{$EXTERNALSYM TASK_FLAG_RUN_IF_CONNECTED_TO_INTERNET}
  TASK_FLAG_RUN_IF_CONNECTED_TO_INTERNET = $400;
const
{$EXTERNALSYM TASK_FLAG_RESTART_ON_IDLE_RESUME}
  TASK_FLAG_RESTART_ON_IDLE_RESUME = $800;
const
{$EXTERNALSYM TASK_FLAG_SYSTEM_REQUIRED}
  TASK_FLAG_SYSTEM_REQUIRED = $1000;
const
{$EXTERNALSYM TASK_FLAG_RUN_ONLY_IF_LOGGED_ON}
  TASK_FLAG_RUN_ONLY_IF_LOGGED_ON = $2000;

const
{$EXTERNALSYM TASK_TRIGGER_FLAG_HAS_END_DATE}
  TASK_TRIGGER_FLAG_HAS_END_DATE = $1;
const
{$EXTERNALSYM TASK_TRIGGER_FLAG_KILL_AT_DURATION_END}
  TASK_TRIGGER_FLAG_KILL_AT_DURATION_END = $2;
const
{$EXTERNALSYM TASK_TRIGGER_FLAG_DISABLED}
  TASK_TRIGGER_FLAG_DISABLED = $4;

//
// 1440 = 60 mins/hour * 24 hrs/day since a trigger/TASK could run all day at
// one minute intervals.
//

const
{$EXTERNALSYM TASK_MAX_RUN_TIMES}
  TASK_MAX_RUN_TIMES: Integer = 1440;

//
// The TASK_TRIGGER_TYPE field of the TASK_TRIGGER structure determines
// which member of the TRIGGER_TYPE_UNION field to use.
//
type
{$EXTERNALSYM _TASK_TRIGGER_TYPE}
  _TASK_TRIGGER_TYPE = (
{$EXTERNALSYM TASK_TIME_TRIGGER_ONCE}
    TASK_TIME_TRIGGER_ONCE, // 0   // Ignore the Type field.
{$EXTERNALSYM TASK_TIME_TRIGGER_DAILY}
    TASK_TIME_TRIGGER_DAILY, // 1   // Use DAILY
{$EXTERNALSYM TASK_TIME_TRIGGER_WEEKLY}
    TASK_TIME_TRIGGER_WEEKLY, // 2   // Use WEEKLY
{$EXTERNALSYM TASK_TIME_TRIGGER_MONTHLYDATE}
    TASK_TIME_TRIGGER_MONTHLYDATE, // 3   // Use MONTHLYDATE
{$EXTERNALSYM TASK_TIME_TRIGGER_MONTHLYDOW}
    TASK_TIME_TRIGGER_MONTHLYDOW, // 4   // Use MONTHLYDOW
{$EXTERNALSYM TASK_EVENT_TRIGGER_ON_IDLE}
    TASK_EVENT_TRIGGER_ON_IDLE, // 5   // Ignore the Type field.
{$EXTERNALSYM TASK_EVENT_TRIGGER_AT_SYSTEMSTART}
    TASK_EVENT_TRIGGER_AT_SYSTEMSTART, // 6   // Ignore the Type field.
{$EXTERNALSYM TASK_EVENT_TRIGGER_AT_LOGON}
    TASK_EVENT_TRIGGER_AT_LOGON // 7 // Ignore the Type field.
    );
{$EXTERNALSYM TASK_TRIGGER_TYPE}
  TASK_TRIGGER_TYPE = _TASK_TRIGGER_TYPE;
  TTaskTriggerType = _TASK_TRIGGER_TYPE;

{$EXTERNALSYM PTASK_TRIGGER_TYPE}
  PTASK_TRIGGER_TYPE = ^_TASK_TRIGGER_TYPE;
  PTaskTriggerType = ^_TASK_TRIGGER_TYPE;


type
{$EXTERNALSYM _DAILY}
  _DAILY = packed record
    DaysInterval: WORD;
  end;
{$EXTERNALSYM DAILY}
  DAILY = _DAILY;
  TDaily = _DAILY;


type
{$EXTERNALSYM _WEEKLY}
  _WEEKLY = packed record
    WeeksInterval: WORD;
    rgfDaysOfTheWeek: WORD;
  end;
{$EXTERNALSYM WEEKLY}
  WEEKLY = _WEEKLY;
  TWeekly = _WEEKLY;


type
{$EXTERNALSYM _MONTHLYDATE}
  _MONTHLYDATE = packed record
    rgfDays: DWORD;
    rgfMonths: WORD;
  end;
{$EXTERNALSYM MONTHLYDATE}
  MONTHLYDATE = _MONTHLYDATE;
  TMonthlyDate = _MONTHLYDATE; // OS: Changed capitalization


type
{$EXTERNALSYM _MONTHLYDOW}
  _MONTHLYDOW = packed record
    wWhichWeek: WORD;
    rgfDaysOfTheWeek: WORD;
    rgfMonths: WORD;
  end;
{$EXTERNALSYM MONTHLYDOW}
  MONTHLYDOW = _MONTHLYDOW;
  TMonthlyDOW = _MONTHLYDOW; // OS: Changed capitalization


type
{$EXTERNALSYM _TRIGGER_TYPE_UNION}
  _TRIGGER_TYPE_UNION = packed record
    case Integer of
      0: (Daily: DAILY);
      1: (Weekly: WEEKLY);
      2: (MonthlyDate: MONTHLYDATE);
      3: (MonthlyDOW: MONTHLYDOW);
  end;
{$EXTERNALSYM TRIGGER_TYPE_UNION}
  TRIGGER_TYPE_UNION = _TRIGGER_TYPE_UNION;
  TTriggerTypeUnion = _TRIGGER_TYPE_UNION;


type
{$EXTERNALSYM _TASK_TRIGGER}
  _TASK_TRIGGER = record // SP: removed packed record statement as seemed to affect SetTrigger
    cbTriggerSize: WORD; // Structure size.
    Reserved1: WORD; // Reserved. Must be zero.
    wBeginYear: WORD; // Trigger beginning date year.
    wBeginMonth: WORD; // Trigger beginning date month.
    wBeginDay: WORD; // Trigger beginning date day.
    wEndYear: WORD; // Optional trigger ending date year.
    wEndMonth: WORD; // Optional trigger ending date month.
    wEndDay: WORD; // Optional trigger ending date day.
    wStartHour: WORD; // Run bracket start time hour.
    wStartMinute: WORD; // Run bracket start time minute.
    MinutesDuration: DWORD; // Duration of run bracket.
    MinutesInterval: DWORD; // Run bracket repetition interval.
    rgFlags: DWORD; // Trigger flags.
    TriggerType: TASK_TRIGGER_TYPE; // Trigger type.
    Type_: TRIGGER_TYPE_UNION; // Trigger data.
    Reserved2: WORD; // Reserved. Must be zero.
    wRandomMinutesInterval: WORD; // Maximum number of random minutes
                                   // after start time.

  end;
{$EXTERNALSYM TASK_TRIGGER}

  TASK_TRIGGER = _TASK_TRIGGER;
  TTaskTrigger = _TASK_TRIGGER;

{$EXTERNALSYM PTASK_TRIGGER}
  PTASK_TRIGGER = ^_TASK_TRIGGER;
  PTaskTrigger = ^_TASK_TRIGGER;


//+----------------------------------------------------------------------------
//
//  Interfaces
//
//-----------------------------------------------------------------------------

//+----------------------------------------------------------------------------
//
//  Interface:  ITaskTrigger
//
//  Synopsis:   Trigger object interface. A Task object may contain several
//              of these.
//
//-----------------------------------------------------------------------------
// {148BD52B-A2AB-11CE-B11F-00AA00530503}
const
{$EXTERNALSYM IID_ITaskTrigger}
  IID_ITaskTrigger: TIID = (D1: $148BD52B; D2: $A2AB; D3: $11CE; D4: ($B1, $1F, $00, $AA, $00, $53, $05, $03));


// interface ITaskTrigger;
type
{$EXTERNALSYM ITaskTrigger}
  ITaskTrigger = interface(IUnknown)
    ['{148BD52B-A2AB-11CE-B11F-00AA00530503}']
// Methods:
    function SetTrigger(const pTrigger: TTaskTrigger): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} const PTASK_TRIGGER pTrigger |*)
    function GetTrigger(out pTrigger: TTaskTrigger): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {out} PTASK_TRIGGER pTrigger |*)
    function GetTriggerString(out ppwszTrigger: LPWSTR): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {out} LPWSTR * ppwszTrigger |*)
  end;

//+----------------------------------------------------------------------------
//
//  Interface:  IScheduledWorkItem
//
//  Synopsis:   Abstract base class for any runnable work item that can be
//              scheduled by the task scheduler.
//
//-----------------------------------------------------------------------------
// {a6b952f0-a4b1-11d0-997d-00aa006887ec}
const
{$EXTERNALSYM IID_IScheduledWorkItem}
  IID_IScheduledWorkItem: TIID = (D1: $A6B952F0; D2: $A4B1; D3: $11D0; D4: ($99, $7D, $00, $AA, $00, $68, $87, $EC));


// interface IScheduledWorkItem;
type
{$EXTERNALSYM IScheduledWorkItem}
  IScheduledWorkItem = interface(IUnknown)
    ['{A6B952F0-A4B1-11D0-997D-00AA006887EC}']
// Methods concerning scheduling:
    function CreateTrigger(out piNewTrigger: WORD; out ppTrigger: ITaskTrigger): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {out} WORD * piNewTrigger, {out} ITaskTrigger ** ppTrigger |*)
    function DeleteTrigger(iTrigger: WORD): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} WORD iTrigger |*)
    function GetTriggerCount(out pwCount: WORD): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {out} WORD * pwCount |*)
    function GetTrigger(iTrigger: WORD; out ppTrigger: ITaskTrigger): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} WORD iTrigger, {out} ITaskTrigger ** ppTrigger |*)
    function GetTriggerString(iTrigger: WORD; out ppwszTrigger: LPWSTR): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} WORD iTrigger, {out} LPWSTR * ppwszTrigger |*)
    function GetRunTimes(pstBegin: PSystemTime; pstEnd: PSystemTime; var pCount: WORD; out rgstTaskTimes: PSystemTime): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} const LPSYSTEMTIME pstBegin, {in} const LPSYSTEMTIME pstEnd, {in; out} WORD * pCount, {out} LPSYSTEMTIME * rgstTaskTimes |*)
    function GetNextRunTime(var pstNextRun: SYSTEMTIME): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in; out} SYSTEMTIME * pstNextRun |*)
    function SetIdleWait(wIdleMinutes: WORD; wDeadlineMinutes: WORD): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} WORD wIdleMinutes, {in} WORD wDeadlineMinutes |*)
    function GetIdleWait(out pwIdleMinutes: WORD; out pwDeadlineMinutes: WORD): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {out} WORD * pwIdleMinutes, {out} WORD * pwDeadlineMinutes |*)
// Other methods:
    function Run(): HRESULT; stdcall;
    function Terminate(): HRESULT; stdcall;
    function EditWorkItem(hParent: HWND; dwReserved: DWORD): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} HWND hParent, {in} DWORD dwReserved |*)
    function GetMostRecentRunTime(out pstLastRun: SYSTEMTIME): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {out} SYSTEMTIME * pstLastRun |*)
    function GetStatus(out phrStatus: HRESULT): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {out} HRESULT * phrStatus |*)
    function GetExitCode(out pdwExitCode: DWORD): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {out} DWORD * pdwExitCode |*)
// Properties:
    function SetComment(pwszComment: LPCWSTR): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} LPCWSTR pwszComment |*)
    function GetComment(out ppwszComment: LPWSTR): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {out} LPWSTR * ppwszComment |*)
    function SetCreator(pwszCreator: LPCWSTR): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} LPCWSTR pwszCreator |*)
    function GetCreator(out ppwszCreator: LPWSTR): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {out} LPWSTR * ppwszCreator |*)
    function SetWorkItemData(cbData: WORD; rgbData: PByte): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} WORD cbData, {in} BYTE rgbData[] |*)
    function GetWorkItemData(out pcbData: WORD; out prgbData: PByte): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {out} WORD * pcbData, {out} BYTE ** prgbData |*)
    function SetErrorRetryCount(wRetryCount: WORD): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} WORD wRetryCount |*)
    function GetErrorRetryCount(out pwRetryCount: WORD): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {out} WORD * pwRetryCount |*)
    function SetErrorRetryInterval(wRetryInterval: WORD): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} WORD wRetryInterval |*)
    function GetErrorRetryInterval(out pwRetryInterval: WORD): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {out} WORD * pwRetryInterval |*)
    function SetFlags(dwFlags: DWORD): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} DWORD dwFlags |*)
    function GetFlags(out pdwFlags: DWORD): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {out} DWORD * pdwFlags |*)
    function SetAccountInformation(pwszAccountName: LPCWSTR; pwszPassword: LPCWSTR): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} LPCWSTR pwszAccountName, {in} LPCWSTR pwszPassword |*)
    function GetAccountInformation(out ppwszAccountName: LPWSTR): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {out} LPWSTR * ppwszAccountName |*)
  end;

//+----------------------------------------------------------------------------
//
//  Interface:  ITask
//
//  Synopsis:   Task object interface. The primary means of task object
//              manipulation.
//
//-----------------------------------------------------------------------------
// {148BD524-A2AB-11CE-B11F-00AA00530503}
const
{$EXTERNALSYM IID_ITask}
  IID_ITask: TIID = (D1: $148BD524; D2: $A2AB; D3: $11CE; D4: ($B1, $1F, $00, $AA, $00, $53, $05, $03));


// interface ITask;
type
{$EXTERNALSYM ITask}
  ITask = interface(IScheduledWorkItem)
    ['{148BD524-A2AB-11CE-B11F-00AA00530503}']
// Properties that correspond to parameters of CreateProcess:
    function SetApplicationName(pwszApplicationName: LPCWSTR): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} LPCWSTR pwszApplicationName |*)
    function GetApplicationName(out ppwszApplicationName: LPWSTR): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {out} LPWSTR * ppwszApplicationName |*)
    function SetParameters(pwszParameters: LPCWSTR): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} LPCWSTR pwszParameters |*)
    function GetParameters(out ppwszParameters: LPWSTR): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {out} LPWSTR * ppwszParameters |*)
    function SetWorkingDirectory(pwszWorkingDirectory: LPCWSTR): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} LPCWSTR pwszWorkingDirectory |*)
    function GetWorkingDirectory(out ppwszWorkingDirectory: LPWSTR): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {out} LPWSTR * ppwszWorkingDirectory |*)
    function SetPriority(dwPriority: DWORD): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} DWORD dwPriority |*)
    function GetPriority(out pdwPriority: DWORD): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {out} DWORD * pdwPriority |*)
// Other properties:
    function SetTaskFlags(dwFlags: DWORD): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} DWORD dwFlags |*)
    function GetTaskFlags(out pdwFlags: DWORD): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {out} DWORD * pdwFlags |*)
    function SetMaxRunTime(dwMaxRunTimeMS: DWORD): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} DWORD dwMaxRunTimeMS |*)
    function GetMaxRunTime(out pdwMaxRunTimeMS: DWORD): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {out} DWORD * pdwMaxRunTimeMS |*)
  end;

//+----------------------------------------------------------------------------
//
//  Interface:  IEnumWorkItems
//
//  Synopsis:   Work item object enumerator. Enumerates the work item objects
//              within the Tasks folder.
//
//-----------------------------------------------------------------------------
// {148BD528-A2AB-11CE-B11F-00AA00530503}
const
{$EXTERNALSYM IID_IEnumWorkItems}
  IID_IEnumWorkItems: TIID = (D1: $148BD528; D2: $A2AB; D3: $11CE; D4: ($B1, $1F, $00, $AA, $00, $53, $05, $03));


// interface IEnumWorkItems;
type
{$EXTERNALSYM IEnumWorkItems}
  IEnumWorkItems = interface(IUnknown)
    ['{148BD528-A2AB-11CE-B11F-00AA00530503}']
// Methods:
    function Next(celt: ULONG; out rgpwszNames: PLPWSTR; out pceltFetched: ULONG): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} ULONG celt, {out} LPWSTR ** rgpwszNames, {out} ULONG * pceltFetched |*)
    function Skip(celt: ULONG): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} ULONG celt |*)
    function Reset(): HRESULT; stdcall;
    function Clone(out ppEnumWorkItems: IEnumWorkItems): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {out} IEnumWorkItems ** ppEnumWorkItems |*)
  end;

//+----------------------------------------------------------------------------
//
//  Interface:  ITaskScheduler
//
//  Synopsis:   Task Scheduler interface. Provides location transparent
//              manipulation of task and/or queue objects within the Tasks
//              folder.
//
//-----------------------------------------------------------------------------
// {148BD527-A2AB-11CE-B11F-00AA00530503}
const
{$EXTERNALSYM IID_ITaskScheduler}
  IID_ITaskScheduler: TIID = (D1: $148BD527; D2: $A2AB; D3: $11CE; D4: ($B1, $1F, $00, $AA, $00, $53, $05, $03));


// interface ITaskScheduler;
type
{$EXTERNALSYM ITaskScheduler}
  ITaskScheduler = interface(IUnknown)
    ['{148BD527-A2AB-11CE-B11F-00AA00530503}']
// Methods:
    function SetTargetComputer(pwszComputer: LPCWSTR): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} LPCWSTR pwszComputer |*)
    function GetTargetComputer(out ppwszComputer: LPWSTR): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {out} LPWSTR * ppwszComputer |*)
    function Enum(out ppEnumWorkItems: IEnumWorkItems): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {out} IEnumWorkItems ** ppEnumWorkItems |*)
    function Activate(pwszName: LPCWSTR; const riid: TIID; out ppUnk: IUnknown): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} LPCWSTR pwszName, {in} REFIID riid, {out} IUnknown ** ppUnk |*)
    function Delete(pwszName: LPCWSTR): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} LPCWSTR pwszName |*)
    function NewWorkItem(pwszTaskName: LPCWSTR; const rclsid: TCLSID; const riid: TIID; out ppUnk: IUnknown): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} LPCWSTR pwszTaskName, {in} REFCLSID rclsid, {in} REFIID riid, {out} IUnknown ** ppUnk |*)
    function AddWorkItem(pwszTaskName: LPCWSTR; const pWorkItem: IScheduledWorkItem): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} LPCWSTR pwszTaskName, {in} IScheduledWorkItem * pWorkItem |*)
    function IsOfType(pwszName: LPCWSTR; const riid: TIID): HRESULT; stdcall;
    (*| Parameter(s) was/were [CPP]: {in} LPCWSTR pwszName, {in} REFIID riid |*)
  end;

// EXTERN_C const CLSID CLSID_CTask;
// EXTERN_C const CLSID CLSID_CTaskScheduler;

// {148BD520-A2AB-11CE-B11F-00AA00530503}
const
{$EXTERNALSYM CLSID_CTask}
  CLSID_CTask: TCLSID = (D1: $148BD520; D2: $A2AB; D3: $11CE; D4: ($B1, $1F, $00, $AA, $00, $53, $05, $03));

// {148BD52A-A2AB-11CE-B11F-00AA00530503}
const
{$EXTERNALSYM CLSID_CTaskScheduler}
  CLSID_CTaskScheduler: TCLSID = (D1: $148BD52A; D2: $A2AB; D3: $11CE; D4: ($B1, $1F, $00, $AA, $00, $53, $05, $03));



//
// NOTE: Definition of HPROPSHEETPAGE is from sdk\inc\prsht.h
//       Including this header file causes numerous redefinition errors.
//

type
{$EXTERNALSYM _PSP}
  _PSP = record end;

{$IFNDEF FPC}
type
{$EXTERNALSYM HPROPSHEETPAGE}
  HPROPSHEETPAGE = ^_PSP;
{$ENDIF ~FPC}

type
{$EXTERNALSYM _TASKPAGE}
  _TASKPAGE = (
{$EXTERNALSYM TASKPAGE_TASK}
    TASKPAGE_TASK, // 0
{$EXTERNALSYM TASKPAGE_SCHEDULE}
    TASKPAGE_SCHEDULE, // 1
{$EXTERNALSYM TASKPAGE_SETTINGS}
    TASKPAGE_SETTINGS // 2
    );
{$EXTERNALSYM TASKPAGE}
  TASKPAGE = _TASKPAGE;
  TTaskPage = _TASKPAGE; // OS: Changed capitalization


//+----------------------------------------------------------------------------
//
//  Interface:  IProvideTaskPage
//
//  Synopsis:   Task property page retrieval interface. With this interface,
//              it is possible to retrieve one or more property pages
//              associated with a task object. Task objects inherit this
//              interface.
//
//-----------------------------------------------------------------------------
// {4086658a-cbbb-11cf-b604-00c04fd8d565}
const
{$EXTERNALSYM IID_IProvideTaskPage}
  IID_IProvideTaskPage: TIID = (D1: $4086658A; D2: $CBBB; D3: $11CF; D4: ($B6, $04, $00, $C0, $4F, $D8, $D5, $65));


// interface IProvideTaskPage;
type
{$EXTERNALSYM IProvideTaskPage}
  IProvideTaskPage = interface(IUnknown)
    ['{4086658A-CBBB-11CF-B604-00C04FD8D565}']
// Methods:
    function GetPage(tpType: TTaskPage; fPersistChanges: BOOL; out phPage: HPROPSHEETPAGE): HRESULT; stdcall; // OS: Changed TASKPAGE to TTaskPage
    (*| Parameter(s) was/were [CPP]: {in} TASKPAGE tpType, {in} BOOL fPersistChanges, {out} HPROPSHEETPAGE * phPage |*)
  end;


type
{$EXTERNALSYM ISchedulingAgent}
  ISchedulingAgent = ITaskScheduler;

type
{$EXTERNALSYM IEnumTasks}
  IEnumTasks = IEnumWorkItems;

const
{$EXTERNALSYM IID_ISchedulingAgent}
  IID_ISchedulingAgent: TIID = (D1: $148BD527; D2: $A2AB; D3: $11CE; D4: ($B1, $1F, $00, $AA, $00, $53, $05, $03));

const
{$EXTERNALSYM CLSID_CSchedulingAgent}
  CLSID_CSchedulingAgent: TCLSID = (D1: $148BD52A; D2: $A2AB; D3: $11CE; D4: ($B1, $1F, $00, $AA, $00, $53, $05, $03));

type
  TDateTimeArray = array of TDateTime;

  TScheduledTaskStatus = (tsUnknown, tsReady, tsRunning, tsNotScheduled, tsHasNotRun);

  TScheduledTaskFlag =
   (tfInteractive, tfDeleteWhenDone, tfDisabled, tfStartOnlyIfIdle,
    tfKillOnIdleEndl, tfDontStartIfOnBatteries, tfKillIfGoingOnBatteries,
    tfRunOnlyIfDocked, tfHidden, tfRunIfConnectedToInternet,
    tfRestartOnIdleResume, tfSystemRequired, tfRunOnlyIfLoggedOn);
  TScheduledTaskFlags = set of TScheduledTaskFlag;

  TScheduleTaskPropertyPage = (ppTask, ppSchedule, ppSettings);
  TScheduleTaskPropertyPages = set of TScheduleTaskPropertyPage;

const
  ScheduleTaskAllPages = [ppTask, ppSchedule, ppSettings];

  LocalSystemAccount = 'SYSTEM';  // Local system account name
  InfiniteTime = 0.0;

type
  TScheduledTask = class;
  TTasksListXP = TList<TScheduledTask>;

{$HPPEMIT '#define _di_ITaskScheduler ITaskScheduler*'}
{$HPPEMIT '#define _di_ITask ITask*'}

  TTaskScheduleOld = class(TObject)
  private
    FTaskScheduler: ITaskScheduler;
    FTasks: TObjectList;
    function GetTargetComputer: WideString;
    procedure SetTargetComputer(const Value: WideString);
    function GetTask(const Idx: Integer): TScheduledTask;
    function GetTaskCount: Integer;
  public
    constructor Create(const ComputerName: WideString = '');
    destructor Destroy; override;
    procedure Refresh;
    function Add(const TaskName: WideString): TScheduledTask;
    procedure Delete(const Idx: Integer);
    function Remove(const TaskName: WideString): Integer; overload;
    function Remove(const TaskIntf: ITask): Integer; overload;
    function Remove(const ATask: TScheduledTask): Integer; overload;
    property TaskScheduler: ITaskScheduler read FTaskScheduler;
    property TargetComputer: WideString read GetTargetComputer write SetTargetComputer;
    property Tasks[const Idx: Integer]: TScheduledTask read GetTask; default;
    property TaskCount: Integer read GetTaskCount;
  end;

{$HPPEMIT '#define _di_ITaskTrigger ITaskTrigger*'}

  TTaskTriggerOld = class(TCollectionItem)
  private
    FTaskTrigger: ITaskTrigger;
    procedure SetTaskTrigger(const Value: ITaskTrigger);
    function GetTrigger: TTaskTrigger;
    procedure SetTrigger(const Value: TTaskTrigger);
    function GetTriggerString: WideString;
  public
    property TaskTrigger: ITaskTrigger read FTaskTrigger;
    property Trigger: TTaskTrigger read GetTrigger write SetTrigger;
    property TriggerString: WideString read GetTriggerString;
  end;

  TScheduledWorkItem = class;

  TTaskTriggerOlds = class(TCollection)
  public
    FWorkItem: TScheduledWorkItem;
    function GetItem(Index: Integer): TTaskTriggerOld;
    procedure SetItem(Index: Integer; Value: TTaskTriggerOld);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(AWorkItem: TScheduledWorkItem);
    function Add(ATrigger: ITaskTrigger): TTaskTriggerOld; overload;
    function Add: TTaskTriggerOld; overload;
    function AddItem(Item: TTaskTriggerOld; Index: Integer): TTaskTriggerOld;
    function Insert(Index: Integer): TTaskTriggerOld;
    property Items[Index: Integer]: TTaskTriggerOld read GetItem write SetItem; default;
  end;

{$HPPEMIT '#define _di_IScheduledWorkItem IScheduledWorkItem*'}

  TScheduledWorkItem = class(TPersistent)
  private
    FScheduledWorkItem: IScheduledWorkItem;
    FTaskName: WideString;
    FData: TMemoryStream;
    FTriggers: TTaskTriggerOlds;
    function GetComment: WideString;
    procedure SetComment(const Value: WideString);
    function GetCreator: WideString;
    procedure SetCreator(const Value: WideString);
    function GetExitCode: DWORD;
    function GetDeadlineMinutes: Word;
    function GetIdleMinutes: Word;
    function GetMostRecentRunTime:TDateTime;
    function GetNextRunTime:TDateTime;
    function GetStatus: TScheduledTaskStatus;
    function GetErrorRetryCount: Word;
    procedure SetErrorRetryCount(const Value: Word);
    function GetErrorRetryInterval: Word;
    procedure SetErrorRetryInterval(const Value: Word);
    function GetFlags: TScheduledTaskFlags;
    procedure SetFlags(const Value: TScheduledTaskFlags);
    function GetData: TStream;                                  { TODO : stream is owned by instance }
    procedure SetData(const Value: TStream);                    { TODO : stream is owned by caller (copy) }
    function GetTrigger(const Idx: Integer): TTaskTriggerOld;
    function GetTriggerCount: Integer;
  public
    constructor Create(const ATaskName: WideString; const AScheduledWorkItem: IScheduledWorkItem);
    destructor Destroy; override;
    procedure Save;
    procedure Refresh;
    procedure Run;
    procedure Terminate;
    function AddTrigger: TTaskTriggerOld;
    function GetRunTimes(const BeginTime: TDateTime; const EndTime: TDateTime = InfiniteTime): TDateTimeArray;
    property ScheduledWorkItem: IScheduledWorkItem read FScheduledWorkItem;
    property TaskName: WideString read FTaskName write FTaskName;
    property Comment: WideString read GetComment write SetComment;
    property Creator: WideString read GetCreator write SetCreator;
    property ErrorRetryCount: Word read GetErrorRetryCount write SetErrorRetryCount;
    property ErrorRetryInterval: Word read GetErrorRetryInterval write SetErrorRetryInterval;
    property ExitCode: DWORD read GetExitCode;
    property OwnerData: TStream read GetData write SetData;  { TODO : wrong design, get: stream is owned by instance, set stream is owned by caller }
    property IdleMinutes: Word read GetIdleMinutes;
    property DeadlineMinutes: Word read GetDeadlineMinutes;
    property MostRecentRunTime:TDateTime read GetMostRecentRunTime;
    property NextRunTime:TDateTime read GetNextRunTime;
    property Status: TScheduledTaskStatus read GetStatus;
    property Flags: TScheduledTaskFlags read GetFlags write SetFlags;
    property Triggers[const Idx: Integer]: TTaskTriggerOld read GetTrigger; default;
    property TriggerCount: Integer read GetTriggerCount;
  end;

  TScheduledTask = class(TScheduledWorkItem)
  private
    function GetApplicationName: WideString;
    procedure SetApplicationName(const Value: WideString);
    function GetMaxRunTime: DWORD;
    procedure SetMaxRunTime(const Value: DWORD);
    function GetParameters: WideString;
    procedure SetParameters(const Value: WideString);
    function GetPriority: DWORD;
    procedure SetPriority(const Value: DWORD);
    function GetTaskFlags: DWORD;
    procedure SetTaskFlags(const Value: DWORD);
    function GetWorkingDirectory: WideString;
    procedure SetWorkingDirectory(const Value: WideString);
    function GetTask: ITask;
    function GetName:string;
    function GetState:string;
    function GetEnabled:Boolean;
  public
    function ShowPage(Pages: TScheduleTaskPropertyPages = ScheduleTaskAllPages): Boolean;
    property Task: ITask read GetTask;
    property Name:string read GetName;
    property ApplicationName: WideString read GetApplicationName write SetApplicationName;
    property WorkingDirectory: WideString read GetWorkingDirectory write SetWorkingDirectory;
    property MaxRunTime: DWORD read GetMaxRunTime write SetMaxRunTime;
    property Parameters: WideString read GetParameters write SetParameters;
    property Priority: DWORD read GetPriority write SetPriority;
    property TaskFlags: DWORD read GetTaskFlags write SetTaskFlags;
    property State:string read GetState;
    property Enabled:Boolean read GetEnabled;
  end;

//DOM-IGNORE-END

implementation

uses
  System.Win.ComObj, Winapi.CommCtrl, COCUtils, Utils;

const
  TaskFlagMapping: array [TScheduledTaskFlag] of DWORD =
   (TASK_FLAG_INTERACTIVE, TASK_FLAG_DELETE_WHEN_DONE, TASK_FLAG_DISABLED,
    TASK_FLAG_START_ONLY_IF_IDLE, TASK_FLAG_KILL_ON_IDLE_END,
    TASK_FLAG_DONT_START_IF_ON_BATTERIES, TASK_FLAG_KILL_IF_GOING_ON_BATTERIES,
    TASK_FLAG_RUN_ONLY_IF_DOCKED, TASK_FLAG_HIDDEN,
    TASK_FLAG_RUN_IF_CONNECTED_TO_INTERNET, TASK_FLAG_RESTART_ON_IDLE_RESUME,
    TASK_FLAG_SYSTEM_REQUIRED, TASK_FLAG_RUN_ONLY_IF_LOGGED_ON);

//== { TTaskScheduleOld } ====================================================

constructor TTaskScheduleOld.Create(const ComputerName: WideString = '');
begin
  inherited Create;
  FTaskScheduler := CreateComObject(CLSID_CTaskScheduler) as ITaskScheduler;
  FTasks := TObjectList.Create;
  if ComputerName <> '' then
    SetTargetComputer(ComputerName);
end;

destructor TTaskScheduleOld.Destroy;
begin
  FreeAndNil(FTasks);
  inherited Destroy;
end;

function TTaskScheduleOld.GetTargetComputer: WideString;
var
  ComputerName: PWideChar;
begin
  OleCheck(FTaskScheduler.GetTargetComputer(ComputerName));
  Result := ComputerName;
  CoTaskMemFree(ComputerName);
end;

procedure TTaskScheduleOld.SetTargetComputer(const Value: WideString);
begin
  OleCheck(FTaskScheduler.SetTargetComputer(PChar(Value)));
end;

function TTaskScheduleOld.GetTask(const Idx: Integer): TScheduledTask;
begin
  Result := TScheduledTask(FTasks.Items[Idx]);
end;

function TTaskScheduleOld.GetTaskCount: Integer;
begin
  Result := FTasks.Count;
end;

procedure TTaskScheduleOld.Refresh;
var
  EnumWorkItems: IEnumWorkItems;
  ItemName: PLPWSTR;
  RealItemName: PWideChar;
  FetchedCount: DWORD;
  TaskIid: TIID;
  spUnk: IUnknown;
  ATask: TScheduledTask;
begin
  OleCheck(TaskScheduler.Enum(EnumWorkItems));
  TaskIid := IID_ITask;
  ItemName := nil;
  FTasks.Clear;
  while SUCCEEDED(EnumWorkItems.Next(1, ItemName, FetchedCount)) and (FetchedCount > 0) do
   begin
    RealItemName:=ItemName^;
    OleCheck(TaskScheduler.Activate(RealItemName, TaskIid, spUnk));
    ATask:=TScheduledTask.Create(RealItemName, spUnk as ITask);
    ATask.Refresh;
    FTasks.Add(ATask);
   end;
end;

function TTaskScheduleOld.Add(const TaskName: WideString): TScheduledTask;
var
  TaskClsId: TCLSID;
  TaskIid: TIID;
  spUnk: IUnknown;
begin
  TaskClsId := CLSID_CTask;
  TaskIid := IID_ITask;
  OleCheck(TaskScheduler.NewWorkItem(PWideChar(TaskName), TaskClsId, TaskIid, spUnk));
  Result := TScheduledTask.Create(TaskName, spUnk as ITask);
  Result.Save;
  Result.Refresh;
  FTasks.Add(Result);
end;

procedure TTaskScheduleOld.Delete(const Idx: Integer);
begin
  Remove(Tasks[Idx]);
end;

function TTaskScheduleOld.Remove(const TaskName: WideString): Integer;
begin
  for Result := 0 to TaskCount-1 do
    if WideCompareText(Tasks[Result].TaskName, TaskName) = 0 then
    begin
      Delete(Result);
      Exit;
    end;
  Result := -1;
end;

function TTaskScheduleOld.Remove(const TaskIntf: ITask): Integer;
begin
  for Result := 0 to TaskCount-1 do
    if Tasks[Result].Task = TaskIntf then
    begin
      Delete(Result);
      Exit;
    end;
  Result := -1;
end;

function TTaskScheduleOld.Remove(const ATask: TScheduledTask): Integer;
begin
  Result := FTasks.IndexOf(ATask);
  if Result <> -1 then
  begin
    FTaskScheduler.Delete(PWideChar(Tasks[Result].TaskName));
    FTasks.Delete(Result);
    Exit;
  end;
end;

//=== { TTaskTriggerOld } ====================================================

procedure TTaskTriggerOld.SetTaskTrigger(const Value: ITaskTrigger);
begin
  FTaskTrigger := Value;
end;

function TTaskTriggerOld.GetTrigger: TTaskTrigger;
begin
  Result.cbTriggerSize := SizeOf(Result);
  OleCheck(TaskTrigger.GetTrigger(Result));
end;

procedure TTaskTriggerOld.SetTrigger(const Value: TTaskTrigger);
begin
  OleCheck(TaskTrigger.SetTrigger(Value));
end;

function TTaskTriggerOld.GetTriggerString: WideString;
var
  Trigger: PWideChar;
begin
  OleCheck(TaskTrigger.GetTriggerString(Trigger));
  Result := Trigger;
  CoTaskMemFree(Trigger);
end;

//=== { TTaskTriggerOlds } ===================================================

constructor TTaskTriggerOlds.Create(AWorkItem: TScheduledWorkItem);
begin
  inherited Create(TTaskTriggerOld);
  FWorkItem := AWorkItem;
end;

function TTaskTriggerOlds.GetItem(Index: Integer): TTaskTriggerOld;
begin
  Result := TTaskTriggerOld(inherited GetItem(Index));
end;

procedure TTaskTriggerOlds.SetItem(Index: Integer; Value: TTaskTriggerOld);
begin
  inherited SetItem(Index, Value);
end;

function TTaskTriggerOlds.GetOwner: TPersistent;
begin
  Result := FWorkItem;
end;

function TTaskTriggerOlds.Add(ATrigger: ITaskTrigger): TTaskTriggerOld;
begin
  Result := Add;
  Result.SetTaskTrigger(ATrigger);
end;

function TTaskTriggerOlds.Add: TTaskTriggerOld;
begin
  Result := TTaskTriggerOld(inherited Add);
end;

function TTaskTriggerOlds.AddItem(Item: TTaskTriggerOld; Index: Integer): TTaskTriggerOld;
begin
  if Item = nil then
    Result := Add
  else
    Result := Item;

  if Assigned(Result) then
  begin
    Result.Collection := Self;
    if Index < 0 then
      Index := Count - 1;
    Result.Index := Index;
  end;
end;

function TTaskTriggerOlds.Insert(Index: Integer): TTaskTriggerOld;
begin
  Result := AddItem(nil, Index);
end;

//=== { TScheduledWorkItem } ==============================================

constructor TScheduledWorkItem.Create(const ATaskName: WideString;
  const AScheduledWorkItem: IScheduledWorkItem);
begin
  inherited Create;
  FScheduledWorkItem := AScheduledWorkItem;
  FTaskName := ATaskName;
  FData := TMemoryStream.Create;
  FTriggers := TTaskTriggerOlds.Create(Self);
end;

destructor TScheduledWorkItem.Destroy;
begin
  FreeAndNil(FTriggers);
  FreeAndNil(FData);
  inherited Destroy;
end;

function TScheduledWorkItem.AddTrigger: TTaskTriggerOld;
var
  TaskTrigger: ITaskTrigger;
  Dummy: Word;
begin
  Result := FTriggers.Add;
  OleCheck(ScheduledWorkItem.CreateTrigger(Dummy, TaskTrigger));
  Result.SetTaskTrigger(TaskTrigger);
end;

procedure TScheduledWorkItem.Save;
begin
  OleCheck((FScheduledWorkItem as IPersistFile).Save(nil, True));
end;

procedure TScheduledWorkItem.Run;
begin
  OleCheck(FScheduledWorkItem.Run);
end;

procedure TScheduledWorkItem.Terminate;
begin
  OleCheck(FScheduledWorkItem.Terminate);
end;

function TScheduledWorkItem.GetComment: WideString;
var
  Comment: PWideChar;
begin
  OleCheck(FScheduledWorkItem.GetComment(Comment));
  Result := Comment;
  CoTaskMemFree(Comment);
end;

procedure TScheduledWorkItem.SetComment(const Value: WideString);
begin
  OleCheck(FScheduledWorkItem.SetComment(PWideChar(Value)));
end;

function TScheduledWorkItem.GetCreator: WideString;
var
  Creator: PWideChar;
begin
  OleCheck(FScheduledWorkItem.GetCreator(Creator));
  Result := Creator;
  CoTaskMemFree(Creator);
end;

procedure TScheduledWorkItem.SetCreator(const Value: WideString);
begin
  OleCheck(FScheduledWorkItem.SetCreator(PWideChar(Value)));
end;

function TScheduledWorkItem.GetExitCode: DWORD;
begin
  OleCheck(FScheduledWorkItem.GetExitCode(Result));
end;

function TScheduledWorkItem.GetDeadlineMinutes: Word;
var
  Dummy: Word;
begin
  OleCheck(FScheduledWorkItem.GetIdleWait(Result, Dummy));
end;

function TScheduledWorkItem.GetIdleMinutes: Word;
var
  Dummy: Word;
begin
  OleCheck(FScheduledWorkItem.GetIdleWait(Dummy, Result));
end;

function TScheduledWorkItem.GetMostRecentRunTime: TDateTime;
var SysTime:TSystemTime;
begin
  OleCheck(FScheduledWorkItem.GetMostRecentRunTime(SysTime));
  if SysTime.wYear <= 0 then Result:=0 else Result:=SystemTimeToDateTime(SysTime);
end;

function TScheduledWorkItem.GetNextRunTime: TDateTime;
var SysTime:TSystemTime;
begin
 OleCheck(FScheduledWorkItem.GetNextRunTime(SysTime));
 if SysTime.wYear <= 0 then Result:=0 else Result:=SystemTimeToDateTime(SysTime);
end;

function TScheduledWorkItem.GetRunTimes(const BeginTime, EndTime: TDateTime): TDateTimeArray;
var
  BeginSysTime, EndSysTime: TSystemTime;
  I, Count: Word;
  TaskTimes: PSystemTime;
begin
  DateTimeToSystemTime(BeginTime, BeginSysTime);
  DateTimeToSystemTime(EndTime, EndSysTime);

  Count := 0;
  if EndTime = InfiniteTime then
    OleCheck(FScheduledWorkItem.GetRunTimes(@BeginSysTime, nil, Count, TaskTimes))
  else
    OleCheck(FScheduledWorkItem.GetRunTimes(@BeginSysTime, @EndSysTime, Count, TaskTimes));

  try
    SetLength(Result, Count);
    for I := 0 to Count-1 do
    begin
      Result[I] := SystemTimeToDateTime(PSystemTime(TaskTimes)^);
      Inc(TaskTimes);
    end;
  finally
    CoTaskMemFree(TaskTimes);
  end;
end;

function TScheduledWorkItem.GetStatus: TScheduledTaskStatus;
var
  Status: HRESULT;
begin
  OleCheck(FScheduledWorkItem.GetStatus(Status));
  {case Status of
    SCHED_S_TASK_READY:
      Result := tsReady;
    SCHED_S_TASK_RUNNING:
      Result := tsRunning;
    SCHED_S_TASK_NOT_SCHEDULED:
      Result := tsNotScheduled;
    SCHED_S_TASK_HAS_NOT_RUN:
      Result := tsHasNotRun;
  else
    Result := tsUnknown;
  end;  }
    Result := tsUnknown;
end;

function TScheduledWorkItem.GetErrorRetryCount: Word;
begin
  OleCheck(FScheduledWorkItem.GetErrorRetryCount(Result));
end;

procedure TScheduledWorkItem.SetErrorRetryCount(const Value: Word);
begin
  OleCheck(FScheduledWorkItem.SetErrorRetryCount(Value));
end;

function TScheduledWorkItem.GetErrorRetryInterval: Word;
begin
  OleCheck(FScheduledWorkItem.GetErrorRetryInterval(Result));
end;

procedure TScheduledWorkItem.SetErrorRetryInterval(const Value: Word);
begin
  OleCheck(FScheduledWorkItem.SetErrorRetryInterval(Value));
end;

function TScheduledWorkItem.GetFlags: TScheduledTaskFlags;
var
  AFlags: DWORD;
  AFlag: TScheduledTaskFlag;
begin
  OleCheck(FScheduledWorkItem.GetFlags(AFlags));
  Result := [];
  for AFlag:=Low(TScheduledTaskFlag) to High(TScheduledTaskFlag) do
    if (AFlags and TaskFlagMapping[AFlag]) = TaskFlagMapping[AFlag] then
      Include(Result, AFlag);
end;

procedure TScheduledWorkItem.SetFlags(const Value: TScheduledTaskFlags);
var
  AFlags: DWORD;
  AFlag: TScheduledTaskFlag;
begin
  AFlags := 0;
  for AFlag:=Low(TScheduledTaskFlag) to High(TScheduledTaskFlag) do
    if AFlag in Value then
      AFlags := AFlags or TaskFlagMapping[AFlag];
  OleCheck(FScheduledWorkItem.SetFlags(AFlags));
end;

function TScheduledWorkItem.GetData: TStream;
var
  Count: Word;
  Buf: PByte;
begin
  FData.Clear;
  Buf := nil;
  OleCheck(FScheduledWorkItem.GetWorkItemData(Count, Buf));
  try
    FData.Write(Buf^, Count);
    FData.Seek(0, soFromBeginning);
  finally
    CoTaskMemFree(Buf);
  end;
  Result := FData;
end;

procedure TScheduledWorkItem.SetData(const Value: TStream);
begin
  FData.Clear;
  FData.CopyFrom(Value, 0);
  OleCheck(FScheduledWorkItem.SetWorkItemData(FData.Size, PByte(FData.Memory)));
end;

procedure TScheduledWorkItem.Refresh;
var
  I, Count: Word;
  ATrigger: ITaskTrigger;
begin
  OleCheck(FScheduledWorkItem.GetTriggerCount(Count));

  FTriggers.Clear;
  if Count > 0 then
  for I:=0 to Count-1 do
  begin
    OleCheck(FScheduledWorkItem.GetTrigger(I, ATrigger));
    FTriggers.Add(ATrigger);
  end;
end;

function TScheduledWorkItem.GetTriggerCount: Integer;
begin
  Result := FTriggers.Count;
end;

function TScheduledWorkItem.GetTrigger(const Idx: Integer): TTaskTriggerOld;
begin
  Result := TTaskTriggerOld(FTriggers.Items[Idx]);
end;

//=== { TScheduledTask } ==================================================

function TScheduledTask.GetApplicationName: WideString;
var
  AppName: PWideChar;
begin
  OleCheck(Task.GetApplicationName(AppName));
  Result := AppName;
  CoTaskMemFree(AppName);
end;

function TScheduledTask.GetName:string;
begin
 Result:=GetFileNameWoE(TaskName);
end;

function TScheduledTask.GetState:string;
var Flag:TScheduledTaskFlag;
    FText:string;
begin
 Result:='';
 for Flag in Flags do
  begin
   case Flag of
    tfDisabled: FText:='Отключена, ';
    tfHidden: FText:='Скрытая, ';
    tfSystemRequired: FText:='Наивысшие права, ';
    tfInteractive: FText:='Инетрактивная, ';
    tfDeleteWhenDone: FText:='Удалить после выполнения, ';
    tfStartOnlyIfIdle: FText:='Запуск только при простое, ';
    tfKillOnIdleEndl: FText:='Завершить после простоя, ';
    tfDontStartIfOnBatteries: FText:='Не запускать, если от батареи, ';
    tfKillIfGoingOnBatteries: FText:='Завершить, если питание от батареи, ';
    tfRunOnlyIfDocked: FText:='RunOnlyIfDocked, ';
    tfRunIfConnectedToInternet: FText:='Запуск при подключении к сети, ';
    tfRestartOnIdleResume: FText:='Перезапуск при начале простоя, ';
    tfRunOnlyIfLoggedOn: FText:='Только при выполненном входе, ';
   end;
   Result:=Result+FText;
  end;
 Delete(Result, Length(Result) - 1, 2);
end;

function TScheduledTask.GetEnabled:Boolean;
begin
 Result:=not (tfDisabled in Flags);
end;

procedure TScheduledTask.SetApplicationName(const Value: WideString);
begin
  OleCheck(Task.SetApplicationName(PWideChar(Value)));
end;

function TScheduledTask.GetMaxRunTime: DWORD;
begin
  OleCheck(Task.GetMaxRunTime(Result));
end;

procedure TScheduledTask.SetMaxRunTime(const Value: DWORD);
begin
  OleCheck(Task.SetMaxRunTime(Value));
end;

function TScheduledTask.GetParameters: WideString;
var
  Parameters: PWideChar;
begin
  OleCheck(Task.GetParameters(Parameters));
  Result := Parameters;
  CoTaskMemFree(Parameters);
end;

procedure TScheduledTask.SetParameters(const Value: WideString);
begin
  OleCheck(Task.SetParameters(PWideChar(Value)));
end;

function TScheduledTask.GetPriority: DWORD;
begin
  OleCheck(Task.GetPriority(Result));
end;

procedure TScheduledTask.SetPriority(const Value: DWORD);
begin
  OleCheck(Task.SetPriority(Value));
end;

function TScheduledTask.GetTaskFlags: DWORD;
begin
  OleCheck(Task.GetTaskFlags(Result));
end;

procedure TScheduledTask.SetTaskFlags(const Value: DWORD);
begin
  OleCheck(Task.SetTaskFlags(Value));
end;

function TScheduledTask.GetWorkingDirectory: WideString;
var
  WorkingDir: PWideChar;
begin
  OleCheck(Task.GetWorkingDirectory(WorkingDir));
  Result := WorkingDir;
  CoTaskMemFree(WorkingDir);
end;

procedure TScheduledTask.SetWorkingDirectory(const Value: WideString);
begin
  OleCheck(Task.SetWorkingDirectory(PWideChar(Value)));
end;

{$IFDEF FPC}
// strange issue ther, PropertySheet is declared in commctrl but FPC cannot resolve it
function PropertySheet(const lppsph:PROPSHEETHEADER):longint; external 'commctrl.dll' name 'PropertySheetW';
{$ENDIF FPC}

function TScheduledTask.ShowPage(Pages: TScheduleTaskPropertyPages): Boolean;
var
  PageCount: Integer;
  PropPages: array [0..2] of {$IFDEF BORLAND}MSTask.{$ENDIF}HPropSheetPage;
  PropHeader: TPropSheetHeader;
begin
  PageCount := 0;
  if ppTask in Pages then
  begin
    OleCheck((FScheduledWorkItem as IProvideTaskPage).GetPage(TASKPAGE_TASK, True, PropPages[PageCount]));
    Inc(PageCount);
  end;
  if ppSchedule in Pages then
  begin
    OleCheck((FScheduledWorkItem as IProvideTaskPage).GetPage(TASKPAGE_SCHEDULE, True, PropPages[PageCount]));
    Inc(PageCount);
  end;
  if ppSettings in Pages then
  begin
    OleCheck((FScheduledWorkItem as IProvideTaskPage).GetPage(TASKPAGE_SETTINGS, True, PropPages[PageCount]));
    Inc(PageCount);
  end;

  PropHeader.dwSize := SizeOf(PropHeader);
  PropHeader.dwFlags := PSH_DEFAULT or PSH_NOAPPLYNOW;
  PropHeader.phpage := @PropPages;
  PropHeader.nPages := PageCount;
  Result := PropertySheet(PropHeader) > 0;
end;

function TScheduledTask.GetTask: ITask;
begin
  Result := ScheduledWorkItem as ITask;
end;

end.
