// --------------------------------------------------------------------------------------------
// Unit : XmlFile.pas
// Autor: Maciej "Padcom" Hryniszak
//
// Data : 2002-08-xx - Works for the first time. Writen upon the base of XmlFile.pas used for
//                     "RadioTaxi Manager 3.1".
//        2002-09-xx - Method of reading th content changed to more "proffessional". Now it is
//                     used a TParser class from Classes.pas and changed to fit the needs of
//                     Xml format (doublequote instead of quote as an string delimiter).
//                     Added error handling routines (with line number where the error has
//                     occured)
//        2002-10-30 - Extension: a custom tag named Include has been introduced. It allows to
//                     make embedded Xml content instead of writting all in one file. This
//                     feature is enabled by default but can be disabled by passing
//                     ResolveIncludes = False to the constructor of TPxXmlFile.
//                     WARNING: Only the first root tag is included into resulting Xml tree.
//                     So the included file must have a form
//                       <ExampleTag>
//                         interior...
//                       </ExampleTag>
//                     instead of
//                       <ExampleTag1>
//                         interior...
//                       </ExampleTag1>
//                       <ExampleTag2>
//                         interior...
//                       </ExampleTag2>
//                     In the second example only the <ExampleTag1> will be included and the
//                     <ExampleTag2> will be omnited.
//        2002-11-04 - Inside change: Now adding and removing of params is done by TPxXmlParam
//                     instead of providing a complex maintance of params with TPxXmlItem.
//                     Also TPxXmlItem is automaticaly added to his owner (the param Owner in
//                     TPxXmlItem is required !)
//        2002-12-19 - Fix with included XmlFiles: There was a problem with including of XmlFiles
//                     that included only on the first level. Now it is possible to add
//                     <Inclide FileName="filename.xml"/> in any place (not inside a tag definition)
//                     and the content will be inserted in the selected place.
//        2003-02-15 - Added handling of Xml params <?xml-param-name param="" ?>
//        2003-11-10 - Changed description of unit to fit the standard.
//                   - Added conditional definition DEBUG only if there is no FINALVERSION defined
//                     (to fit the standard)
//                   - Change the form XML to Xml (to look more like Xml class from .NET framework)
//        2003-11-12 - Added two methods StoreStream and RestoreStream to the TPxXmlParam class.
//                     Savind is done as UUEncode and therefore it may take a while to store some
//                     larger data into such params.
//                   - Access methods to AsString property has been modified to proper handling
//                     of \" sequence (to make the UUEncode streams possible)
//        2004-05-03 - Fixed bug while disposing TPxXmlProperty
//        2006-02-24 - added compatibility with Delphi 6
//
// Desc : todo.
//
// ToDo : - usage description, doc, additional comments in code;
// --------------------------------------------------------------------------------------------

unit PxXmlFile;

{$I PxDefines.inc}

interface

uses
  Classes, SysUtils;

type
  TPxXmlItem = class;
  TPxXmlObject = class (TObject)
  end;

  TPxXmlParam = class (TPxXmlObject)
  private
    FName: String;
    FValue: String;
    FParent: TPxXmlItem;
    function GetBoolean: Boolean;
    procedure SetBoolean(Value: Boolean);
    function GetFloat: Extended;
    procedure SetFloat(Value: Extended);
    function GetInteger: Int64;
    procedure SetInteger(Value: Int64);
    function GetString: String;
    procedure SetString(Value: String);
  public
    constructor Create(AParent: TPxXmlItem);
    destructor Destroy; override;
    function IsParamName(ParamName: String): Boolean;
    procedure StoreStream(Stream: TStream);
    procedure RestoreStream(Stream: TStream);
    property Parent: TPxXmlItem read FParent;
    property Name: String read FName write FName;
    // string (exactly as it is written in xml)
    property Value: String read FValue write FValue;
    property AsBoolean: Boolean read GetBoolean write SetBoolean;
    property AsFloat: Extended read GetFloat write SetFloat;
    property AsInteger: Int64 read GetInteger write SetInteger;
    // string that knows how to handle special character sequences ("\|", "\'", "\\", "\"");
    property AsString: String read GetString write SetString;
  end;

  TPxXmlParamList = class (TList)
  private
    function GetItem(Index: Integer): TPxXmlParam;
  public
    property Items[Index: Integer]: TPxXmlParam read GetItem; default;
  end;

  TPxXmlItemList = class;

  TPxXmlItem = class (TPxXmlObject)
  private
    FParent: TPxXmlItem;
    FName: String;
    FParams: TPxXmlParamList;
    FItems: TPxXmlItemList;
    function GetParamCount: Integer;
    function GetItemCount: Integer;
    function GetThis: TPxXmlItem;
  public
    constructor Create(AParent: TPxXmlItem);
    destructor Destroy; override;
    function GetItemByName(ItemName: String): TPxXmlItem;
    function HasItem(ItemName: String): Boolean;
    function GetParamByName(ParamName: String): TPxXmlParam;
    function GetParamByNameS(ParamName: String): String;
    function HasParam(ParamName: String): Boolean;
    function IsItemName(ItemName: String): Boolean;
    property Parent: TPxXmlItem read FParent;
    property This: TPxXmlItem read GetThis;
    property Name: String read FName write FName;
    property Params: TPxXmlParamList read FParams;
    property ParamCount: Integer read GetParamCount;
    property Items: TPxXmlItemList read FItems;
    property ItemCount: Integer read GetItemCount;
  end;

  TPxXmlItemList = class (TList)
  private
    function GetItem(Index: Integer): TPxXmlItem;
    procedure SetItem(Index: Integer; Value: TPxXmlItem);
  public
    property Items[Index: Integer]: TPxXmlItem read GetItem write SetItem; default;
  end;

  TPxXmlProperty = class;

  TPxXmlValue = class (TPxXmlObject)
  private
    FName: String;
    FValue: String;
    FParent: TPxXmlProperty;
    function GetBoolean: Boolean;
    procedure SetBoolean(Value: Boolean);
    function GetFloat: Extended;
    procedure SetFloat(Value: Extended);
    function GetInteger: Int64;
    procedure SetInteger(Value: Int64);
    function GetString: String;
    procedure SetString(Value: String);
  public
    constructor Create(AParent: TPxXmlProperty);
    destructor Destroy; override;
    function IsValueName(ValueName: String): Boolean;
    property Parent: TPxXmlProperty read FParent;
    property Name: String read FName write FName;
    // string (exactly as it is written in xml)
    property Value: String read FValue write FValue;
    property AsBoolean: Boolean read GetBoolean write SetBoolean;
    property AsFloat: Extended read GetFloat write SetFloat;
    property AsInteger: Int64 read GetInteger write SetInteger;
    // string that knows how to handle special character sequences ("\|", "\'", "\\", "\"");
    property AsString: String read GetString write SetString;
  end;

  TPxXmlValueList = class (TList)
  private
    function GetItem(Index: Integer): TPxXmlValue;
  public
    property Items[Index: Integer]: TPxXmlValue read GetItem; default;
  end;

  TPxXmlProperty = class (TPxXmlObject)
  private
    FName: String;
    FValues: TPxXmlValueList;
  public
    constructor Create;
    destructor Destroy; override;
    function GetValueByName(ParamName: String): TPxXmlValue;
    function GetValueByNameS(ParamName: String): String;
    function HasValue(ParamName: String): Boolean;
    function IsPropertyName(ItemName: String): Boolean;
    property Name: String read FName write FName;
    property Values: TPxXmlValueList read FValues write FValues;
  end;

  TPxXmlPropertyList = class (TList)
  private
    function GetByName(Name: String): TPxXmlProperty;
    function GetItem(Index: Integer): TPxXmlProperty;
  public
    function PropertyExists(Name: String): Boolean;
    property ByName[Name: String]: TPxXmlProperty read GetByName;
    property Items[Index: Integer]: TPxXmlProperty read GetItem; default;
  end;

  TPxXmlParseStatus = (psNotLoaded, psLoaded, psError);

  TPxXmlFile = class (TPxXmlObject)
  private
    FXmlProperties: TPxXmlPropertyList;
    FXmlRoot: TPxXmlItem;
    FStatus: TPxXmlParseStatus;
    FStatusMessage: String;
    FResolveIncludes: Boolean;
    FInternalFileNameCounter: array of record
      Extension: string;
      Value: Integer;
    end;
    procedure Parse(Stream: TStream);
    procedure DisconnectRoot;
    procedure ResolveIncludes;
  public
    constructor Create(ResolveIncludes: Boolean = True; CreateRoot: Boolean = False);
    destructor Destroy; override;
    function GetNextInternalFileName(Base, Ext: string): string;
    procedure ReadFile(FileName: String);
    procedure ReadStrings(Strings: TStrings);
    procedure ReadStream(Stream: TStream);
    procedure GenerateTree(XmlItem: TPxXmlItem; Strings: TStrings; Ident: String);
    procedure WriteFile(FileName: String);
    procedure WriteStrings(Strings: TStrings);
    procedure WriteStream(Stream: TStream);
    property Status: TPxXmlParseStatus read FStatus;
    property StatusMessage: String read FStatusMessage;
    property XmlProperties: TPxXmlPropertyList read FXmlProperties;
    property XmlItem: TPxXmlItem read FXmlRoot;
  end;

implementation

uses
{$IFDEF VER130}
  Consts;
{$ENDIF}
{$IFDEF VER140}
  RtlConsts;
{$ENDIF}
{$IFDEF VER150}
  RtlConsts;
{$ENDIF}
{$IFDEF FPC}
  RtlConsts;
{$ENDIF}

{ TParser }

const
  ParseBufSize = 65536;

{ TParser special tokens }

  toEOF     = Char(0);
  toSymbol  = Char(1);
  toString  = Char(2);
  toInteger = Char(3);
  toFloat   = Char(4);

type
  TParser = class(TObject)
  private
    FStream: TStream;
    FOrigin: Longint;
    FBuffer: PChar;
    FBufPtr: PChar;
    FBufEnd: PChar;
    FSourcePtr: PChar;
    FSourceEnd: PChar;
    FTokenPtr: PChar;
    FStringPtr: PChar;
    FSourceLine: Integer;
    FSaveChar: Char;
    FToken: Char;
    FStringDelimiter: Char;
    procedure ReadBuffer;
    procedure SkipBlanks;
  public
    constructor Create(Stream: TStream; StringDelimiter: Char);
    destructor Destroy; override;
    procedure Error(const Ident: string);
    procedure ErrorFmt(const Ident: string; const Args: array of const);
    procedure ErrorStr(const Message: string);
    function NextToken: Char;
    function SourcePos: Longint;
    function TokenFloat: Extended;
    function TokenInt: Int64;
    function TokenString: string;
    property SourceLine: Integer read FSourceLine;
    property Token: Char read FToken;
  end;

constructor TParser.Create(Stream: TStream; StringDelimiter: Char);
begin
  inherited Create;
  FStream := Stream;
  GetMem(FBuffer, ParseBufSize);
  FBuffer[0] := #0;
  FBufPtr := FBuffer;
  FBufEnd := FBuffer + ParseBufSize;
  FSourcePtr := FBuffer;
  FSourceEnd := FBuffer;
  FTokenPtr := FBuffer;
  FSourceLine := 1;
  FStringDelimiter := StringDelimiter;
  NextToken;
end;

destructor TParser.Destroy;
begin
  if FBuffer <> nil then
  begin
    FStream.Seek(Longint(FTokenPtr) - Longint(FBufPtr), 1);
    FreeMem(FBuffer, ParseBufSize);
  end;
end;

procedure TParser.Error(const Ident: string);
begin
  ErrorStr(Ident);
end;

procedure TParser.ErrorFmt(const Ident: string; const Args: array of const);
begin
  ErrorStr(Format(Ident, Args));
end;

procedure TParser.ErrorStr(const Message: string);
begin
//  raise EParserError.CreateResFmt(@SParseError, [Message, FSourceLine]);
end;

function TParser.NextToken: Char;
var
  P: PChar;
  NextCharIsNotControl: Boolean;
begin
  SkipBlanks;
  P := FSourcePtr;
  FTokenPtr := P;
  if P^ = FStringDelimiter then
  begin
    NextCharIsNotControl := False;
    repeat
      Inc(P);
      if P^ in [#0, #10, #13] then Error(SInvalidString)
      else if P^ = '\' then
        NextCharIsNotControl := True
      else if (not NextCharIsNotControl) and (P^ = FStringDelimiter) then Break
      else if NextCharIsNotControl then NextCharIsNotControl := False;
    until False;
    FStringPtr := P;
    P := P + 1;
    FTokenPtr := FTokenPtr + 1;
    Result := toString;
  end
  else
    case P^ of
      'A'..'Z', 'a'..'z', '_':
      begin
        Inc(P);
        while P^ in ['A'..'Z', 'a'..'z', '0'..'9', '_'] do Inc(P);
        Result := toSymbol;
      end;
      '$':
      begin
        Inc(P);
        while P^ in ['0'..'9', 'A'..'F', 'a'..'f'] do Inc(P);
        Result := toInteger;
      end;
      '-', '0'..'9':
      begin
        Inc(P);
        while P^ in ['0'..'9'] do Inc(P);
        Result := toInteger;
        while P^ in ['0'..'9', '.', 'e', 'E', '+', '-'] do
        begin
          Inc(P);
          Result := toFloat;
        end;
      end;
      else
        Result := P^;
        if Result <> toEOF then Inc(P);
    end;
  FSourcePtr := P;
  FToken := Result;
end;

procedure TParser.ReadBuffer;
var
  Count: Integer;
begin
  Inc(FOrigin, FSourcePtr - FBuffer);
  FSourceEnd[0] := FSaveChar;
  Count := FBufPtr - FSourcePtr;
  if Count <> 0 then Move(FSourcePtr[0], FBuffer[0], Count);
  FBufPtr := FBuffer + Count;
  Inc(FBufPtr, FStream.Read(FBufPtr[0], FBufEnd - FBufPtr));
  FSourcePtr := FBuffer;
  FSourceEnd := FBufPtr;
  if FSourceEnd = FBufEnd then
  begin
    FSourceEnd := LineStart(FBuffer, FSourceEnd - 1);
    if FSourceEnd = FBuffer then Error(SLineTooLong);
  end;
  FSaveChar := FSourceEnd[0];
  FSourceEnd[0] := #0;
end;

procedure TParser.SkipBlanks;
begin
  repeat
    case FSourcePtr^ of
      #0:
        begin
          ReadBuffer;
          if FSourcePtr^ = #0 then Exit;
          Continue;
        end;
      #10:
        Inc(FSourceLine);
      #33..#255:
        Exit;
    end;
    Inc(FSourcePtr);
  until False;
end;

function TParser.SourcePos: Longint;
begin
  Result := FOrigin + (FTokenPtr - FBuffer);
end;

function TParser.TokenFloat: Extended;
begin
  Result := StrToFloat(TokenString);
end;

function TParser.TokenInt: Int64;
begin
  Result := StrToInt64(TokenString);
end;

function TParser.TokenString: string;
var
  L: Integer;
begin
  Result := '';
  if FToken = toString then
    L := FStringPtr - FTokenPtr
  else
    L := FSourcePtr - FTokenPtr;
  SetString(Result, FTokenPtr, L);
end;

{ TPxXmlObject }

{ TPxXmlParam }

function TPxXmlParam.GetBoolean: Boolean;
begin
  Result := (AnsiCompareText(FValue, 'True') = 0) or (AnsiCompareText(FValue, 'Yes') = 0) or (AnsiCompareText(FValue, '1') = 0);
end;

procedure TPxXmlParam.SetBoolean(Value: Boolean);
begin
  if Value then FValue := '1'
  else FValue := '0';
end;

{$IFNDEF VER150}
function TryStrToFloat(S: String; var Value: Extended): Boolean;
begin
  try
    Value := StrToFloat(S);
    Result := True;
  except
    Result := False;
  end;
end;

function TryStrToInt64(S: String; var Value: Int64): Boolean;
var
  E: Integer;
begin
  Val(S, Value, E);
  Result := E = 0;
end;
{$ENDIF}

function TPxXmlParam.GetFloat: Extended;
begin
  Result := 0;
  if not TryStrToFloat(FValue, Result) then
    Result := 0;
end;

procedure TPxXmlParam.SetFloat(Value: Extended);
begin
  FValue := FloatToStr(Value);
end;

function TPxXmlParam.GetInteger: Int64;
begin
  Result := 0;
  if not TryStrToInt64(FValue, Result) then
    Result := 0;
end;

procedure TPxXmlParam.SetInteger(Value: Int64);
begin
  FValue := IntToStr(Value);
end;

function TPxXmlParam.GetString: String;
var
  I: Integer;
begin
  Result := '';
  I := 1;
  while I <= Length(FValue) do
  begin
    if FValue[I] = '\' then
    begin
      Inc(I);
      if I <= Length(FValue) then
        case FValue[I] of
          '''', '\', '"':
          begin
            Result := Result + FValue[I];
            Inc(I);
          end;
          '|':
          begin
            Result := Result + #13#10;
            Inc(I);
          end;
          else raise Exception.Create('Unknown control character ' + FValue[I] + ' !');
        end;
    end
    else
    begin
      Result := Result + FValue[I];
      Inc(I);
    end;
  end;
end;

procedure TPxXmlParam.SetString(Value: String);
var
  I: Integer;
begin
  I := 1;
  while I <= Length(Value) do
  begin
    case Value[I] of
      '''', '\', '"':
      begin
        Insert('\', Value, I);
        Inc(I, 2);
      end;
      #13:
      begin
        if (I = Length(Value)) and (Value[I + 1] <> #10) then Delete(Value, I, 1)
        else Delete(Value, I, 2);
        Insert('\|', Value, I);
        Inc(I, 2);
      end;
      else Inc(I);
    end;
  end;
  FValue := Value;
end;

{ Public declarations }

constructor TPxXmlParam.Create(AParent: TPxXmlItem);
begin
  inherited Create;
  FParent := AParent;
  if Assigned(Parent) then
    Parent.Params.Add(Self);
end;

destructor TPxXmlParam.Destroy;
begin
  if Assigned(Parent) then
    Parent.Params.Remove(Self);
  inherited Destroy;
end;

function TPxXmlParam.IsParamName(ParamName: String): Boolean;
begin
  Result := AnsiCompareText(FName, ParamName) = 0;
end;

procedure TPxXmlParam.StoreStream(Stream: TStream);
var
  ResultString: String;
  procedure Enc(Buffer: PChar; var Index: Integer);
    function EncOne(Sym: Integer): Char;
    begin
      if Sym = 0 then Result := '`'
      else Result := Chr((Sym and 63) + Ord(' '));
    end;
  var
    C1, C2, C3, C4: Char;
  begin
    C1 := EncOne(Word(Buffer^) shr 2);
    C2 := EncOne(((Word(Buffer^) shl 4) and 48) or ((Word(Buffer[1]) shr 4) and 15));
    C3 := EncOne(((Word(Buffer[1]) shl 2) and 60) or ((Word(Buffer[2]) shr 6) and 3));
    C4 := EncOne(Word(Buffer[2]) and 63);
    ResultString[Index] := C1;
    ResultString[Index + 1] := C2;
    ResultString[Index + 2] := C3;
    ResultString[Index + 3] := C4;
    Inc(Index, 4);
  end;
var
  I, Index: Integer;
  TmpStream: TMemoryStream;
  P: ^Byte;
begin
  TmpStream := TMemoryStream.Create;
  TmpStream.CopyFrom(Stream, Stream.Size);

  ResultString := IntToStr(Stream.Size) + ';';
  Index := Length(ResultString) + 1;

  // align data to 4 bytes
  I := 0;
  while TmpStream.Size mod 4 <> 0 do
    TmpStream.Write(I, 1);

  SetLength(ResultString, Length(ResultString) + Trunc(TmpStream.Size * 1.34));

  // save to UU stream
  P := TmpStream.Memory;
  I := 0;
  while I < TmpStream.Size do
  begin
    Enc(PChar(P), Index);
    Inc(I, 3);
    Inc(P, 3);
  end;
  TmpStream.Free;

  if Index > 3 then
    SetLength(ResultString, Index);
  SetString(ResultString);
end;

procedure TPxXmlParam.RestoreStream(Stream: TStream);
var
  Length: Integer;
  function Dec(Sym: Char): Word;
  begin
    Dec := (Ord(Sym) - Ord(' ')) and $3F;
  end;
  procedure OutDec(Buffer: PChar);
  var
    C1, C2, C3: Char;
  begin
    C1 := Chr((Word(Dec(Buffer^)) shl 2) or (Word(Dec(Buffer[1])) shr 4));
    C2 := Chr((Word(Dec(Buffer[1])) shl 4) or (Word(Dec(Buffer[2])) shr 2));
    C3 := Chr((Word(Dec(Buffer[2])) shl 6) or (Word(Dec(Buffer[3]))));

    with Stream do
    begin
      if Size < Length then
        Write(C1, 1);
      if Size < Length then
        Write(C2, 1);
      if Size < Length then
        Write(C3, 1);
    end;
  end;
var
  I, P: Integer;
  S: String;
begin
  S := GetString;
  P := Pos(';', GetString);
  if P > 0 then
  begin
    Length := StrToInt(Copy(S, 1, P - 1));
    I := P + 1;
    while Stream.Size < Length do
    begin
      OutDec(@(Copy(S, I, 4)[1]));
      Inc(I, 4);
    end;
  end;
end;

{ TPxXmlParamList }

function TPxXmlParamList.GetItem(Index: Integer): TPxXmlParam;
begin
  Result := TObject(inherited Items[Index]) as TPxXmlParam;
end;

{ TPxXmlItem }

{ Private declarations }

function TPxXmlItem.GetParamCount: Integer;
begin
  Result := FParams.Count;
end;

function TPxXmlItem.GetItemCount: Integer;
begin
  Result := FItems.Count;
end;

function TPxXmlItem.GetThis: TPxXmlItem;
begin
  Result := Self;
end;

{ Public declarations }

constructor TPxXmlItem.Create(AParent: TPxXmlItem);
begin
  inherited Create;
  FParent := AParent;
  FParams := TPxXmlParamList.Create;
  FItems := TPxXmlItemList.Create;
  if Assigned(Parent) then
    Parent.Items.Add(Self);
end;

destructor TPxXmlItem.Destroy;
begin
  if Assigned(Parent) then
    Parent.Items.Remove(Self);
  while FParams.Count > 0 do
    FParams[FParams.Count - 1].Free;
  FParams.Free;
  while FItems.Count > 0 do
    FItems[FItems.Count - 1].Free;
  FItems.Free;
  inherited Destroy;
end;

function TPxXmlItem.GetItemByName(ItemName: String): TPxXmlItem;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FItems.Count - 1 do
  begin
    Result := FItems[I];
    if AnsiCompareText(Result.Name, ItemName) = 0 then Break
    else Result := nil;
  end;
  if not Assigned(Result) then
  begin
    Result := TPxXmlItem.Create(Self);
    Result.FName := ItemName;
  end;
end;

function TPxXmlItem.HasItem(ItemName: String): Boolean;
var
  I: Integer;
  XmlItem: TPxXmlItem;
begin
  Result := False;
  for I := 0 to FItems.Count - 1 do
  begin
    XmlItem := FItems[I];
    if AnsiCompareText(XmlItem.Name, ItemName) = 0 then
    begin
      Result := True;
      Break;
    end;
  end;
end;

function TPxXmlItem.GetParamByName(ParamName: String): TPxXmlParam;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FParams.Count - 1 do
  begin
    Result := FParams[I];
    if AnsiCompareText(Result.Name, ParamName) = 0 then Break
    else Result := nil;
  end;
  if not Assigned(Result) then
  begin
    Result := TPxXmlParam.Create(Self);
    Result.FName := ParamName;
  end;
end;

function TPxXmlItem.GetParamByNameS(ParamName: String): String;
begin
  Result := GetParamByName(ParamName).AsString;
end;

function TPxXmlItem.HasParam(ParamName: String): Boolean;
var
  I: Integer;
  XmlParam: TPxXmlParam;
begin
  Result := False;
  for I := 0 to FParams.Count - 1 do
  begin
    XmlParam := FParams[I];
    if AnsiCompareText(XmlParam.Name, ParamName) = 0 then
    begin
      Result := True;
      Break;
    end;
  end;
end;

function TPxXmlItem.IsItemName(ItemName: String): Boolean;
begin
  Result := AnsiCompareText(FName, ItemName) = 0;
end;

{ TPxXmlItemList }

function TPxXmlItemList.GetItem(Index: Integer): TPxXmlItem;
begin
  Result := TObject(inherited Items[Index]) as TPxXmlItem;
end;

procedure TPxXmlItemList.SetItem(Index: Integer; Value: TPxXmlItem);
begin
  inherited Items[Index] := Value;
end;

{ TPxXmlValue }

{ Private declarations }

function TPxXmlValue.GetBoolean: Boolean;
begin
  Result := (AnsiCompareText(FValue, 'True') = 0) or (AnsiCompareText(FValue, 'Yes') = 0) or (AnsiCompareText(FValue, '1') = 0);
end;

procedure TPxXmlValue.SetBoolean(Value: Boolean);
begin
  if Value then FValue := '1'
  else FValue := '0';
end;

function TPxXmlValue.GetFloat: Extended;
begin
  try
    Result := StrToFloat(FValue);
  except
    Result := 0;
  end;
end;

procedure TPxXmlValue.SetFloat(Value: Extended);
begin
  FValue := FloatToStr(Value);
end;

function TPxXmlValue.GetInteger: Int64;
begin
  try
    Result := StrToInt64(FValue);
  except
    Result := 0;
  end;
end;

procedure TPxXmlValue.SetInteger(Value: Int64);
begin
  FValue := IntToStr(Value);
end;

function TPxXmlValue.GetString: String;
var
  I: Integer;
begin
  Result := '';
  I := 1;
  while I <= Length(FValue) do
  begin
    if FValue[I] = '\' then
    begin
      Inc(I);
      if I <= Length(FValue) then
        case FValue[I] of
          '''', '\':
          begin
            Result := Result + FValue[I];
            Inc(I);
          end;
          '|':
          begin
            Result := Result + #13#10;
            Inc(I);
          end;
          else raise Exception.Create('Unknown control character ' + FValue[I] + ' !');
        end;
    end
    else
    begin
      Result := Result + FValue[I];
      Inc(I);
    end;
  end;
end;

procedure TPxXmlValue.SetString(Value: String);
var
  I: Integer;
begin
  I := 1;
  while I <= Length(Value) do
  begin
    case Value[I] of
      '''', '\':
      begin
        Insert('\', Value, I);
        Inc(I, 2);
      end;
      #13:
      begin
        if (I = Length(Value)) and (Value[I + 1] <> #10) then Delete(Value, I, 1)
        else Delete(Value, I, 2);
        Insert('\|', Value, I);
        Inc(I, 2);
      end;
      else Inc(I);
    end;
  end;
  FValue := Value;
end;

{ Public declarations }

constructor TPxXmlValue.Create(AParent: TPxXmlProperty);
begin
  inherited Create;
  FParent := AParent;
  if Assigned(Parent) then
    Parent.Values.Add(Self);
end;

destructor TPxXmlValue.Destroy;
begin
  if Assigned(Parent) then
    Parent.Values.Remove(Self);
  inherited Destroy;
end;

function TPxXmlValue.IsValueName(ValueName: String): Boolean;
begin
  Result := AnsiCompareText(Name, ValueName) = 0;
end;

{ TPxXmlValueList }

{ Private declarations }

function TPxXmlValueList.GetItem(Index: Integer): TPxXmlValue;
begin
  Result := TObject(inherited Items[Index]) as TPxXmlValue;
end;

{ TPxXmlProperty }

constructor TPxXmlProperty.Create;
begin
  inherited Create;
  FValues := TPxXmlValueList.Create;
end;

destructor TPxXmlProperty.Destroy;
begin
  while Values.Count > 0 do
    Values[0].Free;
  Values.Free;
  inherited Destroy;
end;

function TPxXmlProperty.GetValueByName(ParamName: String): TPxXmlValue;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FValues.Count - 1 do
  begin
    Result := FValues[I];
    if AnsiCompareText(Result.Name, ParamName) = 0 then Break
    else Result := nil;
  end;
  if not Assigned(Result) then
  begin
    Result := TPxXmlValue.Create(Self);
    Result.FName := ParamName;
  end;
end;

function TPxXmlProperty.GetValueByNameS(ParamName: String): String;
begin
  Result := GetValueByName(ParamName).AsString;
end;

function TPxXmlProperty.HasValue(ParamName: String): Boolean;
var
  I: Integer;
  XmlValue: TPxXmlValue;
begin
  Result := False;
  for I := 0 to FValues.Count - 1 do
  begin
    XmlValue := FValues[I];
    if AnsiCompareText(XmlValue.Name, ParamName) = 0 then
    begin
      Result := True;
      Break;
    end;
  end;
end;

function TPxXmlProperty.IsPropertyName(ItemName: String): Boolean;
begin
  Result := AnsiCompareText(FName, Name) = 0;
end;

{ TPxXmlPropertyList }

{ Private declarations }

function TPxXmlPropertyList.GetByName(Name: String): TPxXmlProperty;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Count - 1 do
    if AnsiCompareText(Items[I].Name, Name) = 0 then
    begin
      Result := Items[I];
      Break;
    end;
  if not Assigned(Result) then
  begin
    Result := TPxXmlProperty.Create;
    Result.Name := Name;
    Add(Result);
  end;
end;

function TPxXmlPropertyList.GetItem(Index: Integer): TPxXmlProperty;
begin
  Result := TObject(inherited Items[Index]) as TPxXmlProperty;
end;

{ Public declarations }

function TPxXmlPropertyList.PropertyExists(Name: String): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to Count - 1 do
    if AnsiCompareText(Items[I].Name, Name) = 0 then
    begin
      Result := True;
      Break;
    end;
end;

{ TPxXmlFile }

{ Private declaratinos }

procedure TPxXmlFile.Parse(Stream: TStream);
var
  Parser: TParser;
  XmlItem: TPxXmlItem;
  XmlParam: TPxXmlParam;
  XmlProp: TPxXmlProperty;
  XmlValue: TPxXmlValue;
  ParamList: Boolean;
  Comment: String;
begin
  if Assigned(FXmlRoot) then
    FreeAndNil(FXmlRoot);

  XmlItem := nil; ParamList := False;
  Parser := TParser.Create(Stream, '"');
  repeat
    if Parser.TokenString = '<' then
    begin
      Parser.NextToken;
      if Parser.TokenString = '/' then
      begin
        // end of item
        Parser.NextToken;
        if (Parser.Token = toSymbol) and (AnsiCompareText(Parser.TokenString, XmlItem.Name) = 0) then XmlItem := XmlItem.Parent
        else Parser.ErrorStr('Fotter for ' + XmlItem.Name + ' is invalid');
      end
      else if Parser.TokenString = '!' then
      begin
        Parser.NextToken;
        if Parser.TokenString = '--' then
        begin
          Comment := '';
          while Copy(Comment, Length(Comment) - 2, 3) <> '-->' do
          begin
            if Parser.NextToken = toEOF then raise EParserError.Create('Comment not closed !');
            Comment := Comment + Parser.TokenString;
          end;
        end
        else Parser.ErrorStr('Invalid comment');
      end
      else if Parser.TokenString = '?' then
      begin
        if Assigned(FXmlRoot) then Parser.ErrorStr('Invalid Xml parameter definition');

        XmlProp := TPxXmlProperty.Create;
        XmlProperties.Add(XmlProp);
        Parser.NextToken;
        repeat
          XmlProp.Name := Parser.TokenString;
          Parser.NextToken;
          if Parser.Token <> '-' then Break;
        until False;

        repeat
          if Parser.Token = toSymbol then
          begin
            XmlValue := TPxXmlValue.Create(XmlProp);
            XmlValue.Name := Parser.TokenString;
            if Parser.NextToken <> '=' then Parser.ErrorStr('Invalid Xml parameter definition');
            if Parser.NextToken <> toString then Parser.ErrorStr('No param value specified');
            XmlValue.Value := Parser.TokenString;
          end;
          Parser.NextToken;
        until Parser.Token = '?';
        Parser.NextToken;
      end
      else
      begin
        // new subitem
        if Parser.Token <> toSymbol then Parser.ErrorStr('Invalid item identifier');
        if XmlItem = nil then
        begin
          XmlItem := TPxXmlItem.Create(XmlItem);
          FXmlRoot := XmlItem;
        end
        else XmlItem := TPxXmlItem.Create(XmlItem);
        XmlItem.Name := Parser.TokenString;
        ParamList := True;
      end
    end
    else if Parser.TokenString = '/' then
    begin
      // end of item
      Parser.NextToken;
      if Parser.TokenString = '>' then
      begin
        XmlItem := XmlItem.Parent;
        ParamList := False;
      end
      else Parser.ErrorStr('Invalid end of item');
    end
    else if Parser.TokenString = '>' then
      ParamList := False
    else if ParamList then
    begin
      // param
      if Parser.Token <> toSymbol then Parser.ErrorStr('Invalid param name');
      XmlParam := TPxXmlParam.Create(XmlItem);
      XmlParam.Name := Parser.TokenString;
      if Parser.NextToken <> '=' then
        Parser.ErrorStr('Invalid Xml parameter definition');
      if Parser.NextToken <> toString then Parser.ErrorStr('No param value specified');
      XmlParam.Value := Parser.TokenString;
    end
    else Parser.ErrorStr('Parse error');
  until Parser.NextToken = toEOF;
  Parser.Free;
  ResolveIncludes;
end;

procedure TPxXmlFile.DisconnectRoot;
begin
  FXmlRoot := nil;
end;

procedure TPxXmlFile.ResolveIncludes;
  procedure Resolve(XmlItem: TPxXmlItem);
  var
    I: Integer;
    X: TPxXmlFile;
    Item: TPxXmlItem;
    FileName: String;
  begin
    I := 0;
    while I < XmlItem.Items.Count do
    begin
      Item := XmlItem.Items[I];
      if Item.IsItemName('Include') then
      begin
        FileName := Item.GetParamByNameS('FileName');
        if FileName = '' then // no filename has been given
          raise Exception.Create('Included file has no file name !');
        if not FileExists(FileName) then // given filename does not point to an existing file
          raise Exception.CreateFmt('Included file "%s" not found', [Item.GetParamByNameS('FileName')]);
        // create the included file
        X := TPxXmlFile.Create(True);
        // read the included file
        X.ReadFile(Item.GetParamByNameS('FileName'));
        // free the "Include" item
        XmlItem.Items[I].FParent := nil; // a trick,...
        XmlItem.Items[I].Free;
        XmlItem.Items[I] := X.XmlItem;
        XmlItem.Items[I].FParent := XmlItem; // a trick,...
        // disconnect the root from file object
        X.DisconnectRoot;
        // free the included file
        X.Free;
      end
      else
      begin
        Resolve(XmlItem.Items[I]);
        Inc(I);
      end;
    end;
  end;
begin
  if not FResolveIncludes then Exit;
  Resolve(XmlItem);
end;

{ Public declarations }

constructor TPxXmlFile.Create(ResolveIncludes: Boolean = True; CreateRoot: Boolean = False);
begin
  inherited Create;
  FXmlProperties := TPxXmlPropertyList.Create;
  if CreateRoot then
  begin
    FXmlRoot := TPxXmlItem.Create(nil);
    FStatus := psLoaded;
    FStatusMessage := 'Loaded';
  end
  else
  begin
    FXmlRoot := nil;
    FStatus := psNotLoaded;
    FStatusMessage := 'Not loaded';
  end;
  FResolveIncludes := ResolveIncludes;
end;

destructor TPxXmlFile.Destroy;
var
  I: Integer;
begin
  for I := 0 to FXmlProperties.Count - 1 do
    FXmlProperties[I].Free;
  FXmlProperties.Free;
  if Assigned(FXmlRoot) then
    FXmlRoot.Free;
  inherited Destroy;
end;

function TPxXmlFile.GetNextInternalFileName(Base, Ext: string): string;
var
  I: Integer;
  Value: ^Integer;
begin
  if (Ext = '') then
    Ext := '.dat';
  if Ext[1] <> '.' then
    Ext := '.' + Ext;

  Value := nil;
  for I := 0 to Length(FInternalFileNameCounter) - 1 do
    if AnsiCompareText(Ext, FInternalFileNameCounter[I].Extension) = 0 then
    begin
      Value := @FInternalFileNameCounter[I].Value;
      Break;
    end;
  if not Assigned(Value) then
  begin
    SetLength(FInternalFileNameCounter, Length(FInternalFileNameCounter) + 1);
    with FInternalFileNameCounter[Length(FInternalFileNameCounter) - 1] do
    begin
      Value := 0;
      Extension := Ext;
    end;
    Value := @FInternalFileNameCounter[Length(FInternalFileNameCounter) - 1].Value;
  end;

  Inc(Value^);
  Result :=
    // file path
    ExtractFilePath(Base) +
    // file core with incremented counter
    Copy(ExtractFileName(Base), 1, Length(ExtractFileName(Base)) - Length(ExtractFileExt(Base))) + IntToStr(Value^) +
    // extension
    Ext;
end;

procedure TPxXmlFile.ReadFile(FileName: String);
var
  S: TStream;
begin
  S := TFileStream.Create(FileName, fmOpenRead);
  ReadStream(S);
  S.Free;
end;

procedure TPxXmlFile.ReadStrings(Strings: TStrings);
var
  S: TStream;
begin
  S := TMemoryStream.Create;
  Strings.SaveToStream(S);
  S.Position := 0;
  ReadStream(S);
  S.Free;
end;

procedure TPxXmlFile.ReadStream(Stream: TStream);
begin
  try
    Parse(Stream);
    FStatus := psLoaded;
    FStatusMessage := 'OK';
  except
    on E: Exception do
    begin
      if Assigned(FXmlRoot) then FreeAndNil(FXmlRoot);
      FStatus := psError;
      FStatusMessage := E.Message;
    end;
  end;
end;

procedure TPxXmlFile.GenerateTree(XmlItem: TPxXmlItem; Strings: TStrings; Ident: String);
var
  I: Integer;
  XmlParam: TPxXmlParam;
  S: String;
begin
  S := '';
  for I := 0 to XmlItem.Params.Count - 1 do
  begin
    XmlParam := XmlItem.Params[I];
    S := S + ' ' + XmlParam.Name + '="' + XmlParam.Value + '"';
  end;

  if XmlItem.Items.Count = 0 then
  begin
    Strings.Add(Ident + '<' + XmlItem.Name + S + '/>');
    if Ident = '  ' then
      Strings.Add('');
  end
  else
  begin
    Strings.Add(Ident + '<' + XmlItem.Name + S + '>');
    for I := 0 to XmlItem.Items.Count - 1 do
      GenerateTree(XmlItem.Items[I], Strings, Ident + '  ');
    Strings.Add(Ident + '</' + XmlItem.Name + '>');
    if Ident = '  ' then
      Strings.Add('');
  end;
end;

procedure TPxXmlFile.WriteFile(FileName: String);
var
  Strings: TStrings;
begin
  Strings := TStringList.Create;
  WriteStrings(Strings);
  Strings.SaveToFile(FileName);
  Strings.Free;
end;

procedure TPxXmlFile.WriteStrings(Strings: TStrings);
begin
  Strings.BeginUpdate;
  Strings.Clear;
  GenerateTree(FXmlRoot, Strings, '');
  Strings.EndUpdate;
end;

procedure TPxXmlFile.WriteStream(Stream: TStream);
var
  Strings: TStrings;
begin
  Strings := TStringList.Create;
  WriteStrings(Strings);
  Strings.SaveToStream(Stream);
  Strings.Free;
end;

end.

