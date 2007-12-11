program crccalc;

{$APPTYPE CONSOLE}

uses
  Classes, SysUtils, PxCommandLine, PxCRC;

const
  VERSION = 'Version: $Id: crccalc.dpr 258 2006-06-21 00:23:20Z padcom $';
  
type
  TOptions = class (TPxCommandLineParser)
  private
    function GetHelp: Boolean;
    function GetQuiet: Boolean;
    function GetShowVersion: Boolean;
    function GetHexOutput: Boolean;
    function GetInputFileName: String;
  protected
    procedure CreateOptions; override;
    procedure AfterParseOptions; override;
  public
    property Help: Boolean read GetHelp;
    property Quiet: Boolean read GetQuiet;
    property ShowVersion: Boolean read GetShowVersion;
    property HexOutput: Boolean read GetHexOutput;
    property InputFileName: String read GetInputFileName;
  end;


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

function TOptions.GetShowVersion: Boolean;
begin
  Result := ByName['version'].Value;
end;

function TOptions.GetHexOutput: Boolean;
begin
  Result := ByName['hex'].Value;
end;

function TOptions.GetInputFileName: String;
begin
  if ByName['input-file'].WasSpecified then
    Result := ByName['input-file'].Value
  else if LeftList.Count > 0 then
    Result := LeftList[0]
  else
    Result := '';
end;

{ Protected declarations }

procedure TOptions.CreateOptions;
begin
  with AddOption(TPxBoolOption.Create('h', 'help')) do
    Explanation := 'Show help';
  with AddOption(TPxBoolOption.Create('q', 'quiet')) do
    Explanation := 'Be quiet';
  with AddOption(TPxBoolOption.Create('v', 'version')) do
    Explanation := 'Print version information';
  with AddOption(TPxBoolOption.Create('x', 'hex')) do
    Explanation := 'All outputs as hexadecimal values';
  with AddOption(TPxStringOption.Create('i', 'input-file')) do
    Explanation := 'Input file name';

  LeftListExplanation := 'filename';
end;

procedure TOptions.AfterParseOptions;
begin
  if not Quiet then
  begin
    Writeln(ExtractFileName(ParamStr(0)), ' - a CRC checksum calculator.');
    Writeln('Copyright (c) 2004, 2005 Matthias Hryniszak');
    Writeln;
  end;

  if Help then
  begin
    WriteExplanations;
    Halt(0);
  end;

  if ShowVersion then
  begin
    Writeln(VERSION);
    Halt(0);
  end;

  if InputFileName = '' then
  begin
    Writeln('Error: no input file specified');
    Halt(1);
  end
  else if not FileExists(InputFileName) then
  begin
    Writeln('Error: specified input file not found');
    Halt(2);
  end
end;

{ *** }

var
  Options: TOptions;
  InStr, OutStr: TStream;
  CRC: Word;

begin
  Options := TOptions.Create;
  try
    Options.Parse;
    InStr := TFileStream.Create(Options.InputFileName, fmOpenRead);
    if not Options.Quiet then
    begin
      Writeln('File: ', Options.InputFileName);
      Writeln('Size: ', InStr.Size);
    end;
    try
      OutStr := TMemoryStream.Create;
      try
        OutStr.CopyFrom(InStr, InStr.Size);
        CRC := CRCCompute(TMemoryStream(OutStr).Memory, OutStr.Size);
        if not Options.Quiet then
          Write('CRC : ');
        if Options.HexOutput then
          Writeln('0x', IntToHex(CRC, 4))
        else
          Writeln(CRC);
      finally
        OutStr.Free;
      end;
    finally
      InStr.Free;
    end;
  finally
    Options.Free;
  end;
end.

