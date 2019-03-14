program RunCMW;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Windows,
  ShellAPI;

var Bits:Byte;
    cmdLine:string;

function Is64BitWindows:Boolean;
var IsWow64Process:function(hProcess: THandle; out Wow64Process:Bool):Bool; stdcall;
    Wow64Process:Bool;
begin
 {$IF Defined(Win64)}
 Result:=True; // 64-битная программа запускается только на Win64
 Exit;
 {$ELSEIF Defined(CPU16)}
 Result:=False; // Win64 не поддерживает 16-разрядные приложения
 {$ELSE}
 // 32-битные программы могут работать и на 32-разрядной и на 64-разрядной Windows
 // так что этот вопрос требует дальнейшего исследования
 IsWow64Process:=GetProcAddress(GetModuleHandle(Kernel32), 'IsWow64Process');
 Wow64Process:=False;
 if Assigned(IsWow64Process) then
  Wow64Process:=IsWow64Process(GetCurrentProcess, Wow64Process) and Wow64Process;
 Result:=Wow64Process;
 {$ENDIF}
end;

begin
  try
   if {GetEnvironmentVariable('ProgramFiles(x86)') = ''} Is64BitWindows then Bits:=1 else Bits:=0;
   case Bits of
    0:begin
       cmdLine:=ExtractFilePath(ParamStr(0))+'CWM32.exe';
       Writeln('Операционная система x32');
      end;
    1:begin
       cmdLine:=ExtractFilePath(ParamStr(0))+'CWM64.exe';
       Writeln('Операционная система x64');
      end;
   end;
   Writeln('Командная строка: ', cmdLine);
   Writeln('Результат выполнения команды запуска: ', ShellExecute(0, 'open', PChar(cmdLine), '', '', SW_NORMAL));
   Sleep(2000);
  except
   on E: Exception do Writeln(E.ClassName, ': ', E.Message);
  end;
end.
