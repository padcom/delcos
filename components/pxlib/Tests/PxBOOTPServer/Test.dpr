program Test;

{$APPTYPE CONSOLE}

uses
  Classes, SysUtils,
  PxBOOTPServer;

type
  TBOOTPServer = class(TPxBOOTPServer)
  protected
    function GetClientInfo(MAC: String; var IP, Netmask, Gateway: String): Boolean; override;
  end;

{ TBOOTPServer }

{ Protected declarations }

function TBOOTPServer.GetClientInfo(MAC: String; var IP, Netmask, Gateway: String): Boolean;
begin
  Result := inherited GetClientInfo(MAC, IP, Netmask, Gateway);
end;

var
  S: TBOOTPServer;

begin
  S := TBOOTPServer.Create;
  repeat
    CheckSynchronize(100);
  until S.Terminated;
  FreeAndNil(S);                                                     
end.

