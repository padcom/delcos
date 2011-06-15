unit CodeMetrics;

interface

uses
  Windows, Messages, Classes, SysUtils, Forms, Controls, ComCtrls, Dialogs,
  ParseTreeNode;

type
  TFrmCodeMetrics = class(TForm)
    LivMetrics: TListView;
    StatusBar: TStatusBar;
    procedure FormResize(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure LivMetricsColumnClick(Sender: TObject; Column: TListColumn);
    procedure LivMetricsCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
    procedure LivMetricsDblClick(Sender: TObject);
  private
    FColumnIndex: Integer;
    FOrderDescending: Boolean;
    FPosition: TPoint;
    function CompareColumnData(S1, S2: String): Integer;
    procedure CreateProcedureList(Root: TParseTreeNode);
    procedure UpdateStatistics(Source: TStream);
  public
    class function ShowMetrics(Source: TStream): TPoint;
  end;

implementation

{$R *.dfm}

uses
  PascalParser, SourceComplexityCalculator;

{ TFrmCodeMetrics }

procedure TFrmCodeMetrics.FormResize(Sender: TObject);
begin
  inherited;
  LivMetrics.Columns[1].Width := 100;
  LivMetrics.Columns[2].Width := 100;
  LivMetrics.Columns[3].Width := 100;
  LivMetrics.Columns[4].Width := 50;
  LivMetrics.Columns[5].Width := 50;
  LivMetrics.Columns[0].Width := LivMetrics.ClientWidth - 400;
end;

procedure TFrmCodeMetrics.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    Close
  else if Key = VK_RETURN then
    LivMetricsDblClick(Sender)
end;

procedure TFrmCodeMetrics.LivMetricsColumnClick(Sender: TObject; Column: TListColumn);
begin
  if FColumnIndex = Column.Index then
    FOrderDescending := not FOrderDescending
  else
  begin
    FColumnIndex := Column.Index;
    FOrderDescending := True;
  end;

  LivMetrics.AlphaSort;
end;

function TFrmCodeMetrics.CompareColumnData(S1, S2: String): Integer;
var
  V1, V2: Integer;
begin
  V1 := StrToInt(S1);
  V2 := StrToInt(S2);
  if V1 < V2 then
    Result := -1
  else if V1 > V2 then
    Result := 1
  else
    Result := 0;
end;

procedure TFrmCodeMetrics.LivMetricsCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
begin
  try
    if FColumnIndex = 0 then
      Compare := -AnsiCompareStr(Item1.Caption, Item2.Caption)
    else
    begin
      Compare := CompareColumnData(Item1.SubItems[FColumnIndex - 1], Item2.SubItems[FColumnIndex - 1]);
      if Compare = 0 then
        Compare := AnsiCompareStr(Item1.Caption, Item2.Caption);
    end;

    if FOrderDescending then
      Compare := -Compare;
  except
    on E: Exception do
      ShowMessage(E.Message);
  end;
end;

procedure TFrmCodeMetrics.LivMetricsDblClick(Sender: TObject);
begin
  if Assigned(LivMetrics) and Assigned(LivMetrics.ItemFocused) then
  begin
    FPosition.X := StrToInt(LivMetrics.ItemFocused.SubItems[3]);
    FPosition.Y := StrToInt(LivMetrics.ItemFocused.SubItems[4]);
    Close;
  end;
end;

procedure TFrmCodeMetrics.CreateProcedureList(Root: TParseTreeNode);
var
  I: Integer;
  SCC: TSourceComplexityCalculator;
begin
  SCC := TSourceComplexityCalculator.Create(Root);
  try
    for I := 0 to SCC.Functions.Count - 1 do
      with LivMetrics.Items.Add do
      begin
        Caption := SCC.Functions[I];
        try
          SubItems.Add(IntToStr(SCC.Complexity(SCC.Functions[I])));
          SubItems.Add(IntToStr(SCC.LinesOfCode(SCC.Functions[I])));
          SubItems.Add(IntToStr(SCC.NumberOfStatements(SCC.Functions[I])));
          with SCC.DefinitionPoint(SCC.Functions[I]) do
          begin
            SubItems.Add(IntToStr(X));
            SubItems.Add(IntToStr(Y));
          end;
        except
          on E: Exception do
          begin
            ShowMessage('There''s a problem with ' + Caption + ' procedure - can''t add to list');
            Delete;
          end;
        end;
      end;
  finally
    SCC.Free;
  end;
end;

procedure TFrmCodeMetrics.UpdateStatistics(Source: TStream);
var
  Parser: TPascalParser;
begin
  LivMetrics.Items.BeginUpdate;
  Screen.Cursor := crHourGlass;
  try
    LivMetrics.Items.Clear;
    Source.Position := 0;
    Parser := TPascalParser.Create;
    try
      Parser.Parse(Source);
      CreateProcedureList(Parser.Root);
    finally
      Parser.Free;
    end;
  finally
    Screen.Cursor := crDefault;
    LivMetrics.Items.EndUpdate;
  end;
  FColumnIndex := 1;
  FOrderDescending := True;
  LivMetrics.AlphaSort;
end;

class function TFrmCodeMetrics.ShowMetrics(Source: TStream): TPoint;
var
  FrmCodeMetrics: TFrmCodeMetrics;
begin
  FrmCodeMetrics := TFrmCodeMetrics.Create(nil);
  try
    FrmCodeMetrics.UpdateStatistics(Source);
    FrmCodeMetrics.ShowModal;
    Result := FrmCodeMetrics.FPosition;
  finally
    FrmCodeMetrics.Free;
  end;
end;

end.

