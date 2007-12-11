program Test;

{$APPTYPE CONSOLE}

uses
  Windows,
  Winsock,
  PxNetwork;

type
  TTestClient = class (TPxTCPServerClient)
  protected
    procedure Main; override;
  end;

  TEvents = class (TObject)
    class procedure ClientConnected(Client: TPxTCPServerClient);
    class procedure ClientDisconnected(Client: TPxTCPServerClient);
  end;

{ TTestClient }

procedure TTestClient.Main;
var
  C: Char;
  L: Integer;
begin
  repeat
    L := recv(Socket, C, SizeOf(C), 0);
    if L <> SizeOf(C) then
      Terminate
    else
      send(Socket, C, L, 0);
  until Terminated;
end;

{ TEvents }

class procedure TEvents.ClientConnected(Client: TPxTCPServerClient);
begin
  Writeln(Client.IP, ' connected');
end;

class procedure TEvents.ClientDisconnected(Client: TPxTCPServerClient);
begin
  Writeln(Client.IP, ' disconnected');
end;

var
  S: TPxTCPServer;

begin
  S := TPxTCPServer.Create(10000, TTestClient, False);
  try
    S.OnClientConnected := TEvents.ClientConnected;
    S.OnClientDisconnected := TEvents.ClientDisconnected;
    Write('Server running - press Enter to terminate...');
    Readln;
  finally
    S.Terminate;
  end;
end.
