unit Firewall;
{
  adaptation <aboulouy@gmail.com>
  Rйfйrence : http://msdn2.microsoft.com/en-us/library/aa366415.aspx

}
Interface
uses
  SysUtils, ActiveX, ComObj, System.Classes, Vcl.Dialogs;

Const
  // Define Constants from the SDK and their associated string name Scope
  NET_FW_SCOPE_ALL = 0;
  NET_FW_SCOPE_ALL_NAME = 'Все подсети';
  NET_FW_SCOPE_LOCAL_SUBNET = 1;
  NET_FW_SCOPE_LOCAL_SUBNET_NAME = 'Только локальная подсеть';
  NET_FW_SCOPE_CUSTOM = 2;
  NET_FW_SCOPE_CUSTOM_NAME = 'Custom Scope (see RemoteAddresses)';

  // Profile Type
  NET_FW_PROFILE_DOMAIN = 0;
  NET_FW_PROFILE_DOMAIN_NAME = 'Domain';
  NET_FW_PROFILE_STANDARD = 1;
  NET_FW_PROFILE_STANDARD_NAME = 'Standard';

  // IP Version
  NET_FW_IP_VERSION_V4 = 0;
  NET_FW_IP_VERSION_V4_NAME = 'IPv4';
  NET_FW_IP_VERSION_V6 = 1;
  NET_FW_IP_VERSION_V6_NAME = 'IPv6';
  NET_FW_IP_VERSION_ANY = 2;
  NET_FW_IP_VERSION_ANY_NAME = 'Оба';

  // Protocol
  NET_FW_IP_PROTOCOL_TCP = 6;
  NET_FW_IP_PROTOCOL_TCP_NAME = 'TCP';
  NET_FW_IP_PROTOCOL_UDP = 17;
  NET_FW_IP_PROTOCOL_UDP_NAME = 'UDP';


Type
  oleBOOL=-1..0;
Const
  VRAI  =-1;
  FAUX  = 0;

  FW_PROFILE    : Array[0..1]  of string =('DOMAIN','STANDARD');
  FW_IP_VERSION : Array[0..2]  of string =('IPv4','IPv6','IPv4/6');
  FW_BOOL       :  Array[VRAI..FAUX]  of string =('Вкл.','Выкл.');
  Function FW_PROTOCOL(Value:Integer):String;


  Function IsFirewallEnabled:boolean;
  Function IsExceptionsNotAllowed:Boolean;
  Function IsNotificationsDisabled:Boolean;
  Function IsUnicastResponsestoMulticastBroadcastDisabled:Boolean;
  Function IsRemoteAdministrationEnabled:Boolean;

  function FirewallEnabled(STATE:oleBOOL):Boolean;
  Procedure ExceptionsNotAllowed(STATE:oleBOOL);
  Procedure NotificationsDisabled(STATE:oleBOOL);
  Procedure UnicastResponsestoMulticastBroadcastDisabled(STATE:oleBOOL);
  Procedure RemoteAdministrationEnabled(STATE:oleBOOL);

  Function IsAllowInboundEchoRequest:Boolean;
  Function IsAllowInboundMaskRequest:Boolean;
  Function IsAllowInboundRouterRequest:Boolean;
  Function IsAllowInboundTimestampRequest:Boolean;
  Function IsAllowOutboundDestinationUnreachable:Boolean;
  Function IsAllowOutboundPacketTooBig:Boolean;
  Function IsAllowOutboundParameterProblem:Boolean;
  Function IsAllowOutboundSourceQuench:Boolean;
  Function IsAllowOutboundTimeExceeded:Boolean;
  Function IsAllowRedirect:Boolean;

  Procedure AllowInboundEchoRequest(STATE:oleBOOL);
  Procedure AllowInboundMaskRequest(STATE:oleBOOL);
  Procedure AllowInboundRouterRequest(STATE:oleBOOL);
  Procedure AllowInboundTimestampRequest(STATE:oleBOOL);
  Procedure AllowOutboundDestinationUnreachable(STATE:oleBOOL);
  Procedure AllowOutboundPacketTooBig(STATE:oleBOOL);
  Procedure AllowOutboundParameterProblem(STATE:oleBOOL);
  Procedure AllowOutboundSourceQuench(STATE:oleBOOL);
  Procedure AllowOutboundTimeExceeded(STATE:oleBOOL);
  Procedure AllowRedirect(STATE:oleBOOL);

  Function  IsApplicationAuthorized(ApplicationPathAndExe:String):Boolean;
  Function  IsApplicationAuthorizedIsActive(ApplicationPathAndExe:String):Boolean;

  Procedure AddAnAuthorizedApplication(ApplicationName:string;ApplicationPathAndExe:string);
  Function  DeleteAnAuthorizedApplication(ApplicationPathAndExe:string):Integer;
  Procedure RestoreTheDefaultSettings;

  Procedure SetFirewall;

implementation
 uses WinServices;

Function IsFirewallEnabled:boolean;
Var
  objFirewall,
  objPolicy:OleVariant;
begin
 Result:=False;
  Try
    objFirewall := CreateOLEObject('HNetCfg.FwMgr');
    objPolicy := objFirewall.LocalPolicy.CurrentProfile;
    Result:=objPolicy.FirewallEnabled;
  except
  end;
end;

Function  IsExceptionsNotAllowed:Boolean;
Var
  objFirewall,
  objPolicy:OleVariant;
begin
 Result:=False;
  Try
    objFirewall := CreateOLEObject('HNetCfg.FwMgr');
    objPolicy := objFirewall.LocalPolicy.CurrentProfile;
    Result:=objPolicy.ExceptionsNotAllowed;
  except
  end;
end;

Function  IsNotificationsDisabled:Boolean;
Var
  objFirewall,
  objPolicy:OleVariant;
begin
 Result:=False;
  Try
    objFirewall := CreateOLEObject('HNetCfg.FwMgr');
    objPolicy := objFirewall.LocalPolicy.CurrentProfile;
    Result:=objPolicy.NotificationsDisabled;
  except
  end;
end;

Function  IsUnicastResponsestoMulticastBroadcastDisabled:Boolean;
Var
  objFirewall,
  objPolicy:OleVariant;
begin
 Result:=False;
  Try
    objFirewall := CreateOLEObject('HNetCfg.FwMgr');
    objPolicy := objFirewall.LocalPolicy.CurrentProfile;
    Result:=objPolicy.UnicastResponsestoMulticastBroadcastDisabled;
  except
  end;
end;

Function IsRemoteAdministrationEnabled:Boolean;
Var
  objFirewall,
  objPolicy,
  objAdminSettings:OleVariant;
begin
 Result:=False;
  Try
    objFirewall := CreateOLEObject('HNetCfg.FwMgr');
    objPolicy := objFirewall.LocalPolicy.CurrentProfile;
    objAdminSettings := objPolicy.RemoteAdminSettings;
    result:=objAdminSettings.Enabled;
  except
  end;
end;

Function IsAllowInboundEchoRequest:Boolean;
Var
  objFirewall,
  objPolicy,
  objICMPSettings:OleVariant;
begin
 Result:=False;
  Try
    objFirewall := CreateOLEObject('HNetCfg.FwMgr');
    objPolicy := objFirewall.LocalPolicy.CurrentProfile;
    objICMPSettings := objPolicy.ICMPSettings;
    result:=objICMPSettings.AllowInboundEchoRequest;
  except
  end;
end;

Function IsAllowInboundMaskRequest:Boolean;
Var
  objFirewall,
  objPolicy,
  objICMPSettings:OleVariant;
begin
 Result:=False;
  Try
    objFirewall := CreateOLEObject('HNetCfg.FwMgr');
    objPolicy := objFirewall.LocalPolicy.CurrentProfile;
    objICMPSettings := objPolicy.ICMPSettings;
    result:=objICMPSettings.AllowInboundMaskRequest;
  except
  end;
end;

Function IsAllowInboundRouterRequest:Boolean;
Var
  objFirewall,
  objPolicy,
  objICMPSettings:OleVariant;
begin
 Result:=False;
  Try
    objFirewall := CreateOLEObject('HNetCfg.FwMgr');
    objPolicy := objFirewall.LocalPolicy.CurrentProfile;
    objICMPSettings := objPolicy.ICMPSettings;
    result:=objICMPSettings.AllowInboundRouterRequest;
  except
  end;
end;

Function IsAllowInboundTimestampRequest:Boolean;
Var
  objFirewall,
  objPolicy,
  objICMPSettings:OleVariant;
begin
 Result:=False;
  Try
    objFirewall := CreateOLEObject('HNetCfg.FwMgr');
    objPolicy := objFirewall.LocalPolicy.CurrentProfile;
    objICMPSettings := objPolicy.ICMPSettings;
    result:=objICMPSettings.AllowInboundTimestampRequest;
  except
  end;
end;

Function IsAllowOutboundDestinationUnreachable:Boolean;
Var
  objFirewall,
  objPolicy,
  objICMPSettings:OleVariant;
begin
 Result:=False;
  Try
    objFirewall := CreateOLEObject('HNetCfg.FwMgr');
    objPolicy := objFirewall.LocalPolicy.CurrentProfile;
    objICMPSettings := objPolicy.ICMPSettings;
    result:=objICMPSettings.AllowOutboundDestinationUnreachable;
  except
  end;
end;

Function IsAllowOutboundPacketTooBig:Boolean;
Var
  objFirewall,
  objPolicy,
  objICMPSettings:OleVariant;
begin
 Result:=False;
  Try
    objFirewall := CreateOLEObject('HNetCfg.FwMgr');
    objPolicy := objFirewall.LocalPolicy.CurrentProfile;
    objICMPSettings := objPolicy.ICMPSettings;
    result:=objICMPSettings.AllowOutboundPacketTooBig;
  except
  end;
end;

Function IsAllowOutboundParameterProblem:Boolean;
Var
  objFirewall,
  objPolicy,
  objICMPSettings:OleVariant;
begin
 Result:=False;
  Try
    objFirewall := CreateOLEObject('HNetCfg.FwMgr');
    objPolicy := objFirewall.LocalPolicy.CurrentProfile;
    objICMPSettings := objPolicy.ICMPSettings;
    result:=objICMPSettings.AllowOutboundParameterProblem;
  except
  end;
end;


Function IsAllowOutboundSourceQuench:Boolean;
Var
  objFirewall,
  objPolicy,
  objICMPSettings:OleVariant;
begin
 Result:=False;
  Try
    objFirewall := CreateOLEObject('HNetCfg.FwMgr');
    objPolicy := objFirewall.LocalPolicy.CurrentProfile;
    objICMPSettings := objPolicy.ICMPSettings;
    result:=objICMPSettings.AllowOutboundSourceQuench;
  except
  end;
end;

Function IsAllowOutboundTimeExceeded:Boolean;
Var
  objFirewall,
  objPolicy,
  objICMPSettings:OleVariant;
begin
 Result:=False;
  Try
    objFirewall := CreateOLEObject('HNetCfg.FwMgr');
    objPolicy := objFirewall.LocalPolicy.CurrentProfile;
    objICMPSettings := objPolicy.ICMPSettings;
    result:=objICMPSettings.AllowOutboundTimeExceeded;
  except
  end;
end;

function IsAllowRedirect:Boolean;
var
  objFirewall,
  objPolicy,
  objICMPSettings:OleVariant;
begin
 Result:=False;
  Try
    objFirewall := CreateOLEObject('HNetCfg.FwMgr');
    objPolicy := objFirewall.LocalPolicy.CurrentProfile;
    objICMPSettings := objPolicy.ICMPSettings;
    result:=objICMPSettings.AllowRedirect;
  except
  end;
end;

function FirewallEnabled;
var objFirewall,
    objPolicy :OleVariant;
begin
 if State = FAUX then
  begin
   if ServiceStop('MpsSvc') <> 0 then ShowMessage('Не смог остановить службу Брандмауэра Windows.')
   else Sleep(2000);
  end
 else
  begin
   if ServiceStart('MpsSvc') <> 0 then ShowMessage('Не смог запустить службу Брандмауэра Windows.')
   else Sleep(2000);
  end;

 try
  objFirewall:= CreateOLEObject('HNetCfg.FwMgr');
  objPolicy:= objFirewall.LocalPolicy.CurrentProfile;
  objPolicy.FirewallEnabled:=  STATE;
  Result:=True;
 except
  Exit(False);
 end;
end;

Procedure ExceptionsNotAllowed;
Var
  objFirewall,
  objPolicy :OleVariant;
begin
  Try
    objFirewall := CreateOLEObject('HNetCfg.FwMgr');
    objPolicy := objFirewall.LocalPolicy.CurrentProfile;
    objPolicy.ExceptionsNotAllowed := STATE
  except
  end;
end;

Procedure NotificationsDisabled;
Var
  objFirewall,
  objPolicy :OleVariant;
begin
  Try
    objFirewall := CreateOLEObject('HNetCfg.FwMgr');
    objPolicy := objFirewall.LocalPolicy.CurrentProfile;
    objPolicy.NotificationsDisabled := STATE
  except
  end;
end;

Procedure UnicastResponsestoMulticastBroadcastDisabled;
Var
  objFirewall,
  objPolicy :OleVariant;
begin
  Try
    objFirewall := CreateOLEObject('HNetCfg.FwMgr');
    objPolicy := objFirewall.LocalPolicy.CurrentProfile;
    objPolicy.UnicastResponsestoMulticastBroadcastDisabled := STATE
  except
  end;
end;

Procedure RemoteAdministrationEnabled;
Var
  objFirewall,
  objPolicy,
  objAdminSettings:OleVariant;
begin
  Try
    objFirewall := CreateOLEObject('HNetCfg.FwMgr');
    objPolicy := objFirewall.LocalPolicy.CurrentProfile;
    objAdminSettings := objPolicy.RemoteAdminSettings;
    objAdminSettings.Enabled := STATE;
  except
  end;
end;

Procedure AllowInboundEchoRequest;
Var
  objFirewall,
  objPolicy,
  objICMPSettings:OleVariant;
begin
  Try
    objFirewall := CreateOLEObject('HNetCfg.FwMgr');
    objPolicy := objFirewall.LocalPolicy.CurrentProfile;
    objICMPSettings := objPolicy.ICMPSettings;
    objICMPSettings.AllowInboundEchoRequest:=STATE;
  except
  end;
end;

Procedure AllowInboundMaskRequest;
Var
  objFirewall,
  objPolicy,
  objICMPSettings:OleVariant;
begin
  Try
    objFirewall := CreateOLEObject('HNetCfg.FwMgr');
    objPolicy := objFirewall.LocalPolicy.CurrentProfile;
    objICMPSettings := objPolicy.ICMPSettings;
    objICMPSettings.AllowInboundMaskRequest:=STATE;
  except
  end;
end;

Procedure AllowInboundRouterRequest;
Var
  objFirewall,
  objPolicy,
  objICMPSettings:OleVariant;
begin
  Try
    objFirewall := CreateOLEObject('HNetCfg.FwMgr');
    objPolicy := objFirewall.LocalPolicy.CurrentProfile;
    objICMPSettings := objPolicy.ICMPSettings;
    objICMPSettings.AllowInboundRouterRequest:=STATE;
  except
  end;
end;

Procedure AllowInboundTimestampRequest;
Var
  objFirewall,
  objPolicy,
  objICMPSettings:OleVariant;
begin
  Try
    objFirewall := CreateOLEObject('HNetCfg.FwMgr');
    objPolicy := objFirewall.LocalPolicy.CurrentProfile;
    objICMPSettings := objPolicy.ICMPSettings;
    objICMPSettings.AllowInboundTimestampRequest:=STATE;
  except
  end;
end;

Procedure AllowOutboundDestinationUnreachable;
Var
  objFirewall,
  objPolicy,
  objICMPSettings:OleVariant;
begin
  Try
    objFirewall := CreateOLEObject('HNetCfg.FwMgr');
    objPolicy := objFirewall.LocalPolicy.CurrentProfile;
    objICMPSettings := objPolicy.ICMPSettings;
    objICMPSettings.AllowOutboundDestinationUnreachable:=STATE;
  except
  end;
end;

Procedure AllowOutboundPacketTooBig;
Var
  objFirewall,
  objPolicy,
  objICMPSettings:OleVariant;
begin
  Try
    objFirewall := CreateOLEObject('HNetCfg.FwMgr');
    objPolicy := objFirewall.LocalPolicy.CurrentProfile;
    objICMPSettings := objPolicy.ICMPSettings;
    objICMPSettings.AllowOutboundPacketTooBig:=STATE;
  except
  end;
end;

procedure AllowOutboundParameterProblem;
var objFirewall,
    objPolicy,
    objICMPSettings:OleVariant;
begin
 try
  objFirewall:=CreateOLEObject('HNetCfg.FwMgr');
  objPolicy:=objFirewall.LocalPolicy.CurrentProfile;
  objICMPSettings:=objPolicy.ICMPSettings;
  objICMPSettings.AllowOutboundParameterProblem:=STATE;
 except
 end;
end;

procedure AllowOutboundSourceQuench;
var objFirewall,
    objPolicy,
    objICMPSettings:OleVariant;
begin
 try
  objFirewall:=CreateOLEObject('HNetCfg.FwMgr');
  objPolicy:=objFirewall.LocalPolicy.CurrentProfile;
  objICMPSettings:=objPolicy.ICMPSettings;
  objICMPSettings.AllowOutboundSourceQuench:=STATE;
 except
 end;
end;

procedure AllowOutboundTimeExceeded;
var objFirewall,
    objPolicy,
    objICMPSettings:OleVariant;
begin
 try
  objFirewall:=CreateOLEObject('HNetCfg.FwMgr');
  objPolicy:=objFirewall.LocalPolicy.CurrentProfile;
  objICMPSettings:=objPolicy.ICMPSettings;
  objICMPSettings.AllowOutboundTimeExceeded:=STATE;
 except
 end;
end;

procedure AllowRedirect;
var objFirewall,
    objPolicy,
    objICMPSettings:OleVariant;
begin
 try
  objFirewall:=CreateOLEObject('HNetCfg.FwMgr');
  objPolicy:=objFirewall.LocalPolicy.CurrentProfile;
  objICMPSettings:=objPolicy.ICMPSettings;
  objICMPSettings.AllowRedirect:=STATE;
 except
 end;
end;

function FW_PROTOCOL(Value:Integer):string;
begin
 case Value of
  NET_FW_IP_PROTOCOL_UDP:Result:='UDP';
  NET_FW_IP_PROTOCOL_TCP:Result:='TCP';
 else
  Result:='';
 end;
end;

procedure AddAnAuthorizedApplication(ApplicationName:string; ApplicationPathAndExe:string);
var objFirewall,
    objPolicy,
    objApplication,
    colApplications:OleVariant;
begin
 try
  objFirewall:=CreateOLEObject('HNetCfg.FwMgr');
  objPolicy:=objFirewall.LocalPolicy.CurrentProfile;

  objApplication:=CreateOLEObject('HNetCfg.FwAuthorizedApplication');
  objApplication.Name:=ApplicationName;
  objApplication.IPVersion:=NET_FW_IP_VERSION_ANY;
  objApplication.ProcessImageFileName:=ApplicationPathAndExe;
  objApplication.RemoteAddresses:='*';
  objApplication.Scope:=NET_FW_SCOPE_ALL;
  objApplication.Enabled:=VRAI;

  colApplications:=objPolicy.AuthorizedApplications;
  colApplications.Add(objApplication);
 except
 end;
end;

function DeleteAnAuthorizedApplication(ApplicationPathAndExe:string):Integer;
var objFirewall,
    objPolicy,
    colApplications:OleVariant;
begin
 Result:=0;
 try
  objFirewall:=CreateOLEObject('HNetCfg.FwMgr');
  objPolicy:=objFirewall.LocalPolicy.CurrentProfile;
  colApplications:=objPolicy.AuthorizedApplications;
  Result:=colApplications.Remove(ApplicationPathAndExe)
 except
 end;
end;

procedure RestoreTheDefaultSettings;
var objFirewall:OleVariant;
begin
 try
  objFirewall:= CreateOLEObject('HNetCfg.FwMgr');
  objFirewall.RestoreDefaults;
 except
 end;
end;

function IsApplicationAuthorized(ApplicationPathAndExe:String):Boolean;
var objFirewall,
    objPolicy,
    objApplication,
    colApplications:OleVariant;
    IEnum:IEnumVariant;
    Count:LongWord;
begin
 Result:=False;
 try
  objFirewall:=CreateOLEObject('HNetCfg.FwMgr');
  objPolicy:=objFirewall.LocalPolicy.CurrentProfile;
  colApplications:=objPolicy.AuthorizedApplications;
  IEnum:=IUnKnown(colApplications._NewEnum) as IEnumVariant;
  while IEnum.Next(1, objApplication, Count) = S_OK do
   if UpperCase(objApplication.ProcessImageFileName) = UpperCase(ApplicationPathAndExe) then Exit(True);
 except
 end;
end;

function IsApplicationAuthorizedIsActive(ApplicationPathAndExe:String):Boolean;
var objFirewall,
    objPolicy,
    objApplication,
    colApplications:OleVariant;
    IEnum:IEnumVariant;
    Count:LongWord;
begin
 Result:=False;
 try
  objFirewall:=CreateOLEObject('HNetCfg.FwMgr');
  objPolicy:=objFirewall.LocalPolicy.CurrentProfile;
  colApplications:=objPolicy.AuthorizedApplications;
  IEnum:=IUnKnown(colApplications._NewEnum) as IEnumVariant;
  while IEnum.Next(1, objApplication, Count) = S_OK do
   if UpperCase(objApplication.ProcessImageFileName) = UpperCase(ApplicationPathAndExe) then Exit(objApplication.Enabled = VRAI);
 except
 end;
end;


Procedure SetFirewall;
begin
 if IsExceptionsNotAllowed                             then ExceptionsNotAllowed(FAUX);
 if not IsNotificationsDisabled                        then NotificationsDisabled(VRAI);
 if IsUnicastResponsestoMulticastBroadcastDisabled     then UnicastResponsestoMulticastBroadcastDisabled(FAUX);
 if IsRemoteAdministrationEnabled                      then RemoteAdministrationEnabled(FAUX);
 if not IsAllowInboundEchoRequest                      then AllowInboundEchoRequest(VRAI);
end;

end.



