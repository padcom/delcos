unit SourceTokenList;

{ AFS 24 Dec 2002
  A list of source tokens
  This is needed after the text has been turned into tokens
  until it is turned into a parse tree

  The way that this class works has a big impact on JCF run speed
  So it is implemented in a more low-level way to most
  it is a subclass not a wrap of TObjectList

  It is populated, then tokens are read out.
  This is done not by removing items from the start of the list (slow)
  but by keeping the idnex of the current item,
  and advancing it when items are extracted
}

{(*}
(*------------------------------------------------------------------------------
 Delphi Code formatter source code

The Original Code is SourceTokenList, released May 2003.
The Initial Developer of the Original Code is Anthony Steele.
Portions created by Anthony Steele are Copyright (C) 1999-2000 Anthony Steele.
All Rights Reserved.
Contributor(s): Anthony Steele, Adem Baba

The contents of this file are subject to the Mozilla Public License Version 1.1
(the "License"). you may not use this file except in compliance with the License.
You may obtain a copy of the License at http://www.mozilla.org/NPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied.
See the License for the specific language governing rights and limitations
under the License.
------------------------------------------------------------------------------*)
{*)}

interface

uses
  { delphi }
  Classes, SysUtils, Contnrs, 
  { local }
  SourceToken,
  Tokens;

type
  { inherit not encapsulate, for speed }
  TSourceTokenList = class(TObjectList)
  Private
    { This is to keep an index of the next non-nil item
      when reading items out of the list
      List.Extract is a bit slow }
    fiCurrentTokenIndex: integer;

    function GetItem(const piIndex: integer): TSourceToken;
    procedure SetItem(const piIndex: integer; const pcObject: TSourceToken);
  Public
    constructor Create;
    destructor Destroy; override;

    procedure Clear; override;

    function Add(const pcToken: TSourceToken): integer;
    procedure SetXYPositions;
    procedure Insert(const piIndex: integer; const pcItem: TSourceToken);
    function Extract: TSourceToken;
    function EOF: boolean;
    procedure Delete(const piIndex: integer);

    { not relative to current token index }
    property SourceTokens[const piIndex: integer]: TSourceToken Read GetItem Write SetItem;

    {This is to keep an index of the next non-nil item}
    property CurrentTokenIndex: integer Read fiCurrentTokenIndex;

    {----------------------------------------------------
     the following are all relative to the Current Token Index
      e.g. "First" is the token at the current pos }
    function First: TSourceToken;
    function FirstTokenType: TTokenType;
    function FirstWordType: TWordType;
    function FirstTokenLength: integer;

    function FirstSolidToken: TSourceToken;
    function FirstSolidTokenType: TTokenType;
    function FirstSolidTokenLength: integer;

    function FirstSolidWordType: TWordType;
    function FirstTokenWithExclusion(const AExclusions: TTokenTypeSet): TSourceToken;

    function SolidToken(piIndex: integer): TSourceToken;
    function SolidTokenType(const piIndex: integer): TTokenType;
    function SolidWordType(const piIndex: integer): TWordType;
  end;

implementation

constructor TSourceTokenList.Create;
begin
  fiCurrentTokenIndex := 0;
  OwnsObjects := True;
  inherited Create(False);
end;

destructor TSourceTokenList.Destroy;
begin
  inherited Destroy;
end;

procedure TSourceTokenList.Clear;
begin
  inherited Clear;
  fiCurrentTokenIndex := 0;
end;

function TSourceTokenList.GetItem(const piIndex: integer): TSourceToken;
begin
  Result := TSourceToken(List^[piIndex]);
end;

procedure TSourceTokenList.SetItem(const piIndex: integer; const pcObject: TSourceToken);
begin
  inherited SetItem(piIndex, pcObject);
end;

function TSourceTokenList.First: TSourceToken;
begin
  Result := TSourceToken(List^[fiCurrentTokenIndex]);
end;

function TSourceTokenList.FirstTokenType: TTokenType;
begin
  Result := ttUnknown;
  if Count > 0 then
    Result := TSourceToken(List^[fiCurrentTokenIndex]).TokenType;
end;

function TSourceTokenList.FirstWordType: TWordType;
begin
  Result := wtNotAWord;
  if Count > 0 then
    Result := TSourceToken(List^[fiCurrentTokenIndex]).WordType;
end;

function TSourceTokenList.FirstTokenLength: integer;
var
  lc: TSourceToken;
begin
  Result := 0;
  lc     := First;
  if lc <> nil then
    Result := Length(lc.SourceCode);
end;

function TSourceTokenList.FirstSolidTokenType: TTokenType;
var
  lc: TSourceToken;
begin
  Result := ttUnknown;
  lc     := FirstSolidToken;
  if lc <> nil then
    Result := lc.TokenType;
end;

function TSourceTokenList.FirstSolidTokenLength: integer;
var
  lc: TSourceToken;
begin
  Result := 0;
  lc     := FirstSolidToken;
  if lc <> nil then
    Result := Length(lc.SourceCode);
end;

function TSourceTokenList.FirstSolidWordType: TWordType;
var
  lc: TSourceToken;
begin
  Result := wtNotAWord;
  lc     := FirstSolidToken;
  if lc <> nil then
    Result := lc.WordType;
end;

function TSourceTokenList.FirstTokenWithExclusion(
  const AExclusions: TTokenTypeSet): TSourceToken;
var
  liLoop: integer;
  lcItem: TSourceToken;
begin
  Result := nil;
  liLoop := fiCurrentTokenIndex;
  while liLoop < Count do
  begin
    lcItem := TSourceToken(List^[liLoop]);
    if not (lcItem.TokenType in AExclusions) then
    begin
      Result := lcItem;
      break;
    end;
    Inc(liLoop);
  end;
end;

function TSourceTokenList.Add(const pcToken: TSourceToken): integer;
begin
  Result := inherited Add(pcToken);
end;

function TSourceTokenList.FirstSolidToken: TSourceToken;
begin
  Result := SolidToken(1);
end;

function TSourceTokenList.SolidToken(piIndex: integer): TSourceToken;
var
  liLoop:      integer;
  lcTestToken: TSourceToken;
begin
  Assert(piIndex > 0);
  Result := nil;
  liLoop := fiCurrentTokenIndex;

  while liLoop < Count do
  begin
    lcTestToken := TSourceToken(List^[liLoop]);
    if (lcTestToken <> nil) and lcTestToken.IsSolid then
    begin
      // found a solid token.
      if piIndex > 1 then
        Dec(piIndex) // go further
      else
      begin
        // found it
        Result := lcTestToken;
        break;
      end;
    end;
    Inc(liLoop);
  end;
end;

function TSourceTokenList.SolidTokenType(const piIndex: integer): TTokenType;
var
  lc: TSourceToken;
begin
  Result := ttUnknown;
  lc     := SolidToken(piIndex);
  if lc <> nil then
    Result := lc.TokenType;
end;

function TSourceTokenList.SolidWordType(const piIndex: integer): TWordType;
var
  lc: TSourceToken;
begin
  Result := wtNotAWord;
  lc     := SolidToken(piIndex);
  if lc <> nil then
    Result := lc.WordType;
end;

procedure PosLastAndCount(const ASubString, AString: ansistring;
  var ALastPos: integer; var ACount: integer);
var
  {This gets the last occurance and count in one go. It saves time}
  LastCahr1: char;
  Index1:    integer;
  Index2:    integer;
  Index3:    integer;
  Length1:   integer;
  Length2:   integer;
  Found1:    boolean;
begin
  ACount   := 0;
  ALastPos := 0;
  Length1  := Length(AString);
  Length2  := Length(ASubString);
  if Length2 > Length1 then
    Exit
  else
  begin
    LastCahr1 := ASubString[Length2];
    Index1    := Length1;
    while Index1 > 0 do
    begin
      if (AString[Index1] = LastCahr1) then
      begin
        Index2 := Index1;
        Index3 := Length2;
        Found1 := Index2 >= Length2;
        while Found1 and (Index2 > 0) and (Index3 > 0) do
        begin
          Found1 := (AString[Index2] = ASubString[Index3]);
          Dec(Index2);
          Dec(Index3);
        end;
        if Found1 then
        begin
          if ALastPos = 0 then
            ALastPos := Index2 + 1;
          Inc(ACount);
          Index1 := Index2;
          Continue;
        end;
      end;
      Dec(Index1);
    end;
  end;
end;

{ given an existing source pos, and a text string that adds at that pos,
  calculate the new text pos
  - if the text does not contain a newline, add its length onto the Xpos
  - if the text contains newlines, then add on to the Y pos, and
    set the X pos to the text length after the last newline }
{AdemBaba}
procedure AdvanceTextPos(const AText: string; var ARow, ACol: integer);
var
  Length1: integer;
  Count1:  integer;
  Pos1:    integer;
begin
  {This is more than 3 times faster than the original.
  I have meticilously checked that it conforms with the original}
  Length1 := Length(AText);
  case Length1 of
    0: ; {Trivial case}
    1:
    begin
      case AText[1] of
        #13, #10:
        begin {#13 or #10}
          Inc(ACol);
          ARow := 1; // XPos is indexed from 1
        end;
        else
          Inc(ARow, Length1)
      end;
    end;
    2:
    begin
      if (AText[1] = #13) and (AText[2] = #10) then
      begin
        Inc(ACol);
        ARow := 1; // XPos is indexed from 1
      end
      else
        Inc(ARow, Length1);
    end;
    else
      PosLastAndCount(#13#10, AText, Pos1, Count1);
      if Pos1 <= 0 then
        Inc(ARow, Length1)
      else
      begin // multiline
        Inc(ACol, Count1);
        ARow := Length1 - (Pos1 + 1); {2 = Length(AnsiLineBreak)}

        if ARow < 1 then
          ARow := 1;
      end;
  end;
end;

procedure TSourceTokenList.SetXYPositions;
var
  liLoop:   integer;
  liX, liY: integer;
  lcToken:  TSourceToken;
begin
  liX    := 1;
  liY    := 1;
  liLoop := fiCurrentTokenIndex;
  while liLoop < Count do
  begin
    lcToken := TSourceToken(List^[liLoop]);
    lcToken.XPosition := liX;
    lcToken.YPosition := liY;
    AdvanceTextPos(lcToken.SourceCode, liX, liY);
    Inc(liLoop);
  end;
end;

function TSourceTokenList.Extract: TSourceToken;
begin
  { remove the current item and advance to the next item

    Here I am not doing any index checking at all.
    This thing needs to be FAST. Access to here is quite controlled anyway.}
  Result := TSourceToken(List^[fiCurrentTokenIndex]);
  List^[fiCurrentTokenIndex] := nil;

  inc(fiCurrentTokenIndex);
end;

function TSourceTokenList.EOF: boolean;
begin
  Result := fiCurrentTokenIndex >= Count;
end;

procedure TSourceTokenList.Insert(const piIndex: integer; const pcItem: TSourceToken);
begin
  if fiCurrentTokenIndex <> 0 then
    raise Exception.Create('Insert Not allowed in Stack mode');

  inherited Insert(piIndex, pcItem);
end;

procedure TSourceTokenList.Delete(const piIndex: integer);
begin
  if fiCurrentTokenIndex <> 0 then
    raise Exception.Create('Delete Not allowed in Stack mode');

  inherited Delete(piIndex);
end;

end.
