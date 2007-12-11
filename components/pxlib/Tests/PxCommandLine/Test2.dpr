//
// Unloke Test1 it uses the PxCommandLineParser object direct
//
program Test2;

{$APPTYPE CONSOLE}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  PxCommandLine;

procedure WriteTitle;
begin
  Writeln;
  Writeln('Test2 - a TPxCommandLineParser test application');
  Writeln;
end;

var
  Options: TPxCommandLineParser;

begin
  Options := TPxCommandLineParser.Create;
  try
    // integer option
    with Options.AddOption(TPxIntegerOption.Create('i', 'integer', True, True)) do
      Explanation := 'This is an integer option';

    // string option
    with Options.AddOption(TPxStringOption.Create('s', 'string', True, True)) do
      Explanation := 'This is a string option';

    // path-list option
    with Options.AddOption(TPxPathListOption.Create('p', 'path', True, True)) do
      Explanation := 'This is a path list option (that means, it accepts items separated with semicolon)';

    // set option
    with TPxSetOption(Options.AddOption(TPxSetOption.Create('r', 'set', True, True))) do
    begin
      Explanation := 'This is a set option. PossibleValues must contain a list of comma-separated values with all switches, and the params is also specified with a comma-separated list.'#13#10'Currently avaible options: a,b,c';
      PossibleValues := 'a,b,c';
    end;

    //  
    // bool options:
    //
      
    // make it possible not to write a nice logo :(
    with Options.AddOption(TPxBoolOption.Create('q', 'quiet', True, True)) do
      Explanation := 'Don''t write a nice application logo (why?)';

    // and at the end - the help
    with Options.AddOption(TPxBoolOption.Create('h', 'help', True, True)) do
      Explanation := 'This help screen';
    with Options.AddOption(TPxBoolOption.Create('?')) do
      Explanation := 'Same as --help';

    Options.ParseOptions;

    // decide if a logo should be displayed
    if not TPxBoolOption(Options['quiet']).TurnedOn then
      WriteTitle;
    
    // decide if show the help and terminate
    if TPxBoolOption(Options['help']).TurnedOn or TPxBoolOption(Options.ByShortName['?']).TurnedOn then
    begin
      Options.WriteExplanations;
      Halt(0);
    end;

    // FPC: Type-casting is required while "writing" options because 
    //      Writeln doesn't support writing of Variant values well
    if Options['integer'].WasSpecified then
      Writeln('> integer = ', TPxIntegerOption(Options['integer']).Value);
//      Writeln('> integer = ', Options['integer'].Value);
    if Options['string'].WasSpecified then
      Writeln('> string = ', TPxStringOption(Options['string']).Value);
//      Writeln('> string = ', Options['string'].Value);
    if Options['path'].WasSpecified then
      Writeln('> path = ', TPxPathListOption(Options['path']).Values.Text);
//      Writeln('> path = ', Options['path']).Value);
    if Options['set'].WasSpecified then
      Writeln('> set = ', TPxSetOption(Options['set']).Values);
//      Writeln('> set = ', Options['set'].Value);
  finally  
    Options.Free;
  end;
end.
