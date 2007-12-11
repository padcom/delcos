program Test;

{$APPTYPE CONSOLE}

uses
  Windows, Winsock, Classes, SysUtils,
  PxLog, PxUtils, PxNetwork, PxSocketStream;

const
  CONFIG_SERVER_PORT    = 7000;

  // commands
  CMD_SEND_CONFIG       = 1; // send configuration TO client
  CMD_RECV_CONFIG       = 2; // receive configuration FROM client
  CMD_ASK_CONFIG        = 3;

type
  TMMConfigServerRequest = packed record
    Command  : Byte;
    TimeStamp: TDateTime;
    DataSize : LongWord;
  end;

  TMMConfigServerResponse = packed record
    Response : Byte;
    TimeStamp: TDateTime;
    DataSize : LongWord;
  end;

var
  WSAData: TWSAData;
  Handle: TSocket;
  S: TPxSocketStream;
  Request: TMMConfigServerRequest;
  Response: TMMConfigServerResponse;
  Size: Integer;

begin
  WSAStartup($101, WSAData);
  try
    S := TPxSocketStream.Create('127.0.0.1', 7000);
    try
      Request.Command := CMD_ASK_CONFIG;
      Request.TimeStamp := XorDouble(Now, $FFFFFFFFFFFFFFFF);
      Request.DataSize := 0;

      Size := S.Write(Request, SizeOf(Request));
      Log('Sent %d bytes', [Size]);
      Size := S.Read(Response, SizeOf(Response));
      Log('Received %d bytes. Configuration date is %s', [Size, FormatDateTime('YYYY-MM-DD HH:NN:SS', Response.TimeStamp)]);
    finally
      S.Free;
    end;
  except
    on E: Exception do
    begin
      Log(ExceptionToString(E));
      Halt;
    end;
  end;

  Handle := Connect('127.0.0.1', 7000);
  if Handle <> INVALID_SOCKET then
  begin
    Request.Command := CMD_ASK_CONFIG;
    Request.TimeStamp := XorDouble(Now, $FFFFFFFFFFFFFFFF);
    Request.DataSize := 0;

    S := TPxSocketStream.Create(Handle);
    Size := S.Write(Request, SizeOf(Request));
    Log('Sent %d bytes', [Size]);
    Size := S.Read(Response, SizeOf(Response));
    Log('Received %d bytes. Configuration date is %s', [Size, FormatDateTime('YYYY-MM-DD HH:NN:SS', Response.TimeStamp)]);
    S.Free;
    closesocket(Handle);
  end;

  WSACleanup;
end.
