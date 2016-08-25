unit Options;

interface

uses
  Classes, SysUtils,
  PxCommandLine, PxSettings;

type
  TOptions = class (TPxCommandLineParser)
  private
    function GetHelp: Boolean;
    function GetQuiet: Boolean;
    function GetPrintVersion: Boolean;
    function GetInputFile: String;
    function GetSearchPath: TStrings;
    function GetDumpDebugTree: Boolean;
    function GetDumpUsesTree: Boolean;
    function GetDumpAdvancedUsesTree: Boolean;
    function GetDumpCyclomaticComplexity: Boolean;
    function GetRecuseIntoUnits: Boolean;
  protected
    class procedure Initialize;
    class procedure Shutdown;
    procedure CreateOptions; override;
    procedure AfterParseOptions; override;
    procedure WriteProgramHeader;
    procedure WriteProgramVersion;
  public
    class function Instance: TOptions;
    constructor Create;
    property Help: Boolean read GetHelp;
    property Quiet: Boolean read GetQuiet;
    property PrintVersion: Boolean read GetPrintVersion;
    property InputFile: String read GetInputFile;
    property SearchPath: TStrings read GetSearchPath;
    property DumpDebugTree: Boolean read GetDumpDebugTree;
    property DumpUsesTree: Boolean read GetDumpUsesTree;
    property DumpAdvancedUsesTree: Boolean read GetDumpAdvancedUsesTree;
    property DumpCyclomaticComplexity: Boolean read GetDumpCyclomaticComplexity;
    property RecurseIntoUnits: Boolean read GetRecuseIntoUnits;
  end;

implementation

uses
  OptionsValidator;

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

function TOptions.GetPrintVersion: Boolean;
begin
  Result := ByName['version'].Value;
end;

function TOptions.GetInputFile: String;
begin
  Result := ByName['input-file'].Value;
end;

function TOptions.GetSearchPath: TStrings;
begin
  Result := TPxPathListOption(ByName['search-path']).Values;
end;

function TOptions.GetDumpDebugTree: Boolean;
begin
  Result := ByName['dump-debug-tree'].Value;
end;

function TOptions.GetDumpUsesTree: Boolean;
begin
  Result := ByName['dump-uses-tree'].Value;
end;

function TOptions.GetDumpAdvancedUsesTree: Boolean;
begin
  Result := ByName['dump-advanced-uses-tree'].Value;
end;

function TOptions.GetDumpCyclomaticComplexity: Boolean;
begin
  Result := ByName['dump-cyclomatic-complexity'].Value;
end;

function TOptions.GetRecuseIntoUnits: Boolean;
begin
  Result := ByName['recurse-units'].Value;
end;

{ Protected declarations }

var
  _Instance: TOptions = nil;

class procedure TOptions.Initialize;
begin
  _Instance := TOptions.Create;
  _Instance.Parse;
end;

class procedure TOptions.Shutdown;
begin
  Assert(Assigned(_Instance), 'Error: TOptions instance not initialized');
  FreeAndNil(_Instance);
end;

procedure TOptions.CreateOptions;
begin
  with AddOption(TPxBoolOption.Create('h', 'help')) do
    Explanation := 'Show help';
  with AddOption(TPxBoolOption.Create('q', 'quiet')) do
    Explanation := 'Be quiet';
  with AddOption(TPxBoolOption.Create(#0, 'version')) do
    Explanation := 'Print version information and exit';
  with AddOption(TPxStringOption.Create('i', 'input-file')) do
    Explanation := 'Input file (unit or delphi project)';
  with TPxPathListOption(AddOption(TPxPathListOption.Create(#0, 'search-path'))) do
  begin
    Explanation := 'Additional search path';
    Values.Add('');
  end;
  with AddOption(TPxBoolOption.Create('d', 'dump-debug-tree')) do
    Explanation := 'Dump debug source tree';
  with AddOption(TPxBoolOption.Create('u', 'dump-uses-tree')) do
    Explanation := 'Dump uses tree';
  with AddOption(TPxBoolOption.Create('a', 'dump-advanced-uses-tree')) do
    Explanation := 'Dump advanced uses tree';
  with AddOption(TPxBoolOption.Create('c', 'dump-cyclomatic-complexity')) do
    Explanation := 'Dump Cyclomatic Complexity of methods';
  with AddOption(TPxBoolOption.Create(#0, 'recurse-units')) do
    Explanation := 'Recurse into units (very slow!)';
end;

procedure TOptions.AfterParseOptions;
begin
  with TOptionsValidator.Create do
    try
      OnWriteProgramHeader := WriteProgramHeader;
      OnWriteExplanations := WriteExplanations;
      OnWriteProgramVersion := WriteProgramVersion;
      Validate;
      if ExtractFilePath(InputFile) <> '' then
      begin
        ChDir(ExtractFilePath(InputFile));
        ByName['input-file'].Value := ExtractFileName(InputFile);
      end;
    finally
      Free;
    end;
end;

procedure TOptions.WriteProgramHeader;
begin
  Writeln(ExtractFileName(ParamStr(0)), ' - Delphi Code Statistics Generator');
  Writeln('Copyright (c) 2005-2011 Matthias Hryniszak');
  Writeln;
end;

procedure TOptions.WriteProgramVersion;
begin
  Writeln('version 1.0');
  Writeln;
end;

{ Public declarations }

class function TOptions.Instance: TOptions;
begin
  Assert(Assigned(_Instance), 'Error: TOptions instance not initialized');
  Result := _Instance;
end;

constructor TOptions.Create;
begin
  Assert(not Assigned(_Instance), 'Error: TOptions is a singleton and can only be accessed using TUnitRegistry.Instance method');
  inherited Create;
end;

initialization
  TOptions.Initialize;

finalization
  TOptions.Shutdown;

end.




