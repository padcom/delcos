// ----------------------------------------------------------------------------
// Unit        : PxXmlReader.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2006-01-10
// Version     : 1.0 
// Description : Incremental Xml reader
// Changes log : 2006-01-10 - initial version (based on some 3rd party library)
// ToDo        : Testing.
// ----------------------------------------------------------------------------

unit PxXmlReader;

{$I PxDefines.inc}

interface

uses
  Windows, SysUtils, Classes, Math;

type
  TPxXmlTextReader = class
  private
    Stream: TStream;
    Buffer: PChar;
    BufSize: Word;
    BufEnd: PChar;
    BufPos: PChar;
    ConvertOemToChar: Boolean;
    procedure GotoNextChar;
    function GetPos: Longint;
    procedure SetPos(aPos: Longint);
  public
    constructor Create(aStream: TStream; aBufSize: Word);
    destructor Destroy; override;
    function ReadLine: string;
    procedure ReadLineToBuf(aBuf: PChar; aBufSize: Integer);
    function ReadChar: Char;
    function Eof: Boolean;
    property Pos: Longint read GetPos write SetPos;
  end;

  // Inner-used class
  TPxXmlReaderStream = class
  private
    FreeStream: Boolean;
    Stm: TStream;
    Reader: TPxXmlTextReader;
    BackBuffer: string;
    function GetEof: Boolean;
  public
    constructor Create(aStm: TStream; aFreeStream: Boolean);
    destructor Destroy; override;
    function ReadChar(aRemoveChar: Boolean = True): Char;
    function Expect(const s: string; aRemoveChar: Boolean = True): Boolean;
    procedure SkipBlanks;
    procedure PutBack(c: Char); overload;
    procedure PutBack(const s: string); overload;
    property Eof: Boolean read GetEof;
  end;

  TPxXmlReaderTokenType = (
    xrtProcessingInstruction, //Set Name, Value
    xrtDocumentType, //Set Name, Value
    xrtComment, //Set Value+
    xrtCData, //Set Value+
    xrtElementBegin, //Set Name
    xrtElementEnd, //Set Name
    xrtElementAttribute, //Set Name, Value
    xrtText, //Set Value+
    xrtEof
    );

  TPxXmlReaderState = (
    xrsScan,
    xrsReadText,
    xrsReadElement,
    xrsReadComment,
    xrsReadCData
    );

  EPxXmlReader = class(Exception);

  TPxXmlReader = class
  private
    FPortionSize: Integer;
    FTokenType: TPxXmlReaderTokenType;
    FName: string;
    FValue: string;
    FBeginOfValue: Boolean;
    FEndOfValue: Boolean;
    FEndOfXml: Boolean;
    FElements: TStringList;
    FLastElementForClosingTagPath: String;
    State: TPxXmlReaderState;
    Stm: TPxXmlReaderStream;
    Buffer: PChar;
    function GetElementLevel: Integer;
    function GetElementPath: string;
    function GetElementName: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure OpenXml(const aXml: string);
    procedure Open(const aFileName: string); overload;
    procedure Open(aStm: TStream; aFreeStream: Boolean = False); overload;
    procedure Close;
    function Next: TPxXmlReaderTokenType;
    property PortionSize: Integer read FPortionSize write FPortionSize;
    property TokenType: TPxXmlReaderTokenType read FTokenType;
    property Name: string read FName;
    property Value: string read FValue;
    property BeginOfValue: Boolean read FBeginOfValue;
    property EndOfValue: Boolean read FEndOfValue;
    property EndOfXml: Boolean read FEndOfXml;
    property Elements: TStringList read FElements;
    property ElementLevel: Integer read GetElementLevel;
    property ElementPath: string read GetElementPath;
    property ElementName: string read GetElementName;
  end;

implementation

const
  kBufferSize = 8192;

{ TPxXmlTextReader }

constructor TPxXmlTextReader.Create(aStream: TStream; aBufSize: Word);
begin
  inherited Create;
  Stream := aStream;
  BufSize := aBufSize;
  Buffer := AllocMem(aBufSize);
  BufEnd := Buffer + 1;
  BufPos := Buffer;
  GotoNextChar;
end;

destructor TPxXmlTextReader.Destroy;
begin
  if Assigned(Buffer) then
    FreeMem(Buffer, BufSize);
  inherited Destroy;
end;

procedure TPxXmlTextReader.GotoNextChar;
begin
  Inc(BufPos);
  if BufPos = BufEnd then
  begin
    BufEnd := Buffer + Min(BufSize, Stream.Size - Stream.Position);
    Stream.ReadBuffer(Buffer^, BufEnd - Buffer);
    BufPos := Buffer;
  end;
end;

function TPxXmlTextReader.GetPos: Longint;
begin
  Result := Stream.Position - Longint(BufEnd - BufPos);
end;

procedure TPxXmlTextReader.SetPos(aPos: Longint);
begin
  if aPos <> GetPos then
  begin
    Stream.Seek(aPos, soFromBeginning);
    BufEnd := Buffer + 1;
    BufPos := Buffer;
    GotoNextChar;
  end;
end;

function TPxXmlTextReader.ReadLine: string;
var
  aChar: Char;
begin
  Result := '';
  while not Eof do
  begin
    aChar := BufPos^;
    if aChar in [^M, ^J] then
    begin
      GotoNextChar;
      if not Eof and (BufPos^ in [^M, ^J]) and (BufPos^ <> aChar) then
        GotoNextChar;
      Break;
    end;
    SetLength(Result, Length(Result) + 1);
    Result[Length(Result)] := aChar;
    GotoNextChar;
  end;
  if ConvertOemToChar and (Result <> '') then
    OemToCharBuff(PChar(Result), PChar(Result), Length(Result));
end;

procedure TPxXmlTextReader.ReadLineToBuf(aBuf: PChar; aBufSize: Integer);
var
  aChar: Char;
  aSaveBuf: PChar;
begin
  aSaveBuf := aBuf;
  while (not Eof) and (aBufSize > 0) do
  begin
    aChar := BufPos^;
    if aChar in [^M, ^J] then
    begin
      GotoNextChar;
      if not Eof and (BufPos^ in [^M, ^J]) and (BufPos^ <> aChar) then
        GotoNextChar;
      Break;
    end;
    aBuf^ := aChar;
    Inc(aBuf);
    Dec(aBufSize);
    GotoNextChar;
  end;
  aBuf^ := #0;
  if ConvertOemToChar then
    OemToCharBuff(aSaveBuf, aSaveBuf, aBuf - aSaveBuf);
end;

function TPxXmlTextReader.ReadChar: Char;
begin
  if not Eof then
  begin
    Result := BufPos^;
    GotoNextChar;
    if ConvertOemToChar then
      OemToCharBuff(@Result, @Result, 1);
  end
  else
    Result := #0;
end;

function TPxXmlTextReader.Eof: Boolean;
begin
  Result := BufPos = BufEnd;
end;

{ TPxXmlReaderStream }

constructor TPxXmlReaderStream.Create(aStm: TStream; aFreeStream: Boolean);
begin
  inherited Create;
  FreeStream := aFreeStream;
  Stm := aStm;
  Reader := TPxXmlTextReader.Create(Stm, 4096);
  BackBuffer := '';
end;

destructor TPxXmlReaderStream.Destroy;
begin
  Reader.Free;
  if FreeStream then
    Stm.Free;
  inherited Destroy;
end;

function TPxXmlReaderStream.GetEof: Boolean;
begin
  Result := (BackBuffer = '') and Reader.Eof;
end;

function TPxXmlReaderStream.ReadChar(aRemoveChar: Boolean): Char;
var
  aLen: Integer;
begin
  aLen := Length(BackBuffer);
  if aLen <> 0 then
  begin
    Result := BackBuffer[aLen];
    if aRemoveChar then
      SetLength(BackBuffer, aLen - 1);
  end
  else if Reader.Eof then
    Result := #0
  else
  begin
    Result := Reader.ReadChar;
    if not aRemoveChar then
      PutBack(Result);
  end;
end;

function TPxXmlReaderStream.Expect(const s: string; aRemoveChar: Boolean):
  Boolean;
var
  c: Char;
  i: Integer;
begin
  Result := True;
  for i := 1 to Length(s) do
  begin
    if Eof then
    begin
      PutBack(Copy(s, 1, i - 1));
      Result := False;
      break;
    end;
    c := ReadChar;
    if c <> s[i] then
    begin
      PutBack(c);
      PutBack(Copy(s, 1, i - 1));
      Result := False;
      break;
    end;
  end;
  if Result and not aRemoveChar then
    PutBack(s);
end;

procedure TPxXmlReaderStream.SkipBlanks;
var
  c: Char;
begin
  while not Eof do
  begin
    c := ReadChar;
    if Ord(c) > 32 then
    begin
      PutBack(c);
      break;
    end;
  end;
end;

procedure TPxXmlReaderStream.PutBack(c: Char);
begin
  BackBuffer := BackBuffer + c;
end;

procedure TPxXmlReaderStream.PutBack(const s: string);
var
  s2: string;
  aLen, i: Integer;
begin
  aLen := Length(s);
  SetLength(s2, aLen);
  for i := 1 to aLen do
    s2[aLen - i + 1] := s[i];
  BackBuffer := BackBuffer + s2;
end;

{ TPxXmlReader }

constructor TPxXmlReader.Create;
begin
  inherited Create;
  FEndOfXml := True;
  GetMem(Buffer, kBufferSize);
  FElements := TStringList.Create;
end;

destructor TPxXmlReader.Destroy;
begin
  Close;
  FElements.Free;
  FreeMem(Buffer);
  inherited Destroy;
end;

function TPxXmlReader.GetElementLevel: Integer;
begin
  Result := Elements.Count;
end;

function TPxXmlReader.GetElementName: String;
begin
  Result := Elements[Elements.Count - 1];
end;

function TPxXmlReader.GetElementPath: string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to Elements.Count - 1 do
    Result := Result + '\' + Elements[i];
  Delete(Result, 1, 1);
  if FTokenType = xrtElementEnd then
    Result := Result + '\' + FLastElementForClosingTagPath;
end;

procedure TPxXmlReader.OpenXml(const aXml: string);
begin
  Open(TStringStream.Create(aXml), True);
end;

procedure TPxXmlReader.Open(const aFileName: string);
begin
  Open(TFileStream.Create(aFileName, fmOpenRead or fmShareDenyWrite), True);
end;

procedure TPxXmlReader.Open(aStm: TStream; aFreeStream: Boolean);
begin
  Close;
  Stm := TPxXmlReaderStream.Create(aStm, aFreeStream);
  FTokenType := xrtEof;
  FEndOfXml := Stm.Eof;
  Elements.Clear;
  State := xrsScan;
end;

procedure TPxXmlReader.Close;
begin
  FreeAndNil(Stm);
  FTokenType := xrtEof;
  FEndOfXml := True;
  if Assigned(Elements) then
    Elements.Clear;
end;

function TPxXmlReader.Next: TPxXmlReaderTokenType;

  procedure DoReadProcessingInstruction;
  var
    aBuf: PChar;
    aPrevC, c: Char;
    i: Integer;
  begin
    Stm.SkipBlanks;
    aBuf := Buffer;
    i := 0;
    while not Stm.Eof do
    begin
      c := Stm.ReadChar;
      if c in [#0..' ', '?', '>'] then
      begin
        aBuf^ := #0;
        FName := FName + Buffer;
        if not (c in [#0..' ']) then
          Stm.PutBack(c);
        break;
      end;
      aBuf^ := c;
      Inc(aBuf);
      Inc(i);
      if i = kBufferSize - 1 then
      begin
        aBuf^ := #0;
        FName := FName + Buffer;
        aBuf := Buffer;
        i := 0;
      end;
    end;
    if Name = '' then
      raise EPxXmlReader.Create('Error while reading attribute');

    Stm.SkipBlanks;
    aPrevC := #0;
    aBuf := Buffer;
    i := 0;
    while not Stm.Eof do
    begin
      c := Stm.ReadChar;
      if (c = '>') and (aPrevC = '?') then
      begin
        aBuf^ := #0;
        FValue := FValue + Buffer;
        SetLength(FValue, Length(FValue) - 1);
        Result := xrtProcessingInstruction;
        State := xrsScan;
        break;
      end;
      aPrevC := c;
      aBuf^ := c;
      Inc(aBuf);
      Inc(i);
      if i = kBufferSize - 1 then
      begin
        aBuf^ := #0;
        FValue := FValue + Buffer;
        aBuf := Buffer;
        i := 0;
      end;
    end;
    if Result <> xrtProcessingInstruction then
      raise EPxXmlReader.Create('Error while reading processing instruction');
  end;

  procedure DoReadDocumentType;
  var
    aBuf: PChar;
    c: Char;
    aBracketCount, i: Integer;
  begin
    Stm.SkipBlanks;
    aBuf := Buffer;
    i := 0;
    while not Stm.Eof do
    begin
      c := Stm.ReadChar;
      if c in [#0..' ', '>'] then
      begin
        aBuf^ := #0;
        FName := FName + Buffer;
        if not (c in [#0..' ']) then
          Stm.PutBack(c);
        break;
      end;
      aBuf^ := c;
      Inc(aBuf);
      Inc(i);
      if i = kBufferSize - 1 then
      begin
        aBuf^ := #0;
        FName := FName + Buffer;
        aBuf := Buffer;
        i := 0;
      end;
    end;
    if Name = '' then
      raise EPxXmlReader.Create('Ошибка в XML-документе: не задано имя в типе документа');

    Stm.SkipBlanks;
    aBracketCount := 1;
    aBuf := Buffer;
    i := 0;
    while not Stm.Eof do
    begin
      c := Stm.ReadChar;
      if c = '<' then
        Inc(aBracketCount)
      else if c = '>' then
        Dec(aBracketCount);
      if aBracketCount = 0 then
      begin
        aBuf^ := #0;
        FValue := FValue + Buffer;
        Result := xrtDocumentType;
        State := xrsScan;
        break;
      end;
      aBuf^ := c;
      Inc(aBuf);
      Inc(i);
      if i = kBufferSize - 1 then
      begin
        aBuf^ := #0;
        FValue := FValue + Buffer;
        aBuf := Buffer;
        i := 0;
      end;
    end;
    if Result <> xrtDocumentType then
      raise EPxXmlReader.Create('Ошибка в XML-документе: ожидается ">" для типа документа');
  end;

  procedure DoReadComment;
  var
    aBuf: PChar;
    aPrevPrevC, aPrevC, c: Char;
    aLen, i: Integer;
  begin
    FBeginOfValue := State <> xrsReadComment;
    aPrevPrevC := #0;
    aPrevC := #0;
    aBuf := Buffer;
    i := 0;
    while not Stm.Eof do
    begin
      c := Stm.ReadChar;
      if (c = '>') and (aPrevC = '-') and (aPrevPrevC = '-') then
      begin
        aBuf^ := #0;
        FValue := FValue + Buffer;
        SetLength(FValue, Length(FValue) - 2);
        Result := xrtComment;
        State := xrsScan;
        break;
      end;
      aPrevPrevC := aPrevC;
      aPrevC := c;
      aBuf^ := c;
      Inc(aBuf);
      Inc(i);
      if i = kBufferSize - 1 then
      begin
        aBuf^ := #0;
        FValue := FValue + Buffer;
        aBuf := Buffer;
        i := 0;
        aLen := Length(Value);
        if (PortionSize > 0) and (aLen >= PortionSize) then
        begin
          Stm.PutBack(Copy(Value, aLen - 1, 2));
          SetLength(FValue, aLen - 2);
          Result := xrtComment;
          State := xrsReadComment;
          FEndOfValue := False;
          break;
        end;
      end;
    end;
    if Result <> xrtComment then
      raise EPxXmlReader.Create('Ошибка в XML-документе: ожидается "-->"');
  end;

  procedure DoReadCData;
  var
    aBuf: PChar;
    aPrevC, c: Char;
    aLen, i: Integer;
  begin
    FBeginOfValue := State <> xrsReadCData;
    aPrevC := #0;
    aBuf := Buffer;
    i := 0;
    while not Stm.Eof do
    begin
      c := Stm.ReadChar;
      if (c = ']') and (aPrevC = ']') then
      begin
        aBuf^ := #0;
        FValue := FValue + Buffer;
        SetLength(FValue, Length(FValue) - 1);
        Stm.SkipBlanks;
        if Stm.Eof or (Stm.ReadChar <> '>') then
          raise Exception.Create('Ошибка в XML-документе: ожидается "]]>"');
        Result := xrtCData;
        State := xrsScan;
        break;
      end;
      aPrevC := c;
      aBuf^ := c;
      Inc(aBuf);
      Inc(i);
      if i = kBufferSize - 1 then
      begin
        aBuf^ := #0;
        FValue := FValue + Buffer;
        aBuf := Buffer;
        i := 0;
        aLen := Length(Value);
        if (PortionSize > 0) and (aLen >= PortionSize) then
        begin
          Stm.PutBack(Value[aLen]);
          SetLength(FValue, aLen - 1);
          Result := xrtCData;
          State := xrsReadCData;
          FEndOfValue := False;
          break;
        end;
      end;
    end;
    if Result <> xrtCData then
      raise EPxXmlReader.Create('Ошибка в XML-документе: ожидается "]]"');
  end;

  procedure DoReadOpeningElement;
  var
    aBuf: PChar;
    c: Char;
    i: Integer;
  begin
    Stm.SkipBlanks;
    aBuf := Buffer;
    i := 0;
    while not Stm.Eof do
    begin
      c := Stm.ReadChar;
      if c in [#0..' ', '/', '>'] then
      begin
        aBuf^ := #0;
        FName := FName + Buffer;
        if Ord(c) <= 32 then
        begin
          Stm.SkipBlanks;
          if Stm.Eof then
            break;
          c := Stm.ReadChar;
        end;
        if c = '>' then
          State := xrsScan
        else
        begin
          Stm.PutBack(c);
          State := xrsReadElement;
        end;
        Result := xrtElementBegin;
        Elements.Add(Name);
        break;
      end;
      aBuf^ := c;
      Inc(aBuf);
      Inc(i);
      if i = kBufferSize - 1 then
      begin
        aBuf^ := #0;
        FName := FName + Buffer;
        aBuf := Buffer;
        i := 0;
      end;
    end;
    if Result <> xrtElementBegin then
      raise EPxXmlReader.Create('Ошибка в XML-документе: ожидается ">" для открывающего тэга элемента');
    if Name = '' then
      raise EPxXmlReader.Create('Ошибка в XML-документе: не задано имя открывающего тэга элемента');
  end;

  procedure DoReadClosingElement;
  var
    aBuf: PChar;
    c: Char;
    i: Integer;
  begin
    Stm.SkipBlanks;
    aBuf := Buffer;
    i := 0;
    while not Stm.Eof do
    begin
      c := Stm.ReadChar;
      if c in [#0..' ', '>'] then
      begin
        aBuf^ := #0;
        FName := FName + Buffer;
        if Ord(c) <= 32 then
        begin
          Stm.SkipBlanks;
          if Stm.Eof then
            break;
          c := Stm.ReadChar;
        end;
        if c <> '>' then
          break;
        i := Elements.Count - 1;
        if (i < 0) or (Elements[i] <> Name) then
          raise Exception.Create('Ошибка в XML-документе: несоответствие имени закрывающего тэга имени открывающему');
        FLastElementForClosingTagPath := Elements[I];
        Elements.Delete(i);
        Result := xrtElementEnd;
        State := xrsScan;
        break;
      end;
      aBuf^ := c;
      Inc(aBuf);
      Inc(i);
      if i = kBufferSize - 1 then
      begin
        aBuf^ := #0;
        FName := FName + Buffer;
        aBuf := Buffer;
        i := 0;
      end;
    end;
    if Result <> xrtElementEnd then
      raise EPxXmlReader.Create('Ошибка в XML-документе: ожидается ">" для закрывающего тэга элемента');
    if Name = '' then
      raise EPxXmlReader.Create('Ошибка в XML-документе: не задано имя закрывающего тэга элемента');
  end;

  procedure DoReadAttribute;
  var
    aBuf: PChar;
    c: Char;
    i: Integer;
    anEnclosingChar: Char;
  begin
    Stm.SkipBlanks;
    if not Stm.Eof and (Stm.ReadChar(False) = '/') then
    begin
      Stm.ReadChar;
      if Stm.Eof or (Stm.ReadChar <> '>') then
        raise EPxXmlReader.Create('Ошибка в XML-документе: ожидается "/>"');
      i := Elements.Count - 1;
      FName := Elements[i];
      Elements.Delete(i);
      Result := xrtElementEnd;
      State := xrsScan;
      exit;
    end;

    aBuf := Buffer;
    i := 0;
    while not Stm.Eof do
    begin
      c := Stm.ReadChar;
      if c in [#0..' ', '=', '>'] then
      begin
        aBuf^ := #0;
        FName := FName + Buffer;
        if Ord(c) <= 32 then
        begin
          Stm.SkipBlanks;
          if Stm.Eof then
            break;
          c := Stm.ReadChar;
        end;
        if c <> '=' then
          raise EPxXmlReader.Create('Ошибка в XML-документе: ожидается "=" для атрибута элемента');
        break;
      end;
      aBuf^ := c;
      Inc(aBuf);
      Inc(i);
      if i = kBufferSize - 1 then
      begin
        aBuf^ := #0;
        FName := FName + Buffer;
        aBuf := Buffer;
        i := 0;
      end;
    end;
    if Name = '' then
      raise EPxXmlReader.Create('Ошибка в XML-документе: не задано имя атрибута элемента');

    Stm.SkipBlanks;
    if Stm.Eof then
      raise EPxXmlReader.Create('Ошибка в XML-документе: не задано значение атрибута элемента');
    c := Stm.ReadChar;
    anEnclosingChar := c;
    if not (anEnclosingChar in ['"', '''']) then
    begin
      Stm.PutBack(c);
      anEnclosingChar := #0;
    end;
    aBuf := Buffer;
    i := 0;
    while not Stm.Eof do
    begin
      c := Stm.ReadChar;
      if ((anEnclosingChar <> #0) and (c = anEnclosingChar)) or
        ((anEnclosingChar = #0) and (c in [#0..' ', '/', '>'])) then
      begin
        aBuf^ := #0;
        FValue := FValue + Buffer;
        if anEnclosingChar <> #0 then
        begin
          if Stm.Eof then
            break;
          c := Stm.ReadChar;
        end;
        if Ord(c) <= 32 then
        begin
          Stm.SkipBlanks;
          if Stm.Eof then
            break;
          c := Stm.ReadChar;
        end;
        if c = '>' then
          State := xrsScan
        else
          Stm.PutBack(c);
        Result := xrtElementAttribute;
        break;
      end;
      aBuf^ := c;
      Inc(aBuf);
      Inc(i);
      if i = kBufferSize - 1 then
      begin
        aBuf^ := #0;
        FValue := FValue + Buffer;
        aBuf := Buffer;
        i := 0;
      end;
    end;
    if Result <> xrtElementAttribute then
      raise EPxXmlReader.Create('Ошибка в XML-документе: ожидается атрибут элемента');
  end;

  procedure DoReadText;
  var
    aBuf: PChar;
    c: Char;
    aLen, i: Integer;
  begin
    FBeginOfValue := State <> xrsReadText;

    aBuf := Buffer;
    i := 0;
    while True do
    begin
      if Stm.Eof then
      begin
        aBuf^ := #0;
        FValue := FValue + Buffer;
        Result := xrtText;
        State := xrsScan;
        break;
      end;
      c := Stm.ReadChar;
      if c = '<' then
      begin
        aBuf^ := #0;
        FValue := FValue + Buffer;
        Stm.PutBack(c);
        Result := xrtText;
        State := xrsScan;
        break;
      end;
      aBuf^ := c;
      Inc(aBuf);
      Inc(i);
      if i = kBufferSize - 1 then
      begin
        aBuf^ := #0;
        FValue := FValue + Buffer;
        aBuf := Buffer;
        i := 0;
        aLen := Length(Value);
        if (PortionSize > 0) and (aLen >= PortionSize) then
        begin
          Stm.PutBack(Value[aLen]);
          SetLength(FValue, aLen - 1);
          Result := xrtText;
          State := xrsReadText;
          FEndOfValue := False;
          break;
        end;
      end;
    end;
    if Result <> xrtText then
      raise EPxXmlReader.Create('Ошибка в XML-документе: ожидается текст элемента');
  end;

var
  c: Char;
begin
  FName := '';
  FValue := '';
  FBeginOfValue := True;
  FEndOfValue := True;
  Result := xrtEof;
  if not EndOfXml and not Stm.Eof then
    case State of
      xrsReadText: DoReadText;
      xrsReadElement: DoReadAttribute;
      xrsReadComment: DoReadComment;
      xrsReadCData: DoReadCData;
    else
      begin //xrsScan
        if ElementLevel = 0 then
          Stm.SkipBlanks;
        if not Stm.Eof then
        begin
          c := Stm.ReadChar;
          if c = '<' then
          begin
            if Stm.Eof then
              raise Exception.Create('Ошибка в XML-документе: неожидаемое завершение текста');
            c := Stm.ReadChar;
            case c of
              '?': DoReadProcessingInstruction;
              '/': DoReadClosingElement;
              '!':
                if Stm.Expect('--') then
                  DoReadComment
                else if Stm.Expect('[CDATA[') then
                  DoReadCData
                else if Stm.Expect('DOCTYPE') then
                  DoReadDocumentType
                else
                  raise Exception.Create('Ошибка в XML-документе: неизвестная специальная инструкция');
              else
              begin
                Stm.PutBack(c);
                DoReadOpeningElement;
              end;
            end;
          end
          else
          begin
            Stm.PutBack(c);
            if ElementLevel = 0 then
              raise Exception.Create('Ошибка в XML-документе: текст вне элемента');
            DoReadText;
          end;
        end;
      end;
    end;
  if Result = xrtEof then
    FEndOfXml := True;
  FTokenType := Result;
end;

end.

