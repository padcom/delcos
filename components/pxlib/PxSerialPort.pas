// ----------------------------------------------------------------------------
// Unit        : PxSerialPort.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2005-05-05
// Version     : 1.0
// Description : Object oriented serial port communication implementation.
// Changes log : 2005-05-05 - initial version
// ToDo        : Testing.
// ----------------------------------------------------------------------------

unit PxSerialPort;

{$I PxDefines.inc}

interface

uses
  Windows, Classes, SysUtils,
  PxBase, PxResources, PxUtils, PxThread, PxGetText;

type
  // Data bits (byte length)
  TPxSerialPortDataBits = (db7Bits, db8Bits);
  // Parity
  TPxSerialPortParity = (paNone, paOdd, paEven);
  // Stop bits
  TPxSerialPortStopBits = (sbOne, sbOneAndHalf, sbTwo);

  TPxSerialPort = class(THandleStream)
  private
    function GetBaudRate: Integer;
    procedure SetBaudRate(Value: Integer);
    function GetDataBits: TPxSerialPortDataBits;
    procedure SetDataBits(Value: TPxSerialPortDataBits);
    function GetParity: TPxSerialPortParity;
    procedure SetParity(Value: TPxSerialPortParity);
    function GetStopBits: TPxSerialPortStopBits;
    procedure SetStopBits(Value: TPxSerialPortStopBits);
    function GetTimeout: Integer;
    procedure SetTimeout(Value: Integer);
  public
    constructor Create(Port: String);
    destructor Destroy; override;
    procedure Send(S: String); overload;
    procedure Flush;
    // Port settings
    property BaudRate: Integer read GetBaudRate write SetBaudRate;
    property DataBits: TPxSerialPortDataBits read GetDataBits write SetDataBits;
    property Parity: TPxSerialPortParity read GetParity write SetParity;
    property StopBits: TPxSerialPortStopBits read GetStopBits write SetStopBits;
    property Timeout: Integer read GetTimeout write SetTimeout;
  end;

  EPxSerialPortError = class (EPxException);

implementation

{ TPxSerialPort }

{ Private declarations }

function TPxSerialPort.GetBaudRate: Integer;
var
  Settings: DCB;
begin
  if GetCommState(Handle, Settings) then
    Result := Settings.BaudRate
  else
    raise EPxSerialPortError.CreateFmt(SErrorWhileRetrivingSerialPortSettings, [GetLastErrorStr]);
end;

procedure TPxSerialPort.SetBaudRate(Value: Integer);
var
  Settings: DCB;
begin
  if GetCommState(Handle, Settings) then
  begin
    Settings.BaudRate := Value;
    if not SetCommState(Handle, Settings) then
      raise EPxSerialPortError.CreateFmt(SErrorWhileSettingSerialPortSettings, [GetLastErrorStr]);
  end
  else
    raise EPxSerialPortError.CreateFmt(SErrorWhileRetrivingSerialPortSettings, [GetLastErrorStr]);
end;

function TPxSerialPort.GetDataBits: TPxSerialPortDataBits;
var
  Settings: DCB;
begin
  if GetCommState(Handle, Settings) then
    case Settings.ByteSize of
      7: Result := db7Bits;
      8: Result := db8Bits;
      else
        raise EPxSerialPortError.CreateFmt(SInvalidByteSize, [Settings.ByteSize]);
    end
  else
    raise EPxSerialPortError.CreateFmt(SErrorWhileRetrivingSerialPortSettings, [GetLastErrorStr]);
end;

procedure TPxSerialPort.SetDataBits(Value: TPxSerialPortDataBits);
var
  Settings: DCB;
begin
  if GetCommState(Handle, Settings) then
  begin
    case Value of
      db7Bits: Settings.ByteSize := 7;
      db8Bits: Settings.ByteSize := 8;
    end;
    if not SetCommState(Handle, Settings) then
      raise EPxSerialPortError.CreateFmt(SErrorWhileSettingSerialPortSettings, [GetLastErrorStr]);
  end
  else
    raise EPxSerialPortError.CreateFmt(SErrorWhileRetrivingSerialPortSettings, [GetLastErrorStr]);
end;

function TPxSerialPort.GetParity: TPxSerialPortParity;
var
  Settings: DCB;
begin
  if GetCommState(Handle, Settings) then
    case Settings.Parity of
      NOPARITY:
        Result := paNone;
      ODDPARITY:
        Result := paOdd;
      EVENPARITY:
        Result := paEven;
      else
        raise EPxSerialPortError.CreateFmt(SInvalidParity, [Settings.Parity]);
    end
  else
    raise EPxSerialPortError.CreateFmt(SErrorWhileRetrivingSerialPortSettings, [GetLastErrorStr]);
end;

procedure TPxSerialPort.SetParity(Value: TPxSerialPortParity);
var
  Settings: DCB;
begin
  if GetCommState(Handle, Settings) then
  begin
    case Value of
      paNone:
        Settings.Parity := NOPARITY;
      paOdd:
        Settings.Parity := ODDPARITY;
      paEven:
        Settings.Parity := EVENPARITY;
    end;
    if not SetCommState(Handle, Settings) then
      raise EPxSerialPortError.CreateFmt(SErrorWhileSettingSerialPortSettings, [GetLastErrorStr]);
  end
  else
    raise EPxSerialPortError.CreateFmt(SErrorWhileRetrivingSerialPortSettings, [GetLastErrorStr]);
end;

function TPxSerialPort.GetStopBits: TPxSerialPortStopBits;
var
  Settings: DCB;
begin
  if GetCommState(Handle, Settings) then
    case Settings.StopBits of
      ONESTOPBIT:
        Result := sbOne;
      ONE5STOPBITS:
        Result := sbOneAndHalf;
      TWOSTOPBITS:
        Result := sbTwo;
      else
        raise EPxSerialPortError.CreateFmt(SInvalidStopBits, [Settings.StopBits]);
    end
  else
    raise EPxSerialPortError.CreateFmt(SErrorWhileRetrivingSerialPortSettings, [GetLastErrorStr]);
end;

procedure TPxSerialPort.SetStopBits(Value: TPxSerialPortStopBits);
var
  Settings: DCB;
begin
  if GetCommState(Handle, Settings) then
  begin
    case Value of
      sbOne:
        Settings.StopBits := ONESTOPBIT;
      sbOneAndHalf:
        Settings.StopBits := ONE5STOPBITS;
      sbTwo:
        Settings.StopBits := TWOSTOPBITS;
    end;
    if not SetCommState(Handle, Settings) then
      raise EPxSerialPortError.CreateFmt(SErrorWhileSettingSerialPortSettings, [GetLastErrorStr]);
  end
  else
    raise EPxSerialPortError.CreateFmt(SErrorWhileRetrivingSerialPortSettings, [GetLastErrorStr]);
end;

function TPxSerialPort.GetTimeout: Integer;
var
  Timeouts: COMMTIMEOUTS;
begin
  if GetCommTimeouts(Handle, Timeouts) then
    Result := Timeouts.ReadIntervalTimeout
  else
    raise EPxSerialPortError.CreateFmt(SErrorWhileRetrivingSerialPortSettings, [GetLastErrorStr]);
end;

procedure TPxSerialPort.SetTimeout(Value: Integer);
var
  Timeouts: COMMTIMEOUTS;
begin
  if GetCommTimeouts(Handle, Timeouts) then
  begin
    Timeouts.ReadIntervalTimeout := Value;
    if not SetCommTimeouts(Handle, Timeouts) then
      raise EPxSerialPortError.CreateFmt(SErrorWhileSettingSerialPortSettings, [GetLastErrorStr]);
  end
  else
    raise EPxSerialPortError.CreateFmt(SErrorWhileRetrivingSerialPortSettings, [GetLastErrorStr]);
end;

{ Public declarations }

constructor TPxSerialPort.Create(Port: String);
var
  TmpHandle: THandle;
begin
  TmpHandle := CreateFile(PChar(Port), GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0);
  if DWORD(TmpHandle) = INVALID_HANDLE_VALUE then
    raise EPxSerialPortError.CreateFmt(GetText(SCannotOpenSerialPort), [GetLastErrorStr]);
  inherited Create(TmpHandle);
end;

destructor TPxSerialPort.Destroy;
begin
  CloseHandle(Handle);
  inherited Destroy;
end;

procedure TPxSerialPort.Send(S: String);
begin
  Write(S[1], Length(S));
end;

procedure TPxSerialPort.Flush;
begin
  FlushFileBuffers(Handle);
end;

end.

