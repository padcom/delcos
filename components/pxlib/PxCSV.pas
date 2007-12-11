// ----------------------------------------------------------------------------
// Unit        : PxCSV.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        :
// Version     : 1.0
// Description : CSV (comma separated values) format utilities
// Changes log : 2005-02-24 - initial version
// ToDo        : Testing.
// ----------------------------------------------------------------------------

unit PxCSV;

{$I PxDefines.inc}

interface

uses
  SysUtils;

//
// Get a value of a specified column from CVS string (columns are 0-based)
//
function CSVGetData(S: String; Column: Integer; Separator: Char = ';'): String;

//
// Get a value of a specified column from CVS string (columns are 0-based)
//
function CSVGetDataInt(S: String; Column: Integer; Separator: Char = ';'): Integer;

//
// Get a value of a specified column from CVS string (columns are 0-based)
//
function CSVGetDataUInt(S: String; Column: Integer; Separator: Char = ';'): LongWord;

//
// Same as the function above, but returns Int64 values (columns are 0-based)
//
function CSVGetDataInt64(S: String; Column: Integer; Separator: Char = ';'): Int64;

//
// Set a value of a specified column in CVS string. (columns are 0-based)
// If the CSV string doesn't contain enough columns to store the data
// it will extend the source string so that the data can be stored.
//
function CSVSetData(S: String; Column: Integer; Value: String; Separator: Char = ';'): String;

//
// Gets count of columns in the CSV string
//
function CSVGetColumnCount(S: String; Separator: Char = ';'): Integer;

implementation

function CSVGetData(S: String; Column: Integer; Separator: Char = ';'): String;
var
  P, I: Integer;
begin
  // column translation
  Result := ''; P := 0;
  for I := 1 to Length(S) do
  begin
    if S[I] = Separator then
    begin
      Inc(P);
      if P = Column + 1 then Break;
    end
    else if P = Column then
      Result := Result + S[I];
  end;
end;

function CSVGetDataInt(S: String; Column: Integer; Separator: Char = ';'): Integer;
begin
  Result := StrToIntDef(CSVGetData(S, Column, Separator), 0);
end;

function CSVGetDataUInt(S: String; Column: Integer; Separator: Char = ';'): LongWord;
begin
  Result := LongWord(StrToIntDef(CSVGetData(S, Column, Separator), 0));
end;

function CSVGetDataInt64(S: String; Column: Integer; Separator: Char = ';'): Int64;
begin
  Result := StrToInt64Def(CSVGetData(S, Column, Separator), 0);
end;

function CSVSetData(S: String; Column: Integer; Value: String; Separator: Char = ';'): String;
var
  I, P, Index1, Index2: Integer;
begin
  if Column = 0 then Index1 := 1
  else Index1 := 0;
  Index2 := 0;

  // find first and last position in the source string
  // to inject the new value in
  P := 0;
  for I := 1 to Length(S) do
    if S[I] = Separator then
    begin
      Inc(P);
      if P = Column + 1 then
      begin
        Index2 := I;
        Break;
      end
      else Index1 := I;
    end;

  // check if there was enough columns to store the data in
  while P < Column do
  begin
    S := S + ';';
    Index1 := Length(S);
    Index2 := Length(S);
    Inc(P);
  end;

  // check wether it is the one and only column
  if (Index1 <> 0) and (Index2 = 0) then
    Index2 := Length(S);

  if S <> '' then
  begin
    // some checks..
    if (S[Index1] = ';') and (Column > 0) then Inc(Index1);
    if S[Index2] <> ';' then Inc(Index2);
    // inject the required value
    Delete(S, Index1, Index2 - Index1);
    Insert(Value, S, Index1);
  end
  else S := Value;

  Result := S;
end;

function CSVGetColumnCount(S: String; Separator: Char = ';'): Integer;
var
  I: Integer;
begin
  if S = '' then
    Result := 0
  else
  begin
    Result := 1;
    for I := 1 to Length(S) do
      if S[I] = Separator then Inc(Result);
  end;
end;

end.
