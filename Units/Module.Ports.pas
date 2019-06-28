unit Module.Ports;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Winsock, Winsock2, ComCtrls, CMW.Utils, CMW.ModuleStruct, CMW.OSInfo,
  Vcl.Grids, Vcl.ValEdit, Vcl.ExtCtrls;

type

  //����� ��������� ��� ListView-���������
  TPortRowType = (ptTCP, ptUDP, ptTCPEx, ptUDPEx);

  TCOMMONROW = packed record
    dwType: TPortRowType;
    dwState: DWORD;
    dwLocalAddr: DWORD;
    dwLocalPort: DWORD;
    dwRemoteAddr: DWORD;
    dwRemotePort: DWORD;
    dwProcessID: DWORD;
    dwProcessName: string[255];
    dwLocalAddrStr: string[255];
    dwRemoteAddrStr: string[255];
  end;

  // ��������� ��� ������ �������
  PMIB_TCPROW = ^MIB_TCPROW;

  MIB_TCPROW = record
    dwState: DWORD;
    dwLocalAddr: DWORD;
    dwLocalPort: DWORD;
    dwRemoteAddr: DWORD;
    dwRemotePort: DWORD;
  end;

  PMIB_TCPTABLE = ^MIB_TCPTABLE;

  MIB_TCPTABLE = record
    dwNumEntries: DWORD;
    table: array[0..0] of MIB_TCPROW;
  end;

  PMIB_UDPROW = ^MIB_UDPROW;

  MIB_UDPROW = record
    dwLocalAddr: DWORD;
    dwLocalPort: DWORD;
  end;

  PMIB_UDPTABLE = ^MIB_UDPTABLE;

  MIB_UDPTABLE = record
    dwNumEntries: DWORD;
    table: array[0..0] of MIB_UDPROW;
  end;

  // ��������� ��� ����������� �������
  // TCP ROW
  PMIB_TCPEXROW = ^TMIB_TCPEXROW;

  TMIB_TCPEXROW = packed record
    dwState: DWORD;
    dwLocalAddr: DWORD;
    dwLocalPort: DWORD;
    dwRemoteAddr: DWORD;
    dwRemotePort: DWORD;
    dwProcessID: DWORD;
  end;

  // TCP Table
  PMIB_TCPEXTABLE = ^TMIB_TCPEXTABLE;

  TMIB_TCPEXTABLE = packed record
    dwNumEntries: DWORD;
    Table: array[0..0] of TMIB_TCPEXROW;
  end;

  // UDP ROW
  PMIB_UDPEXROW = ^TMIB_UDPEXROW;

  TMIB_UDPEXROW = packed record
    dwLocalAddr: DWORD;
    dwLocalPort: DWORD;
    dwProcessID: DWORD;
  end;

  // UDP Table
  PMIB_UDPEXTABLE = ^TMIB_UDPEXTABLE;

  TMIB_UDPEXTABLE = packed record
    dwNumEntries: DWORD;
    Table: array[0..0] of TMIB_UDPEXROW;
  end;

  TCP_TABLE_CLASS = (TCP_TABLE_BASIC_LISTENER, TCP_TABLE_BASIC_CONNECTIONS, TCP_TABLE_BASIC_ALL, TCP_TABLE_OWNER_PID_LISTENER, TCP_TABLE_OWNER_PID_CONNECTIONS, TCP_TABLE_OWNER_PID_ALL, TCP_TABLE_OWNER_MODULE_LISTENER, TCP_TABLE_OWNER_MODULE_CONNECTIONS, TCP_TABLE_OWNER_MODULE_ALL);

  UDP_TABLE_CLASS = (UDP_TABLE_BASIC, UDP_TABLE_OWNER_PID, UDP_TABLE_OWNER_MODULE);

  TFormPorts = class(TForm)
    EditDisplayName: TEdit;
    Panel1: TPanel;
    Bevel1: TBevel;
    LabelPermission: TLabel;
    ButtonClose: TButton;
    ValueListEditor1: TValueListEditor;
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  TPortsUnit = class(TSystemUnit)
  private
    FDisableIcon: TIcon;
  public
    FImageList: TImageList;
    function FGet: TGlobalState; override;
    procedure OnChanged; override;
    procedure Initialize; override;
    procedure ShowInfo;
    procedure Stop; override;
    constructor Create; override;
    destructor Destroy; override;
    property DisableIcon: TIcon read FDisableIcon write FDisableIcon;
  end;

const
  TCPState: array[0..12] of string = ('����������', '������. ����� �� ������������.',
                                      '������� �������� ����������.',
                                      '������� �������� ���������� ����������.',
                                      '���� ��������� ������������� ����������.',
                                      '���������� �����������.',
                                      '����� ������; ���������� ����������.',
                                      '����� ������; �������� ���������� ��������� �������.',
                                      '��������� ������� �����������; �������� �������� ������.',
                                      '����� ������, ����� ��������� ������� �����������; �������� �������������.',
                                      '��������� ������� �����������, ����� ����� ������; �������� �������������.',
                                      '����� ������, �� ������� ������, ��� ����������� � ���� ��� ���������',
                                      'DELETE TCB');
  ConTypeStr: array[TPortRowType] of string = ('TCP', 'UDP', 'TCP', 'UDP');

var
  FormPorts: TFormPorts;
  HIpHlpApi: THandle = 0;
  TargetIP, ResIP: string;
  ResID: Byte;
  dwSize: DWORD;

  // ������ �������
  GetTcpTable: function(pTcpTable: PMIB_TCPTABLE; var pdwSize: DWORD; bOrder: BOOL): DWORD; stdcall;
 {$EXTERNALSYM GetTcpTable}
  GetUdpTable: function(pUdpTable: PMIB_UDPTABLE; var pdwSize: DWORD; bOrder: BOOL): DWORD; stdcall;
 {$EXTERNALSYM GetUdpTable}

 // ����� �������
  GetExtendedTcpTable: function(pTcpTable: PMIB_TCPEXTABLE; var pdwSize: DWORD; bOrder: BOOL; ulAf: ULONG; TableClass: TCP_TABLE_CLASS; Reserved: ULONG): DWORD; stdcall;
 {$EXTERNALSYM GetExtendedTcpTable}
  GetExtendedUdpTable: function(pTcpTable: PMIB_UDPEXTABLE; var pdwSize: DWORD; bOrder: BOOL; ulAf: ULONG; TableClass: UDP_TABLE_CLASS; Reserved: ULONG): DWORD; stdcall;
 {$EXTERNALSYM GetExtendedUdpTable}

function GetExConnections(LV: TListView): Boolean;

procedure SelectPortsByPID(LV: TListView; PID: integer);

function SetRIPInfo(LV: TListView): Boolean;

function GetNameFromIP(const IP: string): string;

procedure GetNameFromIPProc;

function ToCommonRow(PortData: MIB_TCPROW): TCOMMONROW; overload;

function ToCommonRow(PortData: MIB_UDPROW): TCOMMONROW; overload;

function ToCommonRow(PortData: TMIB_TCPEXROW): TCOMMONROW; overload;

function ToCommonRow(PortData: TMIB_UDPEXROW): TCOMMONROW; overload;

implementation

uses
  Vcl.ImgList, CMW.Main, IniFiles, Module.WinProcesses;

{$R *.dfm}

{
var i:Integer;
    Ini:TIniFile;
begin
 Result:=False;
 if not Assigned(LV) then Exit;
 if LV.Items.Count <=0 then Exit;
 try
  Ini:=TIniFile.Create(CurrentDir+'Data\Ports.inf');
 except
  begin
   Log(['������ �������� �����', CurrentDir+'Data\Ports.inf', GetLastError]);
   Exit;
  end;
 end;
 for i:=0 to LV.Items.Count - 1 do
  begin
   LV.Items[i].SubItems[7]:=Ini.ReadString(LV.Items[i].Caption, LV.Items[i].SubItems[0], '');
   LV.Items[i].SubItems[8]:=Ini.ReadString(LV.Items[i].Caption, LV.Items[i].SubItems[5], '');
   if Stopping then Exit;
  end;
 Ini.Free;
 Result:=True;
}

procedure ShowData(PD: TCOMMONROW);
var
  Old: Integer;
  Ini: TIniFile;
begin
  with FormPorts, PD do
  begin
   { IsRegType:Boolean;

   DisplayName:string;
   Cmd:string;
   RegPath:string;
   RegName:string;
   RegRoot:HKEY;
   Exists:Boolean}

    try
      Ini := TIniFile.Create(CurrentDir + 'Data\Ports.inf');
    except
      begin
        Log(['������ �������� �����', CurrentDir + 'Data\Ports.inf', GetLastError]);
        Exit;
      end;
    end;

    ValueListEditor1.Strings.Clear;
    AddToValueEdit(ValueListEditor1, '��� ����������', ConTypeStr[dwType], '�� ��������');
    AddToValueEdit(ValueListEditor1, '��������� �����', PD.dwLocalAddrStr + ':' + IntToStr(PD.dwLocalPort), '');
    AddToValueEdit(ValueListEditor1, '�������� �����', PD.dwLocalAddrStr + ':' + IntToStr(PD.dwRemotePort), '');
    AddToValueEdit(ValueListEditor1, '��������� ����', Ini.ReadString(ConTypeStr[dwType], IntToStr(dwLocalPort), ''), '');
    AddToValueEdit(ValueListEditor1, '�������� ����', Ini.ReadString(ConTypeStr[dwType], IntToStr(dwRemotePort), ''), '');
    AddToValueEdit(ValueListEditor1, '���������', TCPState[dwState], '�� ��������');

    if ValueListEditor1.Strings.Count * ValueListEditor1.RowHeights[0] + 6 <= 400 then
      ValueListEditor1.Height := ValueListEditor1.Strings.Count * ValueListEditor1.RowHeights[0] + 6
    else
      ValueListEditor1.Height := 400;
    Old := ValueListEditor1.Height;
    ClientHeight := ValueListEditor1.Top + ValueListEditor1.Height + 60;
    ValueListEditor1.Height := Old + 10;
    LabelPermission.Visible := False;
    EditDisplayName.Text := IntToStr(PD.dwProcessID) + ':' + PD.dwProcessName;
    Ini.Free;
    ShowModal;
  end;
end;

function ToCommonRow(PortData: MIB_TCPROW): TCOMMONROW;
begin
  with Result do
  begin
    dwType := ptTCP;
    dwState := PortData.dwState;
    dwLocalAddr := PortData.dwLocalAddr;
    dwLocalPort := PortData.dwLocalPort;
    dwRemoteAddr := PortData.dwRemoteAddr;
    dwRemotePort := PortData.dwRemotePort;
    dwRemoteAddrStr := inet_ntoa(TInAddr(dwRemoteAddr));
    dwLocalAddrStr := inet_ntoa(TInAddr(dwLocalAddr));
    dwProcessID := 0;
  end;
end;

function ToCommonRow(PortData: MIB_UDPROW): TCOMMONROW;
begin
  with Result do
  begin
    dwType := ptUDP;
    dwState := 0;
    dwLocalAddr := PortData.dwLocalAddr;
    dwLocalPort := PortData.dwLocalPort;
    dwRemoteAddr := 0;
    dwRemotePort := 0;
    dwRemoteAddrStr := '';
    dwLocalAddrStr := inet_ntoa(TInAddr(dwLocalAddr));
    dwProcessID := 0;
  end;
end;

function ToCommonRow(PortData: TMIB_TCPEXROW): TCOMMONROW;
begin
  with Result do
  begin
    dwType := ptTCPEx;
    dwState := PortData.dwState;
    dwLocalAddr := PortData.dwLocalAddr;
    dwLocalPort := PortData.dwLocalPort;
    dwRemoteAddr := PortData.dwRemoteAddr;
    dwRemotePort := PortData.dwRemotePort;
    dwRemoteAddrStr := inet_ntoa(TInAddr(dwRemoteAddr));
    dwLocalAddrStr := inet_ntoa(TInAddr(dwLocalAddr));
    dwProcessID := PortData.dwProcessID;
  end;
end;

function ToCommonRow(PortData: TMIB_UDPEXROW): TCOMMONROW;
begin
  with Result do
  begin
    dwType := ptUDPEx;
    dwState := 0;
    dwLocalAddr := PortData.dwLocalAddr;
    dwLocalPort := PortData.dwLocalPort;
    dwRemoteAddr := 0;
    dwRemotePort := 0;
    dwRemoteAddrStr := '';
    dwLocalAddrStr := inet_ntoa(TInAddr(dwLocalAddr));
    dwProcessID := PortData.dwProcessID;
  end;
end;

procedure TPortsUnit.ShowInfo;
begin
  if FListView.Selected = nil then
    Exit;
  if FListView.Selected.Data = nil then
    Exit;
  ShowData(TCOMMONROW(FListView.Selected.Data^));
end;

procedure TPortsUnit.Initialize;
begin
 //
end;

procedure TPortsUnit.OnChanged;
begin
  inherited;
  OnListViewSort;
end;

procedure TPortsUnit.Stop;
begin
  inherited;
end;

function TPortsUnit.FGet: TGlobalState;
var
  IconN: TIcon;
begin
  Inform(LangText(-1, '���������� ������ �������� TCP/UDP ������ ...'));
  Result := gsProcess;
  ListView.Items.BeginUpdate;
  ListView.Items.Clear;
  ListView.Groups.Clear;
  ListView.GroupView := FGrouping;
  ListView.Groups.Add.Header := 'TCP-�����������';
  ListView.Groups.Add.Header := 'UDP-�����������';

  if ListView.SmallImages <> nil then
    ListView.SmallImages.Clear
  else
  begin
    ListView.SmallImages := TImageList.CreateSize(16, 16);
    ListView.SmallImages.ColorDepth := cd32Bit;
  end;

  IconN := TIcon.Create;
  FImageList.GetIcon(0, IconN);
  ListView.SmallImages.AddIcon(IconN);
  FImageList.GetIcon(1, IconN);
  ListView.SmallImages.AddIcon(IconN);
  IconN.Free;
  if (@GetExtendedTcpTable = nil) and (@GetTcpTable = nil) and (@GetExtendedUdpTable = nil) and (@GetUdpTable = nil) then
  begin
    Log(['API ������ ������������ ������� �� ����� ���� ������������']);
    Exit(gsError);
  end;

  if not GetExConnections(ListView) then
    Result := gsError
  else
    Result := gsFinished;

  if Result = gsFinished then
    Inform(LangText(-1, '������ �������� ������ ������� �������.'))
  else
    Inform(LangText(-1, '������ �������� ������ �� �������.'));
  OnChanged;
end;

constructor TPortsUnit.Create;
begin
  inherited;
  FImageList := TImageList.CreateSize(16, 16);
  FImageList.ColorDepth := cd32Bit;
end;

destructor TPortsUnit.Destroy;
begin
  FImageList.Free;
  inherited;
end;

function GetNameFromIP(const IP: string): string;
var
  ThreadLogID: Cardinal;
begin
  if IP.Length <= 3 then
    Exit(IP);
  TargetIP := IP;
  ResIP := IP;
  ResID := 0;
  CreateThread(nil, 0, @GetNameFromIPProc, nil, 0, ThreadLogID);
  while ResID <= 0 do
    Application.ProcessMessages;
  Result := ResIP;
end;

procedure GetNameFromIPProc;
const
  ERR_INADDR = '�� ���� �������� IP �� in_addr.';
  ERR_HOST = '�� ���� �������� ���������� � �����:';
  ERR_WSA = '�� ���� ���������������� WSA.';
  WSA_Type = $101; //$202;
var
  WSA: Winsock.TWSAData;
  Host: Winsock.PHostEnt;
  Addr: Integer;
  Err: Integer;
  IP: string;
begin
  IP := TargetIP;
  ResIP := IP;
  Err := Winsock.WSAStartup(WSA_Type, WSA);
  if Err <> 0 then
  begin
    Log([ERR_WSA, Err, SysErrorMessage(GetLastError)]);
    ResID := 1;
    Exit;
  end;
  Addr := Winsock.inet_addr(PAnsiChar(AnsiString(IP)));
  if Addr = Int(INADDR_NONE) then
  begin
    Log([ERR_INADDR, 'Winsock.inet_addr(PAnsiChar(AnsiString(', IP, '))) =', Addr, SysErrorMessage(GetLastError)]);
    Winsock.WSACleanup;
    ResID := 1;
    Exit;
  end;
  Host := Winsock.gethostbyaddr(@Addr, SizeOf(Addr), PF_INET);
  if Assigned(Host) then
    ResIP := Host.h_name + ' (' + IP + ')'
  else
    Log([ERR_HOST, IP, SysErrorMessage(GetLastError)]);
  Winsock.WSACleanup;
  ResID := 2;
end;

function SetRIPInfo(LV: TListView): Boolean;
var
  i: Integer;
begin
  Result := False;
  if not Assigned(LV) then
    Exit;
  if LV.Items.Count <= 0 then
    Exit;
  for i := 0 to LV.Items.Count - 1 do
  begin
    LV.Items[i].SubItems[1] := GetNameFromIP(TCOMMonROW(LV.Items[i].Data^).dwLocalAddrStr) + ':' + IntToStr(TCOMMonROW(LV.Items[i].Data^).dwLocalPort);
    LV.Items[i].SubItems[2] := GetNameFromIP(TCOMMonROW(LV.Items[i].Data^).dwRemoteAddrStr) + ':' + IntToStr(TCOMMonROW(LV.Items[i].Data^).dwRemotePort);
    if Stopping then
      Exit;
  end;
  Result := True;
end;

procedure SelectPortsByPID(LV: TListView; PID: integer);
var
  i: Integer;
begin
  if LV.Items.Count <= 0 then
    Exit;
  for i := 0 to LV.Items.Count - 1 do
  begin
    LV.Items[i].Selected := LV.Items[i].SubItems[1] = IntToStr(PID);
  end;
  if LV.Selected <> nil then
    LV.Selected.MakeVisible(True);
end;

function GetExConnections(LV: TListView): Boolean;
var
  TCPExTable: PMIB_TCPEXTABLE;
  UDPExTable: PMIB_UDPEXTABLE;
  TCPTable: PMIB_TCPTABLE;
  UDPTable: PMIB_UDPTABLE;
  i: Integer;
  local_name: array[0..255] of Char;
  Er: DWORD;
  FullName: string;
  II: Word;
  p: Cardinal;
  siPID: Integer;
  siLoc: Integer;
  siRem: Integer;
  siSta: Integer;
  Step: Boolean;
begin
  Result := False;
  Step := False;

  try
    try
   //����������� ���������� � TCP-������������
      if @GetExtendedTcpTable <> nil then
      begin
        TCPExTable := nil;
        dwSize := 0;
        Er := GetExtendedTcpTable(TCPExTable, dwSize, False, AF_INET, TCP_TABLE_OWNER_PID_ALL, 0);
        IntToStr(Er);
        if (Er <> ERROR_INSUFFICIENT_BUFFER) or (dwSize = 0) then
        begin
          ShowMessage(IntToStr(Er) + ' (Er <> ERROR_INSUFFICIENT_BUFFER) or (dwSize = 0)');
          Log(['TCPEx', SysErrorMessage(Er), '(Er <> ERROR_INSUFFICIENT_BUFFER) or (dwSize = 0)', Er <> ERROR_INSUFFICIENT_BUFFER, dwSize = 0]);
          Step := False;
        end
        else
        begin
       //TCPExTable:=GetMemory(dwSize);
       //ZeroMemory(TCPExTable, dwSize);
          New(TCPExTable);
          ReallocMem(TCPExTable, dwSize);
          Er := GetExtendedTcpTable(TCPExTable, dwSize, False, AF_INET, TCP_TABLE_OWNER_PID_ALL, 0);
          if Er = NO_ERROR then
          begin
            for i := 0 to TCPExTable^.dwNumEntries - 1 do
            begin
              with LV.Items.Add do
              begin
                Data := AllocMem(SizeOf(TCOMMONROW));
                TCOMMONROW(Data^) := ToCommonRow(TCPExTable^.Table[i]);
                siPID := SubItems.Add('');
                siLoc := SubItems.Add('');
                siRem := SubItems.Add('');
                siSta := SubItems.Add('');

                p := TCPExTable^.Table[i].dwProcessId;
                SubItems[siPID] := IntToStr(p);
                FullName := GetProcessName(p);
                NormFileName(FullName);
                try
                  if FileExists(FullName) then
                  begin
                    if GetFileIcon(FullName, is16, TListView(ListView).SmallImages, II) > 0 then
                      ImageIndex := II
                  end
                  else
                    ImageIndex := 0;
                except
                  Log(['�� ���� ��������� ������ �� �����:', FullName, GetLastError]);
                end;
                Caption := ExtractFileName(FullName);
                TCOMMONROW(Data^).dwProcessName := Caption;
                SubItems[siLoc] := inet_ntoa(TInAddr(TCPExTable^.Table[i].dwLocalAddr)) + ':' + IntToStr(ntohs(TCPExTable^.Table[i].dwLocalPort));
                if TCPExTable^.Table[i].dwState <> 2 then
                  SubItems[siRem] := inet_ntoa(TInAddr(TCPExTable^.Table[i].dwRemoteAddr)) + ':' + IntToStr(ntohs(TCPExTable^.Table[i].dwRemotePort));
                SubItems[siSta] := TCPState[TCPExTable^.Table[i].dwState];
                GroupID := 0;
              end;
            end;
            Step := True;
          end
          else
          begin
            Log(['�� ���� �������� ����� ��������� ���������� � TCP-������������.', SysErrorMessage(Er)]);
            Step := False;
          end;
        end;
      end
      else
        Step := False;

   //���� �� ���� �������� ��������� ���� � ������������, ������� ����� ��������
      if not Step then
      begin
        if @GetTcpTable <> nil then
        begin
          dwSize := 0;
          Er := GetTcpTable(nil, dwSize, True);
          if (Er <> ERROR_INSUFFICIENT_BUFFER) then
            Step := False
          else
          begin
            New(TCPTable);
            ReallocMem(TCPTable, dwSize);
            Er := GetTcpTable(TCPTable, dwSize, True);
            if Er = NO_ERROR then
            begin
              for i := 0 to TCPTable.dwNumEntries - 1 do
              begin
                with LV.Items.Add do
                begin
                  ImageIndex := 0;
                  Data := AllocMem(SizeOf(TCOMMONROW));
                  TCOMMONROW(Data^) := ToCommonRow(TCPTable^.Table[i]);
                  siPID := SubItems.Add('');
                  siLoc := SubItems.Add('');
                  siRem := SubItems.Add('');
                  siSta := SubItems.Add('');

                  Caption := '<��� ������>';
                  TCOMMONROW(Data^).dwProcessName := Caption;
                  SubItems[siLoc] := inet_ntoa(TInAddr(TCPTable^.Table[i].dwLocalAddr)) + ':' + IntToStr(ntohs(TCPTable^.Table[i].dwLocalPort));
                  if TCPTable^.Table[i].dwState <> 2 then
                    SubItems[siRem] := inet_ntoa(TInAddr(TCPTable^.Table[i].dwRemoteAddr)) + ':' + IntToStr(ntohs(TCPTable^.Table[i].dwRemotePort));
                  SubItems[siSta] := TCPState[TCPTable^.Table[i].dwState];
                  GroupID := 0;
                end;
              end;
              Step := True;
            end
            else
              Step := False;
          end;
        end
        else
          Step := False;
      end;
      if not Step then
        Log(['�� ���� �������� ����� ���������� � TCP-������������']);

   //UDP
      if @GetExtendedUdpTable <> nil then
      begin
        Step := False;
        UDPExTable := nil;
        dwSize := 0;
        Er := GetExtendedUdpTable(nil, dwSize, False, AF_INET, UDP_TABLE_OWNER_PID, 0);
        if (Er <> ERROR_INSUFFICIENT_BUFFER) or (dwSize = 0) then
        begin
          Log(['UDPEx', SysErrorMessage(Er), '(Er <> ERROR_INSUFFICIENT_BUFFER) or (dwSize = 0)', Er <> ERROR_INSUFFICIENT_BUFFER, dwSize = 0]);
          Step := False;
        end
        else
        begin
       //UdpExTable:=GetMemory(dwSize);
       //ZeroMemory(UdpExTable, dwSize);
          New(UDPExTable);
          ReallocMem(UDPExTable, dwSize);
          Er := GetExtendedUdpTable(UDPExTable, dwSize, False, AF_INET, UDP_TABLE_OWNER_PID, 0);
          if Er = NO_ERROR then
          begin
            for i := 0 to UDPExTable^.dwNumEntries - 1 do
            begin
              with LV.Items.Add do
              begin
                Data := AllocMem(SizeOf(TCOMMONROW));
                TCOMMONROW(Data^) := ToCommonRow(UDPExTable^.Table[i]);
                siPID := SubItems.Add('');
                siLoc := SubItems.Add('');
                siRem := SubItems.Add('');
                siSta := SubItems.Add('');

                p := UDPExTable^.Table[i].dwProcessId;
                SubItems[siPID] := IntToStr(p);
                FullName := GetProcessName(p);
                NormFileName(FullName);
                try
                  if FileExists(FullName) then
                  begin
                    if GetFileIcon(FullName, is16, TListView(ListView).SmallImages, II) > 0 then
                      ImageIndex := II
                  end
                  else
                    ImageIndex := 0;
                except
                  Log(['�� ���� ��������� ������ �� �����:', FullName, GetLastError]);
                end;

                Caption := ExtractFileName(FullName);
                TCOMMONROW(Data^).dwProcessName := Caption;
                SubItems[siLoc] := inet_ntoa(TInAddr(UDPExTable^.Table[i].dwLocalAddr)) + ':' + IntToStr(ntohs(UDPExTable^.Table[i].dwLocalPort));
                SubItems[siRem] := '';
             //gethostname(PAnsiChar(AnsiString(StrPas(local_name))), 255);
                GroupID := 1;
              end;
            end;
            Step := True;
          end
          else
            Step := False;
        end;
      end
      else
        Step := False;

      if not Step then
      begin
        if @GetUdpTable <> nil then
        begin
          dwSize := 0;
          Er := GetUDPTable(nil, dwSize, True);
          if (Er <> ERROR_INSUFFICIENT_BUFFER) then
            Step := False
          else
          begin
            New(UDPTable);
            ReallocMem(UDPTable, dwSize);
            Er := GetUdpTable(UDPTable, dwSize, True);
            if Er = NO_ERROR then
            begin
              for i := 0 to UDPTable.dwNumEntries - 1 do
              begin
                with LV.Items.Add do
                begin
                  ImageIndex := 1;
                  Data := AllocMem(SizeOf(TCOMMONROW));
                  TCOMMONROW(Data^) := ToCommonRow(UDPTable^.Table[i]);
                  siPID := SubItems.Add('');
                  siLoc := SubItems.Add('');
                  siRem := SubItems.Add('');
                  siSta := SubItems.Add('');

                  Caption := '<��� ������>';
                  TCOMMONROW(Data^).dwProcessName := Caption;
                  SubItems[siLoc] := inet_ntoa(TInAddr(UDPTable^.Table[i].dwLocalAddr)) + ':' + IntToStr(ntohs(UDPTable^.Table[i].dwLocalPort));
                  GroupID := 1;
                end;
              end;
              Step := True;
            end
            else
              Step := False;
          end;
        end
        else
          Step := False;
      end;
      if not Step then
        Log(['�� ���� �������� ����� ���������� � TCP-������������']);
      Result := True;
    except
      begin
        Result := False;
        Log(['������ ��� ��������� ���������� � TCP/UDP-������������', SysErrorMessage(GetLastError)]);
      end;
    end;
  finally
    FreeMemory(TCPExTable);
    FreeMemory(UDPExTable);
  end;
end;

function LoadAPIHelpAPI: Boolean;
begin
  Result := False;
  if HIphlpapi = 0 then
    HIpHlpApi := LoadLibrary('iphlpapi.dll');
  if HIpHlpApi > HINSTANCE_ERROR then
  begin
    try
      @GetTcpTable := GetProcAddress(HIpHlpApi, 'GetTcpTable');
      @GetUdpTable := GetProcAddress(HIpHlpApi, 'GetUdpTable');
    except
      begin
        @GetTcpTable := nil;
        @GetUdpTable := nil;
      end;
    end;
    try
      @GetExtendedTcpTable := GetProcAddress(HIpHlpApi, 'GetExtendedTcpTable');
      @GetExtendedUdpTable := GetProcAddress(HIpHlpApi, 'GetExtendedUdpTable');
    except
      begin
        @GetExtendedTcpTable := nil;
        @GetExtendedUdpTable := nil;
      end;
    end;
    Result := True;
  end;
end;

procedure FreeAPIHelpAPI;
begin
  if HIpHlpApi <> 0 then
    FreeLibrary(HIpHlpApi);
  HIpHlpApi := 0;
end;

procedure TFormPorts.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE:
      Close;
  end;
end;

initialization
  LoadAPIHelpAPI;

finalization
  FreeAPIHelpAPI;

end.

