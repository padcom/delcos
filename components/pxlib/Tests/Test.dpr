program Test;

{$APPTYPE CONSOLE}

uses
  // common units
  Classes, SysUtils,
  // DUnit engine
  TestFramework,
  PxTestRunner in 'PxTestRunner.pas',
  // units to test
  PxClassesTest in 'PxClassesTest.pas',
  PxCSVTest in 'PxCSVTest.pas',
  PxCommandLineTest in 'PxCommandLineTest.pas';

begin
  RegisterTests([
    TPxCircularBufferTest.Suite,
    TPxCSVTest.Suite,
    TPxCommandLineTest.Suite
  ]);

  RunRegisteredTests(bhContinue);
end.

