unit CMW.Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, ComCtrls, ToolWin, ImgList, StdCtrls, Buttons, ShellCtrls,
  Vcl.FileCtrl, generics.collections, Vcl.ButtonGroup, Vcl.ActnMan, Vcl.ActnList,
  Vcl.Imaging.pngimage, System.Actions, Vcl.ActnCtrls, Vcl.Themes, Vcl.Menus,
  Types, CMW.Utils, FWEventLog, Module.WinProcesses, Module.Autoruns,
  Module.WinEvents, Module.Ports, Module.ContextMenu, CMW.ModuleStruct,
  CMW.OSInfo, Module.Applications, Module.Cleaner, Module.Tasks, Module.HDD,
  Module.WinServices, Module.Executting, CMW.ModuleProp, Subs, Vcl.Grids,
  Vcl.ValEdit, Module.WinFirewall, Module.SmartHND, Vcl.AppEvnts,
  System.Generics.Collections, HGM.Controls.SpinEdit, sSpeedButton, HGM.Button,
  Vcl.PlatformDefaultStyleActnCtrls, System.ImageList;

type
  TFormMain = class(TForm)
    PageControlMain: TPageControl;
    TabSheetResult: TTabSheet;
    ImageListToolBar: TImageList;
    TimerTick: TTimer;
    ListViewDelete: TListView;
    ImageListFiles: TImageList;
    TimerCurElem: TTimer;
    TabSheetExeing: TTabSheet;
    TabSheetWinApps: TTabSheet;
    TabSheetAutoruns: TTabSheet;
    ListViewAR: TListView;
    TabSheetEvents: TTabSheet;
    ListViewImPaths: TListView;
    ListViewEvents: TListView;
    PanelCtrlApps: TPanel;
    LabelCountInstall: TLabel;
    PanelAwating: TPanel;
    ProgressBar1: TProgressBar;
    Label4: TLabel;
    ButtonIgnoreDelApp: TButton;
    LabelDelSelect: TLabel;
    LabelRefreshWinApps: TLabel;
    TabSheetSheduler: TTabSheet;
    ListViewSchedule: TListView;
    TabSheetItems: TTabSheet;
    ButtonWinApps: TButton;
    ButtonAutorun: TButton;
    ButtonEvents: TButton;
    ButtonSchedule: TButton;
    ButtonUtils: TButton;
    ActionListMain: TActionList;
    ActionWinApps: TAction;
    ActionAutorun: TAction;
    ActionEvents: TAction;
    ActionSchedule: TAction;
    ActionUtils: TAction;
    ActionInfo: TAction;
    TabSheetInfo: TTabSheet;
    ActionItems: TAction;
    ActionQuit: TAction;
    Label1: TLabel;
    ListViewAccess: TListView;
    ButtonInfo: TButton;
    ButtonScan: TButton;
    PopupMenuJump: TPopupMenu;
    MenuItemAnalyse: TMenuItem;
    MenuItemInfo: TMenuItem;
    MenuItemItems: TMenuItem;
    MenuItemSchedule: TMenuItem;
    MenuItemUtils: TMenuItem;
    MenuItemWinApps: TMenuItem;
    MenuItemEvents: TMenuItem;
    MenuItemAutorun: TMenuItem;
    MenuItemN1: TMenuItem;
    Label2: TLabel;
    Label3: TLabel;
    LabelInfoOS: TLabel;
    Label5: TLabel;
    LabelInfoRam: TLabel;
    Label6: TLabel;
    LabelInfoSysDrive: TLabel;
    Label7: TLabel;
    LabelInfoCPU: TLabel;
    Label8: TLabel;
    LabelInfoMachineName: TLabel;
    Label9: TLabel;
    LabelInfoWorkGroup: TLabel;
    Label10: TLabel;
    LabelInfoActivation: TLabel;
    Label11: TLabel;
    LabelInfoUpdate: TLabel;
    Panel1: TPanel;
    LabelCountTask: TLabel;
    LabelOffAllSch: TLabel;
    Label15: TLabel;
    ActionTweaks: TAction;
    MenuItemTweaks: TMenuItem;
    TabSheetTweaks: TTabSheet;
    ListViewTweaks: TListView;
    ListViewTweakLog: TListView;
    Panel3: TPanel;
    ButtonRepiar: TButton;
    Bevel8: TBevel;
    Label23: TLabel;
    Label24: TLabel;
    ActionUpdate: TAction;
    TabSheetProc: TTabSheet;
    Panel4: TPanel;
    LabelCountProc: TLabel;
    Label27: TLabel;
    Label28: TLabel;
    ActionProcesses: TAction;
    PopupMenuProc: TPopupMenu;
    MenuItemKill: TMenuItem;
    MenuItemKillHard: TMenuItem;
    MenuItemOpenFilepath: TMenuItem;
    MenuItemN2: TMenuItem;
    TabSheetServices: TTabSheet;
    ListViewSrvs: TListView;
    Panel5: TPanel;
    LabelCountService: TLabel;
    Label31: TLabel;
    ActionSrvs: TAction;
    Panel6: TPanel;
    LabelCountEvent: TLabel;
    Label34: TLabel;
    MenuItemGoToSrvFromProc: TMenuItem;
    PopupMenuSrvs: TPopupMenu;
    MenuItemGoToProcFromSrv: TMenuItem;
    PopupMenuAutorun: TPopupMenu;
    MenuItemFindExeAR: TMenuItem;
    ListViewWinApps: TListView;
    TabSheetPorts: TTabSheet;
    ListViewPorts: TListView;
    Panel2: TPanel;
    LabelCountPorts: TLabel;
    ActionPorts: TAction;
    ImageList1: TImageList;
    ImageListFiles32: TImageList;
    MenuItemGoToPortsFromPID: TMenuItem;
    MenuItemGoToPortsFromSrv: TMenuItem;
    PopupMenuPorts: TPopupMenu;
    MenuItemGoToSrvFromPort: TMenuItem;
    MenuItemGoToProcFromPorts: TMenuItem;
    ImageListClearUnit: TImageList;
    ActionClearFind: TAction;
    ActionClearPerform: TAction;
    ListViewParam: TListView;
    ActionLogView: TAction;
    PopupMenuApps: TPopupMenu;
    ActionOpenPathInst: TAction;
    MenuItemOpenPathInst: TMenuItem;
    ActionOpenFileUnist: TAction;
    MenuItemOpenFileUnist: TMenuItem;
    ActionShowAppInfo: TAction;
    MenuItemShowAppInfo: TMenuItem;
    TabSheetHDD: TTabSheet;
    ListViewHDD: TListView;
    Panel7: TPanel;
    ActionHDD: TAction;
    ImageListGuage: TImageList;
    ImageListHDD: TImageList;
    ActionSetHDDAttr: TAction;
    ActionOpenAR: TAction;
    MenuItemOpenAR: TMenuItem;
    ActionOpenProcFromAR: TAction;
    ActionDeleteAppRKEY: TAction;
    MenuItemDeleteAppRKEY: TMenuItem;
    ActionDeleteApp: TAction;
    MenuItemDeleteApp: TMenuItem;
    MenuItemN3: TMenuItem;
    ActionRegedit: TAction;
    ActionAllTasks: TAction;
    PopupMenuCleaner: TPopupMenu;
    ActionOpenCleanerElement: TAction;
    MenuItemOpenCleanerElement: TMenuItem;
    ActionStop: TAction;
    GridPanel1: TGridPanel;
    TreeViewPID: TTreeView;
    ListViewWindows: TListView;
    Bevel6: TBevel;
    Panel8: TPanel;
    LabelCountClr: TLabel;
    Label20: TLabel;
    Label35: TLabel;
    GridPanel2: TGridPanel;
    ActionSrvOpen: TAction;
    MenuItemShowSrv: TMenuItem;
    MenuItemN4: TMenuItem;
    ActionOpenProc: TAction;
    MenuItemOpenProc: TMenuItem;
    ActionShowSrvFromProc: TAction;
    ActionPropAutoruns: TAction;
    ActionPropApps: TAction;
    ActionPropEvents: TAction;
    ActionPropTasks: TAction;
    BalloonHint: TBalloonHint;
    ListViewProc: TListView;
    ActionOpenAppFolder: TAction;
    ActionSrvStop: TAction;
    ActionSrvStart: TAction;
    ActionSrvDelete: TAction;
    ActionSrvOpenProc: TAction;
    ActionSrvOpenPorts: TAction;
    MenuItemSrvDelete: TMenuItem;
    MenuItemSrvStart: TMenuItem;
    MenuItemSrvStop: TMenuItem;
    MenuItemN5: TMenuItem;
    ActionMonitorStart: TAction;
    ActionMonitorStop: TAction;
    ActionWOW64Mode: TAction;
    ActionHelper: TAction;
    TabSheetHelper: TTabSheet;
    GridPanel3: TGridPanel;
    ListViewInfo: TListView;
    MemoInfo: TMemo;
    ValueListEditorInfo: TValueListEditor;
    ActionMSConfig: TAction;
    ActionFirewallRules: TAction;
    TabSheetFireWall: TTabSheet;
    Panel9: TPanel;
    Label36: TLabel;
    Label37: TLabel;
    Label38: TLabel;
    ListViewFW: TListView;
    ActionFWServ: TAction;
    TabSheetShellExplorer: TTabSheet;
    PanelShellCtrl: TPanel;
    ToolBarShellCtrl: TToolBar;
    ImageListShellCtrl: TImageList;
    ToolButtonSENext: TToolButton;
    PanelShell: TPanel;
    ActionSENext: TAction;
    ActionSEPrev: TAction;
    ToolButton1: TToolButton;
    EditSEPath: TEdit;
    ComboBoxRoot: TComboBox;
    ActionOnlyMainWnd: TAction;
    ActionOnlyVisableWnd: TAction;
    ActionOpenMD5Maker: TAction;
    ActionPortAdr: TAction;
    ActionEndStop: TAction;
    ActionProcStopSel: TAction;
    ImageList5: TImageList;
    TabSheetRegedit: TTabSheet;
    Panel10: TPanel;
    ActionRegeditor: TAction;
    ListViewReg: TListView;
    TreeViewReg: TTreeView;
    Splitter2: TSplitter;
    ActionSendToMM: TAction;
    MD5Maker1: TMenuItem;
    ActionAutoCheck: TAction;
    ActionRegLoad: TAction;
    ActionRegUnload: TAction;
    TimerUpdater: TTimer;
    ActionProcProp: TAction;
    N1: TMenuItem;
    N2: TMenuItem;
    ActionRestartInfoTimer: TAction;
    ActionNoteLoad: TAction;
    ActionNoteUnload: TAction;
    TabSheetDebug: TTabSheet;
    MemoDebug: TMemo;
    ActionDebug: TAction;
    ActionLoadLog: TAction;
    ListViewItems: TListView;
    MenuItemFindSrvFile: TMenuItem;
    MenuItemOpenSrvDll: TMenuItem;
    MenuItemARInfo: TMenuItem;
    MenuItemN6: TMenuItem;
    MenuItemDeleteAR: TMenuItem;
    FileOpenDialog: TFileOpenDialog;
    MenuItemSrvST: TMenuItem;
    MenuItemSrvSTBoot: TMenuItem;
    MenuItemSrvSTAuto: TMenuItem;
    MenuItemSrvSTSys: TMenuItem;
    MenuItemSrvSTAutoDelayed: TMenuItem;
    MenuItemSrvSTDemand: TMenuItem;
    MenuItemSrvSTDisable: TMenuItem;
    MenuItemN7: TMenuItem;
    PopupMenuTasks: TPopupMenu;
    ApplicationEvents1: TApplicationEvents;
    TabSheetContextMenu: TTabSheet;
    ListViewContext: TListView;
    Panel11: TPanel;
    LabelContextCount: TLabel;
    Label42: TLabel;
    Label43: TLabel;
    ActionCmdRun: TAction;
    TabSheetBSOD: TTabSheet;
    PanelMenu: TPanel;
    PanelMenuNavigate: TPanel;
    ButtonFlatMenuNav: TButtonFlat;
    ButtonFlatMenuModules: TButtonFlat;
    ButtonFlatMenuHelp: TButtonFlat;
    ButtonFlatMenuFS: TButtonFlat;
    ButtonFlatMenuMon: TButtonFlat;
    ButtonFlatMenuStart: TButtonFlat;
    ButtonFlatMenuFile: TButtonFlat;
    PanelMenuPages: TPanel;
    Shape4: TShape;
    Shape11: TShape;
    PageControlMenu: TPageControl;
    TabSheetMenuStart: TTabSheet;
    Shape9: TShape;
    PanelBarBoxActions: TPanel;
    Panel43: TPanel;
    Panel44: TPanel;
    SpeedButtonMenuBoxData: TsSpeedButton;
    Panel45: TPanel;
    SpeedButtonMenuLoadLast: TsSpeedButton;
    SpeedButtonMenuCopyDesc: TsSpeedButton;
    TabSheetMenuMonitor: TTabSheet;
    Shape12: TShape;
    Shape13: TShape;
    PanelBarPrint: TPanel;
    Shape15: TShape;
    Panel25: TPanel;
    Panel26: TPanel;
    SpeedButtonMenuPrint: TsSpeedButton;
    Panel29: TPanel;
    SpeedButtonProcStopSel: TsSpeedButton;
    Panel48: TPanel;
    PanelBarCtrl: TPanel;
    Panel37: TPanel;
    Panel47: TPanel;
    SpeedButtonMonStart: TsSpeedButton;
    SpeedButtonMonStop: TsSpeedButton;
    TabSheetMenuFS: TTabSheet;
    Shape16: TShape;
    PanelBarDBControl: TPanel;
    SpeedButtonClearFind: TsSpeedButton;
    SpeedButtonClearPerform: TsSpeedButton;
    Shape17: TShape;
    Shape18: TShape;
    Panel53: TPanel;
    Panel55: TPanel;
    SpeedButtonMD5: TsSpeedButton;
    TabSheetMenuNavigation: TTabSheet;
    Shape23: TShape;
    Shape27: TShape;
    Shape57: TShape;
    Shape58: TShape;
    Panel3DPref: TPanel;
    Panel56: TPanel;
    PanelBarPrintSet: TPanel;
    SpeedButtonMenuSetPrint: TsSpeedButton;
    Panel59: TPanel;
    PanelBarAuto: TPanel;
    Panel24: TPanel;
    Panel30: TPanel;
    PanelBarPath: TPanel;
    Panel39: TPanel;
    TabSheetMenuModules: TTabSheet;
    Shape24: TShape;
    PanelBarHelp: TPanel;
    SpeedButtonMenuInfo: TsSpeedButton;
    Shape20: TShape;
    Panel62: TPanel;
    Panel63: TPanel;
    ButtonFlatMenuTools: TButtonFlat;
    SpeedButtonWOW64Mode: TsSpeedButton;
    Panel12: TPanel;
    Panel13: TPanel;
    Panel14: TPanel;
    PanelHDD: TPanel;
    Panel16: TPanel;
    PanelRAM: TPanel;
    Panel18: TPanel;
    PanelCPU: TPanel;
    ImageCPUGraph: TImage;
    ImageDrvC: TImage;
    ImageMem: TImage;
    ImageCPU: TImage;
    Panel20: TPanel;
    sSpeedButton1: TsSpeedButton;
    Shape1: TShape;
    CheckBoxOnlyVisableWnd: TCheckBox;
    CheckBoxOnlyMainWnd: TCheckBox;
    Panel21: TPanel;
    SpeedButtonPorts: TsSpeedButton;
    Panel22: TPanel;
    SpeedButtonPortAdr: TsSpeedButton;
    Panel23: TPanel;
    Panel27: TPanel;
    Panel31: TPanel;
    SpeedButtonFirewallRules: TsSpeedButton;
    Panel35: TPanel;
    SpeedButtonSwitchFW: TsSpeedButton;
    SpeedButtonFWServ: TsSpeedButton;
    SpeedButtonFWInfo: TsSpeedButton;
    Shape2: TShape;
    CheckBoxAutoCheck: TCheckBox;
    Panel28: TPanel;
    SpeedButtonHDD: TsSpeedButton;
    Panel32: TPanel;
    Panel33: TPanel;
    CheckBoxSetHDDAttr: TCheckBox;
    Shape6: TShape;
    Panel34: TPanel;
    SpeedButtonContextMenuGet: TsSpeedButton;
    Panel36: TPanel;
    Panel38: TPanel;
    Shape3: TShape;
    ComboBoxCMElem: TComboBox;
    Shape5: TShape;
    SpeedButtonClasses: TsSpeedButton;
    Shape7: TShape;
    Panel40: TPanel;
    SpeedButtonClassGetNext: TsSpeedButton;
    SpeedButtonClassGetSTop: TsSpeedButton;
    ButtonedEditRun: TButtonedEdit;
    ButtonedEditParam: TButtonedEdit;
    SpeedButtonCmdRun: TsSpeedButton;
    SpeedButtonMSConfig: TsSpeedButton;
    SpeedButtonRegedit: TsSpeedButton;
    Panel41: TPanel;
    SpeedButtonEvents: TsSpeedButton;
    Shape8: TShape;
    Panel42: TPanel;
    Panel46: TPanel;
    SpeedButtonWillGetBackupEvents: TsSpeedButton;
    SpeedButtonWillGetSysEvents: TsSpeedButton;
    Shape10: TShape;
    Panel49: TPanel;
    SpeedButtonAutorun: TsSpeedButton;
    Panel50: TPanel;
    Shape19: TShape;
    Panel51: TPanel;
    sSpeedButton5: TsSpeedButton;
    Panel52: TPanel;
    Shape14: TShape;
    Panel54: TPanel;
    ComboBoxEventsDate: TComboBox;
    ComboBoxEventsList: TComboBox;
    ComboBoxEventType: TComboBox;
    Label44: TLabel;
    Label45: TLabel;
    Label46: TLabel;
    CheckBoxAllTasks: TCheckBox;
    TabSheetMenuTools: TTabSheet;
    Panel57: TPanel;
    SpeedButtonRegeditor: TsSpeedButton;
    Panel58: TPanel;
    Panel60: TPanel;
    SpeedButtonRegLoad: TsSpeedButton;
    Shape25: TShape;
    Panel61: TPanel;
    SpeedButtonUtils: TsSpeedButton;
    SpeedButtonOpenHostsFile: TsSpeedButton;
    Panel64: TPanel;
    Shape29: TShape;
    SpeedButtonTweaks: TsSpeedButton;
    SpeedButtonRegUnload: TsSpeedButton;
    TabSheetMenuHelp: TTabSheet;
    Panel65: TPanel;
    SpeedButtonHelper: TsSpeedButton;
    Panel66: TPanel;
    Panel67: TPanel;
    SpeedButtonAbout: TsSpeedButton;
    Shape21: TShape;
    Panel68: TPanel;
    SpeedButtonLogView: TsSpeedButton;
    SpeedButtonDebug: TsSpeedButton;
    Panel69: TPanel;
    Shape22: TShape;
    Shape26: TShape;
    Panel70: TPanel;
    SpeedButtonNoteUnload: TsSpeedButton;
    SpeedButtonNoteLoad: TsSpeedButton;
    Shape28: TShape;
    Shape30: TShape;
    Shape31: TShape;
    Shape32: TShape;
    ActionWillGetBackupEvents: TAction;
    ActionWillGetSysEvents: TAction;
    Panel15: TPanel;
    ComboBoxStorageList: TComboBox;
    SpeedButtonUpdateStotageList: TsSpeedButton;
    PanelStateBar: TPanel;
    ListBoxState: TListBox;
    ProgressBarState: TProgressBar;
    Panel17: TPanel;
    LabelCountHDD: TLabel;
    Label29: TLabel;
    Panel19: TPanel;
    Label21: TLabel;
    Label22: TLabel;
    LabelCountAutorun: TLabel;
    Panel71: TPanel;
    Panel72: TPanel;
    Panel73: TPanel;
    Panel74: TPanel;
    Splitter3: TSplitter;
    Panel75: TPanel;
    SpeedButtonStop: TsSpeedButton;
    SpeedButtonEndStop: TsSpeedButton;
    SpeedButtonUpdate: TsSpeedButton;
    Panel76: TPanel;
    Panel77: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure TimerCurElemTimer(Sender: TObject);
    procedure ListViewARDblClick(Sender: TObject);
    procedure ButtonIgnoreDelAppClick(Sender: TObject);
    procedure LabelMouseEnter(Sender: TObject);
    procedure LabelMouseLeave(Sender: TObject);
    procedure LabelDelSelectClick(Sender: TObject);
    procedure ActionWinAppsExecute(Sender: TObject);
    procedure ActionAutorunExecute(Sender: TObject);
    procedure ActionEventsExecute(Sender: TObject);
    procedure ActionScheduleExecute(Sender: TObject);
    procedure ActionUtilsExecute(Sender: TObject);
    procedure ActionInfoExecute(Sender: TObject);
    procedure ActionItemsExecute(Sender: TObject);
    procedure ActionQuitExecute(Sender: TObject);
    procedure LabelOffAllSchClick(Sender: TObject);
    procedure ActionTweaksExecute(Sender: TObject);
    procedure OnChangeCurElement(var Value: string);
    procedure Label21Click(Sender: TObject);
    procedure ListViewEventsDblClick(Sender: TObject);
    procedure ActionUpdateExecute(Sender: TObject);
    procedure ActionProcessesExecute(Sender: TObject);
    procedure ListViewProcMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MenuItemKillClick(Sender: TObject);
    procedure MenuItemKillHardClick(Sender: TObject);
    procedure MenuItemOpenFilepathClick(Sender: TObject);
    procedure ActionSrvsExecute(Sender: TObject);
    procedure TreeViewPIDClick(Sender: TObject);
    procedure ListViewProcClick(Sender: TObject);
    procedure MenuItemGoToProcFromSrvClick(Sender: TObject);
    procedure ListViewSrvsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ListViewARMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ActionPortsExecute(Sender: TObject);
    procedure ListViewPortsDblClick(Sender: TObject);
    procedure MenuItemGoToPortsFromPIDClick(Sender: TObject);
    procedure MenuItemGoToSrvFromPortClick(Sender: TObject);
    procedure ListViewPortsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MenuItemGoToProcFromPortsClick(Sender: TObject);
    procedure ActionClearFindExecute(Sender: TObject);
    procedure ActionClearPerformExecute(Sender: TObject);
    procedure ActionLogViewExecute(Sender: TObject);
    procedure TimerTickTimer(Sender: TObject);
    procedure ActionOpenPathInstExecute(Sender: TObject);
    procedure ListViewWinAppsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ActionOpenFileUnistExecute(Sender: TObject);
    procedure ActionHDDExecute(Sender: TObject);
    procedure ActionSetHDDAttrExecute(Sender: TObject);
    procedure ListViewHDDDblClick(Sender: TObject);
    procedure ActionOpenARExecute(Sender: TObject);
    procedure ActionOpenProcFromARExecute(Sender: TObject);
    procedure ActionDeleteAppRKEYExecute(Sender: TObject);
    procedure ActionDeleteAppExecute(Sender: TObject);
    procedure ButtonedEditRunRightButtonClick(Sender: TObject);
    procedure ButtonedEditRunLeftButtonClick(Sender: TObject);
    procedure ButtonedEditParamLeftButtonClick(Sender: TObject);
    procedure ActionRegeditExecute(Sender: TObject);
    procedure ButtonedEditRunKeyPress(Sender: TObject; var Key: Char);
    procedure ActionOpenCleanerElementExecute(Sender: TObject);
    procedure ListViewDeleteMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ListViewParamDblClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ActionAllTasksExecute(Sender: TObject);
    procedure ActionStopExecute(Sender: TObject);
    procedure ListViewWindowsClick(Sender: TObject);
    procedure ActionSrvOpenExecute(Sender: TObject);
    procedure ActionOpenProcExecute(Sender: TObject);
    procedure ActionShowSrvFromProcExecute(Sender: TObject);
    procedure ActionPropAutorunsExecute(Sender: TObject);
    procedure ActionPropAppsExecute(Sender: TObject);
    procedure ActionPropEventsExecute(Sender: TObject);
    procedure ActionPropTasksExecute(Sender: TObject);
    procedure ActionOpenAppFolderExecute(Sender: TObject);
    procedure ActionSrvOpenProcExecute(Sender: TObject);
    procedure ActionSrvOpenPortsExecute(Sender: TObject);
    procedure ActionSrvStopExecute(Sender: TObject);
    procedure ActionSrvStartExecute(Sender: TObject);
    procedure ActionSrvDeleteExecute(Sender: TObject);
    procedure ActionWOW64ModeExecute(Sender: TObject);
    procedure ActionHelperExecute(Sender: TObject);
    procedure ListViewProcKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ActionFirewallRulesExecute(Sender: TObject);
    procedure ActionFWServExecute(Sender: TObject);
    procedure ActionSwitchFWExecute(Sender: TObject);
    procedure ActionFWInfoExecute(Sender: TObject);
    procedure ActionShellExplorerExecute(Sender: TObject);
    procedure ActionSENextExecute(Sender: TObject);
    procedure ActionSEPrevExecute(Sender: TObject);
    procedure ComboBoxRootChange(Sender: TObject);
    procedure EditSEPathKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ActionOnlyMainWndExecute(Sender: TObject);
    procedure ActionOnlyVisableWndExecute(Sender: TObject);
    procedure ActionOpenMD5MakerExecute(Sender: TObject);
    procedure PageControlMainChange(Sender: TObject);
    procedure ActionMonitorStartExecute(Sender: TObject);
    procedure ActionMonitorStopExecute(Sender: TObject);
    procedure ActionPortAdrExecute(Sender: TObject);
    procedure ActionEndStopExecute(Sender: TObject);
    procedure ActionProcStopSelExecute(Sender: TObject);
    procedure ActionRegeditorExecute(Sender: TObject);
    procedure ActionSendToMMExecute(Sender: TObject);
    procedure ActionAutoCheckExecute(Sender: TObject);
    procedure ActionRegLoadExecute(Sender: TObject);
    procedure ActionRegUnloadExecute(Sender: TObject);
    procedure TimerUpdaterTimer(Sender: TObject);
    procedure ActionProcPropExecute(Sender: TObject);
    procedure ActionRestartInfoTimerExecute(Sender: TObject);
    procedure ActionNoteLoadExecute(Sender: TObject);
    procedure ActionNoteUnloadExecute(Sender: TObject);
    procedure ActionDebugExecute(Sender: TObject);
    procedure ActionLoadLogExecute(Sender: TObject);
    procedure ListViewItemsDblClick(Sender: TObject);
    procedure ActionFindSrvFileExecute(Sender: TObject);
    procedure ActionOpenSrvDllExecute(Sender: TObject);
    procedure ActionARInfoExecute(Sender: TObject);
    procedure ActionDeleteARExecute(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ActionWillGetSysEventsExecute(Sender: TObject);
    procedure ActionWillGetBackupEventsExecute(Sender: TObject);
    procedure ActionSrvSTDisableExecute(Sender: TObject);
    procedure ActionSrvSTDemandExecute(Sender: TObject);
    procedure ActionSrvSTAutoExecute(Sender: TObject);
    procedure ActionSrvSTAutoDelayedExecute(Sender: TObject);
    procedure ActionSrvSTBootExecute(Sender: TObject);
    procedure ActionSrvSTSysExecute(Sender: TObject);
    procedure ActionDeleteExecute(Sender: TObject);
    procedure ApplicationEvents1ShortCut(var Msg: TWMKey; var Handled: Boolean);
    procedure ActionContextMenuGetExecute(Sender: TObject);
    procedure ActionClassesExecute(Sender: TObject);
    procedure ActionClassGetNextExecute(Sender: TObject);
    procedure ActionClassGetSTopExecute(Sender: TObject);
    procedure ActionOpenHostsFileExecute(Sender: TObject);
    procedure ListViewContextDblClick(Sender: TObject);
    procedure ActionAboutExecute(Sender: TObject);
    procedure ActionShowAppInfoExecute(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ButtonFlatMenuStartClick(Sender: TObject);
    procedure ButtonFlatMenuMonClick(Sender: TObject);
    procedure ButtonFlatMenuFSClick(Sender: TObject);
    procedure ButtonFlatMenuNavClick(Sender: TObject);
    procedure ButtonFlatMenuModulesClick(Sender: TObject);
    procedure ButtonFlatMenuToolsClick(Sender: TObject);
    procedure ButtonFlatMenuHelpClick(Sender: TObject);
    procedure ComboBoxStorageListChange(Sender: TObject);
    procedure SpeedButtonUpdateStotageListClick(Sender: TObject);
    procedure ActionMSConfigExecute(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    procedure OpenMenuTab(Tab: TTabSheet);
  public
    LPT: Byte;
    LStep: Byte;
    Sz: Byte;
    AvailableInfo: Boolean;
    //SH:TSmartHandler;
    procedure NoteUnload;
    procedure OnSEClick(Sender: TObject);
    procedure CreateFaceItems;
    procedure ExceptionHandler(Sender: TObject; E: Exception);
    function LoadSettings: Boolean;
    function SaveSettings: Boolean;
    procedure OpenTabItems;
    procedure OpenTabNamed(TabSheet: TTabSheet);
    procedure CreateInfo;
    procedure UpdateInfo;
    procedure OpenResult;
    procedure CheckTabsPos;
    procedure NewPointForCPU(PT: Byte);
    procedure DrawGridPart(DCanvas: TCanvas);
    procedure FillComboBoxES;
    procedure FillComboBoxET;
    procedure FillComboBoxED;
    procedure Quit;
  end;

const
  ConfigFileName = 'Data\Config.inf';
  DebugFileName = 'debug.log';
  LinkColor: TColor = clHighlight;
  UnLinkColor: TColor = clBlack;
  GridSz: Byte = 10;
  App32 = 'CWM32.exe';
  App64 = 'CWM64.exe';
  AppNameRu = 'Комплекс обслуживания рабочих станций';
  AppNameEn = 'Complex maintenance of workstations';

var
  FormMain: TFormMain;
  SmartHandler: TSmartHandler;
  //ListOfEventType:TStrings;
  UseEvtInf: Byte = 0;
  WarningAboutInconsistency: Boolean = False;
  WarningAboutTrustlevel: Boolean = False;
  ShellExplorer: TShellListView;
  //BMP:TBitmap;

  //Малозначимые переменные
  FlagLoadNote: Boolean = False;

procedure Init;

function Stopping: Boolean;

procedure CreateProp(SysUnit: TSystemUnit);

implementation

{$R *.dfm}

uses
  ShellAPI, Registry, IniFiles, Vcl.Clipbrd, Module.Regeditor, System.UITypes,
  CMW.About;

procedure SetActionDataLI(LI: TListItem; Action: Pointer; Group: Integer);
begin
  LI.Caption := TAction(Action^).Caption;
  LI.SubItems.Add('');
  LI.Data := Action;
  LI.ImageIndex := TAction(Action^).ImageIndex;
  LI.GroupID := Group;
end;

procedure TFormMain.NoteUnload;
begin
  FileClose(FileCreate(CurrentDir + DebugFileName));
  Application.ProcessMessages;
  Application.ProcessMessages;
  MemoDebug.Lines.SaveToFile(CurrentDir + DebugFileName);
end;

procedure TFormMain.OnSEClick(Sender: TObject);
begin
  if not Assigned(ShellExplorer) then
    Exit;
  EditSEPath.Text := ShellExplorer.RootFolder.PathName;
end;

procedure TFormMain.DrawGridPart(DCanvas: TCanvas);
var
  i: Word;
begin
  Inc(LStep);
  with DCanvas do
  begin
    Pen.Color := $00003300;
    Pen.Width := 1;
  end;
  if LStep >= GridSz div (Sz) then
  begin
    LStep := 0;
    with DCanvas do
    begin
      MoveTo(ClipRect.Width - Sz, 0);
      LineTo(ClipRect.Width - Sz, ClipRect.Height);
    end;
  end;
  with DCanvas do
  begin
    for i := 1 to ClipRect.Height div GridSz do
    begin
      MoveTo(ClipRect.Width - Sz, GridSz * i);
      LineTo(ClipRect.Width + Sz, GridSz * i);
    end;
  end;
end;

procedure TFormMain.NewPointForCPU(PT: Byte);
var
  W, H: Integer;
  MP: Byte;
  BMP: TBitmap;
begin
  W := ImageCPUGraph.Picture.Bitmap.Canvas.ClipRect.Width;
  H := ImageCPUGraph.Picture.Bitmap.Canvas.ClipRect.Height;
  BMP := TBitmap.Create;
  BMP.Width := W;
  BMP.Height := H;
  BMP.PixelFormat := pf24bit;
  ImageCPUGraph.Canvas.Brush.Color := clBlack;
  BMP.Canvas.CopyRect(Rect(0, 0, W, H), ImageCPUGraph.Canvas, Rect(0, 0, W, H));
  ImageCPUGraph.Canvas.FillRect(ImageCPUGraph.Canvas.ClipRect);
  ImageCPUGraph.Canvas.CopyRect(Rect(-Sz, 0, W - Sz, H), BMP.Canvas, Rect(0, 0, W, H));
  BMP.Free;
  DrawGridPart(ImageCPUGraph.Canvas);
  MP := H - Round((H / 100) * PT);
  ImageCPUGraph.Canvas.Pen.Width := 2;
  ImageCPUGraph.Canvas.Pen.Color := MixColors(clRed, clLime, PT);
  WuLine(ImageCPUGraph.Picture.Bitmap, Point(W - (Sz + 1), LPT), Point(W - 1, MP), ImageCPUGraph.Canvas.Pen.Color);
  WuLine(ImageCPUGraph.Picture.Bitmap, Point(W - Sz, LPT), Point(W, MP), ImageCPUGraph.Canvas.Pen.Color);

  LPT := MP;
  ImageCPUGraph.Repaint;
end;

procedure TFormMain.EditSEPathKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_RETURN:
      begin
        if not Assigned(ShellExplorer) then
          Exit;
        ShellExplorer.Root := EditSEPath.Text;
      end;
  end;
end;

procedure TFormMain.ExceptionHandler(Sender: TObject; E: Exception);
begin
  Log(['Исключение:', E.Message, E.BaseException, E.StackInfo, E.StackTrace, E.InnerException, Sender]);
  if MessageBox(0, PWideChar('Возникло исключение с ошибкой: "' + E.Message + '".'#13#10 + 'Продолжить работу?'), 'Внимание', MB_ICONERROR or MB_YESNO) = ID_NO then
    Halt(1);
end;

procedure CreateProp(SysUnit: TSystemUnit);
begin
  TFormUnitProperties.Create(@SysUnit).ShowModal;
end;

function BoolToStr(Value: Boolean): string;
begin
  if Value then
    Result := LangText(33, 'Да')
  else
    Result := LangText(34, 'Нет');
end;

function Stopping: Boolean;
begin
  Application.ProcessMessages;
  Result := SmartHandler.Stop;
end;

procedure Init;
begin
  with FormMain do
  begin
    DoubleBuffered := True;
   //--------------------------------------
    try
      SmartHandler := TSmartHandler.Create;
      SmartHandler.ProgressBarState := ProgressBarState;
    except
      begin
        MessageBox(Application.Handle, PChar(LangText(102, 'Программа не имеет необходимых прав для получения информации о вашем компьютере./nВыполните программу от имени администратора!')), PChar(LangText(103, 'Прошу прощения')), MB_ICONSTOP or MB_OK);
        Application.Terminate;
      end;
    end;
    SmartHandler.OnSetCurElement := OnChangeCurElement;
   //---------------------------На страницу "Управление"
   //OpenTabItems;
    OpenTabNamed(TabSheetInfo);

   //ListOfEventType:=TStringList.Create;
   ///ListOfEventType.LoadFromFile(CurrentDir+'Data\EventLog.inf');
    Caption := AppNameRu + ' ' + BitsToStr(AppBits);

    SmartHandler.AccessState(ListViewAccess);

    SpeedButtonUpdateStotageListClick(nil);

    TimerTick.Enabled := True;
  end;
end;

procedure RefreshLVs;
begin
  with FormMain do
  begin
    ListViewEvents.CustomSort(@CustomDateSortProc, -1);
    LabelCountEvent.Caption := IntToStr(ListViewEvents.Items.Count);
    ListViewSchedule.CustomSort(@CustomStrSortProc, 0);
    LabelCountTask.Caption := IntToStr(ListViewSchedule.Items.Count);
    ListViewImPaths.CustomSort(@CustomStrSortProc, 0);
    ListViewProc.CustomSort(@CustomStrSortProc, -1);
    LabelCountProc.Caption := IntToStr(ListViewProc.Items.Count);
    ListViewPorts.CustomSort(@CustomIntSortProc, 0);
    LabelCountPorts.Caption := IntToStr(ListViewPorts.Items.Count);
  end;
end;

procedure TFormMain.OnChangeCurElement(var Value: string);
begin  //ListBoxState
  ListBoxState.Items.Insert(0, FormatDateTime('HH:MM:SS: ', Now) + Value);
 //ListBoxState.Items.Add();
 //LabelState.Caption:=Value;
  Application.ProcessMessages;
end;

function TFormMain.LoadSettings: Boolean;
var
  Ini: TIniFile;
  SName: string;
  Crt: Boolean;
  FC: Integer;
begin
  Crt := True;
  if not DirectoryExists(CurrentDir + 'Data') then
    Crt := CreateDir(CurrentDir + 'Data');
  if not FileExists(CurrentDir + ConfigFileName) then
  begin
    FC := FileCreate(CurrentDir + ConfigFileName);
    Crt := FC <> 0;
    if Crt then
      FileClose(FC);
  end;
  Ini := TIniFile.Create(CurrentDir + ConfigFileName);
  Position := poDesigned;
  ClientWidth := Ini.ReadInteger('Config', 'Width', ClientWidth);     //772 462
  ClientHeight := Ini.ReadInteger('Config', 'Height', ClientHeight);
  SName := Ini.ReadString('Config', 'StyleName', '');
  if SName <> '' then
    TStyleManager.TrySetStyle(SName, True);
  Left := Ini.ReadInteger('Config', 'Left', Left);
  Top := Ini.ReadInteger('Config', 'Top', Top);
  WindowState := TWindowState(Ini.ReadInteger('Config', 'WindowState', 0));
  Ini.Free;
  Result := True;
end;

procedure TFormMain.MenuItemGoToPortsFromPIDClick(Sender: TObject);
var
  PID: Integer;
begin
  if ListViewProc.Selected = nil then
    Exit;
  if not TryStrToInt(ListViewProc.Selected.SubItems[0], PID) then
    Exit;
  if SmartHandler.PortsUnit.State <> gsFinished then
    ActionPorts.Execute;
  SelectPortsByPID(ListViewPorts, PID);
  OpenTabNamed(TabSheetPorts);
end;

procedure TFormMain.MenuItemGoToProcFromPortsClick(Sender: TObject);
var
  DT: TCOMMONROW;
begin
  if ListViewPorts.Selected = nil then
    Exit;
  if ListViewPorts.Selected.Data = nil then
    Exit;
  DT := TCommonRow(ListViewPorts.Selected.Data^);

  if SmartHandler.ProcessesUnit.State <> gsFinished then
    ActionProcesses.Execute;
  SelectProcByPID(ListViewProc, DT.dwProcessID);
  OpenTabNamed(TabSheetProc);
  ListViewProcClick(nil);
end;

procedure TFormMain.MenuItemGoToProcFromSrvClick(Sender: TObject);
begin
 //
end;

procedure TFormMain.MenuItemGoToSrvFromPortClick(Sender: TObject);
var
  DT: TCOMMONROW;
begin
  if ListViewPorts.Selected = nil then
    Exit;
  if ListViewPorts.Selected.Data = nil then
    Exit;
  DT := TCommonRow(ListViewPorts.Selected.Data^);
  if SmartHandler.ServicesUnit.State <> gsFinished then
    ActionSrvs.Execute;
  SmartHandler.ServicesUnit.Select(DT.dwProcessID);
  OpenTabNamed(TabSheetServices);
end;

procedure TFormMain.MenuItemKillClick(Sender: TObject);
begin
  if MessageBox(Application.Handle, PWideChar('Вы действительн хотите завершить этот процесс?'), '', MB_ICONASTERISK or MB_YESNO) <> ID_YES then
    Exit;
  SmartHandler.ProcessesUnit.DeleteSelected;
end;

procedure TFormMain.MenuItemKillHardClick(Sender: TObject);
begin
  if MessageBox(Application.Handle, PWideChar('Вы действительно хотите завершить этот процесс?'), '', MB_ICONASTERISK or MB_YESNO) <> ID_YES then
    Exit;
  SmartHandler.ProcessesUnit.HardDeleteSelected;
end;

procedure TFormMain.MenuItemOpenFilepathClick(Sender: TObject);
begin
  if ListViewProc.Selected = nil then
    Exit;
  if ListViewProc.Selected.Data = nil then
    Exit;
  OpenFolderAndSelectFile(TProcessData(ListViewProc.Selected.Data^).ExePath);
end;

function TFormMain.SaveSettings: Boolean;
var
  Ini: TIniFile;
begin
  try
    if not FileExists(CurrentDir + ConfigFileName) then
      FileClose(FileCreate(CurrentDir + ConfigFileName));
    try
      Ini := TIniFile.Create(CurrentDir + ConfigFileName);
   //Ini.WriteString('Config', 'StyleName', TStyleManager.ActiveStyle.Name);
      if WindowState = wsNormal then
      begin
        Ini.WriteInteger('Config', 'Left', Left);
        Ini.WriteInteger('Config', 'Top', Top);
        Ini.WriteInteger('Config', 'Width', ClientWidth);
        Ini.WriteInteger('Config', 'Height', ClientHeight);
      end;
      Ini.WriteInteger('Config', 'WindowState', Ord(WindowState));
    except
   //Сохранения не произведены
      Result := False;
    end;
  finally
    Ini.Free;
  end;
  Result := True;
end;

procedure TFormMain.SpeedButtonUpdateStotageListClick(Sender: TObject);
begin
  SmartHandler.HDDUnit.FillComboBox(ComboBoxStorageList);
  if ComboBoxStorageList.Items.Count > 0 then
    ComboBoxStorageList.ItemIndex := 0;
end;

procedure TFormMain.OpenResult;
begin
  PageControlMain.ActivePage := TabSheetResult;
end;

procedure TFormMain.CheckTabsPos;
var
  len: Integer;
begin
 //len:=PageControlMain.Top - (RibbonPanel.Height - 4);
 //PageControlMain.Top:=RibbonPanel.Height - 4;
 //PageControlMain.Height:=PageControlMain.Height + len;
end;

procedure TFormMain.ComboBoxRootChange(Sender: TObject);
begin
  if not Assigned(ShellExplorer) then
    Exit;
  ShellExplorer.Root := ComboBoxRoot.Text;
end;

procedure TFormMain.ComboBoxStorageListChange(Sender: TObject);
begin
 //
end;

procedure TFormMain.TreeViewPIDClick(Sender: TObject);
var
  PID: Integer;
begin
  if TreeViewPID.Selected = nil then
    Exit;
  if TreeViewPID.Selected.Data = nil then
    Exit;
  try
  //ListViewProc.Selected:=TListItem(TreeViewPID.Selected.Data^);
    PID := TProcessData(TreeViewPID.Selected.Data^).ProcessID;

    SelectProcByPID(ListViewProc, PID);
    SelectWndByPID(ListViewWindows, PID);
  except

  end;
end;

procedure TFormMain.ActionAboutExecute(Sender: TObject);
begin
  FormAbout.ShowModal;
end;

procedure TFormMain.ActionAllTasksExecute(Sender: TObject);
begin
  ActionAllTasks.Checked := not ActionAllTasks.Checked;
end;

procedure TFormMain.ActionARInfoExecute(Sender: TObject);
begin
  SmartHandler.AutorunsUnit.ShowInfo;
end;

procedure TFormMain.ActionAutoCheckExecute(Sender: TObject);
begin
 //
end;

procedure TFormMain.ActionAutorunExecute(Sender: TObject);
begin
  if PageControlMain.ActivePage <> TabSheetAutoruns then
  begin
    OpenTabNamed(TabSheetAutoruns);
    Application.ProcessMessages;
    if SmartHandler.AutorunsUnit.State <> gsFinished then
      SmartHandler.AutorunsUnit.Get;
  end
  else
  begin
    SmartHandler.AutorunsUnit.Get;
  end;
end;

procedure TFormMain.ActionClassesExecute(Sender: TObject);
begin
  if PageControlMain.ActivePage <> TabSheetContextMenu then
  begin
    PageControlMain.ActivePage := TabSheetContextMenu;
    Application.ProcessMessages;
    if SmartHandler.ContextMenuUnit.State <> gsFinished then
    begin
      SmartHandler.ContextMenuUnit.Get(gtCLSIDs);
    end;
  end
  else
  begin
    SmartHandler.ContextMenuUnit.Get(gtCLSIDs);
  end;
end;

procedure TFormMain.ActionClassGetNextExecute(Sender: TObject);
begin
  SmartHandler.ContextMenuUnit.Next;
end;

procedure TFormMain.ActionClassGetSTopExecute(Sender: TObject);
begin
  SmartHandler.ContextMenuUnit.Stop;
end;

procedure TFormMain.ActionClearFindExecute(Sender: TObject);
begin
  SmartHandler.CleanerUnit.ScanFiles := ActionAutoCheck.Checked;
  if PageControlMain.ActivePage <> TabSheetResult then
  begin
    PageControlMain.ActivePage := TabSheetResult;
    Application.ProcessMessages;
    if SmartHandler.CleanerUnit.State <> gsFinished then
      SmartHandler.CleanerUnit.Get;
  end
  else
    SmartHandler.CleanerUnit.Get;
end;

procedure TFormMain.ActionClearPerformExecute(Sender: TObject);
begin
  if PageControlMain.ActivePage <> TabSheetResult then
  begin
    PageControlMain.ActivePage := TabSheetResult;
    Application.ProcessMessages;
    if SmartHandler.CleanerUnit.State <> gsFinished then
    begin
      SmartHandler.CleanerUnit.Get;
      if MessageBox(Application.Handle, 'Вы уверены, что хотите удалить все отмеченные элементы?', 'Внимание', MB_ICONINFORMATION or MB_YESNO) <> ID_YES then
        Exit;
      if SmartHandler.CleanerUnit.PerformRemoval then
        ShowMessage('Удаление завершено успешно.');
    end;
  end
  else
  begin
    if SmartHandler.CleanerUnit.State <> gsFinished then
      SmartHandler.CleanerUnit.Get;
    if MessageBox(Application.Handle, 'Вы уверены, что хотите удалить все отмеченные элементы?', 'Внимание', MB_ICONINFORMATION or MB_YESNO) <> ID_YES then
      Exit;
    if SmartHandler.CleanerUnit.PerformRemoval then
      ShowMessage('Удаление завершено успешно.');
  end;
end;

procedure TFormMain.ActionContextMenuGetExecute(Sender: TObject);
var
  RegKey: string;
begin
  case ComboBoxCMElem.ItemIndex of
  //-1:RegKey:=ComboBoxCMElem.Text;
    0:
      RegKey := '*';
    1:
      RegKey := '.exe';
    2:
      RegKey := '.dll';
    3:
      RegKey := 'Directory';
    4:
      RegKey := '.docx';
    5:
      RegKey := '.xls';
    6:
      RegKey := '.xlsx';
    7:
      RegKey := 'AllFilesystemObjects';
  else
    RegKey := ComboBoxCMElem.Text;
  end;
  if PageControlMain.ActivePage <> TabSheetContextMenu then
  begin
    PageControlMain.ActivePage := TabSheetContextMenu;
    Application.ProcessMessages;
    if SmartHandler.ContextMenuUnit.State <> gsFinished then
    begin
      SmartHandler.ContextMenuUnit.RegKey := RegKey;
      SmartHandler.ContextMenuUnit.Get(gtContext);
    end;
  end
  else
  begin
    SmartHandler.ContextMenuUnit.RegKey := RegKey;
    SmartHandler.ContextMenuUnit.Get(gtContext);
  end;
end;

procedure TFormMain.ActionDebugExecute(Sender: TObject);
begin
  OpenTabNamed(TabSheetDebug);
  if not FlagLoadNote then
    ActionNoteLoad.Execute;
end;

procedure TFormMain.ActionDeleteAppExecute(Sender: TObject);
begin
  if ProcessMonitor.Executing then
  begin
    if MessageBox(Application.Handle, PChar(LangText(40, 'Уже идёт удаление другого приложения! Продолжить?')), PChar(LangText(41, 'Внимание')), MB_ICONINFORMATION or MB_YESNO) = ID_YES then
      ProcessMonitor.Stop
    else
      Exit;
  end;
  if MessageBox(Application.Handle, 'Удалить программу?', 'Вопрос', MB_ICONINFORMATION or MB_YESNO) <> ID_YES then
    Exit;
  if not SmartHandler.ApplicationsUnit.DeleteSelected then
    ShowMessage('Не удалено!');
end;

procedure TFormMain.ActionDeleteAppRKEYExecute(Sender: TObject);
begin
  if MessageBox(Application.Handle, 'Вы уверены, что хотите удалить элемент из списка?', 'Внимание', MB_ICONINFORMATION or MB_YESNO) <> ID_YES then
    Exit;

  if SmartHandler.ApplicationsUnit.DeleteRollKey then
  begin
    ShowMessage('Элемент успешно удалён из реестра.');
  end;
end;

procedure TFormMain.ActionDeleteARExecute(Sender: TObject);
begin
  SmartHandler.AutorunsUnit.DeleteSel;
end;

procedure TFormMain.ActionDeleteExecute(Sender: TObject);
begin
 //
end;

procedure TFormMain.UpdateInfo;
begin
  if AvailableInfo then
    CreateInfo;
end;

procedure TFormMain.CreateInfo;
begin
  ValueListEditorInfo.Strings.BeginUpdate;
  ValueListEditorInfo.Strings.Clear;
  try
    begin
      AddToValueEdit(ValueListEditorInfo, 'Операционная система', DelFLSpace(Info.WinVersion), '');
      AddToValueEdit(ValueListEditorInfo, 'Оперативная память', DelFLSpace(Info.MemoryInfo), '');
      AddToValueEdit(ValueListEditorInfo, 'Системный диск', DelFLSpace(Info.SysDriveInfo), '');
      AddToValueEdit(ValueListEditorInfo, 'Процессор', DelFLDSpace(Info.CPU), '');
      AddToValueEdit(ValueListEditorInfo, 'Имя компьютера', DelFLSpace(Info.MachineName), '');
      AddToValueEdit(ValueListEditorInfo, 'Рабочая группа', DelFLSpace(Info.LanGroup), '');
      AddToValueEdit(ValueListEditorInfo, 'Активация Windows', DelFLSpace(Info.WinActivateStatus), '');
      AddToValueEdit(ValueListEditorInfo, 'Центр обновлений', DelFLSpace(Info.WinUpdate), '');
      AddToValueEdit(ValueListEditorInfo, 'Время работы', Info.WindowsTimeWork, '');
      AvailableInfo := True;
    end;
  except
    AvailableInfo := False;
  end;
  ValueListEditorInfo.Strings.EndUpdate;
end;

procedure TFormMain.OpenTabItems;
begin
  case Info.Version of
    winXP:
      OpenTabNamed(TabSheetItems);
  else
    OpenTabNamed(TabSheetItems);
  end;
end;

procedure TFormMain.OpenTabNamed(TabSheet: TTabSheet);
begin
  PageControlMain.ActivePage := TabSheet;
end;

procedure TFormMain.PageControlMainChange(Sender: TObject);
begin                       {
 if PageControlMain.ActivePage =  TabSheetEvents then SmartHandler.EventsUnit.SetStateToPB;
 if PageControlMain.ActivePage =  TabSheetWinApps then SmartHandler.ApplicationsUnit.SetStateToPB;
 if PageControlMain.ActivePage =  TabSheetEvents then SmartHandler.EventsUnit.SetStateToPB;
 if PageControlMain.ActivePage =  TabSheetEvents then SmartHandler.EventsUnit.SetStateToPB;
 if PageControlMain.ActivePage =  TabSheetEvents then SmartHandler.EventsUnit.SetStateToPB;
 if PageControlMain.ActivePage =  TabSheetEvents then SmartHandler.EventsUnit.SetStateToPB; }
end;

procedure TFormMain.Quit;
begin
  LogList := nil;
  with FormMain do
  begin
    if FlagLoadNote then
      NoteUnload;
    TimerCurElem.Enabled := False;
    TimerTick.Enabled := False;
    TimerUpdater.Enabled := False;
    SmartHandler.GlobalStop;
    SaveSettings;
  end;
  Application.Terminate;
end;

procedure TFormMain.ActionEndStopExecute(Sender: TObject);
begin
  Application.ProcessMessages;
  SmartHandler.Stop := False;
end;

procedure TFormMain.ActionEventsExecute(Sender: TObject);
var
  ES: TFWEventSources;
  ET: TFWEventLogRecordType;
  DD: Word;
  IntD: Integer;
begin
  case ComboBoxEventsList.ItemIndex of
    0:
      ES := esApplication;
    1:
      ES := esSecurity;
    2:
      ES := esSystem;
  else
    begin
      FillComboBoxES;
      ES := esSystem;
    end;
  end;
  SmartHandler.EventsUnit.EventSources := ES;

  case ComboBoxEventType.ItemIndex of
    0:
      ET := rtSuccess;
    1:
      ET := rtError;
    2:
      ET := rtWarning;
    3:
      ET := rtInformation;
    4:
      ET := rtAuditSuccess;
    5:
      ET := rtAuditFailed;
  else
    begin
      FillComboBoxET;
      ET := rtError;
    end;
  end;
  SmartHandler.EventsUnit.EventType := ET;

  case ComboBoxEventsDate.ItemIndex of
    0:
      DD := 1;
    1:
      DD := 7;
    2:
      DD := 14;
    3:
      DD := 30;
    4:
      DD := 0;
  else
    if TryStrToInt(ComboBoxEventsDate.Text, IntD) then
      DD := IntD
    else
    begin
      FillComboBoxED;
      DD := 14;
    end;
  end;
  SmartHandler.EventsUnit.DateData := DD;

  if PageControlMain.ActivePage <> TabSheetEvents then
  begin
    OpenTabNamed(TabSheetEvents);
    Application.ProcessMessages;
    if SmartHandler.EventsUnit.State <> gsFinished then
      SmartHandler.EventsUnit.Get;
  end
  else
  begin
    Application.ProcessMessages;
    SmartHandler.EventsUnit.Get;
  end;
end;

procedure TFormMain.ActionFindSrvFileExecute(Sender: TObject);
begin
  SmartHandler.ServicesUnit.OpenFolderBinSelSrv;
end;

procedure TFormMain.ActionFirewallRulesExecute(Sender: TObject);
begin
  if PageControlMain.ActivePage <> TabSheetFireWall then
  begin
    PageControlMain.ActivePage := TabSheetFireWall;
    Application.ProcessMessages;
    if SmartHandler.FirewallUnit.State <> gsFinished then
    begin
      SmartHandler.FirewallUnit.Get(FWModeRules);
    end;
  end
  else
  begin
    Application.ProcessMessages;
    SmartHandler.FirewallUnit.Get(FWModeRules);
  end;
end;

procedure TFormMain.ActionFWInfoExecute(Sender: TObject);
begin
  if PageControlMain.ActivePage <> TabSheetFireWall then
  begin
    PageControlMain.ActivePage := TabSheetFireWall;
    Application.ProcessMessages;
    if SmartHandler.FirewallUnit.State <> gsFinished then
    begin
      SmartHandler.FirewallUnit.Get(FWModeInfo);
    end;
  end
  else
  begin
    Application.ProcessMessages;
    SmartHandler.FirewallUnit.Get(FWModeInfo);
  end;
end;

procedure TFormMain.ActionFWServExecute(Sender: TObject);
begin
  if PageControlMain.ActivePage <> TabSheetFireWall then
  begin
    PageControlMain.ActivePage := TabSheetFireWall;
    Application.ProcessMessages;
    if SmartHandler.FirewallUnit.State <> gsFinished then
    begin
      SmartHandler.FirewallUnit.Get(FWModeServices);
    end;
  end
  else
  begin
    Application.ProcessMessages;
    SmartHandler.FirewallUnit.Get(FWModeServices);
  end;
end;

procedure TFormMain.ActionHDDExecute(Sender: TObject);
begin
  if PageControlMain.ActivePage <> TabSheetHDD then
  begin
    PageControlMain.ActivePage := TabSheetHDD;
    Application.ProcessMessages;
    if SmartHandler.HDDUnit.State <> gsFinished then
    begin
      SmartHandler.HDDUnit.Get(SmartHandler.HDDUnit.GetDriverNum(ComboBoxStorageList.ItemIndex));
    end;
  end
  else
  begin
    Application.ProcessMessages;
    SmartHandler.HDDUnit.Get(SmartHandler.HDDUnit.GetDriverNum(ComboBoxStorageList.ItemIndex));
  end;
end;

procedure TFormMain.ActionHelperExecute(Sender: TObject);
begin
  PageControlMain.ActivePage := TabSheetHelper;
end;

procedure TFormMain.ActionInfoExecute(Sender: TObject);
begin
  PageControlMain.ActivePage := TabSheetInfo;
end;

procedure TFormMain.ActionItemsExecute(Sender: TObject);
begin
  OpenTabItems;
end;

procedure LoadLog;
var
  FS: TFileStream;
begin
  try
    FS := TFileStream.Create(LogFileName, fmShareDenyNone);
  //FormMain.MemoLog.Lines.LoadFromStream(FS);
  //SmartHandler.State:=gsFinished;
  finally
    FS.Free;
  //SmartHandler.State:=gsError;
  end;
  EndThread(0);
end;

procedure TFormMain.ActionLoadLogExecute(Sender: TObject);
var
  ID: Cardinal;
begin
  SmartHandler.AddToProcessing;
  Application.ProcessMessages;
  BeginThread(nil, 0, @LoadLog, nil, 0, ID);
end;

procedure TFormMain.ActionLogViewExecute(Sender: TObject);
begin
 //PageControlMain.ActivePage:=TabSheetLog;
end;

procedure TFormMain.ActionMonitorStartExecute(Sender: TObject);
begin
  SmartHandler.ProcessesUnit.EnableMonitor;
end;

procedure TFormMain.ActionMonitorStopExecute(Sender: TObject);
begin
  SmartHandler.ProcessesUnit.DisableMonitor;
end;

procedure TFormMain.ActionMSConfigExecute(Sender: TObject);
begin
  RunCommand('msconfig', '');
end;

procedure TFormMain.ActionNoteLoadExecute(Sender: TObject);
begin
  if MessageBox(Handle, 'Загрузить список заметок?', 'Внимание', MB_YESNO or MB_ICONQUESTION) <> ID_YES then
    Exit;
  if FileExists(CurrentDir + DebugFileName) then
    MemoDebug.Lines.LoadFromFile(CurrentDir + DebugFileName)
  else
    FileClose(FileCreate(CurrentDir + DebugFileName));
  FlagLoadNote := True;
end;

procedure TFormMain.ActionNoteUnloadExecute(Sender: TObject);
begin
  if MessageBox(Handle, 'Выгрузить список заметок?', 'Внимание', MB_YESNO or MB_ICONQUESTION) <> ID_YES then
    Exit;
  NoteUnload;
end;

procedure TFormMain.ActionOnlyMainWndExecute(Sender: TObject);
begin
  SmartHandler.ProcessesUnit.OnlyMainWnd := not SmartHandler.ProcessesUnit.OnlyMainWnd;
  ActionOnlyMainWnd.Checked := SmartHandler.ProcessesUnit.OnlyMainWnd;
  SmartHandler.ProcessesUnit.Get;
end;

procedure TFormMain.ActionOnlyVisableWndExecute(Sender: TObject);
begin
  SmartHandler.ProcessesUnit.OnlyVisableWnd := not SmartHandler.ProcessesUnit.OnlyVisableWnd;
  ActionOnlyVisableWnd.Checked := SmartHandler.ProcessesUnit.OnlyVisableWnd;
  SmartHandler.ProcessesUnit.Get;
end;

procedure TFormMain.ActionOpenAppFolderExecute(Sender: TObject);
begin
  SmartHandler.ApplicationsUnit.OpenInstalledPath;
end;

procedure TFormMain.ActionOpenARExecute(Sender: TObject);
begin
  SmartHandler.AutorunsUnit.OpenFolderSelAR;
end;

procedure TFormMain.ActionOpenCleanerElementExecute(Sender: TObject);
begin
  SmartHandler.CleanerUnit.OpenSelected;
end;

procedure TFormMain.ActionOpenFileUnistExecute(Sender: TObject);
begin
  SmartHandler.ApplicationsUnit.OpenUninstalledFile;
end;

procedure TFormMain.ActionOpenHostsFileExecute(Sender: TObject);
begin
  SmartHandler.OpenHostsFile;
end;

procedure TFormMain.ActionOpenMD5MakerExecute(Sender: TObject);
begin
  RunCommand(CurrentDir + 'Data\MD5Maker.exe', '');
end;

procedure TFormMain.ActionOpenPathInstExecute(Sender: TObject);
begin
  SmartHandler.ApplicationsUnit.OpenInstalledPath;
end;

procedure TFormMain.ActionOpenProcExecute(Sender: TObject);
begin
  SmartHandler.ProcessesUnit.ShowInfo;
end;

procedure TFormMain.ActionOpenProcFromARExecute(Sender: TObject);
begin
  SmartHandler.AutorunsUnit.ShowARProc(ListViewProc);
  OpenTabNamed(TabSheetProc);
  ListViewProcClick(nil);
end;

procedure TFormMain.ActionOpenSrvDllExecute(Sender: TObject);
begin
  SmartHandler.ServicesUnit.OpenFolderDllSelSrv;
end;

procedure TFormMain.ActionPortAdrExecute(Sender: TObject);
begin
  (Sender as TsSpeedButton).Enabled := False;
  SetRIPInfo(ListViewPorts);
  (Sender as TsSpeedButton).Enabled := True;
end;

procedure TFormMain.ActionPortsExecute(Sender: TObject);
begin
  if PageControlMain.ActivePage <> TabSheetPorts then
  begin
    PageControlMain.ActivePage := TabSheetPorts;
    Application.ProcessMessages;
    if SmartHandler.PortsUnit.State <> gsFinished then
      SmartHandler.PortsUnit.Get;
  end
  else
    SmartHandler.PortsUnit.Get;
end;

procedure TFormMain.ActionProcessesExecute(Sender: TObject);
begin
  if PageControlMain.ActivePage <> TabSheetProc then
  begin
    PageControlMain.ActivePage := TabSheetProc;
    Application.ProcessMessages;
    if SmartHandler.ProcessesUnit.State <> gsFinished then
      SmartHandler.ProcessesUnit.Get;
  end
  else
    SmartHandler.ProcessesUnit.Get;
end;

procedure TFormMain.ActionProcPropExecute(Sender: TObject);
begin
  SmartHandler.ProcessesUnit.ShowProp;
end;

procedure TFormMain.ActionProcStopSelExecute(Sender: TObject);
begin
  SmartHandler.ProcessesUnit.DeleteChecked;
end;

procedure TFormMain.ActionPropAppsExecute(Sender: TObject);
begin
  CreateProp(SmartHandler.ApplicationsUnit);
end;

procedure TFormMain.ActionPropAutorunsExecute(Sender: TObject);
begin
  CreateProp(SmartHandler.AutorunsUnit);
end;

procedure TFormMain.ActionPropEventsExecute(Sender: TObject);
begin
  CreateProp(SmartHandler.EventsUnit);
end;

procedure TFormMain.ActionPropTasksExecute(Sender: TObject);
begin
  CreateProp(SmartHandler.TasksUnit);
end;

procedure TFormMain.ActionQuitExecute(Sender: TObject);
begin
  Close;
end;

procedure TFormMain.ActionRegeditExecute(Sender: TObject);
begin
  RunCommand('regedit', '');
end;

procedure TFormMain.ActionRegeditorExecute(Sender: TObject);
begin
  if PageControlMain.ActivePage <> TabSheetRegedit then
  begin
    PageControlMain.ActivePage := TabSheetRegedit;
    Application.ProcessMessages;
    if SmartHandler.RegeditUnit.State <> gsFinished then
      SmartHandler.RegeditUnit.Get;
  end
  else
  begin
    Application.ProcessMessages;
    SmartHandler.RegeditUnit.Get;
  end;
end;

procedure TFormMain.ActionRegLoadExecute(Sender: TObject);
var
  OP: TOpenDialog;
begin
  OP := TOpenDialog.Create(FormMain);
  OP.Title := 'Выберите файл реестра';
  OP.Filter := 'Все файлы|*.*';
  OP.Options := [ofForceShowHidden, ofEnableSizing];
  if OP.Execute(Handle) then
    if RegDatLoad(OP.FileName) then
      ShowMessage('Файл загружен.');
  OP.Free;
end;

procedure TFormMain.ActionRegUnloadExecute(Sender: TObject);
begin
  if RegDatUnload then
    ShowMessage('Куст успешно выгружен.');
end;

procedure TFormMain.ActionRestartInfoTimerExecute(Sender: TObject);
begin
  try
    TimerCurElemTimer(nil);
    TimerCurElem.Enabled := True;
  except
    begin
      TimerCurElem.Enabled := False;
      Log(['Ошибка в мониторе "CurElem"']);
    end;
  end;
  try
    TimerTickTimer(nil);
    TimerTick.Enabled := True;
  except
    begin
      TimerTick.Enabled := False;
      Log(['Ошибка в мониторе "Tick"']);
    end;
  end;
end;

procedure TFormMain.ActionScheduleExecute(Sender: TObject);
begin
  if PageControlMain.ActivePage <> TabSheetSheduler then
  begin
    PageControlMain.ActivePage := TabSheetSheduler;
    Application.ProcessMessages;
    if SmartHandler.TasksUnit.State <> gsFinished then
      SmartHandler.TasksUnit.Get(FormMain.ActionAllTasks.Checked);
  end
  else
  begin
    Application.ProcessMessages;
    SmartHandler.TasksUnit.Get(FormMain.ActionAllTasks.Checked);
  end;
end;

procedure TFormMain.ActionSendToMMExecute(Sender: TObject);
begin
  if ListViewDelete.Selected = nil then
    Exit;
  RunCommand(CurrentDir + 'Data\SDIAPP.exe', ListViewDelete.Selected.Caption);
end;

procedure TFormMain.ActionSENextExecute(Sender: TObject);
begin
  if not Assigned(ShellExplorer) then
    Exit;
  ShellExplorer.Back;
end;

procedure TFormMain.ActionSEPrevExecute(Sender: TObject);
begin
  if not Assigned(ShellExplorer) then
    Exit;
  ShellExplorer.Back;
end;

procedure TFormMain.ActionSetHDDAttrExecute(Sender: TObject);
begin
  ActionSetHDDAttr.Checked := not ActionSetHDDAttr.Checked;
  SmartHandler.HDDUnit.GetAttrNames := ActionSetHDDAttr.Checked;
end;

procedure TFormMain.ActionSrvDeleteExecute(Sender: TObject);
begin
  SmartHandler.ServicesUnit.DeleteSrv(SmartHandler.ServicesUnit.SelectedItem);
end;

procedure TFormMain.ActionSrvOpenExecute(Sender: TObject);
begin
  SmartHandler.ServicesUnit.ShowSelected;
end;

procedure TFormMain.ActionShellExplorerExecute(Sender: TObject);
begin
  if PageControlMain.ActivePage <> TabSheetShellExplorer then
  begin
    PageControlMain.ActivePage := TabSheetShellExplorer;
    Application.ProcessMessages;
   //if SmartHandler.TasksUnit.State <> gsFinished then SmartHandler.TasksUnit.Get(FormMain.ActionAllTasks.Checked);
  end
  else
  begin
    Application.ProcessMessages;
   //SmartHandler.TasksUnit.Get(FormMain.ActionAllTasks.Checked);
  end;
end;

procedure TFormMain.ActionShowAppInfoExecute(Sender: TObject);
begin
  ShowAppInfo(SmartHandler.ApplicationsUnit);
end;

procedure TFormMain.ActionShowSrvFromProcExecute(Sender: TObject);
var
  PID: Integer;
begin
  if ListViewProc.Selected = nil then
    Exit;
  if not TryStrToInt(ListViewProc.Selected.SubItems[0], PID) then
    Exit;
  OpenTabNamed(TabSheetServices);
  Application.ProcessMessages;
  if SmartHandler.ServicesUnit.State <> gsFinished then
    SmartHandler.ServicesUnit.Get;
  SmartHandler.ServicesUnit.Select(PID);
end;

procedure TFormMain.ActionSrvOpenPortsExecute(Sender: TObject);
var
  PID: Integer;
begin
  if ListViewSrvs.Selected = nil then
    Exit;
  if not TryStrToInt(ListViewSrvs.Selected.SubItems[0], PID) then
    Exit;
  if SmartHandler.PortsUnit.State <> gsFinished then
    ActionPorts.Execute;
  SelectPortsByPID(ListViewPorts, PID);
  OpenTabNamed(TabSheetPorts);
end;

procedure TFormMain.ActionSrvOpenProcExecute(Sender: TObject);
begin
  if ListViewSrvs.Selected = nil then
    Exit;
  if ListViewSrvs.Selected.Data = nil then
    Exit;
  SelectProcByPID(ListViewProc, TServiceObj(ListViewSrvs.Selected.Data^).PID);
  OpenTabNamed(TabSheetProc);
  ListViewProcClick(nil);
end;

procedure TFormMain.ActionSrvsExecute(Sender: TObject);
begin
  if PageControlMain.ActivePage <> TabSheetServices then
  begin
    PageControlMain.ActivePage := TabSheetServices;
    if SmartHandler.ServicesUnit.State <> gsFinished then
      SmartHandler.ServicesUnit.Get;
  end
  else
  begin
    Application.ProcessMessages;
    SmartHandler.ServicesUnit.Get;
  end;
end;

procedure TFormMain.ActionSrvStartExecute(Sender: TObject);
begin
 //Запустить службу
  SmartHandler.ServicesUnit.StartSrv(SmartHandler.ServicesUnit.SelectedItem);
end;

procedure TFormMain.ActionSrvSTAutoDelayedExecute(Sender: TObject);
begin
  SmartHandler.ServicesUnit.SrvSTAutoDelayed;
end;

procedure TFormMain.ActionSrvSTAutoExecute(Sender: TObject);
begin
  SmartHandler.ServicesUnit.SrvSTAuto;
end;

procedure TFormMain.ActionSrvSTBootExecute(Sender: TObject);
begin
  SmartHandler.ServicesUnit.SrvSTBoot;
end;

procedure TFormMain.ActionSrvSTDemandExecute(Sender: TObject);
begin
  SmartHandler.ServicesUnit.SrvSTDemand;
end;

procedure TFormMain.ActionSrvSTDisableExecute(Sender: TObject);
begin
  SmartHandler.ServicesUnit.SrvSTDisable;
end;

procedure TFormMain.ActionSrvStopExecute(Sender: TObject);
begin
 //Остановить службу
  SmartHandler.ServicesUnit.StopSrv(SmartHandler.ServicesUnit.SelectedItem);
end;

procedure TFormMain.ActionSrvSTSysExecute(Sender: TObject);
begin
  SmartHandler.ServicesUnit.SrvSTSys;
end;

procedure TFormMain.ActionStopExecute(Sender: TObject);
begin
  SmartHandler.GlobalStop;
end;

procedure TFormMain.ActionSwitchFWExecute(Sender: TObject);
begin
  SmartHandler.FirewallUnit.Enabled := not SmartHandler.FirewallUnit.Enabled;
end;

procedure TFormMain.ActionTweaksExecute(Sender: TObject);
begin
  if PageControlMain.ActivePage <> TabSheetTweaks then
  begin
    PageControlMain.ActivePage := TabSheetTweaks;
    if SmartHandler.TweaksState = gsIsNotGetted then
      SmartHandler.GetTweaks(ListViewTweaks);
  end
  else
  begin
    Application.ProcessMessages;
    SmartHandler.GetTweaks(ListViewTweaks);
  end;
end;

procedure TFormMain.ActionUpdateExecute(Sender: TObject);
begin
  if PageControlMain.ActivePage = TabSheetInfo then
    UpdateInfo
  else if PageControlMain.ActivePage = TabSheetWinApps then
    ActionWinApps.Execute
  else if PageControlMain.ActivePage = TabSheetAutoruns then
    ActionAutorun.Execute
  else if PageControlMain.ActivePage = TabSheetEvents then
    ActionEvents.Execute
  else if PageControlMain.ActivePage = TabSheetExeing then
    ActionUtils.Execute
  else if PageControlMain.ActivePage = TabSheetSheduler then
    ActionSchedule.Execute
  else if PageControlMain.ActivePage = TabSheetHDD then
    ActionHDD.Execute
  else
// if PageControlMain.ActivePage = TabSheetLog then Unload else
if PageControlMain.ActivePage = TabSheetTweaks then
    ActionTweaks.Execute;
end;

procedure TFormMain.ActionUtilsExecute(Sender: TObject);
begin
  if PageControlMain.ActivePage <> TabSheetExeing then
  begin
    PageControlMain.ActivePage := TabSheetExeing;
    if SmartHandler.ExecuteUnit.State <> gsFinished then
      SmartHandler.ExecuteUnit.Get;
  end
  else
  begin
    SmartHandler.ExecuteUnit.Get;
  end;
end;

procedure TFormMain.ActionWillGetBackupEventsExecute(Sender: TObject);
begin
  if FileOpenDialog.Execute then
  begin
    SmartHandler.EventsUnit.BackupFile := FileOpenDialog.FileName;
    ActionWillGetBackupEvents.Checked := True;
    ActionWillGetSysEvents.Checked := False;
  end
  else
  begin
    ActionWillGetSysEvents.Checked := True;
    ActionWillGetBackupEvents.Checked := False;
  end;
end;

procedure TFormMain.ActionWillGetSysEventsExecute(Sender: TObject);
begin
  SmartHandler.EventsUnit.BackupFile := '';
  ActionWillGetSysEvents.Checked := True;
  ActionWillGetBackupEvents.Checked := False;
end;

procedure TFormMain.ActionWinAppsExecute(Sender: TObject);
begin
  if PageControlMain.ActivePage <> TabSheetWinApps then
  begin
    PageControlMain.ActivePage := TabSheetWinApps;
    if SmartHandler.ApplicationsUnit.State <> gsFinished then
      SmartHandler.ApplicationsUnit.Get;
  end
  else
  begin
    SmartHandler.ApplicationsUnit.Get;
  end;
end;

procedure TFormMain.ActionWOW64ModeExecute(Sender: TObject);
begin
  ActionWOW64Mode.Checked := SmartHandler.WOWSwitch;
end;

procedure TFormMain.ApplicationEvents1ShortCut(var Msg: TWMKey; var Handled: Boolean);
begin
  case Msg.CharCode of
    VK_ESCAPE:
      begin
        TForm(FindControl(Application.ActiveFormHandle)).Close;
        Handled := True;
      end;
  end;
end;

procedure TFormMain.ButtonedEditParamLeftButtonClick(Sender: TObject);
begin
  ButtonedEditParam.Text := Clipboard.AsText;
end;

procedure TFormMain.ButtonedEditRunKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    ButtonedEditRunRightButtonClick(nil);
  end;
end;

procedure TFormMain.ButtonedEditRunLeftButtonClick(Sender: TObject);
begin
  ButtonedEditRun.Text := Clipboard.AsText;
end;

procedure TFormMain.ButtonedEditRunRightButtonClick(Sender: TObject);
begin
  RunCommand(ButtonedEditRun.Text, ButtonedEditParam.Text);
end;

procedure TFormMain.OpenMenuTab(Tab: TTabSheet);

  procedure SetMenuButtonActive(Button: TButtonFlat; Value: Boolean);
  begin
    case Value of
      True:
        Button.ColorNormal := $00F7F6F5;
      False:
        Button.ColorNormal := clWhite;
    end;
  end;

begin
  PageControlMenu.ActivePage := Tab;
  SetMenuButtonActive(ButtonFlatMenuStart, PageControlMenu.ActivePage = TabSheetMenuStart);
  SetMenuButtonActive(ButtonFlatMenuModules, PageControlMenu.ActivePage = TabSheetMenuModules);
  SetMenuButtonActive(ButtonFlatMenuHelp, PageControlMenu.ActivePage = TabSheetMenuHelp);
  SetMenuButtonActive(ButtonFlatMenuNav, PageControlMenu.ActivePage = TabSheetMenuNavigation);
  SetMenuButtonActive(ButtonFlatMenuMon, PageControlMenu.ActivePage = TabSheetMenuMonitor);
  SetMenuButtonActive(ButtonFlatMenuFS, PageControlMenu.ActivePage = TabSheetMenuFS);
  SetMenuButtonActive(ButtonFlatMenuTools, PageControlMenu.ActivePage = TabSheetMenuTools);
  if Tab = TabSheetMenuFS then
    OpenResult;
end;

procedure TFormMain.ButtonFlatMenuFSClick(Sender: TObject);
begin
  OpenMenuTab(TabSheetMenuFS);
end;

procedure TFormMain.ButtonFlatMenuHelpClick(Sender: TObject);
begin
  OpenMenuTab(TabSheetMenuHelp);
end;

procedure TFormMain.ButtonFlatMenuModulesClick(Sender: TObject);
begin
  OpenMenuTab(TabSheetMenuModules);
end;

procedure TFormMain.ButtonFlatMenuMonClick(Sender: TObject);
begin
  OpenMenuTab(TabSheetMenuMonitor);
end;

procedure TFormMain.ButtonFlatMenuNavClick(Sender: TObject);
begin
  OpenMenuTab(TabSheetMenuNavigation);
end;

procedure TFormMain.ButtonFlatMenuStartClick(Sender: TObject);
begin
  OpenMenuTab(TabSheetMenuStart);
end;

procedure TFormMain.ButtonFlatMenuToolsClick(Sender: TObject);
begin
  OpenMenuTab(TabSheetMenuTools);
end;

procedure TFormMain.ButtonIgnoreDelAppClick(Sender: TObject);
begin
  if MessageBox(Application.Handle, PChar(LangText(100, 'Отменить ожидание окончания удаления приложения?')), PChar(LangText(41, 'Внимание')), MB_ICONINFORMATION or MB_YESNO) = ID_YES then
    ProcessMonitor.Stop
  else
    Exit;
end;

procedure TFormMain.FillComboBoxES;
begin
  ComboBoxEventsList.Items.BeginUpdate;
  ComboBoxEventsList.Items.Clear;
  ComboBoxEventsList.Items.Add('Приложение');
  ComboBoxEventsList.Items.Add('Безопасность');
  ComboBoxEventsList.Items.Add('Система');
  ComboBoxEventsList.Items.EndUpdate;
  ComboBoxEventsList.ItemIndex := 2;
end;

procedure TFormMain.FillComboBoxET;
begin
  ComboBoxEventType.Items.BeginUpdate;
  ComboBoxEventType.Items.Clear;
  ComboBoxEventType.Items.Add('Сведения');
  ComboBoxEventType.Items.Add('Ошибки');
  ComboBoxEventType.Items.Add('Предупреждения');
  ComboBoxEventType.Items.Add('Уведомления');
  ComboBoxEventType.Items.Add('Аудит успеха');
  ComboBoxEventType.Items.Add('Аудит отказа');
  ComboBoxEventType.Items.EndUpdate;
  ComboBoxEventType.ItemIndex := 1;
end;

procedure TFormMain.FillComboBoxED;
begin
  ComboBoxEventsDate.Items.BeginUpdate;
  ComboBoxEventsDate.Items.Clear;
  ComboBoxEventsDate.Items.Add('Сутки');
  ComboBoxEventsDate.Items.Add('Неделя');
  ComboBoxEventsDate.Items.Add('Две недели');
  ComboBoxEventsDate.Items.Add('Месяц');
  ComboBoxEventsDate.Items.Add('За всё время');
  ComboBoxEventsDate.Items.EndUpdate;
  ComboBoxEventsDate.ItemIndex := 2;
end;

procedure TFormMain.CreateFaceItems;
begin
  ListViewItems.Clear;
  ListViewItems.Groups.Clear;
 //Мониторинг
  SetActionDataLI(ListViewItems.Items.Add, @ActionProcesses, GetGroup(ListViewItems, 'Мониторинг', True));
  SetActionDataLI(ListViewItems.Items.Add, @ActionSrvs, GetGroup(ListViewItems, 'Мониторинг', True));
  SetActionDataLI(ListViewItems.Items.Add, @ActionEvents, GetGroup(ListViewItems, 'Мониторинг', True));
  SetActionDataLI(ListViewItems.Items.Add, @ActionInfo, GetGroup(ListViewItems, 'Мониторинг', True));
  SetActionDataLI(ListViewItems.Items.Add, @ActionPorts, GetGroup(ListViewItems, 'Мониторинг', True));
  SetActionDataLI(ListViewItems.Items.Add, @ActionHDD, GetGroup(ListViewItems, 'Мониторинг', True));

  SetActionDataLI(ListViewItems.Items.Add, @ActionWinApps, GetGroup(ListViewItems, 'Обслуживание', True));
  SetActionDataLI(ListViewItems.Items.Add, @ActionAutorun, GetGroup(ListViewItems, 'Обслуживание', True));
  SetActionDataLI(ListViewItems.Items.Add, @ActionSchedule, GetGroup(ListViewItems, 'Обслуживание', True));
  SetActionDataLI(ListViewItems.Items.Add, @ActionTweaks, GetGroup(ListViewItems, 'Обслуживание', True));
  SetActionDataLI(ListViewItems.Items.Add, @ActionRegeditor, GetGroup(ListViewItems, 'Обслуживание', True));

  SetActionDataLI(ListViewItems.Items.Add, @ActionUtils, GetGroup(ListViewItems, 'Инструменты', True));
  SetActionDataLI(ListViewItems.Items.Add, @ActionLogView, GetGroup(ListViewItems, 'Инструменты', True));
  SetActionDataLI(ListViewItems.Items.Add, @ActionDebug, GetGroup(ListViewItems, 'Инструменты', True));
end;

procedure TFormMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := False;
  Quit;
end;

procedure TFormMain.FormCreate(Sender: TObject);
var
  BMP: TBitmap;
  i: Byte;
begin
  try
    ShellExplorer := TShellListView.Create(PanelShell);
    with ShellExplorer do
    begin
      Name := 'ShellExplorer';
      Parent := PanelShell;
      Left := 0;
      Top := 0;
      Width := 769;
      Align := alClient;
      Height := 473;
      Root := 'rfDesktop';
      Sorted := True;
      ReadOnly := False;
      HideSelection := False;
      TabOrder := 0;
      ViewStyle := vsReport;
      ObjectTypes := [otFolders, otNonFolders, otHidden];
      OnClick := OnSEClick;
    end;
  except
    begin
      ShellExplorer := nil;
      Log(['Не смог инициализировать проводник оболочки Windows.']);
    end;
  end;

  LPT := 0;
  LStep := GridSz;
  Sz := 3;

  BMP := TBitmap.Create;
  BMP.Width := ImageCPUGraph.Width;
  BMP.Height := ImageCPUGraph.Height;
  BMP.PixelFormat := pf24bit;
  BMP.Canvas.Brush.Color := clBlack;
  BMP.Canvas.Pen.Color := clLime;
  BMP.Canvas.FillRect(BMP.Canvas.ClipRect);
  ImageCPUGraph.Picture.Assign(BMP);
  BMP.Free;
  for i := 0 to PageControlMain.PageCount - 1 do
    PageControlMain.Pages[i].TabVisible := False;
  for i := 0 to ImageCPUGraph.Width div Sz do
    NewPointForCPU(0);
  Application.OnException := ExceptionHandler;
//LogList:=@MemoLog;
  LoadSettings;
  CreateInfo;
  FillComboBoxES;
  FillComboBoxET;
  FillComboBoxED;
  CreateFaceItems;
  OpenMenuTab(TabSheetMenuStart);
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  SmartHandler.Free;
end;

procedure TFormMain.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE:
      Close;
  end;
end;

procedure TFormMain.FormShow(Sender: TObject);
begin
  TimerTickTimer(nil);
 {$IFDEF DEBUG}
  Exit;
 {$ENDIF}
  if not WarningAboutInconsistency then
  begin
    WarningAboutInconsistency := True;
   //Если битность не совпадает...
    if Info.Bits <> AppBits then
    begin
      case MessageBox(Application.Handle, PChar(LangText(-1, 'Разрядность выполняемой версии приложения не соответствует разрядности вашей операционной системы.'#13#10'Запустить соответствующую версию?')), PChar(AppNameRu), MB_ICONWARNING or MB_YESNOCANCEL) of
        ID_YES:
          begin
            if FileExists(CurrentDir + App64) then
            begin
              ShellExecute(Application.Handle, 'open', PChar(CurrentDir + App64), '', '', SW_NORMAL);
              Halt;
            end
            else
            begin
              if MessageBox(Application.Handle, PChar('Файл 64-битного приложения не найден.'#13#10'Выключить перенаправление WOW64?'), PChar(AppNameRu), MB_ICONWARNING or MB_YESNO) = ID_YES then
                ActionWOW64Mode.Execute;
            end;
          end;
        ID_NO:
          if MessageBox(Application.Handle, PChar('Выключить перенаправление WOW64?'), PChar(AppNameRu), MB_ICONWARNING or MB_YESNO) = ID_YES then
            ActionWOW64Mode.Execute;
        ID_CANCEL:
          Halt;
      end;
    end;
  end;
  if not WarningAboutTrustlevel then
  begin
    WarningAboutTrustlevel := True;
    if not IsProgAdmin then
      case MessageBox(Application.Handle, PChar(LangText(-1, 'У программы нет прав администратора. Это повлияет на точность и возможности программы.'#13#10'Перезапустить программу от имени администратора?')), PChar(AppNameRu), MB_ICONWARNING or MB_YESNOCANCEL) of
        ID_YES:
          begin
            if True then
            begin
              ShellExecute(Application.Handle, 'open', PChar(CurrentDir + '\UAC.exe'), PChar('"' + ParamStr(0) + '"'), '', SW_NORMAL);
              Quit;
              Close;
            end;
          end;
        ID_CANCEL:
          Quit;
      end;
  end;
 //TimerTick.Enabled:=True;
 //TimerCurElem.Enabled:=True;
end;

procedure TFormMain.TimerCurElemTimer(Sender: TObject);
begin
  PanelAwating.Visible := ProcessMonitor.Executing;
 //CheckTabsPos;
end;

procedure TFormMain.TimerTickTimer(Sender: TObject);
var
  Ico: TIcon;
  lpMemoryStatus: TMemoryStatus;
  ID, Sz: Integer;
  DSI: TDriveSpaceInfoType;
  CPU: Byte;
begin
  Ico := TIcon.Create;

 //Информация об ОЗУ
  try
    lpMemoryStatus.dwLength := SizeOf(lpMemoryStatus);
    GlobalMemoryStatus(lpMemoryStatus);
    ID := Round(lpMemoryStatus.dwMemoryLoad / (100 / 16));
    if ID < 0 then
      ID := 0
    else if ID > 15 then
      ID := 15;
    PanelRAM.Caption := Format('ОЗУ %d%%', [lpMemoryStatus.dwMemoryLoad]);
    ImageListGuage.GetIcon(ID, Ico);
    ImageMem.Hint := Format('Используется %d%%'#13#10'Всего %d МБ'#13#10'Доступно %d МБ', [lpMemoryStatus.dwMemoryLoad, lpMemoryStatus.dwTotalPhys div Sqr(1024), lpMemoryStatus.dwAvailPhys div Sqr(1024)]);
    ImageMem.Picture.Assign(Ico);
  except
    begin
      TimerTick.Enabled := False;
      Log(['Приостановлен таймер наблюдения за активностью системы из-за ошибки при получении инф. об ОЗУ']);
    end;
  end;

 //Информация о системном диске
  try
    DSI := GetDriveSpaceInfo(C[1] + ':');
    Sz := DSI.TotalSize div (1024 * 1024);
    if Sz = 0 then
      Sz := 1;
    ID := Round((Sz - DSI.FreeSize div (1024 * 1024)) * (100 / Sz));
    PanelHDD.Caption := Format(C[1] + ':\ %d%%', [ID]);
    ImageDrvC.Hint := Format('Используется %d%%'#13#10'Всего ~%d ГБ'#13#10'Свободно ~%d ГБ', [ID, Sz div 1024, DSI.FreeSize div (Sqr(1024) * 1024)]);
    ID := Round(ID / (100 / 16));
    if ID < 0 then
      ID := 0
    else if ID > 15 then
      ID := 15;
    ImageListGuage.GetIcon(ID, Ico);
    ImageDrvC.Picture.Assign(Ico);
  except
    begin
      TimerTick.Enabled := False;
      Log(['Приостановлен таймер наблюдения за активностью системы из-за ошибки при получении инф. о системном диске']);
    end;
  end;

 //Информация о загрузке ЦП
  try
    CPU := Round(CPUUsage);
    NewPointForCPU(CPU);
    PanelCPU.Caption := Format('ЦП %d%%', [CPU]);
    ImageCPU.Hint := Format('Загруженность %d%%', [CPU]);
    ID := Round(CPU / (100 / 16));
    if ID < 0 then
      ID := 0
    else if ID > 15 then
      ID := 15;
    ImageListGuage.GetIcon(ID, Ico);
    ImageCPU.Picture.Assign(Ico);
  except
    begin
      TimerTick.Enabled := False;
      Log(['Приостановлен таймер наблюдения за активностью системы из-за ошибки при получении инф. о загрузке ЦП']);
    end;
  end;

 //Проверим список на наличие в нем уже удалённых программ
  try
    if Assigned(SmartHandler.ApplicationsUnit) then SmartHandler.ApplicationsUnit.CheckItems;
  except
    begin
      TimerTick.Enabled := False;
      Log(['Приостановлен таймер наблюдения за активностью системы из-за ошибки при обновлении списка Программ и компонентов']);
    end;
  end;

 //Общая информация
  try
    UpdateInfo;
  except
    begin
      TimerTick.Enabled := False;
      Log(['Приостановлен таймер наблюдения за активностью системы из-за ошибки при обновлении общей информации']);
    end;
  end;

 Ico.Free;
end;

function CtrlDown: Boolean;
var
  State: TKeyboardState;
begin
  GetKeyboardState(State);
  Result := ((State[vk_Control] and 128) <> 0);
end;

procedure TFormMain.TimerUpdaterTimer(Sender: TObject);
begin
  if CtrlDown then
    if SmartHandler.ProcessesUnit.MonitorIsEnable then
      SmartHandler.ProcessesUnit.SelectFormUnderMouse;
end;

procedure TFormMain.ListViewWinAppsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  MPos: TPoint;
begin
  if Button = mbRight then
  begin
    if ListViewWinApps.Selected <> nil then
    begin
      GetCursorPos(MPos);
      PopupMenuApps.Popup(MPos.X, MPos.Y);
    end;
  end;
end;

procedure TFormMain.ListViewWindowsClick(Sender: TObject);
var
  PID: Integer;
begin
  if ListViewWindows.Selected = nil then
    Exit;
  if not TryStrToInt(ListViewWindows.Selected.SubItems[0], PID) then
    Exit;

  SelectProcByPID(ListViewProc, PID);
  SelectProcByPID(TreeViewPID, PID);
end;

procedure TFormMain.LabelOffAllSchClick(Sender: TObject);
begin
  SmartHandler.TasksUnit.OffSelectedTasks;
end;

procedure TFormMain.Label21Click(Sender: TObject);
begin
  SmartHandler.AutorunsUnit.DeleteChecked;
end;

procedure TFormMain.LabelDelSelectClick(Sender: TObject);
begin
  SmartHandler.ApplicationsUnit.DeleteChecked;
end;

procedure TFormMain.LabelMouseEnter(Sender: TObject);
begin
  if not (Sender is TLabel) then
    Exit;
  if not (Sender as TLabel).Enabled then
    Exit;

  with (Sender as TLabel) do
  begin
    Font.Color := LinkColor;
    Font.Style := Font.Style + [fsUnderline];
    Cursor := crHandPoint;
  end;
end;

procedure TFormMain.LabelMouseLeave(Sender: TObject);
begin
  if not (Sender is TLabel) then
    Exit;
  with (Sender as TLabel) do
  begin
    Font.Color := UnLinkColor;
    Font.Style := (Font.Style - [fsUnderline]);
    Cursor := crDefault;
  end;
end;

procedure TFormMain.ListViewARDblClick(Sender: TObject);
begin
  SmartHandler.AutorunsUnit.ShowInfo;
end;

procedure TFormMain.ListViewARMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  MPos: TPoint;
begin
  if Button = mbRight then
  begin
    if ListViewAR.Selected <> nil then
    begin
      GetCursorPos(MPos);
      PopupMenuAutorun.Popup(MPos.X, MPos.Y);
    end;
  end;
end;

procedure TFormMain.ListViewContextDblClick(Sender: TObject);
begin
  SmartHandler.ContextMenuUnit.ShowInfo;
end;

procedure TFormMain.ListViewDeleteMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  MPos: TPoint;
begin
  if Button = mbRight then
  begin
    if not (Sender is TListView) then
      Exit;
    if (Sender as TListView).Selected <> nil then
    begin
      GetCursorPos(MPos);
      PopupMenuCleaner.Popup(MPos.X, MPos.Y);
    end;
  end;
end;

procedure TFormMain.ListViewEventsDblClick(Sender: TObject);
begin
  if ListViewEvents.Selected = nil then
    Exit;
  SmartHandler.EventsUnit.ShowSelectedEvent;
end;

procedure TFormMain.ListViewHDDDblClick(Sender: TObject);
var
  TRINT: Integer;
begin
  if ListViewHDD.Selected = nil then
    Exit;
  if not TryStrToInt(ListViewHDD.Selected.Caption, TRINT) then
    Exit;
  SmartHandler.HDDUnit.ShowAttribute(IntToStr(TRINT));
end;

procedure TFormMain.ListViewItemsDblClick(Sender: TObject);
begin
  if ListViewItems.Selected = nil then
    Exit;
  if ListViewItems.Selected.Data <> nil then
    TAction(ListViewItems.Selected.Data^).Execute;
end;

procedure TFormMain.ListViewParamDblClick(Sender: TObject);
begin
  if ListViewParam.Selected = nil then
    Exit;
  SmartHandler.CleanerUnit.ScanFiles := ActionAutoCheck.Checked;
  SmartHandler.CleanerUnit.GetByID(ListViewParam.Selected.Index);
end;

procedure TFormMain.ListViewPortsDblClick(Sender: TObject);
begin
  SmartHandler.PortsUnit.ShowInfo;
end;

procedure TFormMain.ListViewPortsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  MPos: TPoint;
begin
  if Button = mbRight then
  begin
    if ListViewPorts.Selected <> nil then
    begin
      GetCursorPos(MPos);
      PopupMenuPorts.Popup(MPos.X, MPos.Y);
    end;
  end;
end;

procedure TFormMain.ListViewProcClick(Sender: TObject);
var
  PID: Integer;
begin
  if ListViewProc.Selected = nil then
    Exit;
  if not TryStrToInt(ListViewProc.Selected.SubItems[siPID], PID) then
    Exit;
 //ShowMessage(GetCmdLineProc(OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, PID))+' '+IntToStr(PID));
  SelectProcByPID(TreeViewPID, PID);
  SelectWndByPID(ListViewWindows, PID);
end;

procedure TFormMain.ListViewProcKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_DELETE then
    SmartHandler.ProcessesUnit.DeleteSelected;
end;

procedure TFormMain.ListViewProcMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  MPos: TPoint;
  ShowPopup: Boolean;
begin
  ShowPopup := False;
  if Button = mbRight then
  begin
    if Sender is TListView then
    begin
      if (Sender as TListView).Selected <> nil then
        ShowPopup := True;
    end
    else if Sender is TTreeView then
    begin
      if (Sender as TTreeView).Selected <> nil then
        ShowPopup := True;
    end
  end;
  if ShowPopup then
  begin
    GetCursorPos(MPos);
    PopupMenuProc.Popup(MPos.X, MPos.Y);
  end;
end;

procedure TFormMain.ListViewSrvsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  MPos: TPoint;
begin
  if Button = mbRight then
  begin
    if ListViewSrvs.Selected <> nil then
    begin
      GetCursorPos(MPos);
      PopupMenuSrvs.Popup(MPos.X, MPos.Y);
    end;
  end;
end;

end.

