program MD5Maker;

uses
  Forms,
  Md5Main in 'Md5Main.PAS' {FormMain},
  MD5 in '..\Imported\MD5.pas',
  NameDialog in 'NameDialog.pas' {FormMD5Name};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.CreateForm(TFormMD5Name, FormMD5Name);
  Application.Run;
end.
 
