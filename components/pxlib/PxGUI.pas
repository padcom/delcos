unit PxGUI;

{$I PxDefines.inc}

interface

uses
  // RTL units
  Windows, Messages, Classes, SysUtils,
  // PxLib units
  PxBase, PxUtils, PxResources;

// ----------------------------------------------------------------------------
// Classes
// ----------------------------------------------------------------------------

type
  TPxGUIObjectList = class;

  //
  // Base object for all GUI elements
  //
  TPxGUIObject = class (TPxBaseObject)
  private
    FOwner: TPxGUIObject;
    FItems: TPxGUIObjectList;
  public
    constructor Create(AOwner: TPxGUIObject); virtual;
    destructor Destroy; override;
    property Owner: TPxGUIObject read FOwner;
    property Items: TPxGUIObjectList read FItems;
  end;

  //
  // A list of base GUI elements
  //
  TPxGUIObjectList = class (TList)
  private
    function GetItem(Index: Integer): TPxGUIObject;
  public
    property Items[Index: Integer]: TPxGUIObject read GetItem; default;
  end;

  //
  // A base class for all visible elements
  //
  TPxGUIView = class (TPxGUIObject)
  private
    FHandle: THandle;
    function GetPosition: TPoint;
    procedure SetPosition(Value: TPoint);
    function GetSize: TSize;
    procedure SetSize(Value: TSize);
    function GetText: String;
    procedure SetText(Value: String);
    function GetVisible: Boolean;
    procedure SetVisible(Value: Boolean);
  protected
    procedure CreateWnd; virtual;
    procedure DestroyWnd; virtual;
    procedure Paint(DC: HDC); virtual;
    procedure WndProc(var Msg: TMessage); virtual;
    property Position: TPoint read GetPosition write SetPosition;
    property Size: TSize read GetSize write SetSize;
    property Text: String read GetText write SetText;
    property Visible: Boolean read GetVisible write SetVisible;
  public
    constructor Create(AOwner: TPxGUIObject); override;
    destructor Destroy; override;
    procedure Hide;
    procedure Show;
    property Handle: THandle read FHandle write FHandle;
  end;

  //
  // A base class for windows (can be used as MainWindow!)
  //
  TPxGUIWindow = class (TPxGUIView)
  private
    procedure WMPaint(var Msg: TWMPaint); message WM_PAINT;
  protected
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
    procedure WndProc(var Msg: TMessage); override;
  public
    property Position;
    property Size;
    property Text;
    property Visible;
  end;

  //
  // Main application object.
  // Created in initialization section so don't override it.
  //
  TPxGUIApplication = class (TPxGUIObject)
  private
    FMainWindow: TPxGUIWindow;
    FTerminated: Boolean;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
    procedure Run;
    property MainWindow: TPxGUIWindow read FMainWindow write FMainWindow;
    property Terminated: Boolean read FTerminated write FTerminated;
  end;

  //
  // All PxGUI exceptions are derived from this class
  //
  PxGUIException = class(EPxException);

// ----------------------------------------------------------------------------
// Some utility functions
// ----------------------------------------------------------------------------

//
// Show a message box with Information icon and SShowMessageTitle title along
// with the OK button.
//
procedure ShowMessage(Msg: String);

var
  Application: TPxGUIApplication;

implementation

{ TPxGUIObject }

{ Private declarations }

{ Public declarations }

constructor TPxGUIObject.Create(AOwner: TPxGUIObject);
begin
  inherited Create;
  FOwner := AOwner;
  FItems := TPxGUIObjectList.Create;
  if Assigned(Owner) then
    Owner.Items.Add(Self);
end;

destructor TPxGUIObject.Destroy;
begin
  while Items.Count > 0 do
    Items[Items.Count - 1].Free;
  FItems.Free;
  if Assigned(Owner) then
    Owner.Items.Remove(Self);
  inherited Destroy;
end;

{ TPxGUIObjectList }

{ Private declarations }

function TPxGUIObjectList.GetItem(Index: Integer): TPxGUIObject;
begin
  Result := TObject(Get(Index)) as TPxGUIObject;
end;

{ TPxGUIView }

{ Private declarations }

function TPxGUIView.GetPosition: TPoint;
var
  R: TRect;
begin
  if Handle <> INVALID_HANDLE_VALUE then
  begin
    GetWindowRect(Handle, R);
    Result := R.TopLeft;
  end
  else
    raise PxGUIException.Create(GetLastErrorStr);
end;

procedure TPxGUIView.SetPosition(Value: TPoint);
begin
  if Handle <> INVALID_HANDLE_VALUE then
    SetWindowPos(Handle, 0, Value.X, Value.Y, Size.cx, Size.cy, 0)
  else
    raise PxGUIException.Create(GetLastErrorStr);
end;

function TPxGUIView.GetSize: TSize;
var
  R: TRect;
begin
  if Handle <> INVALID_HANDLE_VALUE then
  begin
    GetWindowRect(Handle, R);
    Result.cx := R.Right - R.Left;
    Result.cy := R.Bottom - R.Top;
  end
  else
    raise PxGUIException.Create(GetLastErrorStr);
end;

procedure TPxGUIView.SetSize(Value: TSize);
begin
  if Handle <> INVALID_HANDLE_VALUE then
    SetWindowPos(Handle, 0, Position.X, Position.Y, Value.cx, Value.cy, 0)
  else
    raise PxGUIException.Create(GetLastErrorStr);
end;

function TPxGUIView.GetText: String;
var
  Len: Integer;
begin
  if FHandle <> INVALID_HANDLE_VALUE then
  begin
    SetLength(Result, 1024);
    Len := GetWindowText(FHandle, PChar(Result), Length(Result));
    if Len >= 0 then
      SetLength(Result, Len)
    else
      raise PxGUIException.Create(GetLastErrorStr);
  end
  else
    Result := '';
end;

procedure TPxGUIView.SetText(Value: String);
begin
  if FHandle <> INVALID_HANDLE_VALUE then
  begin
    if not SetWindowText(FHandle, PChar(Value)) then
      raise PxGUIException.Create(GetLastErrorStr);
  end
  else
    raise PxGUIException.Create(SWindowNotCreated);
end;

function TPxGUIView.GetVisible: Boolean;
begin
  if FHandle <> INVALID_HANDLE_VALUE then
    Result := IsWindowVisible(Handle)
  else
    raise PxGUIException.Create(SWindowNotCreated);
end;

procedure TPxGUIView.SetVisible(Value: Boolean);
begin
  if FHandle <> INVALID_HANDLE_VALUE then
  begin
    if Visible <> Value then
    begin
      if Value then
        ShowWindow(Handle, SW_SHOW)
      else
        ShowWindow(Handle, SW_HIDE);
      UpdateWindow(Handle);
    end;
  end
  else
    raise PxGUIException.Create('Window not created');
end;

{ Protected declarations }

procedure TPxGUIView.CreateWnd;
begin
  TProcedure(AbstractErrorProc);
end;

procedure TPxGUIView.DestroyWnd;
begin
  if FHandle <> INVALID_HANDLE_VALUE then
    DestroyWindow(FHandle)
end;

procedure TPxGUIView.Paint(DC: HDC);
begin
end;

procedure TPxGUIView.WndProc(var Msg: TMessage);
begin
  Dispatch(Msg);
  Msg.Result := DefWindowProc(FHandle, Msg.Msg, Msg.WParam, Msg.LParam);
end;

{ Public declarations }

constructor TPxGUIView.Create(AOwner: TPxGUIObject);
begin
  inherited Create(AOwner);
  CreateWnd;
end;

destructor TPxGUIView.Destroy;
begin
  DestroyWnd;
  inherited Destroy;
end;

procedure TPxGUIView.Hide;
begin
  Visible := False;
end;

procedure TPxGUIView.Show;
begin
  Visible := True;
end;

{ TPxGUIWindow }

{ Private declarations }

procedure TPxGUIWindow.WMPaint(var Msg: TWMPaint);
var
  R: TRect;
begin
  // let's draw something
  R := Rect(10, 10, 100, 100);
  Msg.DC := GetDC(Handle);
  DrawText(Msg.DC, 'Test', 4, R, 0);
  ReleaseDC(Handle, Msg.DC);
end;

{ Protected declarations }

function PxGUIWndProc(hWindow: HWND; Msg: Cardinal; wParam, lParam: Integer): Integer; stdcall;
  function FindView(Root: TPxGUIView): TPxGUIView;
  var
    I: Integer;
  begin
    if Root.Handle = hWindow then
      Result := Root
    else
    begin
      Result := nil;
      for I := 0 to Root.Items.Count - 1 do
        if Root.Items[I] is TPxGUIView then
        begin
          Result := FindView(Root.Items[I] as TPxGUIView);
          if Assigned(Result) then
            Break;
        end;
    end;
  end;
var
  View: TPxGUIView;
  Message: TMessage;
begin
  if Assigned(Application.MainWindow) then
  begin
    View := FindView(Application.MainWindow);
    if Assigned(View) then
    begin
      // create the Message record
      Message.Msg := Msg;
      Message.WParam := wParam;
      Message.LParam := lParam;
      // call default window proc for this class
      // note: the TPxGUIView.WndProc calls Dispatch and DefWindowProc
      View.WndProc(Message);
      Result := Message.Result;
    end
    else
      // call the default handler
      Result := DefWindowProc(hWindow, Msg, wParam, lParam);
  end
  else
    // call the default handler
    Result := DefWindowProc(hWindow, Msg, wParam, lParam);
end;

procedure TPxGUIWindow.CreateWnd;
var
  ParentWnd: HWND;
  WndClass: TWndClass;
begin
  ZeroMemory(@WndClass, SizeOf(TWndClass));
  with WndClass do
  begin
    style         := CS_CLASSDC or CS_PARENTDC;
    lpfnWndProc   := @PxGUIWndProc;
{$IFDEF FPC}
    hInstance     := System.HInstance;
{$ELSE}
    hInstance     := SysInit.HInstance;
{$ENDIF}
    hbrBackground := COLOR_BTNFACE + 1;
    lpszClassname := PChar(String(ClassName));
  end;
  Windows.RegisterClass(WndClass);

  if Assigned(Owner) and (Owner is TPxGUIView) then
    ParentWnd := TPxGUIView(Owner).Handle
  else
    ParentWnd := 0;

  FHandle := CreateWindowEx(
    WS_EX_WINDOWEDGE,
    PChar(String(ClassName)),
    '',
    WS_CAPTION or WS_SYSMENU or WS_BORDER or WS_THICKFRAME,
    -1, -1, -1, -1, ParentWnd, 0,
    HInstance,
    nil);
    
  PostMessage(FHandle, WM_SETFONT, GetStockObject(DEFAULT_GUI_FONT), 0);
end;

procedure TPxGUIWindow.DestroyWnd;
begin
  inherited DestroyWnd;
  Windows.UnregisterClass(PChar(String(ClassName)), HInstance);
end;

procedure TPxGUIWindow.WndProc(var Msg: TMessage);
begin
  if (Msg.Msg = WM_DESTROY) and (Application.MainWindow = Self) then
    Application.Terminated := True;
  inherited WndProc(Msg);
end;

{ TPxGUIApplication }

{ Public declarations }

constructor TPxGUIApplication.Create;
begin
  inherited Create(nil);
end;

destructor TPxGUIApplication.Destroy;
begin
  inherited Destroy;
end;

procedure TPxGUIApplication.Run;
var
  Msg: TMsg;
begin
  if Assigned(MainWindow) then
  begin
    MainWindow.Show;
    while GetMessage(Msg, MainWindow.Handle, 0, 0) do
    begin
      if not IsDialogMessage(MainWindow.Handle, Msg) then
      begin
        TranslateMessage(Msg);
        DispatchMessage(Msg);
      end;
      if Terminated then Break;
    end;
  end;
end;

{ *** }

procedure ShowMessage(Msg: String);
begin
  MessageBox(Application.MainWindow.Handle, PChar(Msg), PChar(SShowMessageTitle), MB_ICONINFORMATION or MB_OK);
end;

initialization
  Application := TPxGUIApplication.Create;

finalization
  Application.Free;

end.
