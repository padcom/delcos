// ----------------------------------------------------------------------------
// Unit        : PxClasses.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2005-07-18
// Version     : 1.0 
// Description : Base classes definitions
// Changes log : 2005-07-18 - initial version
// ToDo        : Testing.
// ----------------------------------------------------------------------------
  
unit PxClasses;

interface

uses
  Windows, Classes, SysUtils;

type
  TPxCircularBuffer = class (TObject)
  private
    FBufferSize: Integer;
    FData: PByte;
    FReadPtr, FWritePtr: PByte;
    FSize: Integer;
    FSemaphore: RTL_CRITICAL_SECTION;
    function GetAsString: String;
    function GetData: Pointer;
  public
    constructor Create(BufferSize: Integer);
    destructor Destroy; override;
    function Read(var Buffer; BufferSize: Integer): Integer;
    function Write(var Buffer; BufferSize: Integer): Integer;
    procedure Clear;
    property Size: Integer read FSize;
    property Memory: Pointer read GetData;
    property AsString: String read GetAsString;
  end;

implementation

{ TCircularBuffer }

{ Private declarations }

function TPxCircularBuffer.GetAsString: String;
var
  T: PChar;
  C: Integer;
begin
  Result := '';
  T := PChar(FReadPtr);
  C := Size;
  while C > 0 do
  begin
    Result := Result + T^;
    Inc(T);
    if Integer(T) = Integer(FData) + FBufferSize then
      T := PChar(FData)
    else
      Inc(T);
    Dec(C);
  end;
end;

function TPxCircularBuffer.GetData: Pointer;
begin
  Result := FData;
end;

{ Public declarations }

constructor TPxCircularBuffer.Create(BufferSize: Integer);
begin
  inherited Create;
  InitializeCriticalSection(FSemaphore);
  FBufferSize := BufferSize;
  FData := SysGetMem(FBufferSize);
  FReadPtr := FData;
  FWritePtr := FData;
  FSize := 0;
end;

destructor TPxCircularBuffer.Destroy;
begin
  DeleteCriticalSection(FSemaphore);
  SysFreeMem(FData);
  FData := nil;
  FReadPtr := nil;
  FWritePtr := nil;
  inherited Destroy;
end;

function TPxCircularBuffer.Read(var Buffer; BufferSize: Integer): Integer;
var
  Tmp: PByte;
begin
  EnterCriticalSection(FSemaphore);
  try
    Result := 0;
    Tmp := @Buffer;
    if FSize < BufferSize then
      BufferSize := FSize;

    while (FSize > 0) and (BufferSize > 0) do
    begin
      Tmp^ := FReadPtr^;
      if Integer(FReadPtr) < Integer(FReadPtr) + FBufferSize then
        Inc(FReadPtr)
      else
        FReadPtr := FData;
      Inc(Tmp);
      Dec(FSize);
      Dec(BufferSize);
      Inc(Result);
    end;
  finally
    LeaveCriticalSection(FSemaphore);
  end;
end;

function TPxCircularBuffer.Write(var Buffer; BufferSize: Integer): Integer;
var
  Tmp: PByte;
begin
  EnterCriticalSection(FSemaphore);
  try
    Result := 0;
    Tmp := @Buffer;
    while (FSize < FBufferSize) and (BufferSize > 0) do
    begin
      try
        FWritePtr^ := Tmp^;
      except
        Beep;
      end;
      if Integer(FWritePtr) < Integer(FData) + FBufferSize then
        Inc(FWritePtr)
      else
        FWritePtr := FData;
      Inc(Tmp);
      Inc(FSize);
      Dec(BufferSize);
    end;
    Result := Integer(Tmp) - Integer(@Buffer);
  finally
    LeaveCriticalSection(FSemaphore);
  end;
end;

procedure TPxCircularBuffer.Clear;
begin
  FReadPtr := FData;
  FWritePtr := FData;
  FSize := 0;
end;

end.
