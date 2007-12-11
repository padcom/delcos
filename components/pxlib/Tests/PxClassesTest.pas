// ----------------------------------------------------------------------------
// Unit        : PxClassesTest.pas - a part of PxLib test suite
// Author      : Matthias Hryniszak
// Date        : 2006-02-13
// Version     : 1.0 
// Description : 
// Changes log : 2006-02-13 - initial version
// ----------------------------------------------------------------------------

unit PxClassesTest;

{$I ..\PxDefines.inc}

interface

uses
  Classes, SysUtils,
  TestFramework,
  PxClasses;
                  
type
  TPxCircularBufferTest = class(TTestCase)
  private
    FCircularBuffer: TPxCircularBuffer;
  public
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure TestClear;
    procedure TestReadWrite;
  end;

implementation

{ TPxCircularBufferTest }

{ Private declarations }

{ Public declarations }

procedure TPxCircularBufferTest.Setup;
begin
  FCircularBuffer := TPxCircularBuffer.Create(1024);
end;

procedure TPxCircularBufferTest.TearDown; 
begin
  FreeAndNil(FCircularBuffer);
end;

{ Published declarations }

procedure TPxCircularBufferTest.TestClear;
var
  S: String;
begin
  // test write-clear
  S := 'TEST DATA';
  FCircularBuffer.Write(S[1], Length(S));
  FCircularBuffer.Clear;
  Check(FCircularBuffer.Size = 0, 'Error: buffer is not empty');
end;

procedure TPxCircularBufferTest.TestReadWrite;
const
  TEST_DATA = 'TEST DATA TEST DATA TEST DATA TEST DATA TEST DATA TEST DATA TEST DATA';
var
  S: String;
begin
  // test write
  S := TEST_DATA;
  FCircularBuffer.Write(S[1], Length(S));
  Check(FCircularBuffer.Size = Length(TEST_DATA), 'Error: expected data length doesn''t match');
  // test read
  SetLength(S, 1024);
  SetLength(S, FCircularBuffer.Read(S[1], Length(S)));
  Check(S = TEST_DATA, 'Error: read data doesn''t match');
  Abort;
end;

initialization
  RegisterTests([TPxCircularBufferTest.Suite]);

end.
