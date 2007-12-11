program test1;

{$APPTYPE CONSOLE}

uses
  PxWin32Utils in '..\..\PxWin32Utils.pas';

var
  M: TPxSharedMemory;

begin
  M := TPxSharedMemory.Create(maCreate, 'TEST_123', 1024);
  PInteger(M.Memory)^ := 123456;
  Readln;
  M.Free;
end.
