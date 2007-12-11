program Test3;

{$APPTYPE CONSOLE}

uses
  Classes, SysUtils,
  PxCommandLine, PxSettings, PxGetText;
  
resourcestring
  SEnableThisOption = 'Enable this option';
  SThisHelpScreen   = 'This help screen';

type
  TOptions = class (TPxCommandLineParser)
  private
    function GetEnable: Boolean;
    function GetHelp: Boolean;
    function GetFiles: TStrings;
  protected
    procedure CreateOptions; override;
  public
    property Help: Boolean read GetHelp;
    property Enable: Boolean read GetEnable;
    property Files: TStrings read GetFiles;
  end;
  
{ TOptions }

function TOptions.GetEnable: Boolean;
begin
  Result := TPxBoolOption(ByName['enabled']).TurnedOn;
end;

function TOptions.GetHelp: Boolean;
begin
  Result := TPxBoolOption(ByName['help']).TurnedOn;
end;

function TOptions.GetFiles: TStrings;
begin
  Result := LeftList;
end;

{ Protected declarations }

procedure TOptions.CreateOptions;
begin
  with AddOption(TPxBoolOption.Create(#0, 'help')) do
    Explanation := SThisHelpScreen;

  with TPxBoolOption(AddOption(TPxBoolOption.Create('e', 'enabled'))) do
  begin
    TurnedOn := IniFile.ReadBool('Settings', 'Enable', False);
    Explanation := SEnableThisOption;
  end;
end;

var
  I: Integer;
  Opts: TOptions;

begin
  LoadDefaultLang;
  
  Opts := TOptions.Create;
  try
    Opts.ParseOptions;

    if Opts.Help then
    begin
      Opts.WriteExplanations;
      Exit;
    end;

    if Opts.Enable then
      Writeln('Enabled!');
    for I := 0 to Opts.Files.Count - 1 do
      Writeln('Files[', I, '] - ', Opts.Files[I]);
  finally
    Opts.Free;
  end;
end.

