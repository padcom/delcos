// ----------------------------------------------------------------------------
// Unit        : PxCrt32.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 
// Version     : 1.0
// Description : Utilities for console handling (previously found in the
//               Crt.pas in Borland Pascal).
// Changes log : 2004-12-xx - initial version
//               2005-05-03 - compatibility issues with freepascal solved.
// ToDo        : Testing, comments in code.
// ----------------------------------------------------------------------------
  
unit PxCrt32;

{$I PxDefines.inc}

interface

uses 
  Windows, Messages, SysUtils;

{$IFDEF WIN32}
const
  Black        = 0;
  Blue         = 1;
  Green        = 2;
  Cyan         = 3;
  Red          = 4;
  Magenta      = 5;
  Brown        = 6;
  LightGray    = 7;
  DarkGray     = 8;
  LightBlue    = 9;
  LightGreen   = 10;
  LightCyan    = 11;
  LightRed     = 12;
  LightMagenta = 13;
  Yellow       = 14;
  White        = 15;

function WhereX: Integer;
function WhereY: Integer;
procedure ClrEol;
procedure ClrScr;
procedure InsLine;
procedure DelLine;
procedure GotoXY(const X, Y: Integer);
procedure HighVideo;
procedure LowVideo;
procedure NormVideo;
procedure TextBackground(const Color: Word);
procedure TextColor(const Color: Word);
procedure TextAttribut(const Color, Background: Word);
procedure Delay(const Miliseconds: Integer);
function KeyPressed: Boolean;
function ReadKey: Char;
procedure Sound;
procedure NoSound;
procedure ConsoleEnd;
procedure FlushInputBuffer;
function Pipe: Boolean;

var
  hConsoleInput : THandle;
  hConsoleOutput: THandle;
  hConsoleError : THandle;
  WindMin       : TCoord;
  WindMax       : TCoord;
  ViewMax       : TCoord;
  TextAttr      : Word;
  LastMode      : Word;
  SoundFrequenz : Integer;
  SoundDuration : Integer;

{$ENDIF WIN32}

implementation

{$IFDEF WIN32}
var
  StartAttr: Word;
  OldCP    : Integer;
  CrtPipe  : Boolean;
  German   : Boolean;
           
procedure ClrEol;
var 
  Coords: TCoord;
  Len, NW: LongWord;
  CBI: TConsoleScreenBufferInfo;
begin
  GetConsoleScreenBufferInfo(hConsoleOutput, CBI);
  Len := CBI.dwsize.X - CBI.dwCursorPosition.X;
  Coords.X := CBI.dwCursorPosition.X;
  Coords.Y := CBI.dwCursorPosition.Y;
  FillConsoleOutputAttribute(hConsoleOutput, TextAttr,len, Coords, NW);
  FillConsoleOutputCharacter(hConsoleOutput, #32, len, Coords, NW);
end;

procedure ClrScr;
var 
  Coords: TCoord;
  NW: LongWord;
  CBI: TConsoleScreenBufferInfo;
begin
  GetConsoleScreenBufferInfo(hConsoleOutput, CBI);
  Coords.X := 0;
  Coords.Y := 0;
  FillConsoleOutputAttribute(hConsoleOutput, TextAttr, CBI.dwsize.X * CBI.dwsize.Y, Coords, NW);
  FillConsoleOutputCharacter(hConsoleOutput,#32, CBI.dwsize.X * CBI.dwsize.Y, Coords, NW);
  SetConsoleCursorPosition(hConsoleOutput, Coords);
end;

function WhereX: Integer;
var 
  CBI: TConsoleScreenBufferInfo;
begin
  GetConsoleScreenBufferInfo(hConsoleOutput, CBI);
  Result := TCoord(CBI.dwCursorPosition).X + 1
end;

function WhereY: Integer;
var 
  CBI: TConsoleScreenBufferInfo;
begin
  GetConsoleScreenBufferInfo(hConsoleOutput, CBI);
  Result := TCoord(CBI.dwCursorPosition).Y + 1
end;

procedure GotoXY(const X, Y: Integer);
var 
  Coord: TCoord;
begin
  Coord.X := X - 1;
  Coord.X := Y - 1;
  setConsoleCursorPosition(hConsoleOutput, Coord);
end;

procedure InsLine;
var
  CBI: TConsoleScreenBufferInfo;
  SSR: TSmallRect;
  {$IFDEF FPC}
  SCR: TSmallRect;
  {$ENDIF}
  Coord: TCoord;
  CI: TCharInfo;
  NW: LongWord;
begin
  GetConsoleScreenBufferInfo(hConsoleOutput, CBI);
  Coord := CBI.dwCursorPosition;
  SSR.Left := 0;
  SSR.Top := Coord.Y;
  SSR.Right := CBI.srWindow.Right;
  SSR.Bottom := CBI.srWindow.Bottom;
  CI.AsciiChar := #32;
  CI.Attributes := CBI.wAttributes;
  Coord.X := 0;
  Coord.Y := Coord.Y + 1;
{$IFDEF FPC}  
  FillChar(SCR, SizeOf(SCR), 0);
  ScrollConsoleScreenBuffer(hConsoleOutput, SSR, SCR, Coord, CI);
{$ENDIF}
{$IFDEF DELPHI}
  ScrollConsoleScreenBuffer(hConsoleOutput, SSR, nil, Coord, CI);
{$ENDIF}
  Coord.Y := Coord.Y-1;
  FillConsoleOutputAttribute(hConsoleOutput, TextAttr, CBI.dwsize.X * CBI.dwsize.Y, Coord, NW);
end;

procedure DelLine;
var
  CBI: TConsoleScreenBufferInfo;
  SSR: TSmallRect;
  {$IFDEF FPC}
  SCR: TSmallRect;
  {$ENDIF}
  Coord: TCoord;
  CI: TCharInfo;
  NW: LongWord;
begin
  GetConsoleScreenBufferInfo(hConsoleOutput, CBI);
  Coord := CBI.dwCursorPosition;
  SSR.Left := 0;
  SSR.Top := Coord.Y + 1;
  SSR.Right := CBI.srWindow.Right;
  SSR.Bottom := CBI.srWindow.Bottom;
  CI.AsciiChar := #32;
  CI.Attributes := CBI.wAttributes;
  Coord.X := 0;
  Coord.Y := Coord.Y;
  {$IFDEF FPC}
  FillChar(SCR, SizeOf(SCR), 0);
  ScrollConsoleScreenBuffer(hConsoleOutput, SSR, SCR, Coord, CI);
  {$ENDIF}
  {$IFDEF DELPHI}
  ScrollConsoleScreenBuffer(hConsoleOutput, SSR, nil, Coord, CI);
  {$ENDIF}
  FillConsoleOutputAttribute(hConsoleOutput, TextAttr, CBI.dwsize.X * CBI.dwsize.Y, Coord, NW);
end;

procedure TextBackground(const Color: Word);
begin
  LastMode := TextAttr;
  TextAttr := (Color shl $04) or (TextAttr and $0F);
  SetConsoleTextAttribute(hConsoleOutput, TextAttr);
end;

procedure TextColor(const Color: Word);
begin
  LastMode := TextAttr;
  TextAttr := (Color and $0F) or (TextAttr and $F0);
  SetConsoleTextAttribute(hConsoleOutput, TextAttr);
end;

procedure TextAttribut(const Color, Background: Word);
begin
  LastMode := TextAttr;
  TextAttr := (Color and $0F) or (Background shl $04);
  SetConsoleTextAttribute(hConsoleOutput, TextAttr);
end;

procedure HighVideo;
begin
  LastMode := TextAttr;
  TextAttr := TextAttr or $08;
  SetConsoleTextAttribute(hConsoleOutput, TextAttr);
end;

procedure LowVideo;
begin
  LastMode := TextAttr;
  TextAttr := TextAttr and $F7;
  SetConsoleTextAttribute(hConsoleOutput, TextAttr);
end;

procedure NormVideo;
begin
  LastMode := TextAttr;
  TextAttr := StartAttr;
  SetConsoleTextAttribute(hConsoleOutput, TextAttr);
end;

procedure FlushInputBuffer;
begin
  FlushConsoleInputBuffer(hConsoleInput)
end;

function KeyPressed: Boolean;
var 
  NumberOfEvents: LongWord;
begin
  GetNumberOfConsoleInputEvents(hConsoleInput, NumberOfEvents);
  Result := NumberOfEvents > 0;
end;

function ReadKey: Char;
var
  NumRead: LongWord;
  InputRec: TInputRecord;
begin
  while not ReadConsoleInput(hConsoleInput, InputRec, 1, NumRead) or (InputRec.EventType <> KEY_EVENT) do;
{$IFDEF FPC}
  Result := InputRec.Event.KeyEvent.AsciiChar;
{$ENDIF}
{$IFDEF DELPHI}
  Result := InputRec.KeyEvent.AsciiChar;
{$ENDIF}
end;

procedure Delay(const Miliseconds: Integer);
begin
  Sleep(Miliseconds);
end;

procedure Sound;
begin
  Windows.Beep(SoundFrequenz, SoundDuration);
end;

procedure NoSound;
begin
  Windows.Beep(SoundFrequenz, 0);
end;

procedure ConsoleEnd;
begin
  if IsConsole and not CrtPipe then
  begin
    if WhereX > 1 then Writeln;
    TextColor(Green);
    SetFocus(GetCurrentProcess);
    Write('Press any key!');
    NormVideo;
    FlushInputBuffer;
    ReadKey;
    FlushInputBuffer;
  end;
end;

function Pipe: Boolean;
begin
  Result := CrtPipe;
end;

procedure Init;
var
  CBI: TConsoleScreenBufferInfo;
  Coords : TCoord;
begin
  SetActiveWindow(0);
  hConsoleInput := GetStdHandle(STD_INPUT_HANDLE);
  hConsoleOutput := GetStdHandle(STD_OUTPUT_HANDLE);
  hConsoleError := GetStdHandle(STD_ERROR_HANDLE);
  if GetConsoleScreenBufferInfo(hConsoleOutput, CBI) then
  begin
    TextAttr := CBI.wAttributes;
    StartAttr := CBI.wAttributes;
    lastmode := CBI.wAttributes;
    Coords.X := CBI.srWindow.Left + 1;
    Coords.Y := CBI.srWindow.Top + 1;
    WindMin := Coords;
    ViewMax := CBI.dwsize;
    Coords.X := CBI.srWindow.Right + 1;
    Coords.Y := CBI.srWindow.Bottom + 1;
    WindMax := Coords;
    crtpipe := False;
  end 
  else CrtPipe := True;
  SoundFrequenz := 1000;
  SoundDuration := -1;
  OldCP := GetConsoleOutputCP;
  SetConsoleOutputCP(1252);
  German := $07 = (LoWord(GetUserDefaultLangID) and $03FF);
end;

initialization
  Init;
  
finalization
  SetConsoleoutputCP(OldCP);
 
{$ENDIF WIN32}

end.
