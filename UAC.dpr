program UAC;

{$APPTYPE CONSOLE}

uses
  Winapi.Windows;

begin
 WinExec(PAnsiChar(AnsiString(ParamStr(1))), SW_NORMAL);
end.
