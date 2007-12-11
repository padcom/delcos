// ----------------------------------------------------------------------------
// Unit        : PxSocketStream - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2004-12-22
// Version     : 1.0
// Description : Definition of specialized stream to handle socket reads and
//               writes. Based on TWinSocketStream from ScktComp.pas but
//               modified to work with pure handle instead of TSocket component.
// Changes log : 2004-12-22 - Initial version
//               2006-02-24 - added compatibility with Delphi 6
// ToDo        : Testing.
// ----------------------------------------------------------------------------

unit PxSocketStream;

{$I PxDefines.inc}

interface

uses
  Windows, Winsock, Classes, SysUtils, SyncObjs, PxNetwork, PxFPC;

type
  //
  // Specialized stream to handle socket reads and writes
  //
  TPxSocketStream = class(TStream)
  private
    FHandle: TSocket;
    FHandleCreated: Boolean;
    FTimeout: Longint;
    FEvent: TSimpleEvent;
  public
    constructor Create(AHandle: TSocket; TimeOut: Longint = 10000); overload;
    constructor Create(IP: String; Port: Word; TimeOut: Longint = 10000); overload;
    destructor Destroy; override;
    // by default take the timeout value from constructor
    function WaitForData(Timeout: Longint = -1): Boolean;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: Word): Longint; override;
    property Handle: TSocket read FHandle;
    property TimeOut: Longint read FTimeout write FTimeout;
  end;

  ESocketError = class(Exception);

implementation

uses
{$IFDEF VER130}
  Consts;
{$ENDIF}
{$IFDEF VER140}
  RTLConsts;
{$ENDIF}
{$IFDEF VER150}
  RTLConsts;
{$ENDIF}
{$IFDEF FPC}
  RTLConsts;
{$ENDIF}

{ TPxSocketStream }

constructor TPxSocketStream.Create(AHandle: TSocket; TimeOut: Longint = 10000);
begin
  inherited Create;
  FHandle := AHandle;
  FHandleCreated := False;
  FTimeOut := TimeOut;
  FEvent := TSimpleEvent.Create;
end;

constructor TPxSocketStream.Create(IP: String; Port: Word; TimeOut: Longint = 10000);
var
  S: TSocket;
begin
  S := Connect(IP, Port);
  if S <> TSocket(INVALID_SOCKET) then
  begin
    Create(S, TimeOut);
    FHandleCreated := True;
  end
  else
    raise ESocketError.Create('Error while creating/connecting socket');
end;

destructor TPxSocketStream.Destroy;
begin
  if FHandleCreated then
    closesocket(FHandle);
  FEvent.Free;
  inherited Destroy;
end;

function TPxSocketStream.WaitForData(Timeout: Longint = -1): Boolean;
var
  FDSet: TFDSet;
  TimeVal: TTimeVal;
begin
  if Timeout = -1 then
    TimeOut := FTimeout;
  TimeVal.tv_sec := Timeout div 1000;
  TimeVal.tv_usec := (Timeout mod 1000) * 1000;
  FD_ZERO(FDSet);
  FD_SET(FHandle, FDSet);
  Result := select(0, @FDSet, nil, nil, @TimeVal) > 0;
end;

function TPxSocketStream.Read(var Buffer; Count: Longint): Longint;
var
  Overlapped: TOverlapped;
  ErrorCode: Integer;
begin
  Result := -1;
  FillChar(OVerlapped, SizeOf(Overlapped), 0);
  Overlapped.hEvent := FEvent.Handle;
  if not ReadFile(FHandle, Buffer, Count, DWORD(Result), @Overlapped) and (GetLastError <> ERROR_IO_PENDING) then
  begin
    ErrorCode := GetLastError;
    raise ESocketError.CreateResFmt(@SSocketIOError, [sSocketRead, ErrorCode, SysErrorMessage(ErrorCode)]);
  end;
  if FEvent.WaitFor(FTimeOut) <> wrSignaled then
    Result := 0
  else
  begin
    GetOverlappedResult(FHandle, Overlapped, DWORD(Result), False);
    FEvent.ResetEvent;
  end;
end;

function TPxSocketStream.Write(const Buffer; Count: Longint): Longint;
var
  Overlapped: TOverlapped;
  ErrorCode: Integer;
begin
  Result := -1;
  FillChar(OVerlapped, SizeOf(Overlapped), 0);
  Overlapped.hEvent := FEvent.Handle;
  if not WriteFile(FHandle, Buffer, Count, DWORD(Result), @Overlapped) and (GetLastError <> ERROR_IO_PENDING) then
  begin
    ErrorCode := GetLastError;
    raise ESocketError.CreateResFmt(@SSocketIOError, [SSocketWrite, ErrorCode, SysErrorMessage(ErrorCode)]);
  end;
  if FEvent.WaitFor(FTimeOut) <> wrSignaled then
    Result := 0
  else
    GetOverlappedResult(FHandle, Overlapped, DWORD(Result), False);
end;

function TPxSocketStream.Seek(Offset: Longint; Origin: Word): Longint;
begin
  Result := 0;
end;

end.

