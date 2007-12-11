program Test;

{$APPTYPE CONSOLE}

uses
  Classes, SysUtils, PxBase;

type
  ITestInterface = interface (IUnknown)
    ['{329070FA-93B4-45A5-8442-1F89F6EC2FBD}']
    function GetItem(Index: Integer): String;
    procedure HelloWorld;
    property Test[Index: Integer]: String read GetItem; default;
  end;

//  TTestClass = class (TInterfacedObject, ITestInterface)
  TTestClass = class (TPxBaseObject, ITestInterface)
  private
    FHelloMsg: String;
    function GetItem(Index: Integer): String;
    procedure HelloWorld;
  public
    constructor Create;
    destructor Destroy; override;
  end;

function TTestClass.GetItem(Index: Integer): String;
begin
  Result := IntToStr(Index);
end;

procedure TTestClass.HelloWorld;
begin
  Writeln(FHelloMsg);
  FHelloMsg := 'TTestClass.HelloWorld;';
end;

constructor TTestClass.Create;
begin
  inherited Create;
  FHelloMsg := 'TTestClass.Create;';
end;

destructor TTestClass.Destroy;
begin
  FHelloMsg := 'TTestClass.Destroy;';
  inherited Destroy;
end;

var
  L: TList;
  C: TTestClass;
  I: ITestInterface;

begin
  L := TList.Create;
  L.Add(TTestClass.Create);
  C := L[0];
  Writeln(C.RefCount);
  I := TInterfacedObject(L[0]) as ITestInterface;
  Writeln(C.RefCount);
  I.HelloWorld;
  Writeln(I[12345678]);
  Writeln(C.RefCount);
  I := nil;
  Writeln(C.RefCount);
  I := C as ITestInterface;
  Writeln(C.RefCount);
  I.HelloWorld;
  Writeln(C.RefCount);
  I := nil;
  Writeln(C.RefCount);
  C.HelloWorld;
  Writeln(C.RefCount);
  C.Free;
end.

