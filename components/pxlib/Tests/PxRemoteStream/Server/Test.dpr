program Test;

{$I ..\..\..\PxDefines.inc}

{$IFDEF DELPHI}
  {$APPTYPE CONSOLE}
{$ENDIF}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  Windows, Winsock, Classes, SysUtils,
  PxLog, 
  PxRemoteStreamServer, 
  PxRemoteStreamDefs;

begin
  SwitchLogToConsole;
  SetLogLevel(10);
  try
    TPxRemoteStreamServerThread.Create(ExtractFilePath(ParamStr(0)), '', PX_REMOTE_STREAM_PORT + 1);
  except
    on E: Exception do
    begin
      Log(E.Message);
      Halt;
    end;
  end;
  Log('Waiting for connections');
  SetLogLevel(4);
  repeat
    CheckSynchronize(1000);
  until False;
end.
