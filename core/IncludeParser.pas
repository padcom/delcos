unit IncludeParser;

interface

uses
  Classes, SysUtils, RegExpr;

type
  TIncludeParser = class (TObject)
  private
    FIncludes: TStrings;
    function ExpandFileName(FileName: String): String;
    procedure RegisterInclude(FileName: String);
  public
    constructor Create;
    destructor Destroy; override;
    procedure ParseIncludes(FileName: String); overload;
    procedure ParseIncludes(Source: TStrings); overload;
    property Includes: TStrings read FIncludes;
  end;

implementation

uses Options;

{ TIncludeParser }

{ Private declarations }

function TIncludeParser.ExpandFileName(FileName: String): String;
var
  I: Integer;
  Path: String;
begin
  Result := '';
  with TOptions.Instance do
    for I := 0 to SearchPath.Count - 1 do
    begin
      if SearchPath[I] <> '' then
        Path := IncludeTrailingPathDelimiter(SearchPath[I])
      else
        Path := '';
      if FileExists(Path + FileName) then
      begin
        Result := Path + FileName;
        Break;
      end;
    end;
end;

procedure TIncludeParser.RegisterInclude(FileName: String);
begin
  if ExpandFileName(FileName) <> '' then
    FileName := ExpandFileName(FileName);
  if FIncludes.IndexOf(UpperCase(FileName)) = -1 then
  begin
    FIncludes.Add(FileName);
    if FileExists(FileName) then
      ParseIncludes(FileName);
  end;
end;

{ Public declarations }

constructor TIncludeParser.Create;
begin
  inherited Create;
  FIncludes := TStringList.Create;
end;

destructor TIncludeParser.Destroy;
begin
  FreeAndNil(FIncludes);
  inherited Destroy;
end;

procedure TIncludeParser.ParseIncludes(FileName: String);
var
  Source: TStrings;
begin
  if not FileExists(FileName) then
    Exit;
    
  Source := TStringList.Create;
  try
    Source.LoadFromFile(FileName);
    ParseIncludes(Source);
  finally
    Source.Free;
  end;
end;

procedure TIncludeParser.ParseIncludes(Source: TStrings);
var
  Found: Boolean;
begin
  with TRegExpr.Create do
    try
      Expression := '(\{|\(\*)\$[iI] +(.+?)(\}|\*\))';
      Found := Exec(Source.Text);
      while Found do
      begin
        RegisterInclude(Match[2]);
        Found := ExecNext;
      end;
    finally
      Free;
    end;
end;

end.
