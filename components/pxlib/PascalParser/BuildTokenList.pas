{(*}
(*------------------------------------------------------------------------------
 Delphi Code formatter source code 

The Original Code is BuildTokenList.pas, released April 2000.
The Initial Developer of the Original Code is Anthony Steele. 
Portions created by Anthony Steele are Copyright (C) 1999-2004 Anthony Steele.
All Rights Reserved. 
Contributor(s): Anthony Steele. 

The contents of this file are subject to the Mozilla Public License Version 1.1
(the "License"). you may not use this file except in compliance with the License.
You may obtain a copy of the License at http://www.mozilla.org/NPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied.
See the License for the specific language governing rights and limitations 
under the License.
------------------------------------------------------------------------------*)
{*)}

unit BuildTokenList;

{ AFS 29 Nov 1999
 converts the input string of chars into a list of tokens
 This is the lexical analysis phase of the parsing
}

interface

uses
  { delphi }
  Windows, Forms, SysUtils,
  { local }
  Tokens, SourceToken, SourceTokenList;

type

  TBuildTokenList = class(TObject)
  private
    { property implementation }
    fsSourceCode: string;

    { woker procs }
    fiCurrentIndex: integer;

    procedure SetSourceCode(const Value: string);

    function Current: char;
    function CurrentChars(const piCount: integer): string;
    function ForwardChar(const piOffset: integer): char;
    function ForwardChars(const piOffset, piCount: integer): string;
    function Consume(const piCount: integer = 1): string;
    function EndOfFile: boolean;
    function EndOfFileAfter(const piChars: integer): boolean;

      { implementation of GetNextToken }
    function TryReturn(const pcToken: TSourceToken): boolean;

    function TryCurlyComment(const pcToken: TSourceToken): boolean;
    function TrySlashComment(const pcToken: TSourceToken): boolean;
    function TryBracketStarComment(const pcToken: TSourceToken): boolean;

    function TryWhiteSpace(const pcToken: TSourceToken): boolean;
    function TryLiteralString(const pcToken: TSourceToken;
      const pcDelimiter: char): boolean;

    function TryNumber(const pcToken: TSourceToken): boolean;
    function TryHexNumber(const pcToken: TSourceToken): boolean;

    function TryDots(const pcToken: TSourceToken): boolean;

    function TryAssign(const pcToken: TSourceToken): boolean;

    function TrySingleCharToken(const pcToken: TSourceToken): boolean;

    function TryPunctuation(const pcToken: TSourceToken): boolean;
    function TryWord(const pcToken: TSourceToken): boolean;

    function GetNextToken: TSourceToken;

  protected

  public
    constructor Create;
    destructor Destroy; override;

    function BuildTokenList: TSourceTokenList;

    property SourceCode: string read fsSourceCode write SetSourceCode;
  end;


implementation

uses
  ParserUtils;

const
  codepage_Chinese = 950;

function CheckMultiByte(const pcChar: char): Boolean;
begin
  Result := IsDBCSLeadByte(Byte(pcChar));
end;

{ TBuildTokenList }

constructor TBuildTokenList.Create;
begin
  inherited;
  SourceCode := '';
end;

destructor TBuildTokenList.Destroy;
begin
  inherited;
end;

procedure TBuildTokenList.SetSourceCode(const Value: string);
begin
  fsSourceCode := Value;
  // reset the index 
  fiCurrentIndex := 1;
end;

function TBuildTokenList.GetNextToken: TSourceToken;
var
  lcNewToken: TSourceToken;

  procedure DoAllTheTries;
  begin
    { first look for return }
    if TryReturn(lcNewToken) then
      exit;
    { comments }
    if TryCurlyComment(lcNewToken) then
      exit;
    if TrySlashComment(lcNewToken) then
      exit;
    if TryBracketStarComment(lcNewToken) then
      exit;
    { the rest }
    if TryWhiteSpace(lcNewToken) then
      exit;
    if TryLiteralString(lcNewToken, '''') then
      exit;
    if TryLiteralString(lcNewToken, '"') then
      exit;

    if TryWord(lcNewToken) then
      exit;
    if TryNumber(lcNewToken) then
      exit;
    if TryHexNumber(lcNewToken) then
      exit;

    if TryDots(lcNewToken) then
      exit;

    { attempt assign before colon }
    if TryAssign(lcNewToken) then
      exit;

    if TryPunctuation(lcNewToken) then
      exit;

    if TrySingleCharToken(lcNewToken) then
      exit;

    { default }
    lcNewToken.TokenType  := ttUnknown;
    lcNewToken.SourceCode := Current;
    Consume(1);
  end;

begin
  if EndOfFile then
    Result := nil
  else
  begin
    lcNewToken := TSourceToken.Create;
    DoAllTheTries;

    lcNewToken.WordType := WordTypeOfToken(lcNewToken.TokenType);
    Result := lcNewToken;
  end;
end;

{-------------------------------------------------------------------------------
  worker fns for GetNextComment }

function TBuildTokenList.TryBracketStarComment(const pcToken: TSourceToken): boolean;
var
  liCommentLength: integer;

  procedure MoveToCommentEnd;
  begin
    { comment is ended by *) or by EOF (bad source) }
    while True do
    begin
      if EndOfFileAfter(liCommentLength) then
        break;

      if CheckMultiByte(ForwardChar(liCommentLength)) then
      begin
        liCommentLength := liCommentLength + 2;
        continue;
      end;

      if ForwardChars(liCommentLength, 2) = '*)' then
        break;

      inc(liCommentLength);
    end;

    // include the comment end
    if not EndOfFileAfter(liCommentLength) and (ForwardChars(liCommentLength, 2) = '*)') then
      inc(liCommentLength, 2);
  end;


begin
  Result := False;
  if not (Current = '(') then
    exit;


  if CurrentChars(2) <> '(*' then
    exit;

  { if the comment starts with (*) that is not the end of the comment }
  liCommentLength := 2;

  MoveToCommentEnd;

  pcToken.TokenType := ttComment;
  pcToken.CommentStyle := eBracketStar;
  pcToken.SourceCode := CurrentChars(liCommentLength);
  Consume(liCommentLength);
  
  Result := True;
end;

function TBuildTokenList.TryCurlyComment(const pcToken: TSourceToken): boolean;
var
  liCommentLength: integer;

  procedure MoveToCommentEnd;
  begin
    { comment is ended by close-curly or by EOF (bad source) }
    while True do
    begin
      if EndOfFileAfter(liCommentLength) then
        break;

      if CheckMultiByte(ForwardChar(liCommentLength)) then
      begin
        liCommentLength := liCommentLength + 2;
        continue;
      end;

      if ForwardChar(liCommentLength) = '}' then
        break;

      inc(liCommentLength);
    end;

    { include the closing brace }
    if not EndOfFileAfter(liCommentLength) and (ForwardChars(liCommentLength, 1) = '}') then
      inc(liCommentLength);
  end;

begin
  Result := False;
  if Current <> '{' then
    exit;

  pcToken.TokenType  := ttComment;
  liCommentLength := 1;

  { compiler directive are the comments with a $ just after the open-curly
    this is always the case }
  if ForwardChar(1) = '$' then
    pcToken.CommentStyle := eCompilerDirective
  else
    pcToken.CommentStyle := eCurlyBrace;

  MoveToCommentEnd;

  pcToken.SourceCode := CurrentChars(liCommentLength);
  Consume(liCommentLength);
  
  Result := True;
end;

function TBuildTokenList.TrySlashComment(const pcToken: TSourceToken): boolean;
var
  liCommentLength: integer;

  procedure MoveToCommentEnd;
  begin
    { comment is ended by return or by EOF (bad source) }
    while True do
    begin
      if EndOfFileAfter(liCommentLength) then
        break;

      if CheckMultiByte(ForwardChar(liCommentLength)) then
      begin
        liCommentLength := liCommentLength + 2;
        continue;
      end;

      if TParserUtils.CharIsReturn(ForwardChar(liCommentLength)) then
        break;

      inc(liCommentLength);
    end;
  end;

begin
  Result := False;
  if Current <> '/' then
    exit;

  { until end of line or file }
  if CurrentChars(2) <> '//' then
    exit;

  liCommentLength := 2;

  MoveToCommentEnd;

  pcToken.TokenType := ttComment;
  pcToken.CommentStyle := eDoubleSlash;
  pcToken.SourceCode := CurrentChars(liCommentLength);
  Consume(liCommentLength);

  Result := True;
end;


function TBuildTokenList.TryReturn(const pcToken: TSourceToken): boolean;
var
  chNext: char;
begin
  Result := False;
  if not TParserUtils.CharIsReturn(Current) then
    exit;

  pcToken.TokenType  := ttReturn;
  pcToken.SourceCode := Current;
  Consume;

  { concat the next return char if it is not the same
    This will recognise <cr><lf> or <lf><cr>, but not <cr><cr> }

  chNext := Current;
  if TParserUtils.CharIsReturn(chNext) and (chNext <> pcToken.SourceCode[1]) then
  begin
    pcToken.SourceCode := pcToken.SourceCode + chNext;
    Consume;
  end;
  Result := True;
end;

{ complexities like 'Hello'#32'World' and #$12'Foo' are assemlbed in the parser }
function TBuildTokenList.TryLiteralString(const pcToken: TSourceToken;
  const pcDelimiter: char): boolean;
begin
  Result := False;

  if Current = pcDelimiter then
  begin
    Result := True;
    { read the opening ' }
    pcToken.SourceCode := pcToken.SourceCode + Current;
    Consume;

    { read until the close ' }
    repeat
      if Current = #0 then
        break;
      if TParserUtils.CharIsReturn(Current) then
        Raise Exception.Create('Unterminated string: ' + pcToken.SourceCode);

      { two quotes in a row are still part of the string }
      if (Current = pcDelimiter) then
      begin
        { two consecutive quote chars inside string, read them }
        if (ForwardChar(1) = pcDelimiter) then
        begin
          pcToken.SourceCode := pcToken.SourceCode + CurrentChars(2);
          Consume(2);
        end
        else
        begin
          { single quote char ends string }
          pcToken.SourceCode := pcToken.SourceCode + Current;
          Consume;
          break;
        end
      end
      else
      begin
        { normal char, read it }
        pcToken.SourceCode := pcToken.SourceCode + Current;
        Consume;
      end;

    until False;

    pcToken.TokenType := ttQuotedLiteralString;
  end;
end;


function TBuildTokenList.TryWord(const pcToken: TSourceToken): boolean;

  function IsWordChar(const ch: char): boolean;
  begin
    Result := TParserUtils.CharIsAlpha(ch) or (ch = '_');
  end;

begin
  Result := False;

  if not IsWordChar(Current) then
    exit;

  pcToken.SourceCode := Current;
  Consume;

  { concat any subsequent word chars }
  while IsWordChar(Current) or TParserUtils.CharIsDigit(Current) do
  begin
    pcToken.SourceCode := pcToken.SourceCode + Current;
    Consume;
  end;

  { try to recognise the word as built in }
  pcToken.TokenType := TypeOfToken(pcToken.SourceCode);
  if pcToken.TokenType = ttUnknown then
    pcToken.TokenType := ttIdentifier;

  Result := True;
end;

function CharIsWhiteSpaceNoReturn(const ch: AnsiChar): boolean;
begin
  { 7 April 2004 following sf snag 928460 and discussion in newsgroups
    must accept all other chars < 32 as white space }

  // Result := CharIsWhiteSpace(ch) and (ch <> AnsiLineFeed) and (ch <> AnsiCarriageReturn);

  Result := (Ord(ch) <= Ord(' ')) and
    (not (ch in [#10, #13, #0]));
end;

function TBuildTokenList.TryWhiteSpace(const pcToken: TSourceToken): boolean;
begin
  Result := False;
  if not CharIsWhiteSpaceNoReturn(Current) then
    exit;

  pcToken.TokenType  := ttWhiteSpace;
  pcToken.SourceCode := Current;
  Consume;

  { concat any subsequent return chars }
  while CharIsWhiteSpaceNoReturn(Current) do
  begin
    pcToken.SourceCode := pcToken.SourceCode + Current;
    Consume;
  end;

  Result := True;
end;

function TBuildTokenList.TryAssign(const pcToken: TSourceToken): boolean;
begin
  Result := False;

  if Current <> ':' then
    exit;

  if CurrentChars(2) <> ':=' then
    exit;

  pcToken.TokenType := ttAssign;
  pcToken.SourceCode := CurrentChars(2);
  Consume(2);
  
  Result := True;
end;

function TBuildTokenList.TryNumber(const pcToken: TSourceToken): boolean;
var
  lbHasDecimalSep: boolean;
begin
  Result := False;

  { recognise a number -
   they don't start with a '.' but may contain one

   a minus sign in front is considered unary operator not part of the number
   this is bourne out by the compiler considering
    '- 0.3' and -0.3' to be the same value
    and -.3 is not legal at all }

  { first one must be a digit }
  if not TParserUtils.CharIsDigit(Current) then
    exit;

  if (Current = '.') or (Current = '-') then
    exit;

  pcToken.TokenType  := ttNumber;
  pcToken.SourceCode := Current;
  Consume;
  lbHasDecimalSep := False;

  { concat any subsequent number chars
    only one decimal seperator allowed

    also NB that two dots can be array range, as in
    var foo = array[1..100] of integer;
    ie one dat = decimal
    two dots = end of number
  }
  while TParserUtils.CharIsDigit(Current) or (Current = '.') do
  begin
    // have we got to the dot?
    if (Current = '.') then
    begin
      if CurrentChars(2) = '..' then
        break;

      if lbHasDecimalSep then
        // oops! a second one
        break
      else
        lbHasDecimalSep := True;
    end;

    pcToken.SourceCode := pcToken.SourceCode + Current;
    Consume;
  end;

  { scientific notation suffix, eg 3e2 = 30, 2.1e-3 = 0.0021 }

  { check for a trailing 'e' }
  if Current in ['e', 'E'] then
  begin
    // sci notation mode
    pcToken.SourceCode := pcToken.SourceCode + Current;
    Consume;

    // can be a minus or plus here
    if Current in ['-', '+'] then
    begin
      pcToken.SourceCode := pcToken.SourceCode + Current;
      Consume;
    end;

    { exponent must be integer }
    while TParserUtils.CharIsDigit(Current) do
    begin
      pcToken.SourceCode := pcToken.SourceCode + Current;
      Consume;
    end;
  end;

  Result := True;
end;

{ NB: do not localise '.' with DecimalSeperator
  Delphi source code does *not* change for this }
function TBuildTokenList.TryHexNumber(const pcToken: TSourceToken): boolean;
var
  lbHasDecimalSep: boolean;
begin
  Result := False;

  { starts with a $ }
  if Current <> '$' then
    exit;

  pcToken.TokenType  := ttNumber;
  pcToken.SourceCode := Current;
  Consume;
  lbHasDecimalSep := False;

  { concat any subsequent number chars }
  while (Current in ['0'..'9', 'A'..'F', 'a'..'f']) or (Current = '.') do
  begin
    // have we got to the dot?
    if (Current = '.') then
    begin
      if CurrentChars(2) = '..' then
        break;

      if lbHasDecimalSep then
        // oops! a second one
        break
      else
        lbHasDecimalSep := True;
    end;

    pcToken.SourceCode := pcToken.SourceCode + Current;
    Consume;
  end;

  Result := True;
end;

{ try the range '..' operator and object access  '.' operator }
function TBuildTokenList.TryDots(const pcToken: TSourceToken): boolean;
begin
  Result := False;

  if Current <> '.' then
    exit;

  pcToken.SourceCode := Current;
  Consume;

  if Current = '.' then
  begin
    pcToken.TokenType  := ttDoubleDot;
    pcToken.SourceCode := pcToken.SourceCode + Current;
    Consume;
  end
  else
  begin
    pcToken.TokenType := ttDot;
  end;

  Result := True;
end;


function IsPuncChar(const ch: char): boolean;
begin
  Result := False;

  if TParserUtils.CharIsWhiteSpace(ch) then
    exit;
  if TParserUtils.CharIsAlphaNum(ch) then
    exit;
  if TParserUtils.CharIsReturn(ch) then
    exit;

  if TParserUtils.CharIsControl(ch) then
    exit;

  Result := True;
end;

function TBuildTokenList.TryPunctuation(const pcToken: TSourceToken): boolean;


  function FollowsPunctuation(const chLast, ch: char): boolean;
  const
    { these have meanings on thier own and should not be recognised as part of the punc.
     e.g '=(' is not a punctation symbol, but 2 of them ( for e.g. in const a=(3);
     simlarly ');' is 2 puncs }
    UnitaryPunctuation: set of char = [
      '''', '"', '(', ')', '[', ']', '{',
      '#', '$', '_', ';', '@', '^', ','];

   { these can't have anything following them:
    for e.g, catch the case if a=-1 then ...
      where '=-1' should be read as '=' '-1' not '=-' '1'
      Nothing legitimately comes after '=' AFAIK
      also a:=a*-1;
      q:=q--1; // q equals q minus minus-one. It sucks but it compiles so it must be parsed
      etc }
    SingleChars: set of char = ['=', '+', '-', '*', '/', '\'];

  begin
    Result := False;

    if (chLast in UnitaryPunctuation) or (ch in UnitaryPunctuation) then
      exit;

    if chLast in SingleChars then
      exit;

    { '<' or '<' can only be followed by '<', '>' or '='.
     Beware of "if x<-1" }
    if (chLast in ['<', '>']) and not (ch in ['<', '>', '=']) then
      exit;

    // ':' can be followed by '='
    if (chLast = ':') and (ch <> '=') then
      exit;

    Result := IsPuncChar(ch);
  end;

var
  leWordType:  TWordType;
  leTokenType: TTokenType;
  lcLast:      char;
begin
  Result := False;

  if not IsPuncChar(Current) then
    exit;

  pcToken.TokenType := ttPunctuation;
  lcLast := Current;
  pcToken.SourceCode := lcLast;
  Consume;

  { concat any subsequent punc chars }
  while FollowsPunctuation(lcLast, Current) do
  begin
    lcLast := Current;
    pcToken.SourceCode := pcToken.SourceCode + lcLast;
    Consume;
  end;

  { try to recognise the punctuation as an operator }
  TypeOfToken(pcToken.SourceCode, leWordType, leTokenType);
  if leTokenType <> ttUnknown then
  begin
    pcToken.TokenType := leTokenType;
  end;

  Result := True;
end;

function TBuildTokenList.TrySingleCharToken(const pcToken: TSourceToken): boolean;
begin
  Result := False;

  pcToken.TokenType := TypeOfToken(Current);
  if pcToken.TokenType <> ttUnknown then
  begin
    pcToken.SourceCode := Current;
    Consume;
    Result := True;
  end;
end;

function TBuildTokenList.BuildTokenList: TSourceTokenList;
const
  UPDATE_INTERVAL = 4096; // big incre,ents here, this is fatser than parsing
var
  lcList:    TSourceTokenList;
  lcNew:     TSourceToken;
  liCounter: integer;
begin
  Assert(SourceCode <> '');

  liCounter := 0;
  lcList    := TSourceTokenList.Create;

  while not EndOfFile do
  begin
    lcNew := GetNextToken;
    lcList.Add(lcNew);

    Inc(liCounter);
    if (liCounter mod UPDATE_INTERVAL) = 0 then
      Application.ProcessMessages;
  end;

  Result := lcList;
end;

function TBuildTokenList.Current: char;
begin
  Result := fsSourceCode[fiCurrentIndex];
end;

function TBuildTokenList.CurrentChars(const piCount: integer): string;
begin
  Result := Copy(fsSourceCode, fiCurrentIndex, piCount);
end;

function TBuildTokenList.ForwardChar(const piOffset: integer): char;
begin
  Result := fsSourceCode[fiCurrentIndex + piOffset];
end;

function TBuildTokenList.ForwardChars(const piOffset, piCount: integer): string;
begin
  Result := Copy(fsSourceCode, fiCurrentIndex + piOffset, piCount);
end;


function TBuildTokenList.Consume(const piCount: integer): string;
begin
  inc(fiCurrentIndex, piCount);
end;

function TBuildTokenList.EndOfFile: boolean;
begin
  Result := fiCurrentIndex > Length(fsSourceCode);
end;

function TBuildTokenList.EndOfFileAfter(const piChars: integer): boolean;
begin
  Result := (fiCurrentIndex + piChars) > Length(fsSourceCode);
end;

end.
