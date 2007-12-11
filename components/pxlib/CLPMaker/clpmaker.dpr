program clpmaker;

{$APPTYPE CONSOLE}

uses
  Classes, SysUtils,
  PxCommandLine in '..\PxCommandLine.pas',
  PxXmlReader in '..\PxXmlReader.pas';

type
  TOptionType = (otBoolean, otString);

  TOption = class (TObject)
    Name: String;
    Kind: TOptionType;
    Short: Char;
    Long: String;
    Explanation: String;
    procedure Read(Reader: TPxXmlReader);
    procedure ReadName(Reader: TPxXmlReader);
    procedure ReadShort(Reader: TPxXmlReader);
    procedure ReadLong(Reader: TPxXmlReader);
    procedure ReadExplanation(Reader: TPxXmlReader);
  end;

  TOptionList = class (TList)
  private
    function GetItem(Index: Integer): TOption;
  public
    property Items[Index: Integer]: TOption read GetItem; default;
  end;

  TCmdLine = class (TObject)
  private
    FUnit: String;
    FClass: String;
    FOptions: TOptionList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Read(Reader: TPxXmlReader);
    procedure ReadUnit(Reader: TPxXmlReader);
    procedure ReadClass(Reader: TPxXmlReader);
    property Options: TOptionList read FOptions;
  end;

  TCodeGenerator = class (TObject)
  private
    function KindToClass(Kind: TOptionType): String;
    function KindToType(Kind: TOptionType): String;
  public
    procedure Generate(CmdLine: TCmdLine; Output: TStrings);
  end;

{ TOption }

procedure TOption.Read(Reader: TPxXmlReader);
var
  Name: String;
begin
  Name := Reader.Name;
  while Reader.Next <> xrtEof do
    case Reader.TokenType of
      xrtElementAttribute:
      begin
        if Reader.Name = 'type' then
        begin
          if Reader.Value = 'bool' then
            Kind := otBoolean
          else if Reader.Value = 'string' then
            Kind := otString
          else
            raise Exception.CreateFmt('Error: unknown option type "%s"', [Reader.Value]);
        end
        else
          raise Exception.CreateFmt('Error: unknown param for option "%s"', [Reader.Name]);
      end;
      xrtElementBegin:
      begin
        if Reader.Name = 'name' then
          ReadName(Reader)
        else if Reader.Name = 'short' then
          ReadShort(Reader)
        else if Reader.Name = 'long' then
          ReadLong(Reader)
        else if Reader.Name = 'explanation' then
          ReadExplanation(Reader)
        else
          raise Exception.CreateFmt('Error: unknown param element "%s"', [Reader.Name]); 
      end;
      xrtElementEnd:
        if Reader.Name <> 'option' then
          raise Exception.CreateFmt('Error: invalid closing tag "%s"', [Reader.Name])
        else
          Break;
    end;
end;

procedure TOption.ReadName(Reader: TPxXmlReader);
begin
  while Reader.Next <> xrtEof do
    case Reader.TokenType of
      xrtText:
        Name := Reader.Value;
      xrtElementEnd:
        Break;
    end;
end;

procedure TOption.ReadShort(Reader: TPxXmlReader);
begin
  while Reader.Next <> xrtEof do
    case Reader.TokenType of
      xrtText:
        Short := Copy(Reader.Value, 1, 1)[1];
      xrtElementEnd:
        Break;
    end;
end;

procedure TOption.ReadLong(Reader: TPxXmlReader);
begin
  while Reader.Next <> xrtEof do
    case Reader.TokenType of
      xrtText:
        Long := Reader.Value;
      xrtElementEnd:
        Break;
    end;
end;

procedure TOption.ReadExplanation(Reader: TPxXmlReader);
begin
  while Reader.Next <> xrtEof do
    case Reader.TokenType of
      xrtText:
        Explanation := Reader.Value;
      xrtElementEnd:
        Break;
    end;
end;

{ TOptionList }

{ Private declarations }

function TOptionList.GetItem(Index: Integer): TOption;
begin
  Result := TObject(Get(Index)) as TOption;
end;

{ TCmdLine }

{ Private declarations }

{ Public declarations }

constructor TCmdLine.Create;
begin
  inherited Create;
  FOptions := TOptionList.Create;
end;

destructor TCmdLine.Destroy;
var
  I: Integer;
begin
  for I := 0 to Options.Count - 1 do
    Options[I].Free;
  FreeAndNil(FOptions);
  inherited Destroy;
end;

procedure TCmdLine.Read(Reader: TPxXmlReader);
var
  Option: TOption;
begin
  while Reader.Next <> xrtEof do
    case Reader.TokenType of
      xrtElementBegin:
      begin
        if Reader.Name = 'unit' then
          ReadUnit(Reader)
        else if Reader.Name = 'class' then
          ReadClass(Reader)
        else if Reader.Name = 'option' then
        begin
          Option := TOption.Create;
          Option.Read(Reader);
          Options.Add(Option);
        end
        else
          raise Exception.CreateFmt('Error: unknown element "%s"', [Reader.Name]);
      end;
      xrtElementEnd:
      begin
        if Reader.Name = 'options' then
          Break
        else
          raise Exception.CreateFmt('Error: unknown element "%s"', [Reader.Name]);
      end;
    end;
end;

procedure TCmdLine.ReadUnit(Reader: TPxXmlReader);
begin
  while Reader.Next <> xrtEof do
    case Reader.TokenType of
      xrtText:
        FUnit := Reader.Value;
      xrtElementEnd:
        Break;
    end;
end;

procedure TCmdLine.ReadClass(Reader: TPxXmlReader);
begin
  while Reader.Next <> xrtEof do
    case Reader.TokenType of
      xrtText:
        FClass := Reader.Value;
      xrtElementEnd:
        Break;
    end;
end;

{ TCodeGenerator }

{ Private declarations }

function TCodeGenerator.KindToClass(Kind: TOptionType): String;
begin
  case Kind of
    otBoolean:
      Result := TPxBoolOption.ClassName;
    otString:
      Result := TPxStringOption.ClassName;
  end;
end;

function TCodeGenerator.KindToType(Kind: TOptionType): String;
begin
  case Kind of
    otBoolean:
      Result := 'Boolean';
    otString:
      Result := 'String';
  end;
end;

{ Public declarations }

procedure TCodeGenerator.Generate(CmdLine: TCmdLine; Output: TStrings);
var
  I: Integer;
begin
  Output.Add('unit ' + CmdLine.FUnit + ';');
  Output.Add('');
  Output.Add('interface');
  Output.Add('');
  Output.Add('uses');
  Output.Add('  Classes, SysUtils, PxCommandLine, PxSettings;');
  Output.Add('');
  Output.Add('type');
  Output.Add('  ' + CmdLine.FClass + ' = class (TPxCommandLineParser)');
  Output.Add('  private');
  for I := 0 to CmdLine.Options.Count - 1 do
    Output.Add('    function Get' + CmdLine.Options[I].Name + ': ' + KindToType(CmdLine.Options[I].Kind) + ';');
  Output.Add('  protected');
  Output.Add('    procedure CreateOptions; override;');
  Output.Add('    procedure AfterParseOptions; override;');
  Output.Add('  public');
  for I := 0 to CmdLine.Options.Count - 1 do
    Output.Add('    property ' + CmdLine.Options[I].Name + ': ' + KindToType(CmdLine.Options[I].Kind) + ' read Get' + CmdLine.Options[I].Name + ';');
  Output.Add('  end;');
  Output.Add('');
  if CmdLine.Options.Count > 0 then
  begin
    Output.Add('resourcestring');
    for I := 0 to CmdLine.Options.Count - 1 do
      Output.Add('  S' + CmdLine.Options[I].Name + ' = ''' + CmdLine.Options[I].Explanation + ''';');
    Output.Add('');
  end;
  Output.Add('implementation');
  Output.Add('');
  Output.Add('{ ' + CmdLine.FClass + ' }');
  Output.Add('');
  Output.Add('{ Private declarations }');
  Output.Add('');
  for I := 0 to CmdLine.Options.Count - 1 do
  begin
    Output.Add('function ' + CmdLine.FClass + '.Get' + CmdLine.Options[I].Name + ': ' + KindToType(CmdLine.Options[I].Kind) + ';');
    Output.Add('begin');
    Output.Add('  Result := ByName[''' + CmdLine.Options[I].Long + '''].Value;');
    Output.Add('end;');
    Output.Add('');
  end;
  Output.Add('{ Protected declarations }');
  Output.Add('');
  Output.Add('procedure ' + CmdLine.FClass + '.CreateOptions;');
  Output.Add('begin');
  for I := 0 to CmdLine.Options.Count - 1 do
  begin
    Output.Add('  with AddOption(' + KindToClass(CmdLine.Options[I].Kind) + '.Create(''' + CmdLine.Options[I].Short + ''', ''' + CmdLine.Options[I].Long + ''')) do');
    Output.Add('  begin');
    Output.Add('    Value := IniFile.ReadString(''options'', ''' + CmdLine.Options[I].Long + ''', '''');');
    Output.Add('    Explanation := S' + CmdLine.Options[I].Name + ';');
    Output.Add('  end;');
  end;
  Output.Add('end;');
  Output.Add('');
  Output.Add('procedure ' + CmdLine.FClass + '.AfterParseOptions;');
  Output.Add('begin');
  Output.Add('');
  Output.Add('end;');
  Output.Add('');
  Output.Add('end.');
  Output.Add('');
end;

{ *** }

const
  VERSION = 'Version: $Id: clpmaker.dpr 258 2006-06-21 00:23:20Z padcom $';

type
  TOptions = class (TPxCommandLineParser)
  private
    function GetHelp: Boolean;
    function GetQuiet: Boolean;
    function GetShowVersion: Boolean;
    function GetInputFile: String;
    function GetOutputFile: String;
  protected
    procedure CreateOptions; override;
    procedure AfterParseOptions; override;
  public
    property Help: Boolean read GetHelp;
    property Quiet: Boolean read GetQuiet;
    property ShowVersion: Boolean read GetShowVersion;
    property InputFile: String read GetInputFile;
    property OutputFile: String read GetOutputFile;
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

function TOptions.GetInputFile: String;
begin
  Result := ByName['input-file'].Value;
  if (Result = '') and (FLeftList.Count > 0) then
    Result := FLeftList[0];
end;

function TOptions.GetOutputFile: String;
begin
  Result := ByName['output-file'].Value;
  if (Result = '') and (FLeftList.Count > 1) then
    Result := FLeftList[1];
end;

{ Protected declarations }

procedure TOptions.CreateOptions;
begin
  with AddOption(TPxBoolOption.Create('h', 'help')) do
    Explanation := 'Show help';
  with AddOption(TPxBoolOption.Create('q', 'quiet')) do
    Explanation := 'Be quiet (no logo or program informations are displayed)';
  with AddOption(TPxBoolOption.Create('v', 'version')) do
    Explanation := 'Show version information';
  with AddOption(TPxStringOption.Create('i', 'input-file')) do
    Explanation := 'Input file (.xml)';
  with AddOption(TPxStringOption.Create('o', 'output-file')) do
    Explanation := 'Output file (.pas)';

  LeftListExplanation := 'input-file output-file';
end;

procedure TOptions.AfterParseOptions;
begin
  if not Quiet then
  begin
    Writeln(ExtractFileName(ParamStr(0)), ' - code generator for PxCommandLine unit');
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

  if InputFile = '' then
  begin
    Writeln('Error: no input file specified');
    Halt(1);
  end;
end;

procedure ReadSettings(Reader: TPxXmlReader; var CmdLine: TCmdLine);
begin
  try
    while Reader.Next <> xrtEof do
      case Reader.TokenType of
        xrtElementBegin:
        begin
          if Reader.Name = 'options' then
          begin
            CmdLine := TCmdLine.Create;
            CmdLine.Read(Reader);
          end
          else
            raise Exception.CreateFmt('Error: unknown element "%s"', [Reader.Name]);
        end;
        xrtElementEnd:
        begin
          if Reader.Name <> 'options' then
            raise Exception.CreateFmt('Error: unknown element "%s"', [Reader.Name])
          else
            Break;
        end;
      end;
  except
    on E: Exception do
    begin
      Writeln(E.Message);
      Halt(2);
    end;
  end;
end;

var
  Options: TOptions;
  Reader: TPxXmlReader;
  CmdLine: TCmdLine;
  CodeGen: TCodeGenerator;
  Output: TStrings;

begin
  Options := TOptions.Create;
  try
    Options.Parse;

    Reader := TPxXmlReader.Create;
    Reader.Open(Options.InputFile);

    ReadSettings(Reader, CmdLine);
    if Assigned(CmdLine) then
    begin
      Output := TStringList.Create;
      try
        CodeGen := TCodeGenerator.Create;
        try
          CodeGen.Generate(CmdLine, Output);
          if Options.OutputFile <> '' then
            Output.SaveToFile(Options.OutputFile)
          else
            Writeln(Output.Text)
        finally
          CodeGen.Free;
        end;
      finally
        Output.Free;
      end;
    end;
  finally
    Options.Free;
  end;
end.

