//-----------------------------------------------------------------------------
//
//  Copyright 1982-2001 Pervasive Software Inc. All Rights Reserved
//
//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
//
//  BTRAPI32.PAS
//    This is the Pascal unit for MS Windows Btrieve to be called by
//    Delphi for Windows NT/2000 or Windows 9x/Me.
//
//-----------------------------------------------------------------------------

unit BtrApi32;

interface

uses
  BtrConst;

type
  POS_BLOCK_T = array[0..POS_BLOCK_SIZE - 1] of Byte;

  //
  // Record type definitions for Stat and Create operations
  //
  FILE_SPECS_T = packed record
    RecLength   : SmallInt;
    PageSize    : SmallInt;
    IndexCount  : SmallInt;
    RecCount    : LongWord;
    Flags       : SmallInt;
    DupPointers : Byte;
    NotUsed     : Byte;
    Allocations : SmallInt;
  end;

  KEY_SPECS_T = packed record
    Position    : SmallInt;
    Length      : SmallInt;
    Flags       : SmallInt;
    Reserved    : array[0..3] of Char;
    KeyType     : Char;
    NullChar    : Char;
    NotUsed     : array[0..1] of Char;
    ManualKeyNumber: Byte;
    AcsNumber   : Byte;
  end;

  FILE_CREATE_BUFFER_T = packed record
    FileSpecs   : FILE_SPECS_T;
    KeySpecs    : array[0..4] of KEY_SPECS_T;
  end;

  //
  // The following types are needed for use with 'BTRCALLBACK'.
  //
  SQL_YIELD_T = packed record
     iSessionID : Word;
  end;

  BTRV_YIELD_T = packed record
    iOpCode           : Word;
    bClientIDlastFour : array[1..4] of Byte;
  end;

  BTI_CB_INFO_T = packed record
    typex  : Word;
    size   : Word;
    case U: Boolean of
      False: (sYield: SQL_YIELD_T);
      True : (bYield: BTRV_YIELD_T);
  end;

  BTI_CB_FUNC_PTR_T = function(var bCallbackInfo: BTI_CB_INFO_T; var bUserData): Word;
  BTI_CB_FUNC_PTR_PTR_T = ^BTI_CB_FUNC_PTR_T;
  
//
// PLATFORM-INDEPENDENT FUNCTIONS
//   BTRV and BTRVID are the same on all platforms for which they have
//   an implementation.  We recommend that you use only these two
//   functions with Btrieve 6.x client components, and then issue
//   the B_STOP operation prior to exiting your application.
//
function BTRV(Operation: Word; var PosBlock; var DataBuffer; var DataLen: Word; 
  var KeyBuffer; KeyNumber: SmallInt): SmallInt;

function BTRVID(Operation: Word; var PosBlock; var DataBuffer; var DataLen: Word; 
  var KeyBuffer; KeyNumber: SmallInt; var ClientID): SmallInt;

//
// PLATFORM-SPECIFIC FUNCTIONS
//   These APIs are specific to the MS Windows platform.  With the
//   exception of BTRCALLBACK, we recommend that you use either
//   BTRV or BTRVID, shown above.  Slight performance gains can be
//   achieved by using BTRCALL or BTRCALLID.
//
function BTRCALL(Operation: Word; var PosBlock; var DataBuffer; var DataLen: LongInt;
  var KeyBuffer; KeyLength: BYTE; KeyNum: ShortInt): SmallInt; far; stdcall;

function BTRCALLID(Operation: Word; var PosBlock; var DataBuffer; var DataLen: LongInt;
  var KeyBuffer; KeyLength: BYTE; KeyNum: ShortInt; var ClientId): SmallInt; far; stdcall;

//
// BTRCALLBACK - Used to register call-back function to Btrieve.
//
function BTRCALLBACK(Action: Word; Option: Word; CallBackFunction: BTI_CB_FUNC_PTR_T; 
  PreviousCallBackFunction: BTI_CB_FUNC_PTR_PTR_T; var UserData; 
  var PreviousUserData: POINTER; var ClientID): SmallInt; stdcall;

//
// HISTORICAL FUNCTIONS
//   These APIs were needed prior to Btrieve 6.x client
//   components.  Older applications may still call these functions,
//   and the Btrieve Windows 6.x client component will work correctly.
//   New applications using the 6.x client components do NOT have to
//   call these functions.
//
function BTRVINIT(var InitializationString): SmallInt;
function BTRVSTOP: SmallInt;
function BRQSHELLINIT(var InitializationString): SmallInt;

implementation

function BTRCALL; external 'W3BTRV7.DLL' name 'BTRCALL';
function BTRCALLID; external 'W3BTRV7.DLL'  name 'BTRCALLID';
function BTRCALLBACK; external 'W3BTRV7.DLL'  name 'BTRCALLBACK';

  { Implementation of BTRV }
function BTRV(Operation: Word; var PosBlock; var DataBuffer; var DataLen: Word; 
  var KeyBuffer; KeyNumber: SmallInt): SmallInt;
var
  KeyLen: BYTE;
  DataLenParam: LongInt;
  DataPack: array[1..2] of Word absolute DataLenParam;
begin
  KeyLen:= 255; // maximum key length
  DataLenParam := dataLen;
  Result := BTRCALL(Operation, PosBlock, DataBuffer, DataLenParam, KeyBuffer, KeyLen, KeyNumber);
  DataLen := DataPack[1];
end;

function BTRVID(Operation: Word; var PosBlock; var DataBuffer; var DataLen: Word; 
  var KeyBuffer; KeyNumber: SmallInt; var ClientID): SmallInt;
var
  KeyLen : Byte;
  DataLenParam: LongInt;
  DataPack : array[1..2] of Word absolute DataLenParam;
begin
  DataLenParam := DataLen;
  KeyLen:= 255; // maximum key length
  Result := BTRCALLID(Operation, PosBlock, DataBuffer, DataLenParam, KeyBuffer, KeyLen, KeyNumber, ClientID);
  DataLen := DataPack[1];
end;

function WBSHELLINIT(var InitializationString): SmallInt; far; stdcall; external 'W3BTRV7.DLL' name 'WBSHELLINIT';
function WBRQSHELLINIT(var InitializationString): SmallInt; external 'W3BTRV7.DLL' name 'WBRQSHELLINIT';
function WBTRVINIT(var InitializationString): SmallInt; external 'W3BTRV7.DLL' name 'WBTRVINIT';
function WBTRVSTOP: SmallInt; external 'W3BTRV7.DLL' name 'WBTRVSTOP';

function BTRVINIT(var InitializationString): SmallInt;
begin
  BTRVINIT := WBTRVINIT(InitializationString);
end;

function BTRVSTOP: SmallInt;
begin
  BTRVSTOP:= WBTRVSTOP;
end;

function BRQSHELLINIT(var initializationString): SmallInt;
begin
  BRQSHELLINIT:= WBRQSHELLINIT(initializationString);
end;

end.
