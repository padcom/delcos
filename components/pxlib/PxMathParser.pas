// ----------------------------------------------------------------------------
// Unit        : PxMathParser.pas - a part of PxLib
// Author      : Fedor Koshevnikov, Igor Pavluk, Serge Korolev and 
//               Matthias Hryniszak
// Date        : 2004-03-27
// Version     : 1.0
// Description : Simply pass a string formula to GetFormulaValue() and you will 
//               receive result
// Changes log : 2004-03-27 - initial version
//               2004-03-27 - added support for functions that return a value out 
//                            of a string
//                          - added support for functions that convert values 
//                            (using ConvUtils and StdConvs units). A default 
//                            function for coverting units is added by default to 
//                            user-defined conversion functions.
//                          - stripped dependencies with other Rx units
//               2005-03-24 - incorporated into the PxLib
// ToDo        : Testing.
// ----------------------------------------------------------------------------

unit PxMathParser;

{$I PxDefines.inc}

interface

uses
  SysUtils, Classes,
{$IFDEF USE_UNIT_CONVERSIONS}
  ConvUtils, 
{$ENDIF}
  PxBase, PxResources;

type
  TPxMathParserFunc = (
    pfArcTan,
    pfCos,
    pfSin,
    pfTan,
    pfAbs,
    pfExp,
    pfLn,
    pfLog,
    pfSqrt,
    pfSqr,
    pfInt,
    pfFrac,
    pfTrunc,
    pfRound,
    pfArcSin,
    pfArcCos,
    pfSign,
    pfNot
  );

  EPxMathParserError = class(EPxException);

  TPxMathParserUserFunction = function(Value: Extended): Extended;
  TPxMathParserGetValueFunction = function(Value: String): Extended;
{$IFDEF USE_UNIT_CONVERSIONS}
  TPxMathParserConvertValueFunction = function(Value: Extended; BaseType, ResultType: TConvType): Extended;
{$ENDIF}

  TPxMathParser = class(TObject)
  private
    FCurPos: Cardinal;
    FParseText: string;
    function GetChar: Char;
    procedure NextChar;
    procedure SkipBlanks;
    function GetNumber(var AValue: Extended): Boolean;
    function GetConst(var AValue: Extended): Boolean;
    function GetFunction(var AValue: TPxMathParserFunc): Boolean;
    function GetUserFunction(var Index: Integer): Boolean;
    function GetGetValueFunction(var Index: Integer): Boolean;
{$IFDEF USE_UNIT_CONVERSIONS}
    function GetConvertValueFunction(var Index: Integer): Boolean;
{$ENDIF}
    function Term: Extended;
    function SubTerm: Extended;
    function Calculate: Extended;
    function GetString: String;
{$IFDEF USE_UNIT_CONVERSIONS}
    function GetConvType(Expect: Char): TConvType;
{$ENDIF}
  public
    function Exec(const AFormula: string): Extended;
    class procedure RegisterUserFunction(const Name: string; Proc: TPxMathParserUserFunction);
    class procedure UnregisterUserFunction(const Name: string);
    class procedure RegisterGetValueFunction(const Name: string; Proc: TPxMathParserGetValueFunction);
    class procedure UnregisterGetValueFunction(const Name: string);
{$IFDEF USE_UNIT_CONVERSIONS}
    class procedure RegisterConvertValueFunction(const Name: string; Proc: TPxMathParserConvertValueFunction);
    class procedure UnregisterConvertValueFunction(const Name: string);
{$ENDIF}
  end;

function GetFormulaValue(const Formula: string): Extended;

implementation

uses 
  Math;

const
  SpecialChars = [#0..' ', '+', '-', '/', '*', ')', '^', ';'];

  FuncNames: array[TPxMathParserFunc] of PChar = (
    'ARCTAN',
    'COS',
    'SIN',
    'TAN',
    'ABS',
    'EXP',
    'LN',
    'LOG',
    'SQRT',
    'SQR',
    'INT',
    'FRAC',
    'TRUNC',
    'ROUND',
    'ARCSIN',
    'ARCCOS',
    'SIGN',
    'NOT'
  );

{ Parser errors }

procedure InvalidCondition(Position: Integer; Str: String);
begin
  if Position <> -1 then
    raise EPxMathParserError.CreateFmt('Error near position %d: %s', [Position, Str])
  else
    raise EPxMathParserError.CreateFmt('Error: %s', [Str]);
end;

{ IntPower and Power functions are copied from Borland's MATH.PAS unit }

{ User defined functions }

type
  TFarUserFunction = TPxMathParserUserFunction;
  TFarGetValueFunction = TPxMathParserGetValueFunction;
{$IFDEF USE_UNIT_CONVERSIONS}
  TFarConvertValueFunction = TPxMathParserConvertValueFunction;
{$ENDIF}

var
  UserFuncList: TStrings;
  GetValueFuncList: TStrings;
{$IFDEF USE_UNIT_CONVERSIONS}
  ConvertValueFuncList: TStrings;
{$ENDIF}

function GetUserFuncList: TStrings;
begin
  if not Assigned(UserFuncList) then
  begin
    UserFuncList := TStringList.Create;
    with TStringList(UserFuncList) do
    begin
      Sorted := True;
      Duplicates := dupIgnore;
    end;
  end;
  Result := UserFuncList;
end;

procedure FreeUserFunc; 
begin
  UserFuncList.Free;
  UserFuncList := nil;
end;

function GetGetValueFuncList: TStrings;
begin
  if not Assigned(GetValueFuncList) then
  begin
    GetValueFuncList := TStringList.Create;
    with TStringList(GetValueFuncList) do
    begin
      Sorted := True;
      Duplicates := dupIgnore;
    end;
  end;
  Result := GetValueFuncList;
end;

procedure FreeGetValueFunc; 
begin
  GetValueFuncList.Free;
  GetValueFuncList := nil;
end;

{$IFDEF USE_UNIT_CONVERSIONS}
function GetConvertValueFuncList: TStrings;
begin
  if not Assigned(ConvertValueFuncList) then
  begin
    ConvertValueFuncList := TStringList.Create;
    with TStringList(ConvertValueFuncList) do
    begin
      Sorted := True;
      Duplicates := dupIgnore;
    end;
  end;
  Result := ConvertValueFuncList;
end;

procedure FreeConvertValueFunc; 
begin
  ConvertValueFuncList.Free;
  ConvertValueFuncList := nil;
end;
{$ENDIF}

{ TPxMathParser }

function TPxMathParser.GetChar: Char;
begin
  Result := FParseText[FCurPos];
end;

procedure TPxMathParser.NextChar;
begin
  Inc(FCurPos);
end;

procedure TPxMathParser.SkipBlanks;
begin
  while FParseText[FCurPos] in [' '] do Inc(FCurPos);
end;

function TPxMathParser.GetNumber(var AValue: Extended): Boolean;
var
  C: Char;
  SavePos: Cardinal;
  Code: Integer;
  IsHex: Boolean;
  TmpStr: string;
begin
  Result := False;
  C := GetChar;
  SavePos := FCurPos;
  TmpStr := '';
  IsHex := False;
  if C = '$' then
  begin
    TmpStr := C;
    NextChar;
    C := GetChar;
    while C in ['0'..'9', 'A'..'F', 'a'..'f'] do
    begin
      TmpStr := TmpStr + C;
      NextChar;
      C := GetChar;
    end;
    IsHex := True;
    Result := (Length(TmpStr) > 1) and (Length(TmpStr) <= 9);
  end
  else if C in ['+', '-', '0'..'9', '.', DecimalSeparator] then
  begin
    if (C in ['.', DecimalSeparator]) then
      TmpStr := '0' + '.'
    else
      TmpStr := C;
    NextChar;
    C := GetChar;
    if (Length(TmpStr) = 1) and (TmpStr[1] in ['+', '-']) and (C in ['.', DecimalSeparator]) then
      TmpStr := TmpStr + '0';
    while C in ['0'..'9', '.', 'E', 'e', DecimalSeparator] do
    begin
      if C = DecimalSeparator then
        TmpStr := TmpStr + '.'
      else
        TmpStr := TmpStr + C;
      if (C = 'E') then
      begin
        if (Length(TmpStr) > 1) and (TmpStr[Length(TmpStr) - 1] = '.') then
          Insert('0', TmpStr, Length(TmpStr));
        NextChar;
        C := GetChar;
        if (C in ['+', '-']) then
        begin
          TmpStr := TmpStr + C;
          NextChar;
        end;
      end
      else NextChar;
      C := GetChar;
    end;
    if (TmpStr[Length(TmpStr)] = '.') and (Pos('E', TmpStr) = 0) then
      TmpStr := TmpStr + '0';
    Val(TmpStr, AValue, Code);
    Result := (Code = 0);
  end;
  Result := Result and (FParseText[FCurPos] in SpecialChars);
  if Result then
  begin
    if IsHex then
      AValue := StrToInt(TmpStr)
    { else AValue := StrToFloat(TmpStr) };
  end
  else
  begin
    AValue := 0;
    FCurPos := SavePos;
  end;
end;

function TPxMathParser.GetConst(var AValue: Extended): Boolean;
begin
  Result := False;
  case FParseText[FCurPos] of
    'E':
      if FParseText[FCurPos + 1] in SpecialChars then
      begin
        AValue := Exp(1);
        Inc(FCurPos);
        Result := True;
      end;
    'P':
      if (FParseText[FCurPos + 1] = 'I') and (FParseText[FCurPos + 2] in SpecialChars) then
      begin
        AValue := Pi;
        Inc(FCurPos, 2);
        Result := True;
      end;
  end
end;

function TPxMathParser.GetUserFunction(var Index: Integer): Boolean;
var
  TmpStr: string;
  I: Integer;
begin
  Result := False;
  if (FParseText[FCurPos] in ['A'..'Z', 'a'..'z', '_']) and Assigned(UserFuncList) then
  begin
    with UserFuncList do
      for I := 0 to Count - 1 do
      begin
        TmpStr := Copy(FParseText, FCurPos, Length(Strings[I]));
        if (CompareText(TmpStr, Strings[I]) = 0) and (Objects[I] <> nil) then
        begin
          if FParseText[FCurPos + Cardinal(Length(TmpStr))] = '(' then
          begin
            Result := True;
            Inc(FCurPos, Length(TmpStr));
            Index := I;
            Exit;
          end;
        end;
      end;
  end;
  Index := -1;
end;

function TPxMathParser.GetGetValueFunction(var Index: Integer): Boolean;
var
  TmpStr: string;
  I: Integer;
begin
  Result := False;
  if (FParseText[FCurPos] in ['A'..'Z', 'a'..'z', '_']) and Assigned(GetValueFuncList) then
  begin
    with GetValueFuncList do
      for I := 0 to Count - 1 do
      begin
        TmpStr := Copy(FParseText, FCurPos, Length(Strings[I]));
        if (CompareText(TmpStr, Strings[I]) = 0) and (Objects[I] <> nil) then
        begin
          if FParseText[FCurPos + Cardinal(Length(TmpStr))] = '(' then
          begin
            Result := True;
            Inc(FCurPos, Length(TmpStr));
            Index := I;
            Exit;
          end;
        end;
      end;
  end;
  Index := -1;
end;

{$IFDEF USE_UNIT_CONVERSIONS}
function TPxMathParser.GetConvertValueFunction(var Index: Integer): Boolean;
var
  TmpStr: string;
  I: Integer;
begin
  Result := False;
  if (FParseText[FCurPos] in ['A'..'Z', 'a'..'z', '_']) and Assigned(ConvertValueFuncList) then
  begin
    with ConvertValueFuncList do
      for I := 0 to Count - 1 do
      begin
        TmpStr := Copy(FParseText, FCurPos, Length(Strings[I]));
        if (CompareText(TmpStr, Strings[I]) = 0) and (Objects[I] <> nil) then
        begin
          if FParseText[FCurPos + Cardinal(Length(TmpStr))] = '(' then
          begin
            Result := True;
            Inc(FCurPos, Length(TmpStr));
            Index := I;
            Exit;
          end;
        end;
      end;
  end;
  Index := -1;
end;
{$ENDIF}

function TPxMathParser.GetFunction(var AValue: TPxMathParserFunc): Boolean;
var
  I: TPxMathParserFunc;
  TmpStr: string;
begin
  Result := False;
  AValue := Low(TPxMathParserFunc);
  if FParseText[FCurPos] in ['A'..'Z', 'a'..'z', '_'] then
  begin
    for I := Low(TPxMathParserFunc) to High(TPxMathParserFunc) do
    begin
      TmpStr := Copy(FParseText, FCurPos, StrLen(FuncNames[I]));
      if CompareText(TmpStr, StrPas(FuncNames[I])) = 0 then
      begin
        AValue := I;
        if FParseText[FCurPos + Cardinal(Length(TmpStr))] = '(' then
        begin
          Result := True;
          Inc(FCurPos, Length(TmpStr));
          Break;
        end;
      end;
    end;
  end;
end;

function TPxMathParser.Term: Extended;
var
  Value: Extended;
  NoFunc: TPxMathParserFunc;
  UserFunc: Integer;
  Func: Pointer;
{$IFDEF USE_UNIT_CONVERSIONS}
  CT1, CT2: TConvType;
{$ENDIF}
begin
  if FParseText[FCurPos] = '(' then
  begin
    Inc(FCurPos);
    Value := Calculate;
    if FParseText[FCurPos] <> ')' then InvalidCondition(FCurPos, SParseNotCramp);
    Inc(FCurPos);
  end
  else
  begin
    if not GetNumber(Value) then
      if not GetConst(Value) then
        if GetUserFunction(UserFunc) then
        begin
          Inc(FCurPos);
          Func := UserFuncList.Objects[UserFunc];
          Value := TFarUserFunction(Func)(Calculate);
          if FParseText[FCurPos] <> ')' then
            InvalidCondition(FCurPos, SParseNotCramp);
          Inc(FCurPos);
        end
        else if GetGetValueFunction(UserFunc) then
        begin
          Inc(FCurPos);
          Func := GetValueFuncList.Objects[UserFunc];
          Value := TFarGetValueFunction(Func)(GetString);
          if FParseText[FCurPos] <> ')' then
            InvalidCondition(FCurPos, SParseNotCramp);
          Inc(FCurPos);
        end
{$IFDEF USE_UNIT_CONVERSIONS}
        else if GetConvertValueFunction(UserFunc) then
        begin
          Inc(FCurPos);
          Func := ConvertValueFuncList.Objects[UserFunc];
          Value := Calculate;
          CT1 := GetConvType(';');
          CT2 := GetConvType(')');
          Value := TFarConvertValueFunction(Func)(Value, CT1, CT2);
          if FParseText[FCurPos] <> ')' then
            InvalidCondition(FCurPos, SParseNotCramp);
          Inc(FCurPos);
        end
{$ENDIF}
        else if GetFunction(NoFunc) then
        begin
          Inc(FCurPos);
          Value := Calculate;
          try
            case NoFunc of
              pfArcTan:
                Value := ArcTan(Value);
              pfCos:
                Value := Cos(Value);
              pfSin:
                Value := Sin(Value);
              pfTan:
                if Cos(Value) = 0 then
                  InvalidCondition(FCurPos, SParseDivideByZero)
                else
                  Value := Sin(Value) / Cos(Value);
              pfAbs:
                Value := Abs(Value);
              pfExp:
                Value := Exp(Value);
              pfLn:
                if Value <= 0 then
                  InvalidCondition(FCurPos, SParseLogError)
                else
                  Value := Ln(Value);
              pfLog:
                if Value <= 0 then
                  InvalidCondition(FCurPos, SParseLogError)
                else
                  Value := Ln(Value) / Ln(10);
              pfSqrt:
                if Value < 0 then
                  InvalidCondition(FCurPos, SParseSqrError)
                else
                  Value := Sqrt(Value);
              pfSqr:
                Value := Sqr(Value);
              pfInt:
                Value := Round(Value);
              pfFrac:
                Value := Frac(Value);
              pfTrunc:
                Value := Trunc(Value);
              pfRound:
                Value := Round(Value);
              pfArcSin:
                if Value = 1 then
                  Value := Pi / 2
                else
                  Value := ArcTan(Value / Sqrt(1 - Sqr(Value)));
              pfArcCos:
                if Value = 1 then
                  Value := 0
                else
                  Value := Pi / 2 - ArcTan(Value / Sqrt(1 - Sqr(Value)));
              pfSign:
                if Value > 0 then
                  Value := 1
                else if Value < 0 then
                  Value := -1;
              pfNot:
                Value := not Trunc(Value);
            end;
          except
            on E: EParserError do
              raise
            else
              InvalidCondition(-1, SParseInvalidFloatOperation);
          end;
          if FParseText[FCurPos] <> ')' then
            InvalidCondition(FCurPos, SParseNotCramp);
          Inc(FCurPos);
        end
        else
          InvalidCondition(FCurPos, SParseSyntaxError);
  end;
  Result := Value;
end;

function TPxMathParser.SubTerm: Extended;
var
  Value: Extended;
begin
  Value := Term;
  while FParseText[FCurPos] in ['*', '^', '/'] do
  begin
    Inc(FCurPos);
    if FParseText[FCurPos - 1] = '*' then
      Value := Value * Term
    else if FParseText[FCurPos - 1] = '^' then
      Value := Power(Value, Term)
    else if FParseText[FCurPos - 1] = '/' then
      try
        Value := Value / Term;
      except
        InvalidCondition(FCurPos, SParseDivideByZero);
      end;
  end;
  Result := Value;
end;

function TPxMathParser.Calculate: Extended;
var
  Value: Extended;
begin
  Value := SubTerm;
  while FParseText[FCurPos] in ['+', '-'] do
  begin
    Inc(FCurPos);
    if FParseText[FCurPos - 1] = '+' then
      Value := Value + SubTerm
    else
      Value := Value - SubTerm;
  end;
  if not (FParseText[FCurPos] in [#0, ')', '>', '<', '=', ',', ';']) then
    InvalidCondition(FCurPos, SParseSyntaxError);
  Result := Value;
end;

function TPxMathParser.GetString: String;
begin
  Result := '';
  SkipBlanks;
  if not (FParseText[FCurPos] in ['''']) then
    InvalidCondition(FCurPos, SParseSyntaxError);
  Inc(FCurPos);
  SkipBlanks;
  while not (FParseText[FCurPos] in [#0, '''']) do
  begin
    Result := Result + FParseText[FCurPos];
    Inc(FCurPos);
  end;
  if not (FParseText[FCurPos] in ['''']) then
    InvalidCondition(FCurPos, SParseSyntaxError);
  Inc(FCurPos);
  SkipBlanks;
  if not (FParseText[FCurPos] in [')']) then
    InvalidCondition(FCurPos, SParseSyntaxError);
end;

{$IFDEF USE_UNIT_CONVERSIONS}
function TPxMathParser.GetConvType(Expect: Char): TConvType;
var
  S: String;
begin
  S := '';
  SkipBlanks;
  if not (FParseText[FCurPos] in [';']) then
    InvalidCondition(FCurPos, SParseSyntaxError);
  Inc(FCurPos);
  SkipBlanks;
  while FParseText[FCurPos] in ['A'..'Z', 'a'..'z', '0'..'9'] do
  begin
    S := S + FParseText[FCurPos];
    Inc(FCurPos);
  end;
  SkipBlanks;
  if not (FParseText[FCurPos] in [Expect, #0]) then
    InvalidCondition(FCurPos, SParseSyntaxError);

  if S = '' then
    Result := 65535
  else
    StrToConvUnit('1 ' + S, Result);
end;
{$ENDIF}

function TPxMathParser.Exec(const AFormula: string): Extended;
var
  I, J: Integer;
begin
  J := 0;
  Result := 0;
  FParseText := '';
  for I := 1 to Length(AFormula) do
  begin
    case AFormula[I] of
      '(':
        Inc(J);
      ')':
        Dec(J);
    end;
    if AFormula[I] > ' ' then
      FParseText := FParseText + UpCase(AFormula[I]);
  end;
  if J = 0 then
  begin
    FCurPos := 1;
    FParseText := FParseText + #0;
    if (FParseText[1] in ['-', '+']) then
      FParseText := '0' + FParseText;
    Result := Calculate;
  end
  else
    InvalidCondition(FCurPos, SParseNotCramp);
end;

class procedure TPxMathParser.RegisterUserFunction(const Name: string; Proc: TPxMathParserUserFunction);
var
  I: Integer;
begin
  if (Length(Name) > 0) and (Name[1] in ['A'..'Z', 'a'..'z', '_']) then
  begin
    if not Assigned(Proc) then
      UnregisterUserFunction(Name)
    else
    begin
      with GetUserFuncList do
      begin
        I := IndexOf(Name);
        if I < 0 then I := Add(Name);
        Objects[I] := @Proc;
      end;
    end;
  end
  else InvalidCondition(-1, SParseSyntaxError);
end;

class procedure TPxMathParser.UnregisterUserFunction(const Name: string);
var
  I: Integer;
begin
  if Assigned(UserFuncList) then
    with UserFuncList do
    begin
      I := IndexOf(Name);
      if I >= 0 then
        Delete(I);
      if Count = 0 then
        FreeUserFunc;
    end;
end;

class procedure TPxMathParser.RegisterGetValueFunction(const Name: string; Proc: TPxMathParserGetValueFunction);
var
  I: Integer;
begin
  if (Length(Name) > 0) and (Name[1] in ['A'..'Z', 'a'..'z', '_']) then
  begin
    if not Assigned(Proc) then
      UnregisterGetValueFunction(Name)
    else
    begin
      with GetGetValueFuncList do
      begin
        I := IndexOf(Name);
        if I < 0 then I := Add(Name);
        Objects[I] := @Proc;
      end;
    end;
  end
  else InvalidCondition(-1, SParseSyntaxError);
end;

class procedure TPxMathParser.UnregisterGetValueFunction(const Name: string);
var
  I: Integer;
begin
  if Assigned(GetValueFuncList) then
    with GetValueFuncList do
    begin
      I := IndexOf(Name);
      if I >= 0 then
        Delete(I);
      if Count = 0 then
        FreeGetValueFunc;
    end;
end;

{$IFDEF USE_UNIT_CONVERSIONS}
class procedure TPxMathParser.RegisterConvertValueFunction(const Name: string; Proc: TPxMathParserConvertValueFunction);
var
  I: Integer;
begin
  if (Length(Name) > 0) and (Name[1] in ['A'..'Z', 'a'..'z', '_']) then
  begin
    if not Assigned(Proc) then
      UnregisterConvertValueFunction(Name)
    else
    begin
      with GetConvertValueFuncList do
      begin
        I := IndexOf(Name);
        if I < 0 then I := Add(Name);
        Objects[I] := @Proc;
      end;
    end;
  end
  else InvalidCondition(-1, SParseSyntaxError);
end;

class procedure TPxMathParser.UnregisterConvertValueFunction(const Name: string);
var
  I: Integer;
begin
  if Assigned(ConvertValueFuncList) then
    with ConvertValueFuncList do
    begin
      I := IndexOf(Name);
      if I >= 0 then
        Delete(I);
      if Count = 0 then
        FreeGetValueFunc;
    end;
end;
{$ENDIF}

{ *** }

function GetFormulaValue(const Formula: string): Extended;
begin
  with TPxMathParser.Create do
    try
      Result := Exec(Formula);
    finally
      Free;
    end;
end;

{$IFDEF USE_UNIT_CONVERSIONS}
function ConvertValueUnit(Value: Extended; Base, Dest: TConvType): Extended;
begin
  Result := 0;
  if (Base = 65535) and (Dest = 65535) then
    InvalidCondition(-1, SAtLeastOneUnitMustBeSpecified)
  else if Base = 65535 then
    Result := ConvertTo(Value, Dest)
  else if Dest = 65535 then
    Result := ConvertFrom(Base, Value)
  else
    Result := ConvertTo(ConvertFrom(Base, Value), Dest);
end;
{$ENDIF}

initialization
  UserFuncList := nil;
  GetValueFuncList := nil;
{$IFDEF USE_UNIT_CONVERSIONS}
  ConvertValueFuncList := nil;
//  TMathParser.RegisterConvertValueFunction('Convert', @ConvertValueUnit);
{$ENDIF}

finalization
  FreeUserFunc;
  FreeGetValueFunc;
{$IFDEF USE_UNIT_CONVERSIONS}
  FreeConvertValueFunc;
{$ENDIF}

end.
