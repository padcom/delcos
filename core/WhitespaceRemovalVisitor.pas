unit WhitespaceRemovalVisitor;

interface

uses
  Classes, SysUtils,
  ParseTreeNode, SourceToken, Tokens, PascalParser,
  SourceTreeWalker;

type
  TWhitespaceRemovalVisitor = class (TInterfacedObject, INodeVisitor)
    procedure Visit(Node: TParseTreeNode);
  end;

implementation

{ TWhitespaceRemovalVisitor }

procedure TWhitespaceRemovalVisitor.Visit(Node: TParseTreeNode);
begin
  if TPascalParser.IsWhiteSpaceNode(Node) then
    Node.Parent.RemoveChild(Node);
end;

end.

