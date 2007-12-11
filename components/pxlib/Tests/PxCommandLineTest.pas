// ----------------------------------------------------------------------------
// Unit        : PxCommandLineTest.pas - a part of PxLib test suite
// Author      : Matthias Hryniszak
// Date        : 2006-02-13
// Version     : 1.0 
// Description : 
// Changes log : 2006-02-13 - initial version
// ----------------------------------------------------------------------------

unit PxCommandLineTest;

{$I ..\PxDefines.inc}

interface

uses
  Classes, SysUtils,
  TestFramework,
  PxCommandLine;
  
type
  TPxCommandLineTest = class (TTestCase)
  private
    FParams: TStrings;
    FParser: TPxCommandLineParser;
  public
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure TestBoolOption;
    procedure TestIntegerOption;
    procedure TestStringOption;
  end;

implementation

{ TPxCommandLineTest }

{ Public declarations }

procedure TPxCommandLineTest.Setup;
begin
  FParams := TStringList.Create;
  FParams.Add('-i');
  FParams.Add('123');
  FParams.Add('--integer');
  FParams.Add('123');
  FParams.Add('-b');
  FParams.Add('--bool');
  FParams.Add('-s');
  FParams.Add('string');
  FParams.Add('--string');
  FParams.Add('string');

  FParser := TPxCommandLineParser.Create(FParams);
  FParser.AddOption(TPxBoolOption.Create('b', 'bool')).Explanation := 'Boolean option';
  FParser.AddOption(TPxIntegerOption.Create('i', 'integer')).Explanation := 'Integer option';
  FParser.AddOption(TPxStringOption.Create('s', 'string')).Explanation := 'String option';
end;

procedure TPxCommandLineTest.TearDown;
begin
  FreeAndNil(FParams);
  FreeAndNil(FParser);
end;

{ Published declarations }

procedure TPxCommandLineTest.TestBoolOption;
begin
  FParser.Parse;
  Check(FParser.ByName['bool'].Value = True, 'Error: expected TRUE');
end;

procedure TPxCommandLineTest.TestIntegerOption;
begin
  FParser.Parse;
  Check(FParser.ByName['integer'].Value = 123, 'Error: expected 123');
end;

procedure TPxCommandLineTest.TestStringOption;
begin
  FParser.Parse;
  Check(FParser.ByName['string'].Value = 'string', 'Error: expected ''string'' string');
end;

initialization
  RegisterTests([TPxCommandLineTest.Suite]);

end.
