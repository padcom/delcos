unit SourceTreeWalker;

interface

uses
  Classes, SysUtils,
  ParseTreeNode, ParseTreeNodeType;

type
  INodeVisitor = interface
    ['{3CCC0A6A-0E0C-4E37-9521-9B6A92F9028F}']
    procedure Visit(Node: TParseTreeNode);
  end;

  ISourceTreeWalker = interface
    ['{653F6C4A-3A38-498E-A4DD-F7A34391748C}']
    procedure Walk(Root: TParseTreeNode; Visitor: INodeVisitor);
  end;

  TSourceTreeWalker = class (TInterfacedObject, ISourceTreeWalker)
  private
    function ContainsNode(Parent, Node: TParseTreeNode): Boolean;
  public
    procedure Walk(Root: TParseTreeNode; Visitor: INodeVisitor);
  end;

implementation

{ TSourceTreeWalker }

{ Private declarations }

function TSourceTreeWalker.ContainsNode(Parent, Node: TParseTreeNode): Boolean;
var
  I: Integer;
begin
  if Assigned(Parent) then
  begin
    Result := False;
    for I := 0 to Parent.ChildNodeCount - 1 do
      if Parent.ChildNodes[I] = Node then
      begin
        Result := True;
        Break;
      end;
  end
  else
    Result := True
end;

{ Public declarations }

procedure TSourceTreeWalker.Walk(Root: TParseTreeNode; Visitor: INodeVisitor);
var
  OldCount, I: Integer;
  Parent, Node: TParseTreeNode;
begin
  if not Assigned(Root) then
    Exit;

  Parent := Root.Parent;
  Visitor.Visit(Root);

  if ContainsNode(Parent, Root) then
  begin
    I := 0;
    while I < Root.ChildNodeCount do
    begin
      Node := Root.ChildNodes[I];
      OldCount := Root.ChildNodeCount;
      Walk(Node, Visitor);
      if OldCount = Root.ChildNodeCount then
//      if ContainsNode(Root, Node) then
        Inc(I);
    end;
  end;
end;

end.


