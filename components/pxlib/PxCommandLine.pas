// ----------------------------------------------------------------------------
// Unit        : PxCommandLine.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2005-04-11
// Version     : 1.0
// Description : Command-line utilities
// Changes log : 2005-04-11 - initial version (based on Johannes Berg's
//                            OptionParser unit)
//                          - removed dependencies with WrapText unit
//               2005-04-18 - some cleanup, additional example (Test2.dpr)
//               2005-11-03 - added possibility to "name" the FLeftList via
//                            TPxCommandLineParser.FLeftListExplanation field
//               2006-04-09 - removed TPxDefCommandLineParser
//                          - changed visibility of some TPxCommandLineParser
//                            methods and properties. Now it's mandatory to
//                            derivate a new class from it. Although it's not
//                            mandatory it's strongly suggested that this class
//                            is created as a singleton
//                          - code cleanup
// ToDo        : Testing, comments in code.
// ----------------------------------------------------------------------------

unit PxCommandLine;

{$I PxDefines.inc}

interface

uses
  Classes, SysUtils;

const
  // default short option character used
  DefShortOptionChar = '-';
  // default long option string used
  DefLongOptionString = '--';

type
  TPxCommandLineParser = class;
  // @abstract(abstract base class for options)
  // This class implements all the basic functionality and provides
  // abstract methods for the @link(TPxCommandLineParser) class to call, which are
  // overridden by descendants.
  // It also provides function to write the explanation.
  TPxOption = class
  protected
    FShort: Char;
    FLong: string;
    FShortSens: Boolean;
    FLongSens: Boolean;
    FExplanation: WideString;
    FWasSpecified: Boolean;
    FParser: TPxCommandLineParser;
    function ParseOption(const AWords: TStrings): Boolean; virtual; abstract;
    function GetValue: Variant; virtual; abstract;
    procedure SetValue(const AValue: Variant); virtual; abstract;
  public
    // Create a new Option, almost never overridden. Set AShort to #0 in order
    // to have no short option.
    constructor Create(const AShort: Char); overload; virtual;
    constructor Create(const AShort: Char; const ALong: string); overload; virtual;
    constructor Create(const AShort: Char; const ALong: string; const AShortCaseSensitive: Boolean); overload; virtual;
    constructor Create(const AShort: Char; const ALong: string; const AShortCaseSensitive: Boolean; const ALongCaseSensitive: Boolean); overload; virtual;
    // returns the width of the string "-s, --long-option" where s is the short option.
    // Removes non-existant options (longoption = '' or shortoption = #0)
    function GetOptionWidth: Integer;
    // writes the wrapped explanation including option format,
    // AOptWidth determines how much it is indented & wrapped
    procedure WriteExplanation(const AOptWidth: Integer);
    // Short form of the option - single character - if #0 then not used }
    property ShortForm: Char read FShort write FShort;
    // long form of the option - string - if empty, then not used
    property LongForm: string read FLong write FLong;
    // specified whether the short form should be case sensitive or not
    property ShortCaseSensitive: Boolean read FShortSens write FShortSens;
    // specifies whether the long form should be case sensitive or not
    property LongCaseSensitive: Boolean read FLongSens write FLongSens;
    // signifies if the option was specified at least once
    property WasSpecified: Boolean read FWasSpecified;
    // explanation for the option, see also @link(WriteExplanation)
    property Explanation: WideString read FExplanation write FExplanation;
    // Value as Variant - for easier access through the @link(TPxCommandLineParser.ByName) property
    property Value: Variant read GetValue write SetValue;
  end;

  // @abstract(simple Boolean option)
  // turned off when not specified,
  // turned on when specified. Cannot handle --option=false et al.
  TPxBoolOption = class(TPxOption)
  protected
    function ParseOption(const AWords: TStrings): Boolean; override;
    function GetValue: Variant; override;
    procedure SetValue(const AValue: Variant); override;
  public
    property TurnedOn: Boolean read FWasSpecified write FWasSpecified;
  end;

  // @abstract(base class for all options that values)
  // base class for all options that take one or more values
  // of the form --option=value or --option value etc }
  TPxValueOption = class(TPxOption)
  protected
    function CheckValue(const AString: String): Boolean; virtual; abstract;
    function ParseOption(const AWords: TStrings): Boolean; override;
  end;

  // @abstract(Integer option)
  // accepts only Integers
  TPxIntegerOption = class(TPxValueOption)
  protected
    FValue: Integer;
    function CheckValue(const AString: String): Boolean; override;
    function GetValue: Variant; override;
    procedure SetValue(const AValue: Variant); override;
  public
    property Value: Integer read FValue write FValue;
  end;

  // @abstract(String option)
  // accepts a single string
  TPxStringOption = class(TPxValueOption)
  protected
    FValue: String;
    function CheckValue(const AString: String): Boolean; override;
    function GetValue: Variant; override;
    procedure SetValue(const AValue: Variant); override;
  public
    property Value: String read FValue write FValue;
  end;

  // @abstract(stringlist option)
  // accepts multiple strings and collates them
  // even if the option itself is specified more than one time
  TPxStringListOption = class(TPxValueOption)
  protected
    FValues: TStringList;
    function CheckValue(const AString: String): Boolean; override;
    function GetValue: Variant; override;
    procedure SetValue(const AValue: Variant); override;
  public
    constructor Create(const AShort: Char; const ALong: String; const AShortCaseSensitive, ALongCaseSensitive: Boolean); overload; override;
    destructor Destroy; override;
    property Values: TStringList read FValues;
  end;

  // @abstract(pathlist option)
  // accepts multiple strings paths and collates them
  // even if the option itself is specified more than one time.
  // Paths in a single option can be separated by the
  // DirectorySeparator
  TPxPathListOption = class(TPxStringListOption)
    function CheckValue(const AString: String): Boolean; override;
  end;

  // @abstract(useful for making a choice of things)
  // Values must not have a + or - sign as the last character as that
  // can be used to add/remove items from the default set, specifying
  // items without +/- at the end clears the default and uses only
  // specified items
  TPxSetOption = class(TPxValueOption)
  protected
    FPossibleValues,
    FValues: TStringList;
    function GetPossibleValues: string;
    procedure SetPossibleValues(const Value: string);
    function CheckValue(const AString: String): Boolean; override;
    function GetValue: Variant; override;
    procedure SetValue(const AValue: Variant); override;
    function GetValues: string;
    procedure SetValues(const Value: string);
  public
    constructor Create(const AShort: Char; const ALong: String; const AShortCaseSensitive, ALongCaseSensitive: Boolean); overload; override;
    destructor Destroy; override;
    function HasValue(const AValue: string): Boolean;
    property PossibleValues: string read GetPossibleValues write SetPossibleValues;
    property Values: string read GetValues write SetValues;
  end;

  // @abstract(OptionParser - instantiate one of these for commandline parsing)
  // This class is the main parsing class, although a lot of parsing is handled
  // by @link(TPxOption) and its descendants instead.
  TPxCommandLineParser = class
  private
    FLeftListExplanation: string;
    function GetMaxOptLen: Integer;
  protected
    FParams: TStringList;
    FOptions: TList;
    FLeftList: TStringList;
    FShortOptionChar: Char;
    FLongOptionString: string;
    // additional information to print at the end of command line format explanation
    // for example:
    //  Usage: crccalc.exe [Options] filename
    // the text "filename" comes directly from this variable
    property LeftListExplanation: string read FLeftListExplanation write FLeftListExplanation;
    function GetOption(const AIndex: Integer): TPxOption;
    function GetOptionsCount: Integer;
    function GetOptionByLongName(const AName: string): TPxOption;
    function GetOptionByShortname(const AName: Char): TPxOption;
    procedure CreateOptions; virtual;
    procedure AfterParseOptions; virtual;
  public
    // Create without any options - this will parse the current command line
    constructor Create;
    // destroy the option parser object and all associated @link(TPxOption) objects
    destructor Destroy; override;
    // Add a @link(TPxOption) descendant to be included in parsing the command line
    function AddOption(const AOption: TPxOption): TPxOption;
    // Parse the specified command line, see also @link(Create)
    procedure Parse;
    procedure ParseOptions(AParams: TStrings = nil); overload;
    procedure ParseOptions(AParams: String); overload;
    // output explanations for all options to stdout, will nicely format the
    // output and wrap explanations
    procedure WriteExplanations;
    // This StringList contains all the items from the command line that could
    // not be parsed. Includes options that didn't accept their value and
    // non-options like filenames specified on the command line
    property LeftList: TStringList read FLeftList;
    // The number of option objects that were added to this parser
    property OptionsCount: Integer read GetOptionsCount;
    // retrieve an option by index - you can use this and @link(OptionsCount)
    // to iterate through the options that this parser owns
    property Options[const AIndex: Integer]: TPxOption read GetOption;
    // retrieve an option by its long form. Case sensitivity of the options
    // is taken into account!
    property ByName[const AName: string]: TPxOption read GetOptionByLongName; default;
    // retrieve an option by its short form. Case sensitivity of the options
    // is taken into account!
    property ByShortName[const AName: Char]: TPxOption read GetOptionByShortname;
    // introductory character to be used for short options
    property ShortOptionStart: Char read FShortOptionChar write FShortOptionChar default DefShortOptionChar;
    // introductory string to be used for long options
    property LongOptionStart: String read FLongOptionString write FLongOptionString;
    // max length of all options (used by WriteExplanation method)
    property MaxOptLen: Integer read GetMaxOptLen;
  end;

implementation

uses
{$IFDEF VER130}
  PxDelphi5,
  Consts,
{$ENDIF}
{$IFDEF VER150}
  RtlConsts,
{$ENDIF}
  PxResources;

{ TPxCommandLineParser }

constructor TPxCommandLineParser.Create;
begin
  inherited Create;
  FParams := TStringList.Create;
  FLeftList := TStringList.Create;
  FOptions := TList.Create;

  FLongOptionString := DefLongOptionString;
  FShortOptionChar := DefShortOptionChar;

  CreateOptions;
end;

destructor TPxCommandLineParser.Destroy;
var
  i: Integer;
begin
  for i := FOptions.Count-1 downto 0 do
    TPxOption(FOptions[i]).Free;
  FLeftList.Free;
  FParams.Free;
  FOptions.Free;
  inherited;
end;

function TPxCommandLineParser.AddOption(const AOption: TPxOption): TPxOption;
begin
  FOptions.Add(AOption);
  Result := AOption;
  AOption.FParser := Self;
end;

procedure TPxCommandLineParser.Parse;
begin
  ParseOptions;
end;

procedure TPxCommandLineParser.ParseOptions(AParams: TStrings = nil);
var
  LCopyList: TStringList;
  i: Integer;
  LFoundSomething: Boolean;
begin
  FParams.Clear;
  if Assigned(AParams) then
    FParams.Assign(AParams)
  else
    for i := 1 to ParamCount do
      FParams.Add(ParamStr(i));

  LCopyList := TStringList.Create;
  LCopyList.Assign(FParams);
  FLeftList.Clear;
  try
    while LCopyList.Count > 0 do
    begin
      LFoundSomething := False;
      for i := 0 to FOptions.Count-1 do
      begin
        if TPxOption(FOptions[i]).ParseOption(LCopyList) then
        begin
          LFoundSomething := true;
          break;
        end;
      end;
      if not LFoundSomething then
      begin
        FLeftList.Add(LCopyList[0]);
        LCopyList.Delete(0);
      end;
    end;
    AfterParseOptions;
  finally
    LCopyList.Free;
  end;
end;

procedure TPxCommandLineParser.ParseOptions(AParams: String);
var
  I: Integer;
  S: String;
  InQuote: Boolean;
  Params: TStrings;
begin
  Params := TStringList.Create;
  try
    InQuote := False;
    for I := 1 to Length(AParams) do
    begin
      if (AParams[I] = ' ') and (not InQuote) then
      begin
        Params.Add(S);
        S := '';
      end
      else if AParams[I] = '"' then
      begin
        InQuote := not InQuote;
        if S <> '' then
        begin
          Params.Add(S);
          S := '';
        end;
      end
      else
        S := S + AParams[I];
    end;
    if S <> '' then
      Params.Add(S);
    ParseOptions(Params);
  finally
    Params.Free;
  end;
end;

function TPxCommandLineParser.GetOptionsCount: Integer;
begin
  Result := FOptions.Count;
end;

function TPxCommandLineParser.GetOption(const AIndex: Integer): TPxOption;
begin
  Result := TPxOption(FOptions[AIndex]);
end;

procedure TPxCommandLineParser.WriteExplanations;
  function Max(const A,B: Integer): Integer;
  begin
    if A>B then Result := A else Result := B;
  end;
var
  i: Integer;
  LMaxWidth: Integer;
begin
  LMaxWidth := MaxOptLen;
  Writeln('Usage: ', ExtractFileName(ParamStr(0)), ' [Options] ', FLeftListExplanation);
  Writeln;
  for i := 0 to OptionsCount-1 do
    Options[i].WriteExplanation(LMaxWidth);
end;

function TPxCommandLineParser.GetOptionByLongName(const AName: string): TPxOption;
var
  i: Integer;
begin
  Result := nil;
  for i := GetOptionsCount-1 downto 0 do
    if (Options[i].LongForm = AName) OR (Options[i].LongCaseSensitive AND (LowerCase(Options[i].LongForm) = LowerCase(AName))) then
    begin
      Result := Options[i];
      Break;
    end;
end;

function TPxCommandLineParser.GetOptionByShortname(const AName: Char): TPxOption;
var
  i: Integer;
begin
  Result := nil;
  for i := GetOptionsCount-1 downto 0 do
    if (Options[i].ShortForm = AName) OR (Options[i].LongCaseSensitive AND (LowerCase(Options[i].ShortForm) = LowerCase(AName))) then
    begin
      Result := Options[i];
      Break;
    end;
end;

procedure TPxCommandLineParser.CreateOptions;
begin
end;

procedure TPxCommandLineParser.AfterParseOptions;
begin
end;

function TPxCommandLineParser.GetMaxOptLen: Integer;
  function Max(const A,B: Integer): Integer;
  begin
    if A>B then Result := A else Result := B;
  end;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to OptionsCount-1 do
    Result := Max(Result, Options[i].GetOptionWidth);
end;

{ TPxOption }

constructor TPxOption.Create(const AShort: Char; const ALong: string; const AShortCaseSensitive, ALongCaseSensitive: Boolean);
begin
  inherited Create;
  FShort := AShort;
  FLong := ALong;
  FShortSens := AShortCaseSensitive;
  FLongSens := ALongCaseSensitive;
end;

constructor TPxOption.Create(const AShort: Char);
begin
  Create(AShort, '', True, False);
end;

constructor TPxOption.Create(const AShort: Char; const ALong: string);
begin
  Create(AShort, ALong, True, False);
end;

constructor TPxOption.Create(const AShort: Char; const ALong: string; const AShortCaseSensitive: Boolean);
begin
  Create(AShort, ALong, AShortCaseSensitive, False);
end;

function TPxOption.GetOptionWidth: Integer;
begin
  Result := 0;
  Inc(Result, 4); // "-x, "
  if Length(LongForm)>0 then
    Inc(Result, Length(LongForm)+Length(FParser.LongOptionStart))
  else
    Dec(Result, 2);
end;

procedure TPxOption.WriteExplanation(const AOptWidth: Integer);
  procedure WriteBlank(const ANumber: Integer);
  var
    j: Integer;
  begin
    for j := ANumber-1 downto 0 do
      Write(' ');
  end;
var
  LLines: TStringList;
  i: Integer;
  LWritten: Integer;
begin
  Write('  ');
  LWritten := 2;
  if ShortForm <> #0 then
  begin
    Write(FParser.ShortOptionStart, ShortForm);
    Inc(LWritten, 2);
    if Length(LongForm) > 0 then
    begin
      Write(', ');
      Inc(LWritten, 2);
    end;
  end
  else
  begin
    Write('    ');
    Inc(LWritten, 4);
  end;
  if Length(LongForm)>0 then
  begin
    Write(FParser.LongOptionStart, LongForm);
    Inc(LWritten, Length(FParser.LongOptionStart) + Length(LongForm));
  end;
  Write(' ');
  Inc(LWritten, 1);
  LLines := TStringList.Create;
  LLines.Text := WrapText(Explanation, 77 - AOptWidth);
  for i := 0 to LLines.Count-1 do
  begin
    if Length(LLines[i]) > 0 then
    begin
      // WrapText has a bug...
      if i = 0 then
        WriteBlank(AOptWidth + 4 - LWritten)
      else
        WriteBlank(AOptWidth + 4);
      WriteLn(LLines[i]);
    end;
  end;
  LLines.Free;
end;

{ TPxBoolOption }

function TPxBoolOption.GetValue: Variant;
begin
  Result := WasSpecified;
end;

function TPxBoolOption.ParseOption(const AWords: TStrings): Boolean;
begin
  Result := False;
  if ShortForm <> #0 then
  begin
    if AWords[0] = FParser.ShortOptionStart+ShortForm then
    begin
      Result := True;
      AWords.Delete(0);
      FWasSpecified := True;
    end
    else if (not ShortCaseSensitive) and (LowerCase(AWords[0]) = FParser.ShortOptionStart+LowerCase(ShortForm)) then
    begin
      Result := True;
      AWords.Delete(0);
      FWasSpecified := True;
    end;
  end;

  if (not Result) and (Length(LongForm) > 0) then
  begin
    if AWords[0] = FParser.LongOptionStart+LongForm then
    begin
      Result := True;
      AWords.Delete(0);
      FWasSpecified := True;
    end
    else if (not LongCaseSensitive) and (LowerCase(AWords[0]) = FParser.LongOptionStart+LowerCase(LongForm)) then
    begin
      Result := True;
      AWords.Delete(0);
      FWasSpecified := True;
    end;
  end;
end;

procedure TPxBoolOption.SetValue(const AValue: Variant);
begin
  FWasSpecified := AValue;
end;

{ TPxValueOption }

function TPxValueOption.ParseOption(const AWords: TStrings): Boolean;
var
  LValue: string;
begin
  Result := False;
  if ShortForm <> #0 then
  begin
    if (Copy(AWords[0],1,Length(FParser.ShortOptionStart+ShortForm)) = FParser.ShortOptionStart+ShortForm) OR ((not ShortCaseSensitive) and (LowerCase(Copy(AWords[0],1,Length(FParser.ShortOptionStart+ShortForm))) = FParser.ShortOptionStart+LowerCase(ShortForm))) then
    begin
      LValue := Copy(AWords[0], Length(FParser.ShortOptionStart+ShortForm)+1, MaxInt);
      if LValue = '' then
      begin
        if AWords.Count>1 then
        begin
          LValue := AWords[1];
          if CheckValue(LValue) then
          begin
            Result := True;
            AWords.Delete(0);
            AWords.Delete(0);
          end
          else
          begin
            Result := CheckValue('');
            if Result then
              AWords.Delete(0);
          end;
        end
        else
        begin
          Result := CheckValue(LValue);
          if Result then
            AWords.Delete(0);
        end;
      end
      else
      begin
        Result := CheckValue(LValue);
        if Result then
          AWords.Delete(0);
      end;
    end;
  end;
  if Result then FWasSpecified := True;
  if (not Result) and (Length(LongForm) > 0) then
  begin
    if (Copy(AWords[0],1,Length(FParser.LongOptionStart+LongForm)) = FParser.LongOptionStart+LongForm) OR ((not LongCaseSensitive) AND (LowerCase(Copy(AWords[0],1,Length(FParser.LongOptionStart+LongForm))) = FParser.LongOptionStart+LowerCase(LongForm))) then
    begin
      if Length(AWords[0]) = Length(FParser.LongOptionStart+LongForm) then
      begin
        if AWords.Count>1 then
          LValue := AWords[1]
        else
          LValue := '';
        Result := CheckValue(LValue);
        if Result then
        begin
          AWords.Delete(0);
          if AWords.Count>0 then
            AWords.Delete(0);
        end;
      end
      else if Copy(AWords[0], Length(FParser.LongOptionStart+LongForm)+1, 1) = '=' then
      begin
        LValue := Copy(AWords[0], Length(FParser.LongOptionStart+LongForm)+2, MaxInt);
        Result := CheckValue(LValue);
        if Result then
          AWords.Delete(0);
      end;
    end;
  end;
  if Result then FWasSpecified := True;
end;

{ TPxIntegerOption }

function TPxIntegerOption.CheckValue(const AString: String): Boolean;
var
  LValue: Integer;
begin
  Result := TryStrToInt(AString, LValue);
  if Result then FValue := LValue;
end;

function TPxIntegerOption.GetValue: Variant;
begin
  Result := FValue;
end;

procedure TPxIntegerOption.SetValue(const AValue: Variant);
begin
  FValue := AValue;
end;

{ TPxStringOption }

function TPxStringOption.CheckValue(const AString: String): Boolean;
begin
  FValue := AString;
  Result := True;
end;

function TPxStringOption.GetValue: Variant;
begin
  Result := FValue;
end;

procedure TPxStringOption.SetValue(const AValue: Variant);
begin
  FValue := AValue;
end;

{ TPxStringOptionList }

function TPxStringListOption.CheckValue(const AString: String): Boolean;
begin
  Result := True;
  FValues.Add(AString);
end;

constructor TPxStringListOption.Create(const AShort: Char; const ALong: String; const AShortCaseSensitive, ALongCaseSensitive: Boolean);
begin
  inherited;
  FValues := TStringList.Create;
end;

destructor TPxStringListOption.Destroy;
begin
  FValues.Free;
  inherited;
end;

function TPxStringListOption.GetValue: Variant;
begin
  Result := FValues.Text;
end;

procedure TPxStringListOption.SetValue(const AValue: Variant);
begin
  FValues.Text := AValue;
end;

{ TPxSetOption }

function TPxSetOption.CheckValue(const AString: String): Boolean;
var
  LList,
  LResult: TStringList;
  i: Integer;
  s: string;
  si: Integer;
  LCleared: Boolean;
begin
  Result := True;
  LCleared := false;
  LList := TStringList.Create;
  LResult := TStringList.Create;
  try
    LList.Duplicates := dupIgnore;
    LList.CommaText := AString;
    LList.Sorted := True;
    LResult.Assign(FValues); // default values
    LResult.Duplicates := dupIgnore;
    LResult.Sorted := True;
    i := 0;
    while i < LList.Count do
    begin
      s := LList[i];
      if Length(s) = 0 then continue;
      case s[length(s)] of
        '-':
        begin
          SetLength(s, Length(s)-1);
          if FPossibleValues.IndexOf(s) >= 0 then
          begin
            si := LResult.IndexOf(s);
            if si>=0 then
              LResult.Delete(si);
          end
          else
          begin
            Result := false;
            Break;
          end;
        end;
        '+':
        begin
          SetLength(s, Length(s)-1);
          if FPossibleValues.IndexOf(s) >= 0 then
            LResult.Add(s)
          else
          begin
            Result := false;
            Break;
          end;
        end;
        else
        begin
          if FPossibleValues.IndexOf(s) >= 0 then
            LResult.Add(s)
          else
          begin
            Result := false;
            Break;
          end;
          if not LCleared then
          begin
            LCleared := True;
            LResult.Clear;
            i := -1; // restart from beginning
          end;
        end;
      end;
      Inc(i);
    end;
  finally
    LList.Free;
    FValues.Assign(LResult);
    LResult.Free;
  end;
end;

constructor TPxSetOption.Create(const AShort: Char; const ALong: String; const AShortCaseSensitive, ALongCaseSensitive: Boolean);
begin
  inherited;
  FPossibleValues := TStringList.Create;
  FPossibleValues.Duplicates := dupIgnore;
  FPossibleValues.Sorted := True;
  FValues := TStringList.Create;
  FValues.Duplicates := dupIgnore;
  FValues.Sorted := True;
end;

destructor TPxSetOption.Destroy;
begin
  FPossibleValues.Free;
  FValues.Free;
  inherited;
end;

function TPxSetOption.GetPossibleValues: string;
begin
  Result := FPossibleValues.CommaText;
end;

function TPxSetOption.GetValue: Variant;
begin
  Result := FValues.CommaText;
end;

function TPxSetOption.GetValues: string;
begin
  Result := FValues.CommaText;
end;

function TPxSetOption.HasValue(const AValue: string): Boolean;
begin
  Result := FValues.IndexOf(AValue)>=0;
end;

procedure TPxSetOption.SetPossibleValues(const Value: string);
begin
  FPossibleValues.CommaText := Value;
end;

procedure TPxSetOption.SetValue(const AValue: Variant);
begin
  FValues.CommaText := AValue;
end;

procedure TPxSetOption.SetValues(const Value: string);
begin
  FValues.CommaText := Value;
end;

{ TPxPathListOption }

function TPxPathListOption.CheckValue(const AString: String): Boolean;
var
  LValues: TStringList;
begin
  Result := true;
  LValues := TStringList.Create;
  LValues.Text := StringReplace(AString, PathSep, SLineBreak, [rfReplaceAll]);
  FValues.AddStrings(LValues);
  LValues.Free;
end;

end.
