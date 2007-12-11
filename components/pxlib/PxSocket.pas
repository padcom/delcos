// ----------------------------------------------------------------------------
// Unit        : PxSocket.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2005-03-29
// Version     : 1.0
// Description : System-independent socket implementation
// Changes log : 2005-03-29 - initial version
// ToDo        : - Linux port.
//               - Testing.
// ----------------------------------------------------------------------------

unit PxSocket;

{$I PxDefines.inc}

interface

uses
  Classes, SysUtils,
{$IFDEF WIN32}
  Winsock,
{$ENDIF}
  PxBase, PxThread;

type
  TPxClientSocket = class (TPxBaseObject)
  private
    FSocket: TSocket;
  public
    constructor Create(ASocket: TSocket);
    destructor Destroy; override;
  end;

  TPxTCPClientSocket = class (TPxClientSocket)
    function Send(var Data; DataSize: Integer): Integer;
    function Recv(var Buffer; BufferSize: Integer): Integer;
  end;

  TPxUDPClientSocket = class (TPxClientSocket)
    function SendTo(var Data; DataSize: Integer; Addr: TSockAddrIn; AddrSize: Integer): Integer;
    function RecvTo(var Buffer; BufferSize: Integer; var Addr: TSockAddrIn; var AddrSize: Integer): Integer;
  end;

  TPxServerSocket = class;

  TPxServerSocketClientThread = class (TPxThread)
  private
    FSocket: TPxClientSocket;
    FServer: TPxServerSocket;
  public
    constructor Create(AServer: TPxServerSocket; ASocket: TPxClientSocket);
    destructor Destroy; override;
    property Server: TPxServerSocket read FServer;
    property Socket: TPxClientSocket read FSocket;
  end;

  TPxServerSocketClientThreadClass = class of TPxServerSocketClientThread;

  TPxServerSocketClientThreadList = class (TList)
  private
    function GetItem(Index: Integer): TPxServerSocketClientThread;
  public
    property Items[Index: Integer]: TPxServerSocketClientThread read GetItem; default;
  end;

  TPxServerSocket = class (TPxThread)
  private
    FSocket: TSocket;
    FClientClass: TPxServerSocketClientThreadClass;
    FClients: TPxServerSocketClientThreadList;
  protected
    procedure Execute; override;
  public
    constructor Create(Port: Word; AClientClass: TPxServerSocketClientThreadClass);
    destructor Destroy; override;
    property Clients: TPxServerSocketClientThreadList read FClients;
  end;

implementation

uses
  PxLog;

{ TPxBaseSocket }

{ TPxClientSocket }

constructor TPxClientSocket.Create(ASocket: TSocket);
begin
  inherited Create;
  FSocket := ASocket;
end;

destructor TPxClientSocket.Destroy;
begin
  if FSocket <> INVALID_SOCKET then
    Winsock.closesocket(FSocket);
  FSocket := INVALID_SOCKET;
  inherited Destroy;
end;

{ TPxTCPClientSocket }

function TPxTCPClientSocket.Send(var Data; DataSize: Integer): Integer;
begin
  Result := Winsock.send(FSocket, Data, DataSize, 0);
end;

function TPxTCPClientSocket.Recv(var Buffer; BufferSize: Integer): Integer;
begin
  Result := Winsock.recv(FSocket, Buffer, BufferSize, 0);
end;

{ TPxUDPClientSocket }

function TPxUDPClientSocket.SendTo(var Data; DataSize: Integer; Addr: TSockAddrIn; AddrSize: Integer): Integer;
begin
  Result := Winsock.sendto(FSocket, Data, DataSize, 0, Addr, AddrSize);
end;

function TPxUDPClientSocket.RecvTo(var Buffer; BufferSize: Integer; var Addr: TSockAddrIn; var AddrSize: Integer): Integer;
begin
  Result := Winsock.recvfrom(FSocket, Buffer, BufferSize, 0, Addr, AddrSize);
end;

{ TPxServerSocketClientThread }

constructor TPxServerSocketClientThread.Create(AServer: TPxServerSocket; ASocket: TPxClientSocket);
begin
  inherited Create(True);
  FServer := AServer;
  FSocket := ASocket;
  if Assigned(Server) then
    Server.Clients.Add(Self);
  Resume;
end;

destructor TPxServerSocketClientThread.Destroy;
begin
  if Assigned(Server) then
    Server.Clients.Remove(Self);
  inherited;
end;

{ TPxServerSocketClientThreadList }

{ Private declarations }

function TPxServerSocketClientThreadList.GetItem(Index: Integer): TPxServerSocketClientThread;
begin
  Result := TObject(Get(Index)) as TPxServerSocketClientThread;
end;

{ TPxServerSocket }

{ Protected declarations }

procedure TPxServerSocket.Execute;
var
  S: TSocket;
  A: TSockAddrIn;
  L: Integer;
begin
  repeat
    L := SizeOf(A);
    FillChar(A, L, 0);
    S := accept(FSocket, @A, @L);
    if S <> INVALID_SOCKET then
      FClientClass.Create(Self, TPxTCPClientSocket.Create(S));
  until Terminated;
end;

{ Public declarations }

constructor TPxServerSocket.Create(Port: Word; AClientClass: TPxServerSocketClientThreadClass);
var
  A: TSockAddrIn;
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FSocket := Winsock.socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if FSocket = INVALID_SOCKET then
    raise Exception.Create('Error while creating server socket');
  A.sin_family := AF_INET;
  A.sin_port := htons(Port);
  A.sin_addr.S_addr := INADDR_ANY;
  if Winsock.bind(FSocket, A, SizeOf(A)) <> 0 then
  begin
    Winsock.closesocket(FSocket);
    FSocket := INVALID_SOCKET;
    raise Exception.Create('Error while binding server socket (another instance already running?)');
  end;
  if Winsock.listen(FSocket, 5) <> 0 then
    raise Exception.Create('Error while listenting on server socket');
  FClients := TPxServerSocketClientThreadList.Create;
  FClientClass := AClientClass;
  Resume;
end;

destructor TPxServerSocket.Destroy;
var
  I: Integer;
begin
  for I := FClients.Count - 1 downto 0 do
    FClients[I].Free;
  FreeAndNil(FClients);
  inherited Destroy;
end;

{ *** }

var
  Initialized: Boolean = False;

procedure Initialize;
{$IFDEF WIN32}
var
  WSAData: TWSAData;
{$ENDIF}
begin
{$IFDEF WIN32}
  if WSAStartup($101, WSAData) <> 0 then
  begin
    Log('Error while starting Winsock library');
    Halt(10);
  end;
  Initialized := True;
{$ENDIF}
end;

procedure Finalize;
begin
{$IFDEF WIN32}
  if Initialized then
    WSACleanup;
{$ENDIF}
end;

initialization
  Initialize;

finalization
  Finalize;

end.

