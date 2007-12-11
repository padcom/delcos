// ----------------------------------------------------------------------------
// Unit        : PxNetwork.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2004-12-03
// Version     : 1.0
// Description : Network routines that cannot be qualified elswhere.
// Changes log : 2004-12-03 - initial version
//               2004-12-22 - moved from PxUtils to PxNetUtils
//               2005-03-05 - function GetLastErrorStr moved to PxUtils
//               2005-03-15 - added KnockPorts (port knocking client
//                            implementation).
//               2005-05-04 - added basic classes to support server-side
//                            of simple TCP connections.
//                          - changed name to PxNetwork.pas  
// ToDo        : Testing.
// ----------------------------------------------------------------------------

unit PxNetwork;

{$I PxDefines.inc}

interface

uses
  Windows, Winsock, SysUtils, Classes,
  PxBase, PxLog, PxThread, PxGetText, PxResources;

type
  TPxTCPServer = class;

  //
  // Basic TCP client connection on the server side
  //
  TPxTCPServerClient = class (TPxThread)
  private
    FServer: TPxTCPServer;
    FSocket: TSocket;
    FAddr  : TSockAddrIn;
    function GetIP: String;
    function GetPort: Word;
    procedure Close;
  protected
    // reserved - don't use
    procedure Execute; override;
    // override this method to implement application-specific
    // processing of network traffic.
    procedure Main; virtual;
    // hidden properties (publish only if neccecery)
    property Server: TPxTCPServer read FServer;
    property Socket: TSocket read FSocket;
  public
    constructor Create(AServer: TPxTCPServer; ASocket: TSocket; AAddr: TSockAddrIn); virtual;
    destructor Destroy; override;
    // this objects dispose itself automatically, but if you really must
    // do it by yourself do it using Terminate - not Destroy!
    procedure Terminate;
    property IP: String read GetIP;
    property Port: Word read GetPort;
  end;

  TPxTCPServerClientClass = class of TPxTCPServerClient;

  //
  // Mutex-synchronized list of TCP client connections. For internal use only!
  //
  TPxTCPServerClientList = class (TList)
  private
    FMutex: THandle;
    function GetItem(Index: Integer): TPxTCPServerClient;
  public
    constructor Create;
    destructor Destroy; override;
    function Add(Item: TPxTCPServerClient): Integer;
    function Remove(Item: TPxTCPServerClient): Integer;
    procedure Delete(Index: Integer);
    property Items[Index: Integer]: TPxTCPServerClient read GetItem; default;
  end;

  TPxTCPServerClientNotify = procedure (Sender: TPxTCPServerClient) of object;

  //
  // Basic (but fully implemented) TCP server with some synchronized events
  // Synchronized events require CheckSynchronize in the main thread context,
  // which is done automatically for VCL GUI applications, but console applications
  // must call it explicite. For further informations see VCL manual.
  //
  TPxTCPServer = class (TPxThread)
  private
    FClientClass: TPxTCPServerClientClass;
    FClients: TPxTCPServerClientList;
    FSocket: TSocket;
    FClient: TPxTCPServerClient;
    FSynchronize: Boolean;
    FOnClientConnected: TPxTCPServerClientNotify;
    FOnClientDisconnected: TPxTCPServerClientNotify;
    procedure DoClientConnected(Client: TPxTCPServerClient);
    procedure InternalDoClientConnected;
    procedure DoClientDisconnected(Client: TPxTCPServerClient);
    procedure InternalDoClientDisconnected;
  protected
    function CreateSocket(Port: Word): TSocket; virtual;
    procedure Execute; override;
  public
    constructor Create(APort: Word; AClientClass: TPxTCPServerClientClass; ASynchronize: Boolean = True);
    destructor Destroy; override;
    // Never call Destroy on this object - call Terminate
    procedure Terminate;
    property Clients: TPxTCPServerClientList read FClients;
    property Socket: TSocket read FSocket;
    property OnClientConnected: TPxTCPServerClientNotify read FOnClientConnected write FOnClientConnected;
    property OnClientDisconnected: TPxTCPServerClientNotify read FOnClientDisconnected write FOnClientDisconnected;
  end;

  EPxTCPServerClientListException = class (Exception);
  EPxTCPServerException = class (Exception);

// Creates a TCP socket and connect it to the specified host:port
// Returns INVALID_SOCKET if no socket is avaible or if connection
// could not have been established
function Connect(IP: String; Port: Word; SendTimeout: Integer = -1; RecvTimeout: Integer = -1; KeepAlive: Boolean = True): TSocket;

// Creates a TCP socket that is ready for receiving connections
// Returns INVALID_SOCKET if no socket is avaible or if another application
// is already listening on this socket
function CreateServer(Port: Word): TSocket;

// Client implementation of port knocking. This one works only with TCP locks.
// See http://www.zeroflux.org/knock for more details and knockd for Linux.
function KnockPorts(IP: String; Ports: array of Word): Boolean;

implementation

{ TPxTCPServerClient }

{ Private declarations }

function TPxTCPServerClient.GetIP: String;
begin
  Result := inet_ntoa(FAddr.sin_addr);
end;

function TPxTCPServerClient.GetPort: Word;
begin
  Result := ntohs(FAddr.sin_port);
end;

procedure TPxTCPServerClient.Close;
begin
  if FSocket <> INVALID_SOCKET then
  begin
    closesocket(FSocket);
    FSocket := INVALID_SOCKET;
  end;
end;

{ Protected declarations }

procedure TPxTCPServerClient.Execute;
begin
  Log('%s client connected', [ClassName]);
  if Assigned(FServer) then
    FServer.DoClientConnected(Self);
  Main;
  if Assigned(FServer) then
    FServer.DoClientDisconnected(Self);
  Log('%s client disconnected', [ClassName]);
end;

procedure TPxTCPServerClient.Main;
begin
end;

{ Public declarations }

constructor TPxTCPServerClient.Create(AServer: TPxTCPServer; ASocket: TSocket; AAddr: TSockAddrIn);
begin
  inherited Create(True);
  FreeOnTerminate := True;

  FServer := AServer;
  FSocket := ASocket;
  FAddr   := AAddr;

  if Assigned(FServer) then
    // mutex-synchronized list cares about racing conditions
    FServer.Clients.Add(Self);

  Resume;
end;

destructor TPxTCPServerClient.Destroy;
begin
  Close;
  if Assigned(FServer) then
    // mutex-synchronized list cares about racing conditions
    FServer.Clients.Remove(Self);
  inherited Destroy;
end;

procedure TPxTCPServerClient.Terminate;
begin
  inherited Terminate;
  Close;
end;

{ TPxTCPServerClientList }

{ Private declarations }

function TPxTCPServerClientList.GetItem(Index: Integer): TPxTCPServerClient;
begin
  Result := TObject(Get(Index)) as TPxTCPServerClient;
end;

{ Public declarations }

constructor TPxTCPServerClientList.Create;
begin
  inherited Create;
  FMutex := CreateMutex(nil, False, '');
end;

destructor TPxTCPServerClientList.Destroy;
begin
  CloseHandle(FMutex);
  inherited Destroy;
end;

function TPxTCPServerClientList.Add(Item: TPxTCPServerClient): Integer;
begin
  if WaitForSingleObject(FMutex, 1000) <> WAIT_OBJECT_0 then
    raise EPxTCPServerClientListException.Create('Error while aquiring mutex');
  try
    Result := inherited Add(Item);
  finally
    ReleaseMutex(FMutex);
  end;
end;

function TPxTCPServerClientList.Remove(Item: TPxTCPServerClient): Integer;
begin
  if WaitForSingleObject(FMutex, 1000) <> WAIT_OBJECT_0 then
    raise EPxTCPServerClientListException.Create('Error while aquiring mutex');
  try
    Result := IndexOf(Item);
    if Result >= 0 then
      Delete(Result);
  finally
    ReleaseMutex(FMutex);
  end;
end;

procedure TPxTCPServerClientList.Delete(Index: Integer);
begin
  if WaitForSingleObject(FMutex, 1000) <> WAIT_OBJECT_0 then
    raise EPxTCPServerClientListException.Create('Error while aquiring mutex');
  try
    inherited Delete(Index);
  finally
    ReleaseMutex(FMutex);
  end;
end;

{ TPxTCPServer }

{ Private declarations }

procedure TPxTCPServer.DoClientConnected(Client: TPxTCPServerClient);
begin
  if Assigned(FOnClientConnected) then
  begin
    FClient := Client;
    if FSynchronize then
      Synchronize(InternalDoClientConnected)
    else
      InternalDoClientConnected;
  end;
end;

procedure TPxTCPServer.InternalDoClientConnected;
begin
  FOnClientConnected(FClient);
end;

procedure TPxTCPServer.DoClientDisconnected(Client: TPxTCPServerClient);
begin
  if Assigned(FOnClientDisconnected) then
  begin
    FClient := Client;
    if FSynchronize then
      Synchronize(InternalDoClientDisconnected)
    else
      InternalDoClientDisconnected;
  end;
end;

procedure TPxTCPServer.InternalDoClientDisconnected;
begin
  FOnClientDisconnected(FClient);
end;

{ Protected declarations }

function TPxTCPServer.CreateSocket(Port: Word): TSocket;
var
  Addr: TSockAddrIn;
begin
  Result := Winsock.socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if Result = INVALID_SOCKET then
    raise EPxTCPServerException.Create(GetText(SErrorWhileCreatingServerSocket));
  FillChar(Addr, SizeOf(Addr), 0);
  Addr.sin_family := AF_INET;
  Addr.sin_port := htons(Port);
  Addr.sin_addr.S_addr := INADDR_ANY;
  if bind(Result, Addr, SizeOf(Addr)) <> 0 then
  begin
    closesocket(Result);
    raise EPxTCPServerException.Create(GetText(SErrorWhileBindingServerSocket));
  end;
  if listen(Result, 5) <> 0 then
  begin
    closesocket(Result);
    raise EPxTCPServerException.Create(GetText(SErrorWhileListeningOnServerSocket));
  end;
end;

procedure TPxTCPServer.Execute;
var
  CS: TSocket;
  CA: TSockAddrIn;
  CL: Integer;
begin
  repeat
    FillChar(CA, SizeOf(CA), 0);
    CL := SizeOf(CA);
    CS := accept(FSocket, @CA, @CL);
    if CS <> INVALID_SOCKET then
      FClientClass.Create(Self, CS, CA);
  until Terminated;
end;

{ Public declarations }

constructor TPxTCPServer.Create(APort: Word; AClientClass: TPxTCPServerClientClass; ASynchronize: Boolean = True);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FSocket := CreateSocket(APort);
  FClientClass := AClientClass;
  FClients := TPxTCPServerClientList.Create;
  FSynchronize := ASynchronize; 
  Resume;
end;

destructor TPxTCPServer.Destroy;
var
  OldCount: Integer;
begin
  closesocket(FSocket);
  FSocket := INVALID_SOCKET;
  while Clients.Count > 0 do
  begin
    OldCount := Clients.Count;
    Clients[Clients.Count - 1].Terminate;
    while Clients.Count = OldCount do Sleep(10);
  end;
  FClients.Free;
  inherited Destroy;
end;

procedure TPxTCPServer.Terminate;
begin
  inherited Terminate;
  closesocket(FSocket);
  FSocket := INVALID_SOCKET;
end;

{ *** }

function Connect(IP: String; Port: Word; SendTimeout: Integer = -1; RecvTimeout: Integer = -1; KeepAlive: Boolean = True): TSocket;
var
  Addr: TSockAddrIn;
begin
  Result := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if Result <> TSocket(INVALID_SOCKET) then
  begin
    Addr.sin_family := AF_INET;
    Addr.sin_port := ntohs(Port);
    Addr.sin_addr.S_addr := inet_addr(PChar(IP));
    if Winsock.connect(Result, Addr, SizeOf(Addr)) <> 0 then
    begin
      closesocket(Result);
      Result := TSocket(INVALID_SOCKET);
    end
    else
    begin
      if SendTimeout <> -1 then
        if setsockopt(Result, SOL_SOCKET, SO_SNDTIMEO, @SendTimeout, SizeOf(SendTimeout)) <> S_OK then
          Beep;

      if RecvTimeout <> -1 then
        if setsockopt(Result, SOL_SOCKET, SO_RCVTIMEO, @RecvTimeout, SizeOf(RecvTimeout)) <> S_OK then
          Beep;

      // enable/disable sending of keep-alive packets
      if setsockopt(Result, SOL_SOCKET, SO_KEEPALIVE, @KeepAlive, SizeOf(KeepAlive)) <> S_OK then
        Beep;
    end;
  end;
end;

function CreateServer(Port: Word): TSocket;
var
  Addr: TSockAddrIn; 
begin
  Result := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if Result <> TSocket(INVALID_SOCKET) then
  begin
    Addr.sin_family := AF_INET;
    Addr.sin_port := htons(Port);
    Addr.sin_addr.S_addr := INADDR_ANY;
    if bind(Result, Addr, SizeOf(Addr)) <> 0 then
    begin
      Result := TSocket(INVALID_SOCKET);
      Exit;
    end;
    if listen(Result, 5) <> 0 then
    begin
      Result := TSocket(INVALID_SOCKET);
      Exit;
    end;
  end;
end;

function KnockPorts(IP: String; Ports: array of Word): Boolean;
var
  A: TSockAddrIn;
  S: TSocket;
  b: Integer ;
  I: Integer;
begin
  Result := True;
  for I := 0 to Length(Ports) - 1 do
  begin
    S := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if S = TSocket(INVALID_SOCKET) then
    begin
      Result := False;
      Exit;
    end;
    B := 1;
{$IFDEF DELPHI}    
    if ioctlsocket(s, FIONBIO, b) <> 0 then
{$ENDIF}
{$IFDEF FPC}
    if ioctlsocket(s, Longint(FIONBIO), b) <> 0 then
{$ENDIF}
    begin
      Result := False;
      Exit;
    end;
    A.sin_family := AF_INET;
    A.sin_port := htons(Ports[I]);
    A.sin_addr.S_addr := inet_addr(PChar(IP));
    Winsock.connect(S, A, SizeOf(A));
    closesocket(S);
  end;
end;

{ *** }

procedure Initialize;
var
  WSAData: TWSAData;
begin
  WSAStartup($101, WSAData);
end;

procedure Finalize;
begin
  WSACleanup;
end;

initialization
  Initialize;

finalization
  Finalize;

end.

