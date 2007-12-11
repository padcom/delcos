// ----------------------------------------------------------------------------
// Unit        : PxSplash.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 
// Version     : 1.0
// Description : 
// Changes log : 2005-06-01 - initial version
//               2005-06-22 - changed the way the message loop is driven. 
//                            Now it is a separate thread.
// ToDo        : Testing.
// ----------------------------------------------------------------------------

unit PxSplash;

interface

uses
{$IFDEF USEVCL}
  Forms,
{$ENDIF}                        
  Windows, Messages;

//
// This unit requires that in the splash bitmap is included in the exe resources, ie:
//
// splash.rc:
//   SPLASH BITMAP "appsplash.bmp"
//
// and the resulting resource file is linked to the executable with
//
// project.dpr:
//   {$R Splash.res}

//
// Show the splash for Timeout miliseconds.
// If Timeout = 0 equals then no timeout. In that case use HideSplash to manualy remove the splash from screen
//
procedure ShowSplash(Timeout: Integer);

//
// Call this to hide the splash manually (see ShowSplash without timeout)
//
procedure HideSplash;

implementation

const
  SPLASH_WIDTH  = 440;
  SPLASH_HEIGHT = 221;
  SPLASH_CLASS  = 'SPLASH';

var
  SplashClass: WNDCLASS;
  hSplashWnd: THandle;
  hSplashLogo: THandle;
  hSplashThread: THandle;

function SplashWndProc(hWnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): Integer; stdcall;
var
  PS: PAINTSTRUCT;
  DC, BDC: HDC;
begin
  case Msg of
    WM_CREATE:
    begin
      hSplashLogo := LoadBitmap(hInstance, 'SPLASH');
      Result := 0;
    end;
    WM_DESTROY:
    begin
      DeleteObject(hSplashLogo);
      PostQuitMessage(0);
      Result := 0;
    end;
    WM_PAINT:
    begin
      DC := BeginPaint(hWnd, PS);
      BDC := CreateCompatibleDC(DC);
      SelectObject(BDC, hSplashLogo);
      BitBlt(DC, 0, 0, SPLASH_WIDTH, SPLASH_HEIGHT, BDC, 0, 0, SRCCOPY);
      DeleteDC(BDC);
      EndPaint(hWnd, PS);
      Result := 0;
    end;
    WM_CLOSE:
    begin
      Result := DefWindowProc(hWnd, Msg, wParam, lParam);
    end;
    WM_TIMER:
    begin
      KillTimer(hWnd, 1);
      DestroyWindow(hWnd);
      Result := 0;
    end;
    else Result := DefWindowProc(hWnd, Msg, wParam, lParam);
  end;
end;

procedure SplashThread(Data: Pointer); stdcall;
var
  M: MSG;
  R: TRect;
  Timeout: Integer;
begin
  Timeout := Integer(Data);

  SplashClass.style := CS_VREDRAW or CS_HREDRAW;
  SplashClass.lpfnWndProc := @SplashWndProc;
  SplashClass.cbClsExtra := 0;
  SplashClass.cbWndExtra := 0;
  SplashClass.hInstance := hInstance;
  SplashClass.hIcon := 0;
  SplashClass.hCursor := LoadCursor(hInstance, IDC_WAIT);
  SplashClass.hbrBackground := 0;
  SplashClass.lpszMenuName := '';
  SplashClass.lpszClassName := SPLASH_CLASS;
  RegisterClass(SplashClass);

  GetClientRect(GetDesktopWindow, R);
  R.Left := (R.Right - SPLASH_WIDTH) div 2;
  R.Top := (R.Bottom - SPLASH_Height) div 2;
  hSplashWnd := CreateWindowEx(WS_EX_TOPMOST or WS_EX_TOOLWINDOW, SPLASH_CLASS, '', WS_CHILD or WS_POPUP, R.Left, R.Top, SPLASH_WIDTH, SPLASH_HEIGHT, GetDesktopWindow, 0, HInstance, nil);
  ShowWindow(hSplashWnd, SW_SHOWNORMAL);
  UpdateWindow(hSplashWnd);

  if Timeout > 0 then
    SetTimer(hSplashWnd, 1, Timeout, nil);

  while GetMessage(M, 0, 0, 0) do
  begin
    TranslateMessage(M);
    DispatchMessage(M);
  end;

  UnregisterClass(SPLASH_CLASS, hInstance);
//  ExitThread(0);
end;

procedure ShowSplash;
var
  TID: Cardinal;
begin
  // create the splash thread so that messages are
  hSplashThread := CreateThread(nil, 4096, @SplashThread, Pointer(Timeout), 0, TID);
end;

procedure HideSplash;
begin
  if hSplashWnd <> 0 then
  begin
    // Close the splash window and wait 'till the splash thread terminates  
    SendMessage(hSplashWnd, WM_TIMER, 1, 0);
    WaitForSingleObject(hSplashThread, INFINITE);

{$IFDEF USEVCL}
    // Make the top-most window active
    //
    // Warning: If a additional form is created before the main application form it becomes the active window
    //
    if Screen.FormCount > 0 then
      SetForegroundWindow(Screen.Forms[0].Handle);
{$ENDIF}
  end;
end;

end.
