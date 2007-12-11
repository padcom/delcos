unit CyclomaticComplexityCalculatorVisitor;

interface

uses
  Classes, SysUtils, StrUtils,
  PascalParser, ParseTreeNode, ParseTreeNodeType, SourceToken, Tokens,
  SourceTreeWalker;

type
  TMethod = class (TObject)
  private
    FParent: TMethod;
    FHeadingNode: TParseTreeNode;
    FBlockNode: TParseTreeNode;
    FEndNode: TParseTreeNode;
    FIfCount: Integer;
    FElseCount: Integer;
    FAndCount: Integer;
    FOrCount: Integer;
    FForCount: Integer;
    FWhileCount: Integer;
    FCaseCount: Integer;
    FExceptCount: Integer;
    FRepeatCount: Integer;
    function GetNameNode: TParseTreeNode;
    function GetName: String;
    function GetCyclomaticComplexity: Integer;
  public
    property Name: String read GetName;
    property CyclomaticComplexity: Integer read GetCyclomaticComplexity;
  end;

  TMethodList = class (TList)
  private
    function GetItem(Index: Integer): TMethod;
  public
    procedure Clear; override;
    property Items[Index: Integer]: TMethod read GetItem; default;
  end;

  TCyclomaticComplexityCalculatorVisitor = class (TInterfacedObject, INodeVisitor)
  private
    FMethods: TMethodList;
    FCurrentMethod: TMethod;
    function CreateNewMethodFromNode(Node: TParseTreeNode): TMethod;
    procedure ProcessSourceToken(Token: TSourceToken);
  protected
    property Methods: TMethodList read FMethods;
  public
    constructor Create(AMethods: TMethodList);
    procedure Visit(Node: TParseTreeNode);
  end;

implementation

{ TMethod }

{ Private declarations }

function TMethod.GetNameNode: TParseTreeNode;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FHeadingNode.ChildNodeCount - 1 do
  begin
    Result := FHeadingNode.ChildNodes[I];
    if Result.NodeType <> nUnknown then
      Break;
  end;
end;

function TMethod.GetName: String;
var
  I: Integer;
  Node: TParseTreeNode;
begin
  Result := '';
  if Assigned(FParent) then
    Result := Result + FParent.Name + ':';
  Node := GetNameNode;
  for I := 0 to Node.ChildNodeCount - 1 do
    Result := Result + Node.ChildNodes[I].Describe;
end;

function TMethod.GetCyclomaticComplexity: Integer;
begin
  Result := 1 +
    FIfCount +
    FAndCount +
    FOrCount +
    FElseCount +
    FForCount +
    FWhileCount +
    FRepeatCount +
    FCaseCount +
    FExceptCount;
end;

{ TMethodList }

{ Private declarations }

function TMethodList.GetItem(Index: Integer): TMethod;
begin
  Result := TObject(Get(Index)) as TMethod;
end;

{ Public declarations }

procedure TMethodList.Clear;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    Items[I].Free;
  inherited Clear;
end;

{ TCyclomaticComplexityCalculatorVisitor }

{ Private declarations }

function TCyclomaticComplexityCalculatorVisitor.CreateNewMethodFromNode(Node: TParseTreeNode): TMethod;
begin
  if Node.ChildNodeCount < 4 then
    Result := FCurrentMethod
  else
  begin
    Result := TMethod.Create;
    Result.FHeadingNode := Node.ChildNodes[0];
    Result.FBlockNode := Node.ChildNodes[2];
    Result.FEndNode := Node.ChildNodes[3];
    Methods.Add(Result);
    Result.FParent := FCurrentMethod;
  end;
end;

procedure TCyclomaticComplexityCalculatorVisitor.ProcessSourceToken(Token: TSourceToken);
begin
  case Token.TokenType of
    ttIf: Inc(FCurrentMethod.FIfCount);
    ttAnd: Inc(FCurrentMethod.FAndCount);
    ttOr: Inc(FCurrentMethod.FOrCount);
    ttElse: if Token.NextLeafNode <> nil then
      if TSourceToken(Token.NextLeafNode).TokenType <> ttIf then Inc(FCurrentMethod.FElseCount);
    ttFor: Inc(FCurrentMethod.FForCount);
    ttWhile: Inc(FCurrentMethod.FWhileCount);
    ttRepeat: Inc(FCurrentMethod.FRepeatCount);
  end;
end;

{ Public declarations }

constructor TCyclomaticComplexityCalculatorVisitor.Create(AMethods: TMethodList);
begin
  inherited Create;
  FMethods := AMethods;
end;

procedure TCyclomaticComplexityCalculatorVisitor.Visit(Node: TParseTreeNode);
begin
  if Node.NodeType in ProcedureNodes then
    FCurrentMethod := CreateNewMethodFromNode(Node)
  else if Assigned(FCurrentMethod) then
  begin
    if FCurrentMethod.FEndNode = Node then
      FCurrentMethod := FCurrentMethod.FParent
    else if Node.NodeType in [nCaseStatement, nCaseLabel] then
      Inc(FCurrentMethod.FCaseCount)
    else if Node.NodeType in [nExceptBlock] then
      Inc(FCurrentMethod.FExceptCount)
    else if Node is TSourceToken then
      ProcessSourceToken(Node as TSourceToken)
  end;
end;

end.


