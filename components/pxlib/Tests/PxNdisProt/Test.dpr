program Test;

{$APPTYPE CONSOLE}

uses
  PxNdisProt;

var
  H: THandle;
  P: TETHPacket;
  C: Integer;

const
  broadcast: TETHAddress = (255, 255, 255, 255, 255, 255);

begin
  H := NdisProtOpen('\DEVICE\{18630303-DC8A-4408-87A0-3907C1A2E389}');
  repeat
    if NdisProtWaitForData(H) then
    begin
      C := NdisProtReadData(H, P);
      if (C > 0) and (P.Header.Source[1]=$50) and (P.Header.Protocol = $0800) and (PIPFrame(@P.Data)^.Protocol = 17) then
        NdisProtDumpFrame(P, C, False);
    end;
  until False;
  NdisProtClose(H);
end.

