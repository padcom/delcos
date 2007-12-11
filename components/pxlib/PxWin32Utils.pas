// ----------------------------------------------------------------------------
// Unit        : PxWin32Utils.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2005-10-12
// Version     : 1.0
// Description : Win32 utility functions and procedures
// Changes log : 2005-10-12 - initial version
//               2005-10-12 - added RunCommandAndReadOutput function
//               2005-10-28 - added TPxSharedMemory class
// ToDo        : Testing.
// ----------------------------------------------------------------------------

unit PxWin32Utils;

{$I PxDefines.inc}

interface

uses
  Windows, Classes, SysUtils;

type
  //
  // shared memory access type (first is a'la server, second a'la client)
  //
  TPxSharedMemoryAccess = (maCreate, maOpen);

  //
  // Shared memory object.
  //
  TPxSharedMemory = class (TObject)
  private
    FMemory: Pointer;
    FHandle: THandle;
  public
    constructor Create(Access: TPxSharedMemoryAccess; Name: String; Size: LongWord);
    destructor Destroy; override;
    property Memory: Pointer read FMemory;
  end;

//
// This function runs a command, waits for the application to finish
// and returns the application's exit code.
//
// Parameters:
//   CmdLine - command line to execute
//   WorkDir - working directory for the command execution context
//   Timeout - timeout after which the process is marked as frozen (return code: -2)
//
// Returns:
//   -1 if the CreateProcess function has failed
//   -2 if the WaitForSingleObject function has failed
//   -3 if the GetExitCodeProcess function has failed
//  >=0 if the application has been successfully executed and returned
//      a valid exit code
//
function RunCommand(CmdLine: String; WorkDir: String = ''; Timeout: DWORD = INFINITE; WindowState: Word = SW_NORMAL): Integer;

const
  ERROR_CANNOT_CREATE_PIPE      = -1;
  ERROR_CANNOT_DUPLICATE_HANDLE = -2;
  ERROR_CANNOT_CLOSE_HANDLE     = -3;
  ERROR_CANNOT_CREATE_PROCESS   = -4;
  ERROR_CANNOT_READ_OUTPUT      = -5;
  ERROR_CANNOT_GET_EXIT_CODE    = -6;
  ERROR_TIMEOUT                 = -7;

//
// This function runs a command, waits for the application to finish
// and returns the application's exit code together with the application's
// output written to standard output.
//
// Origin: http://support.microsoft.com/default.aspx?scid=kb;en-us;190351
//
// Parameters:
//   CmdLine - command line to execute
//   Output  - placeholder for process outputs
//   WorkDir - working directory for the command execution context
//   Timeout - timeout after which the process is marked as frozen (return code: -7)
//
// Returns:
//   -1 if the CreatePipe function has failed
//   -2 if the DuplicateHandle function has failed
//   -3 if the CloseHandle function has failed
//   -4 if the CreateProcess function has failed
//   -5 if the output read procedure has failed
//   -6 if the GetExitCodeProcess function has failed
//   -7 if execution time has been exceeded
//  >=0 if the application has been successfully executed and returned
//      a valid exit code
//
function RunCommandAndReadOutput(CmdLine: String; Output: TStream; WorkDir: PChar = nil; ShowCmd: Word = SW_SHOWNORMAL; Timeout: DWORD = INFINITE): Integer;

implementation

{ TPxSharedMemory }

{ Private declarations }

{ Public declarations }

constructor TPxSharedMemory.Create(Access: TPxSharedMemoryAccess; Name: String; Size: LongWord);
begin
  inherited Create;
  case Access of
    maCreate:
    begin
      if Size = 0 then
        raise Exception.Create('Error: cannot create shared memory with Size=0');
      FHandle := CreateFileMapping($FFFFFFFF, nil, PAGE_READWRITE, 0, Size, PChar(Name));
      if FHandle = INVALID_HANDLE_VALUE then
        raise Exception.CreateFmt('Error: cannot create shared memory. Error code: %d', [GetLastError]);
      FMemory := MapViewOfFile(FHandle, FILE_MAP_ALL_ACCESS, 0, 0, Size);
      if not Assigned(FMemory) then
        raise Exception.CreateFmt('Error: cannot create shared memory. Error code: %d', [GetLastError]);
    end;
    maOpen:
    begin
      if Size = 0 then
        raise Exception.Create('Error: cannot open shared memory with Size=0');
      FHandle := OpenFileMapping(FILE_MAP_ALL_ACCESS, False, PChar(Name));
      if FHandle = INVALID_HANDLE_VALUE then
        raise Exception.CreateFmt('Error: cannot open shared memory. Error code: %d', [GetLastError]);
      FMemory := MapViewOfFile(FHandle, FILE_MAP_ALL_ACCESS, 0, 0, Size);
      if not Assigned(FMemory) then
        raise Exception.CreateFmt('Error: cannot open shared memory. Error code: %d', [GetLastError]);
    end;
  end;
end;

destructor TPxSharedMemory.Destroy;
begin
  if Assigned(FMemory) then
    UnmapViewOfFile(FMemory);
  if FHandle <> INVALID_HANDLE_VALUE then
    CloseHandle(FHandle);
  inherited Destroy;
end;

{ *** }

function RunCommand(CmdLine: String; WorkDir: String = ''; Timeout: DWORD = INFINITE; WindowState: Word = SW_NORMAL): Integer;
var
  proc: PROCESS_INFORMATION;
  start: STARTUPINFO;
  temp: Cardinal;
  dir: PChar;
begin
  // determinate the path to the command
  if WorkDir <> '' then
    Dir := PChar(WorkDir)
  else
    Dir := nil;

  // start execution
  ZeroMemory(@proc, SizeOf(proc));
  ZeroMemory(@start, SizeOf(start));
  start.cb := SizeOf(start);
  start.wShowWindow := WindowState;
  start.dwFlags := STARTF_USESHOWWINDOW;
  if not CreateProcess(nil, PChar(CmdLine), nil, nil, False, 0, nil, Dir, start, proc) then
    Result := -1 // cannot create process (ie. file not found or something like it)
  else if WaitForSingleObject(proc.hProcess, Timeout) <> WAIT_OBJECT_0 then
    Result := -2 // cannot wait for the process to end
  else if not GetExitCodeProcess(proc.hProcess, temp) then
    Result := -2
  else
    Result := temp;

  // close handles to process and main process thread
  CloseHandle(proc.hProcess);
  CloseHandle(proc.hThread);
end;

function RunCommandAndReadOutput(CmdLine: String; Output: TStream; WorkDir: PChar = nil; ShowCmd: Word = SW_SHOWNORMAL; Timeout: DWORD = INFINITE): Integer;
var
  hOutputReadTmp,hOutputRead,hOutputWrite: THandle;
  hInputWriteTmp,hInputRead,hInputWrite: THandle;
  hErrorWrite: THandle;
  sa: SECURITY_ATTRIBUTES;
  pi: PROCESS_INFORMATION;
  si: STARTUPINFO;
  lpBuffer: array[0..4095] of Byte;
  nBytesRead, dwExitCode: DWORD;
begin
  // Set up the security attributes struct.
  sa.nLength := SizeOf(SECURITY_ATTRIBUTES);
  sa.lpSecurityDescriptor := nil;
  sa.bInheritHandle := True;

  // Create the child output pipe.
  if not CreatePipe(hOutputReadTmp, hOutputWrite, @sa, 0) then
  begin
    Result := ERROR_CANNOT_CREATE_PIPE;
    Exit;
  end;

  // Create a duplicate of the output write handle for the std error
  // write handle. This is necessary in case the child application
  // closes one of its std output handles.
  if not DuplicateHandle(GetCurrentProcess, hOutputWrite, GetCurrentProcess, @hErrorWrite, 0, TRUE,DUPLICATE_SAME_ACCESS) then
  begin
    Result := ERROR_CANNOT_DUPLICATE_HANDLE;
    Exit;
  end;

  // Create the child input pipe.
  if not CreatePipe(hInputRead, hInputWriteTmp, @sa, 0) then
  begin
    Result := ERROR_CANNOT_CREATE_PIPE;
    Exit;
  end;

  // Create new output read handle and the input write handles. Set
  // the Properties to FALSE. Otherwise, the child inherits the
  // properties and, as a result, non-closeable handles to the pipes
  // are created.
  if not DuplicateHandle(GetCurrentProcess, hOutputReadTmp, GetCurrentProcess, @hOutputRead, 0, False, DUPLICATE_SAME_ACCESS) then
  begin
    Result := ERROR_CANNOT_DUPLICATE_HANDLE;
    Exit;
  end;
  if not DuplicateHandle(GetCurrentProcess, hInputWriteTmp, GetCurrentProcess, @hInputWrite, 0, False, DUPLICATE_SAME_ACCESS) then
  begin
    Result := ERROR_CANNOT_DUPLICATE_HANDLE;
    Exit;
  end;

  // Close inheritable copies of the handles you do not want to be
  // inherited.
  if not CloseHandle(hOutputReadTmp) then
  begin
    Result := ERROR_CANNOT_CLOSE_HANDLE;
    Exit;
  end;
  if not CloseHandle(hInputWriteTmp) then
  begin
    Result := ERROR_CANNOT_CLOSE_HANDLE;
    Exit;
  end;

  // Set up the start up info struct.
  ZeroMemory(@si, SizeOf(STARTUPINFO));
  si.cb := SizeOf(STARTUPINFO);
  si.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
  si.wShowWindow := SW_HIDE;
  si.hStdOutput := hOutputWrite;
  si.hStdInput := hInputRead;
  si.hStdError := hErrorWrite;

  // Launch the process that you want to redirect
  if not CreateProcess(nil, PChar(CmdLine), nil, nil, True, 0, nil, WorkDir, si, pi) then
  begin
    Result := ERROR_CANNOT_CREATE_PROCESS;
    Exit;
  end;

  // wait until the process finishes
  if Timeout <> INFINITE then
    if WaitForSingleObject(pi.hProcess, Timeout) <> WAIT_OBJECT_0 then
    begin
      Result := ERROR_TIMEOUT;
      Exit;
    end;

  // close any unnecessary handles.
  if not CloseHandle(pi.hThread) then
  begin
    Result := ERROR_CANNOT_CLOSE_HANDLE;
    Exit;
  end;

  // Close pipe handles (do not continue to modify the parent).
  // You need to make sure that no handles to the write end of the
  // output pipe are maintained in this process or else the pipe will
  // not close when the child process exits and the ReadFile will hang.
  if not CloseHandle(hOutputWrite) then
  begin
    Result := ERROR_CANNOT_CLOSE_HANDLE;
    Exit;
  end;
  if not CloseHandle(hInputRead) then
  begin
    Result := ERROR_CANNOT_CLOSE_HANDLE;
    Exit;
  end;
  if not CloseHandle(hErrorWrite) then
  begin
    Result := ERROR_CANNOT_CLOSE_HANDLE;
    Exit;
  end;

  // Read the child's output.
  while True do
  begin
    if (not ReadFile(hOutputRead, lpBuffer, SizeOf(lpBuffer), nBytesRead, nil)) or (nBytesRead = 0) then
    begin
      if GetLastError = ERROR_BROKEN_PIPE then
        Break // pipe done - normal exit path.
      else
      begin
        Result := ERROR_CANNOT_READ_OUTPUT;
        Exit;
      end;
    end;

    // add read data to output
    Output.Write(lpBuffer, nBytesRead);
  end;
  // Redirection is complete

  // close pipe handles
  if not CloseHandle(hOutputRead) then
  begin
    Result := ERROR_CANNOT_CLOSE_HANDLE;
    Exit;
  end;
  if not CloseHandle(hInputWrite) then
  begin
    Result := ERROR_CANNOT_CLOSE_HANDLE;
    Exit;
  end;

  // read exit code
  if not GetExitCodeProcess(pi.hProcess, dwExitCode) then
  begin
    Result := ERROR_CANNOT_GET_EXIT_CODE;
    Exit;
  end;

  // close proces handle
  if not CloseHandle(pi.hProcess) then
  begin
    Result := ERROR_CANNOT_CLOSE_HANDLE;
    Exit;
  end;

  Result := dwExitCode;
end;

end.

