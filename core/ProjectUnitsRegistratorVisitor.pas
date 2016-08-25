unit ProjectUnitsRegistratorVisitor;

interface

uses
  Classes, SysUtils, StrUtils, 
  ParseTreeNode, ParseTreeNodeType, SourceToken,
  SourceTreeWalker;

type
  TProjectUnitsRegistratorVisitor = class (TInterfacedObject, INodeVisitor)
  private
    function ExtractUnitName(Node: TParseTreeNode): String;
    function ExtractFileName(Node: TParseTreeNode): String;
  public
    procedure Visit(Node: TParseTreeNode);
  end;

implementation

uses
  UnitRegistry;

{ TProjectUnitsRegistratorVisitor }

function TProjectUnitsRegistratorVisitor.ExtractUnitName(Node: TParseTreeNode): String;
begin
  Result := Node.ChildNodes[0].ChildNodes[0].Describe;
end;

function TProjectUnitsRegistratorVisitor.ExtractFileName(Node: TParseTreeNode): String;
begin
  Result := '';
  if (Node.ChildNodeCount = 3) and (Node.ChildNodes[2] is TSourceToken) then
  begin
    Result := TSourceToken(Node.ChildNodes[2]).SourceCode;
    Result := AnsiReplaceStr(Result, '''', '');
  end;
end;

procedure TProjectUnitsRegistratorVisitor.Visit(Node: TParseTreeNode);
var
  UnitName, FileName: String;
begin
  if Node.NodeType = nUsesItem then
  begin
    UnitName := ExtractUnitName(Node);
    FileName := ExtractFileName(Node);
    if (UnitName <> '') and (FileName <> '') then
      TUnitRegistry.Instance.RegisterUnit(UnitName, FileName, True);
  end;
end;

end.