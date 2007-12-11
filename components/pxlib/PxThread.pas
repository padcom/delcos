// ----------------------------------------------------------------------------
// Unit        : PxThread.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2004-10-27
// Version     : 1.0
// Description : A thread class.
// Changes log ; 2004-10-27 - Initial version.
//               2005-09-28 - Removed deps with PxLog unit
// ToDo        : Testing.
// ----------------------------------------------------------------------------

unit PxThread;

{$I PxDefines.inc}

interface

uses
  Windows, Classes, SysUtils;

type
  //
  // A thread class
  //
  TPxThread = class (TThread)
  private
    FTerminationEvent: THandle;
  public
    constructor Create(CreateSuspended: Boolean);
    destructor Destroy; override;
    //
    // A sleep function that terminates if a specific event is raised
    // Use this instead of Windows.Sleep() if you want that the wait
    // process will be stopped if the thread is terminated
    //
    // Return values:
    //   True if the sleep process has not been interrupted
    //   False if the sleep process has been interrupted
    //
    function Sleep(Timeout: Integer): Boolean;
    //
    // Stops the Sleep function. If a Sleep function was waiting
    // it returns immediately with False.
    //
    procedure CancelSleep;
    // overriden to call CancelSleep;
    procedure Terminate;

    // inherited properties
    property Terminated;
  end;

implementation

{ TPxThread }

{ Private declarations }

{ Public declarations }

constructor TPxThread.Create(CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  FTerminationEvent := CreateEvent(nil, False, False, nil);
end;

destructor TPxThread.Destroy;
begin
  CancelSleep;
  CloseHandle(FTerminationEvent);
  FTerminationEvent := 0;
  inherited Destroy;
end;

function TPxThread.Sleep(Timeout: Integer): Boolean;
begin
  Result := WaitForSingleObject(FTerminationEvent, Timeout) = WAIT_TIMEOUT;
  if not Result then
    ResetEvent(FTerminationEvent);
end;

procedure TPxThread.CancelSleep;
begin
  if (FTerminationEvent <> 0) and (FTerminationEvent <> INVALID_HANDLE_VALUE) then
    SetEvent(FTerminationEvent);
end;

procedure TPxThread.Terminate;
begin
  inherited Terminate;
  CancelSleep;
end;

end.

