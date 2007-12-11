program madInstall;

{$APPTYPE CONSOLE}

uses
  Windows,
  Messages,
  Types,
  PxGUI;

//var
//  mainWnd, edit, static, browse, madshi, install, abort : cardinal;
//
//function WndProc(window, msg: cardinal; wParam, lParam: integer) : integer; stdcall;
//begin
//  result := DefWindowProc(window, msg, wParam, lParam);
//  if msg = WM_DESTROY then ExitProcess(0);
//end;
//
//type
//  TWndProc = function(hWindow: HWND; Msg: Cardinal; wParam, lParam: Integer): Integer; stdcall;
//
//var
//  Prev: TWndProc;
//
//function WndProc1(hWindow: HWND; Msg: Cardinal; wParam, lParam: Integer): Integer; stdcall;
//var
//  M: TMessage;
//begin
//  // ROTFL! This is a subclased window procedure that changes the default behaviour of
//  // WM_CHAR event. If the "y" key is pressed the "z" key is passed along and otherway
//  // the "z" key is switched back to "y".
//  M.Msg := Msg;
//  M.WParam := wParam;
//  M.LParam := lParam;
//  if (Msg = WM_CHAR) then
//  begin
//    if TWMKey(M).CharCode = Ord('y') then
//      TWMKey(M).CharCode := Ord('z')
//    else if TWMKey(M).CharCode = Ord('z') then
//      TWMKey(M).CharCode := Ord('y')
//  end;
//  wParam := M.wParam;
//  lParam := M.lParam;
//  Result := Prev(hWindow, Msg, wParam, lParam);
//end;
//
//var
//  wndClass : TWndClass;
//  msg      : TMsg;
//  Font     : HFONT;
//
//procedure SetWindowFont(hWindow: HWND; hFont: HFONT);
//begin
//  // this is how you set a font for a window
//  // It must be done for every window and not like in the
//  // VCL only for the TForm that's hosting other controls.
//  PostMessage(hWindow, WM_SETFONT, hFont, 0);
//end;
//
//procedure DoMain;
//begin
//  ZeroMemory(@wndClass, sizeOf(TWndClass));
//  with wndClass do begin
//    style         := CS_CLASSDC or CS_PARENTDC;
//    lpfnWndProc   := @WndProc;
//    hInstance     := SysInit.HInstance;
//    hbrBackground := color_btnface + 1;
//    lpszClassname := 'madInstall';
//  end;
//
//  RegisterClass(wndClass);
//
//  mainWnd := CreateWindowEx(
//    WS_EX_WINDOWEDGE or WS_EX_TOOLWINDOW{ or WS_EX_DLGMODALFRAME},
//    'madInstall',
//    'madInstall...',
//    WS_VISIBLE or WS_CAPTION or WS_SYSMENU or WS_BORDER or WS_THICKFRAME,
//    330, 280, 325, 110, 0, 0,
//    HInstance,
//    nil);
//
//  // this is how you get the default GUI font (MS Sans Serif)
//  Font := GetStockObject(DEFAULT_GUI_FONT);
//
//  static := CreateWindow('Static', 'Path:', WS_VISIBLE or WS_CHILD or SS_LEFT,
//                         8, 12, 76, 13, mainWnd, 0, HInstance, nil);
//  SetWindowFont(static, Font);
//  edit := CreateWindowEx(WS_EX_CLIENTEDGE, 'Edit', '', WS_CHILD or WS_VISIBLE or WS_BORDER or WS_TABSTOP,
//                         40, 8, 250, 22, mainWnd, 0, HInstance, nil);
//  SetWindowFont(edit, Font);
//  browse := CreateWindow('Button', '...', WS_VISIBLE or WS_CHILD or WS_TABSTOP or BS_PUSHLIKE or BS_TEXT,
//                         292, 11, 17, 17, mainWnd, 0, HInstance, nil);
//  SetWindowFont(browse, Font);
//  madshi := CreateWindow('Static', 'www.madshi.net', WS_VISIBLE or WS_CHILD or SS_LEFT,
//                         4, 64, 90, 13, mainWnd, 0, HInstance, nil);
//  SetWindowFont(madshi, Font);
//  install := CreateWindow('Button', 'Install', WS_VISIBLE or WS_CHILD or WS_TABSTOP or BS_DEFPUSHBUTTON or BS_TEXT,
//                          145, 43, 75, 25, mainWnd, 0, HInstance, nil);
//  SetWindowFont(install, Font);
//  abort := CreateWindow('Button', 'Abort', WS_VISIBLE or WS_CHILD or WS_TABSTOP or BS_PUSHLIKE or BS_TEXT,
//                        233, 43, 75, 25, mainWnd, 0, HInstance, nil);
//  SetWindowFont(Abort, Font);
//
//  Prev := Pointer(GetWindowLong(edit, GWL_WNDPROC));
//  SetWindowLong(edit, GWL_WNDPROC, Integer(Pointer(@WndProc1)));
//
//  SetFocus(install);
//  while GetMessage(Msg, mainWnd, 0, 0) do
//  begin
//    if not IsDialogMessage(mainWnd, Msg) then
//    begin
//      TranslateMessage(msg);
//      DispatchMessage(msg);
//    end;
//  end;
//end;

begin
  Application.MainWindow := TPxGUIWindow.Create(Application);
  Application.MainWindow.Text := 'Hello, world!';
  Application.MainWindow.Position := Point(100, 100);
  Application.MainWindow.Size := TSize(Point(400, 400));
  Application.Run;
end.
