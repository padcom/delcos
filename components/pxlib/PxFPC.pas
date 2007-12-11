// ----------------------------------------------------------------------------
// Unit        : PxFPC.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2005-03-28
// Version     : 1.0
// Description : Freepascal - Delphi compatibility fucntions required by PxLib
// Changes log : 2005-03-28 - initial version
// ToDo        : Testing.
// ----------------------------------------------------------------------------
 
unit PxFPC;

{$I PxDefines.inc}

interface

uses
  Windows, SysUtils, SyncObjs;

{$IFDEF FPC}

type
  TSimpleEvent = class (SyncObjs.TSimpleEvent)
    procedure Acquire; override;
    procedure Release; override;
  end;

function SetServiceStatus(hServiceStatus: SERVICE_STATUS_HANDLE; var lpServiceStatus: TServiceStatus): BOOL; stdcall;
function QueryServiceStatus(hService: SC_HANDLE; var lpServiceStatus: TServiceStatus): BOOL; stdcall;
function StartServiceCtrlDispatcher(var lpServiceStartTable: TServiceTableEntry): BOOL; stdcall;
function FileSetDate(FileName: String; Age: Longint): Longint;
function TryStrToDate(const S: string; out Value: TDateTime): Boolean; 
function TryStrToTime(const S: string; out Value: TDateTime): Boolean; 

// missing imports..
function OleInitialize(pReserved: Pointer): HResult; external 'OLE32' name 'OleInitialize';
procedure OleUninitialize; external 'OLE32' name 'OleUninitialize';

{$ENDIF}
 
implementation

{$IFDEF FPC}

uses
  RtlConsts;

{ TSimpleEvent }

procedure TSimpleEvent.Acquire; 
begin
end;

procedure TSimpleEvent.Release;
begin
end;

{ *** }

function SetServiceStatus(hServiceStatus: SERVICE_STATUS_HANDLE; var lpServiceStatus: TServiceStatus): BOOL; stdcall;
begin
  Result := Windows.SetServiceStatus(hServiceStatus, @lpServiceStatus);
end;

function QueryServiceStatus(hService: SC_HANDLE; var lpServiceStatus: TServiceStatus): BOOL; stdcall;
begin
  Result := Windows.QueryServiceStatus(hService, @lpServiceStatus);
end;

function StartServiceCtrlDispatcher(var lpServiceStartTable: TServiceTableEntry): BOOL; stdcall;
begin
  Result := Windows.StartServiceCtrlDispatcher(@lpServiceStartTable);
end;

function FileSetDate(FileName: String; Age: Longint): Longint;
var
  H: THandle;
begin
   H := FileOpen(FileName, 0);
  Result := SysUtils.FileSetDate(H, Age);
  FileClose(H);
end;

function TryStrToDate(const S: string; out Value: TDateTime): Boolean; 
begin
  try
    Value := StrToDate(S);
    Result := True;
  except
    Result := False;
  end;
end;

function TryStrToTime(const S: string; out Value: TDateTime): Boolean; 
begin
  try
    Value := StrToTime(S);
    Result := True;
  except
    Result := False;
  end;
end;

{$ENDIF}

end.
