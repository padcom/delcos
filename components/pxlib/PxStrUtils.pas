// ----------------------------------------------------------------------------
// Unit        : PxStrUtils.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2004-10-27
// Version     : 1.0
// Description ; String utilities
// Changes log ; 2004-10-27 - Initial version
// ToDo        : Testing.
// ----------------------------------------------------------------------------

unit PxStrUtils;

{$I PxDefines.inc}

interface

uses
  Classes, SysUtils, PxBase, PxResources;

type
  //
  // Unicode-enabled list of strings
  //
  TWideStrings = class
  private
    FWideStringList: TList;
    function Get(Index: Integer): WideString;
    procedure Put(Index: Integer; const S: WideString);
  public
    constructor Create;
    destructor Destroy; override;
    function  Count: Integer;
    procedure Clear;
    function Add(const S: WideString): Integer;
    function IndexOf(const S: WideString): Integer;
    function IndexOfIgnoreCase(const S: WideString): Integer;
    procedure Insert(Index: Integer; const S: WideString);
    property Strings[Index: Integer]: WideString read Get write Put; default;
  end;

// Create an escape (\letter) string
function EscapeString(S: String): String;
// Decode an escaped (\letter-encoded) string
function UnEscapeString(S: String): String;
// Replace all occurences of one string with another string in a given string
// Warning! Replaced text cannot contain the same text as the string to replace
function ReplaceStr(S: String; ToFind, ToReplace: String): String;
function ReplaceStrW(S: WideString; ToFind, ToReplace: WideString): WideString;

implementation

{ TWideStrings }

type
  // TWideStrings elements
  TWString = record
    WString: WideString;
  end;

{ Private declarations }

function TWideStrings.Get(Index: Integer): WideString;
var
  PWStr: ^TWString;
begin
  Result := '';
  if ( (Index >= 0) and (Index < FWideStringList.Count) ) then
  begin
    PWStr := FWideStringList.Items[Index];
    if PWStr <> nil then
      Result := PWStr^.WString;
  end;
end;

procedure TWideStrings.Put(Index: Integer; const S: WideString);
begin
  Insert(Index,S);
end;

{ Public declarations }

constructor TWideStrings.Create;
begin
  FWideStringList := TList.Create;
end;

destructor TWideStrings.Destroy;
var
  Index: Integer;
  PWStr: ^TWString;
begin
  { TODO - BB Investigate : Could call Clear here }
  for Index := 0 to FWideStringList.Count-1 do
  begin
    PWStr := FWideStringList.Items[Index];
    if PWStr <> nil then
      Dispose(PWStr);
  end;
  FWideStringList.Free;
  inherited Destroy;
end;

function TWideStrings.Add(const S: WideString): Integer;
var
  PWStr: ^TWString;
begin
  New(PWStr);
  PWStr^.WString := S;
  Result := FWideStringList.Add(PWStr);
end;

function TWideStrings.IndexOfIgnoreCase(const S: WideString): Integer;
var
  Index: Integer;
  PWStr: ^TWString;
begin
  Result := -1;
  for Index := 0 to FWideStringList.Count -1 do
  begin
    PWStr := FWideStringList.Items[Index];
    if PWStr <> nil then
    begin
      if SameText(S, PWStr^.WString) then
      begin
        Result := Index;
        break;
      end;
    end;
  end;
end;

function TWideStrings.IndexOf(const S: WideString): Integer;
var
  Index: Integer;
  PWStr: ^TWString;
begin
  Result := -1;
  for Index := 0 to FWideStringList.Count -1 do
  begin
    PWStr := FWideStringList.Items[Index];
    if PWStr <> nil then
    begin
      if S = PWStr^.WString then
      begin
        Result := Index;
        break;
      end;
    end;
  end;
end;

function TWideStrings.Count: Integer;
begin
  Result := FWideStringList.Count;
end;

procedure TWideStrings.Clear;
var
  Index: Integer;
  PWStr: ^TWString;
begin
  for Index := 0 to FWideStringList.Count-1 do
  begin
    PWStr := FWideStringList.Items[Index];
    if PWStr <> nil then
      Dispose(PWStr);
  end;
  FWideStringList.Clear;
end;

procedure TWideStrings.Insert(Index: Integer; const S: WideString);
var
  PWStr: ^TWString;
begin
  if((Index < 0) or (Index > FWideStringList.Count)) then
    raise Exception.Create(SWideStringOutofBounds);
  if Index < FWideStringList.Count then
  begin
    PWStr := FWideStringList.Items[Index];
    if PWStr <> nil then
      PWStr.WString := S;
  end
  else
    Add(S);
end;

{ *** }

function EscapeString(S: String): String;
var
  P: Integer;
begin
  Result := S;
  // new line encoding
  repeat
    P := Pos(#13#10, Result);
    if P <> 0 then
    begin
      Result[P] := '\';
      Result[P + 1] := 'n';
    end;
  until P = 0;
end;

function UnEscapeString(S: String): String;
var
  P: Integer;
begin
  Result := S;
  // new line encoding
  repeat
    P := Pos('\n', Result);
    if P <> 0 then
    begin
      Result[P] := #13;
      Result[P + 1] := #10;
    end;
  until P = 0;
end;

function ReplaceStr(S: String; ToFind, ToReplace: String): String;
var
  P: Integer;
begin
  repeat
    P := Pos(ToFind, S);
    if P > 0 then
    begin
      Delete(S, P, Length(ToFind));
      Insert(ToReplace, S, P);
    end;
  until P = 0;

  Result := S;
end;

function ReplaceStrW(S: WideString; ToFind, ToReplace: WideString): WideString;
var
  P: Integer;
begin
  repeat
    P := Pos(ToFind, S);
    if P > 0 then
    begin
      Delete(S, P, Length(ToFind));
      Insert(ToReplace, S, P);
    end;
  until P = 0;

  Result := S;
end;

end.
