program CWM;

uses
  Vcl.Forms,
  Vcl.Themes,
  Vcl.Styles,
  FWEventLog in 'Imported\FWEventLog.pas',
  Main in 'Main.pas' {FormMain},
  ShellRecycle in 'Imported\ShellRecycle.pas',
  Utils in 'Utils.pas',
  Autoruns in 'Autoruns.pas',
  WinEvents in 'WinEvents.pas' {FormEventInfo},
  taskSchd in 'Imported\taskSchd.pas',
  taskSchdXP in 'Imported\taskSchdXP.pas',
  Ports in 'Ports.pas' {FormPorts},
  StructUnit in 'StructUnit.pas',
  Applications in 'Applications.pas' {FormApp},
  OSInfo in 'OSInfo.pas',
  Cleaner in 'Cleaner.pas',
  CleanerElements in 'CleanerElements.pas',
  HDD in 'HDD.pas' {FormHDD},
  Tasks in 'Tasks.pas' {FormTask},
  SMARTAPI in 'Imported\SMARTAPI.pas',
  WMI in 'Imported\WMI.pas',
  WinServices in 'WinServices.pas' {FormService},
  COCUtils in 'COCUtils.pas' {FormService},
  WbemScripting_TLB in 'Imported\WbemScripting_TLB.pas',
  Subs in 'Imported\Subs.pas',
  WinProcesses in 'WinProcesses.pas' {FormProcess},
  Executting in 'Executting.pas' {FormExec},
  CommonProp in 'CommonProp.pas' {FormUnitProperties},
  Firewall in 'Imported\Firewall.pas',
  WinFirewall in 'WinFirewall.pas' {FormFirewall},
  NativeAPI in 'Imported\NativeAPI.pas',
  MD5 in 'Imported\MD5.pas',
  SmartHND in 'SmartHND.pas' {FormSmartHND},
  Regeditor in 'Regeditor.pas' {FormReg},
  ContextMenu in 'ContextMenu.pas' {FormContextMenu},
  LoadingForm in 'LoadingForm.pas' {FormLoading},
  About in 'About.pas' {FormAbout};

{$R *.res}

begin
 FormLoading:=TFormLoading.Create(nil);
 FormLoading.Show;
 FormLoading.Step('Запуск');
 Application.ProcessMessages;
 FormLoading.Step('OSInfo.Init');
 OSInfo.Init;
 //
 FormLoading.Step('Application.Initialize');
 Application.Initialize;
 Application.MainFormOnTaskbar:=True;
 Application.Title:='Complex maintenance of workstation';
 //
 FormLoading.Step('FormMain.Initialize');
 Application.CreateForm(TFormMain, FormMain);
 FormLoading.Step('Forms Initialize');
  Application.CreateForm(TFormApp, FormApp);
  Application.CreateForm(TFormTask, FormTask);
  Application.CreateForm(TFormContextMenu, FormContextMenu);
  Application.CreateForm(TFormPorts, FormPorts);
  Application.CreateForm(TFormHDD, FormHDD);
  Application.CreateForm(TFormService, FormService);
  Application.CreateForm(TFormProcess, FormProcess);
  Application.CreateForm(TFormExec, FormExec);
  Application.CreateForm(TFormFirewall, FormFirewall);
  Application.CreateForm(TFormSmartHND, FormSmartHND);
  Application.CreateForm(TFormReg, FormReg);
  Application.CreateForm(TFormAutorun, FormAutorun);
  Application.CreateForm(TFormAbout, FormAbout);
 FormLoading.Step('SmartHandler.GlobalStart');
  SmartHandler.GlobalStart;
 FormLoading.Step('Готово');
  FormLoading.Close;
  Application.Run;
end.
