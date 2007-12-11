unit CommentRemovalVisitor;

interface

uses
  Classes, SysUtils,
  ParseTreeNode, SourceToken, Tokens,
  SourceTreeWalker;

type
  TCommentRemovalVisitor = class (TInterfacedObject, INodeVisitor)
    procedure Visit(Node: TParseTreeNode);
  end;

implementation

{ TCommentRemovalVisitor }

procedure TCommentRemovalVisitor.Visit(Node: TParseTreeNode);
begin
  if (Node is TSourceToken) and (TSourceToken(Node).TokenType = ttComment) then
    Node.Parent.RemoveChild(Node);
end;

end.

