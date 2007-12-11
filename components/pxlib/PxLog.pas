// ----------------------------------------------------------------------------
// Unit        : PxLog.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2004-10-10
// Version     : 1.0
// Description ; Logging facilities for applications.
// Changes log ; 2004-10-10 - Initial version
//               2004-10-11 - added type TLogLevel that defines the size of
//                            log level constants
//               2004-12-21 - added the possibility to turn on/off date in log
//                            entries.
//               2005-03-24 - GetLogLevel and SetLogLevel functions to
//                            manipulate the current LogLevel at runtime.
//               2005-05-03 - All procedures (excluding initialization) are now
//                            thread safe
//               2005-06-21 - Added additional parameters for logging (all to be
//                            set via [Log] section in application's ini file):
//                            - LogKind (continous, incremental)
//                            - MaxLines (after this amount of logs is achieved
//                              a new log is generated and the previous is
//                              renamed in form logfile.log.x, where x is an
//                              autoincremented value discovered from existing 
//                              files in application's folder
// ToDo        : Testing.
// ----------------------------------------------------------------------------

unit PxLog;

{$I PxDefines.inc}

interface

uses
  Windows, Messages, SysUtils, IniFiles,
  PxBase, PxUtils;

type
  TLogLevel = type UINT32;

const
  //
  // Log levels
  //

  // default log level
  LOGLEVEL_DEFAULT      = 0;
  // default debug log level
  LOGLEVEL_DEBUG        = 5;
  // default strong-debug level (used only while searching for really nasty bugs)
  LOGLEVEL_STRONG_DEBUG = 10;

var
  //
  // Indicates if Date should be included in log entries
  //
  IncludeDateInLog: Boolean = True;
  LastLogEntry    : String  = '';

//
// Simply add a log message at the default log level
//
procedure Log(S: String); overload;

// 
// Add a log message at the default log level.
// Passed string is a template for the Format function
//
procedure Log(S: String; Params: array of const); overload;

//
// Add a simple log at a given level
//
procedure Log(Level: TLogLevel; S: String); overload;

// 
// Add a log message at the given log level.
// Passed string is a template for the Format function
//
procedure Log(Level: TLogLevel; S: String; Params: array of const); overload;

//
// Retrives the current log level
//
function GetLogLevel: Word;

//
// Sets the log level (usefull in test applications where creating a .ini file
// is not needed).
//
procedure SetLogLevel(ALogLevel: Word);

//
// Sets a handle to a list box so that log messages can go there instead of
// the real text console
//
procedure SetLogHandle(Handle: THandle);

//
// Checks if log entries goes to console (like in debug mode)
//
function LogToConsole: Boolean;

//
// Switsches the logging window into console
//
procedure SwitchLogToConsole;

//
// Starts the logging subsystem
//
procedure Initialize;

implementation

uses
{$IFDEF VER130}
  PxDelphi5,
{$ENDIF}
  PxSettings;

type
  TPxLogStyle = (lsContinuous, lsIncremental);

const
  // section in settings file
  SLOG          : String = 'Log'; // do not localize
  // file name value key
  SLOG_FILE_NAME: String = 'FileName'; // do not localize
  // log level value key
  SLOG_LEVEL    : String = 'Level'; // do not localize

  SLOG_KIND     : String = 'Kind';
  SLOG_KIND_CONT: String = 'Continuous'; // default, do not localize
  SLOG_KIND_INC : String = 'Incremental'; // do not localize
  SLOG_MAX_LINES: String = 'MaxLines'; // default=0 (disabled), do not localize

var
  // indicates wether logs are written to a log file or console
  LogToFile: Boolean;
  // used when no console is available and the log file is not initialized yet
  LogBootFile: Text;
  LogBootFileInitialized: Boolean;
  // if logging to file - this is the file
  LogFile: Text;
  LogFileName: String;
  // if logging is to a console and this is set - a list box is used instead of a real console
  LogHandle: THandle;
  // current logging level
  LogLevel: Word;
  // thread-safety
  LogMutex: THandle;
  LogLevelMutex: THandle;
  LogHandleMutex: THandle;
  // style of the logging system
  LogStyle: TPxLogStyle;
  // count of logs stored to the
  LogLines: Integer;
  MaxLogLines: Integer;
  LoggingInitialized: Boolean = False;

function GetLastLogFileIndex: Integer;
var
  SRec: TSearchRec;
  SRes, Temp: Integer;
begin
  Result := 0;
  SRes := FindFirst(LogFileName + '.*', faAnyFile, SRec);
  while SRes = 0 do
  begin
    if TryStrToInt(Copy(SRec.Name, Length(ExtractFileName(LogFileName)) + 2, MaxInt), Temp) and (Temp >= Result) then
      Result := Temp + 1;
    SRes := FindNext(SRec);
  end;
end;

procedure Log(S: String);
begin
  Log(LOGLEVEL_DEFAULT, S);
end;

procedure Log(S: String; Params: array of const);
begin
  Log(LOGLEVEL_DEFAULT, Format(S, Params));
end;

procedure Log(Level: TLogLevel; S: String);
var
  Index: Integer;
begin
  if IncludeDateInLog then
    S := FormatDateTime('YYYY-MM-DD HH:NN:SS - ', Now) + S
  else
    S := FormatDateTime('HH:NN:SS - ', Now) + S;

  LastLogEntry := S;

  if LogLevel >= Level then
    if WaitForSingleObject(LogMutex, INFINITE) = WAIT_OBJECT_0 then
      try
        if LogToFile then
        begin
          if (MaxLogLines > 0) and (LogStyle = lsIncremental) then
          begin
            Inc(LogLines);
            if LogLines > MaxLogLines then
            begin
              Index := GetLastLogFileIndex;
              CloseFile(LogFile);
              RenameFile(LogFileName, LogFileName + '.' + IntToStr(Index));
              AssignFile(LogFile, LogFileName);
              Rewrite(LogFile);
              LogLines := 0;
            end;
          end;

          Writeln(LogFile, S);
          Flush(LogFile);
        end
        else if IsConsole then
          Writeln(S)
        else if LogBootFileInitialized then
          Writeln(LogBootFile, S);

        if LogHandle <> 0 then
          SendMessage(LogHandle, LB_ADDSTRING, 0, Cardinal(PChar(S)));
      finally
        ReleaseMutex(LogMutex);
      end;
end;

procedure Log(Level: TLogLevel; S: String; Params: array of const);
begin
  Log(Level, Format(S, Params));
end;

function GetLogLevel: Word;
begin
  Result := LogLevel;
end;

procedure SetLogLevel(ALogLevel: Word);
begin
  if WaitForSingleObject(LogLevelMutex, INFINITE) = WAIT_OBJECT_0 then
  begin
    LogLevel := ALogLevel;
    ReleaseMutex(LogLevelMutex);
    Log(LOGLEVEL_DEBUG, 'Changed LogLevel from %d to %d', [LogLevel, ALogLevel]);
  end
  else
    Log(LOGLEVEL_DEBUG, 'Error while changing LogLevel from %d to %d', [LogLevel, ALogLevel]);
end;

procedure SetLogHandle(Handle: THandle);
begin
  if WaitForSingleObject(LogHandleMutex, INFINITE) = WAIT_OBJECT_0 then
    LogHandle := Handle;
end;

function LogToConsole: Boolean;
begin
  Result := (not LogToFile) and (LogHandle = 0);
end;

procedure SwitchLogToConsole;
begin
  if LogToConsole then Exit;
  if LogToFile then
  begin
    CloseFile(LogFile);
    LogToFile := False;
  end;
  if LogHandle <> 0 then
    SetLogHandle(0);
  Log('Switched into console mode');
end;

procedure Initialize;
const
{$IFDEF DEBUG}
  DefaultLogLevel = LOGLEVEL_DEBUG;
{$ELSE}
  DefaultLogLevel = LOGLEVEL_DEFAULT;
{$ENDIF}
var
  Index: Integer;
begin
  // while running from package as a part of delphi environment don't start the logging subsystem
  if IsDelphiHost then Exit;

  if LogMutex = 0 then
    LogMutex := CreateMutex(nil, False, '');
  if LogLevelMutex = 0 then
    LogLevelMutex := CreateMutex(nil, False, '');
  if LogHandleMutex = 0 then
    LogHandleMutex := CreateMutex(nil, False, '');

  if SameText(SLOG_KIND_INC, IniFile.ReadString(SLOG, SLOG_KIND, SLOG_KIND_CONT)) then
  begin
    LogStyle := lsIncremental;
    MaxLogLines := IniFile.ReadInteger(SLOG, SLOG_MAX_LINES, 0);
  end
  else
  begin
    LogStyle := lsContinuous;
    MaxLogLines := 0;
  end;
  LogLines := 0;

  try
    LogFileName := IniFile.ReadString(SLOG, SLOG_FILE_NAME, ChangeFileExt(ParamStr(0), '.log'));
    LogToFile :=  LogFileName <> '';
    if ExtractFilePath(LogFileName) = '' then
      LogFileName := ExtractFilePath(ParamStr(0)) + LogFileName;
    if LogToFile then
    begin
      // check if old log is to be backuped or appended
      if (LogStyle = lsIncremental) and FileExists(LogFileName) then
      begin
        Index := GetLastLogFileIndex;
        RenameFile(LogFileName, LogFileName + '.' + IntToStr(Index));
      end;

      AssignFile(LogFile, LogFileName);
      if FileExists(LogFileName) then
        Append(LogFile)
      else
        Rewrite(LogFile);

    end
    else if not IsConsole then
    begin
      AllocConsole;
      IsConsole := True;
    end;

    if LogBootFileInitialized then
    begin
      CloseFile(LogBootFile);
      LogBootFileInitialized := False;
    end;
    LogLevel := IniFile.ReadInteger(SLOG, SLOG_LEVEL, DefaultLogLevel);
    Log('--- Log begin ---');
  except
    LogToFile := False;
    Log('Error: cannot start log - application terminated');
    IniFile.Free;
    Halt(1);
  end;

  LoggingInitialized := True;
end;

procedure Finalize;
begin
  // while running from package as a part of delphi environment the logging subsystem is inactive so there's nothing to clean up here
  if IsDelphiHost then Exit;

  if LoggingInitialized then
  begin
    Log('--- Log end ---');
    if LogToFile then
    begin
      Flush(LogFile);
      CloseFile(LogFile);
    end;
    LoggingInitialized := False;
  end;
end;

initialization
{$IFDEF AUTO_ENABLE_LOGGING}
  AssignFile(LogBootFile, ChangeFileExt(ParamStr(0), '.boot.log'));
  Rewrite(LogBootFile);
  LogBootFileInitialized := True;
  Initialize;
{$ENDIF}

finalization
  if LogBootFileInitialized then
    CloseFile(LogBootFile);
  CloseHandle(LogMutex);
  CloseHandle(LogLevelMutex);
  CloseHandle(LogHandleMutex);
  Finalize;

end.
