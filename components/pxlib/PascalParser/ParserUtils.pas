unit ParserUtils;

interface

uses
  Windows;

type
  TParserUtils = class (TObject)
    class function GetCharType(const C: Char): Word;
    class function CharIsAlpha(const C: Char): Boolean;
    class function StrIsAlpha(const S: string): Boolean;
    class function CharIsAlphaNum(const C: Char): Boolean;
    class function StrIsAlphaNum(const S: string): Boolean;
    class function CharIsReturn(const C: Char): Boolean;
    class function CharIsDigit(const C: Char): Boolean;
    class function CharIsWhiteSpace(const C: Char): Boolean;
    class function CharIsControl(const C: Char): Boolean;
    class function StrLeft(const S: string; Count: Integer): string;
    class function StrRight(const S: string; Count: Integer): string;
    class function StrRestOf(const S: string; N: Integer): string;
    class function StrChopRight(const S: string; N: Integer): string;
    class function StrRepeat(const S: string; Count: Integer): string;
  end;

implementation

class function TParserUtils.GetCharType(const C: Char): Word;
begin
  GetStringTypeExA(LOCALE_USER_DEFAULT, CT_CTYPE1, @C, SizeOf(Char), Result);
end;

class function TParserUtils.CharIsAlpha(const C: Char): Boolean;
begin
  Result := (GetCharType(C) and C1_ALPHA) <> 0;
end;

class function TParserUtils.StrIsAlpha(const S: string): Boolean;
var
  I: Integer;
begin
  Result := S <> '';
  for I := 1 to Length(S) do
  begin
    if not CharIsAlpha(S[I]) then
    begin
      Result := False;
      Exit;
    end;
  end;
end;

class function TParserUtils.CharIsAlphaNum(const C: Char): Boolean;
var
  CharType: Word;
begin
  CharType := GetCharType(C);
  Result := ((CharType and C1_ALPHA) <> 0) or ((CharType and C1_DIGIT) <> 0);
end;

class function TParserUtils.StrIsAlphaNum(const S: string): Boolean;
var
  I: Integer;
begin
  Result := S <> '';
  for I := 1 to Length(S) do
  begin
    if not CharIsAlphaNum(S[I]) then
    begin
      Result := False;
      Exit;
    end;
  end;
end;

class function TParserUtils.CharIsReturn(const C: Char): Boolean;
begin
  Result := C in [#13,#10];
end;

class function TParserUtils.CharIsDigit(const C: Char): Boolean;
begin
  Result := (GetCharType(C) and C1_DIGIT) <> 0;
end;

class function TParserUtils.CharIsWhiteSpace(const C: Char): Boolean;
begin
  Result := C in [#9, #10, #11, #12, #13, ' '];
end;

class function TParserUtils.CharIsControl(const C: Char): Boolean;
begin
  Result := (GetCharType(C) and C1_CNTRL) <> 0;
end;

class function TParserUtils.StrLeft(const S: string; Count: Integer): string;
begin
  Result := Copy(S, 1, Count);
end;

class function TParserUtils.StrRight(const S: string; Count: Integer): string;
begin
  Result := Copy(S, Length(S) - Count + 1, Count);
end;

class function TParserUtils.StrRestOf(const S: string; N: Integer ): string;
begin
  Result := Copy(S, N, (Length(S) - N + 1));
end;

class function TParserUtils.StrChopRight(const S: string; N: Integer): string;
begin
  Result := Copy(S, 1, Length(S) - N);
end;

class function TParserUtils.StrRepeat(const S: string; Count: Integer): string;
var
  Len, Index: Integer;
  Dest, Source: PChar;
begin
  Len := Length(S);
  SetLength(Result, Count * Len);
  Dest := PChar(Result);
  Source := PChar(S);
  if Dest <> nil then
    for Index := 0 to Count - 1 do
  begin
    Move(Source^, Dest^, Len*SizeOf(Char));
    Inc(Dest,Len*SizeOf(Char));
  end;
end;

end.
