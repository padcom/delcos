unit Options;

interface

uses
  Classes, SysUtils,
  PxSettings, PxCommandLine;
  
type
  TOptions = class (TPxCommandLineParser)
  private
    function GetHelp: Boolean;
    function GetQuiet: Boolean;
    function GetDTDFile: String;
    function GetUnitName: String;
  protected
    procedure CreateOptions; override;
    procedure AfterParseOptions; override;
  public
    constructor Create; override;
    destructor Destroy; override;
    class function Instance: TOptions;
    property Help: Boolean read GetHelp;
    property Quiet: Boolean read GetQuiet;
    property DTDFile: String read GetDTDFile;
    property UnitName: String read GetUnitName;
  end;

implementation

{ TOptions }

{ Private declarations }

function TOptions.GetHelp: Boolean;
begin
  Result := ByName['help'].Value;
end;

function TOptions.GetQuiet: Boolean;
begin
  Result := ByName['quiet'].Value;
end;

function TOptions.GetDTDFile: String;
begin
  Result := ByName['dtd-file'].Value;
end;

function TOptions.GetUnitName: String;
begin
  Result := ByName['unit'].Value;
end;

{ Protected declarations }

procedure TOptions.CreateOptions; 
begin
  with AddOption(TPxBoolOption.Create('h', 'help')) do
    Explanation := 'Show help';
  with AddOption(TPxBoolOption.Create('q', 'quiet')) do
    Explanation := 'Be quiet';
  with AddOption(TPxStringOption.Create('d', 'dtd-file')) do
    Explanation := 'Input DTD file';
  with AddOption(TPxStringOption.Create('u', 'unit')) do
    Explanation := 'Unit output name';
end;

procedure TOptions.AfterParseOptions; 
begin
  if not Quiet then
  begin
    Writeln(Format('%s - create classes that read data from an Xml file', [ExtractFileName(ParamStr(0))]));
    Writeln;
  end;
  
  if Help then
  begin
    WriteExplanations;
    Halt(0);
  end;
  
  if DTDFile = '' then
  begin
    Writeln('Error: no DTD file specified!');
    Halt(1);
  end;

  if UnitName = '' then
  begin
    Writeln('Error: no unit name specified!');
    Halt(1);
  end;
end;

{ Public declarations }

var
  _Options: TOptions;

constructor TOptions.Create; 
begin
  Assert(_Options = nil, 'Error: TOptions is a singleton and should only be accessed through TOptions.Instance method');
  inherited Create;
  _Options := Self;
end;

destructor TOptions.Destroy; 
begin
  _Options := nil;
  inherited Destroy;
end;

class function TOptions.Instance: TOptions;
begin
  Assert(_Options <> nil, 'Error: TOptions instance has not been initialized');
  Result := _Options;
end;

initialization
  TOptions.Create.Parse;

finalization
  TOptions.Instance.Free;
    
end.

