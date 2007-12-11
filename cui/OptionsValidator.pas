unit OptionsValidator;

interface

uses
  Classes, SysUtils, IniFiles;

type
  TConsoleOutputEvent = procedure of object;

  TOptionsValidator = class (TObject)
  private
    FOnWriteProgramHeader: TConsoleOutputEvent;
    FOnWriteExplanations: TConsoleOutputEvent;
    FOnWriteProgramVersion: TConsoleOutputEvent;
    procedure UpdateSearchPathFromDOFFile;
  protected
    procedure DoWriteProgramHeader;
    procedure DoWriteExplanations;
    procedure DoWriteProgramVersion;
  public
    procedure Validate;
    property OnWriteProgramHeader: TConsoleOutputEvent read FOnWriteProgramHeader write FOnWriteProgramHeader;
    property OnWriteExplanations: TConsoleOutputEvent read FOnWriteExplanations write FOnWriteExplanations;
    property OnWriteProgramVersion: TConsoleOutputEvent read FOnWriteProgramVersion write FOnWriteProgramVersion;
  end;

implementation

uses
  Options;

{ TOptionsValidator }

{ Private declarations }

procedure TOptionsValidator.UpdateSearchPathFromDOFFile;
var
  DOFFileName, SearchPath: String;
begin
  DOFFileName := ExpandFileName(ChangeFileExt(TOptions.Instance.InputFile, '.dof'));
  if not FileExists(DOFFileName) then
    Exit;

  with TIniFile.Create(DOFFileName) do
    try
      if ValueExists('Directories', 'SearchPath') then
        SearchPath := ReadString('Directories', 'SearchPath', '')
      else
        SearchPath := '';
    finally
      Free;
    end;

  with TOptions.Instance.SearchPath do
    Text := StringReplace(SearchPath, PathSep, SLineBreak, [rfReplaceAll]) + Text;
end;

{ Protected declarations }

procedure TOptionsValidator.DoWriteProgramHeader;
begin
  if Assigned(FOnWriteProgramHeader) then
    FOnWriteProgramHeader;
end;

procedure TOptionsValidator.DoWriteExplanations;
begin
  if Assigned(FOnWriteExplanations) then
    FOnWriteExplanations;
end;

procedure TOptionsValidator.DoWriteProgramVersion;
begin
  if Assigned(FOnWriteProgramVersion) then
    FOnWriteProgramVersion;
end;

{ Public declarations }

procedure TOptionsValidator.Validate;
begin
  if not TOptions.Instance.Quiet then
    DoWriteProgramHeader;
  if TOptions.Instance.Help then
  begin
    DoWriteExplanations;
    Halt(0);
  end;
  if TOptions.Instance.PrintVersion then
  begin
    DoWriteProgramVersion;
    Halt(0);
  end;
  if TOptions.Instance.InputFile = '' then
  begin
    Writeln('Error: no input file specified');
    Halt(1);
  end;
  if not FileExists(TOptions.Instance.InputFile) then
  begin
    Writeln('Error: specified input file does not exists');
    Halt(1);
  end;
  if TOptions.Instance.LeftList.Count > 0 then
  begin
    Writeln('Error: unrecognized option ', TOptions.Instance.LeftList[0]);
    Halt(2);
  end;
  UpdateSearchPathFromDOFFile;
end;

end.


