unit PxTerminal;

interface

uses
  Windows, SysUtils,
  PxBase, PxUtils, PxThread, PxGetText;

type
  TBaudRate = (br1200, br2400, br4800, br9600, br14400, br19200, br28800, br38400, br56000, br112000, br115200);
  TDataBits = (db7, db8);
  TParity   = (paNone, paOdd, paEven);
  TStopBits = (sbOne, sbOneAndHalf, sbTwo);

  TPxTerminal = class;

  TOnDataReadEvent = procedure (Sender: TPxTerminal; Data: Pointer; DataSize: DWORD) of object;

  TPxTerminal = class (TObject)
  private
    FSerial: THandle;
    FKeyboard: THandle;
    FOutput: THandle;
    FSerialThread: TPxThread;
    FKeyboardThread: TPxThread;
    FOnSeriaData: TOnDataReadEvent;
    FOnKeyboardData: TOnDataReadEvent;
  protected
  public
    constructor Create(COM: String; BaudRate: TBaudRate; DataBits: TDataBits; Parity: TParity; StopBits: TStopBits);
    destructor Destroy; override;
    procedure Run;
    property OnSeriaData: TOnDataReadEvent read FOnSeriaData write FOnSeriaData;
    property OnKeyboardData: TOnDataReadEvent read FOnKeyboardData write FOnKeyboardData;
  end;

  EPxTerminalError = class (Exception);

implementation

//type
//  TSource = (srcSerial, srcKeyboard);

//  TReadThread = class (TPxThread)
//  private
//    FHandle: THandle;
//    FSource: TSource;
//    FTerminal: TPxTerminal;
//  protected
//    procedure Execute; override;
//  public
//    constructor Create(ASource: TSource; AHandle: THandle);
//  end;

{ TReadThread }

{ Private declarations }

{ Protected declarations }

//procedure TReadThread.Execute;
//var
//  Data : array of Byte;
//  Count: DWORD;
//begin
//  SetLength(Data, 1024);
//  repeat
//    if ReadFile(FHandle, Data[0], SizeOf(Data), Count, nil) then
//      case FSource of
//        srcSerial: FTerminal.
//  until Terminated;
//end;

{ Public declarations }

//constructor TReadThread.Create(ASource: TSource; AHandle: THandle);
//begin
//  inherited Create(True);
//  FSource := ASource;
//  FHandle := AHandle;
//  Resume;
//end;

{ TPxTerminal }

{ Private declarations }

{ Protected declarations }

{ Public declarations }

constructor TPxTerminal.Create(COM: String; BaudRate: TBaudRate; DataBits: TDataBits; Parity: TParity; StopBits: TStopBits);
var
  Settings: DCB;
  Cto: COMMTIMEOUTS;
begin
  FSerial := CreateFile(PChar(COM), GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0);
  if FSerial = INVALID_HANDLE_VALUE then
    raise EPxTerminalError.CreateFmt(GetText(SCannotOpenSerialPort), [GetLastErrorStr]);

  Settings.DCBlength := SizeOf(Settings);
  GetCommState(FSerial, Settings);
  Settings.Flags := 0;
  case BaudRate of
    br1200: Settings.BaudRate := 1200;
    br2400: Settings.BaudRate := 2400;
    br4800: Settings.BaudRate := 4800;
    br9600: Settings.BaudRate := 9600;
    br14400: Settings.BaudRate := 14400;
    br19200: Settings.BaudRate := 19200;
    br28800: Settings.BaudRate := 28800;
    br38400: Settings.BaudRate := 38400;
    br56000: Settings.BaudRate := 56000;
    br112000: Settings.BaudRate := 112000;
    br115200: Settings.BaudRate := 115200;
  end;
  case DataBits of
    db7: Settings.ByteSize := 7;
    db8: Settings.ByteSize := 8;
  end;
  case Parity of
    paNone: Settings.Parity := NOPARITY;
    paOdd: Settings.Parity := ODDPARITY;
    paEven: Settings.Parity := EVENPARITY;
  end;
  case StopBits of
    sbOne: Settings.StopBits := ONESTOPBIT;
    sbOneAndHalf: Settings.StopBits := ONE5STOPBITS;
    sbTwo: Settings.StopBits := TWOSTOPBITS;
  end;
  if not SetCommMask(FSerial, 0) then
    raise EPxTerminalError.CreateFmt(GetText(SCannotOpenSerialPort), [GetLastErrorStr]);

  if not SetCommTimeouts(FSerial, Cto) then
    raise EPxTerminalError.CreateFmt(GetText(SCannotOpenSerialPort), [GetLastErrorStr]);

  if not SetCommState(FSerial, Settings) then
    raise EPxTerminalError.CreateFmt(GetText(SCannotOpenSerialPort), [GetLastErrorStr]);

  FKeyboard := GetStdHandle(STD_INPUT_HANDLE);
  FOutput := GetStdHandle(STD_OUTPUT_HANDLE);
end;

destructor TPxTerminal.Destroy;
begin
  FileClose(FSerial);
  FileClose(FKeyboard);
  inherited Destroy;
end;

var
  Terminated: Boolean;
  Handles: array[0..1] of THandle;

function ConsoleHandler(dwCtrlType: DWORD): Integer;
begin
  case dwCtrlType of
    CTRL_C_EVENT,
    CTRL_BREAK_EVENT,
    CTRL_CLOSE_EVENT,
    CTRL_LOGOFF_EVENT,
    CTRL_SHUTDOWN_EVENT:
    begin
      Terminated := True;
      FileClose(Handles[0]);
      FileClose(Handles[1]);
    end;
  end;
  Result := 0;
end;

type
  PWaitTHreadParams = ^TWaitThreadParams;
  TWaitThreadParams = record
    Input : THandle;
    Output: THandle;
  end;

procedure WaitThread(Params: PWaitTHreadParams); stdcall;
var
  Count : Cardinal;
  Buffer: Char;
begin
  repeat
    ReadFile(Params^.Input, Buffer, 1, Count, nil);
    if Count > 0 then
      WriteFile(Params^.Output, Buffer, Count, Count, nil);
  until Terminated;
  ExitThread(0);
end;

procedure TPxTerminal.Run;
var
  T1, T2: THandle;
  P1, P2: TWaitThreadParams;
begin
  SetConsoleCtrlHandler(@ConsoleHandler, True);
  P1.Input := FKeyboard; P1.Output := FSerial;
  CreateThread(nil, 1024, @WaitThread, @P1, 0, T1);
  P2.Input := FSerial; P2.Output := FKeyboard;
  CreateThread(nil, 1024, @WaitThread, @P2, 0, T2);
  repeat
    Sleep(100);
  until Terminated;
  WaitForSingleObject(T1, 1000);
  WaitForSingleObject(T2, 1000);
end;

end.

