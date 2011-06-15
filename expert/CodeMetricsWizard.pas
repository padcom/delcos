unit CodeMetricsWizard;

interface

uses
{$IFDEF VER130}
{$ELSE}
  Types,  
{$ENDIF}
  Windows, Messages, SysUtils, Classes, Menus, Dialogs,
  ToolsAPI, BaseWizard;

type
  TCodeMetricsWizard = class(TBaseWizard)
  private
    FMenuItemsOwner: TComponent;
    function FindPositionToInsertItems(EditMenu: TMenuItem): Integer;
    procedure InitMenuItems;
    procedure MenuItemClick(Sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
  end;

procedure Register;

implementation

uses 
  CodeMetrics;

{ TCodeMetricsWizard }

{ Private declarations }

function TCodeMetricsWizard.FindPositionToInsertItems(EditMenu: TMenuItem): Integer;
var
  I: Integer;
begin
  // Start by finding where to insert the new item.
  Result := EditMenu.Count; // default is at end of menu
  for I := 0 to EditMenu.Count-1 do
    if CompareText(EditMenu[I].Name, 'EditSelectAll') = 0 then
    begin
      Result := I;
      Break;
    end;
end;

procedure TCodeMetricsWizard.InitMenuItems;
var
  EditMenu: TMenuItem;
  InsertPosition: Integer;
  Item: TMenuItem;
begin
  EditMenu := (BorlandIDEServices as INTAServices).MainMenu.Items[3];
  InsertPosition := FindPositionToInsertItems(EditMenu);
  Item := TMenuItem.Create(FMenuItemsOwner);
  Item.Shortcut := TextToShortCut('Ctrl+Shift+M');
  Item.OnClick := MenuItemClick;
  Item.Caption := 'Code metrics';
  EditMenu.Insert(InsertPosition, Item);
end;

procedure TCodeMetricsWizard.MenuItemClick(Sender: TObject);
var
  Editor: IOTASourceEditor;
  Reader: IOTAEditReader;
  Source: TStream;
  JumpTo: TPoint;
  EditPos: TOTAEditPos;
begin
  Editor := GetEditor;
  Assert(Editor <> nil, 'Error: can''t find editor');
  Assert(Editor.EditViewCount > 0, 'Error: can''t find edit view');

  Reader := Editor.CreateReader;
  Source := TMemoryStream.Create;
  try
    GetSource(Source);
    Source.Position := 0;
    JumpTo := TFrmCodeMetrics.ShowMetrics(Source);
    if (JumpTo.X > 0) and (JumpTo.Y > 0) then
    begin
      EditPos.Col := JumpTo.X;
      EditPos.Line := JumpTo.Y;
//      ShowMessageFmt('X=%d; Y=%d, EditPos.Col=%d, EditPos.Line=%d', [JumpTo.X, JumpTo.Y, EditPos.Col, EditPos.Line]);
      Editor.EditViews[0].TopPos := EditPos;
      Editor.EditViews[0].CursorPos := EditPos;
      Editor.BlockStart := TOTACharPos(EditPos);
    end;
    Editor.Show;
  finally
    Source.Free;
  end;
end;

{ Public declarations }

constructor TCodeMetricsWizard.Create;
begin
  inherited Create('Padcom.CodeMetrics', 'Padcom.CodeMetrics');
  FMenuItemsOwner := TComponent.Create(nil);
  InitMenuItems;
end;

destructor TCodeMetricsWizard.Destroy;
begin
  FreeAndNil(FMenuItemsOwner);
  inherited Destroy;
end;

{ *** }

procedure Register;
begin
  RegisterPackageWizard(TCodeMetricsWizard.Create);
end;

end.
