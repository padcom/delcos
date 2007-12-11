//-----------------------------------------------------------------------------
//
//  Copyright 1982-2001 Pervasive Software Inc. All Rights Reserved
//
//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
//
//  BTRCLASS.PAS
//
//  This software is part of the Pervasive Software Developer Kit.
//
//  This source code is only intended as a supplement to the
//  Pervasive.SQL documentation; see that documentation for detailed
//  information regarding the use of Pervasive.SQL.
//
//  This unit illustrates using a simple Delphi class to 'wrap' the
//  Pervasive.SQL Transactional API.
//
//-----------------------------------------------------------------------------

unit BtrClass;

interface

uses
  SysUtils, BtrConst, BtrAPI32;

const
  // Keep path <= 64 for SQL compatibility
  BTRCLASS_GENERAL_ERROR = -1;

type
  TBtrvFile = class(TObject)
  private
    FStatus: SmallInt;
    FFileOpen: Boolean;
    FPosBlock: POS_BLOCK_T;
    FFilePath: String[MAX_FILE_NAME_LENGTH];
    FKeyBuffer: array[0..MAX_KEY_SIZE - 1] of Char;
    FDataLength: Word;
    FKeyNumber: SmallInt;
    FDataBuffer: PChar;
    function CallBtrv(Op: SmallInt): SmallInt;
  public
    constructor Create;        
    destructor Destroy; override;
      
    procedure SetFilePath(FileName: String);
    procedure SetDataBuffer(Buffer: Pointer);
    procedure SetDataLength(DataLength: SmallInt);
    function  SetKey(Key: SmallInt) : SmallInt;
    procedure ClearKeyBuffer;
    procedure PutKeyInfo(Src: PChar; Start, Size: SmallInt);
    function  MakeDataBuffer(Size: Word) : Boolean;

    function Open: SmallInt;
    function Close: SmallInt;
    function GetFirst: SmallInt;
    function GetEqual: SmallInt;
    function GetNext: SmallInt;
    function GetLast: SmallInt;
    function GetGE: SmallInt;
    function GetGT: SmallInt;
    function GetLE: SmallInt;
    function GetLT: SmallInt;
    function GetPosition(var Position: Longint): SmallInt;
    function GetDirect(Position: Longint): SmallInt;
    function GetPrev: SmallInt;
    function Update: SmallInt;
    function Delete: SmallInt;
    function Insert: SmallInt;
    function IsOpen: Boolean;
    function ResetBtrv: SmallInt;
    function GetLastStatus: SmallInt;
    function GetSpecs(var Specs: FILE_CREATE_BUFFER_T): SmallInt;
    function Recreate: SmallInt;
  end;

implementation

function Max(A, B: integer): Integer;
begin
  if A >= B then 
    Result := A
  else 
    Result := B;
end;

{ TBtrvFile }

{ Private declarations }

function TBtrvFile.CallBtrv(Op: SmallInt): SmallInt;
begin
  if FDataBuffer <> nil then 
  begin
    // Status gets set and returned on every call
    FStatus := BTRV(Op, FPosBlock, FDataBuffer^, FDataLength, FKeyBuffer, FKeyNumber);
    Result := FStatus;
  end 
  else 
    Result := BTRCLASS_GENERAL_ERROR;
end;

{ Public declarations }

constructor TBtrvFile.Create;
begin
  inherited Create;
  FFilePath := '';
  FillChar(FPosBlock, SizeOf(FPosBlock), #0);
  FillChar(FKeyBuffer, SizeOf(FKeyBuffer), #0);
  FDataBuffer := nil;
  FDataLength := 0;
  FKeyNumber := 0;
  FFileOpen := False;
end;

destructor TBtrvFile.Destroy;
begin
  if FFileOpen then
    Close;
  inherited Destroy;
end;
                    
procedure TBtrvFile.SetFilePath(FileName: String);
begin
  FFilePath := FileName;
end;

procedure TBtrvFile.SetDataBuffer(Buffer: Pointer);
begin
  FDataBuffer := Buffer;
end;

procedure TBtrvFile.SetDataLength(DataLength: SmallInt);
begin
  FDataLength := DataLength;
end;

function TBtrvFile.SetKey(Key: SmallInt) : SmallInt;
begin
  Result := FKeyNumber;
  FKeyNumber := Key;
end;

procedure TBtrvFile.ClearKeyBuffer;
begin
  FillChar(FKeyBuffer, SizeOf(FKeyBuffer), #0);
end;

procedure TBtrvFile.PutKeyInfo(Src: pchar; Start, Size: SmallInt);
var
  I, J: SmallInt;
begin
  if Src <> nil then 
  begin
    J := 0;
    //Move(FKeyBuffer[Start], Src, Size);
    for I := Start to Start + Size do 
    begin
      FKeyBuffer[I] := Src[J];
      Inc(J);
    end;
  end;
end;

function TBtrvFile.MakeDataBuffer(Size: Word): Boolean;
var
  OK: Boolean;
  P : PChar;
begin
  OK := True;
  P  := nil;

  // allocate memory of Size bytes
  try
    GetMem(P, Size);
  except
    OK := False;
  end;
  if OK then
    FDataBuffer := P;
  Result := OK;
end;

function TBtrvFile.Open: SmallInt;
begin
  Result := BTRCLASS_GENERAL_ERROR;
  if (FFilePath <> '') then 
  begin
    FillChar(FKeyBuffer, SizeOf(FKeyBuffer), #0);
    Move(FFilePath[1], FKeyBuffer, Byte(FFilePath[0]));
    CallBtrv(B_OPEN);
    if FStatus = B_NO_ERROR then
      FFileOpen := True;
    Result := FStatus;
  end;
end;

function TBtrvFile.Close: SmallInt;
begin
  CallBtrv(B_CLOSE);
  FFileOpen := False;
  Result := FStatus;
end;

function TBtrvFile.GetFirst: SmallInt;
begin
  CallBtrv(B_GET_FIRST);
  Result := FStatus;
end;

function TBtrvFile.GetEqual: SmallInt;
begin
  CallBtrv(B_GET_EQUAL);
  Result := FStatus;
end;

function TBtrvFile.GetNext: SmallInt;
begin
  CallBtrv(B_GET_NEXT);
  Result := FStatus;
end;

function TBtrvFile.GetLast: SmallInt;
begin
  CallBtrv(B_GET_LAST);
  Result := FStatus;
end;

function TBtrvFile.GetGE: SmallInt;
begin
  CallBtrv(B_GET_GE);
  Result := FStatus;
end;

function TBtrvFile.GetGT: SmallInt;
begin
  CallBtrv(B_GET_GT);
  Result := FStatus;
end;

function TBtrvFile.GetLE: SmallInt;
begin
  CallBtrv(B_GET_LE);
  Result := FStatus;
end;

function TBtrvFile.GetLT: SmallInt;
begin
  CallBtrv(B_GET_LT);
  Result := FStatus;
end;

function TBtrvFile.GetDirect(Position: Longint): SmallInt;
begin
  FillChar(FDataBuffer^, FDataLength, #0);
  Move(Position, FDataBuffer^, SizeOf(Position));
  CallBtrv(B_GET_DIRECT);
  Result := FStatus;
end;

function TBtrvFile.GetPrev: SmallInt;
begin
  CallBtrv(B_GET_PREVIOUS);
  Result := FStatus;
end;

function TBtrvFile.IsOpen: Boolean;
begin
  Result := FFileOpen;
end;

function TBtrvFile.GetPosition(var Position: Longint): SmallInt;
var
  SaveLength: Longint;
  SaveBuffer: PChar;
begin
  SaveLength := FDataLength;
  SaveBuffer := FDataBuffer;
  FDataBuffer := @Position;
  FDataLength := SizeOf(Position);
  try
    CallBtrv(B_GET_POSITION);
    Result := FStatus;
  finally
    FDataBuffer := SaveBuffer;
    FDataLength := SaveLength;
  end;
end;

function TBtrvFile.Update: SmallInt;
begin
  Result := CallBtrv(B_UPDATE);
end;

function TBtrvFile.ResetBtrv: SmallInt;
begin
  Result := CallBtrv(B_RESET);
  FFileOpen := False;
end;

function TBtrvFile.Insert: SmallInt;
begin
  Result := CallBtrv(B_INSERT);
end;

function TBtrvFile.Delete: SmallInt;
begin
  Result := CallBtrv(B_DELETE);
end;

function TBtrvFile.GetLastStatus: SmallInt;
begin
  Result := FStatus;
end;

function TBtrvFile.GetSpecs(var Specs: FILE_CREATE_BUFFER_T): SmallInt;
begin
  Result := CallBtrv(B_STAT);
  Move(FDataBuffer^, Specs, SizeOf(Specs));
end;

function TBtrvFile.Recreate: SmallInt;
var
  Specs: FILE_CREATE_BUFFER_T;
  B    : Byte;
  W    : Word;
  FN   : String;
begin
  GetSpecs(Specs);
  W := 0;
  BTRV(B_CLOSE, FPosBlock, B, W, B, 0);
  FN := Trim(Copy(FKeyBuffer, 1, SizeOf(FKeyBuffer)));
  Result := BTRV(B_CREATE, FPosBlock, FDataBuffer^, FDataLength, FFilePath[1], FKeyNumber);
  if Result = 0 then
    Result := Open
  else
    FStatus := Result;
end;

end.

