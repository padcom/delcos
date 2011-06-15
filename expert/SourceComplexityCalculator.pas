unit SourceComplexityCalculator;

interface

uses
{$IFDEF VER130}
  Windows,
{$ELSE}
  Types,  
{$ENDIF}
  Classes, SysUtils, 
  ParseTreeNode, ParseTreeNodeType, SourceToken, Tokens, PascalParser;

type
  TSourceComplexityCalculator = class (TObject)
  private
    FRoot: TParseTreeNode;
    FFunctions: TStrings;
    procedure FillFunctionList(Root: TParseTreeNode);
    function CalculateElseBlockComplexity(Root: TParseTreeNode): Integer;
    function CalculateCaseLabelComplexity(Root: TParseTreeNode): Integer;
  protected
    function FindNode(Root: TParseTreeNode; NodeTypeToFind: TParseTreeNodeTypeSet): TParseTreeNode;
    function GatherProcName(Root: TParseTreeNode): String;
    function FindProcRoot(Root: TParseTreeNode; ProcName: String): TParseTreeNode;
    function GatherDecisionPoints(Root: TParseTreeNode): Integer;
    function GatherLinesOfCode(Root: TParseTreeNode): Integer;
    function GatherNumberOfStatements(Root: TParseTreeNode): Integer;
    function GatherSourcePosition(Root: TParseTreeNode): TPoint;
  public
    constructor Create(ARoot: TParseTreeNode);
    destructor Destroy; override;
    function Complexity(ProcName: String): Integer;
    function LinesOfCode(ProcName: String): Integer;
    function NumberOfStatements(ProcName: String): Integer;
    function DefinitionPoint(ProcName: String): TPoint;
    property Root: TParseTreeNode read FRoot;
    property Functions: TStrings read FFunctions;
  end;

implementation

{ TSourceComplexityCalculator }

{ Private declarations }

procedure TSourceComplexityCalculator.FillFunctionList(Root: TParseTreeNode);
var
  I: Integer;
begin
  if Root.NodeType in [nFunctionDecl, nProcedureDecl, nConstructorDecl, nDestructorDecl] then
    Functions.Add(GatherProcName(Root))
  else
    for I := 0 to Root.ChildNodeCount - 1 do
      FillFunctionList(Root.ChildNodes[I]);
end;

function TSourceComplexityCalculator.CalculateElseBlockComplexity(Root: TParseTreeNode): Integer;
var
  Tmp1, Tmp2: TParseTreeNode;
begin
  Tmp1 := FindNode(Root, [nStatement]);
  Tmp2 := FindNode(Tmp1, [nIfBlock, nUnknown]);
  if Assigned(Tmp2) then
    Result := 0
  else
    Result := 1
end;

function TSourceComplexityCalculator.CalculateCaseLabelComplexity(Root: TParseTreeNode): Integer;
begin
  if Root.Parent.FirstNodeAfter(Root).Describe = ':' then
    Result := 1
  else
    Result := 0;
end;

{ Protected declarations }

function TSourceComplexityCalculator.FindNode(Root: TParseTreeNode; NodeTypeToFind: TParseTreeNodeTypeSet): TParseTreeNode;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Root.ChildNodeCount - 1 do
  begin
    Result := Root.ChildNodes[I];
    if Result.NodeType in NodeTypeToFind then
      Break
    else
      Result := nil;
  end;
end;

function TSourceComplexityCalculator.GatherProcName(Root: TParseTreeNode): String;
var
  I: Integer;
begin
  Root := FindNode(Root, [nFunctionHeading, nProcedureHeading, nConstructorHeading, nDestructorHeading]);
  Assert(Assigned(Root), 'Error: can''t find procedure heading node');
  Root := FindNode(Root, [nIdentifier]);
  Assert(Assigned(Root), 'Error: can''t find identifier node');

  Result := '';
  for I := 0 to Root.ChildNodeCount - 1 do
  begin
    if TPascalParser.IsCommentNode(Root.ChildNodes[I]) then
      Continue;
    if TPascalParser.IsWhiteSpaceNode(Root.ChildNodes[I]) then
      Continue;
    Result := Result + Root.ChildNodes[I].Describe;
  end;
end;

function TSourceComplexityCalculator.FindProcRoot(Root: TParseTreeNode; ProcName: String): TParseTreeNode;
var
  I: Integer;
begin
  Result := nil;
  if Root.NodeType in [nFunctionDecl, nProcedureDecl, nConstructorDecl, nDestructorDecl] then
  begin
    if AnsiSameText(GatherProcName(Root), ProcName) then
      Result := Root;
  end
  else
    for I := 0 to Root.ChildNodeCount - 1 do
    begin
      Result := FindProcRoot(Root.ChildNodes[I], ProcName);
      if Result <> nil then
        Break;
    end;
end;

function TSourceComplexityCalculator.GatherDecisionPoints(Root: TParseTreeNode): Integer;
const
  NODES_THAT_INCREASE_COMPLEXITY = [nIfBlock, nForStatement, nWhileStatement, nRepeatStatement, nTryBlock, nExceptBlock, nOnExceptionHandler, nElseCase];
var
  I: Integer;
begin
  if Root.NodeType in NODES_THAT_INCREASE_COMPLEXITY then
    Result := 1
  else if Root.NodeType = nElseBlock then
    Result := CalculateElseBlockComplexity(Root)
  else if Root.NodeType = nCaseLabel then
    Result := CalculateCaseLabelComplexity(Root)
  else if (Root is TSourceToken) and (TSourceToken(Root).TokenType in [ttAnd, ttOr]) then
    Result := 1
  else
    Result := 0;

  for I := 0 to Root.ChildNodeCount - 1 do
    Result := Result + GatherDecisionPoints(Root.ChildNodes[I]);
end;

function TSourceComplexityCalculator.GatherLinesOfCode(Root: TParseTreeNode): Integer;
var
  I: Integer;
begin
  if Root.Describe = 'Return' then
    Result := 1
  else
    Result := 0;

  for I := 0 to Root.ChildNodeCount - 1 do
    Result := Result + GatherLinesOfCode(Root.ChildNodes[I]);
end;

function TSourceComplexityCalculator.GatherNumberOfStatements(Root: TParseTreeNode): Integer;
var
  I: Integer;
begin
  if Root.NodeType = nStatement then
    Result := 1
  else
    Result := 0;

  for I := 0 to Root.ChildNodeCount - 1 do
    Result := Result + GatherNumberOfStatements(Root.ChildNodes[I]);
end;

function TSourceComplexityCalculator.GatherSourcePosition(Root: TParseTreeNode): TPoint;
var
  I: Integer;
begin
  Result.X := -1;
  Result.Y := -1;
  if Root is TSourceToken then
  begin
    Result.X :=  TSourceToken(Root).XPosition;
    Result.Y :=  TSourceToken(Root).YPosition;
  end;
  for I := 0 to Root.ChildNodeCount - 1 do
  begin
    Result := GatherSourcePosition(Root.ChildNodes[I]);
    if (Result.X <> -1) and (Result.Y <> -1) then
      Break;
  end;
end;

{ Public declarations }

constructor TSourceComplexityCalculator.Create(ARoot: TParseTreeNode);
begin
  inherited Create;
  FFunctions := TStringList.Create;
  FRoot := ARoot;
  Assert(Assigned(Root), 'Error: can''t calculate complexity if no root is given');
  TStringList(Functions).Duplicates := dupIgnore;
  FillFunctionList(Root);
  TStringList(Functions).Sort;
end;

destructor TSourceComplexityCalculator.Destroy;
begin
  FreeAndNil(FFunctions);
  inherited Destroy;
end;

function TSourceComplexityCalculator.Complexity(ProcName: String): Integer;
var
  ProcRoot: TParseTreeNode;
begin
  ProcRoot := FindProcRoot(Root, ProcName);
  Assert(Assigned(ProcRoot), 'Error: can''t find procedure root');
  Result := GatherDecisionPoints(ProcRoot) + 1;
end;

function TSourceComplexityCalculator.LinesOfCode(ProcName: String): Integer;
var
  ProcRoot: TParseTreeNode;
begin
  ProcRoot := FindProcRoot(Root, ProcName);
  Assert(Assigned(ProcRoot), 'Error: can''t find procedure root');
  Result := GatherLinesOfCode(ProcRoot) + 1;
end;

function TSourceComplexityCalculator.NumberOfStatements(ProcName: String): Integer;
var
  ProcRoot: TParseTreeNode;
begin
  ProcRoot := FindProcRoot(Root, ProcName);
  Assert(Assigned(ProcRoot), 'Error: can''t find procedure root');
  Result := GatherNumberOfStatements(ProcRoot);
end;

function TSourceComplexityCalculator.DefinitionPoint(ProcName: String): TPoint;
var
  ProcRoot: TParseTreeNode;
begin
  ProcRoot := FindProcRoot(Root, ProcName);
  Assert(Assigned(ProcRoot), 'Error: can''t find procedure root');
  Result := GatherSourcePosition(ProcRoot);
end;

end.

