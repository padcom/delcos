program ERISGen;

{$IFNDEF FPC}
  {$APPTYPE CONSOLE}
{$ENDIF}

{Access to DataFile.pas}
{Access to BaseTypes.pas}

uses
  Classes, SysUtils, PxDataFile, PxDataFileGenerator, PxCommandLine, PxUtils;

type
  TOptions = class (TPxCommandLineParser)
  private
    FHelp: TPxBoolOption;
    FQuiet: TPxBoolOption;
    FInputFile: TPxStringOption;
    FOutputFile: TPxStringOption;
    function GetHelp: Boolean;
    function GetQuiet: Boolean;
    function GetInputFile: String;
    function GetOutputFile: String;
  protected
    procedure CreateOptions; override;
    procedure AfterParseOptions; override;
  public
    property Help: Boolean read GetHelp;
    property Quiet: Boolean read GetQuiet;
    property InputFile: String read GetInputFile;
    property OutputFile: String read GetOutputFile;
  end;

{ TOptions }

{ Private declarations }

function TOptions.GetHelp: Boolean;
begin
  Result := FHelp.WasSpecified;
end;

function TOptions.GetQuiet: Boolean;
begin
  Result := FQuiet.WasSpecified;
end;

function TOptions.GetInputFile: String;
begin
  Result := FInputFile.Value;
end;

function TOptions.GetOutputFile: String;
begin
  Result := FOutputFile.Value;
end;

{ Protected declarations }

procedure TOptions.CreateOptions;
begin
  FHelp := TPxBoolOption.Create('h', 'help', False);
  FHelp.Explanation := 'Print this help screen';
  AddOption(FHelp);
  FQuiet := TPxBoolOption.Create('q', 'quiet', False);
  FQuiet.Explanation := 'Be quiet (no logo is displayed)';
  AddOption(FQuiet);
  FInputFile := TPxStringOption.Create('i', 'input-file', False);
  FInputFile.Explanation := 'Input (.xdf) file with data file definitions';
  AddOption(FInputFile);
  FOutputFile := TPxStringOption.Create('o', 'output-file', False);
  FOutputFile.Explanation := 'Output (.pas) file. If not specified the file name is taken from the data file definition in source file';
  AddOption(FOutputFile);
end;

procedure TOptions.AfterParseOptions;
begin
  if not Quiet then
  begin
    Writeln('ERISGen.exe - DataFile generator v2.0');
    Writeln('Copyright 2004, 2005 - Matthias Hryniszak');
    Writeln;
  end;

  if Help then
  begin
    WriteExplanations;
    Halt(0);
  end;

  if LeftList.Count > 0 then
  begin
    Writeln('Error: unknown option ', LeftList[0]);
    Halt(1);
  end;

  if InputFile = '' then
  begin
    Writeln('Error: no input file specified!');
    Halt(2);
  end;

  if InputFile = OutputFile then
  begin
    Writeln('Error: input file is the same as output file');
    Halt(3);
  end;
end;

{ *** }

var
  Options: TOptions;
  FileName: String = '';

begin
  Options := TOptions.Create;
  try
    Options.Parse;
    try
      FileName := Options.InputFile;
      if GenerateDataFile(FileName, Options.OutputFile) then
      begin
        if not Options.Quiet then
          Writeln('Writting output file ', FileName, ' ... done');
      end
      else
      begin
        Writeln('Error');
        Writeln;
        Writeln(ErrorMsg);
        Halt(3);
      end;
    except
      on E: Exception do
      begin
        Writeln(String(ExceptionToString(E)));
        Halt;
      end
    end;
  finally
    Options.Free
  end;
end.
