program Test;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ELSE}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
  Windows, Winsock, Classes, SysUtils,
  PxLog, PxRemoteStream, PxRemoteStreamDefs, PxProfiler;

type
  TTestObject = class (TObject)
  public
    constructor Create; virtual;
  end;

constructor TTestObject.Create;
begin
  Fail;
  Writeln('This is not displayed!');
end;

//var
//  T: String;

var
  S: TPxRemoteStream;
  T: TFileStream;
  I, FailedAt: Integer;
  Speed: Double;

begin
  FailedAt := -1;
  try
    S := TPxRemoteStream.Create('pxrs://155.169.255.110:' + IntToStr(PX_REMOTE_STREAM_PORT + 1) + '/Multimaster.db', fmCreate); // do not translate
    try
      Writeln('CONNECTED');
      Writeln('TPxRemoteStream.FileAge: ', FormatDateTime('YYYY-MM-DD HH-NN-SS', S.FileAge));
      Write('Performing stress-test...');
      for I := 0 to 50 do
      begin
        S.Size := 0;
        S.Position := 0;
        Profiler.SetItemMark('Sending');
        T := TFileStream.Create('D:\Development\Projects\Multimaster\DataGenerator\Multimaster.db', fmOpenRead);
        Speed := T.Size;
        try
          S.CopyFrom(T, T.Size);
        finally
          T.Free;
        end;
        Profiler.SetItemMark('Sending');
        Speed := (Speed / (Profiler.Items[0].LastTime * SecsPerDay)) / (1024 * 1024);
        Writeln('last time request: ', Profiler.Items[0].LastTimeStr + ', Speed: ', Speed:3:4, ' Mb/s -> ', (Speed*8):3:4, ' Mbit/s');
      end;
      Writeln('OK');
    finally
      S.Free;
    end;
  except
    on E: Exception do
    begin
      Writeln(E.Message);
      if FailedAt <> -1 then
        Writeln('Failed at ', FailedAt);
    end;
  end;
end.

