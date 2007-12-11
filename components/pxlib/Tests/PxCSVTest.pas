// ----------------------------------------------------------------------------
// Unit        : PxCSVTest.pas - a part of PxLib test suite
// Author      : Matthias Hryniszak
// Date        : 2006-02-13
// Version     : 1.0 
// Description : 
// Changes log : 2006-02-13 - initial version
// ----------------------------------------------------------------------------

unit PxCSVTest;

{$I ..\PxDefines.inc}

interface

uses
  Classes, SysUtils,
  TestFramework,
  PxCSV;
  
type
  TPxCSVTest = class (TTestCase)
  published
    procedure TestGetData;
    procedure TestGetDataInt;
    procedure TestGetDataUInt;
    procedure TestGetDataInt64;
    procedure TestSetData;
    procedure TestGetColumnCount;
  end;

implementation

{ TPxCSVTest }

{ Published declarations }

procedure TPxCSVTest.TestGetData;
begin
  // check empty string
  Check(CSVGetData('', 0) = '', 'Error: expected empty string');
  Check(CSVGetData('', 1) = '', 'Error: expected empty string');
  Check(CSVGetData('', 2) = '', 'Error: expected empty string');
  // check one-column string
  Check(CSVGetData('data', 0) = 'data', 'Error: expected ''data'' string');
  Check(CSVGetData('data', 1) = '', 'Error: expected empty string');
  Check(CSVGetData('data', 2) = '', 'Error: expected empty string');
  // check two-column string
  Check(CSVGetData('data1;data2', 0) = 'data1', 'Error: expected ''data1'' string');
  Check(CSVGetData('data1;data2', 1) = 'data2', 'Error: expected ''data2'' string');
  Check(CSVGetData('data1;data2', 2) = '', 'Error: expected empty string');
  // check three-column string
  Check(CSVGetData('data1;data2;data3', 0) = 'data1', 'Error: expected ''data1'' string');
  Check(CSVGetData('data1;data2;data3', 1) = 'data2', 'Error: expected ''data2'' string');
  Check(CSVGetData('data1;data2;data3', 2) = 'data3', 'Error: expected ''data2'' empty string');
  Check(CSVGetData('data1;data2;data3', 3) = '', 'Error: expected empty string');
  Abort;
end;

procedure TPxCSVTest.TestGetDataInt;
begin
  Check(CSVGetDataInt('', 0) = 0, 'Error: expected 0');
  Check(CSVGetDataInt('123', 0) = 123, 'Error: expected 123');
  Check(CSVGetDataInt('123.456', 0) = 0, 'Error: expected 0');
  Abort;
end;

procedure TPxCSVTest.TestGetDataUInt;
begin
  Check(CSVGetDataUInt('', 0) = 0, 'Error: expected 0');
  Check(CSVGetDataUInt('-123', 0) = Longword(-123), 'Error: expected Longword(-123)');
  Check(CSVGetDataUInt('-123.456', 0) = 0, 'Error: expected 0');
  Abort;
end;

procedure TPxCSVTest.TestGetDataInt64;
begin
  Check(CSVGetDataInt64('', 0) = 0, 'Error: expected 0');
  Check(CSVGetDataInt64('123456789123456789', 0) = 123456789123456789, 'Error: expected 123456789123456789');
  Check(CSVGetDataInt64('123456789123456789.123', 0) = 0, 'Error: expected 0');
end;

procedure TPxCSVTest.TestSetData;
var
  S: String;
begin
  S := CSVSetData('', 0, '123');
  Check(S = '123', 'Error: expected ''123'' string');
  S := CSVSetData('', 1, '123');
  Check(S = ';123', 'Error: expected '';123'' string');
  S := CSVSetData('', 2, '123');
  Check(S = ';;123', 'Error: expected '';123'' string');
  S := CSVSetData('1;2;3;4;5;6;', 2, '123');
  Check(S = '1;2;123;4;5;6;', 'Error: expected ''1;2;123;4;5;6;'' string');
end;

procedure TPxCSVTest.TestGetColumnCount;
begin
  Check(CSVGetColumnCount('') = 0, 'Error expected 0 columns');
  Check(CSVGetColumnCount(';') = 2, 'Error expected 2 column');
  Check(CSVGetColumnCount('1;') = 2, 'Error expected 2 column');
  Check(CSVGetColumnCount(';1') = 2, 'Error expected 2 column');
  Check(CSVGetColumnCount('1;1') = 2, 'Error expected 2 column');
  Check(CSVGetColumnCount(';;') = 3, 'Error expected 3 column');
  Check(CSVGetColumnCount('1;;') = 3, 'Error expected 3 column');
  Check(CSVGetColumnCount(';1;') = 3, 'Error expected 3 column');
  Check(CSVGetColumnCount(';;1') = 3, 'Error expected 3 column');
  Check(CSVGetColumnCount('1;1;') = 3, 'Error expected 3 column');
  Check(CSVGetColumnCount(';1;1') = 3, 'Error expected 3 column');
  Check(CSVGetColumnCount('1;;1') = 3, 'Error expected 3 column');
  Check(CSVGetColumnCount('1;1;1') = 3, 'Error expected 3 column');
end;

initialization
  RegisterTests([TPxCSVTest.Suite]);

end.
