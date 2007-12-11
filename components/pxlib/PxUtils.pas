// ----------------------------------------------------------------------------
// Unit        : PxUtils.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2004-12-03
// Version     : 1.0
// Description : Routines that cannot be qualified elswhere.
// Changes log : 2004-12-03 - initial version
//               2004-12-22 - added ExceptionToString function to simplify
//                            exception handling in threads. You can use this
//                            function in TPxThread descendants to log errors
//                            in a little more descriptive way
//               2005-03-01 - added OverwriteProcedure function (based of
//                            sources from TNT components suite)
//               2005-03-15 - added IsDelphiIDERunning and IsDelphiHost
//               2005-03-21 - added PostKeyEx32 procedure
//               2005-08-18 - added GetExeProcessId function
//               2005-10-04 - added ByteToBin and BinToByte functions
//               2005-10-14 - added Delphi 5 comaptibility
// ToDo        : Testing.
// ----------------------------------------------------------------------------

unit PxUtils;

{$I PxDefines.inc}

interface

uses
  Windows, Classes, SysUtils;

// XOR the content of a double value (treat as an array of bytes)
function XorDouble(Data: Double; XorValue: Int64): Double;

// Convert an exception object to human readable string
function ExceptionToString(E: Exception; Sender: TObject = nil): WideString;

// Min and Max calculation for integer values (they are used often
// and including Math unit just for them is to expensive)
function Min(A, B: Integer): Integer;
function Max(A, B: Integer): Integer;

// OverwriteProcedure originally from Igor Siticov
// Modified by Jacques Garcia Vazquez, Matthias Hryniszak
function OverwriteProcedure(OldProcedure, NewProcedure: Pointer): Pointer;

// Returns a string describing GetLastError error code
function GetLastErrorStr: WideString;

// Removes all occourences of the & sign (used to mark the hot-key in menus)
// so that the same strings can be used in menus and in other elements
function RemoveAmpersand(S: WideString): WideString;

// Removes all new line characters with spaces
function StripCRLFToSpaces(S: WideString): WideString;

// Checks if Delphi IDE is running
function IsDelphiIDERunning: Boolean;

// Checks is Delphi IDE is the current host application
// Usefull if some subsystems are working automatically and Delphi is not
// cooperating with them well.
function IsDelphiHost: Boolean;

// Uses keybd_event to manufacture a series of key events matching
// the passed parameters. The events go to the control with focus.
// Note that for characters key is always the upper-case version of
// the character. Sending without any modifier keys will result in
// a lower-case character, sending it with [ssShift] will result
// in an upper-case character!
//
// Parameters:
//  Key       : virtual keycode of the key to send. For printable
//              keys this is simply the ANSI code (Ord(character)).
//  Shift     : state of the modifier keys. This is a set, so you
//              can set several of these keys (shift, control, alt,
//              mouse buttons) in tandem. The TShiftState type is
//              declared in the Classes Unit.
//  SpecialKey: normally this should be False. Set it to True to
//              specify a key on the numeric keypad, for example.
procedure PostKey(Key: Word; const Shift: TShiftState; SpecialKey: Boolean);

// Changes any occourences of '/' to the right path separator
function UnifyPathSeparator(Path: String): String;

// Generates a random string of a given length
function RandomString(Length: Integer): String;

// Gets the actual file size (using TFileStream !)
function FileSize(FileName: String): Int64;

// Gets process id from the given executable name
function GetExeProcessId(ExeName: String): THandle;

//
// Checks if a pointer is a valid pointer.
// Can be used if in Data property of some controls
// a bogus pointer $0000001 - $00000FF is assigned.
//
function AssignedEx(const P): Boolean;

//
// Converts a byte to a string with binary represantation 
//
function ByteToBin(B: Byte): String;

//
// Converts a string with binary represantation to an integer
//
function BinToByte(S: string): Int64;
function IntToBin(V: Int64; L: Integer): String;
function BinToInt(S: string): Int64;

implementation

{$IFDEF VER130}
uses
  PxDelphi5;
{$ENDIF}  

function XorDouble(Data: Double; XorValue: Int64): Double;
var
  I: Integer;
  BD, BX: PByteArray;
begin
  BD := @Data; BX := @XorValue;
  for I := 0 to 7 do
    BD^[I] := BD^[I] xor BX^[I];
  Result := Data;
end;

function ExceptionToString(E: Exception; Sender: TObject = nil): WideString;
begin
  if Assigned(Sender) then
    Result := WideFormat('%s exception raised at 0x%.8X (%s): "%s"', [E.ClassName, LongWord(ExceptAddr), Sender.ClassName, E.Message])
  else
    Result := WideFormat('%s exception raised at 0x%.8X: "%s"', [E.ClassName, LongWord(ExceptAddr), E.Message]);
end;

function Min(A, B: Integer): Integer;
begin
  if A < B then Result := A
  else Result := B;
end;

function Max(A, B: Integer): Integer;
begin
  if A > B then Result := A
  else Result := B;
end;

function OverwriteProcedure(OldProcedure, NewProcedure: Pointer): Pointer;
var
  X: PAnsiChar;
  Y: Integer;
  ov2, ov: Cardinal;
  P: Pointer;
begin
  // need six bytes in place of 5
  X := PAnsiChar(OldProcedure);
  if not VirtualProtect(Pointer(X), 6, PAGE_EXECUTE_READWRITE, @ov) then
    RaiseLastOSError;

  // if a jump is present then a redirect is found
  // $FF25 = jmp dword ptr [xxx]
  // This redirect is normally present in bpl files, but not in exe files
  P := OldProcedure;

  if Word(P^) = $25FF then
  begin
    Inc(Integer(P), 2); // skip the jump
    // get the jump address p^ and dereference it p^^
    P := Pointer(Pointer(P^)^);

    // release the memory
    if not VirtualProtect(Pointer(X), 6, ov, @ov2) then
      RaiseLastOSError;

    // re protect the correct one
    X := PAnsiChar(P);
    if not VirtualProtect(Pointer(X), 6, PAGE_EXECUTE_READWRITE, @ov) then
      RaiseLastOSError;
  end;

  // return old function location
  Result := X;

  // store new function location
  X[0] := AnsiChar($E9);
  Y := Integer(NewProcedure) - Integer(P) - 5;
  X[1] := AnsiChar(Y and 255);
  X[2] := AnsiChar((Y shr 8) and 255);
  X[3] := AnsiChar((Y shr 16) and 255);
  X[4] := AnsiChar((Y shr 24) and 255);

  if not VirtualProtect(Pointer(X), 6, ov, @ov2) then
    RaiseLastOSError;
end;

function GetLastErrorStr: WideString;
var
  Buffer: WideString;
begin
  SetLength(Buffer, 1024);
  SetLength(Buffer, FormatMessageW(FORMAT_MESSAGE_FROM_SYSTEM, nil, GetLastError, 0, @Buffer[1], Length(Buffer), nil));
  Result := WideFormat('Error %d'#13#10#13#10'%s', [GetLastError, Buffer]);
end;

function RemoveAmpersand(S: WideString): WideString;
var
  P: Integer;
begin
  repeat
    P := Pos('&', S);
    if P <> 0 then
      Delete(S, P, 1);
  until P = 0;
  Result := S;
end;

function StripCRLFToSpaces(S: WideString): WideString;
var
  I: Integer;
begin
  for I := 1 to Length(S) do
    if S[I] = WideChar(#13) then
    begin
      S[I] := ' ';
      S[I + 1] := ' ';
    end;
  Result := S;
end;

function IsDelphiIDERunning: Boolean;
begin
  Result := not ((FindWindow('TApplication', nil) = 0) or (FindWindow('TAlignPalette', nil) = 0) or (FindWindow('TPropertyInspector', nil) = 0) or (FindWindow('TAppBuilder', nil) = 0));
end;

function IsDelphiHost: Boolean;
begin
  Result := SameText(ExtractFileName(ParamStr(0)), 'delphi32.exe');
end;

procedure PostKey(Key: Word; const Shift: TShiftState; SpecialKey: Boolean);
type
  TShiftKeyInfo = record
    Shift: Byte;
    VKey: Byte;
  end;
  ByteSet = set of 0..7;
const
  ShiftKeys: array [1..3] of TShiftKeyInfo = (
    (Shift: Ord(ssCtrl);  VKey: VK_CONTROL),
    (Shift: Ord(ssShift); VKey: VK_SHIFT),
    (Shift: Ord(ssAlt);   VKey: VK_MENU));
var
  Flag: DWORD;
  bShift: ByteSet absolute shift;
  I: Integer;
begin
  for I := 1 to 3 do
    if ShiftKeys[i].Shift in bShift then
      keybd_event(ShiftKeys[I].VKey, MapVirtualKey(ShiftKeys[i].VKey, 0), 0, 0);

  if SpecialKey then
    Flag := KEYEVENTF_EXTENDEDKEY
  else
    Flag := 0;

  keybd_event(Key, MapVirtualKey(Key, 0), Flag, 0);
  Flag := Flag or KEYEVENTF_KEYUP;
  keybd_event(Key, MapVirtualKey(Key, 0), Flag, 0);

  for I := 3 downto 1 do
    if ShiftKeys[i].Shift in bShift then
      keybd_event(ShiftKeys[i].VKey, MapVirtualKey(ShiftKeys[i].VKey, 0), KEYEVENTF_KEYUP, 0);
end;

function UnifyPathSeparator(Path: String): String;
var
  I: Integer;
begin
  if PathDelim <> '/' then
    for I := 1 to Length(Path) do
      if Path[I] = '/' then
        Path[I] := PathDelim;
  Result := Path;
end;

function RandomString(Length: Integer): String;
var
  I: Integer;
begin
  SetLength(Result, Length);
  for I := 1 to Length do
  begin
    Result[I] := Chr(Random(Ord('z') - Ord('a')) + Ord('a'));
    if Random(2) = 1 then
      Result[I] := UpCase(Result[I]);
  end;
end;

function FileSize(FileName: String): Int64;
var
  F: TFileStream;
begin
  if FileExists(FileName) then
  begin
    F := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      try
        Result := F.Size;
      except
        Result := 0;
      end;
    finally
      F.Free;
    end;
  end
  else
    Result := 0;
end;

type
  PPROCESSENTRY32 = ^PROCESSENTRY32;
  tagPROCESSENTRY32 = record
    dwSize: DWORD;
    cntUsage: DWORD;
    th32ProcessID: DWORD;          // this process
    th32DefaultHeapID: Longword;
    th32ModuleID: DWORD;           // associated exe
    cntThreads: DWORD;
    th32ParentProcessID: DWORD;    // this process's parent process
    pcPriClassBase: Longint;          // Base priority of process's threads
    dwFlags: DWORD;
    szExeFile: array [0..MAX_PATH - 1] of Char;    // Path
  end;
  PROCESSENTRY32 = tagPROCESSENTRY32;
  TProcessEntry32 = PROCESSENTRY32;

const
  TH32CS_SNAPHEAPLIST = $00000001;
  TH32CS_SNAPPROCESS  = $00000002;
  TH32CS_SNAPTHREAD   = $00000004;
  TH32CS_SNAPMODULE   = $00000008;
  TH32CS_SNAPMODULE32 = $00000010;
  TH32CS_SNAPALL      = TH32CS_SNAPHEAPLIST or TH32CS_SNAPPROCESS or TH32CS_SNAPTHREAD or TH32CS_SNAPMODULE;
  TH32CS_INHERIT      = $80000000;

function CreateToolhelp32Snapshot(dwFlags, th32ProcessID: DWORD): THandle; stdcall; external 'kernel32.dll';
function Process32First(hSnapshot: THandle; var lppe: PROCESSENTRY32): BOOL; stdcall; external 'kernel32.dll';
function Process32Next(hSnapshot: THandle; var lppe: PROCESSENTRY32): BOOL; stdcall; external 'kernel32.dll';

function GetExeProcessId(ExeName: String): THandle;
var
  hProcessSnap: THandle;
  pe32: PROCESSENTRY32;
  Res : Boolean;
begin
  Result := INVALID_HANDLE_VALUE;

  hProcessSnap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if hProcessSnap <> 0 then
  begin
    ZeroMemory(@pe32, SizeOf(pe32));
    pe32.dwSize := SizeOf(pe32);
    Res := Process32First(hProcessSnap, pe32);
    while Res do
    begin
      if AnsiSameText(pe32.szExeFile, ExeName) then
      begin
        Result := pe32.th32ProcessID;
        Break;
      end
      else Res := Process32Next(hProcessSnap, pe32);
    end;

    CloseHandle(hProcessSnap);
  end;
end;

function AssignedEx(const P): Boolean;
begin
  Result := (Integer(P) > $000000FF) and System.Assigned(Pointer(P));
end;

function ByteToBin(B: Byte): String;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to 7 do
  begin
    if B and 1 <> 0 then Result := '1' + Result
    else Result := '0' + Result;
    B := B shr 1;
  end;
end;

function BinToByte(S: string): Int64;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to Length(S) do
  begin
    if S[I] = '1' then
      Result := Result or 1;
    if I < Length(S) then
      Result := Result shl 1;
  end;
end;

function IntToBin(V: Int64; L: Integer): String;
begin
  Result := '';
  while V > 0 do
  begin
    if V and 1 = 0 then
      Result := '0' + Result
    else
      Result := '1' + Result;
    V := V shr 1;
  end;
  while Length(Result) < L do
    Result := '0' + Result;
end;

function BinToInt(S: string): Int64;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to Length(S) do
  begin
    if S[I] = '1' then
      Result := Result or 1;
    if I < Length(S) then
      Result := Result shl 1;
  end;
end;


end.



