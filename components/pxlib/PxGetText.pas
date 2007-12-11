// ----------------------------------------------------------------------------
// Unit        : PxGetText.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2005-03-01
// Version     : 1.0
// Description : Utilities to read, write and translate strings using MO files.
// Changes log : 2005-03-01 - initial version
//                          - changed from string to UTF8String and WideString
//                          - resourcestrings are translated automatically
//                          - added function to compile the MO file from source
//                          - CompilePO2MO file is now exactly the same as
//                            compiled with msgfmt-compiled
//               2005-03-02 - escape sequences: \n, \\ and \" are interpreted
//                            correctly now
//               2005-03-15 - fixed: range check error while reading strings
//                            with the length of 0
//                          - changed manually allocated buffers into dynamic
//                            arrays since the free pascal compiler supports
//                            them too.
//               2005-05-10 - added GetTextFmt and GetTextWFmt functions
//               2005-10-14 - added Delphi 5 compatibility 
// ToDo        : - GNU gettext compatibility functions: domains
//               - Testing.
// ----------------------------------------------------------------------------

unit PxGetText;

{$I PxDefines.inc}

interface

uses
{$IFDEF VER130}
  PxDelphi5,
{$ENDIF}
  Windows, Classes, SysUtils;

const
  MOFileHeaderMagic = $950412DE;

type

  //
  // MO file header
  //
  TMOFileHeader = packed record
    Magic: LongWord;             // MOFileHeaderMagic
    Revision: LongWord;          // Revision (always 0)
    StringsCount: LongWord;      // Number of string pairs
    OrigTabOffset: LongWord;     // Offset of original string offset table
    TransTabOffset: LongWord;    // Offset of translated string offset table
    HashTabSize: LongWord;       // Size of hashing table
    HashTabOffset: LongWord;     // Offset of first hashing table entry
  end;

  //
  // String entry info
  //
  TMOStringInfo = packed record
    Length: LongWord;
    Offset: LongWord;
  end;

  //
  // Array of the above record
  //
  TMOStringTable = array of TMOStringInfo;

  TLongWordDynArray = array of LongWord;
  TStringDynArray = array of String;

  //
  // This class represents a single MO file
  //
  TMOFile = class (TObject)
  protected
    StringCount, HashTableSize: LongWord;
    HashTable: TLongWordDynArray;
    OrigTable, TranslTable: TMOStringTable;
    OrigStrings, TranslStrings: TStringDynArray;
  public
    constructor Create(Stream: TStream); overload;
    constructor Create(const FileName: String); overload;
    destructor Destroy; override;
    // Warning: requires an UTF-8 encoded source string
    function GetText(Org: UTF8String; Len: LongWord; Hash: LongWord): WideString; overload;
    // If you know the hash - use this version
    function GetText(Org: WideString; Hash: LongWord): WideString; overload;
    // If you only know the original test - use this version
    function GetText(Org: WideString): WideString; overload;
    // If you know the resourcestring variable - use this version like S := MOFile.GetText(@@SMyText);
    function GetText(ResStr: PResStringRec): WideString; overload;
  end;

  TMOFileList = class (TList)
  private
    function GetItem(Index: Integer): TMOFile;
  public
    property Items[Index: Integer]: TMOFile read GetItem; default;
  end;

  EMOFileError = class(Exception);

{$IFNDEF HOOK_LOADRESSTRING}
//
// This function overrides the LoadResString function
// to provide translated resourcestrings.
//
procedure InstallOverrides;
{$ENDIF}

//
// functions to manage active language (.mo) files.
//
// When multiple files are loaded the check is done in the order
// in which the files have been loaded. This functionality is
// provided only because some strings might be independent from
// the application (ie. RTL common strings) and as such they will
// exist in a separate file. The order in which .mo files are
// loaded should consider which texts will be used most and they
// should be loaded first.
//
procedure LoadLanguageFile(FileName: WideString);
procedure UnloadLanguageFile(MOFile: TMOFile; Free: Boolean = True);
procedure UnloadAllLanguageFiles;

//
// functions to load translated string instead of the original version
//
function GetText(S: String): String;
function GetTextFmt(S: String; Params: array of const): String;
function GetTextW(S: WideString): WideString;
function GetTextWFmt(S: WideString; Params: array of const): WideString;
function LoadResString(ResStringRec: PResStringRec): string;
function LoadResStringFmt(ResStringRec: PResStringRec; Params: array of const): string; 
function LoadResStringW(ResStringRec: PResStringRec): WideString; 
function LoadResStringWFmt(ResStringRec: PResStringRec; Params: array of const): WideString; 

//
// functions to compile a .po (source) file into a .mo (binary) file
//
function CompilePO2MO(POFile, MOFile: TStream): Boolean; overload;
function CompilePO2MO(POFile, MOFile: TFileName): Boolean; overload;

var
  //
  // Add to this collection TMOFile objects that contain resources used by your application.
  // The safe way of using this list is over the LoadLanguageFile, UnloadLanguageFile and
  // UnloadAllLanguageFiles procedures
  //
  MOFiles: TMOFileList = nil;

const
  //
  // GetThreadLocale return values.
  // Thanks to Frank Andreas de Groot for this table
  //
  IDAfrikaans                 = $0436;  IDAlbanian                  = $041C;
  IDArabicAlgeria             = $1401;  IDArabicBahrain             = $3C01;
  IDArabicEgypt               = $0C01;  IDArabicIraq                = $0801;
  IDArabicJordan              = $2C01;  IDArabicKuwait              = $3401;
  IDArabicLebanon             = $3001;  IDArabicLibya               = $1001;
  IDArabicMorocco             = $1801;  IDArabicOman                = $2001;
  IDArabicQatar               = $4001;  IDArabic                    = $0401;
  IDArabicSyria               = $2801;  IDArabicTunisia             = $1C01;
  IDArabicUAE                 = $3801;  IDArabicYemen               = $2401;
  IDArmenian                  = $042B;  IDAssamese                  = $044D;
  IDAzeriCyrillic             = $082C;  IDAzeriLatin                = $042C;
  IDBasque                    = $042D;  IDByelorussian              = $0423;
  IDBengali                   = $0445;  IDBulgarian                 = $0402;
  IDBurmese                   = $0455;  IDCatalan                   = $0403;
  IDChineseHongKong           = $0C04;  IDChineseMacao              = $1404;
  IDSimplifiedChinese         = $0804;  IDChineseSingapore          = $1004;
  IDTraditionalChinese        = $0404;  IDCroatian                  = $041A;
  IDCzech                     = $0405;  IDDanish                    = $0406;
  IDBelgianDutch              = $0813;  IDDutch                     = $0413;
  IDEnglishAUS                = $0C09;  IDEnglishBelize             = $2809;
  IDEnglishCanadian           = $1009;  IDEnglishCaribbean          = $2409;
  IDEnglishIreland            = $1809;  IDEnglishJamaica            = $2009;
  IDEnglishNewZealand         = $1409;  IDEnglishPhilippines        = $3409;
  IDEnglishSouthAfrica        = $1C09;  IDEnglishTrinidad           = $2C09;
  IDEnglishUK                 = $0809;  IDEnglishUS                 = $0409;
  IDEnglishZimbabwe           = $3009;  IDEstonian                  = $0425;
  IDFaeroese                  = $0438;  IDFarsi                     = $0429;
  IDFinnish                   = $040B;  IDBelgianFrench             = $080C;
  IDFrenchCameroon            = $2C0C;  IDFrenchCanadian            = $0C0C;
  IDFrenchCotedIvoire         = $300C;  IDFrench                    = $040C;
  IDFrenchLuxembourg          = $140C;  IDFrenchMali                = $340C;
  IDFrenchMonaco              = $180C;  IDFrenchReunion             = $200C;
  IDFrenchSenegal             = $280C;  IDSwissFrench               = $100C;
  IDFrenchWestIndies          = $1C0C;  IDFrenchZaire               = $240C;
  IDFrisianNetherlands        = $0462;  IDGaelicIreland             = $083C;
  IDGaelicScotland            = $043C;  IDGalician                  = $0456;
  IDGeorgian                  = $0437;  IDGermanAustria             = $0C07;
  IDGerman                    = $0407;  IDGermanLiechtenstein       = $1407;
  IDGermanLuxembourg          = $1007;  IDSwissGerman               = $0807;
  IDGreek                     = $0408;  IDGujarati                  = $0447;
  IDHebrew                    = $040D;  IDHindi                     = $0439;
  IDHungarian                 = $040E;  IDIcelandic                 = $040F;
  IDIndonesian                = $0421;  IDItalian                   = $0410;
  IDSwissItalian              = $0810;  IDJapanese                  = $0411;
  IDKannada                   = $044B;  IDKashmiri                  = $0460;
  IDKazakh                    = $043F;  IDKhmer                     = $0453;
  IDKirghiz                   = $0440;  IDKonkani                   = $0457;
  IDKorean                    = $0412;  IDLao                       = $0454;
  IDLatvian                   = $0426;  IDLithuanian                = $0427;
  IDMacedonian                = $042F;  IDMalaysian                 = $043E;
  IDMalayBruneiDarussalam     = $083E;  IDMalayalam                 = $044C;
  IDMaltese                   = $043A;  IDManipuri                  = $0458;
  IDMarathi                   = $044E;  IDMongolian                 = $0450;
  IDNepali                    = $0461;  IDNorwegianBokmol           = $0414;
  IDNorwegianNynorsk          = $0814;  IDOriya                     = $0448;
  IDPolish                    = $0415;  IDBrazilianPortuguese       = $0416;
  IDPortuguese                = $0816;  IDPunjabi                   = $0446;
  IDRhaetoRomanic             = $0417;  IDRomanianMoldova           = $0818;
  IDRomanian                  = $0418;  IDRussianMoldova            = $0819;
  IDRussian                   = $0419;  IDSamiLappish               = $043B;
  IDSanskrit                  = $044F;  IDSerbianCyrillic           = $0C1A;
  IDSerbianLatin              = $081A;  IDSesotho                   = $0430;
  IDSindhi                    = $0459;  IDSlovak                    = $041B;
  IDSlovenian                 = $0424;  IDSorbian                   = $042E;
  IDSpanishArgentina          = $2C0A;  IDSpanishBolivia            = $400A;
  IDSpanishChile              = $340A;  IDSpanishColombia           = $240A;
  IDSpanishCostaRica          = $140A;  IDSpanishDominicanRepublic  = $1C0A;
  IDSpanishEcuador            = $300A;  IDSpanishElSalvador         = $440A;
  IDSpanishGuatemala          = $100A;  IDSpanishHonduras           = $480A;
  IDMexicanSpanish            = $080A;  IDSpanishNicaragua          = $4C0A;
  IDSpanishPanama             = $180A;  IDSpanishParaguay           = $3C0A;
  IDSpanishPeru               = $280A;  IDSpanishPuertoRico         = $500A;
  IDSpanishModernSort         = $0C0A;  IDSpanish                   = $040A;
  IDSpanishUruguay            = $380A;  IDSpanishVenezuela          = $200A;
  IDSutu                      = $0430;  IDSwahili                   = $0441;
  IDSwedishFinland            = $081D;  IDSwedish                   = $041D;
  IDTajik                     = $0428;  IDTamil                     = $0449;
  IDTatar                     = $0444;  IDTelugu                    = $044A;
  IDThai                      = $041E;  IDTibetan                   = $0451;
  IDTsonga                    = $0431;  IDTswana                    = $0432;
  IDTurkish                   = $041F;  IDTurkmen                   = $0442;
  IDUkrainian                 = $0422;  IDUrdu                      = $0420;
  IDUzbekCyrillic             = $0843;  IDUzbekLatin                = $0443;
  IDVenda                     = $0433;  IDVietnamese                = $042A;
  IDWelsh                     = $0452;  IDXhosa                     = $0434;
  IDZulu                      = $0435;

//
// LocaleID to language suffix conversion
//
function LocaleId2Lang(LocaleId: Word): string;

//
// This is a very specialized function to load the language file
// based on the application's executable and a two letter language
// code, like example_de for german, example_en for english, aso.
//
procedure LoadDefaultLang;

//
// This procedure loads the language embedded in the application's resources
// To use it create a resource script entry like this
//
//   language_name RCDATA compiled_language_file.mo
//
// compile the resource file and link it to the executable file or a library
// that comes with your application like this
//
//   {$R resource_file.res}
//
// The Instance parameter tells if you want to load resources from main
// program file or a library that's dynamically loaded.
// The second form is to load a language from a dll. It's only a wrapper
// around LoadLibrary/LoadResourceLang/FreeLibrary, but it might be handy.
//
procedure LoadResourceLang(Instance: THandle; ResName: String); overload;
procedure LoadResourceLang(FileName: String; ResName: String); overload;

//
// Character encoding functions
//
function Win1250toISO852(S: string): string;

implementation

uses
  PxUtils;

//
// generate hash value for the specified string
//
function HashString(S: String): Cardinal;
var
  G: Cardinal;
  I: Integer;
begin
  Result := 0;
  for I := 1 to Length(S) do
  begin
    Result := Result shl 4;
    Inc(Result, Ord(S[I]));
    G := Result and Cardinal($F shl 28);
    if G <> 0 then
    begin
      Result := Result xor (G shr 24);
      Result := Result xor G;
    end;
  end;
  // this is not in the standard version from gettext suite (file: hash-string.h)
//  if Result = 0 then
//     Result := $FFFFFFFF;
end;

//
// Get a resourcestring value
//
function InternalGetResString(ResStringRec: PResStringRec): WideString;
{$IFDEF DELPHI}
var
  Len: Integer;
  Buffer: array [0..1023] of Char;
{$ENDIF}  
begin
{$IFDEF DELPHI}
  if ResStringRec = nil then Exit;
  Assert(ResStringRec^.Identifier < 65536, Format('Invalid ResStringRec^.Identifier = %d', [ResStringRec^.Identifier])); // do not translate

  if Win32Platform = VER_PLATFORM_WIN32_NT then
  begin
    Result := '';
    Len := 0;
    while Len = Length(Result) do
    begin
      if Length(Result) = 0 then
        SetLength(Result, 1024)
      else
        SetLength(Result, Length(Result) * 2);
      Len := LoadStringW(FindResourceHInstance(ResStringRec^.Module^),  ResStringRec^.Identifier, PWideChar(Result), Length(Result));
    end;
    SetLength(Result, Len);
  end
  else
    SetString(Result, Buffer, LoadString(FindResourceHInstance(ResStringRec^.Module^), ResStringRec^.Identifier, Buffer, SizeOf(Buffer)));
{$ENDIF}
{$IFDEF FPC}
  Result := '';
{$ENDIF}
end;

{ TMOFile }

constructor TMOFile.Create(Stream: TStream);
var
  Header: TMOFileHeader;
  I: Integer;
begin
  inherited Create;

  // Read file header
  Stream.Read(Header, Sizeof(Header));

  if Header.Magic <> MOFileHeaderMagic then
    raise EMOFileError.Create('Invalid magic - not a MO file?');

  SetLength(OrigTable, Header.StringsCount);
  SetLength(TranslTable, Header.StringsCount);
  SetLength(OrigStrings, Header.StringsCount);
  SetLength(TranslStrings, Header.StringsCount);

  Stream.Position := Header.OrigTabOffset;
  Stream.Read(OrigTable[0], Header.StringsCount * SizeOf(TMOStringInfo));

  Stream.Position := Header.TransTabOffset;
  Stream.Read(TranslTable[0], Header.StringsCount * SizeOf(TMOStringInfo));

  StringCount := Header.StringsCount;

  // Read original strings
  for I := 0 to StringCount - 1 do
    if OrigTable[I].Length <> 0 then
    begin
      Stream.Position := OrigTable[I].Offset;
      SetLength(OrigStrings[I], OrigTable[I].Length);
      Stream.Read(OrigStrings[I][1], OrigTable[I].Length);
    end;

  // Read translated strings
  for I := 0 to StringCount - 1 do
    if OrigTable[I].Length <> 0 then
    begin
      Stream.Position := TranslTable[I].Offset;
      SetLength(TranslStrings[I], TranslTable[I].Length);
      Stream.Read(TranslStrings[I][1], TranslTable[I].Length);
    end;

  // Read hashing table
  HashTableSize := Header.HashTabSize;
  SetLength(HashTable, HashTableSize);
  Stream.Position := Header.HashTabOffset;
  Stream.Read(HashTable[0], 4 * HashTableSize);
end;

constructor TMOFile.Create(const FileName: String);
var
  F, T: TStream;
begin
  T := nil;
  F := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    if AnsiSameText(ExtractFileExt(FileName), '.po') then
    begin
      // this is a source file - compile it first
      T := TMemoryStream.Create;
      if not CompilePO2MO(F, T) then
      begin
        T.Free;
        F.Free;
        Fail;
      end;
      F.Free;
      T.Position := 0;
    end
    else
      T := F;
    try
      Create(T);
    except
      Fail;
    end;
  finally
    T.Free;
  end;
end;

destructor TMOFile.Destroy;
begin
  SetLength(OrigTable, 0);
  SetLength(TranslTable, 0);
  SetLength(OrigStrings, 0);
  SetLength(TranslStrings, 0);
  SetLength(HashTable, 0);
  inherited Destroy;
end;

function TMOFile.GetText(Org: UTF8String; Len: LongWord; Hash: LongWord): WideString;
var
{$IFDEF USE_HASH_TABLE}
  idx, incr, nstr: LongWord;
{$ELSE}  
  I: Integer;
{$ENDIF}
  S: UTF8String;
begin
{$IFDEF USE_HASH_TABLE}
  idx := Hash mod HashTableSize;
  incr := 1 + (Hash mod (HashTableSize - 2));
  while True do
  begin
    nstr := HashTable[idx];
    if nstr = 0 then
    begin
      if Org = '' then
        S := TranslStrings[0]
      else
        S := '';
      Break;
    end;
    if (OrigTable[nstr - 1].Length = Len) and (StrComp(PChar(OrigStrings[nstr - 1]), PChar(Org)) = 0) then
    begin
      S := TranslStrings[nstr - 1];
      Break;
    end
    else if idx >= HashTableSize - incr then
      Dec(idx, HashTableSize - incr)
    else
      Inc(idx, incr);
  end;
{$ELSE}
  S := '';
  for I := 0 to Length(OrigTable) - 1 do
    if StrComp(PChar(OrigStrings[I]), PChar(Org)) = 0 then
    begin
      S := TranslStrings[I];
      Break;
    end;
{$ENDIF}
  Result := UTF8Decode(S);
end;

function TMOFile.GetText(Org: WideString; Hash: LongWord): WideString;
var
  S: UTF8String;
begin
  S := UTF8Encode(Org);
  Result := GetText(PChar(S), Length(Org), Hash);
end;

function TMOFile.GetText(Org: WideString): WideString;
begin
  Result := GetText(Org, HashString(UTF8Encode(Org)));
end;

function TMOFile.GetText(ResStr: PResStringRec): WideString;
begin
  Result := InternalGetResString(ResStr);
  Result := GetText(Result, HashString(Result));
end;

{ TMOFileList }

{ Private declarations }

function TMOFileList.GetItem(Index: Integer): TMOFile;
begin
  Result := TObject(Get(Index)) as TMOFile;
end;

{ *** }

procedure LoadLanguageFile(FileName: WideString);
var
  MOFile: TMOFile;
begin
  // do not load files that don't exist
  if not FileExists(FileName) then
    Exit;

  // make sure the file is being read from application folder
  if ExtractFilePath(FileName) = '' then
    FileName := ExtractFilePath(ParamStr(0)) + FileName;

  // check if the file can be loaded (ie. if file exists and no errors occour while reading)
  MOFile := TMOFile.Create(FileName);
  if Assigned(MOFile) then
    MOFiles.Add(MOFile);
end;

procedure UnloadLanguageFile(MOFile: TMOFile; Free: Boolean = True);
begin
  if Assigned(MOFile) then
  begin
    MOFiles.Remove(MOFile);
    if Free then
      FreeAndNil(MOFile);
  end;
end;

procedure UnloadAllLanguageFiles;
begin
  while MOFiles.Count > 0 do
    UnloadLanguageFile(MOFiles[MOFiles.Count - 1]);
end;

function GetText(S: String): String;
begin
  Result := GetTextW(S);
end;

function GetTextFmt(S: String; Params: array of const): String;
begin
  Result := Format(GetText(S), Params);
end;

function GetTextW(S: WideString): WideString;
var
  I: Integer;
  T: WideString;
begin
  Result := S;
  if Assigned(MOFiles) then
    for I := 0 to MOFiles.Count - 1 do
    begin
      T := MOFiles[I].GetText(Result);
      if T <> '' then
      begin
        Result := T;
        Break;
      end;
    end;
end;

function GetTextWFmt(S: WideString; Params: array of const): WideString;
begin
  Result := WideFormat(GetTextW(S), Params);
end;

function LoadResString(ResStringRec: PResStringRec): string;
begin
  Result := LoadResStringW(ResStringRec);
  if IsConsole then
    Result := Win1250toISO852(Result);
end;

function LoadResStringFmt(ResStringRec: PResStringRec; Params: array of const): string;
begin
  Result := Format(LoadResString(ResStringRec), Params);
end;

function LoadResStringW(ResStringRec: PResStringRec): WideString;
begin
  Result := InternalGetResString(ResStringRec);
  Result := GetTextW(Result);
end;

function LoadResStringWFmt(ResStringRec: PResStringRec; Params: array of const): WideString;
begin
  Result := WideFormat(LoadResStringW(ResStringRec), Params);
end;

function CompilePO2MO(POFile, MOFile: TStream): Boolean;
type
  TPair = record
    Original  : String;
    Translated: String;
  end;
  TPairs = array of TPair;

  procedure SortPairs(var Pairs: TPairs);
  var
    I: Integer;
    Changed: Boolean;
    Tmp: TPair;
  begin
    // a simple bubble-sort alg. to sort the pairs list
    repeat
      Changed := False;
      for I := 0 to Length(Pairs) - 2 do
        if AnsiCompareText(Pairs[I].Original, Pairs[I + 1].Original) = 1 then
        begin
          // change of order needed
          Tmp := Pairs[I];
          Pairs[I] := Pairs[I + 1];
          Pairs[I + 1] := Tmp;
          Changed := True;
        end;
    until not Changed;
  end;

const
   SID_MSGID  = 'msgid';
   SID_MSGSTR = 'msgstr';

  function Read(var Cmd, Data: String): Boolean;
  var
    S: String;
    I, Count: Integer;
  begin
    // read/parse an entry form source stream
    Cmd := ''; Data := '';
    Result := False;
    SetLength(S, 4096);
    Count := POFile.Read(S[1], Length(S));
    if Count = 0 then
      Exit;
    for I := 1 to Count do
      if S[I] in [#13, #10] then
      begin
        // take care of different new-line definitions (CRLF, CR and LF)
        SetLength(S, I - 1);
        if (S <> '') and (S[I] = #13) and (I < Count) and (S[I + 1] = #10) then
          POFile.Seek(I - Count + 1, soFromCurrent)
        else
          POFile.Seek(I - Count, soFromCurrent);
        Break;
      end
      else if (I < Length(S)) and (S[I] + S[I + 1] = '\n') then
      begin
        // manage "\n" sequence
        Move(S[I + 1], S[I], Count - I);
        S[I] := #10;
        S[Length(S)] := #0;
        Dec(Count);
      end
      else if (I < Length(S)) and (S[I] + S[I + 1] = '\"') then
      begin
        // manage "\"" sequence
        Move(S[I + 1], S[I], Count - I);
        S[I] := '"';
        S[Length(S)] := #0;
        Dec(Count);
      end
      else if (I < Length(S)) and (S[I] + S[I + 1] = '\\') then
      begin
        // manage "\"" sequence
        Move(S[I + 1], S[I], Count - I);
        S[I] := '\';
        S[Length(S)] := #0;
        Dec(Count);
      end;
    S := Trim(S);
    if (S <> '') and (S[1] <> '#') then
    begin
      if S[1] = '"' then
      begin
        // return just the data
        Cmd := '';
        Data := Copy(S, 2, Length(S) - 2);
        Result := True;
      end
      else if AnsiSameText(SID_MSGID, Copy(S, 1, Length(SID_MSGID))) then
      begin
        // return a msgid
        Cmd := SID_MSGID;
        Data := Copy(S, Length(SID_MSGID) + 2, MaxInt);
        Data := Copy(Data, 2, Length(Data) - 2);
        Result := True;
      end
      else if AnsiSameText(SID_MSGSTR, Copy(S, 1, Length(SID_MSGSTR))) then
      begin
        // return a msgstr
        Cmd := SID_MSGSTR;
        Data := Copy(S, Length(SID_MSGSTR) + 2, MaxInt);
        Data := Copy(Data, 2, Length(Data) - 2);
        Result := True;
      end
      else Result := False;
    end;
  end;

  function NextPrime(Value: Integer): Integer;
  var
    I, J: Integer;
    IsPrime: Boolean;
  begin
    // get the next prime number after the given value
    Result := -1;
    for I := Value + 1 to MaxInt do
    begin
      IsPrime := True;
      for J := 2 to Value - 1 do
        if I mod J = 0 then
        begin
          IsPrime := False;
          Break;
        end;
      if IsPrime then
      begin
        Result := I;
        Break;
      end;
    end;
  end;

var
  Cmd, Data: String;
  Pairs: TPairs;
  I, Index: Integer;
  Offset: LongWord;
  Header: TMOFileHeader;
  HashTable: TLongWordDynArray;
  OrigTable, TranslTable: TMOStringTable;
  hash_val, idx, incr: Cardinal;
  InMsgID, InMsgStr: Boolean;
begin
  Result := True;

  // parse the source file
  SetLength(Pairs, 20); Index := -1; InMsgID := False; InMsgStr := False;
  repeat
    if Read(Cmd, Data) then
    begin
      if Cmd = SID_MSGID then
      begin
        InMsgID := True;
        InMsgStr := False;
        Inc(Index);
        if Index = Length(Pairs) then
          SetLength(Pairs, Length(Pairs) + 10)
        else if (Index > 0) and (Pairs[Index - 1].Translated = '') then
        begin
          Dec(Index);
          Pairs[Index].Original := '';
          Pairs[Index].Translated := '';
        end;
      end
      else if Cmd = SID_MSGSTR then
      begin
        InMsgID := False;
        InMsgStr := True;
      end;

      if InMsgID then
        Pairs[Index].Original := Pairs[Index].Original + Data
      else if InMsgStr then
        Pairs[Index].Translated := Pairs[Index].Translated + Data;
    end;
  until POFile.Position >= POFile.Size;
  if Pairs[Index].Translated = '' then
    Dec(Index);
  SetLength(Pairs, Index + 1);
  SortPairs(Pairs);

  // make the strings null-terminated
  for I := 0 to Length(Pairs) - 1 do
  begin
    Pairs[I].Original := Pairs[I].Original + #0;
    Pairs[I].Translated := Pairs[I].Translated + #0;
  end;

  // generate MO file
  Header.Magic := MOFileHeaderMagic;
  Header.Revision := 0;
  Header.StringsCount := Length(Pairs);
  Header.OrigTabOffset := SizeOf(TMOFileHeader);
  Header.TransTabOffset := Header.OrigTabOffset + (Header.StringsCount * SizeOf(TMOStringInfo));
  Header.HashTabOffset := Header.TransTabOffset + (Header.StringsCount * SizeOf(TMOStringInfo));
  Header.HashTabSize := NextPrime((Header.StringsCount * 4) div 3);

  Offset := Header.HashTabOffset + Header.HashTabSize * 4;
  // generate string tables
  SetLength(OrigTable, Header.StringsCount);
  for I := 0 to Length(Pairs) - 1 do
  begin
    OrigTable[I].Length := Length(Pairs[I].Original) - 1;
    OrigTable[I].Offset := Offset;
    Offset := Offset + OrigTable[I].Length + 1;
  end;
  // generate string tables
  SetLength(TranslTable, Header.StringsCount);
  for I := 0 to Length(Pairs) - 1 do
  begin
    TranslTable[I].Length := Length(Pairs[I].Translated) - 1;
    TranslTable[I].Offset := Offset;
    Offset := Offset + TranslTable[I].Length + 1;
  end;

  // generate hash table
  SetLength(HashTable, Header.HashTabSize);
  for I := 0 to Header.StringsCount - 1 do
  begin
    hash_val := HashString(Copy(Pairs[I].Original, 1, Length(Pairs[I].Original) - 1));
    idx := hash_val mod Header.HashTabSize;
    if HashTable[idx] <> 0 then
    begin
      incr := 1 + (hash_val mod (Header.HashTabSize - 2));
      repeat
         if idx >= Header.HashTabSize - incr then
           idx := idx - (Header.HashTabSize - incr)
         else
           idx := idx + incr;
      until HashTable[idx] = 0;
    end;
    HashTable[idx] := I + 1;
  end;

  // save all to destination stream
  MOFile.Write(Header, SizeOf(Header));
  MOFile.Write(OrigTable[0], Header.StringsCount * SizeOf(TMOStringInfo));
  MOFile.Write(TranslTable[0], Header.StringsCount * SizeOf(TMOStringInfo));
  MOFile.Write(HashTable[0], Header.HashTabSize * 4);
  for I := 0 to Length(Pairs) - 1 do
    MOFile.Write(Pairs[I].Original[1], Length(Pairs[I].Original));
  for I := 0 to Length(Pairs) - 1 do
    MOFile.Write(Pairs[I].Translated[1], Length(Pairs[I].Translated));
end;

function CompilePO2MO(POFile, MOFile: TFileName): Boolean;
var
  PO, MO: TStream;
begin
  PO := TFileStream.Create(POFile, fmOpenRead);
  try
    MO := TFileStream.Create(MOFile, fmCreate);
    try
      Result := CompilePO2MO(PO, MO);
    finally
      MO.Free;
    end;
  finally
    PO.Free;
  end;
end;


function LocaleId2Lang(LocaleId: Word): string;
begin
  // confront with the http://cvs.freedesktop.org/xorg/xc/nls/locale.alias?rev=1.12
  
  case LocaleId of
    IDAfrikaans:                  Result := 'af_ZA';
    IDAlbanian:                   Result := 'sq_AL';
    IDArabicAlgeria:              Result := 'ar_DZ';
    IDArabicBahrain:              Result := 'ar_BH';
    IDArabicEgypt:                Result := 'ar_EG';
    IDArabicIraq:                 Result := 'ar_IQ';
    IDArabicJordan:               Result := 'ar_JO';
    IDArabicKuwait:               Result := 'ar_KW';
    IDArabicLebanon:              Result := 'ar_LB';
    IDArabicLibya:                Result := 'ar_LY';
    IDArabicMorocco:              Result := 'ar_MA';
    IDArabicOman:                 Result := 'ar_OM';
    IDArabicQatar:                Result := 'ar_QA';
    IDArabic:                     Result := 'ar_SA';
    IDArabicSyria:                Result := 'en_EN';
    IDArabicTunisia:              Result := 'ar_TN';
    IDArabicUAE:                  Result := 'en_EN';
    IDArabicYemen:                Result := 'ar_YE';
    IDArmenian:                   Result := 'en_EN';
    IDAssamese:                   Result := 'en_EN';
    IDAzeriCyrillic:              Result := 'en_EN';
    IDAzeriLatin:                 Result := 'en_EN';
    IDBasque:                     Result := 'eu_ES';
    IDByelorussian:               Result := 'en_EN';
    IDBengali:                    Result := 'en_EN';
    IDBulgarian:                  Result := 'bg_BG';
    IDBurmese:                    Result := 'en_EN';
    IDCatalan:                    Result := 'ca_ES';
    IDChineseHongKong:            Result := 'zh_HK';
    IDChineseMacao:               Result := 'en_EN';
    IDSimplifiedChinese:          Result := 'zh_TW';
    IDChineseSingapore:           Result := 'zh_SG';
    IDTraditionalChinese:         Result := 'en_EN';
    IDCroatian:                   Result := 'hr_HR';
    IDCzech:                      Result := 'cs_CZ';
    IDDanish:                     Result := 'da_DK';
    IDBelgianDutch:               Result := 'nl_BE';
    IDDutch:                      Result := 'nl_NL';
    IDEnglishAUS:                 Result := 'en_AU';
    IDEnglishBelize:              Result := 'en_BZ';
    IDEnglishCanadian:            Result := 'en_CA';
    IDEnglishCaribbean:           Result := 'en_EN';
    IDEnglishIreland:             Result := 'en_IE';
    IDEnglishJamaica:             Result := 'en_JM';
    IDEnglishNewZealand:          Result := 'en_NZ';
    IDEnglishPhilippines:         Result := 'en_EN';
    IDEnglishSouthAfrica:         Result := 'en_ZA';
    IDEnglishTrinidad:            Result := 'en_TT';
    IDEnglishUK:                  Result := 'en_UK';
    IDEnglishUS:                  Result := 'en_US';
    IDEnglishZimbabwe:            Result := 'en_EN';
    IDEstonian:                   Result := 'et_EE';
    IDFaeroese:                   Result := 'fo_FO';
    IDFarsi:                      Result := 'fa_IR';
    IDFinnish:                    Result := 'fi_FI';
    IDBelgianFrench:              Result := 'fr_BE';
    IDFrenchCameroon:             Result := 'fr_FR';
    IDFrenchCanadian:             Result := 'fr_CA';
    IDFrenchCotedIvoire:          Result := 'fr_FR';
    IDFrench:                     Result := 'fr_FR';
    IDFrenchLuxembourg:           Result := 'fr_LU';
    IDFrenchMali:                 Result := 'fr_FR';
    IDFrenchMonaco:               Result := 'fr_FR';
    IDFrenchReunion:              Result := 'fr_FR';
    IDFrenchSenegal:              Result := 'fr_FR';
    IDSwissFrench:                Result := 'fr_CH';
    IDFrenchWestIndies:           Result := 'fr_FR';
    IDFrenchZaire:                Result := 'fr_FR';
    IDFrisianNetherlands:         Result := 'ml_NL';
    IDGaelicIreland:              Result := 'en_EN';
    IDGaelicScotland:             Result := 'en_EN';
    IDGalician:                   Result := 'gl_ES';
    IDGeorgian:                   Result := 'ka_GE';
    IDGermanAustria:              Result := 'de_AU';
    IDGerman:                     Result := 'de_DE';
    IDGermanLiechtenstein:        Result := 'de_LI';
    IDGermanLuxembourg:           Result := 'de_LU';
    IDSwissGerman:                Result := 'de_CH';
    IDGreek:                      Result := 'el_GR';
    IDGujarati:                   Result := 'en_EN';
    IDHebrew:                     Result := 'iw_IL';
    IDHindi:                      Result := 'en_EN';
    IDHungarian:                  Result := 'hu_HU';
    IDIcelandic:                  Result := 'is_IS';
    IDIndonesian:                 Result := 'id_ID';
    IDItalian:                    Result := 'it_IT';
    IDSwissItalian:               Result := 'it_CH';
    IDJapanese:                   Result := 'ja_JP';
    IDKannada:                    Result := 'en_EN';
    IDKashmiri:                   Result := 'en_EN';
    IDKazakh:                     Result := 'en_EN';
    IDKhmer:                      Result := 'en_EN';
    IDKirghiz:                    Result := 'en_EN';
    IDKonkani:                    Result := 'en_EN';
    IDKorean:                     Result := 'ko_KR';
    IDLao:                        Result := 'en_EN';
    IDLatvian:                    Result := 'lv_LV';
    IDLithuanian:                 Result := 'lt_LT';
    IDMacedonian:                 Result := 'mk_MK';
    IDMalaysian:                  Result := 'en_EN';
    IDMalayBruneiDarussalam:      Result := 'en_EN';
    IDMalayalam:                  Result := 'en_EN';
    IDMaltese:                    Result := 'en_EN';
    IDManipuri:                   Result := 'en_EN';
    IDMarathi:                    Result := 'en_EN';
    IDMongolian:                  Result := 'en_EN';
    IDNepali:                     Result := 'en_EN';
    IDNorwegianBokmol:            Result := 'no_NO';
    IDNorwegianNynorsk:           Result := 'no_NO';
    IDOriya:                      Result := 'en_EN';
    IDPolish:                     Result := 'pl_PL';
    IDBrazilianPortuguese:        Result := 'pt_BR';
    IDPortuguese:                 Result := 'pt_PT';
    IDPunjabi:                    Result := 'en_EN';
    IDRhaetoRomanic:              Result := 'en_EN';
    IDRomanianMoldova:            Result := 'en_EN';
    IDRomanian:                   Result := 'ro_RO';
    IDRussianMoldova:             Result := 'en_EN';
    IDRussian:                    Result := 'ru_RU';
    IDSamiLappish:                Result := 'en_EN';
    IDSanskrit:                   Result := 'en_EN';
    IDSerbianCyrillic:            Result := 'sr_YU';
    IDSerbianLatin:               Result := 'sr_YU';
    IDSesotho:                    Result := 'en_EN';
    IDSindhi:                     Result := 'en_EN';
    IDSlovak:                     Result := 'sk_SK';
    IDSlovenian:                  Result := 'sl_SI';
    IDSorbian:                    Result := 'en_EN';
    IDSpanishArgentina:           Result := 'en_EN';
    IDSpanishBolivia:             Result := 'en_EN';
    IDSpanishChile:               Result := 'en_EN';
    IDSpanishColombia:            Result := 'en_EN';
    IDSpanishCostaRica:           Result := 'en_EN';
    IDSpanishDominicanRepublic:   Result := 'en_EN';
    IDSpanishEcuador:             Result := 'en_EN';
    IDSpanishElSalvador:          Result := 'en_EN';
    IDSpanishGuatemala:           Result := 'en_EN';
    IDSpanishHonduras:            Result := 'en_EN';
    IDMexicanSpanish:             Result := 'en_EN';
    IDSpanishNicaragua:           Result := 'en_EN';
    IDSpanishPanama:              Result := 'en_EN';
    IDSpanishParaguay:            Result := 'en_EN';
    IDSpanishPeru:                Result := 'en_EN';
    IDSpanishPuertoRico:          Result := 'en_EN';
    IDSpanishModernSort:          Result := 'en_EN';
    IDSpanish:                    Result := 'es_ES';
    IDSpanishUruguay:             Result := 'en_EN';
    IDSpanishVenezuela:           Result := 'en_EN';
//    IDSutu:                       Result := 'en_EN';
    IDSwahili:                    Result := 'en_EN';
    IDSwedishFinland:             Result := 'sv_FI';
    IDSwedish:                    Result := 'sv_SE';
    IDTajik:                      Result := 'en_EN';
    IDTamil:                      Result := 'en_EN';
    IDTatar:                      Result := 'en_EN';
    IDTelugu:                     Result := 'te_IN';
    IDThai:                       Result := 'en_EN';
    IDTibetan:                    Result := 'en_EN';
    IDTsonga:                     Result := 'en_EN';
    IDTswana:                     Result := 'en_EN';
    IDTurkish:                    Result := 'tr_TR';
    IDTurkmen:                    Result := 'en_EN';
    IDUkrainian:                  Result := 'uk_UA';
    IDUrdu:                       Result := 'ur_PK';
    IDUzbekCyrillic:              Result := 'en_EN';
    IDUzbekLatin:                 Result := 'en_EN';
    IDVenda:                      Result := 'en_EN';
    IDVietnamese:                 Result := 'en_EN';
    IDWelsh:                      Result := 'en_EN';
    IDXhosa:                      Result := 'en_EN';
    IDZulu:                       Result := 'en_EN';
    else                          Result := 'en_EN';
  end;                            
end;

procedure LoadDefaultLang;
var
  LanguageFile: String;
  Suffix: String;
begin
  LanguageFile := ExtractFileName(ParamStr(0));
  LanguageFile := Copy(LanguageFile, 1, Length(LanguageFile) - Length(ExtractFileExt(LanguageFile)));
  Suffix := LocaleId2Lang(GetThreadLocale);

  if FileExists(LanguageFile + '_' + Suffix + '.mo') then
    LanguageFile := LanguageFile + '_' + Suffix + '.mo'
  else if FileExists(LanguageFile + '_' + Copy(Suffix, 1, 2) + '.mo') then
    LanguageFile := LanguageFile + '_' + Copy(Suffix, 1, 2) + '.mo'
  else if FileExists(LanguageFile + '_en_EN.mo') then
    LanguageFile := LanguageFile + '_en_EN.mo'
  else if FileExists(LanguageFile + '_en.mo') then
    LanguageFile := LanguageFile + '_en.mo'
  else if FileExists(LanguageFile + '.mo') then
    LanguageFile := LanguageFile + '.mo'
  else
    LanguageFile := '';

  // load the language file
  if LanguageFile <> '' then
    PxGetText.LoadLanguageFile(LanguageFile);
end;

procedure LoadResourceLang(Instance: THandle; ResName: String);
var
  S: TStream;
  MOFile: TMOFile;
begin
  S := TResourceStream.Create(Instance, ResName, RT_RCDATA);
  try
    MOFile := TMOFile.Create(S);
    MOFiles.Add(MOFile);
  finally
    S.Free;
  end;
end;

procedure LoadResourceLang(FileName: String; ResName: String);
var
  Instance: THandle;
begin
  Instance := LoadLibrary(PChar(FileName));
  if Instance <> 0 then
    try
      LoadResourceLang(Instance, ResName);
    finally
      FreeLibrary(Instance);
    end;
end;

{ *** }

var
  OldLoadResString: Pointer = nil;

procedure InstallOverrides;
begin
  if OldLoadResString = nil then
{$IFDEF FPC}
    OldLoadResString := OverwriteProcedure(@ObjPas.LoadResString, @LoadResString);
{$ELSE}
    OldLoadResString := OverwriteProcedure(@System.LoadResString, @LoadResString);
{$ENDIF}
end;

procedure Initialize;
begin
  // while running from package as a part of delphi environment don't start the translation subsystem
  if IsDelphiHost then Exit;
  MOFiles := TMOFileList.Create;
{$IFDEF HOOK_LOADRESSTRING}
  InstallOverrides;
{$ENDIF}
end;

procedure Finalize;
var
  I: Integer;
begin
  // while running from package as a part of delphi environment the translation subsystem is not started
  if IsDelphiHost then Exit;
  for I := 0 to MOFIles.Count - 1 do
    MOFiles[I].Free;
  FreeAndNil(MOFiles);
end;

function Win1250toISO852(S: string): string;
const
  WIN1250: string = '¹æê³óñœŸ¿¥ÆÊ£ÓÑŒ¯';
  CP852  : string = #$A5#$86#$A9#$88#$A2#$E4#$98#$AB#$BE#$A4#$8F#$A8#$9D#$E0#$E3#$97#$8D#$BD;
var
  I, P: Integer;
begin
  for I := 1 to Length(S) do
  begin
    P := Pos(S[I], Win1250);
    if P > 0 then
      S[I] := CP852[P];
  end;
  Result := S;
end;

initialization
  Initialize;

finalization
  Finalize;

end.

