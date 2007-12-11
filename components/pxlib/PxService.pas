// ----------------------------------------------------------------------------
// Unit        : PxService.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2004-10-27
// Version     : 1.0
// Description : Service applications facilities. This should be independent
//               from the platform (Delphi/Kylix).
//
//               To create a simple or event more advanced service create a new
//               console application project, create a class that inherits from
//               TPxService class and override this methods to create the
//               service functionality:
//
//               OnInitialize - in this method implement all initialization
//                              required by service
//               OnFinalize   - in this method implement all finalization
//                              required by service and cleanup any resources
//                              allocated by service
//               ReadSettings - in this method read all service-specific settings
//               Main         - in this method implement the main service
//                              functionality. A basic implementation of Main
//                              method would look like this:
//
//                              // service's thread main loop
//                              repeat
//                               // give other threads some time to breath
//                               Sleep(1);
//                              until Terminated;
//
//                             Depending on the value passed to Sleep the thread
//                             is more time-consuming (smaller value) or less
//                             time-consuming (greater value).
//
// Changes log ; 2004-10-27 - Initial version (based on an old version of
//                            ServiceConf and TestSvc project).
//               2004-12-21 - Fixed bug when setting the service description.
//               2005-03-23 - Compatibility with FPC achieved
//                          - JwaWinSvc references removed
//               2005-04-17 - Added a possibility to create a service application
//                            that works like standard window-less user-mode app
// ToDo        : - Testing.
// ----------------------------------------------------------------------------

unit PxService;

{$I PxDefines.inc}

interface

uses
  Windows, ActiveX, Classes, SysUtils, IniFiles,
{$IFDEF DELPHI}
  WinSvc,
{$ENDIF}  
  PxLog, PxThread, PxSettings;

type
  TPxService = class (TPxThread)
  private
    FClosed: Boolean;
    FDebugMode: Boolean;
{$IFDEF WIN32}
    FServiceName: String;
    FServiceDescription: String;
{$ENDIF}
  protected
    // override this to initialize the service
    procedure OnInitialize; virtual;
    // override this to cleanup after the main service loop ends
    procedure OnFinalize; virtual;
    // override this to read additional application settings
    // do not forget to call the inherited method !
    procedure ReadSettings(IniFile: TIniFile); virtual;
    // override this to implement the main service functionality
    procedure Main; virtual;
    // do NOT override this - use Main procedure to implement the service functionality
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    // call this to initialize
    procedure Initialize;
    // call this to start the service
    procedure Run(AppMode: Boolean = False);

    property Closed: Boolean read FClosed;
    property DebugMode: Boolean read FDebugMode write FDebugMode;
{$IFDEF WIN32}
    property ServiceName: String read FServiceName;
    property ServiceDescription: String read FServiceDescription;
{$ENDIF}
  end;

implementation

uses
{$IFDEF FPC}
  PxFPC,
{$ENDIF}
{$IFDEF VER130}
  Consts;
{$ENDIF}
{$IFDEF VER150}
  RtlConsts;
{$ENDIF}

//
// Additional import and constants to set service description
// 
 
const
  SERVICE_CONFIG_DESCRIPTION = 1;
  
function ChangeServiceConfig2(hService: SC_HANDLE; dwInfoLevel: DWORD; lpInfo: Pointer): BOOL; external 'advapi32.dll' name 'ChangeServiceConfig2A';

var
  ServiceStatus      : SERVICE_STATUS;
  ServiceStatusHandle: SERVICE_STATUS_HANDLE;
  ServiceControlEvent: THandle;
  Service            : TPxService;

procedure ServiceControlHandler(ControlCode: DWORD); stdcall; forward;
procedure ServiceProc(argc: DWORD; argv: PLPSTR); stdcall; forward;
procedure InstallService; forward;
procedure UninstallService; forward;
procedure RunService; forward;
procedure DebugService; forward;
procedure ServiceMain(Thread: TPxService); forward;
function ConsoleHandler(dwCtrlType: DWORD): BOOL; forward;

{ TPxService }

{ Private declarations }

{ Protected declarations }

procedure TPxService.ReadSettings(IniFile: TIniFile);
begin
{$IFDEF WIN32}
  FServiceName := IniFile.ReadString('Service', 'Name', ExtractFileName(ParamStr(0)));
  FServiceDescription := IniFile.ReadString('Service', 'Description', 'Description of ' + ExtractFileName(ParamStr(0)));
{$ENDIF}
end;

procedure TPxService.OnInitialize;
begin
end;

procedure TPxService.OnFinalize;
begin
end;

procedure TPxService.Main;
begin
end;

procedure TPxService.Execute;
begin
  OleInitialize(nil);
  FClosed := False;
  Main;
  FClosed := True;
  SetEvent(ServiceControlEvent);
//  OleUninitialize;
end;

{ Public declarations }

constructor TPxService.Create;
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FClosed := True;
  OnInitialize;
end;

destructor TPxService.Destroy;
begin
  OnFinalize;
  inherited Destroy;
end;

procedure TPxService.Initialize;
var
  IniFile: TIniFile;
begin
  inherited Create(True);

  FDebugMode := FindCmdLineSwitch('debug', ['-', '/'], True);

  IniFile := TIniFile.Create(SettingsFileName);
  ReadSettings(IniFile);
  FreeAndNil(IniFile);

  if (not FDebugMode) and LogToConsole then
    FDebugMode := True
  else if FDebugMode and (not LogToConsole) then
    SwitchLogToConsole;
end;

procedure TPxService.Run(AppMode: Boolean = False);
begin
  if AppMode then
  begin
    Log('Running in application mode');
    FDebugMode := True;
  end;
  ServiceMain(Self);
end;

{ *** }

procedure ServiceControlHandler(ControlCode: DWORD); stdcall;
begin
  Log(LOGLEVEL_DEBUG, 'ServiceControlHandler(ControlCode=%d)', [ControlCode]);
  case ControlCode of
    SERVICE_CONTROL_INTERROGATE:
    begin
    end;
    SERVICE_CONTROL_SHUTDOWN,
    SERVICE_CONTROL_STOP:
    begin
      Service.Terminate;
      SetServiceStatus(ServiceStatusHandle, ServiceStatus);
      SetEvent(ServiceControlEvent);
    end;
    SERVICE_CONTROL_PAUSE:
    begin
      Service.Suspend;
    end;
    SERVICE_CONTROL_CONTINUE:
    begin
      Service.Resume;
    end;
    else if (ControlCode > 127) and (ControlCode < 256) then
    begin
      // user control codes
    end
  end;
  SetServiceStatus(ServiceStatusHandle, ServiceStatus);
end;

procedure ServiceProc(argc: DWORD; argv: PLPSTR); stdcall;
var
  Msg: TMsg;
  OldMainThreadId: THandle;
begin
  Log(LOGLEVEL_DEBUG, 'ServiceProc()');

  ServiceStatus.dwServiceType := SERVICE_WIN32;
  ServiceStatus.dwCurrentState := SERVICE_STOPPED;
  ServiceStatus.dwControlsAccepted := 0;
  ServiceStatus.dwWin32ExitCode := NO_ERROR;
  ServiceStatus.dwServiceSpecificExitCode := NO_ERROR;
  ServiceStatus.dwCheckPoint := 0;
  ServiceStatus.dwWaitHint := 0;

  ServiceStatusHandle := RegisterServiceCtrlHandler(PAnsiChar(Service.ServiceName), @ServiceControlHandler);
  if ServiceStatusHandle <> 0 then
  begin
    // service is starting
    ServiceStatus.dwCurrentState := SERVICE_START_PENDING;
    SetServiceStatus(ServiceStatusHandle, ServiceStatus);
    // Create the Controlling Event here
    ServiceControlEvent := CreateEvent(nil, False, False, nil);
    // Service running
    ServiceStatus.dwControlsAccepted := ServiceStatus.dwControlsAccepted or (SERVICE_ACCEPT_STOP or SERVICE_ACCEPT_SHUTDOWN);
    ServiceStatus.dwCurrentState := SERVICE_RUNNING;
    SetServiceStatus(ServiceStatusHandle, ServiceStatus);

    // log, that the service is running
    Log(LOGLEVEL_DEBUG, 'Starting main service thread');

    // store MainThreadId and make current thread the main thread
    OldMainThreadID := MainThreadID;
    MainThreadID := GetCurrentThreadId;

    // start service thread here...
    Service.Resume;
    Log(LOGLEVEL_DEBUG, 'ServiceThread resumed');

    // wait until the service has stopped
    repeat
      if PeekMessage(Msg, 0, 0, 0, PM_REMOVE) then
      begin
        TranslateMessage(Msg);
        DispatchMessage(Msg);
      end;
      if WaitForSingleObject(ServiceControlEvent, 100) = WAIT_OBJECT_0 then
      begin
        Log(LOGLEVEL_DEBUG, 'WaitForSingleObject() = WAIT_OBJECT_0 in ServiceProc');
        Break;
      end;
      if GetCurrentThreadID = MainThreadID then
      begin
{$IFDEF DELPHI}
        CheckSynchronize(1);
{$ENDIF}
{$IFDEF FPC}
        CheckSynchronize;
        Sleep(1);
{$ENDIF}
      end
      else
        Log(LOGLEVEL_DEBUG, '!!! GetCurrentThreadID <> MainThreadID !!! NO SYNCHRONIZATION PERFORMED !!!');
    until False;

    // restore main thread id
    MainThreadID := OldMainThreadID;

    // service was stopped
    ServiceStatus.dwCurrentState := SERVICE_STOP_PENDING;
    SetServiceStatus(ServiceStatusHandle, ServiceStatus);

    // log, that the service has stopped execution
    Log(LOGLEVEL_DEBUG, 'Service stopped');

    // do cleanup here
    ServiceControlEvent := 0;

    // service is now stopped
    ServiceStatus.dwControlsAccepted := ServiceStatus.dwControlsAccepted and (not (SERVICE_ACCEPT_STOP or SERVICE_ACCEPT_SHUTDOWN));
    ServiceStatus.dwCurrentState := SERVICE_STOPPED;
    SetServiceStatus(ServiceStatusHandle, ServiceStatus);
  end;
end;

procedure InstallService;
var
  ServiceControlManager, Service_: SC_HANDLE;
  Description: PAnsiChar;
begin
  ServiceControlManager := OpenSCManager(nil, nil, SC_MANAGER_CREATE_SERVICE);

  if ServiceControlManager <> 0 then
  begin
    Service_ := CreateService(
      ServiceControlManager,
      PChar(Service.ServiceName),
      PChar(Service.ServiceName),
      SERVICE_ALL_ACCESS, SERVICE_WIN32_OWN_PROCESS,
      SERVICE_AUTO_START, SERVICE_ERROR_IGNORE, PChar(ParamStr(0)),
      nil, nil, nil, nil, nil);
    if Service_ <> 0 then
    begin
      Description := PAnsiChar(Service.ServiceDescription);
      ChangeServiceConfig2(
        Service_,
        SERVICE_CONFIG_DESCRIPTION,
        @Description
      );
      CloseServiceHandle(Service_);
      Log('Service %s installed successfully', [Service.ServiceName]);
    end
    else if GetLastError = ERROR_SERVICE_EXISTS then
      Log('Error: Service %s already exists !', [Service.ServiceName])
    else
      Log('Error while installing service %s. Error Code: %d', [Service.ServiceName, GetLastError]);
  end;
  CloseServiceHandle(ServiceControlManager);
end;

procedure UninstallService;
var
  ServiceControlManager, Service_: SC_HANDLE;
  ServiceStatus: SERVICE_STATUS;
  Error: DWORD;
begin
  ServiceControlManager := OpenSCManager(nil, nil, SC_MANAGER_CONNECT);

  if ServiceControlManager <> 0 then
  begin
    Service_ := OpenService(serviceControlManager, PChar(Service.ServiceName), SERVICE_QUERY_STATUS or $00010000);
    if Service_ <> 0 then
    begin
      if QueryServiceStatus(Service_, ServiceStatus) then
      begin
        if ServiceStatus.dwCurrentState = SERVICE_STOPPED then
        begin
          if DeleteService(Service_) then
            Log('Service %s removed successfully', [Service.ServiceName])
          else
          begin
            Error := GetLastError;
            case Error of
              ERROR_ACCESS_DENIED:
                Log('Error: Access denied while trying to remove the service %s', [Service.ServiceName]);
              ERROR_INVALID_HANDLE:
                Log('Error: Handle invalid while trying to remove the service %s', [Service.ServiceName]);
              ERROR_SERVICE_MARKED_FOR_DELETE:
                Log('Error: Service % already marked for deletion', [Service.ServiceName]);
              else
                Log('Error: Unknown error code %d', [Error]);
            end;
          end;
        end
        else Log('Service  %s is still running.', [Service.ServiceName]);
      end
      else
      begin
        Error := GetLastError;
        case Error of
          ERROR_ACCESS_DENIED:
            Log('Error: Access denied while trying to remove the service %s', [Service.ServiceName]);
          ERROR_INVALID_HANDLE:
            Log('Error: Handle invalid while trying to remove the service %s', [Service.ServiceName]);
          ERROR_SERVICE_MARKED_FOR_DELETE:
            Log('Error: Service  %s already marked for deletion', [Service.ServiceName]);
          else
            Log('Error: Unknown error code %s', [Error]);
        end;
      end;
      CloseServiceHandle(Service_);
    end
    else Log('Error: Unknown error code %d', [GetLastError]);
    CloseServiceHandle(ServiceControlManager);
  end;
end;

procedure RunService;
var
  ServiceTable: TServiceTableEntry;
begin
  FillChar(ServiceTable, SizeOf(ServiceTable), 0);
  ServiceTable.lpServiceName := PChar(Service.FServiceName);
  ServiceTable.lpServiceProc := @ServiceProc;
  StartServiceCtrlDispatcher(ServiceTable);
  if GetCurrentThreadID = MainThreadID then
    Log(LOGLEVEL_DEBUG, 'GetCurrentThreadID = MainThreadID') ;
end;

procedure DebugService;
var
  Msg: TMsg;
begin
  ServiceControlEvent := CreateEvent(nil, False, False, nil);

  // bind console controls (to catch ctrl+XXX keyboard macros and exit)
  SetConsoleCtrlHandler(@ConsoleHandler, True);

  // start service thread here...
  Service.Resume;

  // wait until the service has stopped
  repeat
    if PeekMessage(Msg, 0, 0, 0, PM_REMOVE) then
    begin
      TranslateMessage(Msg);
      DispatchMessage(Msg);
    end;
    if WaitForSingleObject(ServiceControlEvent, 0) = WAIT_OBJECT_0 then
      Break;
    CheckSynchronize(1);
  until False;

  // do cleanup here
  ServiceControlEvent := 0;
end;

procedure ServiceMain(Thread: TPxService);
begin
  Service := Thread;

  Log(LOGLEVEL_DEBUG, 'Started with CmdLine=%s', [CmdLine]);

  if FindCmdLineSwitch('install', ['-', '/'], True) then
    InstallService
  else if FindCmdLineSwitch('remove', ['-', '/'], True) then
    UninstallService
  else if FindCmdLineSwitch('debug', ['-', '/'], True) or Thread.FDebugMode then
    DebugService
  else if FindCmdLineSwitch('start', ['-', '/'], True) then
  begin
    Writeln('To start this service type');
    Writeln('C:\>net start ', Service.ServiceName);
    Writeln;
    Writeln;
  end
  else if FindCmdLineSwitch('stop', ['-', '/'], True) then
  begin
    Writeln('To stop this service type');
    Writeln('C:\>net stop ', Service.ServiceName);
    Writeln;
    Writeln;
  end
  else if FindCmdLineSwitch('help', ['-', '/'], True) or FindCmdLineSwitch('?', ['-', '/'], True) then
  begin
    Log(LOGLEVEL_DEBUG, 'Showing help');
    Writeln(ExtractFileName(ParamStr(0)) + ' [-install] [-remove] [-start] [-stop] [-debug]');
    Writeln;
    Writeln('  -install    - to install this application as a Win32 service');
    Writeln('  -remove     - to remve the service installed with -install');
    Writeln('  -start      - to start the service if installed');
    Writeln('  -stop       - to stop the service if installed and running');
    Writeln('  -debug      - to run this application in debug mode');
    Writeln;
    Writeln;
  end
  else
  begin
    Log(LOGLEVEL_DEBUG, 'GetCurrentProcessId = %d', [GetCurrentProcessId]);
    RunService;
  end;
end;

function ConsoleHandler(dwCtrlType: DWORD): BOOL;
begin
  Log(LOGLEVEL_DEBUG, 'Closing...');

  // terminate main service thread
  Service.Terminate;
  // wait until the main service thread terminates
  while not Service.Closed do Sleep(10);

  Result := True;
end;

end.
