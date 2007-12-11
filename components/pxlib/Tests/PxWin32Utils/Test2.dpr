program test2;

{$APPTYPE CONSOLE}

uses
  PxWin32Utils in '..\..\PxWin32Utils.pas';

var
  M: TPxSharedMemory;

begin
  M := TPxSharedMemory.Create(maOpen, 'TEST_123', 1024);
  Writeln(PInteger(M.Memory)^);
  M.Free;
end.
