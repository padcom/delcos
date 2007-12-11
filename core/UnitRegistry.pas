unit UnitRegistry;

interface

uses
  Classes, SysUtils,
  PascalParser;

type
  TUnitRegistry = class (TObject)
  private
    FUnits: TStrings;
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
    function RegisterUnit(UnitName, FileName: String; IncludedInProject: Boolean = False): TPascalParser;
    procedure GetProjectRegisteredUnitsNames(Units: TStrings);
    procedure GetAllRegisteredUnitsNames(Units: TStrings);
    property UnitParser[UnitName: String]: TPascalParser read GetUnitParser;
  end;

implementation

uses
  Options, 
  SourceTreeWalker;

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
begin
  Result := '';
  with TOptions.Instance do
    for I := 0 to SearchPath.Count - 1 do
      if FileExists(IncludeTrailingPathDelimiter(SearchPath[I]) + UnitName + '.pas') then
      begin
        Result := IncludeTrailingPathDelimiter(SearchPath[I]) + UnitName + '.pas';
        Break;
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
end;

destructor TUnitRegistry.Destroy;
var
  I: Integer;
begin
  for I := 0 to Units.Count - 1 do
    Units.Objects[I].Free;
  FreeAndNil(FUnits);
  inherited Destroy;
end;

function TUnitRegistry.RegisterUnit(UnitName, FileName: String; IncludedInProject: Boolean = False): TPascalParser;
begin
  UnitName := UpperCase(UnitName);
  Assert(Units.IndexOf(UnitName) = -1, Format('Error: unit "%s" already registered', [UnitName]));
  Assert(FileExists(FileName), Format('Error: file "%s" not found', [FileName]));
  Result := TPascalParser.Create;
  Result.PreserveWhiteSpaces := False;
  Result.PreserveComments := False;
  Result.Parse(FileName);
  Result.Tag := Integer(IncludedInProject);
  Units.AddObject(UnitName, Result);
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

initialization
  TUnitRegistry.Initialize;

finalization
  TUnitRegistry.Shutdown;

end.

