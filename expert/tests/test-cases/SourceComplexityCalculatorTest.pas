unit SourceComplexityCalculatorTest;

interface

uses
  Classes, SysUtils, TestFramework,
  SourceComplexityCalculator;

type
  TSourceComplexityCalculatorTest = class (TTestCase)
  protected
    procedure CheckComplexity(Source: String; ProcName: String; ExpectedComplexity, ExpectedLinesOfCode, ExpectedStatementsCount: Integer);
  published
    procedure TestSimple;
    procedure TestComplex;
    procedure TestIfStatement;
    procedure TestIfElseStatement;
    procedure TestIfElseIfStatement;
    procedure TestIfElseIfElseStatement;
    procedure TestForLoop;
    procedure TestWhileLoop;
    procedure TestRepeatUntilLoop;
    procedure TestCaseBlock;
    procedure TestCaseElseBlock;
    procedure TestTryfinallyBlock;
    procedure TestTryExceptBlock;
    procedure TestTryExceptOnBlock;
  end;

implementation

uses
  PascalParser;

{ TSourceComplexityCalculatorTest }

{ Protected declarations }

procedure TSourceComplexityCalculatorTest.CheckComplexity(Source: String; ProcName: String; ExpectedComplexity, ExpectedLinesOfCode, ExpectedStatementsCount: Integer);
var
  SourceContainer: TStrings;
  Parser: TPascalParser;
  SCC: TSourceComplexityCalculator;
begin
  SourceContainer := TStringList.Create;
  try
    SourceContainer.Text := Source;
    Parser := TPascalParser.Create;
    Parser.Parse(SourceContainer);
    try
      SCC := TSourceComplexityCalculator.Create(Parser.Root);
      try
        CheckEquals(ProcName, SCC.Functions[0]);
        CheckEquals(ExpectedComplexity, SCC.Complexity(ProcName));
        CheckEquals(ExpectedLinesOfCode, SCC.LinesOfCode(ProcName));
        CheckEquals(ExpectedStatementsCount, SCC.Complexity(ProcName));
      finally
        SCC.Free;
      end;
    finally
      Parser.Free;
    end;
  finally
    SourceContainer.Free;
  end;
end;

{ Published declarations }

procedure TSourceComplexityCalculatorTest.TestSimple;
const
  SOURCE = 'unit test; interface procedure testme; implementation procedure testme; begin end; end.';
begin
  CheckComplexity(SOURCE, 'testme', 1, 1, 1);
end;

procedure TSourceComplexityCalculatorTest.TestComplex;
const
  SOURCE = 'unit test;'#13#10'interface'#13#10'procedure testme;'#13#10'implementation'#13#10'procedure testme;'#13#10 +
           'begin'#13#10 +
           'if a < b then Beep;'#13#10 +
           'if a < b then Beep else Beep;'#13#10 +
           'if a < b then Beep else if a > b then Beep else Beep;'#13#10 +
           'for i := 0 to 100 do Beep;'#13#10 +
           'case i of 1: ; end;'#13#10 +
           'case i of 1: ; 2: ; end;'#13#10 +
           'case i of 1: ; else Beep; end;'#13#10 +
           'case i of 1: ; 2: ; else Beep; end;'#13#10 +
           'try finally end;'#13#10 +
           'try except end;'#13#10 +
           'try except on E: Exception do end;'#13#10 +
           'end; end.';
begin
  CheckComplexity(SOURCE, 'testme', 22, 14, 22);
end;

procedure TSourceComplexityCalculatorTest.TestIfStatement;
const
  SOURCE = 'unit test; interface procedure testme; implementation procedure testme; begin if a < b then Beep; end; end.';
begin
  CheckComplexity(SOURCE, 'testme', 2, 1, 2);
end;

procedure TSourceComplexityCalculatorTest.TestIfElseStatement;
const
  SOURCE = 'unit test; interface procedure testme; implementation procedure testme; begin if a < b then Beep else Beep; end; end.';
begin
  CheckComplexity(SOURCE, 'testme', 3, 1, 3);
end;

procedure TSourceComplexityCalculatorTest.TestIfElseIfStatement;
const
  SOURCE = 'unit test; interface procedure testme; implementation procedure testme; begin if a < b then Beep else if a > b then Beep; end; end.';
begin
  CheckComplexity(SOURCE, 'testme', 3, 1, 3);
end;

procedure TSourceComplexityCalculatorTest.TestIfElseIfElseStatement;
const
  SOURCE = 'unit test; interface procedure testme; implementation procedure testme; begin if a < b then Beep else if a > b then Beep else Beep; end; end.';
begin
  CheckComplexity(SOURCE, 'testme', 4, 1, 4);
end;

procedure TSourceComplexityCalculatorTest.TestForLoop;
const
  SOURCE = 'unit test; interface procedure testme; implementation procedure testme; begin for i := 0 to 100 do Beep; end; end.';
begin
  CheckComplexity(SOURCE, 'testme', 2, 1, 2);
end;

procedure TSourceComplexityCalculatorTest.TestWhileLoop;
const
  SOURCE = 'unit test; interface procedure testme; implementation procedure testme; begin while false do Beep; end; end.';
begin
  CheckComplexity(SOURCE, 'testme', 2, 1, 2);
end;

procedure TSourceComplexityCalculatorTest.TestRepeatUntilLoop;
const
  SOURCE = 'unit test; interface procedure testme; implementation procedure testme; begin repeat Beep; until False; end; end.';
begin
  CheckComplexity(SOURCE, 'testme', 2, 1, 2);
end;

procedure TSourceComplexityCalculatorTest.TestCaseBlock;
const
  SOURCE1 = 'unit test; interface procedure testme; implementation procedure testme; begin case i of 1: ; end; end; end.';
  SOURCE2 = 'unit test; interface procedure testme; implementation procedure testme; begin case i of 1: ; 2: ; end; end; end.';
begin
  CheckComplexity(SOURCE1, 'testme', 2, 1, 2);
  CheckComplexity(SOURCE2, 'testme', 3, 1, 3);
end;

procedure TSourceComplexityCalculatorTest.TestCaseElseBlock;
const
  SOURCE1 = 'unit test; interface procedure testme; implementation procedure testme; begin case i of 1: ; else Beep; end; end; end.';
  SOURCE2 = 'unit test; interface procedure testme; implementation procedure testme; begin case i of 1: ; 2: ; else Beep; end; end; end.';
begin
  CheckComplexity(SOURCE1, 'testme', 3, 1, 3);
  CheckComplexity(SOURCE2, 'testme', 4, 1, 4);
end;

procedure TSourceComplexityCalculatorTest.TestTryFinallyBlock;
const
  SOURCE = 'unit test; interface procedure testme; implementation procedure testme; begin try finally end; end; end.';
begin
  CheckComplexity(SOURCE, 'testme', 2, 1, 2);
end;

procedure TSourceComplexityCalculatorTest.TestTryExceptBlock;
const
  SOURCE = 'unit test; interface procedure testme; implementation procedure testme; begin try except end; end; end.';
begin
  CheckComplexity(SOURCE, 'testme', 3, 1, 3);
end;

procedure TSourceComplexityCalculatorTest.TestTryExceptOnBlock;
const
  SOURCE = 'unit test; interface procedure testme; implementation procedure testme; begin try except on E: Exception do end; end; end.';
begin
  CheckComplexity(SOURCE, 'testme', 4, 1, 4);
end;

initialization
  RegisterTest(TSourceComplexityCalculatorTest.Suite);

end.

