unit SourceTreeDumperVisitor;

interface

uses
  Classes, SysUtils, StrUtils,
  ParseTreeNode, ParseTreeNodeType,
  SourceTreeWalker;

type
  TSourceTreeDumperVisitor = class (TInterfacedObject, INodeVisitor)
  private
    FOutput: TStrings;
    function GetNodeDepth(Node: TParseTreeNode): Integer;
  protected
    property Output: TStrings read FOutput;
  public
    constructor Create(AOutput: TStrings);
    procedure Visit(Node: TParseTreeNode);
  end;

implementation

{ TSourceTreeDumperVisitor }

{ Private declarations }

function TSourceTreeDumperVisitor.GetNodeDepth(Node: TParseTreeNode): Integer;
begin
  Result := 0;
  if Assigned(Node) then
    Result := Result + 1 + GetNodeDepth(Node.Parent);
end;

{ Public declarations }

constructor TSourceTreeDumperVisitor.Create(AOutput: TStrings);
begin
  inherited Create;
  FOutput := AOutput;
end;

procedure TSourceTreeDumperVisitor.Visit(Node: TParseTreeNode);
begin
  Output.Add(DupeString('  ', GetNodeDepth(Node)) + Node.Describe);
end;

end.

