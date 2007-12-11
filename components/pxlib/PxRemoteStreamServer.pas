// ----------------------------------------------------------------------------
// Unit        : PxRemoteStreamServer.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2005-02-01
// Version     : 1.0
// Description : Remote stream - server part
// Changes log : 2005-02-01 - initial version
//               2005-02-14 - added logging of received commands
//               2005-02-23 - added LimitToFolder parameter with default value
//                            of empty string to limit opening of possible
//                            files to the folder where executable file resides
// ToDo        : Testing, comments in code.
// ----------------------------------------------------------------------------

unit PxRemoteStreamServer;

{$I PxDefines.inc}

interface

uses
  Windows, Winsock, Classes, SysUtils,
{$IFDEF VER130}
  PxDelphi5, FileCtrl,
{$ENDIF}  
  PxBase, PxResources, PxThread, PxLog, PxUtils, PxRemoteStreamDefs;

type
  TPxRemoteStreamServerThread = class;

  TPxRemoteStreamServerClientThread = class (TPxThread)
  private
    FServer: TPxRemoteStreamServerThread;
    FSocket: TSocket;
    FStream: TStream;
    FFileName: String;
    procedure CheckSend(Achieved, Expected: Int64);
    function GetBackupFileName(FileName: String): String;
    procedure OpenFile(Request: TPxRemoteStreamPacket);
    procedure CloseFile(Request: TPxRemoteStreamPacket);
    procedure SetSize(Request: TPxRemoteStreamPacket);
    procedure Read(Request: TPxRemoteStreamPacket);
    procedure Write(Request: TPxRemoteStreamPacket);
    procedure Seek(Request: TPxRemoteStreamPacket);
    procedure GetFileAge(Request: TPxRemoteStreamPacket);
    procedure DeleteFile(Request: TPxRemoteStreamPacket);
  protected
    procedure Execute; override;
  public
    constructor Create(Server: TPxRemoteStreamServerThread; Socket: TSocket);
    destructor Destroy; override;
  end;

  TPxRemoteStreamServerThread = class (TPxThread)
  private
    FSocket: TSocket;
    FLimitToFolder: String;
    FBackupDir: String;
  protected
    procedure Execute; override;
  public
    constructor Create(BackupDir: String; LimitToFolder: String = ''; Port: Word = PX_REMOTE_STREAM_PORT);
    destructor Destroy; override;
  end;

  EPxRemoteStreamServerException = class (EPxException);

implementation

{ TPxRemoteStreamServerClientThread }

{ Private declarations }

procedure TPxRemoteStreamServerClientThread.CheckSend(Achieved, Expected: Int64);
begin
  if Achieved <> Expected then
    raise EPxRemoteStreamServerException.CreateResFmt(@SErrorWhileSendingResponse, [Expected, Achieved, GetLastErrorStr])
end;

function TPxRemoteStreamServerClientThread.GetBackupFileName(FileName: String): String;
var
  Index: Integer;
  Dir, Base, Ext, Date: String;
begin
  // get a unique file name consisting of date and index
  Dir := ExcludeTrailingPathDelimiter(FServer.FBackupDir);
  Ext := ExtractFileExt(FileName);
  Base := Copy(ExtractFileName(FileName), 1, Length(ExtractFileName(FileName)) - Length(Ext));
  Date := FormatDateTime('YYYYMMDD', Now);
  Index := 0;
  repeat
    if Index = 0 then
      Result := Format('%s\%s-%s%s', [Dir, Base, Date, Ext])
    else
      Result := Format('%s\%s-%s-%d%s', [Dir, Base, Date, Index, Ext]);
    if FileExists(Result) then
      Inc(Index)
    else
      Break;
  until False;
end;

procedure TPxRemoteStreamServerClientThread.OpenFile(Request: TPxRemoteStreamPacket);
var
  Response: TPxRemoteStreamResponse;
begin
  if Assigned(FStream) then
    FStream.Free;

  try
    with PPxRemoteStreamOpenFilePacket(@Request)^ do
    begin
      Log(LOGLEVEL_DEBUG, 'TPxRemoteStreamServerClientThread.OpenFile(FileName=%s, Mode=%d)', [FileName, Mode]);
      FFileName := UnifyPathSeparator(FileName);
      if FServer.FLimitToFolder <> '' then
        FFileName := FServer.FLimitToFolder + FFileName;
      Log(LOGLEVEL_DEBUG, 'TPxRemoteStreamServerClientThread.OpenFile() - Requested file: %s', [FFileName]);
      if (Mode and 3 <> 0) and (Backup = 1) then
      begin
        // make sure the backup folder is there
        if not DirectoryExists(FServer.FBackupDir) then
          MkDir(FServer.FBackupDir);
        RenameFile(FFileName, GetBackupFileName(FFileName));
      end;
      FStream := TFileStream.Create(FFileName, Mode);
    end;
    Response.Header.Command := PX_RES_OK;
  except
    if GetLastError <> ERROR_SUCCESS then
      Response.Header.Command := GetLastError
    else
      Response.Header.Command := ERROR_FILE_NOT_FOUND;
  end;

  CheckSend(Winsock.send(FSocket, Response, SizeOf(Response), 0), SizeOf(Response));
end;

procedure TPxRemoteStreamServerClientThread.CloseFile(Request: TPxRemoteStreamPacket);
var
  Response: TPxRemoteStreamResponse;
begin
  Log(LOGLEVEL_DEBUG, 'TPxRemoteStreamServerClientThread.CloseFile');
  if Assigned(FStream) then
    FreeAndNil(FStream)
  else
    Log(LOGLEVEL_DEBUG, 'Warning: file has not been opened');
  Response.Header.Command := PX_RES_OK;
  CheckSend(Winsock.send(FSocket, Response, SizeOf(Response), 0), SizeOf(Response));
end;

procedure TPxRemoteStreamServerClientThread.SetSize(Request: TPxRemoteStreamPacket);
var
  Response: TPxRemoteStreamResponse;
begin
  try
    with PPxRemoteStreamSetSizePacket(@Request)^ do
    begin
      Log(LOGLEVEL_DEBUG, 'TPxRemoteStreamServerClientThread.SetSize(NewSize=%d)', [NewSize]);
      FStream.Size := NewSize;
    end;
    Response.Header.Command := PX_RES_OK;
  except
    if GetLastError <> ERROR_SUCCESS then
      Response.Header.Command := GetLastError
    else
      Response.Header.Command := ERROR_INVALID_PARAMETER;
  end;
  CheckSend(Winsock.send(FSocket, Response, SizeOf(Response), 0), SizeOf(Response));
end;

procedure TPxRemoteStreamServerClientThread.Read(Request: TPxRemoteStreamPacket);
var
  Response: TPxRemoteStreamReadResponsePacket;
begin
  try
    with PPxRemoteStreamReadRequestPacket(@Request)^ do
    begin
      Log(LOGLEVEL_DEBUG, 'TPxRemoteStreamServerClientThread.Read(Count=%d)', [Count]);
      Response.Count := FStream.Read(Response.Data, Min(SizeOf(Response.Data), Count));
    end;
    Response.Header.Command := PX_RES_OK;
  except
    if GetLastError <> ERROR_SUCCESS then
      Response.Header.Command := GetLastError
    else
      Response.Header.Command := ERROR_INVALID_PARAMETER;
  end;
  CheckSend(Winsock.send(FSocket, Response, SizeOf(Response), 0), SizeOf(Response));
end;

procedure TPxRemoteStreamServerClientThread.Write(Request: TPxRemoteStreamPacket);
var
  Response: TPxRemoteStreamWriteResponse;
begin
  try
    with PPxRemoteStreamWritePacket(@Request)^ do
    begin
      Log(LOGLEVEL_DEBUG, 'TPxRemoteStreamServerClientThread.Write(Count=%d)', [Count]);
      Response.Count := FStream.Write(Data, Count);
    end;
    Response.Header.Command := PX_RES_OK;
  except
    on E: Exception do
    begin
      if GetLastError <> ERROR_SUCCESS then
        Response.Header.Command := GetLastError
      else
        Response.Header.Command := ERROR_INVALID_PARAMETER;
      Log(LOGLEVEL_DEBUG-1, 'TPxRemoteStreamServerClientThread.Write(): %s', [E.Message]);
      Log(LOGLEVEL_DEBUG-1, 'TPxRemoteStreamServerClientThread.Write(): %s', [GetLastErrorStr]);
    end;
  end;
  CheckSend(Winsock.send(FSocket, Response, SizeOf(Response), 0), SizeOf(Response));
end;

procedure TPxRemoteStreamServerClientThread.Seek(Request: TPxRemoteStreamPacket);
var
  Response: TPxRemoteStreamSeekResponsePacket;
begin
  try
    with PPxRemoteStreamSeekRequestPacket(@Request)^ do
    begin
      Log(LOGLEVEL_DEBUG, 'TPxRemoteStreamServerClientThread.Seek(Offset=%d, Origin=%d)', [Offset, Integer(Origin)]);
{$IFDEF VER130}
      Response.Offset := FStream.Seek(Offset, Word(Origin));
{$ENDIF}
{$IFDEF VER150}
      Response.Offset := FStream.Seek(Offset, Origin);
{$ENDIF}
    end;
    Response.Header.Command := PX_RES_OK;
  except
    if GetLastError <> ERROR_SUCCESS then
      Response.Header.Command := GetLastError
    else
      Response.Header.Command := ERROR_SEEK;
  end;
  CheckSend(Winsock.send(FSocket, Response, SizeOf(Response), 0), SizeOf(Response));
end;

procedure TPxRemoteStreamServerClientThread.GetFileAge(Request: TPxRemoteStreamPacket);
var
  Response: TPxRemoteStreamGetFileAgeResponse;
begin
  Response.Header.Command := PX_RES_OK;
  Response.FileAge := FileDateToDateTime(FileAge(FFileName));
  Log(LOGLEVEL_DEBUG, 'TPxRemoteStreamServerClientThread.GetFileAge');
  CheckSend(Winsock.send(FSocket, Response, SizeOf(Response), 0), SizeOf(Response));
end;

procedure TPxRemoteStreamServerClientThread.DeleteFile(Request: TPxRemoteStreamPacket);
var
  Response: TPxRemoteStreamResponse;
begin
  try
    with PPxRemoteStreamDeleteFilePacket(@Request)^ do
    begin
      Log(LOGLEVEL_DEBUG, 'TPxRemoteStreamServerClientThread.DeleteFile(FileName=%s)', [FileName]);
      FFileName := UnifyPathSeparator(FileName);
      if FServer.FLimitToFolder <> '' then
        FFileName := FServer.FLimitToFolder + FFileName;
      Log(LOGLEVEL_DEBUG, 'TPxRemoteStreamServerClientThread.DeleteFile() - Requested file: %s', [FFileName]);
      if FileExists(FFileName) then
      begin
        if Backup = 1 then
        begin
          // make sure the backup folder is there
          if not DirectoryExists(FServer.FBackupDir) then
            MkDir(FServer.FBackupDir);
          RenameFile(FFileName, GetBackupFileName(FFileName));
        end
        else
          SysUtils.DeleteFile(FFileName);
      end
      else
      begin
        SetLastError(ERROR_FILE_NOT_FOUND);
        Abort;
      end;
    end;
    Response.Header.Command := PX_RES_OK;
  except
    if GetLastError <> ERROR_SUCCESS then
      Response.Header.Command := GetLastError
    else
      Response.Header.Command := ERROR_FILE_NOT_FOUND;
  end;

  CheckSend(Winsock.send(FSocket, Response, SizeOf(Response), 0), SizeOf(Response));
end;

{ Protected declarations }

procedure TPxRemoteStreamServerClientThread.Execute;
var
  Request: TPxRemoteStreamPacket;
  Response: TPxRemoteStreamResponse;
begin
  repeat
    if Winsock.recv(FSocket, Request, SizeOf(Request), 0) < SizeOf(TPxRemoteStreamHeader) then
      Terminate
    else
      try
        case Request.Command of
          PX_CMD_OPEN:
            OpenFile(Request);
          PX_CMD_SET_SIZE:
            SetSize(Request);
          PX_CMD_READ:
            Read(Request);
          PX_CMD_WRITE:
            Write(Request);
          PX_CMD_SEEK:
            Seek(Request);
          PX_CMD_GET_FILE_AGE:
            GetFileAge(Request);
          PX_CMD_DELETE:
            DeleteFile(Request);
          PX_CMD_CLOSE:
            CloseFile(Request);
          else
          begin
            Log(LOGLEVEL_DEBUG-1, 'TPxRemoteStreamServerClientThread.(unknown command %d)', [Request.Command]);
            Response.Header.Command := ERROR_INVALID_FUNCTION;
            CheckSend(Winsock.send(FSocket, Response, SizeOf(Response), 0), SizeOf(Response));
          end;
        end;
      except
        on E: Exception do
          Log(LOGLEVEL_DEBUG, '%s', [ExceptionToString(E, Self)]);
      end;
  until Terminated;

  Log(LOGLEVEL_DEBUG, 'TPxRemoteStreamServerClientThread - connection terminated');
end;

{ Public declarations }

constructor TPxRemoteStreamServerClientThread.Create(Server: TPxRemoteStreamServerThread; Socket: TSocket);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FServer := Server;
  FSocket := Socket;
  Resume;
end;

destructor TPxRemoteStreamServerClientThread.Destroy;
begin
  if FSocket <> TSocket(INVALID_SOCKET) then
    closesocket(FSocket);
  if Assigned(FStream) then
    FreeAndNil(FStream);
  inherited Destroy;
end;

{ TPxRemoteStreamServerThread }

{ Private declarations }

{ Protected declarations }

procedure TPxRemoteStreamServerThread.Execute;
var
  CS: TSocket;
  CA: TSockAddrIn;
  CAS: Integer;
begin
  repeat
    FillChar(CA, SizeOf(CA), 0);
    CAS := SizeOf(CA);
    CS := Winsock.accept(FSocket, @CA, @CAS);
    if CS <> TSocket(INVALID_SOCKET) then
    begin
      TPxRemoteStreamServerClientThread.Create(Self, CS);
      Log(LOGLEVEL_DEBUG, 'TPxRemoteStreamServerThread - Connection accepted from %s', [inet_ntoa(CA.sin_addr)]);
    end
    else
      Break;
  until Terminated;
end;

{ Public declarations }

constructor TPxRemoteStreamServerThread.Create(BackupDir: String; LimitToFolder: String = ''; Port: Word = PX_REMOTE_STREAM_PORT);
var
  Addr: TSockAddrIn;
begin
  inherited Create(True);
  FBackupDir := IncludeTrailingPathDelimiter(BackupDir);
  if LimitToFolder <> '' then
    FLimitToFolder := IncludeTrailingPathDelimiter(LimitToFolder)
  else
    FLimitToFolder := '';
  FSocket := Winsock.socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if FSocket = TSocket(INVALID_SOCKET) then
    raise EPxRemoteStreamServerException.CreateRes(@SErrorWhileCreatingServerSocket);

  Addr.sin_family := AF_INET;
  Addr.sin_port := htons(Port);
  Addr.sin_addr.S_addr := INADDR_ANY;
  if Winsock.bind(FSocket, Addr, SizeOf(Addr)) <> 0 then
    raise EPxRemoteStreamServerException.CreateRes(@SErrorWhileBindingServerSocket);

  if Winsock.listen(FSocket, 5) <> 0 then
    raise EPxRemoteStreamServerException.CreateRes(@SErrorWhileListeningServerSocket);

  Priority := tpHigher;
  Resume;
end;

destructor TPxRemoteStreamServerThread.Destroy;
begin
  closesocket(FSocket);
  inherited Destroy;
end;

end.

