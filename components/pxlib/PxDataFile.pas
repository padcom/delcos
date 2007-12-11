// ----------------------------------------------------------------------------
// Unit        : PxDataFile.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2002-11-16
// Version     : 1.0
// Description : 
// Changes log : 2002-11-16 - initial version
//               2003-02-07 - added a method to finalize a data record
//                          - added a property for TPxDataFile telling that the contents has been modified
//               2003-02-18 - added support for signature and version of file. In the derived classes
//                            instead of setting fields in header it is better to set the apriopriate
//                            propertis (Signature, Version).
//                          - added support for handling graphical parts of record. All such parts are
//                            internally stored as PNG images.
//                          - fixed: problem with saving a file with a default filename when the current
//                            path has changed.
//               2003-02-20 - added support for handling compressed data. New class TCompressedDataFile
//                            introduces saving and loading of compressed data with some additional
//                            info (small letter "c" as a last letter of file version). An uncompressed
//                            file can be read with TCompressedDataFile and then saved as a compressed
//                            file.
//               2003-08-09 - added posibility to save the file under a different filename (default param
//                            for TPxDataFile.Save method).
//                          - added methods to create and remove single records in file (ie. main data
//                            file datas that occur only once in the file). CreateSingles and
//                            DestroySingles. Inside of this two method you can call AddRecord and
//                            DelRecord to create and dispose single records.
//                          - added methods for creating and disposing additional items for the DataFile
//                            CreateAddons and DestroyAddons.
//                          - compilation of image parts only if the DATARECORDEX_PART_IMAGE conditional
//                            is defined. If it becomes defined then additionals are required (PNGImage,
//                            PNGLang and PNGZLib from "Portable Network Graphics Delphi 1.435" package
//                            (http://PNGdelphi.sourceforge.net)
//               2003-11-09 - removed the TPxDataFile.DestroySingles and TPxDataContainer.DestroySingles because
//                            single records are removed during _ClearRecords wich calls OnDelRecord method.
//               2003-11-10 - cosmetic change: param list for saving of different types of parts has been
//                            unified (WritePart)
//                          - added an initialization of TPxDataRecord.Buffer (ZeroFill)
//                          - added TPxDataEvents class to manage events outside the TPxDataFile derived classes.
//                            (to make sense with the code generation machanism)
//               2003-11-12 - added method TPxDataFile.Clear(RecreateSingles: Boolean = True).
//                            If RecreateSingles is set to true then the method CreateSingles is called and
//                            any single record is created. if not the single records will be set to a nil !.
//                          - similar fix has been applied while loading file. You have to remeamber ALWAYS
//                            to free single records in OnAddRecord using Free and the Records.Remove(fieldname).
//                            Otherwise the single records will multiply with every save/load sequence.
//                            The code generator does it.
//               2004-02-22 - added reading and writing of Float values with unit family and unit id
//               2004-02-23 - added RecordID, TRecordsResolver and TPxDataEvents.OnResolveIDs event
//               2004-03-06 - added methods for storing data in streams (not only in files)
//               2004-03-21 - added support for BZip2 compression (using BZIP2 Data Compression Interface Unit)
//               2004-03-23 - added support for stream parts (that is parts instead of known data contains only
//                            buffer - access to this diata is via TMemoryStream
//               2004-03-25 - A BIG CHANGE ! All headers have now a field Flags of type LongWord. For that
//               ----------   reason (the system was no more extensible, sorry) the all the old files MUST FIRST
//                            BE CONVERTED into Xml (source) files and the read with this new version.
//                            To compile this unit without this modification define a THIN_HEADERS directive.
//                            This disables creating of additional data in headers and all additional features
//                            that come with it.
//                          - "c" from Version in TCompressedFile is gone (now in flags, if THIN_HEADERS not defined)
//                          - a new property for TPxDataRecord: Modified (using flags)
//                          - a new parameter for TPxDataFile.Save (and coresponding methods in TPxDataRecord,
//                            TPxDataRecordEx and TPxDataContainer) for saving only modified records.
//               2004-03-28 - reading and writing of TExpression parts
//               2004-04-11 - removed TPNGImage support (now it is a raw TBitmap)
//               2004-07-14 - added support for resolving ids in single records (OnResolveIDs event/method)
//                          - stripped IDENT_RESOLVER directive
//                          - stripped THIN_HEADERS directire
//               2004-11-09 - bugfix: record flags have not been restored while reading record   
//               2004-12-17 - added prototype for Assign procedure (generated automaticaly by DataFileGenerator)
//               2005-02-2x - changed Assign procedure and base class for records to TPersistent to have RTTI informations
//                            (needed while XmlSerialization). 
//               2005-06-16 - stripped down image part (use stream parts instead)
// ToDo        : Testing.
// ----------------------------------------------------------------------------
  
unit PxDataFile;

{ --------------------------------------------------------------------------------------------
  Opis : Loading and saving binary files with variable-length records, including specialized 
         records containing parts (data, string, floating-point values or graphical data).
         All records stored in the file have the same header layout what allows to read unknown
         records from the file as TPxDataRecord. This rule complies also to TPxDataContainer
         aswell as TPxDataRecordEx so it's possible to create an application that reads only
         some of the records but stores all of them during save operation.
         In case of TPxDataRecord if the defined buffer size varies from the one that's stored
         in the file the right abount of data is read (data from file is eighter truncated or
         filled with nulls).
         While saving to file if there's a previous version of the file it is renamed to
         FileName.~ext.

  Hints: Physical order of records might be changed if the reading process finds some unknown
         records, but the logical order remains the same (regarding TPxDataContainer which
         is recognized by TPxDataFile). This way one cannot relay on the physical order but
         only on their logical representation.
         In case of destructors for file and container classes it's imperative that the
         list objects are created AFTER the call to inherited Create and AFTER the call to
         inherited Destroy for example:
         
         type
           TMyFile = class (TPxDataFile)
           protected
             procedure OnAddRecord(Rec: TPxDataRecord); override;
             procedure OnDelRecord(Rec: TPxDataRecord; RecordWillBeDisposed: Boolean); override;
           public
             constrcutor Create;
             destructor Destroy; override;
             MyItems: TList;
             DaneOgolne: TMyGlobalData;
           end;

         procedure TMyFile.OnAddRecord(Rec: TPxDataRecord);
         begin
           if Rec is TMyItem then
             MyItems.Add(Record);
         end;

         procedure TMyFile.OnDelRecord(Rec: TPxDataRecord; RecordWillBeDisposed: Boolean);
         begin
           if Rec is TMyItem then
             MyItems.Remove(Record);
         end;

         constructor TMyFile.Create;
         begin
           inherited Create;
           MyItems := TList.Create;
         end;

         destructor TMyFile.Destroy;
         begin
           inherited Destroy;
           MyItems.Free; // !!!
         end;

         A more elegant way is to override methods CreateLists and DestroyLists which are
         called in the right place (for example DtaFileGenerator does it this way).

         It's this way because the method OnDelRecord is executed inside the destructor
         via the ClearRecords method which removes all records and must have all the 
         pointers to lists containing references to objects being disposed.

         Single reocord fields (for example global data for a project) are not created
         within the constructor nor are disposed in the destructor but should be assigned
         in event methods OnAddRecord/OnDelRecord. The place where single records are
         created (so that the Clear method can recreate them) is the CreateSingles method
         (please note that there's no DestroySingles method at all!). Here's a complete
         example on how to deal with single records:

         procedure TMyFile.OnAddRecord(Rec: TPxDataRecord);
         begin
           if Rec is TMyDaneOgolne then
             DaneOgolne := Rec as TMyDaneOgolne;
         end;

         procedure TMyFile.OnDelRecord(Rec: TPxDataRecord; RecordWillBeDisposed: Boolean);
         begin
           if Rec is TMyDaneOgolne then
             DaneOgolne := nil;
         end;

         procedure TMyFile.CreateSingles;
         begin
           AddRecord(TMyDaneOgolne.Create(Self));
         end;

         Objects created this way will be automatically created and disposed along with
         records kept in Records list and corresponding fields will always have the right
         data.

         WARNING! During file reading signature and version MUST BE EQUAL!

  Cond : To use float parts declare DATARECORDEX_PART_FLOAT directive (Delphi7 only !)
         To use expressions parts declare DATARECORDEX_PART_EXPRESSION directive (Delphi7 only !)
         To use BZip2 compression define BZIP2_COMPRESSION directive

  ToDo : - Test events (TPxDataEvents)
         - TExpression - klasa wyra¿eñ
 -------------------------------------------------------------------------------------------- }

interface

{$I PxDefines.inc}

uses
  Classes, SysUtils, TypInfo,
{$IFDEF BZIP2_COMPRESSION}
  BZip2,
{$ELSE}
{$IFDEF DELPHI}
  ZLib,
{$ENDIF}
{$IFDEF FPC}
  ZStream,
{$ENDIF}
{$ENDIF}
  PxBase,
  PxResources;

type
  TIdentifier = type UInt32;
  
const
  INVALID_IDENTIFIER_VALUE = 0;
  NO_ID             = TIdentifier($FFFFFFFF);
  MAX_AUTO_ID       = $FFFFFFFF;
  MIN_AUTO_ID       = $80000001;

const
  // special record kinds
  kindInvalidRecord = $0000;
  kindEndRecord     = $FFFF;
  kindDataContainer = $FFFE;
  kindIdGenerator   = $FFFD;
  // special part ids
  partInvalidPart   = $0000;
  partEndPart       = $FFFF;
  partString        = $FFFE;
  partImage         = $FFFC;
  partStream        = $FFFB; // a stream part (i.e. to store component data)

{ DataRecord.Header.Flags }
  FLAG_R_MODIFIED   = 1 shl 0;
  FLAG_R_CREATED    = 1 shl 1;
  FLAG_R_CONNECTIONS_OK = 1 shl 2;

{ DataContainer.Header.Flags }
//  FLAG_C_ ???

{ DataPart.Header.Flags }
//  FLAG_P_ ???

{ DataFile.Header.Flags }
  FLAG_F_COMPRESSED = 1 shl 0;

type
  TPxDataFile = class;

  TPxBaseDataObject = class (TPersistent)
  private
    FOwner: TPxBaseDataObject;
    function GetRoot: TPxBaseDataObject;
  public
    constructor Create(AOwner: TPxBaseDataObject); virtual;
    property Owner: TPxBaseDataObject read FOwner;
    property Root: TPxBaseDataObject read GetRoot;
  end;

  // header of base (simple) data record
  PPxDataRecordHeader = ^TPxDataRecordHeader;
  TPxDataRecordHeader = packed record
    Kind : UInt16; // 16 bit
    Size : UInt32; // 32 bit
    Flags: UInt32; // 32 bit
  end;

  TPxDataRecordClass = class of TPxDataRecord;

  TPxIdResolver = class;

  // base data record (all the records have the same schema)
  TPxDataRecord = class (TPxBaseDataObject)
  private
    FBuffer: Pointer;
    FDataFile: TPxDataFile;
    procedure SetModified(Value: Boolean);
    procedure SetCreated(Value: Boolean);
    procedure SetConnectionsOK(Value: Boolean);
  protected
    Header: TPxDataRecordHeader;
    property Buffer: Pointer read FBuffer;
    procedure AssignTo(Source: TPersistent); override;
    function GetModified: Boolean; virtual;
    function GetCreated: Boolean; virtual;
    function GetConnectionsOK: Boolean; virtual;
    // initialization of a record - override this to set Kind and Size fields in header
    procedure Initialize; virtual;
    // called after buffer is set (needed only for strict TPxDataRecord descendants)
    procedure AfterCreate; virtual;
    // finalization of a record - override this to free extra resources allocated by this record
    procedure Finalize; virtual;
    // reading and writing of data
    procedure ReadFromStream(S: TStream; const RH: TPxDataRecordHeader); virtual;
    procedure WriteToStream(S: TStream; OnlyIfModified: Boolean); virtual;
    // events
    procedure BeforeRead; virtual;
    procedure AfterRead; virtual;
    procedure BeforeWrite; virtual;
    procedure AfterWrite; virtual;
    procedure BeforeFileWrite; virtual;
    procedure AfterFileRead; virtual;
    procedure OnResolveIDs(IdentResolver: TPxIdResolver); virtual;
  public
    constructor Create(AOwner: TPxBaseDataObject); override;
    destructor Destroy; override;
    function RecordID: TIdentifier; virtual;
    property Kind: UInt16 read Header.Kind;
    property DataFile: TPxDataFile read FDataFile;
    property Modified: Boolean read GetModified write SetModified;
    property Created: Boolean read GetCreated write SetCreated;
    property ConnectionsOK: Boolean read GetConnectionsOK write SetConnectionsOK;
  published
    property Flags: UInt32 read Header.Flags write Header.Flags;
  end;

  ENotImplemented = class (Exception)
    constructor Create;
  end;

  // a list of data records
  TPxDataRecordList = class (TList)
  private
    function GetItem(Index: Integer): TPxDataRecord;
  public
    property Items[Index: Integer]: TPxDataRecord read GetItem; default;
  end;

  TPxIdGenerator = class (TPxDataRecord)
  protected
    procedure Initialize; override;
    procedure AfterCreate; override;
  public
    function NewId: TIdentifier;
    function GetLastId: TIdentifier;
    procedure SetLastId(Value: TIdentifier);
  published
    property LastId: TIdentifier read GetLastId write SetLastId;
  end;

  // records container - can be used i.e. to create multiple-documents files. general purpose is to group
  // records in a single "window"
  TPxDataContainer = class (TPxDataRecord)
  private
    FRecords: TPxDataRecordList;
    FUnknownRecords: TPxDataRecordList;
    // pointer to buffer is hidden, because this is only a container for other records
    property Buffer;
  protected
    function GetModified: Boolean; override;
    // initialization - override to set Kind field in the header
    // WARNING: you MUST NOT add data to an container (via Buffer property) because it is can contain
    // only records.
    procedure Initialize; override;
    // creating and disposing of record lists.
    procedure CreateLists; virtual;
    procedure DestroyLists; virtual;
    // creating and disposing of single records (ie. common data, in other words records that occur only one per
    // container instance)
    procedure CreateSingles; virtual;
    // creating and disposing of additional objects.
    procedure CreateAddons; virtual;
    procedure DestroyAddons; virtual;
    // reading and writing of contained records
    procedure ReadFromStream(S: TStream; const RH: TPxDataRecordHeader); override;
    procedure WriteToStream(S: TStream; OnlyIfModified: Boolean); override;
    // events:
    // initialization after read and before write
    procedure AfterFileRead; override;
    procedure BeforeFileWrite; override;
    // adding/removing elements from lists
    procedure OnAddRecord(Rec: TPxDataRecord); virtual;
    procedure OnDelRecord(Rec: TPxDataRecord; RecordWillBeDisposed: Boolean); virtual;
  public
    constructor Create(AOwner: TPxBaseDataObject); override;
    destructor Destroy; override;
    // adda a new record to instance
    function AddRecord(Rec: TPxDataRecord): TPxDataRecord;
    // delete a record from container and free its instance
    procedure DelRecord(Rec: TPxDataRecord; FreeRecord: Boolean = False);
    // a list of all top-level records in container (see: TPxDataFile.Records)
    property Records: TPxDataRecordList read FRecords;
  end;

  // result of reading a part of data
  TPxReadPartResult = (rprUnknown, rprRecognized, rprDiscard);

  // data part header
  TPxDataPartHeader = packed record
    Part : Word;     // 16 bit
    Size : LongWord; // 32 bit
    Flags: LongWord; // 32 bit
  end;

  // DataRecordEx is a data record that is divided inside into parts.
  // for a list of currently supported parts see definition of partXXX constants
  TPxDataRecordEx = class (TPxDataRecord)
  private
    FUnknownParts: array of Byte;
    // pointer to buffer is hidden because all the data are stored as parts
    property Buffer;
  protected
    // use this to create a stream (by default this creates a TMemoryStream)
    procedure CreateStream(ID: Integer; var Stream: TStream);
    // Reading and writing of parts - DO NOT OVERRIDE !
    procedure ReadFromStream(S: TStream; const RH: TPxDataRecordHeader); override;
    procedure WriteToStream(S: TStream; OnlyIfModified: Boolean); override;
    // procedura odczytuj¹ca dane z nadmiarem/niedomiarem (u¿ywaj do odczytu podczêœci).
    // W tym przypadku z koniecznoœci czêœæ danych nadmiarowych jest bezpowtornie utracona.
    procedure ReadData(S: TStream; var Buff; BuffSize, DataSize: Integer);
    // procedura odczytu podczêœci rekordu - pokryj aby odczytaæ znane ci czêœci
    // zawsze na koñcu bloku case: else Result := inherited;
    function ReadPart(S: TStream; const PH: TPxDataPartHeader): TPxReadPartResult; virtual;
    // procedura odczytuj¹ca stringi - pokryj aby pobraæ przeczytan¹ watoœæ ze strumienia
    function ReadString(S: WideString; const ID: Word): TPxReadPartResult; virtual;
    // procedura odczytuj¹ca grafikê
    function ReadStream(Stream: TStream; const ID: Word): TPxReadPartResult; virtual;
    // procedura zapisuj¹ca podczêœæ typu dane
    procedure WritePart(S: TStream; PartID: Word; var Data; PartSize: Longword);
    // porocedura zapisuj¹ca podczêœæ typu string
    procedure WriteString(S: TStream; ID: Word; Data: WideString);
    // porocedura zapisuj¹ca podczêœæ typu strumien danych
    procedure WriteStream(S: TStream; ID: Word; Data: TStream);
    // procedura zapisuj¹ca wszystkie podczêœci - pokryj j¹ aby zapisaæ wszystkie znane ci
    // podczêœci rekordu
    procedure WriteAllParts(S: TStream); virtual;
  public
    constructor Create(AParent: TPxBaseDataObject); override;
    destructor Destroy; override;
  end;

  EPxDuplicateIdentRecordIDs = class (Exception);

  TPxIdResolver = class (TObject)
  private
    FRecords: TPxDataRecordList;
    function GetItem(ID: TIdentifier): TPxDataRecord;
  public
    constructor Create(Records: TPxDataRecordList);
    property Item[ID: TIdentifier]: TPxDataRecord read GetItem; default;
  end;

  // object that receives data events
  TPxDataEvents = class
    // data record events
    procedure OnCreateStream(DataRecordEx: TPxDataRecordEx; StreamID: Integer; var Stream: TStream); virtual;
    procedure BeforeReadRecord(DataRecord: TPxDataRecord); virtual;
    procedure AfterReadRecord(DataRecord: TPxDataRecord); virtual;
    procedure BeforeWriteRecord(DataRecord: TPxDataRecord); virtual;
    procedure AfterWriteRecord(DataRecord: TPxDataRecord); virtual;
    procedure BeforeFileWriteRecord(DataRecord: TPxDataRecord); virtual;
    procedure AfterFileReadRecord(DataRecord: TPxDataRecord); virtual;
    // data container events
    procedure AfterFileReadContainer(DataContainer: TPxDataContainer); virtual;
    procedure BeforeFileWriteContainer(DataContainer: TPxDataContainer); virtual;
    procedure OnAddRecordContainer(DataContainer: TPxDataContainer; DataRecord: TPxDataRecord); virtual;
    procedure OnDelRecordContainer(DataContainer: TPxDataContainer; DataRecord: TPxDataRecord; RecordWillBeDisposed: Boolean); virtual;
    // file events
    procedure AfterFileReadFile(DataFile: TPxDataFile); virtual;
    procedure BeforeFileWriteFile(DataFile: TPxDataFile); virtual;
    procedure OnAddRecordFile(DataFile: TPxDataFile; DataRecord: TPxDataRecord); virtual;
    procedure OnDelRecordFile(DataFile: TPxDataFile; DataRecord: TPxDataRecord; RecordWillBeDisposed: Boolean); virtual;
    procedure OnResolveIDs(DataFile: TPxDataFile; DataRecord: TPxDataRecord; Resolver: TPxIdResolver); virtual;
    // because saving records might take a while a specialized event will be generated each time a record has been
    // successfully saved
    procedure OnSaveProgress(Min, Max, Current: Integer); virtual;
  end;

  // file signature (default PCDF)
  TPxDataFileSignature = array [0..3] of Char;
  // file version (default 1.00)
  TPxDataFileVersion = array [0..3] of Char;
  // creation date (default is always taken from system date)
  TPxDataFileCreationDate = array [0..7] of Char;
  // last write date (default is always taken from system date)
  TPxDataFileModificationDate = array [0..7] of Char;

  // standard data file header
  TPxDataFileHeader = packed record
    FileID  : TPxDataFileSignature;        // 4 bytes
    Version : TPxDataFileVersion;          // 4 bytes
    Created : TPxDataFileCreationDate;     // 8 bytes
    Modified: TPxDataFileModificationDate; // 8 bytes
    Flags   : LongWord;                  // 32 bit
  end;

  // Result of record recognition
  TPxRecognizeRecordResult = (rrrRecognized, rrrDiscard, rrrUnknown);

  // Exceptions
  EInvalidSignature = class(Exception);
  EInvalidVersion = class(Exception);
  EInvalidStructure = class(Exception);
  EInvalidOperation = class(Exception);

  // data file
  TPxDataFile = class (TPxBaseDataObject)
  private
    FHeader: TPxDataFileHeader;
    FSignature: TPxDataFileSignature;
    FVersion: TPxDataFileVersion;
    FEvents: TPxDataEvents;
    FFileName: TFileName;
    FMakeBackup: Boolean;
    FRecords: TPxDataRecordList;
    FUnknownRecords: TPxDataRecordList;
    FModified: Boolean;
    FConnectionsOK: Boolean;
    FIdentRecords: TPxDataRecordList;
    procedure SetSignature(Value: TPxDataFileSignature);
    procedure SetVersion(Value: TPxDataFileVersion);
    function GetCreated: String;
    procedure SetCreated(Value: String);
    function GetLastModified: String;
    procedure SetLastModified(Value: String);
    function GetModified: Boolean;
    procedure SetModified(Value: Boolean);
  protected
    // override this to set Signature and Version fields - the rest (LastModified nad Created) are
    // filled automaticaly by TPxDataFile.WriteHeader
    procedure Initialize; virtual;
    // override this to finalize (free some extra resources used by) data file (needed really seldom)
    procedure Finalize; virtual;
    // creating and disposing of list of records (sugerowane jest tworzenie tylko obiektów list a dodawanie i usuwanie
    // rekordów nale¿y zrobic w CreateAddons)
    procedure CreateLists; virtual;
    procedure DestroyLists; virtual;
    // tworzenie i zwalnianie pojedynczych rekordów (np. dane ogólne pliku, które wystêpuj¹ tylko raz)
    procedure CreateSingles; virtual;
    // tworzenie/dodawanie i zwalnianie/usuwanie dodatkowych rekordów z list.
    procedure CreateAddons; virtual;
    procedure DestroyAddons; virtual;
    // mozna pokryæ w celu obs³ugi innego rodzaju nag³ówka lub dodatkowego nag³ówka dla pliku
    procedure ReadHeader(S: TStream); virtual;
    procedure WriteHeader(S: TStream); virtual;
    // rozpoznawanie rekordów - pokryj aby przeczytaæinteresuj¹ce ciê rekordy
    function RecognizeRecord(const RH: TPxDataRecordHeader; var RecordClass: TPxDataRecordClass): TPxRecognizeRecordResult; virtual;
    // odczyt i zapis rekordów (wyci¹gniête z Load i Save w celu prostrzego zrobienia zapisu i
    // odczytu innych plików, np. skompresowanych). Zapewnia to prawid³ow¹ obs³ugê nag³ówka
    // i daje dowolnoœæ przy zapisie rekordów
    procedure LoadRecords(S: TStream); virtual;
    procedure SaveRecords(S: TStream; OnlyIfModified: Boolean); virtual;
    // events:
    // adding/removing of elements
    procedure OnAddRecord(Rec: TPxDataRecord); virtual;
    procedure OnDelRecord(Rec: TPxDataRecord; RecordWillBeDisposed: Boolean); virtual;
    // initialization after reading and before writing of file
    procedure AfterFileRead; virtual;
    procedure BeforeFileWrite; virtual;
    // file signature
    property Signature: TPxDataFileSignature read FSignature write SetSignature;
    // file version
    property Version: TPxDataFileVersion read FVersion write SetVersion;
    // creation date
    property DateCreated: String read GetCreated write SetCreated;
    // last modification date
    property DateLastModified: String read GetLastModified write SetLastModified;
    // flags
    property Flags: LongWord read FHeader.Flags write FHeader.Flags;
    // external object implementing events
    property Events: TPxDataEvents read FEvents;
  public
    constructor Create(AEvents: TPxDataEvents = nil); reintroduce; virtual;
    destructor Destroy; override;
    // utility functions
    function KindIdToClass(Kind: UInt16): TPxDataRecordClass;
    procedure ResolveIds(DataRecord: TPxDataRecord = nil);
    // records management
    // add a new record into the file (see also TPxDataContainer.AddRecord)
    function AddRecord(Rec: TPxDataRecord): TPxDataRecord;
    // delete a record from file and (if specified) free its instance (see also TPxDataContainer.DelRecord)
    procedure DelRecord(Rec: TPxDataRecord; FreeRecord: Boolean = False);
    // cleaning
    procedure Clear(RecreateSingles: Boolean = True);
    // saving/loading of file
    procedure Load(FileName: TFileName); overload;
    procedure Load(S: TStream); overload;
    procedure Merge(FileName: TFileName); overload;
    procedure Merge(S: TStream); overload;
    procedure Save(NewFileName: TFileName = ''; OnlyChangedRecords: Boolean = False); overload;
    procedure Save(S: TStream; OnlyChangedRecords: Boolean = False); overload;
{$IFDEF VER150}
    procedure WriteXML(FileName: TFileName);
{$ENDIF}
    // this is kind of self-explanatory
    property FileName: TFileName read FFileName write FFileName;
    // do you wanna create backup from this file while saving ?
    property MakeBackup: Boolean read FMakeBackup write FMakeBackup;
    // a list of all top-level records in file (TPxDataContainer i his records are treated as one record only !)
    property Records: TPxDataRecordList read FRecords;
    // information about changes in the file (modified is automaticaly set via Add/DelRecord and Load/Save/LoadXml/SaveXml)
    property Modified: Boolean read GetModified write SetModified;
  end;

  // A data file with compressed records
  TPxCompressedDataFile = class (TPxDataFile)
  private
{$IFNDEF BZIP2_COMPRESSION}
    FCompressionLevel: TCompressionLevel;
{$ENDIF}
    function GetCompressed: Boolean;
    procedure SetCompressed(Value: Boolean);
  protected
    procedure LoadRecords(S: TStream); override;
    procedure SaveRecords(S: TStream; OnlyIfModified: Boolean = False); override;
  public
    constructor Create(AEvents: TPxDataEvents = nil); override;
{$IFNDEF BZIP2_COMPRESSION}
    // Compression level (clMax by default, only for ZLib compressor)
    property CompressionLevel: TCompressionLevel read FCompressionLevel write FCompressionLevel;
{$ENDIF}
    property Compressed: Boolean read GetCompressed write SetCompressed;
  end;

// Uwaga: nie sprawdza jest d³ugoœæ docelowego bufora !
// FOR INTERNAL USE ONLY
procedure StringToArrayOfChar(S: String; D: PChar);

implementation

procedure StringToArrayOfChar(S: String; D: PChar);
begin
  Move(S[1], D^, Length(S));
end;

type
  TOnDelRecordEvent = procedure (Rec: TPxDataRecord; RecordWillBeDisposed: Boolean) of object;

procedure _ClearRecords(KnownRecords, UnknownRecords: TPxDataRecordList; OnDelRecord: TOnDelRecordEvent);
var
  I: Integer;
begin
  for I := 0 to KnownRecords.Count - 1 do
  begin
    if Assigned(OnDelRecord) then
      OnDelRecord(KnownRecords[I], True);
    KnownRecords[I].Free;
  end;
  KnownRecords.Clear;
  for I := 0 to UnknownRecords.Count - 1 do
  begin
    if Assigned(OnDelRecord) then
      OnDelRecord(UnknownRecords[I], True);
    UnknownRecords[I].Free;
  end;
  UnknownRecords.Clear;
end;

type
  TOnAddRecordEvent = procedure (Rec: TPxDataRecord) of object;

procedure _ReadRecords(S: TStream; ExptectedSize: Integer; Reader: TPxBaseDataObject; KnownRecords, UnknownRecords: TPxDataRecordList; OnAddRecord: TOnAddRecordEvent; IdentRecords: TPxDataRecordList);
var
  TempRH: TPxDataRecordHeader;
  Rec: TPxDataRecord;
  RecordClass: TPxDataRecordClass;
  BytesRead: Integer;
  TotalSize: Integer;
  DataFile: TPxDataFile;
begin
  // pobranie wskazania na plik danych
  if Reader is TPxDataFile then DataFile := Reader as TPxDataFile
  else DataFile := TPxDataRecord(Reader).DataFile;

  // odczyt elementów kontenera
  TotalSize := S.Position;
  repeat
    BytesRead := S.Read(TempRH, SizeOf(TempRH));

    if BytesRead < SizeOf(TempRH) then  // b³¹d podczas odczytu nag³ówka rekordu
      raise EInvalidStructure.Create('Error while reading records.');

    if TempRH.Kind = kindEndRecord then // koniec rekordów
      Break;

    if TempRH.Kind = kindInvalidRecord then // b³êdny rekord
      raise EInvalidStructure.Create('Error while reading records: Kind=0');

    // rozpoznanie rodzaju rekordu
    case DataFile.RecognizeRecord(TempRH, RecordClass) of
      rrrRecognized: // przeczytanie rozpoznanego rekordu
      begin
        Rec := RecordClass.Create(Reader);
        Rec.ReadFromStream(S, TempRH);
        KnownRecords.Add(Rec);
        // add to this list only records that contains a valid RecordID
        if Rec.RecordID <> NO_ID then
          IdentRecords.Add(Rec);
        if Assigned(OnAddRecord) then
          OnAddRecord(Rec);
      end;
      rrrDiscard: // przeskoczenie rekordu danych (utrata danych)
        S.Seek(TempRH.Size, soFromCurrent);
      rrrUnknown: // przeczytanie nierozpoznanego rekordu danych
      begin
        Rec := TPxDataRecord.Create(Reader);
        Rec.ReadFromStream(S, TempRH);
        UnknownRecords.Add(Rec);
      end;
    end;
  until False;

  // sprawdzenie poprawnoœci przeczytanych danych (pozycja w pliku)
  if (ExptectedSize > 0) and (S.Position - TotalSize <> ExptectedSize) then
    raise EInvalidStructure.Create('Error while reading records: Expected file position does not match.');
end;

procedure _WriteRecords(S: TStream; KnownRecords, UnknownRecords: TPxDataRecordList; OnlyIfModified: Boolean);
var
  I: Integer;
  EndHeader: TPxDataRecordHeader;
begin
  // zapisanie rozpoznanych rekordów
  for I := 0 to KnownRecords.Count - 1 do
  begin
    KnownRecords[I].WriteToStream(S, OnlyIfModified);
    if Assigned(KnownRecords[I].DataFile.Events) then
      KnownRecords[I].DataFile.Events.OnSaveProgress(0, KnownRecords.Count + UnknownRecords.Count, I + 1);
  end;

  // zapisanie nierozpoznanych ale przeczytanych rekordów
  for I := 0 to UnknownRecords.Count - 1 do
  begin
    UnknownRecords[I].WriteToStream(S, OnlyIfModified);
    if Assigned(UnknownRecords[I].DataFile.Events) then
      UnknownRecords[I].DataFile.Events.OnSaveProgress(0, KnownRecords.Count + UnknownRecords.Count, KnownRecords.Count + I + 1);
  end;

  // zapisanie koñca konterera
  EndHeader.Kind := kindEndRecord;
  EndHeader.Size := 0;
  S.Write(EndHeader, SizeOf(EndHeader));
end;

{ TPxBaseDataObject }

{ Private declarations }

function TPxBaseDataObject.GetRoot: TPxBaseDataObject;
begin
  Result := Self;
  while Assigned(Result.Owner) do
    Result := Result.Owner;
  if Result = Self then
    Result := nil;
end;

{ Public declarations }

constructor TPxBaseDataObject.Create(AOwner: TPxBaseDataObject);
begin
  inherited Create;
  FOwner := AOwner;
end;

{ TPxDataRecord }

{ Private declarations }

procedure TPxDataRecord.SetModified(Value: Boolean);
begin
  if Value then
    Header.Flags := Header.Flags or FLAG_R_MODIFIED
  else
    Header.Flags := Header.Flags and (not FLAG_R_MODIFIED);
    
  if Assigned(FDataFile) then
    FDataFile.FModified := FDataFile.FModified or Value;
end;

procedure TPxDataRecord.SetCreated(Value: Boolean);
begin
  if Value then
    Header.Flags := Header.Flags or FLAG_R_CREATED
  else
    Header.Flags := Header.Flags and (not FLAG_R_CREATED);
end;

procedure TPxDataRecord.SetConnectionsOK(Value: Boolean);
begin
  if Value then
    Header.Flags := Header.Flags or FLAG_R_CONNECTIONS_OK
  else
    Header.Flags := Header.Flags and (not FLAG_R_CONNECTIONS_OK);
  FDataFile.FConnectionsOK := FDataFile.FConnectionsOK or Value;
end;

{ Protected declarations }

procedure TPxDataRecord.AssignTo(Source: TPersistent);
begin
  raise ENotImplemented.Create;
end;

function TPxDataRecord.GetModified: Boolean;
begin
  Result := (Header.Flags and FLAG_R_MODIFIED) = FLAG_R_MODIFIED;
end;

function TPxDataRecord.GetCreated: Boolean;
begin
  Result := (Header.Flags and FLAG_R_CREATED) = FLAG_R_CREATED;
end;

function TPxDataRecord.GetConnectionsOK: Boolean;
begin
  Result := (Header.Flags and FLAG_R_CONNECTIONS_OK) = FLAG_R_CONNECTIONS_OK;
end;

procedure TPxDataRecord.Initialize;
begin
  Header.Kind := kindInvalidRecord;
  Header.Size := 0;
end;

procedure TPxDataRecord.AfterCreate;
begin
end;

procedure TPxDataRecord.Finalize;
begin
end;

procedure TPxDataRecord.ReadFromStream(S: TStream; const RH: TPxDataRecordHeader);
begin
  Modified := False;
  Created := False;

  Header.Kind := RH.Kind;
  Header.Flags := RH.Flags;
  if Header.Size < RH.Size then
  begin
    // czytanie nadmiarowej informacji
    ReallocMem(FBuffer, RH.Size);
    Header.Size := RH.Size;
  end;
  FillChar(FBuffer^, Header.Size, 0);
  BeforeRead;
  if Assigned(DataFile.Events) then
    DataFile.Events.BeforeReadRecord(Self);
  S.Read(FBuffer^, RH.Size);
  if Assigned(DataFile.Events) then
    DataFile.Events.AfterReadRecord(Self);
  AfterRead;
end;

procedure TPxDataRecord.WriteToStream(S: TStream; OnlyIfModified: Boolean);
begin
  if (not Modified) and OnlyIfModified then
    Exit;

  if Assigned(DataFile.Events) then
    DataFile.Events.BeforeWriteRecord(Self);
  BeforeWrite;
  S.Write(Header, SizeOf(Header));
  S.Write(Buffer^, Header.Size);
  if Assigned(DataFile.Events) then
    DataFile.Events.AfterWriteRecord(Self);

  Modified := False;
  AfterWrite;
end;

procedure TPxDataRecord.BeforeRead;
begin
end;

procedure TPxDataRecord.AfterRead;
begin
end;

procedure TPxDataRecord.BeforeWrite;
begin
end;

procedure TPxDataRecord.AfterWrite;
begin
end;

procedure TPxDataRecord.BeforeFileWrite;
begin
end;

procedure TPxDataRecord.AfterFileRead;
begin
end;

procedure TPxDataRecord.OnResolveIDs(IdentResolver: TPxIdResolver);
begin
end;

{ Public declarations }

constructor TPxDataRecord.Create(AOwner: TPxBaseDataObject);
begin
  inherited Create(AOwner);
  // odnalezienie obiektu pliku (dla przyœpieszenia odczytu)
  FDataFile := Root as TPxDataFile;

  Initialize;
  if Header.Size > 0 then
  begin
    GetMem(FBuffer, Header.Size);
    FillChar(FBuffer^, Header.Size, 0);
  end;
  AfterCreate;
  
  Created := True;
end;

destructor TPxDataRecord.Destroy;
begin
  Finalize;
  if Header.Size > 0 then
    FreeMem(Buffer, Header.Size);
  inherited Destroy;
end;

function TPxDataRecord.RecordID: TIdentifier;
begin
  Result := NO_ID;
end;

{ ENotImplemented }

constructor ENotImplemented.Create;
begin
  inherited Create('Not implemented');
end;

{ TPxDataRecordList }

{ Private declarations }

function TPxDataRecordList.GetItem(Index: Integer): TPxDataRecord;
begin
  Result := TObject(inherited Items[Index]) as TPxDataRecord;
end;

{ TPxIdGenerator }

{ Protected declarations }

procedure TPxIdGenerator.Initialize;
begin
  inherited Initialize;
  Header.Kind := kindIdGenerator;
  Header.Size := SizeOf(TIdentifier);
end;

procedure TPxIdGenerator.AfterCreate;
begin
  SetLastId(MIN_AUTO_ID);
end;

{ Public declarations }

function TPxIdGenerator.NewId: TIdentifier;
begin
  Result := TIdentifier(Buffer^);
  if Result = MAX_AUTO_ID then
    raise Exception.CreateFmt(SErrorMaxIdExceeded, [Result]);
  Inc(Result);
  TIdentifier(Buffer^) := Result;
end;

function TPxIdGenerator.GetLastId: TIdentifier;
begin
  Result := TIdentifier(Buffer^);
end;

procedure TPxIdGenerator.SetLastId(Value: TIdentifier);
begin
  TIdentifier(Buffer^) := Value;
end;

{ TPxDataContainer }

{ Private declarations }

{ Protected declarations }

function TPxDataContainer.GetModified: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to Records.Count - 1 do
    if Records[I].Modified then
    begin
      Result := True;
      Break;
    end;
end;

procedure TPxDataContainer.Initialize;
begin
  inherited Initialize;
  Header.Kind := kindDataContainer;
  Header.Size := 0;
end;

procedure TPxDataContainer.CreateLists;
begin
end;

procedure TPxDataContainer.DestroyLists;
begin
end;

procedure TPxDataContainer.CreateSingles;
begin
end;

procedure TPxDataContainer.CreateAddons;
begin
end;

procedure TPxDataContainer.DestroyAddons;
begin
end;

procedure TPxDataContainer.ReadFromStream(S: TStream; const RH: TPxDataRecordHeader);
begin
  // odczytanie rekordu
  Header.Flags := RH.Flags;
  Modified := False;
  BeforeRead;
  _ReadRecords(S, RH.Size, Self, FRecords, FUnknownRecords, OnAddRecord, DataFile.FIdentRecords);
  AfterRead;
end;

procedure TPxDataContainer.WriteToStream(S: TStream; OnlyIfModified: Boolean);
var
  TempStream: TMemoryStream;
begin
  if (not Modified) and OnlyIfModified then
    Exit;

  BeforeWrite;

  // utworzenie tymczasowego strumienia pamiêciowego
  TempStream := TMemoryStream.Create;
  try
    // zapis rekordów do tymczasowego strumienia pamiêciowego
    _WriteRecords(TempStream, FRecords, FUnknownRecords, OnlyIfModified);

    // zapis do strumienia docelowego
    Header.Size := TempStream.Size;
    S.Write(Header, SizeOf(Header));
    S.Write(TempStream.Memory^, Header.Size);
    Header.Size := 0;
    // zwolnienie tymczasowego strumienia pamiêciowego
  finally
    TempStream.Free;
  end;

  Modified := False;
  AfterWrite;
end;

procedure TPxDataContainer.AfterFileRead;
var
  I: Integer;
begin
  for I := 0 to FRecords.Count - 1 do
    FRecords[I].AfterFileRead;
end;

procedure TPxDataContainer.BeforeFileWrite;
var
  I: Integer;
begin
  for I := 0 to FRecords.Count - 1 do
    FRecords[I].BeforeFileWrite;
end;

procedure TPxDataContainer.OnAddRecord(Rec: TPxDataRecord);
begin
end;

procedure TPxDataContainer.OnDelRecord(Rec: TPxDataRecord; RecordWillBeDisposed: Boolean);
begin
end;

{ Public declarations }

constructor TPxDataContainer.Create(AOwner: TPxBaseDataObject);
begin
  inherited Create(AOwner);
  FRecords := TPxDataRecordList.Create;
  FUnknownRecords := TPxDataRecordList.Create;
  if Assigned(Buffer) then
    raise EInvalidStructure.Create('Header.Size > 0 ! DataContainer cannot contain private data !');
  CreateLists;
  CreateSingles;
  CreateAddons;
end;

destructor TPxDataContainer.Destroy;
begin
  _ClearRecords(FRecords, FUnknownRecords, OnDelRecord);
  FUnknownRecords.Free;
  FRecords.Free;
  DestroyAddons;
  DestroyLists;
  inherited Destroy;
end;

function TPxDataContainer.AddRecord(Rec: TPxDataRecord): TPxDataRecord;
begin
  if FRecords.IndexOf(Rec) = -1 then
  begin
    FRecords.Add(Rec);
    OnAddRecord(Rec);
    if Assigned(DataFile.Events) then
      DataFile.Events.OnAddRecordContainer(Self, Rec);
    Result := Rec;
  end
  else raise EInvalidOperation.Create('Record is already added !');
end;

procedure TPxDataContainer.DelRecord(Rec: TPxDataRecord; FreeRecord: Boolean = False);
begin
  if FRecords.Remove(Rec) >= 0 then
  begin
    if Assigned(DataFile.Events) then
      DataFile.Events.OnDelRecordContainer(Self, Rec, FreeRecord);
    OnDelRecord(Rec, FreeRecord);
    if FreeRecord then
      Rec.Free;
  end
  else raise EInvalidOperation.Create('Record is not added !');
end;

{ TPxDataRecordEx }

{ Protected declarations }

procedure TPxDataRecordEx.CreateStream(ID: Integer; var Stream: TStream);
begin
  if Assigned(DataFile.Events) then
    DataFile.Events.OnCreateStream(Self, ID, Stream);
  if not Assigned(Stream) then
    Stream := TMemoryStream.Create;
end;

procedure TPxDataRecordEx.ReadFromStream(S: TStream; const RH: TPxDataRecordHeader);
var
  BytesRead: Integer;
  PH: TPxDataPartHeader;
  ExpectedPos: Integer;
  TmpSize: Int64;
begin
  Header.Flags := RH.Flags;
  Modified := False;
  BeforeRead;
  if Assigned(DataFile.Events) then
    DataFile.Events.BeforeReadRecord(Self);
  SetLength(FUnknownParts, 0);
  ExpectedPos := LongWord(S.Position) + RH.Size;
  repeat
    BytesRead := S.Read(PH, SizeOf(PH));

    if BytesRead < SizeOf(PH) then // error while reading part header
      raise EInvalidStructure.Create('Error while reading part of ' + ClassName + ' record !');

    if PH.Part = partEndPart then // end of parts
      Break;

    if PH.Part = partInvalidPart then // invalid part
      raise EInvalidStructure.Create('Error while reading part of ' + ClassName + ' record: PartID=0');

    case ReadPart(S, PH) of
      rprRecognized: ;
      rprDiscard: S.Seek(PH.Size, soFromCurrent);
      rprUnknown:
      begin
        // read of an unknown part
        TmpSize := PH.Size;
        SetLength(FUnknownParts, Length(FUnknownParts) + SizeOf(PH) + TmpSize);
        Move(PH, FUnknownParts[Length(FUnknownParts) - SizeOf(PH) - TmpSize], SizeOf(PH));
        S.Read(FUnknownParts[Length(FUnknownParts) - TmpSize], TmpSize);
      end;
    end;
  until False;

  // check for data integrity errors (file position, maby some day also CRC checking...)
  if S.Position <> ExpectedPos then
    raise EInvalidStructure.Create('Error while reading parts of ' + ClassName + ': Expected file position does not match.');
  if Assigned(DataFile.Events) then
    DataFile.Events.AfterReadRecord(Self);
  AfterRead;
end;

procedure TPxDataRecordEx.WriteToStream(S: TStream; OnlyIfModified: Boolean);
var
  TempStream: TMemoryStream;
  EndPart: TPxDataPartHeader;
begin
  if (not Modified) and OnlyIfModified then
    Exit;

  BeforeWrite;
  if Assigned(DataFile.Events) then
    DataFile.Events.BeforeWriteRecord(Self);

  TempStream := TMemoryStream.Create;
  try
    WriteAllParts(TempStream);
    if Length(FUnknownParts) > 0 then
      TempStream.Write(FUnknownParts[0], Length(FUnknownParts));
    EndPart.Part := partEndPart;
    EndPart.Size := 0;
    TempStream.Write(EndPart, SizeOf(EndPart));
    Header.Size := TempStream.Size;
    S.Write(Header, SizeOf(Header));
    S.Write(TempStream.Memory^, TempStream.Size);
    Header.Size := 0;
  finally
    TempStream.Free;
  end;
  if Assigned(DataFile.Events) then
    DataFile.Events.AfterWriteRecord(Self);

  Modified := False;
  AfterWrite;
end;

procedure TPxDataRecordEx.ReadData(S: TStream; var Buff; BuffSize, DataSize: Integer);
var
  ToRead: Integer;
begin
  if BuffSize < DataSize then ToRead := BuffSize
  else ToRead := DataSize;
  S.Read(Buff, ToRead);
  if BuffSize < DataSize then
    S.Seek(DataSize - BuffSize, soFromCurrent);
end;

function TPxDataRecordEx.ReadPart(S: TStream; const PH: TPxDataPartHeader): TPxReadPartResult;
var
  Str: WideString;
  ID : Word;
  TmpStream: TMemoryStream;
begin
  Result := rprUnknown;
  case PH.Part of
    partString:
    begin
      S.Read(ID, SizeOf(ID));
      SetLength(Str, (PH.Size div 2) - 1);
      if Length(Str) > 0 then
      begin
        S.Read(Str[1], PH.Size - SizeOf(ID));
        Result := ReadString(Str, ID);
      end
      else
        Result := rprRecognized;
      if Result = rprUnknown then
        S.Seek(-PH.Size, soFromCurrent);
    end;
    partStream:
    begin
      S.Read(ID, SizeOf(ID));
      TmpStream := TMemoryStream.Create;
      try
        TmpStream.CopyFrom(S, PH.Size - SizeOf(ID));
        TmpStream.Position := 0;
        Result := ReadStream(TmpStream, ID);
        if Result = rprUnknown then
          S.Seek(-PH.Size, soFromCurrent);
      finally
        TmpStream.Free;
      end;
    end;
  end;
end;

function TPxDataRecordEx.ReadString(S: WideString; const ID: Word): TPxReadPartResult;
begin
  Result := rprUnknown;
end;

function TPxDataRecordEx.ReadStream(Stream: TStream; const ID: Word): TPxReadPartResult;
begin
  Result := rprUnknown;
end;

procedure TPxDataRecordEx.WritePart(S: TStream; PartID: Word; var Data; PartSize: Longword);
var
  PH: TPxDataPartHeader;
begin
  PH.Part := PartID;
  PH.Size := PartSize;
  S.Write(PH, SizeOf(PH));
  S.Write(Data, PartSize);
end;

procedure TPxDataRecordEx.WriteString(S: TStream; ID: Word; Data: WideString);
var
  PH: TPxDataPartHeader;
begin
  PH.Part := partString;
  PH.Size := Length(Data) * 2 + SizeOf(ID);
  S.Write(PH, SizeOf(PH));
  S.Write(ID, SizeOf(ID));
  if Length(Data) > 0 then
    S.Write(Data[1], Length(Data) * 2);
end;

procedure TPxDataRecordEx.WriteStream(S: TStream; ID: Word; Data: TStream);
var
  PH: TPxDataPartHeader;
begin
  // do not save empty stream parts (saves place)
  if Data.Size > 0 then
  begin
    PH.Part := partStream;
    PH.Size := Data.Size + SizeOf(ID);
    S.Write(PH, SizeOf(PH));
    S.Write(ID, SizeOf(ID));
    Data.Position := 0;
    S.CopyFrom(Data, Data.Size);
  end;
end;

procedure TPxDataRecordEx.WriteAllParts(S: TStream);
begin
end;

{ Public declarations }

constructor TPxDataRecordEx.Create(AParent: TPxBaseDataObject);
begin
  inherited Create(AParent);
  FUnknownParts := nil;
  if Assigned(Buffer) then
    raise EInvalidStructure.CreateFmt('Header.Size > 0 in record ClassName=%s !!!', [ClassName]);
end;

destructor TPxDataRecordEx.Destroy;
begin
  FUnknownParts := nil;
  inherited Destroy;
end;

{ TPxIdResolver }

{ Private declarations }

function CompareItemsByID(P1, P2: Pointer): Integer;
var
  R1: TPxDataRecord absolute P1;
  R2: TPxDataRecord absolute P2;
begin
  if R1.RecordID < R2.RecordID then Result := -1
  else if R1.RecordID > R2.RecordID then Result := 1
  else Result := 0;
end;

function TPxIdResolver.GetItem(ID: TIdentifier): TPxDataRecord;
var
  L, R, M: Integer;
  LId, RId, MId: TIdentifier;
begin
  Result := nil; L := 0; R := FRecords.Count - 1;
  repeat
    M := (L + R) div 2;
    MId := FRecords[M].RecordID;
    LId := FRecords[L].RecordID;
    RId := FRecords[R].RecordID;

    if MId = ID then Result := FRecords[M]
    else if LId = ID then Result := FRecords[L]
    else if RId = ID then Result := FRecords[R]
    else if (L = M) or (R = M) then Break
    else if MId > ID then R := M
    else L := M;
  until Result <> nil;
end;

{ Public declarations }

constructor TPxIdResolver.Create(Records: TPxDataRecordList);
begin
  inherited Create;
  FRecords := Records;
  FRecords.Sort(@CompareItemsByID);
end;

{ TPxDataEvents }

procedure TPxDataEvents.OnCreateStream(DataRecordEx: TPxDataRecordEx; StreamID: Integer; var Stream: TStream);
begin
end;

procedure TPxDataEvents.BeforeReadRecord(DataRecord: TPxDataRecord);
begin
end;

procedure TPxDataEvents.AfterReadRecord(DataRecord: TPxDataRecord);
begin
end;

procedure TPxDataEvents.BeforeWriteRecord(DataRecord: TPxDataRecord);
begin
end;

procedure TPxDataEvents.AfterWriteRecord(DataRecord: TPxDataRecord);
begin
end;

procedure TPxDataEvents.BeforeFileWriteRecord(DataRecord: TPxDataRecord);
begin
end;

procedure TPxDataEvents.AfterFileReadRecord(DataRecord: TPxDataRecord);
begin
end;

procedure TPxDataEvents.BeforeFileWriteContainer(DataContainer: TPxDataContainer);
begin
end;

procedure TPxDataEvents.AfterFileReadContainer(DataContainer: TPxDataContainer);
begin
end;

procedure TPxDataEvents.OnAddRecordContainer(DataContainer: TPxDataContainer; DataRecord: TPxDataRecord);
begin
end;

procedure TPxDataEvents.OnDelRecordContainer(DataContainer: TPxDataContainer; DataRecord: TPxDataRecord; RecordWillBeDisposed: Boolean);
begin
end;

procedure TPxDataEvents.AfterFileReadFile(DataFile: TPxDataFile);
begin
end;

procedure TPxDataEvents.BeforeFileWriteFile(DataFile: TPxDataFile);
begin
end;

procedure TPxDataEvents.OnAddRecordFile(DataFile: TPxDataFile; DataRecord: TPxDataRecord);
begin
end;

procedure TPxDataEvents.OnDelRecordFile(DataFile: TPxDataFile; DataRecord: TPxDataRecord; RecordWillBeDisposed: Boolean);
begin
end;

procedure TPxDataEvents.OnResolveIDs(DataFile: TPxDataFile; DataRecord: TPxDataRecord; Resolver: TPxIdResolver);
begin
end;

procedure TPxDataEvents.OnSaveProgress(Min, Max, Current: Integer); 
begin
end;

{ TPxDataFile }

{ Private declarations }

procedure TPxDataFile.SetSignature(Value: TPxDataFileSignature);
begin
  FSignature := Value;
  FHeader.FileID := Value;
end;

procedure TPxDataFile.SetVersion(Value: TPxDataFileVersion);
begin
  FVersion := Value;
  FHeader.Version := Value;
end;

function ArrayOfCharToStr(First: PChar; Length: Integer): String;
var
  I: Integer;
begin
  SetLength(Result, Length);
  for I := 1 to Length do
  begin
    Result[I] := First^;
    Inc(First);
  end;
end;

function TPxDataFile.GetCreated: String;
begin
  Result := ArrayOfCharToStr(FHeader.Created, 8);
end;

procedure TPxDataFile.SetCreated(Value: String);
begin
  StringToArrayOfChar(Value, FHeader.Created);
end;

function TPxDataFile.GetLastModified: String;
begin
  Result := ArrayOfCharToStr(FHeader.Modified, 8);
end;

procedure TPxDataFile.SetLastModified(Value: String);
begin
  StringToArrayOfChar(Value, FHeader.Modified);
end;

function TPxDataFile.GetModified: Boolean;
begin
  Result := FModified;
end;

procedure TPxDataFile.SetModified(Value: Boolean);
begin
  FModified := Value;
end;

{ Protected declarations }

procedure TPxDataFile.Initialize;
begin
  Signature := 'PCDF';
  Version := '1.00';
  StringToArrayOfChar(FormatDateTime('YYYYMMDD', Now), FHeader.Created);
  StringToArrayOfChar('        ', FHeader.Modified);
end;

procedure TPxDataFile.Finalize;
begin
end;

procedure TPxDataFile.CreateLists;
begin
end;

procedure TPxDataFile.DestroyLists;
begin
end;

procedure TPxDataFile.CreateSingles;
begin
end;

procedure TPxDataFile.CreateAddons;
begin
end;

procedure TPxDataFile.DestroyAddons;
begin
end;

procedure TPxDataFile.ReadHeader(S: TStream);
var
  Count: Integer;
begin
  Count := S.Read(FHeader, SizeOf(FHeader));
  if Count <> SizeOf(FHeader) then
    raise Exception.Create('Error reading file header !');
  if FHeader.FileID <> Signature then
    raise EInvalidSignature.Create('File signature does not match !');
  if FHeader.Version <> Version then
    raise EInvalidVersion.Create('File version does not match !');
end;

procedure TPxDataFile.WriteHeader(S: TStream);
begin
  StringToArrayOfChar(FormatDateTime('YYYYMMDD', Now), FHeader.Modified);
  FHeader.FileID := FSignature;
  FHeader.Version := FVersion;
  S.Write(FHeader, SizeOf(FHeader));
end;

function TPxDataFile.RecognizeRecord(const RH: TPxDataRecordHeader; var RecordClass: TPxDataRecordClass): TPxRecognizeRecordResult;
begin
  Result := rrrUnknown;
  case RH.Kind of
    kindDataContainer:
    begin
      RecordClass := TPxDataContainer;
      Result := rrrRecognized;
    end;
  end;
end;

procedure TPxDataFile.LoadRecords(S: TStream);
begin
  _ReadRecords(S, -1, Self, FRecords, FUnknownRecords, OnAddRecord, FIdentRecords);
end;

procedure TPxDataFile.SaveRecords(S: TStream; OnlyIfModified: Boolean);
begin
  _WriteRecords(S, FRecords, FUnknownRecords, OnlyIfModified);
end;

procedure TPxDataFile.OnAddRecord(Rec: TPxDataRecord);
begin
end;

procedure TPxDataFile.OnDelRecord(Rec: TPxDataRecord; RecordWillBeDisposed: Boolean);
begin
end;

procedure TPxDataFile.AfterFileRead;
var
  I: Integer;
begin
  for I := 0 to FRecords.Count - 1 do
    FRecords[I].AfterFileRead;
end;

procedure TPxDataFile.BeforeFileWrite;
var
  I: Integer;
begin
  for I := 0 to FRecords.Count - 1 do
    FRecords[I].BeforeFileWrite;
end;

{ Public declarations }

constructor TPxDataFile.Create(AEvents: TPxDataEvents = nil);
begin
  inherited Create(nil);
  FEvents := AEvents;
  FMakeBackup := True;
  FRecords := TPxDataRecordList.Create;
  FUnknownRecords := TPxDataRecordList.Create;
  FIdentRecords := TPxDataRecordList.Create;
  CreateLists;
  CreateSingles;
  CreateAddons;
  Initialize;
end;

destructor TPxDataFile.Destroy;
begin
  _ClearRecords(FRecords, FUnknownRecords, OnDelRecord);
  FIdentRecords.Free;
  FUnknownRecords.Free;
  FRecords.Free;
  DestroyAddons;
  DestroyLists;
  if Assigned(Events) then
    FreeAndNil(FEvents);
  inherited Destroy;
end;

function TPxDataFile.KindIdToClass(Kind: UInt16): TPxDataRecordClass;
var
  H: TPxDataRecordHeader;
begin
  Result := nil;
  H.Kind := Kind;
  case RecognizeRecord(H, Result) of
    rrrUnknown: Result := nil;
  end;
end;

procedure TPxDataFile.ResolveIds(DataRecord: TPxDataRecord = nil);
var
  I: Integer;
  Resolver: TPxIdResolver;
begin
  // check if IdentRecords list is already filled - if not - fill it
  if FIdentRecords.Count = 0 then
    for I := 0 to Records.Count - 1 do
      if Records[I].RecordID <> NO_ID then
        FIdentRecords.Add(Records[I]);
  Resolver := TPxIdResolver.Create(FIdentRecords);
  try
    if Assigned(DataRecord) then
    begin
      DataRecord.OnResolveIDs(Resolver);
      if Assigned(Events) then
        Events.OnResolveIDs(Self, DataRecord, Resolver);
    end
    else
      for I := 0 to FIdentRecords.Count - 1 do
      begin
        FIdentRecords[I].OnResolveIDs(Resolver);
        if Assigned(Events) then
          Events.OnResolveIDs(Self, FIdentRecords[I], Resolver);
      end;
  finally
    Resolver.Free;
  end;
end;

function TPxDataFile.AddRecord(Rec: TPxDataRecord): TPxDataRecord;
begin
  if FRecords.IndexOf(Rec) = -1 then
  begin
    FRecords.Add(Rec);
    OnAddRecord(Rec);
    if Assigned(Events) then
      Events.OnAddRecordFile(Self, Rec);
    FModified := True;
    Result := Rec;
  end
  else raise EInvalidOperation.Create('Record is already added !');
end;

procedure TPxDataFile.DelRecord(Rec: TPxDataRecord; FreeRecord: Boolean = False);
begin
  if FRecords.Remove(Rec) >= 0 then
  begin
    if Assigned(Events) then
      Events.OnDelRecordFile(Self, Rec, FreeRecord);
    OnDelRecord(Rec, FreeRecord);
    FModified := True;
    if FreeRecord then
      Rec.Free;
  end
  else raise EInvalidOperation.Create('Record is not added !');
end;

procedure TPxDataFile.Clear(RecreateSingles: Boolean = True);
begin
  FIdentRecords.Clear;
  _ClearRecords(FRecords, FUnknownRecords, OnDelRecord);
  if RecreateSingles then
    CreateSingles;
end;

procedure TPxDataFile.Load(FileName: TFileName);
var
  S: TStream;
  I: Integer;
begin
  FFileName := ExpandFileName(FileName);
  if not FileExists(FileName) then Exit;
  S := TFileStream.Create(FileName, fmOpenRead);
  try
    Load(S);
  finally
    S.Free;
  end;
  FModified := False;
  AfterFileRead;
  if Assigned(Events) then
  begin
    Events.AfterFileReadFile(Self);
    for I := 0 to Records.Count - 1 do
      if Records[I] is TPxDataContainer then
        Events.AfterFileReadContainer(Records[I] as TPxDataContainer)
      else
        Events.AfterFileReadRecord(Records[I]);
  end;
end;

procedure TPxDataFile.Load(S: TStream);
begin
  FIdentRecords.Clear;
  _ClearRecords(FRecords, FUnknownRecords, OnDelRecord);
  CreateSingles;
  if S.Size > SizeOf(FHeader) then
  begin
    ReadHeader(S);
    LoadRecords(S);
    ResolveIds;
  end;
end;

procedure TPxDataFile.Merge(FileName: TFileName);
var
  S: TStream;
  I: Integer;
begin
  FFileName := ExpandFileName(FileName);
  if not FileExists(FileName) then Exit;
  S := TFileStream.Create(FileName, fmOpenRead);
  try
    Merge(S);
  finally
    S.Free;
  end;
  FModified := False;
  AfterFileRead;
  if Assigned(Events) then
  begin
    Events.AfterFileReadFile(Self);
    for I := 0 to Records.Count - 1 do
      if Records[I] is TPxDataContainer then
        Events.AfterFileReadContainer(Records[I] as TPxDataContainer)
      else
        Events.AfterFileReadRecord(Records[I]);
  end;
end;

procedure TPxDataFile.Merge(S: TStream);
begin
  if S.Size > SizeOf(FHeader) then
  begin
    ReadHeader(S);
    LoadRecords(S);
    ResolveIds;
  end;
end;

procedure TPxDataFile.Save(NewFileName: TFileName = ''; OnlyChangedRecords: Boolean = False);
var
  S: TStream;
  NewName: String;
  I: Integer;
begin
  if NewFileName <> '' then
    FFileName := NewFileName;
  // sprawdzenie, czy rekordy maj¹ przypisany identyfikator Header.Kind
  for I := 0 to Records.Count - 1 do
    if Records[I].Header.Kind = kindInvalidRecord then
      raise EInvalidOperation.CreateFmt('Record ClassName=%s not initialized for writting', [Records[I].ClassName]);

  BeforeFileWrite;
  if Assigned(Events) then
  begin
    Events.BeforeFileWriteFile(Self);
    for I := 0 to Records.Count - 1 do
      if Records[I] is TPxDataContainer then
        Events.BeforeFileWriteContainer(Records[I] as TPxDataContainer)
      else
        Events.BeforeFileWriteRecord(Records[I])
  end;

  ExpandFileName(FFileName);
  if MakeBackup and FileExists(FFileName) then
  begin
    // zrób backup z poprzedniej wersji pliku
    NewName := Copy(FFileName, 1, Length(FFileName) - Length(ExtractFileExt(FFileName))) + '.~' + Copy(ExtractFileExt(FFileName), 2, Length(ExtractFileExt(FFileName)) - 1);
    try
      // usuñ poprzedni¹ wersjê pliku - robimy backup
      if FileExists(NewName) then
        DeleteFile(NewName);
      RenameFile(FFileName, NewName);
    except
      raise EInvalidOperation.Create('Unable to create backup file !');
    end;
  end;
  S := TFileStream.Create(FFileName, fmCreate);
  try
    Save(S, OnlyChangedRecords);
  finally
    S.Free;
  end;
  FModified := False;
end;

procedure TPxDataFile.Save(S: TStream; OnlyChangedRecords: Boolean = False);
begin
  WriteHeader(S);
  SaveRecords(S, OnlyChangedRecords);
end;

{$IFDEF VER150}
procedure TPxDataFile.WriteXML(FileName: TFileName);
var
  F: TextFile;
  procedure SerializeXML(Data: TPersistent);
    function GetTagName(Obj: TObject): String;
    begin
      Result := Obj.ClassName;
      if (Result[1] = 'T') and (UpCase(Result[2]) = Result[2]) then
        Delete(Result, 1, 1);
    end;
    procedure DoSerialize(Data: TObject; Indent: String);
    var
      I: Integer;
      TI: PTypeInfo;
      TD: PTypeData;
      PL: PPropList;
      Col: TCollection;
      List: TList;
      TmpData: TObject;
    begin
      TI := Data.ClassInfo;
      if Assigned(TI) then
      begin
        if Data is TCollection then
        begin
          Col := Data as TCollection;
          if Col.Count > 0 then
          begin
            Writeln(F, Indent, '<', GetTagName(Data), '>');
            for I := 0 to Col.Count - 1 do
              DoSerialize(Col.Items[I], Indent + #9);
            Writeln(F, Indent, '</', GetTagName(Data), '>');
          end;
        end
        else if Data is TPersistent then
        begin
          Writeln(F, Indent, '<', GetTagName(Data), '>');
          TD := GetTypeData(TI);
          GetMem(PL, TD^.PropCount * SizeOf(PPropInfo));
          if TD^.PropCount > 0 then
            GetPropList(TI, PL);
          for I := 0 to TD^.PropCount - 1 do
          begin
            if PL^[I]^.PropType^.Kind = tkClass then
            begin
              TmpData := GetObjectProp(Data, PL^[I]);
              DoSerialize(TmpData, Indent + #9);
            end
            else if PL^[I]^.GetProc <> nil then
            begin
              // only readable properties are stored
              Write(F, Indent, #9'<' + PL^[I]^.Name + '>');
              Write(F, String(GetPropValue(Data, PL^[I]^.Name)));
              Writeln(F, '</' + PL^[I]^.Name + '>');
            end;
          end;
          Writeln(F, Indent, '</', GetTagName(Data), '>');
          FreeMem(PL);
        end;
      end
      else if Data is TList then
      begin
        List := Data as TList;
        if List.Count > 0 then
        begin
          Writeln(F, Indent, '<', GetTagName(Data), '>');
          for I := 0 to List.Count - 1 do
          begin
            if (List[I] <> nil) and (TObject(List[I]) is TPersistent) then
              DoSerialize(List[I], Indent + #9);
          end;
          Writeln(F, Indent, '</', GetTagName(Data), '>');
        end;
      end
    end;
  begin
  // This is how you set the property value as text (variant)
  // if PL^[I]^.SetProc <> nil then
  //   SetPropValue(Data, PL^[I]^.Name, '999');
    DoSerialize(Data, '');
  end;

begin
  AssignFile(F, FileName);
  Rewrite(F);
  Writeln(F, '<?xml version="1.0" encoding="Windows-1250" ?>');
  Writeln(F);
  SerializeXML(Self);
  CloseFile(F);
end;
{$ENDIF}

{ TPxCompressedDataFile }

{ Private declarations }

function TPxCompressedDataFile.GetCompressed: Boolean;
begin
  Result := Flags and FLAG_F_COMPRESSED = FLAG_F_COMPRESSED;
end;

procedure TPxCompressedDataFile.SetCompressed(Value: Boolean);
begin
  if Value then
    Flags := Flags or FLAG_F_COMPRESSED
  else
    Flags := Flags and (not FLAG_F_COMPRESSED);
end;

{ Protected declaraitons }

procedure TPxCompressedDataFile.LoadRecords(S: TStream);
var
  TmpStr: TStream;
begin
  if Compressed then
  begin
{$IFDEF BZIP2_COMPRESSION}
    TmpStr := TBzDecompressionStream.Create(S);
{$ELSE}
    TmpStr := TDecompressionStream.Create(S);
{$ENDIF}
    try
      inherited LoadRecords(TmpStr);
    finally
      TmpStr.Free;
    end;
  end
  else inherited LoadRecords(S);
end;

procedure TPxCompressedDataFile.SaveRecords(S: TStream; OnlyIfModified: Boolean = False);
var
  TmpStr: TStream;
begin
  if Compressed then
  begin
{$IFDEF BZIP2_COMPRESSION}
    TmpStr := TBzCompressionStream.Create(bs1, S);
{$ELSE}
    TmpStr := TCompressionStream.Create(FCompressionLevel, S);
{$ENDIF}
    try
      inherited SaveRecords(TmpStr, OnlyIfModified);
    finally
      TmpStr.Free;
    end;
  end
  else inherited SaveRecords(S, OnlyIfModified);
end;

{ Public declarations }

constructor TPxCompressedDataFile.Create(AEvents: TPxDataEvents = nil);
begin
  inherited Create;
  Compressed := True;
{$IFNDEF BZIP2_COMPRESSION}
  FCompressionLevel := clMax;
{$ENDIF}
end;

end.
