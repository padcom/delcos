// ----------------------------------------------------------------------------
// Unit        : PxRemoteStream.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2005-02-01
// Version     : 1.0
// Description : Remote stream - client part
// Changes log : 2005-02-01 - initial version
//               2005-03-04 - added SendTimeout and RecvTimeout properties
//               2006-02-24 - added compatibility with Delphi 6
// ToDo        : Testing, comments in code.
// ----------------------------------------------------------------------------

unit PxRemoteStream;

{$I PxDefines.inc}

interface

uses
  Windows, Winsock, Classes, SysUtils,
{$IFDEF VER130}
  PxDelphi5,
{$ENDIF}  
  PxBase, PxUtils, PxResources, PxRemoteStreamDefs;

type
  TPxRemoteStream = class (TStream)
  private
    FSocket: TSocket;
    FSendTimeout: Integer;
    FRecvTimeout: Integer;
    function Open(FileName: String; Mode: Word; MakeBackup: Boolean): Boolean;
    procedure SetSendTimeout(Value: Integer);
    procedure SetRecvTimeout(Value: Integer);
  protected
    function Connect(URL: string; Mode: Word; MakeBackup: Boolean; ASendTimeout, ARecvTimeout: Integer): Boolean;
{$IFDEF VER130}
    procedure SetSize(NewSize: Integer); override;
{$ENDIF}
{$IFDEF VER140}
    procedure SetSize(const NewSize: Int64); override;
{$ENDIF}
{$IFDEF VER150}
    procedure SetSize(const NewSize: Int64); override;
{$ENDIF}
{$IFDEF FPC}
    procedure SetSize(const NewSize: Int64); override;
{$ENDIF}
  public
    constructor Create(URL: string; Mode: Word; MakeBackup: Boolean = True; ASendTimeout: Integer = -1; ARecvTimeout: Integer = -1);
    destructor Destroy; override;
    class function Delete(URL: string; MakeBackup: Boolean = True; ASendTimeout: Integer = -1; ARecvTimeout: Integer = -1): Boolean;
    function FileAge: TDateTime;
    function Read(var Buffer; Count: Longint): Longint; override;
{$IFDEF VER130}
    function Seek(Offset: Longint; Origin: Word): Longint; override;
{$ENDIF}
{$IFDEF VER140}
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
{$ENDIF}
{$IFDEF VER150}
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
{$ENDIF}
{$IFDEF FPC}
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
{$ENDIF}
    function Write(const Buffer; Count: Longint): Longint; override;
    property SendTimeout: Integer read FSendTimeout write SetSendTimeout;
    property RecvTimeout: Integer read FRecvTimeout write SetRecvTimeout;
  end;

implementation

uses
  SysConst;

{ TPxRemoteStream }

{ Private declarations }

function TPxRemoteStream.Open(FileName: String; Mode: Word; MakeBackup: Boolean): Boolean;
var
  Request: TPxRemoteStreamOpenFilePacket;
  Response: TPxRemoteStreamResponse;
begin
  Result := False;
  Request.Header.Command := PX_CMD_OPEN;
  Request.Mode := Mode;
  if MakeBackup then
    Request.Backup := 1
  else
    Request.Backup := 0;
  StrPCopy(@Request.FileName, FileName);
  Winsock.send(FSocket, Request, SizeOf(Request), 0);
  if (Winsock.recv(FSocket, Response, SizeOf(Response), 0) <> SizeOf(Response)) or (Response.Header.Command <> PX_RES_OK) then
  begin
    closesocket(FSocket);
    FSocket := TSocket(INVALID_SOCKET);
    SetLastError(Response.Header.Command);
    Exit;
  end;
  Result := True;
end;

procedure TPxRemoteStream.SetSendTimeout(Value: Integer);
begin
  FSendTimeout := SendTimeout;
  if setsockopt(FSocket, SOL_SOCKET, SO_SNDTIMEO, @SendTimeout, SizeOf(SendTimeout)) <> S_OK then
    Beep;
end;

procedure TPxRemoteStream.SetRecvTimeout(Value: Integer);
begin
  FRecvTimeout := RecvTimeout;
  if setsockopt(FSocket, SOL_SOCKET, SO_RCVTIMEO, @RecvTimeout, SizeOf(RecvTimeout)) <> S_OK then
    Beep;
end;

{ Protected declarations }

function TPxRemoteStream.Connect(URL: string; Mode: Word; MakeBackup: Boolean; ASendTimeout, ARecvTimeout: Integer): Boolean;
var
  P, Port: Integer;
  Host, FileName: string;
  Addr: TSockAddrIn;
begin
  Result := False;

  // decode URL
  P := Pos('pxrs://', LowerCase(URL));
  if P <> 1 then
    Exit;
  System.Delete(URL, 1, 7);
  P := Pos(':', URL);
  if P <> 0 then
  begin
    Host := Copy(URL, 1, P - 1);
    System.Delete(URL, 1, P);
    P := Pos('/', URL);
    if P = 0 then
      Exit;
    if not TryStrToInt(Copy(URL, 1, P - 1), Port) then
      Exit;
    System.Delete(URL, 1, P);
    FileName := URL;
  end
  else
  begin
    P := Pos('/', URL);
    if P = 0 then
      Exit;
    Host := Copy(URL, 1, P - 1);
    Port := PX_REMOTE_STREAM_PORT;
    System.Delete(URL, 1, P);
    FileName := URL;
  end;

  FillChar(Addr, SizeOf(Addr), 0);
  Addr.sin_family := AF_INET;
  Addr.sin_port := htons(Port);
  Addr.sin_addr.S_addr := inet_addr(PChar(Host));

  FSocket := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if FSocket = TSocket(INVALID_SOCKET) then
    Exit;

  if Winsock.connect(FSocket, Addr, SizeOf(Addr)) <> 0 then
  begin
    FSocket := TSocket(INVALID_SOCKET);
    Exit;
  end;

  if ASendTimeout <> -1 then
    SetSendTimeout(ASendTimeout);

  if ARecvTimeout <> -1 then
    SetRecvTimeout(ARecvTimeout);

  Result := Open(FileName, Mode, MakeBackup);
end;

{$IFDEF VER130}
procedure TPxRemoteStream.SetSize(NewSize: Integer);
{$ENDIF}
{$IFDEF VER140}
procedure TPxRemoteStream.SetSize(const NewSize: Int64);
{$ENDIF}
{$IFDEF VER150}
procedure TPxRemoteStream.SetSize(const NewSize: Int64);
{$ENDIF}
{$IFDEF FPC}
procedure TPxRemoteStream.SetSize(const NewSize: Int64);
{$ENDIF}
var
  Request: TPxRemoteStreamSetSizePacket;
  Response: TPxRemoteStreamResponse;
begin
  Request.Header.Command := PX_CMD_SET_SIZE;
  Request.NewSize := NewSize;
  Winsock.send(FSocket, Request, SizeOf(Request), 0);
  if (Winsock.recv(FSocket, Response, SizeOf(Response), 0) <> SizeOf(Response)) or (Response.Header.Command <> PX_RES_OK) then
    raise EPxRemoteStreamException.CreateResFmt(@SErrorWhileConnecting, [GetLastErrorStr]);
end;

{ Public declarations }

constructor TPxRemoteStream.Create(URL: string; Mode: Word; MakeBackup: Boolean = True; ASendTimeout: Integer = -1; ARecvTimeout: Integer = -1);
begin
  inherited Create;
  if not Connect(URL, Mode, MakeBackup, ASendTimeout, ARecvTimeout) then
    case GetLastError of
      ERROR_FILE_NOT_FOUND:
{$IFDEF VER130}
        raise EFOpenError.Create(SFileNotFound);
{$ENDIF}
{$IFDEF VER150}
        raise EFOpenError.Create(@SFileNotFound, URL);
{$ENDIF}
{$IFDEF FPC}
        raise EFOpenError.Create(SFileNotFound);
{$ENDIF}
      else
        raise EPxRemoteStreamException.CreateResFmt(@SErrorWhileSettingStreamSize, [GetLastErrorStr]);
    end;
end;

destructor TPxRemoteStream.Destroy;
var
  Request: TPxRemoteStreamReadRequestPacket;
  Response: TPxRemoteStreamReadResponsePacket;
begin
  if FSocket <> TSocket(INVALID_SOCKET) then
  begin
    Request.Header.Command := PX_CMD_CLOSE;
    Request.Count := 0;
    Winsock.send(FSocket, Request, SizeOf(Request), 0);
    if (Winsock.recv(FSocket, Response, SizeOf(Response), 0) < SizeOf(TPxRemoteStreamHeader)) or (Response.Header.Command <> PX_RES_OK) then
      raise EPxRemoteStreamException.CreateResFmt(@SErrorWhileClosingStream, [GetLastErrorStr]);
    closesocket(FSocket);
  end;
  inherited Destroy;
end;

class function TPxRemoteStream.Delete(URL: string; MakeBackup: Boolean = True; ASendTimeout: Integer = -1; ARecvTimeout: Integer = -1): Boolean;
var
  S: TSocket;
  P, Port: Integer;
  Host, FileName: string;
  Addr: TSockAddrIn;
  Request: TPxRemoteStreamDeleteFilePacket;
  Response: TPxRemoteStreamResponse;
begin
  Result := False;

  // decode URL
  P := Pos('pxrs://', LowerCase(URL));
  if P <> 1 then
    Exit;
  System.Delete(URL, 1, 7);
  P := Pos(':', URL);
  if P <> 0 then
  begin
    Host := Copy(URL, 1, P - 1);
    System.Delete(URL, 1, P);
    P := Pos('/', URL);
    if P = 0 then
      Exit;
    if not TryStrToInt(Copy(URL, 1, P - 1), Port) then
      Exit;
    System.Delete(URL, 1, P);
    FileName := URL;
  end
  else
  begin
    P := Pos('/', URL);
    if P = 0 then
      Exit;
    Host := Copy(URL, 1, P - 1);
    Port := PX_REMOTE_STREAM_PORT;
    System.Delete(URL, 1, P);
    FileName := URL;
  end;

  FillChar(Addr, SizeOf(Addr), 0);
  Addr.sin_family := AF_INET;
  Addr.sin_port := htons(Port);
  Addr.sin_addr.S_addr := inet_addr(PChar(Host));

  S := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if S = TSocket(INVALID_SOCKET) then
    Exit;

  if Winsock.connect(S, Addr, SizeOf(Addr)) <> 0 then
    Exit;

  if ASendTimeout <> -1 then
    if setsockopt(S, SOL_SOCKET, SO_SNDTIMEO, @ASendTimeout, SizeOf(ASendTimeout)) <> S_OK then
    begin
      closesocket(S);
      Exit;
    end;

  if ARecvTimeout <> -1 then
    if setsockopt(S, SOL_SOCKET, SO_RCVTIMEO, @ARecvTimeout, SizeOf(ARecvTimeout)) <> S_OK then
    begin
      closesocket(S);
      Exit;
    end;

  Request.Header.Command := PX_CMD_DELETE;
  if MakeBackup then
    Request.Backup := 1
  else
    Request.Backup := 0;
  StrPCopy(@Request.FileName, FileName);
  Winsock.send(S, Request, SizeOf(Request), 0);
  if (Winsock.recv(S, Response, SizeOf(Response), 0) <> SizeOf(Response)) or (Response.Header.Command <> PX_RES_OK) then
  begin
    closesocket(S);
    SetLastError(Response.Header.Command);
    Exit;
  end;

  closesocket(S);
  Result := True;
end;

function TPxRemoteStream.FileAge: TDateTime;
var
  Request: TPxRemoteStreamGetFileAgeRequest;
  Response: TPxRemoteStreamGetFileAgeResponse;
begin
  Request.Header.Command := PX_CMD_GET_FILE_AGE;
  Winsock.send(FSocket, Request, SizeOf(Request), 0);
  if (Winsock.recv(FSocket, Response, SizeOf(Response), 0) <> SizeOf(Response)) or (Response.Header.Command <> PX_RES_OK) then
    raise EPxRemoteStreamException.CreateResFmt(@SErrorWhileGettingFileAge, [GetLastErrorStr]);
  Result := Response.FileAge;
end;

function TPxRemoteStream.Read(var Buffer; Count: Longint): Longint;
var
  B: PByteArray;
  Request: TPxRemoteStreamReadRequestPacket;
  Response: TPxRemoteStreamReadResponsePacket;
begin
  B := @Buffer;
  Result := 0;
  Request.Header.Command := PX_CMD_READ;
  while Result <> Count do
  begin
    Request.Count := Count - Result;
    Winsock.send(FSocket, Request, SizeOf(Request), 0);
    if (Winsock.recv(FSocket, Response, SizeOf(Response), 0) < SizeOf(TPxRemoteStreamHeader) + 8 + Response.Count) or (Response.Header.Command <> PX_RES_OK) then
      raise EPxRemoteStreamException.CreateResFmt(@SErrorWhileReadingData, [GetLastErrorStr]);
    Move(Response.Data, B^, Response.Count);
    Integer(B) := Integer(B) + Integer(Response.Count);
    Result := Result + Response.Count;
    if Response.Count < SizeOf(Response.Data) then Break;
  end;
end;

{$IFDEF VER130}
function TPxRemoteStream.Seek(Offset: Longint; Origin: Word): Longint;
{$ENDIF}
{$IFDEF VER140}
function TPxRemoteStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; 
{$ENDIF}
{$IFDEF VER150}
function TPxRemoteStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; 
{$ENDIF}
{$IFDEF FPC}
function TPxRemoteStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; 
{$ENDIF}
var
  Request: TPxRemoteStreamSeekRequestPacket;
  Response: TPxRemoteStreamSeekResponsePacket;
begin
  Request.Header.Command := PX_CMD_SEEK;
  Request.Offset := Offset;
  Request.Origin := TSeekOrigin(Origin);
  Winsock.send(FSocket, Request, SizeOf(Request), 0);
  if (Winsock.recv(FSocket, Response, SizeOf(Response), 0) <> SizeOf(Response)) or (Response.Header.Command <> PX_RES_OK) then
    raise EPxRemoteStreamException.CreateResFmt(@SErrorWhileSeeking, [GetLastErrorStr]);
  Result := Response.Offset;
end;

function TPxRemoteStream.Write(const Buffer; Count: Longint): Longint;
var
  SendCount, SentCount, RecvCount: Integer;
  B: PByteArray;
  Request: TPxRemoteStreamWritePacket;
  Response: TPxRemoteStreamWriteResponse;
begin
  B := @Buffer; Result := 0;
  FillChar(Request, SizeOf(Request), 0);
  Request.Header.Command := PX_CMD_WRITE;
  while Result < Count do
  begin
    Request.Count := Min(Count - Result, SizeOf(Request.Data));
    Move(B^, Request.Data, Min(Count - Result, SizeOf(Request.Data)));

    SendCount := SizeOf(TPxRemoteStreamHeader) + 8 + Min(Count - Result, SizeOf(Request.Data));
    if SendCount > SizeOf(TPxRemoteStreamWritePacket) then
      raise EPxRemoteStreamException.CreateResFmt(@SErrorWhileWritingData, [GetLastErrorStr]);
      
    SentCount := Winsock.send(FSocket, Request, SendCount, 0);
    if SendCount <> SentCount then
      raise EPxRemoteStreamException.CreateResFmt(@SErrorWhileWritingData, [GetLastErrorStr]);
      
    FillChar(Response, SizeOf(Response), 0);
    RecvCount := Winsock.recv(FSocket, Response, SizeOf(Response), 0);
    if RecvCount = 2 then // this says, that an unidentified command had been received
      raise EPxRemoteStreamException.CreateResFmt(@SErrorWhileWritingData, [GetLastErrorStr]);
      
    if (RecvCount <> SizeOf(Response)) or (Response.Header.Command <> PX_RES_OK) then
      raise EPxRemoteStreamException.CreateResFmt(@SErrorWhileWritingData, [GetLastErrorStr]);
      
    Integer(B) := Integer(B) + Response.Count;
    Result := Result + Response.Count;
  end;
end;

end.

