program Test;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  PxCSV;

var
  S: String = 'value1;value2;value3';

begin
  Writeln(CSVGetData(S, 0), ' - ', CSVGetData(S, 1), ' - ', CSVGetData(S, 2));
  Writeln;
  Writeln(CSVSetData('', 0, 'TEST VALUE'));
  Writeln(CSVSetData('', 1, 'TEST VALUE'));
  Writeln(CSVSetData('', 2, 'TEST VALUE'));
end.
