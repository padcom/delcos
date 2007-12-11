program Test;

{$IFDEF FPC}
  // freepascal compiler
  {$MODE DELPHI}
{$ELSE}
  // delphi compiler
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
  PxCommandLine, SysUtils;

type
  //
  // This is the recomended (object-oriented) use of TPxCommandLineParser
  //
  TOptions = class (TPxCommandLineParser)
  private
    FTestBool: TPxBoolOption;
    FTestInteger: TPxIntegerOption;
    FTestString: TPxStringOption;
  protected
    procedure CreateOptions; override;
  public
    property TestBool: TPxBoolOption read FTestBool;
    property TestInteger: TPxIntegerOption read FTestInteger;
    property TestString: TPxStringOption read FTestString;
  end;

{ TOptions }

{ Protected declarations }

procedure TOptions.CreateOptions;
begin
  FTestBool := TPxBoolOption.Create('b', 'b');
  FTestBool.Explanation := 'This is an explanation for option "b"';
  AddOption(FTestBool);
  FTestInteger := TPxIntegerOption.Create('i', 'i');
  FTestInteger.Explanation := 'This is an explanation for option "i"';
  AddOption(FTestInteger);
  FTestString := TPxStringOption.Create('s', 's');
  FTestString.Explanation := 'This is an explanation for option "s"';
  AddOption(FTestString);
end;

var
  Options: TOptions;

begin
  Options := TOptions.Create;
  Options.ParseOptions;
  if Options.TestBool.TurnedOn then
    Writeln('Option specified')
  else
    Writeln('Option NOT specified');
    
  if Options.TestInteger.WasSpecified then
    Writeln('Option -i = ', Options.TestInteger.Value);
  
  if Options.TestString.WasSpecified then
    Writeln('Option -s = ', Options.TestString.Value);
  Options.Free;
end.


