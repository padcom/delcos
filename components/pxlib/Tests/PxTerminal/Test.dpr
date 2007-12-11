program Test;

{$APPTYPE CONSOLE}

uses
  PxTerminal;

var
  Terminal: TPxTerminal;

begin
  Terminal := TPxTerminal.Create('COM2', br19200, db8, paNone, sbOne);
  Terminal.Run;
  Terminal.Free;
end.
