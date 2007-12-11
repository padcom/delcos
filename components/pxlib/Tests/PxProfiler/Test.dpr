program Test;

{$APPTYPE CONSOLE}

uses
  Windows, Classes, SysUtils,
  PxBase, PxUtils, PxProfiler;

type
  TTestClass = class (TObject)
  private
    procedure TestPrivate;
  protected
    procedure TestProtected;
  public
    procedure TestPublic;
  end;

{ TTestClass }

{ Private declarations }

procedure TTestClass.TestPrivate;
begin
end;

{ Protected declarations }

procedure TTestClass.TestProtected;
begin
end;

{ Public declarations }

procedure TTestClass.TestPublic;
begin
end;

{ *** }

function OverwriteProcedure(OldProcedure, NewProcedure: Pointer): Pointer;
var
  X: PAnsiChar;
  Y: Integer;
  ov2, ov: Cardinal;
  P: Pointer;
begin
  // need six bytes in place of 5
  X := PAnsiChar(OldProcedure);
  if not VirtualProtect(Pointer(X), 6, PAGE_EXECUTE_READWRITE, @ov) then
    RaiseLastOSError;

  // if a jump is present then a redirect is found
  // $FF25 = jmp dword ptr [xxx]
  // This redirect is normally present in bpl files, but not in exe files
  P := OldProcedure;

  if Word(P^) = $25FF then
  begin
    Inc(Integer(P), 2); // skip the jump
    // get the jump address p^ and dereference it p^^
    P := Pointer(Pointer(P^)^);

    // release the memory
    if not VirtualProtect(Pointer(X), 6, ov, @ov2) then
      RaiseLastOSError;

    // re protect the correct one
    X := PAnsiChar(P);
    if not VirtualProtect(Pointer(X), 6, PAGE_EXECUTE_READWRITE, @ov) then
      RaiseLastOSError;
  end;

  // return old function location
  Result := X;

  // store new function location
//  X[0] := AnsiChar($E9); // jmp
  X[0] := AnsiChar($9A); // call
  Y := Integer(NewProcedure) - Integer(P) - 5;
  X[1] := AnsiChar(Y and 255);
  X[2] := AnsiChar((Y shr 8) and 255);
  X[3] := AnsiChar((Y shr 16) and 255);
  X[4] := AnsiChar((Y shr 24) and 255);

  if not VirtualProtect(Pointer(X), 6, ov, @ov2) then
    RaiseLastOSError;
end;

procedure TestMe;
begin
  Writeln('TestMe;')
end;

procedure TestMe2;
begin
  Writeln('TestMe2;')
end;

var
  T: TTestClass;

begin
  T := TTestClass.Create;
  T.TestPrivate;
  T.TestProtected;
  T.TestPublic;
  T.Free;
  TestMe;
  OverwriteProcedure(@TestMe, @TestMe2);
  TestMe;
  testMe2;
end.
