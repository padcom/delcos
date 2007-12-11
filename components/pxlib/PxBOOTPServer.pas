// ----------------------------------------------------------------------------
// Unit        : PxBOOTPServer.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2005-03-30
// Version     : 1.0
// Description : A BOOTP server for use with microcontrollers.
//               Default client port is 68 and default server port is 67. To
//               change the default values create a file bootp.conf and in
//               section [General] set ClientPort and ServerPort values.
//               In section [Hosts] host configuration can be stored. Every
//               host configuration is described in form
//                 MAC_ADDRESS=IP|NETMASK|DEFAULT_GW
//               where
//                 MAC_ADDRESS - MAC address (hardware address)
//                 IP          - IP address
//                 NETMASK     - Netmask
//                 DEFAULT_GW  - Default gateway
//               To provide additional/different configuration kinds simply
//               override the GetClientInfo() protected method and return true
//               if the request has been successfully processed. If you call the
//               inherited method you can use the build-in system to retrieve
//               client configuration.
// Changes log : 2005-03-30 - initial version
// ToDo        : Testing.
// ----------------------------------------------------------------------------

unit PxBOOTPServer;

{$I PxDefines.inc}

interface

uses
  Windows, Classes, SysUtils, IniFiles, Winsock,
  PxBase, PxLog, PxThread;

const
  DEFAULT_SERVER_PORT     = 67; // server responds to this port with replies
  DEFAULT_CLIENT_PORT     = 68; // client sends to this port requests

type
  UINT8 = Byte;
  UINT16 = Word;
  UINT32 = Cardinal;

  TPxBOOTPEntry = class (TObject)
  private
    FMAC: String;
    FIP: String;
    FNetmask: String;
    FGateway: String;
  public
    constructor Create(AMAC, AIP, ANetmask, AGateway: String);
    class function ParseConfigParams(Config: String; var IP, Netmask, Gateway: String): Boolean;
    property MAC: String read FMAC;
    property IP : String read FIP;
    property Netmask: String read FNetmask;
    property Gateway: String read FGateway;
  end;

  TPxBOOTPEntries = class (TList)
  private
    function GetItem(Index: Integer): TPxBOOTPEntry;
  public
    constructor Create;
    property Items[Index: Integer]: TPxBOOTPEntry read GetItem; default;
  end;

  TPxBOOTPServer = class (TPxThread)
  private
    FServerPort: Word;
    FClientPort: Word;
    FServerSocket: TSocket;
    FClientSocket: TSocket;
    FEntries: TPxBOOTPEntries;
  protected
    function GetClientInfo(MAC: String; var IP, Netmask, Gateway: String): Boolean; virtual;
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Terminate;
    property ServerPort: Word read FServerPort write FServerPort;
    property ClientPort: Word read FClientPort write FClientPort;
    property Entries: TPxBOOTPEntries read FEntries;
  end;

function GetLocalIPAddress: LongWord;

implementation

const
  BOOTP_REQUEST           = 1;
  BOOTP_REPLY             = 2;
  BOOTP_RESET             = 255;

  BOOTP_HTYPE_ETHERNET    = 1;
  BOOTP_HWLEN_ETHERNET    = 6;

  BOOTP_OPTION_SUBNETMASK = 1;
  BOOTP_OPTION_DEFGW      = 3;
  BOOTP_OPTION_CLIENT     = 5;

function GetLocalIPAddress: LongWord;
  function LookupHostAddr(const hn: string): String;
  var
    h: PHostEnt;
  begin
    Result := '';
    if hn <> '' then
    begin
      if hn[1] in ['0'..'9'] then
      begin
        if inet_addr(pchar(hn)) <> INADDR_NONE then
          Result := hn;
      end
      else
      begin
        h := gethostbyname(PChar(hn));
        if h <> nil then
          with h^ do
            Result := Format('%d.%d.%d.%d', [Ord(h_addr^[0]), Ord(h_addr^[1]), Ord(h_addr^[2]), Ord(h_addr^[3])]);
      end;
    end
    else Result := '0.0.0.0';
  end;
  function LocalHostName: String;
  var
    Name: array[0..255] of Char;
  begin
    Result := '';
    if gethostname(name, SizeOf(name)) = 0 then
      Result := Name;
  end;
begin
  Result := inet_addr(PChar(LookupHostAddr(LocalHostName)));
end;

type
  // taken from rfc951.txt; r - retrived only, w - sent only, x - retrived and sent
  TBOOTPData = packed record
    // awaited: BOOTP_REPLY
{x} op      : UINT8;                      // packet op code / message type.
                                          // 1 = BOOTREQUEST, 2 = BOOTREPLY
    // awaited: BOOTP_HTYPE_ETHERNET
{x} htype   : UINT8;                      // hardware address type, see ARP section in "Assigned Numbers" RFC.
                                          // '1' = 10mb ethernet
    // awaited: BOOTP_HWLEN_ETHERNET
{x} hlen    : UINT8;                      // hardware address length (eg '6' for 10mb ethernet).
    // skipped
{w} hops    : UINT8;                      // client sets to zero, optionally used by gateways in cross-gateway booting.
    // awaited: $CA0332F1
{x} xid     : UINT32;                     // transaction ID, a random number, used to match this boot request with the responses it generates.
    // skipped
{w} secs    : UINT16;                     // filled in by client, seconds elapsed since client started trying to boot.
    // skipped
    unused  : UINT16;                     // unused
    // skipped
    ciaddr  : UINT32;                     // client IP address; filled in by client in bootrequest if known.
    // awaited: IP ADDRESS
{r} yiaddr  : UINT32;                     // 'your' (client) IP address; filled by server if client doesn't know its own address (ciaddr was 0).
    // skipped
    siaddr  : UINT32;                     // server IP address; returned in bootreply by server.
    // skipped
    giaddr  : UINT32;                     // gateway IP address, used in optional cross-gateway booting.
    // awaited: Hardware address - do not change and it will be OK !
{x} chaddr  : array[0..15] of UINT8;      // client hardware address, filled in by client.
    // skipped
    sname   : array[0..63] of UINT8;      // optional server host name, null terminated string.
    // skipped
    filename: array[0..127] of UINT8;     // boot file name, null terminated string; 'generic' name or null in bootrequest,
                                          // fully qualified directory-path name in bootreply.
    case Integer of
      0: (
        vend: array[0..63] of UINT8;      // optional vendor-specific area, e.g. could be hardware type/serial on request, or 'capability' / remote
      );                                  // file system handle on reply. This info may be set aside for use by a third phase bootstrap or kernel.
      1: (
{r}     subnet: packed record
          op    : UINT8;                  // BOOTP_OPTION_SUBNETMASK (1)
          size  : UINT8;                  // 4
          snmask: UINT32;                 // subnet mask
        end;
{r}     gateway: packed record
          op    : UINT8;                  // BOOTP_OPTION_DEFGW (3)
          size  : UINT8;                  // 4
          gw    : UINT32;                 // default gateway
        end;
{r}     client: packed record
          op    : UINT8;                  // BOOTP_OPTION_CLIENT (3)
          size  : UINT8;                  // 4
          gw    : UINT32;                 // default client to send data to
        end;
      );
  end;

{ TPxBOOTPEntry }

constructor TPxBOOTPEntry.Create(AMAC, AIP, ANetmask, AGateway: String);
begin
  inherited Create;
  FMAC := AMAC;
  FIP := AIP;
  FNetmask := ANetmask;
  FGateway := AGateway;
  if (MAC = '') or (IP = '') or (Netmask = '') or (Gateway = '') then Fail;
end;

class function TPxBOOTPEntry.ParseConfigParams(Config: String; var IP, Netmask, Gateway: String): Boolean;
var
  P: Integer;
begin
  Result := True;

  P := Pos('|', Config);
  if P <> 0 then
  begin
    IP := Copy(Config, 1, P - 1);
    Delete(Config, 1, P);
  end
  else
    Result := False;

  P := Pos('|', Config);
  if P <> 0 then
  begin
    Netmask := Copy(Config, 1, P - 1);
    Delete(Config, 1, P);
  end
  else
    Result := False;

  if Config <> '' then
    Gateway := Config
  else
    Result := False;
end;

{ TPxBOOTPEntries }

{ Private declarations }

function TPxBOOTPEntries.GetItem(Index: Integer): TPxBOOTPEntry;
begin
  Result := TObject(Get(Index)) as TPxBOOTPEntry;
end;

{ Public declarations }

constructor TPxBOOTPEntries.Create;
var
  I: Integer;
  IniFile: TIniFile;
  Entries: TStrings;
  Entry: TPxBOOTPEntry;
  IP, Netmask, Gateway: String;
begin
  inherited Create;
  Entries := TStringList.Create;
  try
    IniFile := TIniFile.Create(ChangeFileExt(ParamStr(0), '.conf'));
    try
      IniFile.ReadSection('hosts', Entries);

      for I := 0 to Entries.Count - 1 do
        if TPxBOOTPEntry.ParseConfigParams(IniFile.ReadString('hosts', Entries[I], ''), IP, Netmask, Gateway) then
        begin
          Entry := TPxBOOTPEntry.Create(Entries[I], IP, Netmask, Gateway);
          if Assigned(Entry) then
            Add(Entry);
        end;
    finally
      IniFile.Free;
    end;
  finally
    Entries.Free;
  end;
end;

{ TPxBOOTPServer }

{ Private declarations }

{ Protected declarations }

function GetThisServerIP: String;
  function LookupHostAddr(const hn: string): String;
  var
    h: PHostEnt;
  begin
    Result := '';
    if hn <> '' then
    begin
      if hn[1] in ['0'..'9'] then
      begin
        if inet_addr(pchar(hn)) <> INADDR_NONE then
          Result := hn;
      end
      else
      begin
        h := gethostbyname(pchar(hn));
        if h <> nil then
          Result := format('%d.%d.%d.%d', [ord(h^.h_addr^[0]), ord(h^.h_addr^[1]), ord(h^.h_addr^[2]), ord(h^.h_addr^[3])]);
      end;
    end
    else Result := '0.0.0.0';
  end;
  function LocalHostName: String;
  var
    name: array[0..255] of char;
  begin
    Result := '';
    if gethostname(name, sizeof(name)) = 0 then
      Result := name;
  end;
  function LocalHostAddr: String;
  begin
    Result := LookupHostAddr(LocalHostName);
  end;
begin
  Result := LocalHostAddr;
end;

function GetMACAddressFromBOOTPPacket(bootp_packet: TBOOTPData): String;
begin
  Result := Format('%.2X:%.2X:%.2X:%.2X:%.2X:%.2X', [
    bootp_packet.chaddr[0],
    bootp_packet.chaddr[1],
    bootp_packet.chaddr[2],
    bootp_packet.chaddr[3],
    bootp_packet.chaddr[4],
    bootp_packet.chaddr[5]
  ]);
end;

function TPxBOOTPServer.GetClientInfo(MAC: String; var IP, Netmask, Gateway: String): Boolean;
var
  I: Integer;
  Entry: TPxBOOTPEntry;
begin
  Entry := nil;
  for I := 0 to Entries.Count - 1 do
  begin
    Entry := Entries[I];
    if Entry.MAC = MAC then
      Break
    else
      Entry := nil;
  end;
  if Assigned(Entry) then
  begin
    IP := Entry.IP;
    Netmask := Entry.IP;
    Gateway := Entry.IP;
    Result := IP <> '';
  end
  else Result := False;
end;

procedure TPxBOOTPServer.Execute;
var
  Addr: sockaddr_in;
  AddrLen, Count: Integer;
  FDRead: TFDSet;
  Time: TTimeVal;
  bootp_packet: TBOOTPData;
  LogMessage: String;
  ClientMAC, ClientIP, ClientNetmask, ClientGateway: String;
begin
  Log('BOOTP server started successfully');
  while not Terminated do
  begin
    AddrLen := SizeOf(Addr);
    FD_ZERO(FDRead);
    FD_SET(FServerSocket, FDRead);
    Time.tv_sec := 1;
    Time.tv_usec := 1000;
    case Select(0, @FDRead, nil, nil, @Time) of
      1:
      begin
        FillChar(Addr, SizeOf(Addr), 0);
        Count := recvfrom(FServerSocket, bootp_packet, SizeOf(bootp_packet), 0, Addr, AddrLen);
        if Count > 0 then
        begin
          ClientMAC := GetMACAddressFromBOOTPPacket(bootp_packet);
          LogMessage := 'Received BOOTP request from ' + ClientMAC + '...';
          if GetClientInfo(ClientMAC, ClientIP, ClientNetmask, ClientGateway) then
          begin
            LogMessage := LogMessage + 'Responding with IP=' + ClientIP + '...';
            bootp_packet.op := BOOTP_REPLY;
            bootp_packet.yiaddr := inet_addr(PChar(ClientIP));
            bootp_packet.subnet.op := BOOTP_OPTION_SUBNETMASK;
            bootp_packet.subnet.size := 4;
            bootp_packet.subnet.snmask := inet_addr(PChar(ClientNetmask));
            bootp_packet.gateway.op := BOOTP_OPTION_DEFGW;
            bootp_packet.gateway.size := 4;
            bootp_packet.gateway.gw := inet_addr(PChar(ClientGateway));
            bootp_packet.client.op := BOOTP_OPTION_CLIENT;
            bootp_packet.client.size := 4;
            bootp_packet.client.gw := GetLocalIPAddress;
            Addr.sin_addr.S_addr := INADDR_BROADCAST;
            sendto(FClientSocket, bootp_packet, SizeOf(bootp_packet), 0, Addr, AddrLen);
            LogMessage := LogMessage + 'OK';
          end
          else
            LogMessage := LogMessage + 'Host not configured';
          Log(LogMessage);
        end;
      end;
    end;
    Sleep(100);
  end;
  Log('BOOTP server terminated.');
end;

{ Public declarations }

constructor TPxBOOTPServer.Create;
var
  Addr: sockaddr_in;
  Opt : BOOL;
  ConfigFile: TIniFile;
begin
  inherited Create(True);

  Log('BOOTP server is starting...');

  FEntries := TPxBOOTPEntries.Create;
  
  ConfigFile := TIniFile.Create(ChangeFileExt(ParamStr(0), '.conf'));
  FServerPort := ConfigFile.ReadInteger('General', 'ServerPort', DEFAULT_SERVER_PORT);
  FClientPort := ConfigFile.ReadInteger('General', 'ClientPort', DEFAULT_CLIENT_PORT);
  ConfigFile.Free;

  // server socket
  FServerSocket := socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
  if FServerSocket = INVALID_SOCKET then
  begin
    Log('Error creating server socket for BOOTP server.');
    Fail;
  end;
  // bind the server socket so that it can receive packets on a specified port
  Addr.sin_family := AF_INET;
  Addr.sin_port := htons(ServerPort);
  Addr.sin_addr.S_addr := INADDR_ANY;
  if bind(FServerSocket, Addr, SizeOf(Addr)) = SOCKET_ERROR then
  begin
    Log('Error binding server socket for BOOTP server (another instance already running ?).');
    Fail;
  end;
  // set the SOL_SOCKET -> SO_BROADCAST option to TRUE so that the socket can send/receive broadcast messages

  // client socket
  FClientSocket := socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
  if FClientSocket = INVALID_SOCKET then
  begin
    Log('Error creating client socket for BOOTP server.');
    Fail;
  end;
  // bind the server socket so that it can receive packets on a specified port
  Addr.sin_family := AF_INET;
  Addr.sin_port := htons(ClientPort);
  Addr.sin_addr.S_addr := INADDR_ANY;
  if bind(FClientSocket, Addr, SizeOf(Addr)) = SOCKET_ERROR then
  begin
    Log('Error binding client socket for BOOTP server (another instance already running ?).');
    Fail;
  end;
  // set the SOL_SOCKET -> SO_BROADCAST option to TRUE so that the socket can send/receive broadcast messages
  Opt := True;
  if setsockopt(FClientSocket, SOL_SOCKET, SO_BROADCAST, @Opt, SizeOf(Opt)) = SOCKET_ERROR then
  begin
    Log('Error setting SO_BROADCAST flag for BOOTP client socket.');
    Fail;
  end;

  Resume;
end;

destructor TPxBOOTPServer.Destroy;
begin
  inherited Destroy;
end;

procedure TPxBOOTPServer.Terminate;
begin
  inherited Terminate;
  // close socket (implies an error on server socket, but that is OK !)
  closesocket(FServerSocket);
end;

{ *** }

procedure Initialize;
var
  WSAData: TWSAData;
begin
  WSAStartup($202, WSAData);
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
