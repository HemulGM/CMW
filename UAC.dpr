program UAC;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, Winapi.Windows, Vcl.Dialogs;

begin
 try
  WinExec(PAnsiChar(AnsiString(ParamStr(1))), SW_NORMAL);
 except
  on E: Exception do Writeln(E.ClassName, ': ', E.Message);
 end;
end.
