unit UnitRegistry;

interface

uses
  Classes, SysUtils,
  PascalParser;

type
  TUnitRegistry = class (TObject)
  private
    FUnits: TStrings;
    FUsesList: TStrings;
    FIncludes: TStrings;
    function GetUnitParser(UnitName: String): TPascalParser;
    function FindUnitSource(UnitName: String): String;
  protected
    class procedure Initialize;
    class procedure Shutdown;
    property Units: TStrings read FUnits;
  public
    class function Instance: TUnitRegistry;
    constructor Create;
    destructor Destroy; override;
    function IsUnitRegistered(UnitName: String): Boolean;
    function RegisterUnit(UnitName, FileName: String; IncludedInProject: Boolean = False): TPascalParser;
    procedure AddUsedUnit(UnitName, UsedUnit: String);
    procedure GetProjectRegisteredUnitsNames(Units: TStrings);
    procedure GetAllRegisteredUnitsNames(Units: TStrings);
    procedure GetUnitUsesList(UnitName: String; UsesList: TStrings);
    procedure GetUnitIncludes(UnitName: String; Includes: TStrings);
    property UnitParser[UnitName: String]: TPascalParser read GetUnitParser;
  end;

implementation

uses
  Options,
  SourceTreeWalker, 
  IncludeParser, CommentRemovalVisitor, WhitespaceRemovalVisitor;

{ TUnitRegistry }

{ Private declarations }

function TUnitRegistry.GetUnitParser(UnitName: String): TPascalParser;
var
  UnitIndex: Integer;
  FileName: String;
begin
  Result := nil;
  UnitName := UpperCase(UnitName);
  UnitIndex := Units.IndexOf(UnitName);
  if UnitIndex <> -1 then
    Result := Units.Objects[UnitIndex] as TPascalParser
  else
  begin
    FileName := FindUnitSource(UnitName);
    if FileName <> '' then
      Result := RegisterUnit(UnitName, FileName);
  end;
end;

function TUnitRegistry.FindUnitSource(UnitName: String): String;
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
      if FileExists(Path + UnitName + '.pas') then
      begin
        Result := Path + UnitName + '.pas';
        Break;
      end;
    end;
end;

{ Protected declarations }

var
  _Instance: TUnitRegistry = nil;

class procedure TUnitRegistry.Initialize;
begin
  _Instance := TUnitRegistry.Create;
end;

class procedure TUnitRegistry.Shutdown;
begin
  Assert(Assigned(_Instance), 'Error: TUnitRegistry instance not initialized');
  FreeAndNil(_Instance);
end;

{ Public declarations }

class function TUnitRegistry.Instance: TUnitRegistry;
begin
  Assert(Assigned(_Instance), 'Error: TUnitRegistry instance not initialized');
  Result := _Instance;
end;

constructor TUnitRegistry.Create;
begin
  Assert(not Assigned(_Instance), 'Error: TUnitRegistry is a singleton and can only be accessed using TUnitRegistry.Instance method');

  inherited Create;
  FUnits := TStringList.Create;
  FUsesList := TStringList.Create;
  FIncludes := TStringList.Create;
end;

destructor TUnitRegistry.Destroy;
var
  I: Integer;
begin
  for I := 0 to Units.Count - 1 do
    Units.Objects[I].Free;
  FreeAndNil(FUnits);
  for I := 0 to FUsesList.Count - 1 do
    FUsesList.Objects[I].Free;
  FreeAndNil(FUsesList);
  for I := 0 to FIncludes.Count - 1 do
    FIncludes.Objects[I].Free;
  FreeAndNil(FIncludes);
  inherited Destroy;
end;

function TUnitRegistry.IsUnitRegistered(UnitName: String): Boolean;
begin
  Result := Units.IndexOf(UnitName) <> -1;
end;

function TUnitRegistry.RegisterUnit(UnitName, FileName: String; IncludedInProject: Boolean = False): TPascalParser;
var
  Source: TStrings;
  UsesList: TStrings;
  Includes: TStrings;
  IncludeParser: TIncludeParser;
begin
  UnitName := UpperCase(UnitName);
  Assert(Units.IndexOf(UnitName) = -1, Format('Error: unit "%s" already registered', [UnitName]));
  Assert(FileExists(FileName), Format('Error: file "%s" not found', [FileName]));
  Result := TPascalParser.Create;
  Result.PreserveWhiteSpaces := True;
  Result.PreserveComments := True;
  Source := TStringList.Create;
  try
    Source.LoadFromFile(FileName);
    IncludeParser := TIncludeParser.Create;
    try
      IncludeParser.ParseIncludes(Source);
      Includes := TStringList.Create;
      Includes.Assign(IncludeParser.Includes);
      FIncludes.AddObject(UnitName, Includes);
    finally
      IncludeParser.Free;
    end;
    Result.Parse(Source);
    UsesList := TStringList.Create;
    FUsesList.AddObject(UnitName, UsesList);
    TSourceTreeWalker.Create.Walk(Result.Root, TCommentRemovalVisitor.Create);
    TSourceTreeWalker.Create.Walk(Result.Root, TWhitespaceRemovalVisitor.Create);
  finally
    Source.Free;
  end;
  Result.Tag := Integer(IncludedInProject);
  Units.AddObject(UnitName, Result);
end;

procedure TUnitRegistry.AddUsedUnit(UnitName, UsedUnit: String);
var
  Index: Integer;
begin
  Index := FUsesList.IndexOf(UnitName);
  Assert(Index <> -1, 'Error: unit not registered!');
  TStrings(FUsesList.Objects[Index]).Add(UsedUnit);
end;

procedure TUnitRegistry.GetProjectRegisteredUnitsNames(Units: TStrings);
var
  I: Integer;
begin
  Units.Clear;
  for I := 0 to Self.Units.Count - 1 do
    if TPascalParser(Self.Units.Objects[I]).Tag <> 0 then
      Units.Add(Self.Units[I]);
end;

procedure TUnitRegistry.GetAllRegisteredUnitsNames(Units: TStrings);
begin
  Units.Assign(Self.Units);
end;

procedure TUnitRegistry.GetUnitUsesList(UnitName: String; UsesList: TStrings);
begin
  UsesList.Clear;
  if FUsesList.IndexOf(UnitName) <> -1 then
    UsesList.Assign(TStrings(FUsesList.Objects[FUsesList.IndexOf(UnitName)]));
end;

procedure TUnitRegistry.GetUnitIncludes(UnitName: String; Includes: TStrings);
begin
  Includes.Clear;
  if FIncludes.IndexOf(UnitName) <> -1 then
    Includes.Assign(TStrings(FIncludes.Objects[FIncludes.IndexOf(UnitName)]));
end;

initialization
  TUnitRegistry.Initialize;

finalization
  TUnitRegistry.Shutdown;

end.



