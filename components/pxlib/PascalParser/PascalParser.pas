unit PascalParser;

{$H+}

interface

uses
  Classes, SysUtils,
  BuildParseTree, BuildTokenList, Nesting, ParseError, ParseTreeNode,
  ParseTreeNodeType, SourceToken, SourceTokenList, Tokens, TokenUtils;

type
  TPascalParser = class (TObject)
  private
    FParseTree: TBuildParseTree;
    function GetRoot: TParseTreeNode;
  protected
    property ParseTree: TBuildParseTree read FParseTree;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Parse(FileName: String); overload;
    procedure Parse(Stream: TStream); overload;
    procedure Parse(Source: TStrings); overload;
    procedure Parse(SourceTokens: TSourceTokenList); overload;
    class function IsCommentNode(Node: TParseTreeNode): Boolean;
    class function IsWhiteSpaceNode(Node: TParseTreeNode): Boolean;
    property Root: TParseTreeNode read GetRoot;
  end;

implementation

uses
  PreProcessorParseTree;

{ TPascalParser }

{ Private declarations }

function TPascalParser.GetRoot: TParseTreeNode;
begin
  Result := ParseTree.Root;
end;

{ Protected declarations }

{ Public declarations }

constructor TPascalParser.Create;
begin
  inherited Create;
  FParseTree := TBuildParseTree.Create;
end;

destructor TPascalParser.Destroy;
begin
  FreeAndNil(FParseTree);
  inherited Destroy;
end;

procedure TPascalParser.Parse(FileName: String);
var
  Source: TStrings;
begin
  Source := TStringList.Create;
  try
    Source.LoadFromFile(FileName);
    Parse(Source);
  finally
    Source.Free;
  end;
end;

procedure TPascalParser.Parse(Stream: TStream);
var
  Source: TStrings;
begin
  Source := TStringList.Create;
  try
    Source.LoadFromStream(Stream);
    Parse(Source);
  finally
    Source.Free;
  end;
end;

procedure TPascalParser.Parse(Source: TStrings);
var
  Tokenizer: TBuildTokenList;
  SourceTokens: TSourceTokenList;
begin
  Tokenizer := TBuildTokenList.Create;
  try
    Tokenizer.SourceCode := Source.Text;
    SourceTokens := Tokenizer.BuildTokenList;
    RemoveConditionalCompilation(SourceTokens);
    SourceTokens.SetXYPositions;
    try
      Parse(SourceTokens);
    finally
      SourceTokens.Free;
    end;
  finally
    Tokenizer.Free;
  end;
end;

procedure TPascalParser.Parse(SourceTokens: TSourceTokenList);
begin
  ParseTree.TokenList := SourceTokens;
  ParseTree.BuildParseTree;
end;

class function TPascalParser.IsCommentNode(Node: TParseTreeNode): Boolean;
begin
  Result := (Node.NodeType = nUnknown) and (Node is TSourceToken) and (Pos('comment ', TSourceToken(Node).Describe) = 1);
end;

class function TPascalParser.IsWhiteSpaceNode(Node: TParseTreeNode): Boolean;
begin
  Result := (Node.NodeType = nUnknown) and (Node is TSourceToken) and (TSourceToken(Node).TokenType in [ttWhiteSpace, ttReturn]);
end;

end.

