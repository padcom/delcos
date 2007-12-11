// ----------------------------------------------------------------------------
// Warning: this unit requires DUnit to compile
// ----------------------------------------------------------------------------

unit PxTestRunner;

interface

uses
  Classes, SysUtils, TestFramework;

type
  TPxTestRunnerBehaviour = (bhAbort, bhContinue);

  TPxTestRunnerListener = class(TInterfacedObject, ITestListener)
  private
    FBehaviour: TPxTestRunnerBehaviour;
    FPath: TStrings;
    FError: Integer;
    function Path: String;
  public
    constructor Create(Behaviour: TPxTestRunnerBehaviour = bhAbort);
    destructor Destroy; override;
    procedure TestingStarts;
    procedure StartTest(Test: ITest);
    procedure AddSuccess(Test: ITest);
    procedure AddError(Error: TTestFailure);
    procedure AddFailure(Failure: TTestFailure);
    procedure EndTest(Test: ITest);
    procedure TestingEnds(TestResult: TTestResult);
    function  ShouldRunTest(Test: ITest): Boolean;
    procedure Status(Test: ITest; const Msg: string);
    procedure Warning(Test: ITest; const Msg: string);
  end;

procedure RunRegisteredTests(Behaviour: TPxTestRunnerBehaviour = bhAbort);

implementation

{ Private declarations }

function TPxTestRunnerListener.Path: String;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to FPath.Count - 1 do
  begin
    // Skip executable name (but not dll name)
    if (I = 0) and (FPath[I] = ExtractFileName(ParamStr(0))) then
      Continue;
    // add a "/" if not first element
    if Result <> '' then
      Result := Result + '/';
    // add element
    Result := Result + FPath[I];
  end;
end;

{ Public declarations }

constructor TPxTestRunnerListener.Create(Behaviour: TPxTestRunnerBehaviour = bhAbort);
begin
  inherited Create;
  FBehaviour := Behaviour;
  FPath := TStringList.Create;
end;

destructor TPxTestRunnerListener.Destroy;
begin
  FPath.Free;
end;

procedure TPxTestRunnerListener.TestingStarts;
begin
end;

procedure TPxTestRunnerListener.StartTest(Test: ITest);
begin
  FPath.Add(Test.Name);
end;

procedure TPxTestRunnerListener.AddSuccess(Test: ITest);
begin
end;

procedure TPxTestRunnerListener.AddError(Error: TTestFailure);
begin
  Writeln('E [', Path, '] ', Error.ThrownExceptionMessage);
  if FBehaviour = bhAbort then
    Halt(1)
  else
    Inc(FError);
end;

procedure TPxTestRunnerListener.AddFailure(Failure: TTestFailure);
begin
  Writeln('F [', Path, '] ', Failure.ThrownExceptionMessage);
  if FBehaviour = bhAbort then
    Halt(1)
  else
    Inc(FError);
end;

procedure TPxTestRunnerListener.EndTest(Test: ITest);
begin
  FPath.Delete(FPath.Count - 1);
end;

procedure TPxTestRunnerListener.TestingEnds(TestResult: TTestResult);
begin
  if FError <> 0 then
    Halt(FError);
end;

function  TPxTestRunnerListener.ShouldRunTest(Test: ITest):boolean;
begin
  Result := True;
end;

procedure TPxTestRunnerListener.Status(Test: ITest; const Msg: string);
begin
  Writeln('I [', Path, '] ', Msg);
end;

procedure TPxTestRunnerListener.Warning(Test: ITest; const Msg: string);
begin
  Writeln('W [', Path, '] ', UpperCase(Msg));
end;

{ *** }

procedure RunRegisteredTests(Behaviour: TPxTestRunnerBehaviour = bhAbort);
begin
  TestFramework.RunRegisteredTests([TPxTestRunnerListener.Create(Behaviour)]);
end;

end.
