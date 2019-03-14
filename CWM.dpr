program CWM;

uses
  Vcl.Forms,
  Vcl.Themes,
  Vcl.Styles,
  FWEventLog in 'Imported\FWEventLog.pas',
  CMW.Main in 'CMW.Main.pas' {FormMain},
  ShellRecycle in 'Imported\ShellRecycle.pas',
  taskSchd in 'Imported\taskSchd.pas',
  taskSchdXP in 'Imported\taskSchdXP.pas',
  CMW.ModuleStruct in 'CMW.ModuleStruct.pas',
  CMW.OSInfo in 'CMW.OSInfo.pas',
  SMARTAPI in 'Imported\SMARTAPI.pas',
  WMI in 'Imported\WMI.pas',
  CMW.Utils in 'CMW.Utils.pas',
  WbemScripting_TLB in 'Imported\WbemScripting_TLB.pas',
  Subs in 'Imported\Subs.pas',
  CMW.ModuleProp in 'CMW.ModuleProp.pas' {FormUnitProperties},
  Firewall in 'Imported\Firewall.pas',
  NativeAPI in 'Imported\NativeAPI.pas',
  MD5 in 'Imported\MD5.pas',
  CMW.Loading in 'CMW.Loading.pas' {FormLoading},
  CMW.About in 'CMW.About.pas' {FormAbout},
  Module.Applications in 'Units\Module.Applications.pas' {FormApp},
  Module.Autoruns in 'Units\Module.Autoruns.pas' {FormAutorun},
  Module.Cleaner in 'Units\Module.Cleaner.pas',
  Module.CleanerElements in 'Units\Module.CleanerElements.pas',
  Module.HDD in 'Units\Module.HDD.pas' {FormHDD},
  Module.Ports in 'Units\Module.Ports.pas' {FormPorts},
  Module.SmartHND in 'Units\Module.SmartHND.pas' {FormSmartHND},
  Module.Tasks in 'Units\Module.Tasks.pas' {FormTask},
  Module.WinEvents in 'Units\Module.WinEvents.pas' {FormEventInfo},
  Module.WinFirewall in 'Units\Module.WinFirewall.pas' {FormFirewall},
  Module.WinProcesses in 'Units\Module.WinProcesses.pas' {FormProcess},
  Module.WinServices in 'Units\Module.WinServices.pas' {FormService},
  Module.ContextMenu in 'Units\Module.ContextMenu.pas' {FormContextMenu},
  Module.Executting in 'Units\Module.Executting.pas' {FormExec},
  Module.Regeditor in 'Units\Module.Regeditor.pas' {FormReg};

{$R *.res}

begin
 Application.Initialize;
 Application.MainFormOnTaskbar := True;
 Application.Title := 'Complex maintenance of workstation';
 //
 FormLoading := TFormLoading.Create(nil);
 FormLoading.Show;
 FormLoading.Step('Запуск');
 Application.ProcessMessages;
 FormLoading.Step('OSInfo.Init');
 CMW.OSInfo.Init;
 //
 FormLoading.Step('Application.Initialize');
 FormLoading.Step('Forms Initialize');
 Application.CreateForm(TFormMain, FormMain);
  Application.CreateForm(TFormAutorun, FormAutorun);
  Application.CreateForm(TFormAbout, FormAbout);
  Application.CreateForm(TFormApp, FormApp);
  Application.CreateForm(TFormAutorun, FormAutorun);
  Application.CreateForm(TFormHDD, FormHDD);
  Application.CreateForm(TFormPorts, FormPorts);
  Application.CreateForm(TFormSmartHND, FormSmartHND);
  Application.CreateForm(TFormTask, FormTask);
  Application.CreateForm(TFormFirewall, FormFirewall);
  Application.CreateForm(TFormProcess, FormProcess);
  Application.CreateForm(TFormService, FormService);
  Application.CreateForm(TFormContextMenu, FormContextMenu);
  Application.CreateForm(TFormExec, FormExec);
  Application.CreateForm(TFormReg, FormReg);
  FormLoading.Step('SmartHandler.Initialize');
 CMW.Main.Init;
 FormLoading.Step('SmartHandler.GlobalStart');
 SmartHandler.GlobalStart;
 FormLoading.Step('Готово');
 FormLoading.Close;
 Application.Run;
end.

