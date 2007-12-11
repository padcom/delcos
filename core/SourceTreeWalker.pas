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
    procedure Walk(Root: TParseTreeNode; Visitor: INodeVisitor);
  end;

implementation

{ TSourceTreeWalker }

procedure TSourceTreeWalker.Walk(Root: TParseTreeNode; Visitor: INodeVisitor);
var
  OldCount, I: Integer;
  Parent, Node: TParseTreeNode;
begin
  if not Assigned(Root) then
    Exit;

  Parent := Root.Parent;
  if Assigned(Parent) then
    OldCount := Parent.ChildNodeCount
  else
    OldCount := -1;
  Visitor.Visit(Root);

  try
    if (not Assigned(Parent)) or (OldCount = Parent.ChildNodeCount) then
    begin
      I := 0;
      while I < Root.ChildNodeCount do
      begin
        Node := Root.ChildNodes[I];
        OldCount := Root.ChildNodeCount;
        Walk(Node, Visitor);
        if OldCount = Root.ChildNodeCount then
          Inc(I);
      end;
    end;
  except
    on E: Exception do
    begin
      Writeln(E.Message);
      raise;
    end;
  end;
end;

end.




