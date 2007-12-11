// ----------------------------------------------------------------------------
// Unit        : PxBase.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2004-10-18
// Version     : 1.0
// Description : Base definitions
// Changes log : 2004-10-18 - Initial version
//               2005-03-11 - Removed dependencies to GNUGetText unit and
//                            switched to PxGetText.
// ToDo        : Testing.
// ----------------------------------------------------------------------------

unit PxBase;

{$I PxDefines.inc}

interface

uses
{$IFDEF VER130}
  PxDelphi5,
{$ENDIF}
  Windows, Classes, SysUtils;

type
  //
  // Base types
  //
  Int8    = type ShortInt;
  Int16   = type SmallInt;
  Int32   = type Integer;
//  Int64   = type System.Int64; //- already defined in System.dcu
  UInt8   = type Byte;
  UInt16  = type Word;
  UInt32  = type LongWord;
  Float32 = type Single;
  Float48 = type Real48;
  Float64 = type Double;
  Float80 = type Extended;
  Float   = Float64;

  //
  // This class enebles the use of interfaces for standard delphi
  // classes. The objects MUST be manually disposed therefore
  // they can be stored in a standard container like TList.
  //
  // You have to remeamber, that class instances have to be createrd
  // first and disposed last. If any interface variables contain the
  // pointer to an interface implemented by this class there will come
  // an "Invalid pointer operation" exception what means, that not all
  // interface variables are done with this object yet.
  //
  TPxBaseObject = class (TInterfacedObject)
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
  end;

  //
  // This is a list of objects above
  //
  TPxBaseObjectList = class (TList)
  private
    function GetItem(Index: Integer): TPxBaseObject;
  public
    function IndexOf(Item: TPxBaseObject): Integer;
    procedure Add(Item: TPxBaseObject);
    procedure Remove(Item: TPxBaseObject);
    property Items[Index: Integer]: TPxBaseObject read GetItem; default;
  end;

  //
  // An GetText/WideString-enabled exception object
  //
  EPxException = class (Exception)
    constructor Create(const Msg: WideString);
    constructor CreateFmt(const Msg: WideString; const Args: array of const);
    constructor CreateRes(ResStringRec: PResStringRec); 
    constructor CreateResFmt(ResStringRec: PResStringRec; const Args: array of const); 
  end;

//
// Returns an IUnknown from an object if this object implements the IUnknown interface.
// Most common use of this function should be
//
//   SomeProc(GetInterface(my_object) as IMyInterface)
//
// and in SomeProc should be checked if this what has come is <> nil
//
function GetInterface(Obj: TObject): IUnknown;

//
// Checks if given object implements a given interface.
// Can be used together with the GetInterface function like this:
//
//   if Implements(my_object, IMyInterface) then
//     SomeProc(GetInterface(my_object) as IMyInterface);
//
function Implements(Obj: TObject; IID: TGUID): Boolean;

//
// Import routines from kernel32.dll
//
function InterlockedIncrement(var Addend: Integer): Integer; stdcall;
function InterlockedDecrement(var Addend: Integer): Integer; stdcall;

var
  ProgramPath: WideString = '';

implementation

//uses
//  PxGetText;

{ TBaseObject }

{ Public declarations }

procedure TPxBaseObject.AfterConstruction;
begin
  inherited AfterConstruction;
  // make this instance auto-disposal proof
  InterlockedIncrement(FRefCount);
end;

procedure TPxBaseObject.BeforeDestruction;
begin
  // this instance is auto-disposal proof so we need to 
  // manualy decrement the reference counter
  InterlockedDecrement(FRefCount);
  inherited BeforeDestruction;
end;

{ TPxList }

{ Private declarations }

function TPxBaseObjectList.GetItem(Index: Integer): TPxBaseObject;
begin
  Result := TObject(Get(Index)) as TPxBaseObject;
end;

{ Public declarations }

function TPxBaseObjectList.IndexOf(Item: TPxBaseObject): Integer;
begin
  Result := inherited IndexOf(Item);
end;

procedure TPxBaseObjectList.Add(Item: TPxBaseObject);
begin
  inherited Add(Item);
end;

procedure TPxBaseObjectList.Remove(Item: TPxBaseObject);
begin
  inherited Remove(Item);
end;

{ EPxException }

constructor EPxException.Create(const Msg: WideString);
begin
  inherited Create(Msg);
end;

constructor EPxException.CreateFmt(const Msg: WideString; const Args: array of const);
begin
  inherited Create(WideFormat(Msg, Args));
end;

constructor EPxException.CreateRes(ResStringRec: PResStringRec);
begin
//  inherited Create(LoadResStringW(ResStringRec));
  inherited Create(LoadResString(ResStringRec));
end;

constructor EPxException.CreateResFmt(ResStringRec: PResStringRec; const Args: array of const);
begin
//  inherited Create(WideFormat(LoadResStringW(ResStringRec), Args));
  inherited Create(WideFormat(LoadResString(ResStringRec), Args));
end;

{ *** }

function InterlockedIncrement(var Addend: Integer): Integer; stdcall;
  external 'kernel32.dll' name 'InterlockedIncrement';

function InterlockedDecrement(var Addend: Integer): Integer; stdcall;
  external 'kernel32.dll' name 'InterlockedDecrement';

function GetInterface(Obj: TObject): IUnknown;
begin
  if not (Assigned(Obj) and Obj.GetInterface(IUnknown, Result)) then
    Result := nil;
end;

function Implements(Obj: TObject; IID: TGUID): Boolean;
begin
  Result := Assigned(Obj) and Obj.GetInterface(IID, Result)
end;

{ *** }

procedure Initialize;
begin
  ProgramPath := ExtractFilePath(ParamStr(0));
end;

procedure Finalize;
begin

end;

initialization
  Initialize;

finalization
  Finalize;

end.




