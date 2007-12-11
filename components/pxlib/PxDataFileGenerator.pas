// --------------------------------------------------------------------------------------------
// Unit : PxDataFileGenenerator.pas - a part of PxLib
// Autor: Matthias "Padcom" Hryniszak
//  Data : 2003-11-10 - the first object-oriented version.
//                   - added data validation (if the identifiers of classes, parts and fields are
//                     valid and also if the entered id's are valid). The rest is checked by
//                     delphi compiler
//        2003-11-11 - added generation of data containers (TPxDataContainer descendants)
//        2003-11-12 - added generation of LoadXml() and SaveXml() methods if the parameter
//                     XmlMethods="True" for DataFile item is given in config file.
//                     While reading data from xml file a basic checking is done (not only the
//                     tag name but also the ID field. If ID is diferent than the one that is
//                     expected this record is skipped !
//                     WARNING ! Unrecognized records are NOT SAVED to xml file as binary data
//                     (but they are stored in binary form anyway)
//                   - added saving and loading of image parts into and from xml file in
//                     MIME Format.
//        2004-01-12 - added generation of array parts.
//                   - fixed error handling routines in source files (.xfd)
//        2004-01-13 - fixed support for reading and writing array parts from/into xml file.
//        2004-02-22 - added support for generating code for reading and writing of float parts
//        2004-02-23 - added support for generating code for resolving records via RecordID
//        2004-03-06 - changed the way that records are saved and loaded from Xml file.
//                     Now the records in binary file and Xml file are stored in the same order.
//                   - added possibility to inherit a record and a file from another class
//                     insetead of a default
//        2004-03-25 - added support for using StreamParts
//        2004-03-27 - added support for function that gets values from string, ie.
//                     'RECORD[index].FIELD' or 'RECORD.Count' or 'CONTAINER[index].RECORD.FIELD'
//                     or 'CONTAINER[index].RECORD.Count' or 'CONTAINER.Count' - basicly for use
//                     with TMathParser or GetFormulaValue() (see MathParser.pas)
//        2004-03-28 - zapis i odczyt podczêœci typu TExpression
//                   - poprawki do zapisu i odczytu podczêœci typu FloatPart do formatu Xml
//        2004-04-11 - removed TPNGImage support (now image parts are stored as TBitmap)
//        2004-06-15 - added generation of run-time fields (see <RuntimeField> definition)
//        2004-06-16 - fixed generation of SaveXml and LoadXml methods: In some cases an "else"
//                     was generated for the first element.
//                   - renamed GenerateXmlMethods to XmlMethods
//                   - renamed ValueByNameFunc to DataByNameMethod
//        2004-06-17 - fixed problem with TPxDataRecord.RecordIdField by adding "D." to generator
//        2004-07-20 - stripped IDENT_RESOLVER conditional define (see DataFile.pas)
//        2004-07-22 - fixed diagnostic (still not perfect, but already useable !)
//        2004-12-09 - added method Assign into base class for all records (TPxDataRecord)
//                   - added generation of Assign methods for ERIS classes
//        2004-12-15 - changed the method of creating list names (not not-single records) to more intelligent.
//                     It's still not perfect, but now it's centralized so extending it should bring no more
//                     problems. Check the "GetListName" function to see more.
//        2005-02-24 - moved "public" properties (where possible) to "published" section to allow
//                     Xml Serialization (todo)
//        2005-02-28 - RecordId field is removed from AssignTo method. The reason for it is that the records
//                     are supposed to have unique IDs and assigning this value would violate this assumption.
//        2005-03-04 - fix: IdGenerator has been stored more than once
//        2005-06-16 - imported into PxLib
//                   - stripped down image part (use stream parts instead)
//                   - stripped down database load/save stuff
//        2005-09-08 - stripped down database load/save stuff (definitive)
//  Descr: This is a delphi code generator can be used to generate valid object pascal code that
//        handles objects defined in DataFile.pas. If the source file (a'la xml format) is valid
//        then once the code is generated it should compile out-of-the-box with no problems.
//        To add additional handling of events for data objects you should use a TDataEvents
//        descendant and pass it's instance as parameter for TPxDataFile descendant's constructor.
//  Uwagi: Plik opisuj¹cy strukturê binarn¹ zapisywany jest w formie a'la Xml.
//         Przyk³ad (wykorzystuj¹cy wszystkie mo¿liwoœci generatora, kapitalikami zapisano
//        elementy, które musz¹ wyst¹piæ):
//         <DataFile NAME="SampleFile" Signature="test" Version="1.00" XmlMethods="True" StricTPxXMLItemCheck="False" ResolveXmlIncludes="True" ParentClass="" DataByNameMethod="False">
//           <!-- definicja prostego rekordu pojedynczego -->
//          <DataRecord NAME="SimpleSingle" ID="1" Single="True" ParentClass="">
//            <Field NAME="Data1" TYPE="Integer"/>
//            <RuntimeField NAME="field_name" TYPE="field_type" CreateInstance="boolean" CreateParams="create_params"/>
//          </DataRecord>
//           <!-- definicja zlozonego rekordu pojedynczego z okreœleniem identyfikatora rekordu -->
//          <DataRecordEx NAME="ExtendedSingle" ID="2" Single="True" RecordIDField="ID" ParentClass="">
//            <DataPart NAME="D" ID="1">
//              <Field NAME="Data" Type="Double"/>
//              <Field NAME="ID" Type="TIdentifier"/>
//            </DataPart>
//            <ArrayPart NAME="MyArray" ID="1">
//              <Field NAME="Data" Type="Double"/>
//            </ArrayPart>
//            <StringPart NAME="TestStr" ID="1"/>
//            <FloatPart NAME="TestFloat" ID="1" UnitFamily="cbDistance" UnitName="duMeters"/>
//            <RuntimeField NAME="field_name" TYPE="field_type" CreateInstance="boolean" CreateParams="create_params"/>
//          </DataRecordEx>
//           <!-- definicja prostego rekordu wielokrotnego -->
//          <DataRecord NAME="SimpleMulit" ID="3" Single="False" ContainerRecordOnly="True">
//            <Field NAME="Data1" TYPE="Integer"/>
//          </DataRecord>
//           <!-- definicja zlozonego rekordu wielokrotnego -->
//          <DataRecordEx NAMe="ExtendedMulit" ID="4" Single="False">
//            <DataPart NAME="D" ID="1">
//              <Field NAME="Data" TYPE="Double"/>
//            </DataPart>
//            <StringPart NAME="TestStr" ID="1"/>
//            <FloatPart NAME="TestFloat" ID="1" UnitFamily="cbDistance" UnitName="duMeters"/>
//            <StreamPart NAME="TestStm" ID="1"/>
//            <ExpressionPart NAME="TestExp" ID="1" UnitFamily="cbDistance" UnitName="duMeters" Expression=""/>
//          </DataRecordEx>
//           <DataContainer NAME="Container" ID="5">
//            <!-- wskazania rekordów zawieraj¹cych siê w kontenerze danych -->
//            <DataRecord ID="1"/>
//            <DataRecordEx ID="3"/>
//          </DataContainer>
//        </DataFile>
//
//        Opis znaczników:
//        ----------------
//         DataFile -> NAME
//          Nazwa unitu i g³ownej klasy dla pliku
//         DataFile -> Signature
//          Sygnatura pliku (pierwsze 4 znaki, zawsze 4 bajty)
//         DataFile -> Version
//          Wersja pliku (kolejne 4 znaki, zawsze 4 bajty)
//         DataFile -> GenerateXmlMethods
//          Sterowanie generacj¹ metod LoadXml i SaveXml
//         DataFile -> StricTPxXMLItemCheck
//          Sterowanie generacj¹ zawartoœci metod LoadXml i SaveXml: dodatkowe zapisywanie, odczytywanie i sprawdzanie
//          w³aœciwoœci o nazwie ID dla rekordów zapisywanych do pliku Xml
//         DataFile -> ResolveXmlIncludes
//          Sterowanie wczytywaniem plików do³¹czanych (include) przy wczytywaniu danych z plików Xml
//         DataFile -> DataByNameMethod
//          Sterowanie tworzeniem funkcji GetValue(String): Extended (do pobierania danych opisanych tekstem,
//          u¿ycie wskazane z GetFormulaValue() lub TMathParser (MathParser.pas))
//         DataFile, DataRecord, DataRecordEx -> ParentClass
//          Nazwa klasy nmadrzêdnej (je¿eli inna ni¿ domyœlna)
//         DataRecord, DataRecordEx -> NAME
//          Nazwa klasy dla prostego rekordu danych oraz podstawa do tworzenia nazwy zmiennych
//          i typu listy je¿eli element nie wystêpuje pojedynczo
//         DataRecord, DataRecordEx -> ID
//          Identyfikator rekordu
//         DataRecord, DataRecordEx -> Single
//          Oznaczenie, czy rekord wystêpuje w pliku tylko raz. Dla takiego rekordu nie zostanie
//          utworzona lista a jedynie pojedyncze pole w klasie pliku
//         DataRecord, DataRecordEx -> ContainerRecordOnly
//          Oznaczenie, czy rekord ma wchodziæ w sk³ad rekordów przypisanych bezpoœrednio do pliku,
//          czy ma wystêpowaæ tylko w ramach kontenerów danych
//         DataRecordEx -> DataPart
//          Podczêœæ rekordu zawieraj¹ca dane o niezmiennej d³ugoœci (zwykle pola liczbowe, ale
//          równie¿ boolean, char[xxx], widechar[xxx])
//         DataRecordEx -> ArrayPart
//          Podczêœæ analoginczna do DataRecordEx -> DataPart, zawieraj¹ca tablicê danych o niezmiennej
//          d³ugoœci.
//         DataRecordEx -> StringPart
//          Podczêœæ rekordu zawieraj¹ca dane znakowe (napisy)
//         DataRecordEx -> FloatPart
//          Podczêœæ rekordu zawieraj¹ca dane zmiennoprzecinkowe (wartoœæ, rodzinê i jednostkê)
//         DataRecordEx -> StreamPart
//          Podczêœæ rekordu zawieraj¹ca niezidentyfikowane dane
//         DataRecordEx -> ExpressionPart
//          Podczêœæ rekordu zawieraj¹ca wyra¿enie (tekst, rodzinê i jednostkê)
//         DataRecordEx -> DataPart, StringPart, StreamPart, ExpressionPart -> ID
//          Identyfikator podczêœci
//         DataRecordEx -> DataPart, StringPart, StreamPart, ExpressionPart -> NAME
//          Nazwa podczêœci (wykorzystywana do tworzenia pól w klasie rekordu z³o¿onego)
//         DataRecordEx -> DataPart -> Field
//          Definicja pola danych w podczêœci z elementami o sta³ych d³ugoœciach
//         DataRecordEx -> DataPart -> Field -> NAME
//          Nazwa pola danych (wykorzystywana do utworzenia pola w spakowanym rekordzie danych
//          oraz propertisa dla klasy)
//         DataRecordEx -> DataPart -> Field -> TYPE
//          Typ pola danych (wykorzystywany do utworzenia pola w spakowanym rekordzie danych
//          oraz propertisa dla klasy)
//         DataRecord, DataRecordEx -> RuntimeField
//          Definicja pola tworzonego tyko na czas trwania aplikacji (dane nie zapisywane do pliku
//          binarnego ani do pliku Xml). Mo¿e by tworzona instancja (je¿eli pole jest typu klasowego,
//          parametr CreateInstance), a do konstruktora przekazane mog¹ by parametry (zapis w
//          CreateParams, BEZ NAWIASÓW!).
//          Uwaga: Nie jest sprawdzane, czy podana nazwa klasy jest poprawna oraz czy parametry
//          przekazane do konstruktora maj¹ sens.
//         DataContainer -> NAME
//          Nazwa klasy dla konteneradanych oraz podstawa do tworzenia nazwy zmiennych i typu listy
//         DataContainer -> ID
//          Identyfikator rekordu
//         DataContainer -> DataRecord, DataRecordEx -> ID
//          Identyfikator rekordu (musi byæ wczeœniej zdefiniowany).
//
//        - Only DataParts and StringParts are stored into database!
//  Cond : To use float parts declare DATARECORDEX_PART_FLOAT directive (Delphi7 only !)
//  ToDo : - Testing, comments in code, documentation...
//        - automaticaly generate record that stores ID of last added element and can give a new one
//        - automaticaly resolve connections between objects (ResolveIds)
//        - flag parts
//        - getting/setting parts in form RECORD[index].FIELD (not only numeral fields)
// -------------------------------------------------------------------------------------------- 

unit PxDataFileGenerator;

{$I PxDefines.inc}

interface

uses
  Classes, SysUtils;

function GenerateDataFile(var FileName: String; OutputFile: String = ''): Boolean;

var
  ErrorMsg: String = '';

implementation

uses
{$IFDEF VER130}
  PxDelphi5,
{$ENDIF}  
  PxXmlFile, PxCodeGen, Math;

type
  TPxCGDataFileBase = class (TPxCGBase)
    procedure CreateXmlRead(Output: TPxCGOutput); virtual;
    procedure CreateXmlWrite(Output: TPxCGOutput); virtual;
  end;

  TPxCGField = class (TPxCGDataFileBase)
  protected
    procedure ReadParams; override;
  public
    FieldName: String;
    FieldType: String;
    procedure CreateXmlRead(Output: TPxCGOutput); override;
    procedure CreateXmlWrite(Output: TPxCGOutput); override;
  end;

  TPxCGRuntimeField = class (TPxCGField)
  protected
    procedure ReadParams; override;
  public
    CreateInstance: Boolean;
    CreateParams: String;
  end;

  TPxCGAddToListItem = class (TPxCGBase)
  protected
    procedure ReadParams; override;
  public
    Field: String;
    RecordType: String;
    RecordField: String;
  end;

  TPxCGDataRecord = class (TPxCGDataFileBase)
  private
    // TODO: CreateLoadProps and CreateSaveProps for TPxDataRecord
    procedure CreateLoadProps(Output: TPxCGOutput);
    procedure CreateSaveProps(Output: TPxCGOutput);
  protected
    procedure ReadParams; override;
    function HasRuntimeFieldsWithCreateInstance: Boolean;
    procedure CreateListInterface(Output: TPxCGOutput);
    procedure CreateListImplementation(Output: TPxCGOutput);
    procedure CreateBeginningOfReadXml(Output: TPxCGOutput; MultiField: Boolean);
    procedure CreateEndingOfReadXml(Output: TPxCGOutput; MultiField: Boolean);
    procedure CreateAssign(Output: TPxCGOutput; RecordIdField: String); virtual;
  public
    Name: String;
    Id: String;
    Single: Boolean;
    ContainerRecordOnly: Boolean;
    NowInContainer: Boolean;
    ContainerVariable: String;
    Fields: TPxCGBaseList;
    RuntimeFields: TPxCGBaseList;
    RecordIDField: String;
    ParentClass: String;
    PropsStreamingMethods: Boolean;
    AddToLists: TPxCGBaseList;
    AssignMethod: Boolean;
    destructor Destroy; override;
    procedure CreateInterface(Output: TPxCGOutput); override;
    procedure CreateImplementation(Output: TPxCGOutput); override;
    procedure CreateXmlRead(Output: TPxCGOutput); override;
    procedure CreateXmlWrite(Output: TPxCGOutput); override;
  end;

  TPxCGDataRecordEx = class (TPxCGDataRecord)
  private
    procedure CreateLoadProps(Output: TPxCGOutput);
    procedure CreateSaveProps(Output: TPxCGOutput);
    procedure CreateOnResolveIDs(Output: TPxCGOutput);
  protected
    function HasFieldsWithID: Boolean;
    procedure ReadParams; override;
    procedure CreateAssign(Output: TPxCGOutput; RecordIdField: String); override;
  public
    DataParts: TPxCGBaseList;
    ArrayParts: TPxCGBaseList;
    StringParts: TPxCGBaseList;
    FloatParts: TPxCGBaseList;
    StreamParts: TPxCGBaseList;
    ExpressionParts: TPxCGBaseList;
    destructor Destroy; override;
    procedure CreateInterface(Output: TPxCGOutput); override;
    procedure CreateImplementation(Output: TPxCGOutput); override;
    procedure CreateXmlRead(Output: TPxCGOutput); override;
    procedure CreateXmlWrite(Output: TPxCGOutput); override;
  end;

  TPxCGPart = class (TPxCGDataFileBase)
  protected
    procedure ReadParams; override;
  public
    Name: String;
    Id: String;
  end;

  TPxCGDataPart = class (TPxCGPart)
  protected
    procedure ReadParams; override;
  public
    Fields: TPxCGBaseList;
    destructor Destroy; override;
    procedure CreateInterface(Output: TPxCGOutput); override;
    procedure CreateXmlRead(Output: TPxCGOutput); override;
    procedure CreateXmlWrite(Output: TPxCGOutput); override;
  end;

  TPxCGArrayPart = class (TPxCGPart)
  protected
    procedure ReadParams; override;
  public
    Fields: TPxCGBaseList;
    destructor Destroy; override;
    procedure CreateInterface(Output: TPxCGOutput); override;
    procedure CreateImplementation(Output: TPxCGOutput); override;
    procedure CreateXmlRead(Output: TPxCGOutput); override;
    procedure CreateXmlWrite(Output: TPxCGOutput); override;
  end;

  TPxCGStringPart = class (TPxCGPart)
    procedure CreateInterface(Output: TPxCGOutput); override;
    procedure CreateXmlRead(Output: TPxCGOutput); override;
    procedure CreateXmlWrite(Output: TPxCGOutput); override;
  end;

  TPxCGFloatPart = class (TPxCGPart)
  protected
    procedure ReadParams; override;
  public
    UnitFamily: String;
    UnitName: String;
    procedure CreateInterface(Output: TPxCGOutput); override;
    procedure CreateXmlRead(Output: TPxCGOutput); override;
    procedure CreateXmlWrite(Output: TPxCGOutput); override;
  end;

  TPxCGStreamPart = class (TPxCGPart)
    procedure CreateInterface(Output: TPxCGOutput); override;
    procedure CreateXmlRead(Output: TPxCGOutput); override;
    procedure CreateXmlWrite(Output: TPxCGOutput); override;
  end;

  TPxCGExpressionPart = class (TPxCGPart)
  protected
    procedure ReadParams; override;
  public
    UnitFamily: String;
    UnitName: String;
    Expression: String;
    procedure CreateInterface(Output: TPxCGOutput); override;
    procedure CreateXmlRead(Output: TPxCGOutput); override;
    procedure CreateXmlWrite(Output: TPxCGOutput); override;
  end;

  TPxCGDataContainerRecord = class (TPxCGBase)
  protected
    procedure ReadParams; override;
  public
    Id: String;
  end;

  TPxCGDataContainerRecordEx = class (TPxCGDataContainerRecord)
  end;

  TPxCGDataContainer = class (TPxCGDataFileBase)
  private
    function HasSingles: Boolean;
    function HasLists: Boolean;
    procedure ResolveRecords;
    procedure CreateListInterface(Output: TPxCGOutput);
    procedure CreateListImplementation(Output: TPxCGOutput);
  protected
    procedure ReadParams; override;
  public
    Name: String;
    Id: String;
    DataRecords: TPxCGBaseList;
    DataRecordsEx: TPxCGBaseList;
    DataItems: TPxCGBaseList;
    destructor Destroy; override;
    procedure CreateInterface(Output: TPxCGOutput); override;
    procedure CreateImplementation(Output: TPxCGOutput); override;
    procedure CreateXmlRead(Output: TPxCGOutput); override;
    procedure CreateXmlWrite(Output: TPxCGOutput); override;
  end;

  TPxCGUseUnit = class (TPxCGBase)
  protected
    procedure ReadParams; override;
  public
    Name: String;
  end;

  TPxCGDataFile = class (TPxCGBase)
  private
    function HasRecordsWithArrays: Boolean;
    function HasRecordsWithFloats: Boolean;
    function HasRecordsWithRecordID: Boolean;
    function HasSingles: Boolean;
    function HasLists(IncludeContainerRecords: Boolean = False): Boolean;
    function HasContainers: Boolean;
    function HasContainersWithLists: Boolean;
    function HasExpressionParts: Boolean;
    procedure CreateGetDataByName(Output: TPxCGOutput);
  protected
    procedure ReadParams; override;
    procedure AddUnits(Output: TPxCGOutput); override;
    procedure AddRemarks(Output: TPxCGOutput); override;
  public
    Name: String;
    OutputDir: String;
    Signature: String;
    Version: String;
    ParentClass: String;
    GenerateXmlMethods: Boolean;
    StricTPxXMLItemCheck: Boolean;
    ResolveXmlIncludes: Boolean;
    Compressed: Boolean;
    GetDataByNameMethod: Boolean;
    AdditionalUnits: TPxCGBaseList;
    DataRecords: TPxCGBaseList;
    DataRecordsEx: TPxCGBaseList;
    DataContainers: TPxCGBaseList;
    DataItems: TPxCGBaseList;
    DBConnectString: String;
    destructor Destroy; override;
    procedure CreateInterface(Output: TPxCGOutput); override;
    procedure CreateImplementation(Output: TPxCGOutput); override;
  end;

{ TPxCGDataFileBase }

procedure TPxCGDataFileBase.CreateXmlRead(Output: TPxCGOutput);
begin

end;

procedure TPxCGDataFileBase.CreateXmlWrite(Output: TPxCGOutput);
begin
end;

{ TPxCGField }

{ Private declarations }

{ Protected declarations }

procedure TPxCGField.ReadParams;
var
  OwnerName: String;
begin
  if Xml.HasParam('Name') then
    FieldName := Xml.GetParamByNameS('Name');
  if Xml.HasParam('Type') then
    FieldType := Xml.GetParamByNameS('Type');

  if Owner is TPxCGDataRecord then
    OwnerName := 'DataRecord "' + TPxCGDataRecord(Owner).Name + '"'
  else if Owner is TPxCGPart then
    OwnerName := 'DataRecordEx "' + TPxCGDataRecordEx(Owner.Owner).Name + '.' + TPxCGPart(Owner).Name + '" (' + Owner.ClassName + ')'
  else
    OwnerName := Owner.ClassName + ' "???"';

  // sprawdzenie poprawnoœci danych
  if not IsValidName(FieldName) then
    raise EGeneratorException.CreateFmt('Invalid <Field NAME="%s" ... /> in %s', [FieldName, OwnerName]);
  if not IsValidName(FieldType) then
    raise EGeneratorException.CreateFmt('Invalid <Field TYPE="%s" ... /> in %s', [FieldType, OwnerName]);
end;

{ Public declarations }

function _IsArrayOfChar(S: String): Boolean;
begin
  Result := True;
  if not SameText('array', Copy(S, 1, 5)) then
    Result := False
  else if (Pos('[', S) = 0) or (Pos(']', S) = 0) then
    Result := False
  else if not SameText(' of char', Copy(S, Length(S) - 7, 8)) then
    Result := False;
end;

procedure TPxCGField.CreateXmlRead(Output: TPxCGOutput);
var
  S: String;
begin
  if Owner is TPxCGPart then S := FieldName
  else S := 'D.' + FieldName;
  Output.AddLine('with GetItemByName(''' + FieldName + ''') do');
  Output.IncIndent;
    if UpperCase(FieldType) = 'INTEGER' then
      Output.AddLine(S + ' := GetParamByName(''Value'').AsInteger;')
    else if UpperCase(FieldType) = 'TIDENTIFIER' then
      Output.AddLine(S + ' := GetParamByName(''Value'').AsInteger;')
    else if UpperCase(FieldType) = 'WORD' then
      Output.AddLine(S + ' := GetParamByName(''Value'').AsInteger;')
    else if UpperCase(FieldType) = 'DWORD' then
      Output.AddLine(S + ' := GetParamByName(''Value'').AsInteger;')
    else if UpperCase(FieldType) = 'LONGWORD' then
      Output.AddLine(S + ' := GetParamByName(''Value'').AsInteger;')
    else if UpperCase(FieldType) = 'SHORTINT' then
      Output.AddLine(S + ' := GetParamByName(''Value'').AsInteger;')
    else if UpperCase(FieldType) = 'BYTE' then
      Output.AddLine(S + ' := GetParamByName(''Value'').AsInteger;')
    else if UpperCase(FieldType) = 'TCOLOR' then
      Output.AddLine(S + ' := GetParamByName(''Value'').AsInteger;')
    else if UpperCase(FieldType) = 'INT8' then
      Output.AddLine(S + ' := GetParamByName(''Value'').AsInteger;')
    else if UpperCase(FieldType) = 'UINT8' then
      Output.AddLine(S + ' := GetParamByName(''Value'').AsInteger;')
    else if UpperCase(FieldType) = 'INT16' then
      Output.AddLine(S + ' := GetParamByName(''Value'').AsInteger;')
    else if UpperCase(FieldType) = 'UINT16' then
      Output.AddLine(S + ' := GetParamByName(''Value'').AsInteger;')
    else if UpperCase(FieldType) = 'INT32' then
      Output.AddLine(S + ' := GetParamByName(''Value'').AsInteger;')
    else if UpperCase(FieldType) = 'UINT32' then
      Output.AddLine(S + ' := GetParamByName(''Value'').AsInteger;')
    else if UpperCase(FieldType) = 'DOUBLE' then
      Output.AddLine(S + ' := GetParamByName(''Value'').AsFloat;')
    else if UpperCase(FieldType) = 'TDATETIME' then
      Output.AddLine(S + ' := StrToDateTime(GetParamByName(''Value'').AsString);')
    else if UpperCase(FieldType) = 'CURRENCY' then
      Output.AddLine(S + ' := GetParamByName(''Value'').AsFloat;')
    else if UpperCase(FieldType) = 'BOOLEAN' then
      Output.AddLine(S + ' := GetParamByName(''Value'').AsBoolean;')
    else if _IsArrayOfChar(FieldType) then
      Output.AddLine(S + ' := GetParamByName(''Value'').AsString;')
//      Output.AddLine('StringToArrayOfChar(GetParamByNameS(''Value''), ' + S + ');')
    else
      Output.AddLine('DON''t KNOW HOW TO HANDLE TYPE ' + FieldType);
  Output.DecIndent;
end;

procedure TPxCGField.CreateXmlWrite(Output: TPxCGOutput);
var
  S: String;
begin
  if Owner is TPxCGPart then S := FieldName
  else S := 'D.' + FieldName;
  Output.AddLine('with TPxXMLItem.Create(This) do');
  Output.AddBegin;
    Output.AddLine('This.Name := ''' + FieldName + ''';');
    if UpperCase(FieldType) = 'INTEGER' then
      Output.AddLine('GetParamByName(''Value'').AsInteger := ' + S + ';')
    else if UpperCase(FieldType) = 'INT8' then
      Output.AddLine('GetParamByName(''Value'').AsInteger := ' + S + ';')
    else if UpperCase(FieldType) = 'UINT8' then
      Output.AddLine('GetParamByName(''Value'').AsInteger := ' + S + ';')
    else if UpperCase(FieldType) = 'INT16' then
      Output.AddLine('GetParamByName(''Value'').AsInteger := ' + S + ';')
    else if UpperCase(FieldType) = 'UINT16' then
      Output.AddLine('GetParamByName(''Value'').AsInteger := ' + S + ';')
    else if UpperCase(FieldType) = 'INT32' then
      Output.AddLine('GetParamByName(''Value'').AsInteger := ' + S + ';')
    else if UpperCase(FieldType) = 'UINT32' then
      Output.AddLine('GetParamByName(''Value'').AsInteger := ' + S + ';')
    else if UpperCase(FieldType) = 'TIDENTIFIER' then
      Output.AddLine('GetParamByName(''Value'').AsInteger := ' + S + ';')
    else if UpperCase(FieldType) = 'WORD' then
      Output.AddLine('GetParamByName(''Value'').AsInteger := ' + S + ';')
    else if UpperCase(FieldType) = 'DWORD' then
      Output.AddLine('GetParamByName(''Value'').AsInteger := ' + S + ';')
    else if UpperCase(FieldType) = 'LONGWORD' then
      Output.AddLine('GetParamByName(''Value'').AsInteger := ' + S + ';')
    else if UpperCase(FieldType) = 'SHORTINT' then
      Output.AddLine('GetParamByName(''Value'').AsInteger := ' + S + ';')
    else if UpperCase(FieldType) = 'BYTE' then
      Output.AddLine('GetParamByName(''Value'').AsInteger := ' + S + ';')
    else if UpperCase(FieldType) = 'TCOLOR' then
      Output.AddLine('GetParamByName(''Value'').AsInteger := ' + S + ';')
    else if UpperCase(FieldType) = 'DOUBLE' then
      Output.AddLine('GetParamByName(''Value'').AsFloat := ' + S + ';')
    else if UpperCase(FieldType) = 'TDATETIME' then
      Output.AddLine('GetParamByName(''Value'').AsString := FormatDateTime(''YYYY-MM-DD HH:NN:SS'', ' + S + ');')
    else if UpperCase(FieldType) = 'CURRENCY' then
      Output.AddLine('GetParamByName(''Value'').AsFloat := ' + S + ';')
    else if UpperCase(FieldType) = 'BOOLEAN' then
      Output.AddLine('GetParamByName(''Value'').AsBoolean := ' + S + ';')
    else if _IsArrayOfChar(FieldType) then
      Output.AddLine('GetParamByName(''Value'').AsString := ' + S + ';')
    else
      Output.AddLine('DON''t KNOW HOW TO HANDLE TYPE ' + FieldType);
  Output.AddEnd;
end;

{ TPxCGRuntimeField }

{ Protected declarations }

procedure TPxCGRuntimeField.ReadParams;
begin
  inherited ReadParams;
  if Xml.HasParam('CreateInstance') then
    CreateInstance := Xml.GetParamByName('CreateInstance').AsBoolean;
  if Xml.HasParam('CreateParams') then
    CreateParams := Xml.GetParamByNameS('CreateParams');
end;

{ Public declarations }

{ TPxCGAddToListItem }

{ Protected declarations }

procedure TPxCGAddToListItem.ReadParams;
begin
  inherited ReadParams;
  if Xml.HasParam('Field') then
    Field := Xml.GetParamByNameS('Field');
  if Xml.HasParam('RecordType') then
    RecordType := Xml.GetParamByNameS('RecordType');
  if Xml.HasParam('RecordField') then
    RecordField := Xml.GetParamByNameS('RecordField');
end;

{ TPxCGDataRecord }

{ Private declarations }

procedure TPxCGDataRecord.CreateLoadProps(Output: TPxCGOutput);
var
  I: Integer;
  Field: TPxCGField;
begin
  Output.AddLine('');
  Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.LoadProps(S: TStream; Properties: array of Integer);');
  Output.AddLine('var');
  Output.IncIndent;
    Output.AddLine('I, Count: Integer;');
    Output.AddLine('Prop: packed record Id, Kind: Byte; end;');
  Output.DecIndent;
  Output.AddBegin;
    Output.AddLine('repeat');
    Output.IncIndent;
      Output.AddLine('Count := S.Read(Prop, SizeOf(Prop));');
      Output.AddLine('if Count = SizeOf(Prop) then');
      Output.AddBegin;
        Output.AddLine('case Prop.Id of');
        Output.IncIndent;
          for I := 0 to Fields.Count - 1 do
          begin
            Field := Fields[I] as TPxCGField;
            Output.AddLine('propid' + Name + Field.FieldName + ': ');
            Output.IncIndent;
              Output.AddLine('S.Read(D.' + Field.FieldName + ', SizeOf(D.' + Field.FieldName + '));');
            Output.DecIndent;
          end;
        Output.AddEnd;
      Output.AddEnd;
    Output.DecIndent;
    Output.AddLine('until (Count = 0) or (Prop.Id = 0);');
  Output.AddEnd;
end;

procedure TPxCGDataRecord.CreateSaveProps(Output: TPxCGOutput);
var
  I: Integer;
  Field: TPxCGField;
begin
  Output.AddLine('');
  Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.SaveProps(S: TStream; Properties: array of Integer);');
  Output.AddLine('var');
  Output.IncIndent;
    Output.AddLine('I: Integer;');
  Output.DecIndent;
  Output.AddBegin;
    Output.AddLine('for I := 0 to Length(Properties) - 1 do');
    Output.IncIndent;
      Output.AddLine('case Properties[I] of');
      Output.IncIndent;
      for I := 0 to Fields.Count - 1 do
      begin
        Field := Fields[I] as TPxCGField;
        Output.AddLine('propid' + Name + Field.FieldName + ': ');
        Output.IncIndent;
          Output.AddLine('S.Write(D.' + Field.FieldName + ', SizeOf(D.' + Field.FieldName + '));');
        Output.DecIndent;
      end;
      Output.AddEnd;
    Output.DecIndent;
  Output.AddEnd;
end;

{ Protected declarations }

procedure TPxCGDataRecord.ReadParams;
var
  S1, S2: String;
begin
  if Xml.HasParam('Name') then
    Name := Xml.GetParamByNameS('Name');
  if Xml.HasParam('Id') then
    Id := Xml.GetParamByNameS('Id');
  if Xml.HasParam('Single') then
    Single := Xml.GetParamByName('Single').AsBoolean;
  if Xml.HasParam('ContainerRecordOnly') then
    ContainerRecordOnly := Xml.GetParamByName('ContainerRecordOnly').AsBoolean;
  if Xml.HasParam('RecordIDField') then
    RecordIDField := Xml.GetParamByNameS('RecordIDField');
  if Xml.HasParam('ParentClass') then
    ParentClass := Xml.GetParamByNameS('ParentClass');

  // property assignment
  if Xml.HasParam('AssignMethod') then
    AssignMethod := Xml.GetParamByName('AssignMethod').AsBoolean
  else
    // by default this method is there
    AssignMethod := True;

  // property streaming
  if Xml.HasParam('PropsStreamingMethods') then
    PropsStreamingMethods := Xml.GetParamByName('PropsStreamingMethods').AsBoolean;

  if Self is TPxCGDataRecordEx then
    S1 := 'DataRecordEx'
  else
    S1 := 'DataRecord';

  // sprawdzenie poprawnoœci danych
  S2 := '???';
  if not IsValidName(Name) then
    raise EGeneratorException.CreateFmt('Invalid <DataRecord NAME="%s" ... /> in %s "%s"', [Name, S1, S2]);
  S2 := Name;
  if not IsValidNumber(Id) then
    raise EGeneratorException.CreateFmt('Invalid <DataRecord ID="%s" ... /> in %s "%s"', [Id, S1, S2]);
  if (RecordIDField <> '') and (not IsValidName(RecordIDField)) then
    raise EGeneratorException.CreateFmt('Invalid <DataRecord RECORDIDFIELD="%s" ... />', [RecordIDField, S1, S2]);

  Fields := CreateList('Field', TPxCGField);
  RuntimeFields := CreateList('RuntimeField', TPxCGRuntimeField);
  AddToLists := CreateList('AddToList', TPxCGAddToListItem);
end;

function TPxCGDataRecord.HasRuntimeFieldsWithCreateInstance: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to RuntimeFields.Count - 1 do
    if TPxCGRuntimeField(RuntimeFields[I]).CreateInstance then
    begin
      Result := True;
      Break;
    end;
end;

procedure TPxCGDataRecord.CreateListInterface(Output: TPxCGOutput);
begin
  Output.AddLine('');
  Output.IncIndent;
    Output.AddLine(GetTypeName('', Name, 'List') + ' = class (TList)');
    Output.AddPrivate;
      Output.AddLine('function GetItem(Index: Integer): ' + GetTypeName('', Name, '') + ';');
    Output.DecIndent;
    Output.AddPublic;
      Output.AddLine('property Items[Index: Integer]: ' + GetTypeName('', Name, '') + ' read GetItem; default;');
    Output.AddEnd;
  Output.DecIndent;
end;

procedure TPxCGDataRecord.CreateListImplementation(Output: TPxCGOutput);
begin
  Output.AddLine('');
  Output.AddLine('{ ' + GetTypeName('', Name, 'List') + ' }');
  Output.AddLine('');
  Output.AddLine('{ Private declarations }');
  Output.AddLine('');
  Output.AddLine('function ' + GetTypeName('', Name, 'List') + '.GetItem(Index: Integer): ' + GetTypeName('', Name, '') + ';');
  Output.AddBegin;
    Output.AddLine('Result := TObject(Get(Index)) as ' + GetTypeName('', Name, '') + ';');
  Output.AddEnd;
end;

procedure TPxCGDataRecord.CreateBeginningOfReadXml(Output: TPxCGOutput; MultiField: Boolean);
var
  S: String;
  StrI: String;
begin
  if NowInContainer then StrI := 'J'
  else StrI := 'I';
  S := 'if Items[' + StrI + '].IsItemName(''' + Name + ''')';
  if TPxCGDataFile(Owner).StricTPxXMLItemCheck then S := S + ' and (Items[' + StrI + '].GetParamByName(''Id'').AsInteger = ' + Id + ')';
  S := S + ' then';
  Output.AddLine(S);
  if not Single then
  begin
    Output.AddBegin;
      if NowInContainer then S := ContainerVariable
      else S := 'Self';
      Output.AddLine(Name + ' := ' + GetTypeName('', Name, '') + '.Create(' + S + ');');
      Output.AddLine(S + '.AddRecord(' + Name + ');');
  end
  else Output.IncIndent;
    Output.AddLine('with Items[' + StrI + '], ' + Name + ' do');
    if MultiField then
      Output.AddBegin
    else
      Output.IncIndent;
end;

procedure TPxCGDataRecord.CreateEndingOfReadXml(Output: TPxCGOutput; MultiField: Boolean);
begin
  if MultiField then
    Output.AddEnd
  else
    Output.DecIndent;
  if Single then
    Output.DecIndent
  else
    Output.AddEnd;
end;

procedure TPxCGDataRecord.CreateAssign(Output: TPxCGOutput; RecordIdField: String);
var
  I: Integer;
  Field: TPxCGField;
begin
  Output.AddLine('');
  Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.AssignTo(Dest: TPersistent);');
  Output.AddBegin;
    Output.AddLine('if not (Dest is ' + GetTypeName('', Name, '') + ') then');
    Output.IncIndent;
      Output.AddLine('raise Exception.CreateFmt(''Class %s cannot be assigned to %s'', [ClassName, Dest.ClassName]);');
    Output.DecIndent;
    for I := 0 to Fields.Count - 1 do
    begin
      Field := Fields[I] as TPxCGField;
      if not AnsiSameText(Field.FieldName, RecordIdField) then
        Output.AddLine(GetTypeName('', Name, '') + '(Dest).D.' + Field.FieldName + ' := ' + 'D.' + Field.FieldName + ';');
    end;
  Output.AddEnd;
end;

{ Public declarations }

procedure FreeAndNil(Obj: Pointer);
begin
  if Assigned(Obj) then
    SysUtils.FreeAndNil(Obj);
end;

destructor TPxCGDataRecord.Destroy;
begin
  FreeAndNil(Fields);
  inherited Destroy;
end;

procedure TPxCGDataRecord.CreateInterface(Output: TPxCGOutput);
var
  I: Integer;
  Field: TPxCGField;
  RuntimeField: TPxCGRuntimeField;
  S: String;
begin
  // constants
  Output.AddLine('{ ' + GetTypeName('', Name, '') + ' }');
  Output.AddLine('');

  Output.AddLine('const');
  Output.IncIndent;
    Output.AddLine('kindid' + Name + ' = ' + Id + ';');
    // property id's
    for I := 0 to Fields.Count - 1 do
    begin
      Field := Fields[I] as TPxCGField;
      Output.AddLine('propid' + Name + Field.FieldName + ' = ' + IntToStr(I + 1) + ';');
    end;
    Output.AddLine('maxpropid' + Name + ' = ' + IntToStr(Fields.Count) + ';');
  Output.DecIndent;

  // types
  Output.AddLine('');
  Output.AddLine('type');
  Output.IncIndent;
    // data packed record declaration
   Output.AddLine(GetPTypeName('', Name, 'Rec') + ' = ^' + GetTypeName('', Name, 'Rec') + ';');
    Output.AddLine(GetTypeName('', Name, 'Rec') + ' = packed record');
    Output.IncIndent;
      for I := 0 to Fields.Count - 1 do
      begin
        Field := Fields[I] as TPxCGField;
        Output.AddLine(Field.FieldName + ': ' + Field.FieldType + ';');
      end;
    Output.AddEnd;

    // class declaration
    Output.AddLine('');
    if ParentClass = '' then
      Output.AddLine(GetTypeName('', Name, '') + ' = class (TPxDataRecord' + S + ')')
    else
      Output.AddLine(GetTypeName('', Name, '') + ' = class (' + ParentClass + S + ')');
    Output.AddPrivate;
      // runtime fields
      if RuntimeFields.Count > 0 then
        Output.AddLine('// Run-time fields');
      for I := 0 to RuntimeFields.Count - 1 do
      begin
        RuntimeField := RuntimeFields[I] as TPxCGRuntimeField;
        Output.AddLine('F' + RuntimeField.FieldName + ': ' + RuntimeField.FieldType + ';');
      end;
      if RuntimeFields.Count > 0 then
        Output.AddLine('// Access data method');
      Output.AddLine('function GetData: ' + GetPTypeName('', Name, 'Rec') + ';');
    Output.DecIndent;
    Output.AddProtected;
      // Assign method
      if AssignMethod then
        Output.AddLine('procedure AssignTo(Dest: TPersistent); override;');
      Output.AddLine('procedure Initialize; override;');
      if HasRuntimeFieldsWithCreateInstance then
        Output.AddLine('procedure Finalize; override;');
    Output.DecIndent;
    Output.AddPublic;
      if RecordIDField <> '' then
      begin
          Output.AddLine('function RecordID: TIdentifier; override;');
      end;
      if PropsStreamingMethods then
      begin
        Output.AddLine('procedure SaveProps(S: TStream);');
        Output.AddLine('procedure LoadProps(S: TStream; Properties: array of Integer);');
      end;
      // runtime fields
      for I := 0 to RuntimeFields.Count - 1 do
      begin
        RuntimeField := RuntimeFields[I] as TPxCGRuntimeField;
        if RuntimeField.CreateInstance then
          Output.AddLine('property ' + RuntimeField.FieldName + ': ' + RuntimeField.FieldType + ' read F' + RuntimeField.FieldName + ';')
        else
          Output.AddLine('property ' + RuntimeField.FieldName + ': ' + RuntimeField.FieldType + ' read F' + RuntimeField.FieldName + ' write F' + RuntimeField.FieldName + ';');
      end;
      // Data access property
      Output.AddLine('property D: ' + GetPTypeName('', Name, 'Rec') + ' read GetData;');
    Output.AddEnd;
  Output.DecIndent;

  if not Single then
    CreateListInterface(Output);
end;

procedure TPxCGDataRecord.CreateImplementation(Output: TPxCGOutput);
var
  I: Integer;
  RuntimeField: TPxCGRuntimeField;
begin
  Output.AddLine('{ ' + GetTypeName('', Name, '') + ' }');
  Output.AddLine('');
  Output.AddLine('{ Private declarations }');
  Output.AddLine('');
  Output.AddLine('function ' + GetTypeName('', Name, '') + '.GetData: ' + GetPTypeName('', Name, 'Rec') + ';');
  Output.AddBegin;
    Output.AddLine('Result := Buffer;');
  Output.AddEnd;

  Output.AddLine('');
  Output.AddLine('{ Protected declarations }');
  Output.AddLine('');
  Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.Initialize;');
  Output.AddBegin;
    Output.AddLine('inherited Initialize;');
    Output.AddLine('Header.Kind := kindid' + Name + ';');
    Output.AddLine('Header.Size := SizeOf(' + GetTypeName('', Name, 'Rec') + ');');
    for I := 0 to RuntimeFields.Count - 1 do
    begin
      RuntimeField := RuntimeFields[I] as TPxCGRuntimeField;
      if RuntimeField.CreateInstance then
      begin
        if RuntimeField.CreateParams <> '' then
          Output.AddLine('F' + RuntimeField.FieldName + ' := ' + RuntimeField.FieldType + '.Create(' + RuntimeField.CreateParams + ');')
        else
          Output.AddLine('F' + RuntimeField.FieldName + ' := ' + RuntimeField.FieldType + '.Create;');
      end;
    end;
  Output.AddEnd;

  if HasRuntimeFieldsWithCreateInstance then
  begin
    // runtime fields
    Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.Finalize;');
    Output.AddBegin;
      for I := 0 to RuntimeFields.Count - 1 do
      begin
        RuntimeField := RuntimeFields[I] as TPxCGRuntimeField;
        if RuntimeField.CreateInstance then
          Output.AddLine('FreeAndNil(F' + RuntimeField.FieldName + ');');
      end;
      Output.AddLine('inherited Finalize;');
    Output.AddEnd;
  end;
  if (RecordIDField <> '') or PropsStreamingMethods or AssignMethod then
  begin
    if RecordIDField <> ''then
    begin
      Output.AddLine('');
      Output.AddLine('{ Public declarations }');
      Output.AddLine('');
      Output.AddLine('function ' + GetTypeName('', Name, '') + '.RecordID: TIdentifier;');
      Output.AddBegin;
        Output.AddLine('Result := D.' + RecordIDField + ';');
      Output.AddEnd;
    end;

    // props streaming
    if PropsStreamingMethods then
    begin
      CreateLoadProps(Output);
      CreateSaveProps(Output);
    end;

    if AssignMethod then
      CreateAssign(Output, RecordIdField);
  end;

  if not Single then
    CreateListImplementation(Output);
end;

procedure TPxCGDataRecord.CreateXmlRead(Output: TPxCGOutput);
var
  I: Integer;
  Field: TPxCGField;
begin
  CreateBeginningOfReadXml(Output, Fields.Count > 0);
  for I := 0 to Fields.Count - 1 do
  begin
    Field := Fields[I] as TPxCGField;
    Field.CreateXmlRead(Output);
  end;
  CreateEndingOfReadXml(Output, Fields.Count > 0);
end;

procedure TPxCGDataRecord.CreateXmlWrite(Output: TPxCGOutput);
var
  I: Integer;
  Field: TPxCGField;
begin
  Output.AddLine('with TPxXMLItem.Create(This), ' + Name + ' do');

  Output.AddBegin;
    Output.AddLine('This.Name := ''' + Name + ''';');
    if TPxCGDataFile(Owner).StricTPxXMLItemCheck then
      Output.AddLine('GetParamByName(''Id'').AsInteger := ' + Id + ';');
    for I := 0 to Fields.Count - 1 do
    begin
      Field := Fields[I] as TPxCGField;
      Field.CreateXmlWrite(Output);
    end;
  Output.AddEnd;
end;

{ TPxCGDataRecordEx }

{ Private declarations }

procedure TPxCGDataRecordEx.CreateLoadProps(Output: TPxCGOutput);
var
  I, J: Integer;
  DataPart: TPxCGDataPart;
  StringPart: TPxCGStringPart;
  StreamPart: TPxCGStreamPart;
  Field: TPxCGField;
begin
  Output.AddLine('');
  Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.LoadProps(S: TStream; Properties: array of Integer);');
  Output.AddLine('var');
  Output.IncIndent;
    Output.AddLine('I: Integer;');
    if (StringParts.Count > 0) or (StreamParts.Count > 0) then
      Output.AddLine('Len: LongWord;');
  Output.DecIndent;
  Output.AddBegin;
    Output.AddLine('for I := 0 to Length(Properties) - 1 do');
      Output.IncIndent;
        Output.AddLine('case Properties[I] of');
        Output.IncIndent;
          for I := 0 to DataParts.Count - 1 do
          begin
            DataPart := DataParts[I] as TPxCGDataPart;
            for J := 0 to DataPart.Fields.Count - 1 do
            begin
              Field := DataPart.Fields[J] as TPxCGField;
              Output.AddLine('propid' + Name + Field.FieldName + ': ');
              Output.IncIndent;
              Output.AddLine('S.Read(F' + DataPart.Name + '.' + Field.FieldName + ', SizeOf(F' + DataPart.Name + '.' + Field.FieldName + '));');
              Output.DecIndent;
            end;
          end;
          for I := 0 to StringParts.Count - 1 do
          begin
            StringPart := StringParts[I] as TPxCGStringPart;
            Output.AddLine('propid' + Name + StringPart.Name + ': ');
            Output.AddBegin;
              Output.AddLine('S.Read(Len, SizeOf(Len));');
              Output.AddLine('SetLength(F' + StringPart.Name + ', Len);');
              Output.AddLine('if Length(F' + StringPart.Name + ') > 0 then');
              Output.IncIndent;
                Output.AddLine('S.Read(F' + StringPart.Name + '[1], Len * SizeOf(WideChar));');
              Output.DecIndent;
            Output.AddEnd;
          end;
          for I := 0 to StreamParts.Count - 1 do
          begin
            StreamPart := StreamParts[I] as TPxCGStreamPart;
            Output.AddLine('propid' + Name + StreamPart.Name + ': ');
            Output.AddBegin;
              Output.AddLine('S.Read(Len, SizeOf(Len));');
              Output.AddLine('F' + StreamPart.Name + '.Size := 0;');
              Output.AddLine('F' + StreamPart.Name + '.CopyFrom(S, Len);');
            Output.AddEnd;
          end;
        Output.AddEnd;
      Output.DecIndent;
  Output.AddEnd;
end;

procedure TPxCGDataRecordEx.CreateSaveProps(Output: TPxCGOutput);
var
  I, J: Integer;
  DataPart: TPxCGDataPart;
  StringPart: TPxCGStringPart;
  StreamPart: TPxCGStreamPart;
  Field: TPxCGField;
begin
  Output.AddLine('');
  Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.SaveProps(S: TStream; Properties: array of Integer);');
  Output.AddLine('var');
  Output.IncIndent;
    Output.AddLine('I: Integer;');
    if (StringParts.Count > 0) or (StreamParts.Count > 0) then
      Output.AddLine('Len: LongWord;');
  Output.DecIndent;
  Output.AddBegin;
    Output.AddLine('for I := 0 to Length(Properties) - 1 do');
    Output.IncIndent;
      Output.AddLine('case Properties[I] of');
      Output.IncIndent;
      for I := 0 to DataParts.Count - 1 do
      begin
        DataPart := DataParts[I] as TPxCGDataPart;
        for J := 0 to DataPart.Fields.Count - 1 do
        begin
          Field := DataPart.Fields[J] as TPxCGField;
          Output.AddLine('propid' + Name + Field.FieldName + ': ');
          Output.IncIndent;
            Output.AddLine('S.Write(F' + DataPart.Name + '.' + Field.FieldName + ', SizeOf(F' + DataPart.Name + '.' + Field.FieldName + '));');
          Output.DecIndent;
        end;
      end;
      for I := 0 to StringParts.Count - 1 do
      begin
        StringPart := StringParts[I] as TPxCGStringPart;
        Output.AddLine('propid' + Name + StringPart.Name + ': ');
        Output.AddBegin;
          Output.AddLine('Len := Length(F' + StringPart.Name + ');');
          Output.AddLine('S.Write(Len, SizeOf(Len));');
          Output.AddLine('if Length(F' + StringPart.Name + ') > 0 then');
          Output.IncIndent;
            Output.AddLine('S.Write(F' + StringPart.Name + '[1], Len * SizeOf(WideChar));');
          Output.DecIndent;
        Output.AddEnd;
      end;
      for I := 0 to StreamParts.Count - 1 do
      begin
        StreamPart := StreamParts[I] as TPxCGStreamPart;
        Output.AddLine('propid' + Name + StreamPart.Name + ': ');
        Output.AddBegin;
          Output.AddLine('F' + StreamPart.Name + '.Position := 0;');
          Output.AddLine('Len := F' + StreamPart.Name + '.Size;');
          Output.AddLine('S.Write(Len, SizeOf(Len));');
          Output.AddLine('S.CopyFrom(F' + StreamPart.Name + ', Len);');
        Output.AddEnd;
      end;
      Output.AddEnd;
    Output.DecIndent;
  Output.AddEnd;
end;

function CompareTPxCGAddToListItemByField(P1, P2: Pointer): Integer;
var
  D1: TPxCGAddToListItem absolute P1;
  D2: TPxCGAddToListItem absolute P2;
begin
  Result := -AnsiCompareText(D1.Field, D2.Field);
end;

procedure TPxCGDataRecordEx.CreateOnResolveIDs(Output: TPxCGOutput);
var
  I, J, K: Integer;
  DataPart: TPxCGDataPart;
  Field: TPxCGField;
  RuntimeField: TPxCGRuntimeField;
  AddToList: TPxCGAddToListItem;
  TmpList: TList;
  S: String;
  Added: Boolean;
begin
  Output.AddLine('');
  Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.OnResolveIDs(Resolver: TPxIdResolver);');
  Output.AddBegin;
    for I := 0 to DataParts.Count - 1 do
    begin
      DataPart := DataParts[I] as TPxCGDataPart;
      for J := 0 to DataPart.Fields.Count - 1 do
      begin
        Field := DataPart.Fields[J] as TPxCGField;
        if AnsiCompareText('TIdentifier', Field.FieldType) = 0 then
          // search a runtime field that is same as id field
          for K := 0 to RuntimeFields.Count - 1 do
          begin
            RuntimeField := RuntimeFields[K] as TPxCGRuntimeField;
            if AnsiCompareText(RuntimeField.FieldName, Copy(Field.FieldName, 1, Length(Field.FieldName) - 2)) = 0 then
            begin
              Output.AddLine(RuntimeField.FieldName + ' := Resolver.Item[' + Field.FieldName + '];');
              Break;
            end;
          end;
      end;
    end;
    TmpList := TList.Create;
    for I := 0 to AddToLists.Count - 1 do
      TmpList.Add(AddToLists[I]);
    TmpList.Sort(@CompareTPxCGAddToListItemByField);

    Added := False;
    for I := 0 to TmpList.Count - 1 do
    begin
      AddToList := TmpList[I];
      if Added then S := 'else '
      else S := '';
      Output.AddLine(S + 'if (' + AddToList.Field + ' is ' + GetTypeName('', AddToList.RecordType, '') + ') and (' + GetTypeName('', AddToList.RecordType, '') + '(' + AddToList.Field + ').' + AddToList.RecordField + '.IndexOf(Self) = -1) then ');
      Output.IncIndent;
        Output.AddLine(GetTypeName('', AddToList.RecordType, '') + '(' + AddToList.Field + ').' + AddToList.RecordField + '.Add(Self)');
      Output.DecIndent;
      Added := True;

      if (I = TmpList.Count - 1) or (AnsiCompareText(TPxCGAddToListItem(TmpList[I + 1]).Field, AddToList.Field) <> 0) then
      begin
        Output.AddLine('else if Assigned(' + AddToList.Field + ') then ');
        Output.IncIndent;
          Output.AddLine('raise Exception.Create(''Error while resolving connections'');');
        Output.DecIndent;
        Added := False;
      end;
    end;
    TmpList.Free;
  Output.AddEnd;
end;

{ Protected declaration }

function TPxCGDataRecordEx.HasFieldsWithID: Boolean;
var
  I, J, K: Integer;
  DataPart: TPxCGDataPart;
  Field: TPxCGField;
  RuntimeField: TPxCGRuntimeField;
begin
  Result := False;
  for I := 0 to DataParts.Count - 1 do
  begin
    DataPart := DataParts[I] as TPxCGDataPart;
    for J := 0 to DataPart.Fields.Count - 1 do
    begin
      Field := DataPart.Fields[J] as TPxCGField;
      if AnsiCompareText('TIdentifier', Field.FieldType) = 0 then
        for K := 0 to RuntimeFields.Count - 1 do
        begin
          RuntimeField := RuntimeFields[K] as TPxCGRuntimeField;
          if AnsiCompareText(RuntimeField.FieldName, Copy(Field.FieldName, 1, Length(Field.FieldName) - 2)) = 0 then
          begin
            Result := True;
            Exit;
          end;
        end;
    end;
  end;
end;

procedure TPxCGDataRecordEx.ReadParams;
begin
  inherited ReadParams;
  DataParts := CreateList('DataPart', TPxCGDataPart);
  ArrayParts := CreateList('ArrayPart', TPxCGArrayPart);
  StringParts := CreateList('StringPart', TPxCGStringPart);
  FloatParts := CreateList('FloatPart', TPxCGFloatPart);
  StreamParts := CreateList('StreamPart', TPxCGStreamPart);
  ExpressionParts := CreateList('Expression', TPxCGExpressionPart);
end;

procedure TPxCGDataRecordEx.CreateAssign(Output: TPxCGOutput; RecordIdField: String);
var
  I, J: Integer;
  DataPart: TPxCGDataPart;
  ArrayPart: TPxCGArrayPart;
  StringPart: TPxCGStringPart;
  StreamPart: TPxCGStreamPart;
  Field: TPxCGField;
begin
  Output.AddLine('');
  Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.AssignTo(Dest: TPersistent);');
  if ArrayParts.Count > 0 then
  begin
    Output.AddLine('var');
    Output.IncIndent;
        Output.AddLine('I: Integer;');
    Output.DecIndent;
  end;
  Output.AddBegin;
    Output.AddLine('if not (Dest is ' + GetTypeName('', Name, '') + ') then');
    Output.IncIndent;
      Output.AddLine('raise Exception.CreateFmt(''Class %s cannot be assigned to %s'', [ClassName, Dest.ClassName]);');
    Output.DecIndent;
    for I := 0 to DataParts.Count - 1 do
    begin
      DataPart := DataParts[I] as TPxCGDataPart;
      for J := 0 to DataPart.Fields.Count - 1 do
      begin
        Field := DataPart.Fields[J] as TPxCGField;
        if not AnsiSameText(Field.FieldName, RecordIdField) then
          Output.AddLine(GetTypeName('', Name, '') + '(Dest).' + Field.FieldName + ' := ' + Field.FieldName + ';');
      end;
    end;

    for I := 0 to ArrayParts.Count - 1 do
    begin
      ArrayPart := ArrayParts[I] as TPxCGArrayPart;
      Output.AddLine(GetTypeName('', Name, '') + '(Dest).' + ArrayPart.Name + '.Clear;');
      Output.AddLine('for I := 0 to ' + ArrayPart.Name + '.Count - 1 do');
      Output.IncIndent;
        Output.AddLine(GetTypeName('', Name, '') + '(Dest).' + ArrayPart.Name + '.Add.Data := ' + ArrayPart.Name + '[I].Data;');
      Output.DecIndent;
    end;

    for I := 0 to StringParts.Count - 1 do
    begin
      StringPart := StringParts[I] as TPxCGStringPart;
      Output.AddLine(GetTypeName('', Name, '') + '(Dest).' + StringPart.Name + ' := ' + StringPart.Name + ';');
    end;
    for I := 0 to StreamParts.Count - 1 do
    begin
      StreamPart := StreamParts[I] as TPxCGStreamPart;
      Output.AddLine(GetTypeName('', Name, '') + '(Dest).' + StreamPart.Name + '.Size := 0;');
      Output.AddLine(StreamPart.Name + '.Position := 0;');
      Output.AddLine(GetTypeName('', Name, '') + '(Dest).' + StreamPart.Name + '.CopyFrom(' + StreamPart.Name + ', ' + StreamPart.Name + '.Size);');
    end;
  Output.AddEnd;
end;

{ Public declarations }

destructor TPxCGDataRecordEx.Destroy;
begin
  FreeAndNil(ExpressionParts);
  FreeAndNil(StreamParts);
  FreeAndNil(StringParts);
  FreeAndNil(ArrayParts);
  FreeAndNil(DataParts);
  inherited Destroy;
end;

procedure TPxCGDataRecordEx.CreateInterface(Output: TPxCGOutput);
var
  I, J, Index: Integer;
  S: String;
  Field: TPxCGField;
  RuntimeField: TPxCGRuntimeField;
  DataPart: TPxCGDataPart;
  ArrayPart: TPxCGArrayPart;
  StringPart: TPxCGStringPart;
  FloatPart: TPxCGFloatPart;
  StreamPart: TPxCGStreamPart;
  ExpressionPart: TPxCGExpressionPart;
begin
  Output.AddLine('{ ' + GetTypeName('', Name, '') + ' }');
  Output.AddLine('');

  for I := 0 to DataParts.Count - 1 do
  begin
    DataParts[I].CreateInterface(Output);
    Output.AddLine('');
  end;
  for I := 0 to ArrayParts.Count - 1 do
  begin
    ArrayParts[I].CreateInterface(Output);
    Output.AddLine('');
  end;
  for I := 0 to StringParts.Count - 1 do
  begin
    StringParts[I].CreateInterface(Output);
    Output.AddLine('');
  end;
  for I := 0 to FloatParts.Count - 1 do
  begin
    FloatParts[I].CreateInterface(Output);
    Output.AddLine('');
  end;
  for I := 0 to StreamParts.Count - 1 do
  begin
    StreamParts[I].CreateInterface(Output);
    Output.AddLine('');
  end;
  for I := 0 to ExpressionParts.Count - 1 do
  begin
    ExpressionParts[I].CreateInterface(Output);
    Output.AddLine('');
  end;

  // constants
  Output.AddLine('const');
  Output.IncIndent;
    Output.AddLine('kindid' + Name + ' = ' + Id + ';');
    // property id's
    Index := 1;
    for I := 0 to DataParts.Count - 1 do
    begin
      DataPart := DataParts[I] as TPxCGDataPart;
      for J := 0 to DataPart.Fields.Count - 1 do
      begin
        Field := DataPart.Fields[J] as TPxCGField;
        Output.AddLine('propid' + Name + Field.FieldName + ' = ' + IntToStr(Index) + ';');
        Inc(Index);
      end;
    end;
    for I := 0 to ArrayParts.Count - 1 do
    begin
      ArrayPart := ArrayParts[I] as TPxCGArrayPart;
      for J := 0 to ArrayPart.Fields.Count - 1 do
      begin
        Field := ArrayPart.Fields[J] as TPxCGField;
        Output.AddLine('propid' + Name + ArrayPart.Name + Field.FieldName + ' = ' + IntToStr(Index) + ';');
        Inc(Index);
      end;
    end;
    for I := 0 to StringParts.Count - 1 do
    begin
      StringPart := StringParts[I] as TPxCGStringPart;
      Output.AddLine('propid' + Name + StringPart.Name + ' = ' + IntToStr(Index) + ';');
      Inc(Index);
    end;
    for I := 0 to StreamParts.Count - 1 do
    begin
      StreamPart := StreamParts[I] as TPxCGStreamPart;
      Output.AddLine('propid' + Name + StreamPart.Name + ' = ' + IntToStr(Index) + ';');
      Inc(Index);
    end;
    for I := 0 to FloatParts.Count - 1 do
    begin
      FloatPart := FloatParts[I] as TPxCGFloatPart;
      Output.AddLine('propid' + Name + FloatPart.Name + ' = ' + IntToStr(Index) + ';');
      Inc(Index);
    end;
    for I := 0 to ExpressionParts.Count - 1 do
    begin
      ExpressionPart := ExpressionParts[I] as TPxCGExpressionPart;
      Output.AddLine('propid' + Name + ExpressionPart.Name + ' = ' + IntToStr(Index) + ';');
      Inc(Index);
    end;
    Output.AddLine('maxpropid' + Name + ' = ' + IntToStr(Index) + ';');
  Output.DecIndent;
  Output.AddLine('');

  Output.AddLine('type');
  Output.IncIndent;
    if ParentClass = '' then
      Output.AddLine(GetTypeName('', Name, '') + ' = class (TPxDataRecordEx' + S + ')')
    else
      Output.AddLine(GetTypeName('', Name, '') + ' = class (' + ParentClass + S + ')');
    if (DataParts.Count > 0) or (ArrayParts.Count > 0) or (StringParts.Count > 0) or (StreamParts.Count > 0) or (ExpressionParts.Count > 0) or (RuntimeFields.Count > 0) then
    begin
      Output.AddPrivate;
      // runtime fields
      if RuntimeFields.Count > 0 then
        Output.AddLine('// Run-time fields');
      for I := 0 to RuntimeFields.Count - 1 do
      begin
        RuntimeField := RuntimeFields[I] as TPxCGRuntimeField;
        Output.AddLine('F' + RuntimeField.FieldName + ': ' + RuntimeField.FieldType + ';');
      end;
      if RuntimeFields.Count > 0 then
        Output.AddLine('// Saved fields');
      for I := 0 to DataParts.Count - 1 do
      begin
        DataPart := DataParts[I] as TPxCGDataPart;
        Output.AddLine('F' + DataPart.Name + ': ' + GetTypeName('', Name + DataPart.Name, 'Rec') + ';');
      end;
      for I := 0 to ArrayParts.Count - 1 do
      begin
        ArrayPart := ArrayParts[I] as TPxCGArrayPart;
        Output.AddLine('F' + ArrayPart.Name + ': ' + GetTypeName('', Name + ArrayPart.Name, 'Collection') + ';');
      end;
      for I := 0 to StringParts.Count - 1 do
      begin
        StringPart := StringParts[I] as TPxCGStringPart;
        Output.AddLine('F' + StringPart.Name + ': WideString;');
      end;

      if FloatParts.Count > 0 then
      begin
        Output.Lines.Add('{$IFDEF VER150}');
        Output.Lines.Add('{$IFDEF DATARECORDEX_PART_FLOAT}');
        for I := 0 to FloatParts.Count - 1 do
        begin
          FloatPart := FloatParts[I] as TPxCGFloatPart;
          Output.AddLine('F' + FloatPart.Name + ': TFloatData;');
        end;
        Output.Lines.Add('{$ENDIF}');
        Output.Lines.Add('{$ENDIF}');
      end;

      for I := 0 to StreamParts.Count - 1 do
      begin
        StreamPart := StreamParts[I] as TPxCGStreamPart;
        Output.AddLine('F' + StreamPart.Name + ': TStream;');
      end;

      if ExpressionParts.Count > 0 then
      begin
        Output.Lines.Add('{$IFDEF VER150}');
        Output.Lines.Add('{$IFDEF DATARECORDEX_PART_EXPRESSION}');
        for I := 0 to ExpressionParts.Count - 1 do
        begin
          ExpressionPart := ExpressionParts[I] as TPxCGExpressionPart;
          Output.AddLine('F' + ExpressionPart.Name + ': TExpression;');
        end;
        Output.Lines.Add('{$ENDIF}');
        Output.Lines.Add('{$ENDIF}');
      end;

      // Float parts read methods
      for I := 0 to FloatParts.Count - 1 do
      begin
        FloatPart := FloatParts[I] as TPxCGFloatPart;
        Output.AddLine('function Get' + FloatPart.Name + ': PFloatData;');
      end;
      if FloatParts.Count > 0 then
      begin
        Output.Lines.Add('{$ENDIF}');
        Output.Lines.Add('{$ENDIF}');
      end;
    end;
    Output.DecIndent;
    Output.AddProtected;
      // Assign method
      if AssignMethod then
        Output.AddLine('procedure AssignTo(Dest: TPersistent); override;');

      Output.AddLine('procedure Initialize; override;');
      if (ArrayParts.Count > 0) or (StreamParts.Count > 0) or (ExpressionParts.Count > 0) or HasRuntimeFieldsWithCreateInstance then
        Output.AddLine('procedure Finalize; override;');

      if DataParts.Count > 0 then
        Output.AddLine('function ReadPart(S: TStream; const PH: TPxDataPartHeader): TPxReadPartResult; override;');
      if StringParts.Count > 0 then
        Output.AddLine('function ReadString(S: WideString; const ID: Word): TPxReadPartResult; override;');
      if FloatParts.Count > 0 then
      begin
        Output.Lines.Add('{$IFDEF VER150}');
        Output.Lines.Add('{$IFDEF DATARECORDEX_PART_FLOAT}');
        Output.AddLine('function ReadFloat(Value: TFloatData; const ID: Word): TPxReadPartResult; override;');
        Output.Lines.Add('{$ENDIF}');
        Output.Lines.Add('{$ENDIF}');
      end;
      if StreamParts.Count > 0 then
        Output.AddLine('function ReadStream(Stream: TStream; const ID: Word): TPxReadPartResult; override;');

      if ExpressionParts.Count > 0 then
      begin
        Output.Lines.Add('{$IFDEF VER150}');
        Output.Lines.Add('{$IFDEF DATARECORDEX_PART_EXPRESSION}');
        Output.AddLine('function ReadExpression(Value: TExpression; const ID: Word): TPxReadPartResult; override;');
        Output.Lines.Add('{$ENDIF}');
        Output.Lines.Add('{$ENDIF}');
      end;

      if (DataParts.Count > 0) or (StringParts.Count > 0) or (StreamParts.Count > 0) or (ExpressionParts.Count > 0) then
        Output.AddLine('procedure WriteAllParts(S: TStream); override;');

      if HasFieldsWithID then
        Output.AddLine('procedure OnResolveIDs(Resolver: TPxIdResolver); override;');
    Output.DecIndent;
    if (RecordIDField <> '') or PropsStreamingMethods then
    begin
      Output.AddPublic;
      if RecordIDField <> '' then
      begin
        Output.AddLine('function RecordID: TIdentifier; override;');
      end;

      if PropsStreamingMethods then
      begin
        Output.AddLine('procedure LoadProps(S: TStream; Properties: array of Integer);');
        Output.AddLine('procedure SaveProps(S: TStream; Properties: array of Integer);');
      end;

      // runtime fields
      if (RuntimeFields.Count > 0) then
        Output.AddLine('// Run-time fields');
      for I := 0 to RuntimeFields.Count - 1 do
      begin
        RuntimeField := RuntimeFields[I] as TPxCGRuntimeField;
        if RuntimeField.CreateInstance then
          Output.AddLine('property ' + RuntimeField.FieldName + ': ' + RuntimeField.FieldType + ' read F' + RuntimeField.FieldName + ';')
        else
          Output.AddLine('property ' + RuntimeField.FieldName + ': ' + RuntimeField.FieldType + ' read F' + RuntimeField.FieldName + ' write F' + RuntimeField.FieldName + ';');
      end;

      Output.DecIndent;
    end;

    if (ArrayParts.Count > 0) or (DataParts.Count > 0) or (StringParts.Count > 0) or (StreamParts.Count > 0) or (ExpressionParts.Count > 0) then
    begin
      // published (RTTI-enabled) fields
      Output.AddPublished;

      if (RuntimeFields.Count > 0) then
        Output.AddLine('// Saved fields');

      for I := 0 to DataParts.Count - 1 do
      begin
        DataPart := DataParts[I] as TPxCGDataPart;
        for J := 0 to DataPart.Fields.Count - 1 do
        begin
          Field := DataPart.Fields[J] as TPxCGField;
          Output.AddLine('property ' + Field.FieldName + ': ' + Field.FieldType + ' read F' + DataPart.Name + '.' + Field.FieldName + ' write F' + DataPart.Name + '.' + Field.FieldName + ';');
        end;
      end;
      for I := 0 to StringParts.Count - 1 do
      begin
        StringPart := StringParts[I] as TPxCGStringPart;
        Output.AddLine('property ' + StringPart.Name + ': WideString read F' + StringPart.Name + ' write F' + StringPart.Name + ';');
      end;

      for I := 0 to ArrayParts.Count - 1 do
      begin
        ArrayPart := ArrayParts[I] as TPxCGArrayPart;
        Output.AddLine('property ' + ArrayPart.Name + ': ' + GetTypeName('', Name + ArrayPart.Name, 'Collection') + ' read F' + ArrayPart.Name + ';');
      end;

      if FloatParts.Count > 0 then
      begin
        Output.Lines.Add('{$IFDEF VER150}');
        Output.Lines.Add('{$IFDEF DATARECORDEX_PART_FLOAT}');
        for I := 0 to FloatParts.Count - 1 do
        begin
          FloatPart := FloatParts[I] as TPxCGFloatPart;
          Output.AddLine('property ' + FloatPart.Name + ': PFloatData read Get' + FloatPart.Name + ';');
        end;
        Output.Lines.Add('{$ENDIF}');
        Output.Lines.Add('{$ENDIF}');
      end;

      for I := 0 to StreamParts.Count - 1 do
      begin
        StreamPart := StreamParts[I] as TPxCGStreamPart;
        Output.AddLine('property ' + StreamPart.Name + ': TStream read F' + StreamPart.Name + ';');
      end;

      if ExpressionParts.Count > 0 then
      begin
        Output.Lines.Add('{$IFDEF VER150}');
        Output.Lines.Add('{$IFDEF DATARECORDEX_PART_EXPRESSION}');
        for I := 0 to ExpressionParts.Count - 1 do
        begin
          ExpressionPart := ExpressionParts[I] as TPxCGExpressionPart;
          Output.AddLine('property ' + ExpressionPart.Name + ': TExpression read F' + ExpressionPart.Name + ';');
        end;
        Output.Lines.Add('{$ENDIF}');
        Output.Lines.Add('{$ENDIF}');
      end;
    end;
    Output.AddEnd;
  Output.DecIndent;

  if not Single then
    CreateListInterface(Output);
end;

procedure TPxCGDataRecordEx.CreateImplementation(Output: TPxCGOutput);
var
  I: Integer;
  RuntimeField: TPxCGRuntimeField;
  DataPart: TPxCGDataPart;
  ArrayPart: TPxCGArrayPart;
  StringPart: TPxCGStringPart;
  FloatPart: TPxCGFloatPart;
  StreamPart: TPxCGStreamPart;
  ExpressionPart: TPxCGExpressionPart;
begin
  for I := 0 to ArrayParts.Count - 1 do
  begin
    ArrayPart := ArrayParts[I] as TPxCGArrayPart;
    ArrayPart.CreateImplementation(Output);
  end;

  Output.AddLine('{ ' + GetTypeName('', Name, '') + ' }');
  Output.AddLine('');

  // arrays
  if (ArrayParts.Count > 0) or (FloatParts.Count > 0) then
  begin
    Output.AddLine('{ Private declarations }');
    Output.AddLine('');
    if FloatParts.Count > 0 then
    begin
      Output.Lines.Add('{$IFDEF VER150}');
      Output.Lines.Add('{$IFDEF DATARECORDEX_PART_FLOAT}');
    end;
    for I := 0 to FloatParts.Count - 1 do
    begin
      FloatPart := FloatParts[I] as TPxCGFloatPart;
      Output.AddLine('function ' + GetTypeName('', Name, '') + '.Get' + FloatPart.Name + ': PFloatData;');
      Output.AddBegin;
        Output.AddLine('Result := @F' + FloatPart.Name + ';');
      Output.AddEnd;
      if I = FloatParts.Count - 1 then
      begin
        Output.Lines.Add('{$ENDIF}');
        Output.Lines.Add('{$ENDIF}');
      end;
      Output.AddLine('');
    end;
  end;

  Output.AddLine('{ Protected declarations }');
  Output.AddLine('');

  // Initialize
  Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.Initialize;');
  Output.AddBegin;
    Output.AddLine('inherited Initialize;');
    Output.AddLine('Header.Kind := kindid' + Name + ';');
    // runtime fields
    for I := 0 to RuntimeFields.Count - 1 do
    begin
      RuntimeField := RuntimeFields[I] as TPxCGRuntimeField;
      if RuntimeField.CreateInstance then
      begin
        if RuntimeField.CreateParams <> '' then
          Output.AddLine('F' + RuntimeField.FieldName + ' := ' + RuntimeField.FieldType + '.Create(' + RuntimeField.CreateParams + ');')
        else
          Output.AddLine('F' + RuntimeField.FieldName + ' := ' + RuntimeField.FieldType + '.Create;');
      end;
    end;

    // saved fields
    for I := 0 to ArrayParts.Count - 1 do
    begin
      ArrayPart := ArrayParts[I] as TPxCGArrayPart;
      Output.AddLine('F' + ArrayPart.Name + ' := ' + GetTypeName('', Name + ArrayPart.Name, 'Collection') + '.Create;');
    end;

    if FloatParts.Count > 0 then
    begin
      Output.Lines.Add('{$IFDEF VER150}');
      Output.Lines.Add('{$IFDEF DATARECORDEX_PART_FLOAT}');
      for I := 0 to FloatParts.Count - 1 do
      begin
        FloatPart := FloatParts[I] as TPxCGFloatPart;
        Output.AddLine('F' + FloatPart.Name + '.UnitFamily := ' + FloatPart.UnitFamily + ';');
        Output.AddLine('F' + FloatPart.Name + '.UnitType := ' + FloatPart.UnitName + ';');
      end;
      Output.Lines.Add('{$ENDIF}');
      Output.Lines.Add('{$ENDIF}');
    end;

    for I := 0 to StreamParts.Count - 1 do
    begin
      StreamPart := StreamParts[I] as TPxCGStreamPart;
      Output.AddLine('CreateStream(stmid' + Name + StreamPart.Name + ', F' + StreamPart.Name + ');');
    end;

    if ExpressionParts.Count > 0 then
    begin
      Output.Lines.Add('{$IFDEF VER150}');
      Output.Lines.Add('{$IFDEF DATARECORDEX_PART_EXPRESSION}');
      for I := 0 to ExpressionParts.Count - 1 do
      begin
        ExpressionPart := ExpressionParts[I] as TPxCGExpressionPart;
        Output.AddLine('F' + ExpressionPart.Name + ' := TExpression.Create;');
        Output.AddLine('F' + ExpressionPart.Name + '.UnitFamily := ' + ExpressionPart.UnitFamily + ';');
        Output.AddLine('F' + ExpressionPart.Name + '.UnitType := ' + ExpressionPart.UnitName + ';');
        Output.AddLine('F' + ExpressionPart.Name + '.Text := ''' + ExpressionPart.Expression + ''';');
      end;
      Output.Lines.Add('{$ENDIF}');
      Output.Lines.Add('{$ENDIF}');
    end;
  Output.AddEnd;

  // Finalize
  if (ArrayParts.Count > 0) or (StreamParts.Count > 0) or (ExpressionParts.Count > 0) or HasRuntimeFieldsWithCreateInstance then
  begin
    Output.AddLine('');
    Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.Finalize;');
    Output.AddBegin;

    // runtime fields
    if RuntimeFields.Count > 0 then
      Output.AddLine('// Run-time fields');
    for I := 0 to RuntimeFields.Count - 1 do
    begin
      RuntimeField := RuntimeFields[I] as TPxCGRuntimeField;
      if RuntimeField.CreateInstance then
        Output.AddLine('FreeAndNil(F' + RuntimeField.FieldName + ');');
    end;
    if RuntimeFields.Count > 0 then
      Output.AddLine('// Saved fields');

    for I := 0 to ArrayParts.Count - 1 do
    begin
      ArrayPart := ArrayParts[I] as TPxCGArrayPart;
      Output.AddLine('F' + ArrayPart.Name + '.Free;');
    end;

    for I := 0 to StreamParts.Count - 1 do
    begin
      StreamPart := StreamParts[I] as TPxCGStreamPart;
      Output.AddLine('F' + StreamPart.Name + '.Free;');
    end;

    if ExpressionParts.Count > 0 then
    begin
      Output.Lines.Add('{$IFDEF VER150}');
      Output.Lines.Add('{$IFDEF DATARECORDEX_PART_EXPRESSION}');
      for I := 0 to ExpressionParts.Count - 1 do
      begin
        ExpressionPart := ExpressionParts[I] as TPxCGExpressionPart;
        Output.AddLine('F' + ExpressionPart.Name + '.Free;');
      end;
      Output.Lines.Add('{$ENDIF}');
      Output.Lines.Add('{$ENDIF}');
    end;
    Output.AddLine('inherited Finalize;');
    Output.AddEnd;
  end;

  // ReadPart
  if (DataParts.Count > 0) or (ArrayParts.Count > 0) then
  begin
    Output.AddLine('');
    Output.AddLine('function ' + GetTypeName('', Name, '') + '.ReadPart(S: TStream; const PH: TPxDataPartHeader): TPxReadPartResult;');
    Output.AddBegin;
      Output.AddLine('case PH.Part of');
      Output.IncIndent;
        for I := 0 to DataParts.Count - 1 do
        begin
          DataPart := DataParts[I] as TPxCGDataPart;
          Output.AddLine('partid' + Name + DataPart.Name + ':');
          Output.IncIndent;
            Output.AddBegin;
              Output.AddLine('ReadData(S, F' + DataPart.Name + ', SizeOf(F' + DataPart.Name + '), PH.Size);');
              Output.AddLine('Result := rprRecognized;');
            Output.AddEnd;
          Output.DecIndent;
        end;
        for I := 0 to ArrayParts.Count - 1 do
        begin
          ArrayPart := ArrayParts[I] as TPxCGArrayPart;
          Output.AddLine('partid' + Name + ArrayPart.Name + ':');
          Output.AddBegin;
            Output.AddLine('ReadData(S, ' + ArrayPart.Name + '.Add.Data, SizeOf(' + GetTypeName('', Name + ArrayPart.Name, 'Rec') + '), PH.Size);');
            Output.AddLine('Result := rprRecognized;');
          Output.AddEnd;
        end;
        Output.AddLine('else Result := inherited ReadPart(S, PH);');
      Output.AddEnd;
    Output.AddEnd;
  end;

  // ReadString
  if StringParts.Count > 0 then
  begin
    Output.AddLine('');
    Output.AddLine('function ' + GetTypeName('', Name, '') + '.ReadString(S: WideString; const ID: Word): TPxReadPartResult;');
    Output.AddBegin;
      Output.AddLine('case ID of');
      Output.IncIndent;
        for I := 0 to StringParts.Count - 1 do
        begin
          StringPart := StringParts[I] as TPxCGStringPart;
          Output.AddLine('strid' + Name + StringPart.Name + ':');
          Output.IncIndent;
            Output.AddBegin;
              Output.AddLine('F' + StringPart.Name + ' := S;');
              Output.AddLine('Result := rprRecognized;');
            Output.AddEnd;
          Output.DecIndent;
        end;
        Output.AddLine('else Result := inherited ReadString(S, ID);');
      Output.AddEnd;
    Output.AddEnd;
  end;

  // ReadFloat
  if FloatParts.Count > 0 then
  begin
    Output.AddLine('');
    Output.Lines.Add('{$IFDEF VER150}');
    Output.Lines.Add('{$IFDEF DATARECORDEX_PART_FLOAT}');
    Output.AddLine('function ' + GetTypeName('', Name, '') + '.ReadFloat(Value: TFloatData; const ID: Word): TPxReadPartResult;');
    Output.AddBegin;
      Output.AddLine('case ID of');
      Output.IncIndent;
        for I := 0 to FloatParts.Count - 1 do
        begin
          FloatPart := FloatParts[I] as TPxCGFloatPart;
          Output.AddLine('fltid' + Name + FloatPart.Name + ':');
          Output.IncIndent;
            Output.AddBegin;
              Output.AddLine('F' + FloatPart.Name + ' := Value;');
              Output.AddLine('Result := rprRecognized;');
            Output.AddEnd;
          Output.DecIndent;
        end;
        Output.AddLine('else Result := inherited ReadFloat(Value, ID);');
      Output.AddEnd;
    Output.AddEnd;
    Output.Lines.Add('{$ENDIF}');
    Output.Lines.Add('{$ENDIF}');
  end;

  // ReadStream
  if StreamParts.Count > 0 then
  begin
    Output.AddLine('');
    Output.AddLine('function ' + GetTypeName('', Name, '') + '.ReadStream(Stream: TStream; const ID: Word): TPxReadPartResult;');
    Output.AddBegin;
      Output.AddLine('case ID of');
      Output.IncIndent;
        for I := 0 to StreamParts.Count - 1 do
        begin
          StreamPart := StreamParts[I] as TPxCGStreamPart;
          Output.AddLine('stmid' + Name + StreamPart.Name + ':');
          Output.IncIndent;
            Output.AddBegin;
              Output.AddLine('F' + StreamPart.Name + '.Size := 0;');
              Output.AddLine('F' + StreamPart.Name + '.CopyFrom(Stream, Stream.Size);');
              Output.AddLine('F' + StreamPart.Name + '.Position := 0;');
              Output.AddLine('Result := rprRecognized;');
            Output.AddEnd;
          Output.DecIndent;
        end;
        Output.AddLine('else Result := inherited ReadStream(Stream, ID);');
      Output.AddEnd;
    Output.AddEnd;
  end;

  // ReadExpression
  if ExpressionParts.Count > 0 then
  begin
    Output.AddLine('');
    Output.Lines.Add('{$IFDEF VER150}');
    Output.Lines.Add('{$IFDEF DATARECORDEX_PART_EXPRESSION}');
    Output.AddLine('function ' + GetTypeName('', Name, '') + '.ReadExpression(Value: TExpression; const ID: Word): TPxReadPartResult;');
    Output.AddBegin;
      Output.AddLine('case ID of');
      Output.IncIndent;
        for I := 0 to ExpressionParts.Count - 1 do
        begin
          ExpressionPart := ExpressionParts[I] as TPxCGExpressionPart;
          Output.AddLine('expid' + Name + ExpressionPart.Name + ':');
          Output.IncIndent;
            Output.AddBegin;
              Output.AddLine('F' + ExpressionPart.Name + '.Assign(Value);');
              Output.AddLine('Result := rprRecognized;');
            Output.AddEnd;
          Output.DecIndent;
        end;
        Output.AddLine('else Result := inherited ReadExpression(Value, ID);');
      Output.AddEnd;
    Output.AddEnd;
    Output.Lines.Add('{$ENDIF}');
    Output.Lines.Add('{$ENDIF}');
  end;

  // WriteAllParts
  if (DataParts.Count > 0) or (StringParts.Count > 0) or (StreamParts.Count > 0) or (ExpressionParts.Count > 0) then
  begin
    Output.AddLine('');
    Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.WriteAllParts(S: TStream); ');
    if ArrayParts.Count > 0 then
    begin
      Output.AddLine('var');
      Output.IncIndent;
        Output.AddLine('I: Integer;');
      Output.DecIndent;
    end;
    Output.AddBegin;
    for I := 0 to DataParts.Count - 1 do
    begin
      DataPart := DataParts[I] as TPxCGDataPart;
      Output.AddLine('WritePart(S, partid' + Name + DataPart.Name + ', F' + DataPart.Name + ', SizeOf(F' + DataPart.Name + '));');
    end;
    for I := 0 to ArrayParts.Count - 1 do
    begin
      ArrayPart := ArrayParts[I] as TPxCGArrayPart;
      Output.AddLine('for I := 0 to ' + ArrayPart.Name + '.Count - 1 do');
        Output.AddLine('  WritePart(S, partid' + Name + ArrayPart.Name + ', ' + ArrayPart.Name + '.Items[I].Data, SizeOf(' + GetTypeName('', Name + ArrayPart.Name, 'Rec') + '));');
    end;
    for I := 0 to StringParts.Count - 1 do
    begin
      StringPart := StringParts[I] as TPxCGStringPart;
      Output.AddLine('WriteString(S, strid' + Name + StringPart.Name + ', F' + StringPart.Name + ');');
    end;
    if FloatParts.Count > 0 then
    begin
      Output.Lines.Add('{$IFDEF VER150}');
      Output.Lines.Add('{$IFDEF DATARECORDEX_PART_FLOAT}');
      for I := 0 to FloatParts.Count - 1 do
      begin
        FloatPart := FloatParts[I] as TPxCGFloatPart;
        Output.AddLine('WriteFloat(S, fltid' + Name + FloatPart.Name + ', F' + FloatPart.Name + ');');
      end;
      Output.Lines.Add('{$ENDIF}');
      Output.Lines.Add('{$ENDIF}');
    end;
    for I := 0 to StreamParts.Count - 1 do
    begin
      StreamPart := StreamParts[I] as TPxCGStreamPart;
      Output.AddLine('WriteStream(S, stmid' + Name + StreamPart.Name + ', F' + StreamPart.Name + ');');
    end;
    if ExpressionParts.Count > 0 then
    begin
      Output.Lines.Add('{$IFDEF VER150}');
      Output.Lines.Add('{$IFDEF DATARECORDEX_PART_EXPRESSION}');
      for I := 0 to FloatParts.Count - 1 do
      begin
        ExpressionPart := FloatParts[I] as TPxCGExpressionPart;
        Output.AddLine('WriteExpression(S, expid' + Name + ExpressionPart.Name + ', F' + ExpressionPart.Name + ');');
      end;
      Output.Lines.Add('{$ENDIF}');
      Output.Lines.Add('{$ENDIF}');
    end;
    Output.AddEnd;
  end;

  if not Single then
    CreateListImplementation(Output);

  if HasFieldsWithID or (AddToLists.Count > 0) then
    CreateOnResolveIDs(Output);

  if PropsStreamingMethods or (RecordIDField <> '') or AssignMethod then
  begin
    Output.AddLine('');
    Output.AddLine('{ Public declarations }');
    Output.AddLine('');
    if RecordIDField <> '' then
    begin
      Output.AddLine('function ' + GetTypeName('', Name, '') + '.RecordID: TIdentifier;');
      Output.AddBegin;
        Output.AddLine('Result := ' + RecordIDField + ';');
      Output.AddEnd;
    end;

    if PropsStreamingMethods then
    begin
      CreateLoadProps(Output);
      CreateSaveProps(Output);
    end;

    if AssignMethod then
      CreateAssign(Output, RecordIdField);
  end;
end;

procedure TPxCGDataRecordEx.CreateXmlRead(Output: TPxCGOutput);
  function IsMultiField: Boolean;
  var
    I, Count: Integer;
    Part: TPxCGDataPart;
  begin
    Count := StringParts.Count;
    for I := 0 to DataParts.Count - 1 do
    begin
      Part := DataParts[I] as TPxCGDataPart;
      Count := Count + Part.Fields.Count;
    end;
    if ArrayParts.Count > 0 then Inc(Count, 2);
    if FloatParts.Count > 0 then Inc(Count, 2);
    if ExpressionParts.Count > 0 then Inc(Count, 2);
    if StreamParts.Count > 0 then Inc(Count, 2);
    Result := Count > 1;
  end;
var
  I: Integer;
  Part: TPxCGPart;
begin
  CreateBeginningOfReadXml(Output, IsMultiField);
  for I := 0 to DataParts.Count - 1 do
  begin
    Part := DataParts[I] as TPxCGPart;
    Part.CreateXmlRead(Output);
  end;
  for I := 0 to ArrayParts.Count - 1 do
  begin
    Part := ArrayParts[I] as TPxCGPart;
    Part.CreateXmlRead(Output);
  end;
  for I := 0 to StringParts.Count - 1 do
  begin
    Part := StringParts[I] as TPxCGPart;
    Part.CreateXmlRead(Output);
  end;
  for I := 0 to FloatParts.Count - 1 do
  begin
    Part := FloatParts[I] as TPxCGPart;
    Part.CreateXmlRead(Output);
  end;
  for I := 0 to StreamParts.Count - 1 do
  begin
    Part := StreamParts[I] as TPxCGPart;
    Part.CreateXmlRead(Output);
  end;
  for I := 0 to ExpressionParts.Count - 1 do
  begin
    Part := ExpressionParts[I] as TPxCGPart;
    Part.CreateXmlRead(Output);
  end;
  CreateEndingOfReadXml(Output, IsMultiField);
end;

procedure TPxCGDataRecordEx.CreateXmlWrite(Output: TPxCGOutput);
var
  I: Integer;
  Part: TPxCGPart;
begin
  Output.AddLine('with TPxXMLItem.Create(This), ' + Name + ' do');

  Output.AddBegin;
    Output.AddLine('This.Name := ''' + Name + ''';');
    if TPxCGDataFile(Owner).StricTPxXMLItemCheck then
      Output.AddLine('GetParamByName(''Id'').AsInteger := ' + Id + ';');
    for I := 0 to DataParts.Count - 1 do
    begin
      Part := DataParts[I] as TPxCGPart;
      Part.CreateXmlWrite(Output);
    end;
    for I := 0 to ArrayParts.Count - 1 do
    begin
      Part := ArrayParts[I] as TPxCGPart;
      Part.CreateXmlWrite(Output);
    end;
    for I := 0 to StringParts.Count - 1 do
    begin
      Part := StringParts[I] as TPxCGPart;
      Part.CreateXmlWrite(Output);
    end;
    for I := 0 to FloatParts.Count - 1 do
    begin
      Part := FloatParts[I] as TPxCGPart;
      Part.CreateXmlWrite(Output);
    end;
    for I := 0 to StreamParts.Count - 1 do
    begin
      Part := StreamParts[I] as TPxCGPart;
      Part.CreateXmlWrite(Output);
    end;
    for I := 0 to ExpressionParts.Count - 1 do
    begin
      Part := ExpressionParts[I] as TPxCGPart;
      Part.CreateXmlWrite(Output);
    end;
  Output.AddEnd;
end;

{ TPxCGPart }

{ Protected declarations }

procedure TPxCGPart.ReadParams;
begin
  if Xml.HasParam('Name') then
    Name := Xml.GetParamByNameS('Name');
  if Xml.HasParam('Id') then
    Id := Xml.GetParamByNameS('Id');

  // sprawdzenie poprawnoœci danych
  if not IsValidName(Name) then
    raise EGeneratorException.CreateFmt('Invalid <(Part) NAME="%s" ... /> in DataRecordEx "%s"', [Name, TPxCGDataRecordEx(Owner).Name]);
  if not IsValidNumber(Id) then
    raise EGeneratorException.CreateFmt('Invalid <(Part) ID="%s" ... /> in DataRecordEx "%s"', [Id, TPxCGDataRecordEx(Owner).Name]);
end;

{ TPxCGDataPart }

{ Protected declarations }

procedure TPxCGDataPart.ReadParams;
begin
  inherited ReadParams;
  Fields := CreateList('Field', TPxCGField);
end;

{ Public declarations }

destructor TPxCGDataPart.Destroy;
begin
  FreeAndNil(Fields);
  inherited Destroy;
end;

procedure TPxCGDataPart.CreateInterface(Output: TPxCGOutput);
var
  I: Integer;
  Field: TPxCGField;
begin
  Output.AddLine('const');
  Output.IncIndent;
    Output.AddLine('partid' + TPxCGDataRecord(Owner).Name + Name + ' = ' + Id + ';');
  Output.DecIndent;
  Output.AddLine('');

  Output.AddLine('type');
  Output.IncIndent;
    Output.AddLine(GetTypeName('', TPxCGDataRecord(Owner).Name + Name, 'Rec') + ' = packed record');
    Output.IncIndent;
      for I := 0 to Fields.Count - 1 do
      begin
        Field := Fields[I] as TPxCGField;
        Output.AddLine(Field.FieldName + ': ' + Field.FieldType + ';');
      end;
    Output.AddEnd;
  Output.DecIndent;
end;

procedure TPxCGDataPart.CreateXmlRead(Output: TPxCGOutput);
var
  I: Integer;
  Field: TPxCGField;
begin
  for I := 0 to Fields.Count - 1 do
  begin
    Field := Fields[I] as TPxCGField;
    Field.CreateXmlRead(Output);
  end;
end;

procedure TPxCGDataPart.CreateXmlWrite(Output: TPxCGOutput);
var
  I: Integer;
  Field: TPxCGField;
begin
  for I := 0 to Fields.Count - 1 do
  begin
    Field := Fields[I] as TPxCGField;
    Field.CreateXmlWrite(Output);
  end;
end;

{ TPxCGArrayPart }

{ Protected declarations }

procedure TPxCGArrayPart.ReadParams;
begin
  inherited ReadParams;
  Fields := CreateList('Field', TPxCGField);
end;

{ Public declarations }

destructor TPxCGArrayPart.Destroy;
begin
  FreeAndNil(Fields);
  inherited Destroy;
end;

procedure TPxCGArrayPart.CreateInterface(Output: TPxCGOutput);
var
  I: Integer;
  Field: TPxCGField;
begin
  Output.AddLine('const');
  Output.IncIndent;
    Output.AddLine('partid' + TPxCGDataRecord(Owner).Name + Name + ' = ' + Id + ';');
  Output.DecIndent;
  Output.AddLine('');

  Output.AddLine('type');
  Output.IncIndent;
//    Output.AddLine(GetPTypeName('', TPxCGDataRecord(Owner).Name + Name, 'Rec') + ' = ^' + GetTypeName('', TPxCGDataRecord(Owner).Name + Name, 'Rec') + ';');
    Output.AddLine(GetTypeName('', TPxCGDataRecord(Owner).Name + Name, 'Rec') + ' = packed record');
    Output.IncIndent;
      for I := 0 to Fields.Count - 1 do
      begin
        Field := Fields[I] as TPxCGField;
        Output.AddLine(Field.FieldName + ': ' + Field.FieldType + ';');
      end;
    Output.AddEnd;
  Output.DecIndent;

  Output.AddLine('');
  Output.IncIndent;
    Output.AddLine(GetTypeName('', TPxCGDataRecord(Owner).Name + Name, 'Item') + ' = class (TCollectionItem)');
    Output.AddPrivate;
      for I := 0 to Fields.Count - 1 do
      begin
        Field := Fields[I] as TPxCGField;
        if _IsArrayOfChar(Field.FieldType) then
        begin
          Output.AddLine('function Get' + Field.FieldName + ': String;');
          Output.AddLine('procedure Set' + Field.FieldName + '(Value: String);');
        end
        else
        begin
          Output.AddLine('function Get' + Field.FieldName + ': ' + Field.FieldType + ';');
          Output.AddLine('procedure Set' + Field.FieldName + '(Value: ' + Field.FieldType + ');');
        end;
      end;
    Output.DecIndent;
    Output.AddPublic;
      Output.AddLine('Data: ' + GetTypeName('', TPxCGDataRecord(Owner).Name + Name, 'Rec') + ';');
    Output.DecIndent;
    Output.AddPublished;
      for I := 0 to Fields.Count - 1 do
      begin
        Field := Fields[I] as TPxCGField;
        if _IsArrayOfChar(Field.FieldType) then
          Output.AddLine('property ' + Field.FieldName + ': String read Get' + Field.FieldName + ' write Set' + Field.FieldName + ';')
        else
          Output.AddLine('property ' + Field.FieldName + ': ' + Field.FieldType + ' read Get' + Field.FieldName + ' write Set' + Field.FieldName + ';');
//        Output.AddLine('property ' + Field.FieldName + ': ' + Field.FieldType + ' read Get' + Field.FieldName + ' write Set' + Field.FieldName + ';');
      end;
    Output.AddEnd;
  Output.DecIndent;

  Output.AddLine('');
  Output.IncIndent;
    Output.AddLine(GetTypeName('', TPxCGDataRecord(Owner).Name + Name, 'Collection') + ' = class (TCollection)');
    Output.AddPrivate;
      Output.AddLine('function GetItem(Index: Integer): ' + GetTypeName('', TPxCGDataRecord(Owner).Name + Name, 'Item') + ';');
    Output.DecIndent;
    Output.AddPublic;
      Output.AddLine('constructor Create;');
      Output.AddLine('function Add: ' + GetTypeName('', TPxCGDataRecord(Owner).Name + Name, 'Item') + ';');
      Output.AddLine('property Items[Index: Integer]: ' + GetTypeName('', TPxCGDataRecord(Owner).Name + Name, 'Item') + ' read GetItem; default;');
    Output.AddEnd;
  Output.DecIndent;
end;


procedure TPxCGArrayPart.CreateImplementation(Output: TPxCGOutput);
var
  I: Integer;
  Field: TPxCGField;
begin
  Output.AddLine('{ ' + GetTypeName('', TPxCGDataRecord(Owner).Name + Name, 'Item') + ' }');
  Output.AddLine('');
  Output.AddLine('{ Private declarations }');
  Output.AddLine('');
//  for I := 0 to Fields.Count - 1 do
//  begin
//    Field := Fields[I] as TPxCGField;
//    Output.AddLine('function ' + GetTypeName('', TPxCGDataRecord(Owner).Name + Name, 'Item') + '.Get' + Field.FieldName + ': ' + Field.FieldType + ';');
//    Output.AddBegin;
//      Output.AddLine('Result := Data.' + Field.FieldName + ';');
//    Output.AddEnd;
//    Output.AddLine('');
//    Output.AddLine('procedure ' + GetTypeName('', TPxCGDataRecord(Owner).Name + Name, 'Item') + '.Set' + Field.FieldName + '(Value: ' + Field.FieldType + ');');
//    Output.AddBegin;
//      Output.AddLine('Data.' + Field.FieldName + ' := Value;');
//    Output.AddEnd;
//    Output.AddLine('');
//  end;

  for I := 0 to Fields.Count - 1 do
  begin
    Field := Fields[I] as TPxCGField;
    if _IsArrayOfChar(Field.FieldType) then
      Output.AddLine('function ' + GetTypeName('', TPxCGDataRecord(Owner).Name + Name, 'Item') + '.Get' + Field.FieldName + ': String;')
    else
      Output.AddLine('function ' + GetTypeName('', TPxCGDataRecord(Owner).Name + Name, 'Item') + '.Get' + Field.FieldName + ': ' + Field.FieldType + ';');
    Output.AddBegin;
      Output.AddLine('Result := Data.' + Field.FieldName + ';');
    Output.AddEnd;
    Output.AddLine('');
    if _IsArrayOfChar(Field.FieldType) then
      Output.AddLine('procedure ' + GetTypeName('', TPxCGDataRecord(Owner).Name + Name, 'Item') + '.Set' + Field.FieldName + '(Value: String);')
    else
      Output.AddLine('procedure ' + GetTypeName('', TPxCGDataRecord(Owner).Name + Name, 'Item') + '.Set' + Field.FieldName + '(Value: ' + Field.FieldType + ');');
    Output.AddBegin;

    if _IsArrayOfChar(Field.FieldType) then
      Output.AddLine('StringToArrayOfChar(Value, Data.' + Field.FieldName + ');')
    else
      Output.AddLine('Data.' + Field.FieldName + ' := Value;');
    Output.AddEnd;
    Output.AddLine('');
  end;

  Output.AddLine('{ ' + GetTypeName('', TPxCGDataRecord(Owner).Name + Name, 'Collection') + ' }');
  Output.AddLine('');
  Output.AddLine('{ Private declarations }');
  Output.AddLine('');
  Output.AddLine('function ' + GetTypeName('', TPxCGDataRecord(Owner).Name + Name, 'Collection') + '.GetItem(Index: Integer): ' + GetTypeName('', TPxCGDataRecord(Owner).Name + Name, 'Item') + ';');
  Output.AddBegin;
    Output.AddLine('Result := inherited Items[Index] as ' + GetTypeName('', TPxCGDataRecord(Owner).Name + Name, 'Item') + ';');
  Output.AddEnd;
  Output.AddLine('');
  Output.AddLine('{ Public declarations }');
  Output.AddLine('');
  Output.AddLine('constructor ' + GetTypeName('', TPxCGDataRecord(Owner).Name + Name, 'Collection') + '.Create;');
  Output.AddBegin;
    Output.AddLine('inherited Create(' + GetTypeName('', TPxCGDataRecord(Owner).Name + Name, 'Item') + ');');
  Output.AddEnd;
  Output.AddLine('');
  Output.AddLine('function ' + GetTypeName('', TPxCGDataRecord(Owner).Name + Name, 'Collection') + '.Add: ' + GetTypeName('', TPxCGDataRecord(Owner).Name + Name, 'Item') + ';');
  Output.AddBegin;
    Output.AddLine('Result := inherited Add as ' + GetTypeName('', TPxCGDataRecord(Owner).Name + Name, 'Item') + ';');
  Output.AddEnd;
  Output.AddLine('');
end;

procedure TPxCGArrayPart.CreateXmlRead(Output: TPxCGOutput);
var
  I: Integer;
  Field: TPxCGField;
begin
  Output.AddLine('for K := 0 to ItemCount - 1 do');
  Output.IncIndent;
    Output.AddLine('if Items[K].IsItemName(''' + Name + ''') then');
    Output.AddBegin;
      Output.AddLine('with ' + Name + '.Add, Items[K] do');
      Output.AddBegin;
        for I := 0 to Fields.Count - 1 do
        begin
          Field := Fields[I] as TPxCGField;
          Field.CreateXmlRead(Output);
        end;
      Output.AddEnd;
    Output.AddEnd;
  Output.DecIndent;
end;

procedure TPxCGArrayPart.CreateXmlWrite(Output: TPxCGOutput);
var
  I: Integer;
  Field: TPxCGField;
begin
  Output.AddLine('for K := 0 to ' + Name + '.Count - 1 do');
  Output.IncIndent;
    Output.AddLine('with TPxXMLItem.Create(This), ' + Name + '.Items[K] do');
    Output.AddBegin;
      Output.AddLine('This.Name := ''' + Name + ''';');
      for I := 0 to Fields.Count - 1 do
      begin
        Field := Fields[I] as TPxCGField;
        Field.CreateXmlWrite(Output);
      end;
    Output.Addend;
  Output.DecIndent;
end;

{ TPxCGStringPart }

procedure TPxCGStringPart.CreateInterface(Output: TPxCGOutput);
begin
  Output.AddLine('const');
  Output.IncIndent;
    Output.AddLine('strid' + TPxCGDataRecord(Owner).Name + Name + ' = ' + Id + ';');
  Output.DecIndent;
end;

procedure TPxCGStringPart.CreateXmlRead(Output: TPxCGOutput);
begin
  Output.AddLine('with GetItemByName(''' + Name + ''') do');
  Output.IncIndent;
    Output.AddLine(Name + ' := GetParamByNameS(''Value'');');
  Output.DecIndent;
end;

procedure TPxCGStringPart.CreateXmlWrite(Output: TPxCGOutput);
begin
  Output.AddLine('with TPxXMLItem.Create(This) do');
  Output.AddBegin;
    Output.AddLine('This.Name := ''' + Name + ''';');
    Output.AddLine('GetParamByName(''Value'').AsString := ' + Name + ';');
  Output.AddEnd;
end;

{ TPxCGFloatPart }

{ Protected declarations }

procedure TPxCGFloatPart.ReadParams;
begin
  inherited ReadParams;

  if Xml.HasParam('UnitFamily') then
    UnitFamily := Xml.GetParamByNameS('UnitFamily');
  if Xml.HasParam('UnitName') then
    UnitName := Xml.GetParamByNameS('UnitName');

  // sprawdzenie poprawnoœci danych
  if not IsValidName(UnitFamily) then
    raise EGeneratorException.Create('Invalid <(Part) UnitFamily="' + UnitFamily + '" ... />');
  if not IsValidName(UnitName) then
    raise EGeneratorException.Create('Invalid <(Part) UnitName="' + UnitName + '" ... />');
end;

{ Public declarations }

procedure TPxCGFloatPart.CreateInterface(Output: TPxCGOutput);
begin
  Output.Lines.Add('{$IFDEF VER150}');
  Output.Lines.Add('{$IFDEF DATARECORDEX_PART_FLOAT}');
  Output.AddLine('const');
  Output.IncIndent;
    Output.AddLine('fltid' + TPxCGDataRecord(Owner).Name + Name + ' = ' + Id + ';');
  Output.DecIndent;
  Output.Lines.Add('{$ENDIF}');
  Output.Lines.Add('{$ENDIF}');
end;

procedure TPxCGFloatPart.CreateXmlRead(Output: TPxCGOutput);
begin
  Output.Lines.Add('{$IFDEF VER150}');
  Output.Lines.Add('{$IFDEF DATARECORDEX_PART_FLOAT}');
  Output.AddLine('with GetItemByName(''' + Name + ''') do');
  Output.IncIndent;
    Output.AddLine(Name + '.UnitFamily := StrToUnitFamily(GetParamByNameS(''UnitFamily''));');
    Output.AddLine(Name + '.UnitType := StrToUnitType(GetParamByNameS(''UnitType''));');
    Output.AddLine(Name + '.Value := GetParamByName(''Value'').AsFloat;');
  Output.DecIndent;
  Output.Lines.Add('{$ENDIF}');
  Output.Lines.Add('{$ENDIF}');
end;

procedure TPxCGFloatPart.CreateXmlWrite(Output: TPxCGOutput);
begin
  Output.Lines.Add('{$IFDEF VER150}');
  Output.Lines.Add('{$IFDEF DATARECORDEX_PART_FLOAT}');
  Output.AddLine('with TPxXMLItem.Create(This) do');
  Output.AddBegin;
    Output.AddLine('This.Name := ''' + Name + ''';');
    Output.AddLine('GetParamByName(''UnitFamily'').AsString := UnitFamilyToStr(' + Name + '.UnitFamily);');
    Output.AddLine('GetParamByName(''UnitType'').AsString := UnitTypeToStr(' + Name + '.UnitType);');
    Output.AddLine('GetParamByName(''Value'').AsFloat := ' + Name + '.Value;');
  Output.AddEnd;
  Output.Lines.Add('{$ENDIF}');
  Output.Lines.Add('{$ENDIF}');
end;

{ TPxCGStreamPart }

procedure TPxCGStreamPart.CreateInterface(Output: TPxCGOutput);
begin
  Output.AddLine('const');
  Output.IncIndent;
    Output.AddLine('stmid' + TPxCGDataRecord(Owner).Name + Name + ' = ' + Id + ';');
  Output.DecIndent;
end;

procedure TPxCGStreamPart.CreateXmlRead(Output: TPxCGOutput);
begin
  Output.AddLine('with GetItemByName(''' + Name + ''') do');
  Output.AddBegin;
    Output.AddLine(Name + '.Size := 0;');
    Output.AddLine('GetParamByName(''Value'').RestoreStream(' + Name + ');');
    Output.AddLine(Name + '.Seek(0, soFromBeginning);');
  Output.AddEnd;
end;

procedure TPxCGStreamPart.CreateXmlWrite(Output: TPxCGOutput);
begin
  Output.AddLine('with TPxXMLItem.Create(This) do');
  Output.AddBegin;
    Output.AddLine('This.Name := ''' + Name + ''';');
    Output.AddLine(Name + '.Seek(0, soFromBeginning);');
    Output.AddLine('GetParamByName(''Value'').StoreStream(' + Name + ');');
    Output.AddLine(Name + '.Seek(0, soFromBeginning);');
  Output.AddEnd;
end;

{ TPxCGExpressionPart }

{ Protected declarations }

procedure TPxCGExpressionPart.ReadParams;
begin
  inherited ReadParams;

  if Xml.HasParam('UnitFamily') then
    UnitFamily := Xml.GetParamByNameS('UnitFamily');
  if Xml.HasParam('UnitName') then
    UnitName := Xml.GetParamByNameS('UnitName');
  if Xml.HasParam('Expression') then
    Expression := Xml.GetParamByNameS('Expression');

  // sprawdzenie poprawnoœci danych
  if not IsValidName(UnitFamily) then
    raise EGeneratorException.Create('Invalid <(Part) UnitFamily="' + UnitFamily + '" ... />');
  if not IsValidName(UnitName) then
    raise EGeneratorException.Create('Invalid <(Part) UnitName="' + UnitName + '" ... />');
end;

{ Public declarations }

procedure TPxCGExpressionPart.CreateInterface(Output: TPxCGOutput);
begin
  Output.Lines.Add('{$IFDEF VER150}');
  Output.Lines.Add('{$IFDEF DATARECORDEX_PART_EXPRESSION}');
  Output.AddLine('const');
  Output.IncIndent;
    Output.AddLine('expid' + TPxCGDataRecord(Owner).Name + Name + ' = ' + Id + ';');
  Output.DecIndent;
  Output.Lines.Add('{$ENDIF}');
  Output.Lines.Add('{$ENDIF}');
end;

procedure TPxCGExpressionPart.CreateXmlRead(Output: TPxCGOutput);
begin
  Output.Lines.Add('{$IFDEF VER150}');
  Output.Lines.Add('{$IFDEF DATARECORDEX_PART_EXPRESSION}');
  Output.AddLine('with GetItemByName(''' + Name + ''') do');
  Output.IncIndent;
    Output.AddLine(Name + '.UnitFamily := StrToUnitFamily(GetParamByNameS(''UnitFamily''));');
    Output.AddLine(Name + '.UnitType := StrToUnitType(GetParamByNameS(''UnitType''));');
    Output.AddLine(Name + '.Text := GetParamByNameS(''Value'');');
  Output.DecIndent;
  Output.Lines.Add('{$ENDIF}');
  Output.Lines.Add('{$ENDIF}');
end;

procedure TPxCGExpressionPart.CreateXmlWrite(Output: TPxCGOutput);
begin
  Output.Lines.Add('{$IFDEF VER150}');
  Output.Lines.Add('{$IFDEF DATARECORDEX_PART_EXPRESSION}');
  Output.AddLine('with TPxXMLItem.Create(This) do');
  Output.AddBegin;
    Output.AddLine('This.Name := ''' + Name + ''';');
    Output.AddLine('GetParamByName(''UnitFamily'').AsString := UnitFamilyToStr(' + Name + '.UnitFamily);');
    Output.AddLine('GetParamByName(''UnitType'').AsString := UnitTypeToStr(' + Name + '.UnitType);');
    Output.AddLine('GetParamByName(''Value'').AsString := ' + Name + '.Text;');
  Output.AddEnd;
  Output.Lines.Add('{$ENDIF}');
  Output.Lines.Add('{$ENDIF}');
end;

{ TPxCGDataContainerRecord }

{ Protected declarations }

procedure TPxCGDataContainerRecord.ReadParams;
begin
  if Xml.HasParam('Id') then
    Id := Xml.GetParamByNameS('Id');

  // sprawdzenie poprawnoœci danych
  if not IsValidNumber(Id) then
    raise EGeneratorException.Create('Invalid <(Part) ID="' + Id + '" ... />');
end;

{ TPxCGDataContainerRecordEx }

{ TPxCGDataContainer }

{ Private declarations }

function TPxCGDataContainer.HasSingles: Boolean;
var
  I: Integer;
  DataRecord: TPxCGDataRecord;
begin
  Result := False;
  for I := 0 to DataRecords.Count - 1 do
  begin
    DataRecord := DataRecords[I] as TPxCGDataRecord;
    if DataRecord.Single then
    begin
      Result := True;
      Exit;
    end;
  end;
  for I := 0 to DataRecordsEx.Count - 1 do
  begin
    DataRecord := DataRecordsEx[I] as TPxCGDataRecord;
    if DataRecord.Single then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function TPxCGDataContainer.HasLists: Boolean;
var
  I: Integer;
  DataRecord: TPxCGDataRecord;
begin
  Result := False;
  for I := 0 to DataRecords.Count - 1 do
  begin
    DataRecord := DataRecords[I] as TPxCGDataRecord;
    if not DataRecord.Single then
    begin
      Result := True;
      Exit;
    end;
  end;
  for I := 0 to DataRecordsEx.Count - 1 do
  begin
    DataRecord := DataRecordsEx[I] as TPxCGDataRecord;
    if not DataRecord.Single then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

procedure TPxCGDataContainer.ResolveRecords;
var
  I, J: Integer;
  Rec: TPxCGDataRecord;
  Tmp: TPxCGDataContainerRecord;
begin
  for I := 0 to DataRecords.Count - 1 do
  begin
    Tmp := DataRecords[I] as TPxCGDataContainerRecord;
    for J := 0 to TPxCGDataFile(Owner).DataRecords.Count - 1 do
    begin
      Rec := TPxCGDataFile(Owner).DataRecords[J] as TPxCGDataRecord;
      if Tmp.Id = Rec.Id then
      begin
        TList(DataRecords)[I] := Rec;
        Tmp.Free;
        Break;
      end;
    end;
  end;

  for I := 0 to DataRecordsEx.Count - 1 do
  begin
    Tmp := DataRecordsEx[I] as TPxCGDataContainerRecord;
    for J := 0 to TPxCGDataFile(Owner).DataRecordsEx.Count - 1 do
    begin
      Rec := TPxCGDataFile(Owner).DataRecordsEx[J] as TPxCGDataRecord;
      if Tmp.Id = Rec.Id then
      begin
        TList(DataRecordsEx)[I] := Rec;
        Tmp.Free;
        Break;
      end;
    end;
  end;
end;

procedure TPxCGDataContainer.CreateListInterface(Output: TPxCGOutput);
begin
  Output.AddLine('');
  Output.IncIndent;
    Output.AddLine(GetTypeName('', Name, 'List') + ' = class (TList)');
    Output.AddPrivate;
      Output.AddLine('function GetItem(Index: Integer): ' + GetTypeName('', Name, '') + ';');
    Output.DecIndent;
    Output.AddPublic;
      Output.AddLine('property Items[Index: Integer]: ' + GetTypeName('', Name, '') + ' read GetItem; default;');
    Output.AddEnd;
  Output.DecIndent;
end;

procedure TPxCGDataContainer.CreateListImplementation(Output: TPxCGOutput);
begin
  Output.AddLine('');
  Output.AddLine('{ ' + GetTypeName('', Name, 'List') + ' }');
  Output.AddLine('');
  Output.AddLine('{ Private declarations }');
  Output.AddLine('');
  Output.AddLine('function ' + GetTypeName('', Name, 'List') + '.GetItem(Index: Integer): ' + GetTypeName('', Name, '') + ';');
  Output.AddBegin;
    Output.AddLine('Result := TObject(Get(Index)) as ' + GetTypeName('', Name, '') + ';');
  Output.AddEnd;
end;

{ Protected declarations }

procedure TPxCGDataContainer.ReadParams;
var
  I: Integer;
begin
  if Xml.HasParam('Name') then
    Name := Xml.GetParamByNameS('Name');
  if Xml.HasParam('Id') then
    Id := Xml.GetParamByNameS('Id');

  // sprawdzenie poprawnoœci danych
  if not IsValidName(Name) then
    raise EGeneratorException.Create('Invalid <DataContainer NAME="' + Name + '" ... />');
  if not IsValidNumber(Id) then
    raise EGeneratorException.Create('Invalid <DataContainer ID="' + Id + '" ... />');

  DataRecords := CreateList('DataRecord', TPxCGDataContainerRecord);
  DataRecordsEx := CreateList('DataRecordEx', TPxCGDataContainerRecordEx);

  ResolveRecords;

  DataItems := TPxCGBaseList.Create;
  for I := 0 to DataRecords.Count - 1 do
    DataItems.Add(DataRecords[I]);
  for I := 0 to DataRecordsEx.Count - 1 do
    DataItems.Add(DataRecordsEx[I]);
end;

{ Public declarations }

destructor TPxCGDataContainer.Destroy;
begin
  if Assigned(DataItems) then
    DataItems.Clear;
  FreeAndNil(DataItems);
  FreeAndNil(DataRecords);
  FreeAndNil(DataRecordsEx);
end;

function GetListName(FieldName: String): String;
begin
  Result := FieldName;
  if UpCase(FieldName[Length(FieldName)]) = 'Y' then
  begin
    Delete(Result, Length(Result), 1);
    Result := Result + 'ie';
  end
  else if UpperCase(Copy(FieldName, Length(FieldName) - 4, 5)) = 'INDEX' then
  begin
    Delete(Result, Length(Result) - 4, 5);
    Result := Result + 'Indice';
  end;
  Result := Result + 's';
end;

procedure TPxCGDataContainer.CreateInterface(Output: TPxCGOutput);
var
  I: Integer;
  Rec: TPxCGDataRecord;
begin
  // constants
  Output.AddLine('const');
  Output.IncIndent;
    Output.AddLine('kindid' + Name + ' = ' + Id + ';');
  Output.DecIndent;
  Output.AddLine('');

  Output.AddLine('type');
  Output.IncIndent;
    Output.AddLine(GetTypeName('', Name, '') + ' = class (TPxDataContainer)');
    if HasSingles or HasLists then
    begin
      Output.AddPrivate;
      for I := 0 to DataRecords.Count - 1 do
      begin
        Rec := DataRecords[I] as TPxCGDataRecord;
        if Rec.Single then
          Output.AddLine('F' + Rec.Name + ': ' + GetTypeName('', Rec.Name, '') + ';')
        else
          Output.AddLine('F' + GetListName(Rec.Name) + ': ' + GetTypeName('', Rec.Name, 'List') + ';');
      end;
      for I := 0 to DataRecordsEx.Count - 1 do
      begin
        Rec := DataRecordsEx[I] as TPxCGDataRecord;
        if Rec.Single then
          Output.AddLine('F' + Rec.Name + ': ' + GetTypeName('', Rec.Name, '') + ';')
        else
          Output.AddLine('F' + GetListName(Rec.Name) + ': ' + GetTypeName('', Rec.Name, 'List') + ';');
      end;

      Output.DecIndent;
    end;
    Output.AddProtected;
    Output.AddLine('procedure Initialize; override;');
    if HasSingles then
      Output.AddLine('procedure CreateSingles; override;');
    if HasLists then
    begin
      Output.AddLine('procedure CreateLists; override;');
      Output.AddLine('procedure DestroyLists; override;');
    end;
    if HasSingles or HasLists then
    begin
      Output.AddLine('procedure OnAddRecord(Rec: TPxDataRecord); override;');
      Output.AddLine('procedure OnDelRecord(Rec: TPxDataRecord; RecordWillBeDisposed: Boolean); override;');
    end;
  Output.DecIndent;
  if HasSingles or HasLists then
  begin
    Output.AddPublic;
      for I := 0 to DataRecords.Count - 1 do
      begin
        Rec := DataRecords[I] as TPxCGDataRecord;
        if Rec.Single then
          Output.AddLine('property ' + Rec.Name + ': ' + GetTypeName('', Rec.Name, '') + ' read F' + Rec.Name + ';');
      end;
      for I := 0 to DataRecordsEx.Count - 1 do
      begin
        Rec := DataRecordsEx[I] as TPxCGDataRecord;
        if Rec.Single then
          Output.AddLine('property ' + Rec.Name + ': ' + GetTypeName('', Rec.Name, '') + ' read F' + Rec.Name + ';');
      end;
      for I := 0 to DataRecords.Count - 1 do
      begin
        Rec := DataRecords[I] as TPxCGDataRecord;
        if not Rec.Single then
          Output.AddLine('property ' + GetListName(Rec.Name) + ': ' + GetTypeName('', Rec.Name, 'List') + ' read F' + Rec.Name + ';');
      end;
      for I := 0 to DataRecordsEx.Count - 1 do
      begin
        Rec := DataRecordsEx[I] as TPxCGDataRecord;
        if not Rec.Single then
          Output.AddLine('property ' + GetListName(Rec.Name) + 's: ' + GetTypeName('', Rec.Name, 'List') + ' read F' + GetListName(Rec.Name) + ';');
      end;
    Output.DecIndent;
  end;

  Output.AddLine('end;');
  Output.DecIndent;

  CreateListInterface(Output);
end;

procedure TPxCGDataContainer.CreateImplementation(Output: TPxCGOutput);
var
  I: Integer;
  DataRecord: TPxCGDataRecord;
  Added: Boolean;
begin
  Output.AddLine('{ ' + GetTypeName('', Name, '') + ' }');
  Output.AddLine('');
  Output.AddLine('{ Protected declarations }');
  Output.AddLine('');

  Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.Initialize;');
  Output.AddBegin;
    Output.AddLine('inherited Initialize;');
    Output.AddLine('Header.Kind := kindid' + Name + ';');
  Output.AddEnd;

  if HasSingles then
  begin
    Output.AddLine('');
    Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.CreateSingles;');
    Output.AddBegin;
      for I := 0 to DataRecords.Count - 1 do
      begin
        DataRecord := DataRecords[I] as TPxCGDataRecord;
        if DataRecord.Single then
          Output.AddLine('AddRecord(' + GetTypeName('', DataRecord.Name, '') + '.Create(Self));');
      end;
      for I := 0 to DataRecordsEx.Count - 1 do
      begin
        DataRecord := DataRecordsEx[I] as TPxCGDataRecord;
        if DataRecord.Single then
          Output.AddLine('AddRecord(' + GetTypeName('', DataRecord.Name, '') + '.Create(Self));');
      end;
    Output.AddEnd;
  end;

  if HasLists then
  begin
    Output.AddLine('');
    Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.CreateLists;');
    Output.AddBegin;
      for I := 0 to DataRecords.Count - 1 do
      begin
        DataRecord := DataRecords[I] as TPxCGDataRecord;
        if not DataRecord.Single then
          Output.AddLine('F' + GetListName(DataRecord.Name) + ' := ' + GetTypeName('', DataRecord.Name, 'List') + '.Create;');
      end;
      for I := 0 to DataRecordsEx.Count - 1 do
      begin
        DataRecord := DataRecordsEx[I] as TPxCGDataRecord;
        if not DataRecord.Single then
          Output.AddLine('F' + GetListName(DataRecord.Name) + ' := ' + GetTypeName('', DataRecord.Name, 'List') + '.Create;');
      end;

    Output.AddEnd;
    Output.AddLine('');
    Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.DestroyLists;');
    Output.AddBegin;
      for I := 0 to DataRecords.Count - 1 do
      begin
        DataRecord := DataRecords[I] as TPxCGDataRecord;
        if not DataRecord.Single then
          Output.AddLine('F' + GetListName(DataRecord.Name) + '.Free;');
      end;
      for I := 0 to DataRecordsEx.Count - 1 do
      begin
        DataRecord := DataRecordsEx[I] as TPxCGDataRecord;
        if not DataRecord.Single then
          Output.AddLine('F' + GetListName(DataRecord.Name) + '.Free;');
      end;
    Output.AddEnd;
    Output.AddLine('');
    Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.OnAddRecord(Rec: TPxDataRecord);');
    Output.AddBegin;
      Added := False;
      for I := 0 to DataRecords.Count - 1 do
      begin
        DataRecord := DataRecords[I] as TPxCGDataRecord;
        if not Added then
        begin
          Output.AddLine('if Rec is ' + GetTypeName('', DataRecord.Name, '') + ' then');
          Added := True;
        end
        else Output.AddLine('else if Rec is ' + GetTypeName('', DataRecord.Name, '') + ' then');

        Output.IncIndent;
        if DataRecord.Single then
          Output.AddLine('F' + DataRecord.Name + ' := Rec as ' + GetTypeName('', DataRecord.Name, ''))
        else
          Output.AddLine('F' + GetListName(DataRecord.Name) + '.Add(Rec)');
        Output.DecIndent;
      end;
      for I := 0 to DataRecordsEx.Count - 1 do
      begin
        DataRecord := DataRecordsEx[I] as TPxCGDataRecord;
        if not Added then
        begin
          Output.AddLine('if Rec is ' + GetTypeName('', DataRecord.Name, '') + ' then');
          Added := True;
        end
        else Output.AddLine('else if Rec is ' + GetTypeName('', DataRecord.Name, '') + ' then');

        Output.IncIndent;
        if DataRecord.Single then
          Output.AddLine('F' + DataRecord.Name + ' := Rec as ' + GetTypeName('', DataRecord.Name, ''))
        else
          Output.AddLine('F' + GetListName(DataRecord.Name) + '.Add(Rec)');
        Output.DecIndent;
      end;
    Output.AddEnd;
    Output.AddLine('');
    Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.OnDelRecord(Rec: TPxDataRecord; RecordWillBeDisposed: Boolean);');
    Output.AddBegin;
      Added := False;
      for I := 0 to DataRecords.Count - 1 do
      begin
        DataRecord := DataRecords[I] as TPxCGDataRecord;
        if not Added then
        begin
          Output.AddLine('if Rec is ' + GetTypeName('', DataRecord.Name, '') + ' then');
          Added := True;
        end
        else Output.AddLine('else if Rec is ' + GetTypeName('', DataRecord.Name, '') + ' then');

        Output.IncIndent;
        if DataRecord.Single then
          Output.AddLine('F' + DataRecord.Name + ' := nil')
        else
          Output.AddLine('F' + GetListName(DataRecord.Name) + '.Remove(Rec)');
        Output.DecIndent;
      end;
      for I := 0 to DataRecordsEx.Count - 1 do
      begin
        DataRecord := DataRecordsEx[I] as TPxCGDataRecord;
        if not Added then
        begin
          Output.AddLine('if Rec is ' + GetTypeName('', DataRecord.Name, '') + ' then');
          Added := True;
        end
        else Output.AddLine('else if Rec is ' + GetTypeName('', DataRecord.Name, '') + ' then');

        Output.IncIndent;
        if DataRecord.Single then
          Output.AddLine('F' + DataRecord.Name + ' := nil')
        else
          Output.AddLine('F' + GetListName(DataRecord.Name) + '.Remove(Rec)');
        Output.DecIndent;
      end;
    Output.AddEnd;
  end;
  CreateListImplementation(Output);
end;

procedure TPxCGDataContainer.CreateXmlRead(Output: TPxCGOutput);
var
  I: Integer;
  DataRecord: TPxCGDataRecord;
  S: String;
begin
  S := 'if Items[I].IsItemName(''' + Name + ''')';
  if TPxCGDataFile(Owner).StricTPxXMLItemCheck then
    S := S + ' and (Items[I].GetParamByName(''Id'').AsInteger = ' + Id + ')';
  S := S + ' then';

  Output.AddLine(S);
  Output.AddBegin;
    Output.AddLine(Name + ' := ' + GetTypeName('', Name, '') + '.Create(Self);');
    Output.AddLine('AddRecord(' + Name + ');');
    Output.AddLine('with Items[I], ' + Name + ' do');
    Output.IncIndent;
      Output.AddLine('for J := 0 to ItemCount - 1 do');
      Output.AddBegin;
        for I := 0 to DataItems.Count - 1 do
        begin
          DataRecord := DataItems[I] as TPxCGDataRecord;
          DataRecord.NowInContainer := True;
          DataRecord.ContainerVariable := Name;
          DataRecord.CreateXmlRead(Output);
          DataRecord.NowInContainer := False;
        end;
      Output.AddEnd;
    Output.DecIndent;
  Output.AddEnd;
end;

procedure TPxCGDataContainer.CreateXmlWrite(Output: TPxCGOutput);
var
  I: Integer;
  DataRecord: TPxCGDataRecord;
  Added: Boolean;
begin
  Output.AddLine('with TPxXMLItem.Create(This), ' + Name + ' do');

  Output.AddBegin;
    Output.AddLine('This.Name := ''' + Name + ''';');
    if TPxCGDataFile(Owner).StricTPxXMLItemCheck then
      Output.AddLine('GetParamByName(''Id'').AsInteger := ' + Id + ';');

    Output.AddLine('for J := 0 to Records.Count - 1 do');
    Output.AddBegin;
      Added := False;
      for I := 0 to DataItems.Count - 1 do
        if DataItems[I] is TPxCGDataRecord then
        begin
          DataRecord := DataItems[I] as TPxCGDataRecord;
          if DataRecord.ContainerRecordOnly then Continue;
          if not Added then
            Output.AddLine('if Records[J] is ' + GetTypeName('', DataRecord.Name, '') + ' then')
          else
            Output.AddLine('else if Records[J] is ' + GetTypeName('', DataRecord.Name, '') + ' then');
          Added := True;

          Output.AddBegin;
            if not DataRecord.Single then
              Output.AddLine(DataRecord.Name + ' := Records[J] as ' + GetTypeName('', DataRecord.Name, '') + ';');
            DataRecord.CreateXmlWrite(Output);
          Output.AddEndNoColone;
        end;
    Output.AddEnd;
  Output.AddEnd;
end;

{ TPxCGUseUnit }

{ Protected declarations}

procedure TPxCGUseUnit.ReadParams;
begin
  if Xml.HasParam('Name') then
    Name := Xml.GetParamByNameS('Name');

  // sprawdzenie poprawnoœci danych
  if Name = '' then
    raise EGeneratorException.Create('Invalid <UseUnit NAME="' + Name + '" ... />');
end;

{ TPxCGDataFile }

{ Private declarations }

function TPxCGDataFile.HasRecordsWithArrays: Boolean;
var
  I, J: Integer;
  DataRecord: TPxCGDataRecordEx;
  Container: TPxCGDataContainer;
begin
  Result := False;
  for I := 0 to DataRecordsEx.Count - 1 do
  begin
    DataRecord := DataRecordsEx[I] as TPxCGDataRecordEx;
    if DataRecord.ArrayParts.Count > 0 then
    begin
      Result := True;
      Exit;
    end;
  end;
  for I := 0 to DataContainers.Count - 1 do
  begin
    Container := DataContainers[I] as TPxCGDataContainer;
    for J := 0 to Container.DataRecordsEx.Count - 1 do
    begin
      DataRecord := DataRecordsEx[J] as TPxCGDataRecordEx;
      if DataRecord.ArrayParts.Count > 0 then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;
end;

function TPxCGDataFile.HasRecordsWithFloats: Boolean;
var
  I, J: Integer;
  DataRecord: TPxCGDataRecordEx;
  Container: TPxCGDataContainer;
begin
  Result := False;
  for I := 0 to DataRecordsEx.Count - 1 do
  begin
    DataRecord := DataRecordsEx[I] as TPxCGDataRecordEx;
    if DataRecord.FloatParts.Count > 0 then
    begin
      Result := True;
      Exit;
    end;
  end;
  for I := 0 to DataContainers.Count - 1 do
  begin
    Container := DataContainers[I] as TPxCGDataContainer;
    for J := 0 to Container.DataRecordsEx.Count - 1 do
    begin
      DataRecord := DataRecordsEx[J] as TPxCGDataRecordEx;
      if DataRecord.FloatParts.Count > 0 then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;
end;

function TPxCGDataFile.HasRecordsWithRecordID: Boolean;
var
  I, J: Integer;
  DataRecord: TPxCGDataRecordEx;
  Container: TPxCGDataContainer;
begin
  Result := False;
  for I := 0 to DataRecordsEx.Count - 1 do
  begin
    DataRecord := DataRecordsEx[I] as TPxCGDataRecordEx;
    if DataRecord.RecordIDField <> '' then
    begin
      Result := True;
      Exit;
    end;
  end;
  for I := 0 to DataContainers.Count - 1 do
  begin
    Container := DataContainers[I] as TPxCGDataContainer;
    for J := 0 to Container.DataRecordsEx.Count - 1 do
    begin
      DataRecord := DataRecordsEx[J] as TPxCGDataRecordEx;
      if DataRecord.RecordIDField <> '' then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;
end;

function TPxCGDataFile.HasSingles: Boolean;
var
  I: Integer;
  DataRecord: TPxCGDataRecord;
begin
  Result := False;
  for I := 0 to DataRecords.Count - 1 do
  begin
    DataRecord := DataRecords[I] as TPxCGDataRecord;
    if DataRecord.Single and (not DataRecord.ContainerRecordOnly) then
    begin
      Result := True;
      Exit;
    end;
  end;
  for I := 0 to DataRecordsEx.Count - 1 do
  begin
    DataRecord := DataRecordsEx[I] as TPxCGDataRecord;
    if DataRecord.Single and (not DataRecord.ContainerRecordOnly) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function TPxCGDataFile.HasLists(IncludeContainerRecords: Boolean = False): Boolean;
var
  I: Integer;
  DataRecord: TPxCGDataRecord;
begin
  Result := False;
  for I := 0 to DataRecords.Count - 1 do
  begin
    DataRecord := DataRecords[I] as TPxCGDataRecord;
    if not DataRecord.Single and (IncludeContainerRecords or (not DataRecord.ContainerRecordOnly)) then
    begin
      Result := True;
      Exit;
    end;
  end;
  for I := 0 to DataRecordsEx.Count - 1 do
  begin
    DataRecord := DataRecordsEx[I] as TPxCGDataRecord;
    if not DataRecord.Single and (IncludeContainerRecords or (not DataRecord.ContainerRecordOnly)) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function TPxCGDataFile.HasContainers: Boolean;
begin
  Result := DataContainers.Count > 0;
end;

function TPxCGDataFile.HasContainersWithLists: Boolean;
var
  I, J: Integer;
  Container: TPxCGDataContainer;
  DataRecord: TPxCGDataRecord;
begin
  Result := False;
  for I := 0 to DataContainers.Count - 1 do
  begin
    Container := DataContainers[I] as TPxCGDataContainer;

    for J := 0 to Container.DataRecords.Count - 1 do
    begin
      DataRecord := Container.DataRecords[I] as TPxCGDataRecord;
      if not DataRecord.Single then
      begin
        Result := True;
        Exit;
      end;
    end;

    for J := 0 to Container.DataRecordsEx.Count - 1 do
    begin
      DataRecord := Container.DataRecordsEx[I] as TPxCGDataRecord;
      if not DataRecord.Single then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;
end;

function TPxCGDataFile.HasExpressionParts: Boolean;
var
  I, J: Integer;
  Container: TPxCGDataContainer;
  DataRecord: TPxCGDataRecordEx;
begin
  Result := False;
  for I := 0 to DataRecordsEx.Count - 1 do
  begin
    DataRecord := DataRecordsEx[I] as TPxCGDataRecordEx;
    if DataRecord.ExpressionParts.Count > 0 then
    begin
      Result := True;
      Exit;
    end;
  end;
  for J := 0 to DataContainers.Count - 1 do
  begin
    Container := DataContainers[J] as TPxCGDataContainer;
    for I := 0 to Container.DataRecordsEx.Count - 1 do
    begin
      DataRecord := Container.DataRecordsEx[I] as TPxCGDataRecordEx;
      if DataRecord.ExpressionParts.Count > 0 then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;
end;

procedure TPxCGDataFile.CreateGetDataByName(Output: TPxCGOutput);
var
  FirstRecord: Boolean;

  function FieldHasValue(Field: TPxCGField): Boolean;
  begin
    Result :=
       (AnsiCompareText(Field.FieldType, 'Integer') = 0) or
       (AnsiCompareText(Field.FieldType, 'Word') = 0) or
       (AnsiCompareText(Field.FieldType, 'Byte') = 0) or
       (AnsiCompareText(Field.FieldType, 'Smallint') = 0) or
       (AnsiCompareText(Field.FieldType, 'LongWord') = 0) or
       (AnsiCompareText(Field.FieldType, 'DWORD') = 0) or
       (AnsiCompareText(Field.FieldType, 'Single') = 0) or
       (AnsiCompareText(Field.FieldType, 'Double') = 0) or
       (AnsiCompareText(Field.FieldType, 'Extended') = 0);
  end;

  function FieldListHasValueFields(Fields: TPxCGBaseList): Boolean;
  var
    I: Integer;
    Field: TPxCGField;
  begin
    Result := False;
    for I := 0 to Fields.Count - 1 do
    begin
      Field := Fields[I] as  TPxCGField;
      if FieldHasValue(Field) then
      begin
        Result := True;
        Break;
      end;
    end;
  end;

  function DataRecordExHasValueFields(DataRecordEx: TPxCGDataRecordEx): Boolean;
  var
    I: Integer;
    DataPart: TPxCGDataPart;
  begin
    Result := (DataRecordEx.ExpressionParts.Count > 0) or (DataRecordEx.StringParts.Count > 0);
    if Result then Exit;
    for I := 0 to DataRecordEx.DataParts.Count - 1 do
    begin
      DataPart := DataRecordEx.DataParts[I] as TPxCGDataPart;
      if FieldListHasValueFields(DataPart.Fields) then
      begin
        Result := True;
        Break;
      end;
    end;
  end;

  function AddElseAfterStringsParts(DataRecordEx: TPxCGDataRecordEx): Boolean;
  var
    I: Integer;
    DataPart: TPxCGDataPart;
  begin
    Result := DataRecordEx.ExpressionParts.Count > 0;
    if Result then Exit;
    for I := 0 to DataRecordEx.DataParts.Count - 1 do
    begin
      DataPart := DataRecordEx.DataParts[I] as TPxCGDataPart;
      if FieldListHasValueFields(DataPart.Fields) then
      begin
        Result := True;
        Break;
      end;
    end;
  end;

  function AddElseAfterArrayParts(DataRecordEx: TPxCGDataRecordEx): Boolean;
  var
    I: Integer;
    ArrayPart: TPxCGArrayPart;
  begin
    Result := False;
    for I := 0 to DataRecordEx.ArrayParts.Count - 1 do
    begin
      ArrayPart := DataRecordEx.ArrayParts[I] as TPxCGArrayPart;
      if FieldListHasValueFields(ArrayPart.Fields) then
      begin
        Result := True;
        Break;
      end;
    end;
  end;

  function AddElseAfterExpressionParts(DataRecordEx: TPxCGDataRecordEx): Boolean;
  var
    I: Integer;
    DataPart: TPxCGDataPart;
  begin
    Result := False;
    for I := 0 to DataRecordEx.DataParts.Count - 1 do
    begin
      DataPart := DataRecordEx.DataParts[I] as TPxCGDataPart;
      if FieldListHasValueFields(DataPart.Fields) then
      begin
        Result := True;
        Break;
      end;
    end;
  end;

  function DataContainerHasValueFields(DataContainer: TPxCGDataContainer): Boolean;
  var
    I: Integer;
    DataRecord: TPxCGDataRecord;
    DataRecordEx: TPxCGDataRecordEx;
  begin
    Result := False;
    for I := 0 to DataContainer.DataRecords.Count - 1 do
    begin
      DataRecord := DataContainer.DataRecords[I] as TPxCGDataRecord;
      if FieldListHasValueFields(DataRecord.Fields) then
      begin
        Result := True;
        Break;
      end;
    end;
    for I := 0 to DataContainer.DataRecordsEx.Count - 1 do
    begin
      DataRecordEx := DataContainer.DataRecordsEx[I] as TPxCGDataRecordEx;
      Result := DataRecordExHasValueFields(DataRecordEx);
      if Result then Exit;
    end;
  end;

  procedure AddElseExceptionNotFound;
  var
    S: String;
  begin
    S := 'raise Exception.Create(''Unknown element'');';
    if not FirstRecord then
      S := 'else ' + S;
    Output.AddLine(S);
  end;

  procedure CreateForRecords(Prefix: String; DataRecords: TPxCGBaseList; DataRecordsEx: TPxCGBaseList; AcceptContainers: Boolean);
  var
    I, J, K: Integer;
    DataRecord: TPxCGDataRecord;
    DataRecordEx: TPxCGDataRecordEx;
    DataPart: TPxCGDataPart;
    ExpressionPart: TPxCGExpressionPart;
    StringPart: TPxCGStringPart;
    Field: TPxCGField;
    S: String;
    FirstField: Boolean;
  begin
    for I := 0 to DataRecords.Count - 1 do
    begin
      DataRecord := DataRecords[I] as TPxCGDataRecord;
      if (not AcceptContainers) and DataRecord.ContainerRecordOnly then Continue;
      if not FieldListHasValueFields(DataRecord.Fields) then Continue;

      S := 'if AnsiCompareText(Copy(Name, 1, ' + IntToStr(Length(DataRecord.Name)) + '), ''' + DataRecord.Name + ''') = 0 then';
      if not FirstRecord then
        S := 'else ' + S;
      FirstRecord := False;

      Output.AddLine(S);
      Output.AddBegin;
        Output.AddLine('Delete(Name, 1, ' + IntToStr(Length(DataRecord.Name)) + ');');
        if DataRecord.Single then
        begin
          Output.AddLine('if Name[1] <> ''.'' then');
          Output.IncIndent;
            Output.AddLine('raise Exception.Create(''Syntax error: dot expected'');');
          Output.DecIndent;
          FirstField := True;
          for J := 0 to DataRecord.Fields.Count - 1 do
          begin
            Field := DataRecord.Fields[J] as TPxCGField;
            if FieldHasValue(Field) then
            begin
              S := 'if AnsiCompareText(Name, ''' + Field.FieldName + ''') = 0 then';
              if not FirstField then
                S := 'else ' + S;
              FirstField := False;
              Output.AddLine(S);
              Output.IncIndent;
                Output.AddLine('Result := ' + Prefix + DataRecord.Name + '.D.' + Field.FieldName);
              Output.DecIndent;
            end;
          end;
          S := 'raise Exception.Create(''Field not found'');';
          if not FirstField then
            S := 'else ' + S;
          Output.AddLine(S);
        end
        else
        begin
          Output.AddLine('if Name[1] = ''['' then');
          Output.AddBegin;
            Output.AddLine('P := Pos('']'', Name);');
            Output.AddLine('if P = 0 then');
            Output.IncIndent;
              Output.AddLine('raise Exception.Create(''Syntax error: "]" expected'');');
            Output.DecIndent;
            Output.AddLine('Index := StrToInt(Copy(Name, 2, P - 2));');
            Output.AddLine('Delete(Name, 1, P);');
            Output.AddLine('if Name[1] <> ''.'' then');
            Output.IncIndent;
              Output.AddLine('raise Exception.Create(''Syntax error: dot expected'');');
            Output.DecIndent;
            Output.AddLine('Delete(Name, 1, 1);');
            FirstField := True;
            for J := 0 to DataRecord.Fields.Count - 1 do
            begin
              Field := DataRecord.Fields[J] as TPxCGField;
              if FieldHasValue(Field) then
              begin
                S := 'if AnsiCompareText(Name, ''' + Field.FieldName + ''') = 0 then';
                if not FirstField then
                  S := 'else ' + S;
                FirstField := False;
                Output.AddLine(S);
                Output.IncIndent;
                  Output.AddLine('Result := ' + Prefix + GetListName(DataRecord.Name) + '[Index].D.' + Field.FieldName);
                Output.DecIndent;
              end;
            end;
            S := 'raise Exception.Create(''Field not found'');';
            if not FirstField then
              S := 'else ' + S;
            Output.AddLine(S);
          Output.AddEndNoColone;
          Output.AddLine('else if (Name[1] = ''.'') and (AnsiCompareText(Name, ''.Count'') = 0) then');
          Output.IncIndent;
            Output.AddLine('Result := ' + Prefix + GetListName(DataRecord.Name) + '.Count');
          Output.DecIndent;
          Output.AddLine('else raise Exception.Create(''Unknown field'');');
        end;
      Output.AddEndNoColone;
    end;

    for I := 0 to DataRecordsEx.Count - 1 do
    begin
      DataRecordEx := DataRecordsEx[I] as TPxCGDataRecordEx;
      if (not AcceptContainers) and DataRecordEx.ContainerRecordOnly then Continue;
      if not DataRecordExHasValueFields(DataRecordEx) then Continue;

      S := 'if AnsiCompareText(Copy(Name, 1, ' + IntToStr(Length(DataRecordEx.Name)) + '), ''' + DataRecordEx.Name + ''') = 0 then';
      if not FirstRecord then
        S := 'else ' + S;
      FirstRecord := False;

      Output.AddLine(S);
      Output.AddBegin;
        Output.AddLine('Delete(Name, 1, ' + IntToStr(Length(DataRecordEx.Name)) + ');');
        if DataRecordEx.Single then
        begin
          Output.AddLine('if Name[1] <> ''.'' then');
          Output.IncIndent;
            Output.AddLine('raise Exception.Create(''Syntax error: dot expected'');');
          Output.DecIndent;
          FirstField := True;
          for J := 0 to DataRecordEx.DataParts.Count - 1 do
          begin
            DataPart := DataRecordEx.DataParts[J] as TPxCGDataPart;
            for K := 0 to DataPart.Fields.Count - 1 do
            begin
              Field := DataPart.Fields[K] as TPxCGField;
              if FieldHasValue(Field) then
              begin
                S := 'if AnsiCompareText(Name, ''' + Field.FieldName + ''') = 0 then';
                if not FirstField then
                  S := 'else ' + S;
                FirstField := False;
                Output.AddLine(S);
                Output.IncIndent;
                  Output.AddLine('Result := ' + Prefix + DataRecordEx.Name + '.' + Field.FieldName);
                Output.DecIndent;
              end;
            end;
          end;
          for J := 0 to DataRecordEx.StringParts.Count - 1 do
          begin
            StringPart := DataRecordEx.StringParts[J] as TPxCGStringPart;
            S := 'if AnsiCompareText(Name, ''' + StringPart.Name + ''') = 0 then';
            if not FirstField then
              S := 'else ' + S;
            FirstField := False;
            Output.AddLine(S);
            Output.IncIndent;
              Output.AddLine('Result := ' + Prefix + DataRecordEx.Name + '.' + StringPart.Name);
            Output.DecIndent;
          end;
          S := 'raise Exception.Create(''Field not found'');';
          if not FirstField then
            S := 'else ' + S;
          Output.AddLine(S);
        end
        else
        begin
          Output.AddLine('if Name[1] = ''['' then');
          Output.AddBegin;
            Output.AddLine('P := Pos('']'', Name);');
            Output.AddLine('if P = 0 then');
            Output.IncIndent;
              Output.AddLine('raise Exception.Create(''Syntax error: "]" expected'');');
            Output.DecIndent;
            Output.AddLine('Index := StrToInt(Copy(Name, 2, P - 2));');
            Output.AddLine('Delete(Name, 1, P);');
            Output.AddLine('if Name[1] <> ''.'' then');
            Output.IncIndent;
              Output.AddLine('raise Exception.Create(''Syntax error: dot expected'');');
            Output.DecIndent;
            Output.AddLine('Delete(Name, 1, 1);');
            FirstField := True;
            if DataRecordEx.ExpressionParts.Count > 0 then
            begin
              Output.Lines.Add('{$IFDEF VER150}');
              Output.Lines.Add('{$IFDEF DATARECORDEX_PART_EXPRESSION}');
              for J := 0 to DataRecordEx.ExpressionParts.Count - 1 do
              begin
                ExpressionPart := DataRecordEx.ExpressionParts[J] as TPxCGExpressionPart;
                S := 'if AnsiCompareText(Name, ''' + ExpressionPart.Name + ''') = 0 then';
                if not FirstField then
                  S := 'else ' + S;
                FirstField := False;
                Output.AddLine(S);
                Output.IncIndent;
                  S := 'Result := ' + Prefix + GetListName(DataRecordEx.Name) + '[Index].' + ExpressionPart.Name + '.Value';
                  Output.AddLine(S);
                Output.DecIndent;
              end;
              Output.AddLine('else');
              Output.Lines.Add('{$ENDIF}');
              Output.Lines.Add('{$ENDIF}');
            end;
            FirstField := True;
            if DataRecordEx.StringParts.Count > 0 then
            begin
              for J := 0 to DataRecordEx.StringParts.Count - 1 do
              begin
                StringPart := DataRecordEx.StringParts[J] as TPxCGStringPart;
                S := 'if AnsiCompareText(Name, ''' + StringPart.Name + ''') = 0 then';
                if not FirstField then
                  S := 'else ' + S;
                FirstField := False;
                Output.AddLine(S);
                Output.IncIndent;
                  S := 'Result := ' + Prefix + GetListName(DataRecordEx.Name) + '[Index].' + StringPart.Name;
                  Output.AddLine(S);
                Output.DecIndent;
              end;
//              Output.AddLine('else');
            end;
            for J := 0 to DataRecordEx.DataParts.Count - 1 do
            begin
              DataPart := DataRecordEx.DataParts[J] as TPxCGDataPart;
              for K := 0 to DataPart.Fields.Count - 1 do
              begin
                Field := DataPart.Fields[K] as TPxCGField;
                if FieldHasValue(Field) then
                begin
                  S := 'if AnsiCompareText(Name, ''' + Field.FieldName + ''') = 0 then';
                  if not FirstField then
                    S := 'else ' + S;
                  FirstField := False;
                  Output.AddLine(S);
                  Output.IncIndent;
                    Output.AddLine('Result := ' + Prefix + GetListName(DataRecordEx.Name) + '[Index].' + Field.FieldName);
                  Output.DecIndent;
                end;
              end;
            end;
            S := 'raise Exception.Create(''Field not found'');';
            if not FirstField then
              S := 'else ' + S;
            Output.AddLine(S);
          Output.AddEndNoColone;
          Output.AddLine('else if (Name[1] = ''.'') and (AnsiCompareText(Name, ''.Count'') = 0) then');
          Output.IncIndent;
            Output.AddLine('Result := ' + Prefix + GetListName(DataRecordEx.Name) + '.Count');
          Output.DecIndent;
          Output.AddLine('else raise Exception.Create(''Unknown field'');');
        end;
      Output.AddEndNoColone;
    end;
    if AcceptContainers then
      AddElseExceptionNotFound;
  end;

  procedure CreateForContainers;
  var
    I: Integer;
    DataContainer: TPxCGDataContainer;
    S: String;
  begin
    for I := 0 to DataContainers.Count - 1 do
    begin
      DataContainer := DataContainers[I] as TPxCGDataContainer;
      if not DataContainerHasValueFields(DataContainer) then Continue;

      S := 'if AnsiCompareText(Copy(Name, 1, ' + IntToStr(Length(DataContainer.Name)) + '), ''' + DataContainer.Name + ''') = 0 then';
      if not FirstRecord then
        S := 'else ' + S;
      Output.AddLine(S);
      FirstRecord := True;

      Output.AddBegin;
        Output.AddLine('Delete(Name, 1, ' + IntToStr(Length(DataContainer.Name)) + ');');
        Output.AddLine('if Name[1] = ''['' then');
        Output.AddBegin;
          Output.AddLine('P := Pos('']'', Name);');
          Output.AddLine('if P = 0 then');
          Output.IncIndent;
            Output.AddLine('raise Exception.Create(''Syntax error: "]" expected'');');
          Output.DecIndent;
          Output.AddLine('Index2 := StrToInt(Copy(Name, 2, P - 2));');
          Output.AddLine('Delete(Name, 1, P);');
          Output.AddLine('if Name[1] <> ''.'' then');
          Output.IncIndent;
            Output.AddLine('raise Exception.Create(''Syntax error: dot expected'');');
          Output.DecIndent;
          Output.AddLine('Delete(Name, 1, 1);');
          CreateForRecords(GetListName(DataContainer.Name) + '[Index2].', DataContainer.DataRecords, DataContainer.DataRecordsEx, True);
        Output.AddEnd;
      Output.AddEndNoColone;
    end;
    AddElseExceptionNotFound;
  end;

//
// --- New implemenetation ---
//

  function IsAcceptableType(TypeName: String): Boolean;
  begin
    Result :=
       (AnsiCompareText(TypeName, 'WideString') = 0) or
       (AnsiCompareText(TypeName, 'String') = 0) or
       (AnsiCompareText(TypeName, 'Variant') = 0) or
       (AnsiCompareText(TypeName, 'TIdentifier') = 0) or
       (AnsiCompareText(TypeName, 'Cardinal') = 0) or
       (AnsiCompareText(TypeName, 'Integer') = 0) or
       (AnsiCompareText(TypeName, 'Word') = 0) or
       (AnsiCompareText(TypeName, 'Byte') = 0) or
       (AnsiCompareText(TypeName, 'Smallint') = 0) or
       (AnsiCompareText(TypeName, 'LongWord') = 0) or
       (AnsiCompareText(TypeName, 'DWORD') = 0) or
       (AnsiCompareText(TypeName, 'Single') = 0) or
       (AnsiCompareText(TypeName, 'Double') = 0) or
       (AnsiCompareText(TypeName, 'Extended') = 0);
  end;

  function HasAcceptableFields(DataRecord: TPxCGDataRecord): Boolean; overload;
  var
    I: Integer;
    Field: TPxCGField;
    RuntimeField: TPxCGRuntimeField;
  begin
    Result := False;
    for I := 0 to DataRecord.Fields.Count - 1 do
    begin
      Field := DataRecord.Fields[I] as TPxCGField;
      if IsAcceptableType(Field.FieldType) then
      begin
        Result := True;
        Exit;
      end;
    end;
    for I := 0 to DataRecord.RuntimeFields.Count - 1 do
    begin
      RuntimeField := DataRecord.RuntimeFields[I] as TPxCGRuntimeField;
      if IsAcceptableType(RuntimeField.FieldType) then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;

  procedure CreateFieldList(DataRecord: TPxCGDataRecord; Fields: TStrings); overload;
  var
    I: Integer;
    Field: TPxCGField;
    RuntimeField: TPxCGRuntimeField;
  begin
    for I := 0 to DataRecord.Fields.Count - 1 do
    begin
      Field := DataRecord.Fields[I] as TPxCGField;
      if IsAcceptableType(Field.FieldType) then
        Fields.Add(Field.FieldName);
    end;
    for I := 0 to DataRecord.RuntimeFields.Count - 1 do
    begin
      RuntimeField := DataRecord.RuntimeFields[I] as TPxCGRuntimeField;
      if IsAcceptableType(RuntimeField.FieldType) then
        Fields.Add(RuntimeField.FieldName);
    end;
  end;

  function HasAcceptableFields(DataRecord: TPxCGDataRecordEx): Boolean; overload;
  var
    I, J: Integer;
    DataPart: TPxCGDataPart;
    ArrayPart: TPxCGArrayPart;
    Field: TPxCGField;
    RuntimeField: TPxCGRuntimeField;
  begin
    // Runtime fields
    for I := 0 to DataRecord.RuntimeFields.Count - 1 do
    begin
      RuntimeField := DataRecord.RuntimeFields[I] as TPxCGRuntimeField;
      if IsAcceptableType(RuntimeField.FieldType) then
      begin
        Result := True;
        Exit;
      end;
    end;
    // DataPart
    for I := 0 to DataRecord.DataParts.Count - 1 do
    begin
      DataPart := DataRecord.DataParts[I] as TPxCGDataPart;
      for J := 0 to DataPart.Fields.Count - 1 do
      begin
        Field := DataPart.Fields[J] as TPxCGField;
        if IsAcceptableType(Field.FieldType) then
        begin
          Result := True;
          Exit;
        end;
      end;
    end;
    // ArrayPart
    for I := 0 to DataRecord.ArrayParts.Count - 1 do
    begin
      ArrayPart := DataRecord.ArrayParts[I] as TPxCGArrayPart;
      for J := 0 to ArrayPart.Fields.Count - 1 do
      begin
        Field := ArrayPart.Fields[J] as TPxCGField;
        if IsAcceptableType(Field.FieldType) then
        begin
          Result := True;
          Exit;
        end;
      end;
    end;
    // StringPart, ExpressionPart, StreamPart
    Result := (DataRecord.StringParts.Count > 0) or (DataRecord.ExpressionParts.Count > 0) or (DataRecord.StreamParts.Count > 0);
  end;

  procedure CreateFieldList(DataRecord: TPxCGDataRecordEx; Fields: TStrings); overload;
  var
    I, J: Integer;
    DataPart: TPxCGDataPart;
    ArrayPart: TPxCGArrayPart;
    ExpressionPart: TPxCGExpressionPart;
    StringPart: TPxCGStringPart;
    StreamPart: TPxCGStreamPart;
    Field: TPxCGField;
    RuntimeField: TPxCGRuntimeField;
  begin
    // Runtime fields
    for I := 0 to DataRecord.RuntimeFields.Count - 1 do
    begin
      RuntimeField := DataRecord.RuntimeFields[I] as TPxCGRuntimeField;
      if IsAcceptableType(RuntimeField.FieldType) then
        Fields.Add(RuntimeField.FieldName);
    end;
    // DataPart
    for I := 0 to DataRecord.DataParts.Count - 1 do
    begin
      DataPart := DataRecord.DataParts[I] as TPxCGDataPart;
      for J := 0 to DataPart.Fields.Count - 1 do
      begin
        Field := DataPart.Fields[J] as TPxCGField;
        if IsAcceptableType(Field.FieldType) then
          Fields.AddObject(Field.FieldName, Pointer(0));
      end;
    end;
    // ArrayPart
    for I := 0 to DataRecord.ArrayParts.Count - 1 do
    begin
      ArrayPart := DataRecord.ArrayParts[I] as TPxCGArrayPart;
      for J := 0 to ArrayPart.Fields.Count - 1 do
      begin
        Field := ArrayPart.Fields[J] as TPxCGField;
        if IsAcceptableType(Field.FieldType) then
        begin
          Fields.AddObject(ArrayPart.Name, ArrayPart);
          Break;
        end;
      end;
    end;
    // StringPart
    for I := 0 to DataRecord.StringParts.Count - 1 do
    begin
      StringPart := DataRecord.StringParts[I] as TPxCGStringPart;
      Fields.AddObject(StringPart.Name, Pointer(2));
    end;
    // ExpressionPart
    for I := 0 to DataRecord.ExpressionParts.Count - 1 do
    begin
      ExpressionPart := DataRecord.ExpressionParts[I] as TPxCGExpressionPart;
      Fields.AddObject(ExpressionPart.Name, Pointer(3));
    end;
    // StreamPart
    for I := 0 to DataRecord.StreamParts.Count - 1 do
    begin
      StreamPart := DataRecord.StreamParts[I] as TPxCGStreamPart;
      Fields.AddObject(StreamPart.Name, Pointer(4));
    end;
  end;

  function HasAcceptableRecords(Container: TPxCGDataContainer): Boolean; overload;
  var
    I: Integer;
  begin
    Result := False;
    for I := 0 to DataRecords.Count - 1 do
      if HasAcceptableFields(DataRecords[I] as TPxCGDataRecord) then
      begin
        Result := True;
        Exit;
      end;
    for I := 0 to DataRecordsEx.Count - 1 do
      if HasAcceptableFields(DataRecordsEx[I] as TPxCGDataRecordEx) then
      begin
        Result := True;
        Exit;
      end;
  end;

  function HasAcceptableRecords(DataFile: TPxCGDataFile): Boolean; overload;
  var
    I: Integer;
  begin
    Result := False;
    for I := 0 to DataRecords.Count - 1 do
      if HasAcceptableFields(DataRecords[I] as TPxCGDataRecord) then
      begin
        Result := True;
        Exit;
      end;
    for I := 0 to DataRecordsEx.Count - 1 do
      if HasAcceptableFields(DataRecordsEx[I] as TPxCGDataRecordEx) then
      begin
        Result := True;
        Exit;
      end;
    for I := 0 to DataContainers.Count - 1 do
      if HasAcceptableRecords(DataContainers[I] as TPxCGDataContainer) then
      begin
        Result := True;
        Exit;
      end;
  end;

  procedure CreateRecord(DataRecord: TPxCGDataRecord; DataContainer: TPxCGDataContainer = nil); overload;
  var
    I: Integer;
    S: String;
    Fields: TStrings;
  begin
    Fields := TStringList.Create;
    CreateFieldList(DataRecord, Fields);
    S := 'if AnsiCompareText(Copy(Name, 1, ' + IntToStr(Length(DataRecord.Name)) + '), ''' + DataRecord.Name + ''') = 0 then';
    if not FirstRecord then
      S := 'else ' + S;
    FirstRecord := False;
    Output.AddLine(S);
    Output.AddBegin;
      if DataRecord.Single then
      begin
        Output.AddLine('Delete(Name, 1, ' + IntToStr(Length(DataRecord.Name)) + ');');
        Output.AddLine('if Name[1] <> ''.'' then');
        Output.IncIndent;
          Output.AddLine('raise Exception.Create(''Syntax error: dot expected'');');
        Output.DecIndent;
        for I := 0 to Fields.Count - 1 do
        begin
          S := 'if AnsiCompareText(Copy(Name, 1, ' + IntToStr(Length(Fields[I])) + '), ' + Fields[I] + ') = 0 then';
          if I > 0 then
            S := 'else ' + S;
          Output.AddLine(S);
          if Assigned(DataContainer) then
            Output.AddLine('Result := ' + DataContainer.Name + '[Index2].' + DataRecord.Name + '.D.' + Fields[I])
          else
            Output.AddLine('Result := ' + DataRecord.Name + '.D.' + Fields[I])
        end;
        AddElseExceptionNotFound;
      end
      else
      begin
        Output.AddLine('Delete(Name, 1, ' + IntToStr(Length(DataRecord.Name)) + ');');
        Output.AddLine('if Name[1] <> ''['' then');
        Output.IncIndent;
           Output.AddLine('raise Exception.Create(''Error: "[" expected'')');
        Output.DecIndent;
        Output.AddLine('else');
        Output.AddBegin;
          Output.AddLine('P := Pos('']'', Name);');
          Output.AddLine('if P = 0 then');
          Output.IncIndent;
            Output.AddLine('raise Exception.Create(''Syntax error: "]" expected'');');
          Output.DecIndent;
          Output.AddLine('Index := StrToInt(Copy(Name, 2, P - 2));');
          Output.AddLine('Delete(Name, 1, P);');
          Output.AddLine('if Name[1] <> ''.'' then');
          Output.IncIndent;
            Output.AddLine('raise Exception.Create(''Syntax error: dot expected'');');
          Output.DecIndent;
          Output.AddLine('Delete(Name, 1, 1);');

          for I := 0 to Fields.Count - 1 do
          begin
            S := 'if AnsiCompareText(Copy(Name, 1, ' + IntToStr(Length(Fields[I])) + '), ''' + Fields[I] + ''') = 0 then';
            if I > 0 then
              S := 'else ' + S;
            Output.AddLine(S);
            Output.IncIndent;
              if Assigned(DataContainer) then
                Output.AddLine('Result := ' + DataContainer.Name + '[Index2].' + GetListName(DataRecord.Name) + '[Index].D.' + Fields[I])
              else
                Output.AddLine('Result := ' + GetListName(DataRecord.Name) + '[Index].D.' + Fields[I]);
            Output.DecIndent;
          end;
        AddElseExceptionNotFound;
        Output.AddEndNoColone;
      end;
    Output.AddEndNoColone;
    Fields.Free;
  end;

  procedure CreateRecord(DataRecord: TPxCGDataRecordEx; DataContainer: TPxCGDataContainer = nil); overload;
  var
    I: Integer;
    S: String;
    Fields: TStrings;
//    ArrayPart: TPxCGArrayPart;
  begin
    Fields := TStringList.Create;
    CreateFieldList(DataRecord, Fields);

    S := 'if AnsiCompareText(Copy(Name, 1, ' + IntToStr(Length(DataRecord.Name)) + '), ''' + DataRecord.Name + ''') = 0 then';
    if not FirstRecord then
      S := 'else ' + S;
    FirstRecord := False;
    Output.AddLine(S);
    Output.AddBegin;

      if DataRecord.Single then
      begin
        Output.AddLine('Delete(Name, 1, ' + IntToStr(Length(DataRecord.Name) + 1) + ');');
        for I := 0 to Fields.Count - 1 do
        begin
          S := 'if AnsiCompareText(Copy(Name, 1, ' + IntToStr(Length(Fields[I])) + '), ''' + Fields[I] + ''') = 0 then';
          if I > 0 then
            S := 'else ' + S;
          Output.AddLine(S);
          Output.IncIndent;
            if Assigned(DataContainer) then
              S := 'Result := ' + DataContainer.Name + '[Index2].'
            else
              S := 'Result := ';

            //
            // different types of fields
            //
            case Integer(Fields.Objects[I]) of
              0: Output.AddLine(S + DataRecord.Name + '.' + Fields[I]);
              1: // Array parts
              begin
//                ArrayPart := Fields.Objects[I] as TPxCGArrayPart;
                Output.AddBegin;
                Output.AddLine('if AnsiCompareText(Name, 1, 5) = ''.Count'' then');
                Output.IncIndent;
                  Output.AddLine(S + DataRecord.Name + '.' + Fields[I] + 'Count');
                Output.DecIndent;

              end;
              2: Output.AddLine(S + DataRecord.Name + '.' + Fields[I]);
              3: Output.AddLine(S + DataRecord.Name + '.' + Fields[I] + '.Value');
            end;
          Output.DecIndent;
        end;
        AddElseExceptionNotFound;
      end
      else
      begin
        Output.AddLine('Delete(Name, 1, ' + IntToStr(Length(DataRecord.Name)) + ');');
        Output.AddLine('if Name[1] <> ''['' then');
        Output.IncIndent;
           Output.AddLine('raise Exception.Create(''Error: "[" expected'')');
        Output.DecIndent;
        Output.AddLine('else');
        Output.AddBegin;
          Output.AddLine('P := Pos('']'', Name);');
          Output.AddLine('if P = 0 then');
          Output.IncIndent;
            Output.AddLine('raise Exception.Create(''Syntax error: "]" expected'');');
          Output.DecIndent;
          Output.AddLine('Index := StrToInt(Copy(Name, 2, P - 2));');
          Output.AddLine('Delete(Name, 1, P);');
          Output.AddLine('if Name[1] <> ''.'' then');
          Output.IncIndent;
            Output.AddLine('raise Exception.Create(''Syntax error: dot expected'');');
          Output.DecIndent;
          Output.AddLine('Delete(Name, 1, 1);');

          for I := 0 to Fields.Count - 1 do
          begin
            S := 'if AnsiCompareText(Copy(Name, 1, ' + IntToStr(Length(Fields[I])) + '), ''' + Fields[I] + ''') = 0 then';
            if I > 0 then
              S := 'else ' + S;
            Output.AddLine(S);
            Output.IncIndent;
            if Assigned(DataContainer) then
              S := 'Result := ' + DataContainer.Name + '[Index2].'
            else
              S := 'Result := ';

            //
            // different types of fields
            //
            case Integer(Fields.Objects[I]) of
              0,
              2: Output.AddLine(S + GetListName(DataRecord.Name) + '[Index].' + Fields[I]);
              3: Output.AddLine(S + GetListName(DataRecord.Name) + '[Index].' + Fields[I] + '.Value');
            end;
            Output.DecIndent;
          end;
        AddElseExceptionNotFound;
        Output.AddEndNoColone;
      end;

    Output.AddEndNoColone;
    Fields.Free;
  end;

var
  I: Integer;

begin
  FirstRecord := True;

  Output.AddLine('');
  Output.AddLine('function ' + GetTypeName('', Name, '') + '.GetData(Name: String): Variant;');
  Output.AddLine('var');
  Output.IncIndent;
    Output.AddLine('P: Integer;');
    if HasContainers then
      Output.AddLine('Index2: Integer;');
    if (DataRecords.Count > 0) or (DataRecordsEx.Count > 0) then
      Output.AddLine('Index: Integer;');
  Output.DecIndent;
  Output.AddBegin;

  for I := 0 to DataRecords.Count - 1 do
    CreateRecord(DataRecords[I] as TPxCGDataRecord);
  for I := 0 to DataRecordsEx.Count - 1 do
    CreateRecord(DataRecordsEx[I] as TPxCGDataRecordEx);
  AddElseExceptionNotFound;
  Output.AddEnd;
end;

{ Protected declarations }

procedure TPxCGDataFile.ReadParams;
var
  I: Integer;
begin
  if Xml.HasParam('Name') then
    Name := Xml.GetParamByNameS('Name');
  if Xml.HasParam('OutputDir') then
    OutputDir := IncludeTrailingPathDelimiter(Xml.GetParamByNameS('OutputDir'));
  if Xml.HasParam('Signature') then
    Signature := Xml.GetParamByNameS('Signature');
  if Xml.HasParam('Version') then
    Version := Xml.GetParamByNameS('Version');
  if Xml.HasParam('ParentClass') then
    ParentClass := Xml.GetParamByNameS('ParentClass');
  // Xml
  if Xml.HasParam('XmlMethods') then
    GenerateXmlMethods := Xml.GetParamByName('XmlMethods').AsBoolean;
  if Xml.HasParam('StricTPxXMLItemCheck') then
    StricTPxXMLItemCheck := Xml.GetParamByName('StricTPxXMLItemCheck').AsBoolean;
  if Xml.HasParam('ResolveXmlIncludes') then
    ResolveXmlIncludes := Xml.GetParamByName('ResolveXmlIncludes').AsBoolean
  else
    ResolveXmlIncludes := True; // by default, do resolve xml includes

  if Xml.HasParam('DataByNameMethod') then
    GetDataByNameMethod := Xml.GetParamByName('DataByNameMethod').AsBoolean;
  if Xml.HasParam('Compressed') then
    Compressed := Xml.GetParamByName('Compressed').AsBoolean;

  // sprawdzenie poprawnoœci danych
  if not IsValidName(Name) then
    raise EGeneratorException.Create('Invalid <DataFile NAME="' + Name + '" ... />');
  if not IsValidName(Name) then
    raise EGeneratorException.Create('Invalid <DataFile NAME="' + Name + '" ... />');
  if (Signature <> '') and (Length(Signature) <> 4) then
    raise EGeneratorException.Create('Invalid <DataFile Signature="' + Signature + '" ... />');
  if (Version <> '') and (Length(Version) <> 4) then
    raise EGeneratorException.Create('Invalid <DataFile Version="' + Version + '" ... />');

  DataRecords := CreateList('DataRecord', TPxCGDataRecord);
  DataRecordsEx := CreateList('DataRecordEx', TPxCGDataRecordEx);
  DataContainers := CreateList('DataContainer', TPxCGDataContainer);
  DataItems := TPxCGBaseList.Create;
  for I := 0 to DataRecords.Count - 1 do
    if not TPxCGDataRecord(DataRecords[I]).ContainerRecordOnly then
      DataItems.Add(DataRecords[I]);
  for I := 0 to DataRecordsEx.Count - 1 do
    if not TPxCGDataRecordEx(DataRecordsEx[I]).ContainerRecordOnly then
      DataItems.Add(DataRecordsEx[I]);
  for I := 0 to DataContainers.Count - 1 do
    DataItems.Add(DataContainers[I]);
  AdditionalUnits := CreateList('UseUnit', TPxCGUseUnit);
end;

procedure TPxCGDataFile.AddUnits(Output: TPxCGOutput);
var
  I: Integer;
begin
  Output.UsesList.Add('Classes');
  Output.UsesList.Add('SysUtils');
  Output.UsesList.Add('PxBase');
  Output.UsesList.Add('PxDataFile');
  if HasRecordsWithFloats or HasExpressionParts then
  begin
    Output.UsesList.AddObject('StdConvs', TPxCGConditional.Create(['VER150']));
    Output.UsesList.AddObject('BaseTypes', TPxCGConditional.Create(['VER150']));
  end;
  if GenerateXmlMethods then
    Output.UsesList.Add('PxXmlFile');

  // additional units
  for I := 0 to AdditionalUnits.Count - 1 do
    Output.UsesList.Add(TPxCGUseUnit(AdditionalUnits[I]).Name);
end;

procedure TPxCGDataFile.AddRemarks(Output: TPxCGOutput);
begin
  if HasRecordsWithFloats then
    Output.Remarks.Add('To use float parts declare DATARECORDEX_PART_FLOAT directive (Delphi7 only !)');
  if HasExpressionParts then
    Output.Remarks.Add('To use expression parts declare DATARECORDEX_PART_EXPRESSION directive (Delphi7 only !)');
end;

{ Public declarations }

destructor TPxCGDataFile.Destroy;
begin
  if Assigned(DataItems) then
    DataItems.Clear;
  FreeAndNil(DataItems);
  FreeAndNil(DataRecords);
  FreeAndNil(DataRecordsEx);
  FreeAndNil(DataContainers);
  inherited Destroy;
end;

procedure TPxCGDataFile.CreateInterface(Output: TPxCGOutput);
var
  I: Integer;
  DataRecord: TPxCGDataRecord;
  Container: TPxCGDataContainer;
begin
  for I := 0 to DataRecords.Count - 1 do
  begin
    DataRecords[I].CreateInterface(Output);
    Output.AddLine('');
  end;

  for I := 0 to DataRecordsEx.Count - 1 do
  begin
    DataRecordsEx[I].CreateInterface(Output);
    Output.AddLine('');
  end;

  for I := 0 to DataContainers.Count - 1 do
  begin
    DataContainers[I].CreateInterface(Output);
    Output.AddLine('');
  end;

  Output.AddLine('type');
  Output.IncIndent;
    if ParentClass = '' then
    begin
      if Compressed then
        Output.AddLine(GetTypeName('', Name, '') + ' = class (TPxCompressedDataFile)')
      else
        Output.AddLine(GetTypeName('', Name, '') + ' = class (TPxDataFile)');
    end
    else Output.AddLine(GetTypeName('', Name, '') + ' = class (' + ParentClass + ')');

    if HasSingles or HasLists or HasContainers or HasRecordsWithRecordID then
    begin
      Output.AddPrivate;
      // Id generator
      if HasRecordsWithRecordID then
        Output.AddLine('FIdGenerator: TPxIdGenerator;');

      for I := 0 to DataRecords.Count - 1 do
      begin
        DataRecord := DataRecords[I] as TPxCGDataRecord;
        if DataRecord.ContainerRecordOnly then Continue;

        if DataRecord.Single then
          Output.AddLine('F' + DataRecord.Name + ': ' + GetTypeName('', DataRecord.Name, '') + ';')
        else
          Output.AddLine('F' + GetListName(DataRecord.Name) + ': ' + GetTypeName('', DataRecord.Name, 'List') + ';');
      end;
      for I := 0 to DataRecordsEx.Count - 1 do
      begin
        DataRecord := DataRecordsEx[I] as TPxCGDataRecord;
        if DataRecord.ContainerRecordOnly then Continue;

        if DataRecord.Single then
          Output.AddLine('F' + DataRecord.Name + ': ' + GetTypeName('', DataRecord.Name, '') + ';')
        else
          Output.AddLine('F' + GetListName(DataRecord.Name) + ': ' + GetTypeName('', DataRecord.Name, 'List') + ';');
      end;
      for I := 0 to DataContainers.Count - 1 do
      begin
        Container := DataContainers[I] as TPxCGDataContainer;
        Output.AddLine('F' + GetListName(Container.Name) + ': ' + GetTypeName('', Container.Name, 'List') + ';');
      end;
      Output.DecIndent;
    end;

    if HasSingles or HasLists or HasContainers or (Signature <> '') or (Version <> '') or HasRecordsWithRecordID then
    begin
      Output.AddProtected;

      if HasSingles or HasLists or HasContainers then
        Output.AddLine('procedure RegisterClasses;');

      if (Signature <> '') or (Version <> '') then
        Output.AddLine('procedure Initialize; override;');

      if HasSingles or HasRecordsWithRecordID then
        Output.AddLine('procedure CreateSingles; override;');
      if HasLists or HasContainers then
      begin
        Output.AddLine('procedure CreateLists; override;');
        Output.AddLine('procedure DestroyLists; override;');
      end;
      if HasSingles or HasLists or HasContainers then
      begin
        Output.AddLine('function RecognizeRecord(const RH: TPxDataRecordHeader; var RecordClass: TPxDataRecordClass): TPxRecognizeRecordResult; override;');
        Output.AddLine('procedure OnAddRecord(Rec: TPxDataRecord); override;');
        Output.AddLine('procedure OnDelRecord(Rec: TPxDataRecord; RecordWillBeDisposed: Boolean); override;');
      end;
      Output.DecIndent;
    end;

    if HasSingles or HasLists or HasContainers or GenerateXmlMethods or HasRecordsWithRecordID then
    begin
      Output.AddPublic;

      // methods for creating records (they fill the Id field if defined)
      for I := 0 to DataRecords.Count - 1 do
      begin
        DataRecord := DataRecords[I] as TPxCGDataRecord;
        Output.AddLine('function Add' + DataRecord.Name + ': ' + GetTypeName('', DataRecord.Name, '') + ';');
      end;
      for I := 0 to DataRecordsEx.Count - 1 do
      begin
        DataRecord := DataRecordsEx[I] as TPxCGDataRecord;
        Output.AddLine('function Add' + DataRecord.Name + ': ' + GetTypeName('', DataRecord.Name, '') + ';');
      end;

      if GetDataByNameMethod then
        Output.AddLine('function GetData(Name: String): Variant;');

      if GenerateXmlMethods then
      begin
        Output.AddLine('procedure LoadXmlFile(FileName: String);');
        Output.AddLine('procedure LoadXmlStream(Stream: TStream);');
        Output.AddLine('procedure SaveXmlFile(FileName: String);');
        Output.AddLine('procedure SaveXmlStream(Stream: TStream);');
      end;

      Output.DecIndent;
      Output.AddPublished;

      if HasRecordsWithRecordID then
        Output.AddLine('property IdGenerator: TPxIdGenerator read FIdGenerator;');

      // singles
      for I := 0 to DataRecords.Count - 1 do
      begin
        DataRecord := DataRecords[I] as TPxCGDataRecord;
        if DataRecord.ContainerRecordOnly then Continue;

        if DataRecord.Single then
          Output.AddLine('property ' + DataRecord.Name + ': ' + GetTypeName('', DataRecord.Name, '') + ' read F' + DataRecord.Name + ';')
      end;
      for I := 0 to DataRecordsEx.Count - 1 do
      begin
        DataRecord := DataRecordsEx[I] as TPxCGDataRecord;
        if DataRecord.ContainerRecordOnly then Continue;

        if DataRecord.Single then
          Output.AddLine('property ' + DataRecord.Name + ': ' + GetTypeName('', DataRecord.Name, '') + ' read F' + DataRecord.Name + ';')
      end;

      // lists
      for I := 0 to DataRecords.Count - 1 do
      begin
        DataRecord := DataRecords[I] as TPxCGDataRecord;
        if DataRecord.ContainerRecordOnly then Continue;

        if not DataRecord.Single then
          Output.AddLine('property ' + GetListName(DataRecord.Name) + ': ' + GetTypeName('', DataRecord.Name, 'List') + ' read F' + GetListName(DataRecord.Name) + ';');
      end;
      for I := 0 to DataRecordsEx.Count - 1 do
      begin
        DataRecord := DataRecordsEx[I] as TPxCGDataRecord;
        if DataRecord.ContainerRecordOnly then Continue;

        if not DataRecord.Single then
          Output.AddLine('property ' + GetListName(DataRecord.Name) + ': ' + GetTypeName('', DataRecord.Name, 'List') + ' read F' + GetListName(DataRecord.Name) + ';');
      end;

      // containers
      for I := 0 to DataContainers.Count - 1 do
      begin
        Container := DataContainers[I] as TPxCGDataContainer;
        Output.AddLine('property ' + GetListName(Container.Name) + ': ' + GetTypeName('', Container.Name, 'List') + ' read F' + GetListName(Container.Name) + ';');
      end;
    end;

  Output.DecIndent;
  Output.AddLine('end;');
  Output.DecIndent;
end;

procedure TPxCGDataFile.CreateImplementation(Output: TPxCGOutput);
var
  I: Integer;
  DataRecord: TPxCGDataRecord;
  Added: Boolean;
  Container: TPxCGDataContainer;
begin
  for I := 0 to DataRecords.Count - 1 do
  begin
    DataRecords[I].CreateImplementation(Output);
    Output.AddLine('');
  end;

  for I := 0 to DataRecordsEx.Count - 1 do
  begin
    DataRecordsEx[I].CreateImplementation(Output);
    Output.AddLine('');
  end;

  for I := 0 to DataContainers.Count - 1 do
  begin
    DataContainers[I].CreateImplementation(Output);
    Output.AddLine('');
  end;

  Output.AddLine('{ ' + GetTypeName('', Name, '') + ' }');
  if HasSingles or HasLists or HasContainers then
  begin
    Output.AddLine('');
    Output.AddLine('{ Protected declarations }');

    Output.AddLine('');
    Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.RegisterClasses;');
    Output.AddBegin;
      for I := 0 to DataRecords.Count - 1 do
      begin
        DataRecord := DataRecords[I] as TPxCGDataRecord;
        Output.AddLine('RegisterClass(' + GetTypeName('', DataRecord.Name, '') + ');');
      end;
      for I := 0 to DataRecordsEx.Count - 1 do
      begin
        DataRecord := DataRecordsEx[I] as TPxCGDataRecord;
        Output.AddLine('RegisterClass(' + GetTypeName('', DataRecord.Name, '') + ');');
      end;
      for I := 0 to DataContainers.Count - 1 do
      begin
        Container := DataContainers[I] as TPxCGDataContainer;
        Output.AddLine('RegisterClass(' + GetTypeName('', Container.Name, '') + ');');
      end;
    Output.AddEnd;
  end;

  if (Signature <> '') or (Version <> '') or HasSingles or HasLists or HasContainers then
  begin
    Output.AddLine('');
    Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.Initialize;');
    Output.AddBegin;
      Output.AddLine('inherited Initialize;');
      if Signature <> '' then
        Output.AddLine('Signature := ''' + Signature + ''';');
      if Version <> '' then
        Output.AddLine('Version := ''' + Version + ''';');

      Output.AddLine('RegisterClasses;');
    Output.AddEnd;
  end;

  if HasSingles or HasRecordsWithRecordID then
  begin
    Output.AddLine('');
    Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.CreateSingles;');
    Output.AddBegin;
      if HasRecordsWithRecordID then
        Output.AddLine('AddRecord(TPxIdGenerator.Create(Self));');
      for I := 0 to DataRecords.Count - 1 do
      begin
        DataRecord := DataRecords[I] as TPxCGDataRecord;
        if DataRecord.ContainerRecordOnly then Continue;

        if DataRecord.Single then
          Output.AddLine('AddRecord(' + GetTypeName('', DataRecord.Name, '') + '.Create(Self));');
      end;
      for I := 0 to DataRecordsEx.Count - 1 do
      begin
        DataRecord := DataRecordsEx[I] as TPxCGDataRecord;
        if DataRecord.ContainerRecordOnly then Continue;

        if DataRecord.Single then
          Output.AddLine('AddRecord(' + GetTypeName('', DataRecord.Name, '') + '.Create(Self));');
      end;
    Output.AddEnd;
  end;

  if HasLists or HasContainers then
  begin
    Output.AddLine('');
    Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.CreateLists;');
    Output.AddBegin;
      for I := 0 to DataRecords.Count - 1 do
      begin
        DataRecord := DataRecords[I] as TPxCGDataRecord;
        if DataRecord.ContainerRecordOnly then Continue;

        if not DataRecord.Single then
          Output.AddLine('F' + GetListName(DataRecord.Name) + ' := ' + GetTypeName('', DataRecord.Name, 'List') + '.Create;');
      end;
      for I := 0 to DataRecordsEx.Count - 1 do
      begin
        DataRecord := DataRecordsEx[I] as TPxCGDataRecord;
        if DataRecord.ContainerRecordOnly then Continue;

        if not DataRecord.Single then
          Output.AddLine('F' + GetListName(DataRecord.Name) + ' := ' + GetTypeName('', DataRecord.Name, 'List') + '.Create;');
      end;

      // containers
      for I := 0 to DataContainers.Count - 1 do
      begin
        Container := DataContainers[I] as TPxCGDataContainer;
        Output.AddLine('F' + GetListName(Container.Name) + ' := ' + GetTypeName('', Container.Name, 'List') + '.Create;');
      end;

    Output.AddEnd;
    Output.AddLine('');
    Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.DestroyLists;');
    Output.AddBegin;
      for I := 0 to DataRecords.Count - 1 do
      begin
        DataRecord := DataRecords[I] as TPxCGDataRecord;
        if DataRecord.ContainerRecordOnly then Continue;

        if not DataRecord.Single then
          Output.AddLine('F' + GetListName(DataRecord.Name) + '.Free;');
      end;
      for I := 0 to DataRecordsEx.Count - 1 do
      begin
        DataRecord := DataRecordsEx[I] as TPxCGDataRecord;
        if DataRecord.ContainerRecordOnly then Continue;

        if not DataRecord.Single then
          Output.AddLine('F' + GetListName(DataRecord.Name) + '.Free;');
      end;
      for I := 0 to DataContainers.Count - 1 do
      begin
        Container := DataContainers[I] as TPxCGDataContainer;
        Output.AddLine('F' + GetListName(Container.Name) + '.Free;');
      end;
    Output.AddEnd;
  end;

  if HasSingles or HasLists or HasContainers or HasRecordsWithRecordID then
  begin
    Output.AddLine('');
    Output.AddLine('function ' + GetTypeName('', Name, '') + '.RecognizeRecord(const RH: TPxDataRecordHeader; var RecordClass: TPxDataRecordClass): TPxRecognizeRecordResult;');
    Output.AddBegin;
      Output.AddLine('case RH.Kind of');
      Output.IncIndent;
      if HasRecordsWithRecordID then
      begin
        Output.AddLine('kindIdGenerator:');
        Output.IncIndent;
          Output.AddBegin;
            Output.AddLine('RecordClass := TPxIdGenerator;');
            Output.AddLine('Result := rrrRecognized;');
          Output.AddEnd;
        Output.DecIndent;
      end;
      for I := 0 to DataRecords.Count - 1 do
      begin
        DataRecord := DataRecords[I] as TPxCGDataRecord;
        Output.AddLine('kindid' + DataRecord.Name + ':');
        Output.IncIndent;
          Output.AddBegin;
            Output.AddLine('RecordClass := ' + GetTypeName('', DataRecord.Name, '') + ';');
            Output.AddLine('Result := rrrRecognized;');
          Output.AddEnd;
        Output.DecIndent;
      end;
      for I := 0 to DataRecordsEx.Count - 1 do
      begin
        DataRecord := DataRecordsEx[I] as TPxCGDataRecord;
        Output.AddLine('kindid' + DataRecord.Name + ':');
        Output.IncIndent;
          Output.AddBegin;
            Output.AddLine('RecordClass := ' + GetTypeName('', DataRecord.Name, '') + ';');
            Output.AddLine('Result := rrrRecognized;');
          Output.AddEnd;
        Output.DecIndent;
      end;
      // data containers
      for I := 0 to DataContainers.Count - 1 do
      begin
        Container := DataContainers[I] as TPxCGDataContainer;
        Output.AddLine('kindid' + Container.Name + ':');
        Output.IncIndent;
          Output.AddBegin;
            Output.AddLine('RecordClass := ' + GetTypeName('', Container.Name, '') + ';');
            Output.AddLine('Result := rrrRecognized;');
          Output.AddEnd;
        Output.DecIndent;
      end;
      Output.AddLine('else Result := inherited RecognizeRecord(RH, RecordClass);');
      Output.AddEnd;
    Output.AddEnd;
    Output.AddLine('');
    Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.OnAddRecord(Rec: TPxDataRecord);');
    Output.AddBegin;


      if HasRecordsWithRecordID then
      begin
        Output.AddLine('if Rec is TPxIdGenerator then');
        Output.AddBegin;
          Output.AddLine('Records.Remove(FIdGenerator);');
          Output.AddLine('FIdGenerator.Free;');
          Output.AddLine('FIdGenerator := Rec as TPxIdGenerator;');
        Output.AddEndNoColone;
        Added := True;
      end
      else Added := False;

      for I := 0 to DataRecords.Count - 1 do
      begin
        DataRecord := DataRecords[I] as TPxCGDataRecord;
        if DataRecord.ContainerRecordOnly then Continue;

        if not Added then
        begin
          Output.AddLine('if Rec is ' + GetTypeName('', DataRecord.Name, '') + ' then');
          Added := True;
        end
        else Output.AddLine('else if Rec is ' + GetTypeName('', DataRecord.Name, '') + ' then');

        if DataRecord.Single then
        begin
          Output.AddBegin;
          Output.AddLine('Records.Remove(F' + DataRecord.Name + ');');
          Output.AddLine('F' + DataRecord.Name + '.Free;');
          Output.AddLine('F' + DataRecord.Name + ' := Rec as ' + GetTypeName('', DataRecord.Name, '') + ';');
          Output.AddEndNoColone;
        end
        else
        begin
          Output.IncIndent;
            Output.AddLine('F' + GetListName(DataRecord.Name) + '.Add(Rec)');
          Output.DecIndent;
        end;
      end;
      for I := 0 to DataRecordsEx.Count - 1 do
      begin
        DataRecord := DataRecordsEx[I] as TPxCGDataRecord;
        if DataRecord.ContainerRecordOnly then Continue;

        if not Added then
        begin
          Output.AddLine('if Rec is ' + GetTypeName('', DataRecord.Name, '') + ' then');
          Added := True;
        end
        else Output.AddLine('else if Rec is ' + GetTypeName('', DataRecord.Name, '') + ' then');

        if DataRecord.Single then
        begin
          Output.AddBegin;
          Output.AddLine('Records.Remove(F' + DataRecord.Name + ');');
          Output.AddLine('F' + DataRecord.Name + '.Free;');
          Output.AddLine('F' + DataRecord.Name + ' := Rec as ' + GetTypeName('', DataRecord.Name, '') + ';');
          Output.AddEndNoColone;
        end
        else
        begin
          Output.IncIndent;
            Output.AddLine('F' + GetListName(DataRecord.Name) + '.Add(Rec)');
          Output.DecIndent;
        end;
      end;
      for I := 0 to DataContainers.Count - 1 do
      begin
        Container := DataContainers[I] as TPxCGDataContainer;

        if not Added then
        begin
          Output.AddLine('if Rec is ' + GetTypeName('', Container.Name, '') + ' then');
          Added := True;
        end
        else Output.AddLine('else if Rec is ' + GetTypeName('', Container.Name, '') + ' then');
        Output.IncIndent;
        Output.AddLine('F' + GetListName(Container.Name) + '.Add(Rec)');
        Output.DecIndent;
      end;
    Output.AddEnd;
    Output.AddLine('');
    Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.OnDelRecord(Rec: TPxDataRecord; RecordWillBeDisposed: Boolean);');
    Output.AddBegin;
      if HasRecordsWithRecordID then
      begin
        Output.AddLine('if Rec is TPxIdGenerator then');
        Output.IncIndent;
          Output.AddLine('FIdGenerator := nil');
        Output.DecIndent;
        Added := True;
      end
      else Added := False;

      for I := 0 to DataRecords.Count - 1 do
      begin
        DataRecord := DataRecords[I] as TPxCGDataRecord;
        if DataRecord.ContainerRecordOnly then Continue;

        if not Added then
        begin
          Output.AddLine('if Rec is ' + GetTypeName('', DataRecord.Name, '') + ' then');
          Added := True;
        end
        else Output.AddLine('else if Rec is ' + GetTypeName('', DataRecord.Name, '') + ' then');

        Output.IncIndent;
        if DataRecord.Single then
          Output.AddLine('F' + DataRecord.Name + ' := nil')
        else
          Output.AddLine('F' + GetListName(DataRecord.Name) + '.Remove(Rec)');
        Output.DecIndent;
      end;
      for I := 0 to DataRecordsEx.Count - 1 do
      begin
        DataRecord := DataRecordsEx[I] as TPxCGDataRecord;
        if DataRecord.ContainerRecordOnly then Continue;

        if not Added then
        begin
          Output.AddLine('if Rec is ' + GetTypeName('', DataRecord.Name, '') + ' then');
          Added := True;
        end
        else Output.AddLine('else if Rec is ' + GetTypeName('', DataRecord.Name, '') + ' then');

        Output.IncIndent;
        if DataRecord.Single then
          Output.AddLine('F' + DataRecord.Name + ' := nil')
        else
          Output.AddLine('F' + GetListName(DataRecord.Name) + '.Remove(Rec)');
        Output.DecIndent;
      end;
      for I := 0 to DataContainers.Count - 1 do
      begin
        Container := DataContainers[I] as TPxCGDataContainer;
        if not Added then
        begin
          Output.AddLine('if Rec is ' + GetTypeName('', Container.Name, '') + ' then');
          Added := True;
        end
        else Output.AddLine('else if Rec is ' + GetTypeName('', Container.Name, '') + ' then');

        Output.IncIndent;
        Output.AddLine('F' + GetListName(Container.Name) + '.Remove(Rec)');
        Output.DecIndent;
      end;
    Output.AddEnd;
  end;

  for I := 0 to DataRecords.Count - 1 do
  begin
    DataRecord := DataRecords[I] as TPxCGDataRecord;
    Output.AddLine('');
    Output.AddLine('function ' + GetTypeName('', Name, '') + '.Add' + DataRecord.Name + ': ' + GetTypeName('', DataRecord.Name, '') + ';');
    Output.AddBegin;
      Output.AddLine('Result := AddRecord(' + GetTypeName('', DataRecord.Name, '') + '.Create(Self)) as ' + GetTypeName('', DataRecord.Name, '') + ';');
      if DataRecord.RecordIDField <> '' then
        Output.AddLine('Result.D.' + DataRecord.RecordIDField + ' := IdGenerator.NewId;');
    Output.AddEnd;
  end;
  for I := 0 to DataRecordsEx.Count - 1 do
  begin
    DataRecord := DataRecordsEx[I] as TPxCGDataRecord;
    Output.AddLine('');
    Output.AddLine('function ' + GetTypeName('', Name, '') + '.Add' + DataRecord.Name + ': ' + GetTypeName('', DataRecord.Name, '') + ';');
    Output.AddBegin;
      Output.AddLine('Result := AddRecord(' + GetTypeName('', DataRecord.Name, '') + '.Create(Self)) as ' + GetTypeName('', DataRecord.Name, '') + ';');
      if DataRecord.RecordIDField <> '' then
        Output.AddLine('Result.' + DataRecord.RecordIDField + ' := IdGenerator.NewId;');
    Output.AddEnd;
  end;

  if GetDataByNameMethod then
    CreateGetDataByName(Output);

  if GenerateXmlMethods then
  begin
    Output.AddLine('');
    Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.LoadXmlFile(FileName: String);');
    Output.AddLine('var');
    Output.IncIndent;
    Output.AddLine('S: TStream;');
    Output.DecIndent;
    Output.AddBegin;
    Output.AddLine('S := TFileStream.Create(FileName, fmOpenRead);');
    Output.AddLine('LoadXmlStream(S);');
    Output.AddLine('Self.FileName := FileName;');
    Output.AddLine('S.Free;');
    Output.AddEnd;
    Output.AddLine('');
    Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.LoadXmlStream(Stream: TStream);');
    Output.AddLine('var');
    Output.IncIndent;
      Output.AddLine('Xml: TPxXMLFile;');
      if HasLists or HasContainersWithLists then
        Output.AddLine('I: Integer;');
      if HasContainers then
        Output.AddLine('J: Integer;');
      if HasRecordsWithArrays then
        Output.AddLine('K: Integer;');
      for I := 0 to DataRecords.Count - 1 do
      begin
        DataRecord := DataRecords[I] as TPxCGDataRecord;
        if not DataRecord.Single then
          Output.AddLine(DataRecord.Name + ': ' + GetTypeName('', DataRecord.Name, '') + ';');
      end;
      for I := 0 to DataRecordsEx.Count - 1 do
      begin
        DataRecord := DataRecordsEx[I] as TPxCGDataRecord;
        if not DataRecord.Single then
          Output.AddLine(DataRecord.Name + ': ' + GetTypeName('', DataRecord.Name, '') + ';');
      end;
      for I := 0 to DataContainers.Count - 1 do
      begin
        Container := DataContainers[I] as TPxCGDataContainer;
        Output.AddLine(Container.Name + ': ' + GetTypeName('', Container.Name, '') + ';');
      end;
    Output.DecIndent;
    Output.AddBegin;
      Output.AddLine('Clear;');
      if ResolveXmlIncludes then
        Output.AddLine('Xml := TPxXMLFile.Create(True, True);')
      else
        Output.AddLine('Xml := TPxXMLFile.Create(False, True);');
      Output.AddLine('Xml.ReadStream(Stream);');
      Output.AddLine('if Xml.XmlItem.IsItemName(''' + Name + ''') then');
      Output.IncIndent;
        Output.AddLine('with Xml.XmlItem do');
        Output.IncIndent;
          Output.AddLine('if (GetParamByNameS(''Signature'') = Signature) and (GetParamByNameS(''Version'') = Version) then');
          Output.AddBegin;
            Output.AddLine('if HasParam(''Created'') then');
            Output.IncIndent;
              Output.AddLine('DateCreated := GetParamByNameS(''Created'');');
            Output.DecIndent;
            Output.AddLine('if HasParam(''Modified'') then');
            Output.IncIndent;
              Output.AddLine('DateLastModified := GetParamByNameS(''Modified'');');
            Output.DecIndent;

            Output.AddLine('for I := 0 to ItemCount - 1 do');
            Output.AddBegin;

            // load IdGenerator
            if HasRecordsWithRecordID then
            begin
              Output.AddLine('if Items[I].IsItemName(''IdGenerator'') then');
              Output.IncIndent;
                Output.AddLine('IdGenerator.SetLastId(Items[I].GetParamByName(''LastId'').AsInteger);');
              Output.DecIndent;
            end;
            // load records (xml)
            for I := 0 to DataItems.Count - 1 do
              if DataItems[I] is TPxCGDataRecord then
              begin
                DataRecord := DataItems[I] as TPxCGDataRecord;
                if DataRecord.ContainerRecordOnly then Continue;
                DataRecord.NowInContainer := False;
                DataRecord.CreateXmlRead(Output);
              end
              else if DataItems[I] is TPxCGDataContainer then
              begin
                Container := DataItems[I] as TPxCGDataContainer;
                Container.CreateXmlRead(Output);
              end;
              
            Output.AddEnd;
          Output.Addend;
        Output.DecIndent;
      Output.DecIndent;
    Output.AddLine('Xml.Free;');
    Output.AddLine('ResolveIds;');
    Output.AddEnd;
    Output.AddLine('');

    Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.SaveXmlFile(FileName: String);');
    Output.AddLine('var');
    Output.IncIndent;
    Output.AddLine('S: TStream;');
    Output.DecIndent;
    Output.AddBegin;
    Output.AddLine('S := TFileStream.Create(FileName, fmCreate);');
    Output.AddLine('SaveXmlStream(S);');
    Output.AddLine('S.Free;');
    Output.AddEnd;
    Output.AddLine('');
    Output.AddLine('procedure ' + GetTypeName('', Name, '') + '.SaveXmlStream(Stream: TStream);');
    Output.AddLine('var');
    Output.IncIndent;
      Output.AddLine('Xml: TPxXMLFile;');
      if HasLists or HasContainersWithLists then
        Output.AddLine('I: Integer;');
      if HasContainers then
        Output.AddLine('J: Integer;');
      if HasRecordsWithArrays then
        Output.AddLine('K: Integer;');
      for I := 0 to DataRecords.Count - 1 do
      begin
        DataRecord := DataRecords[I] as TPxCGDataRecord;
        if not DataRecord.Single then
          Output.AddLine(DataRecord.Name + ': ' + GetTypeName('', DataRecord.Name, '') + ';');
      end;
      for I := 0 to DataRecordsEx.Count - 1 do
      begin
        DataRecord := DataRecordsEx[I] as TPxCGDataRecord;
        if not DataRecord.Single then
          Output.AddLine(DataRecord.Name + ': ' + GetTypeName('', DataRecord.Name, '') + ';');
      end;
      for I := 0 to DataContainers.Count - 1 do
      begin
        Container := DataContainers[I] as TPxCGDataContainer;
        Output.AddLine(Container.Name + ': ' + GetTypeName('', Container.Name, '') + ';');
      end;
    Output.DecIndent;
    Output.AddBegin;
      Output.AddLine('Xml := TPxXMLFile.Create(False, True);');
      // naglowek
      Output.AddLine('with Xml.XmlItem do');
      Output.AddBegin;
        Output.AddLine('Name := ''' + Name + ''';');
        Output.AddLine('GetParamByName(''Signature'').Value := Signature;');
        Output.AddLine('GetParamByName(''Version'').Value := Version;');
        Output.AddLine('GetParamByName(''Created'').Value := DateCreated;');
        Output.AddLine('GetParamByName(''Modified'').Value := DateLastModified;');

        // Save records
        Added := False;
        // save IdGenerator
        Output.AddLine('for I := 0 to Records.Count - 1 do');
        Output.AddBegin;
          if HasRecordsWithRecordID then
          begin
            if not Added then
              Output.AddLine('if Records[I] is TPxIdGenerator then')
            else
              Output.AddLine('else if Records[I] is TPxIdGenerator then');
            Output.IncIndent;
              Output.AddLine('with TPxXMLItem.Create(This), IdGenerator do');
              Output.AddBegin;
                Output.AddLine('This.Name := ''IdGenerator'';');
                Output.AddLine('This.GetParamByName(''LastId'').AsInteger := IdGenerator.LastId;');
              Output.AddEndNoColone;
            Output.DecIndent;
            Added := True;
          end;
          for I := 0 to DataItems.Count - 1 do
          begin
            if DataItems[I] is TPxCGDataRecord then
            begin
              DataRecord := DataItems[I] as TPxCGDataRecord;
              if DataRecord.ContainerRecordOnly then Continue;
              if not Added then
                Output.AddLine('if Records[I] is ' + GetTypeName('', DataRecord.Name, '') + ' then')
              else
                Output.AddLine('else if Records[I] is ' + GetTypeName('', DataRecord.Name, '') + ' then');
              Added := True;
              Output.AddBegin;
                if not DataRecord.Single then
                  Output.AddLine(DataRecord.Name + ' := Records[I] as ' + GetTypeName('', DataRecord.Name, '') + ';');
                DataRecord.CreateXmlWrite(Output);
              Output.AddEndNoColone;
            end
            else
            begin
              Container := DataItems[I] as TPxCGDataContainer;
              if not Added then
                Output.AddLine('if Records[I] is ' + GetTypeName('', Container.Name, '') + ' then')
              else
                Output.AddLine('else if Records[I] is ' + GetTypeName('', Container.Name, '') + ' then');
              Added := True;
              Output.AddBegin;
                Output.AddLine(Container.Name + ' := Records[I] as ' + GetTypeName('', Container.Name, '') + ';');
                Container.CreateXmlWrite(Output);
              Output.AddEnd;
            end;
          end;

        Output.AddEnd;
      Output.AddEnd;
      Output.AddLine('Xml.WriteStream(Stream);');
      Output.AddLine('Xml.Free;');
    Output.AddEnd;
  end;
end;

{ *** }

function GenerateDataFile(var FileName: String; OutputFile: String = ''): Boolean;
var
  Xml: TPxXMLFile;
  DataFile: TPxCGDataFile;
  Output: TPxCGOutput;
  S: String;
begin
  Result := True;

  Xml := TPxXMLFile.Create;
  Xml.ReadFile(FileName);
  if Xml.Status <> psLoaded then
  begin
    S := Xml.StatusMessage;
    Xml.Free;
    raise EGeneratorException.Create(S);
  end;

  try
    DataFile := TPxCGDataFile.Create(nil, Xml.XMLItem);
  except
    on E: Exception do
    begin
      ErrorMsg := E.Message;
      Result := False;
      Exit;
    end;
  end;

  Output := TPxCGOutput.Create;
  Output.Items.Add(DataFile);
  try
    try
      Output.GenerateFile(DataFile.Name);
      // if Outputdir contains a drive name
      if (Length(DataFile.OutputDir) >= 2) and ((DataFile.OutputDir[2] <> ':') or ((DataFile.OutputDir[1] = '\') and (DataFile.OutputDir[2] = '\'))) then
        FileName := ExtractFilePath(ParamStr(0)) + DataFile.OutputDir +  DataFile.Name + '.pas'
      else
        FileName := DataFile.OutputDir +  DataFile.Name + '.pas';

      if OutputFile <> '' then
        FileName := OutputFile;
        
      Output.Lines.SaveToFile(FileName);
    except
      on E: EGeneratorException do
      begin
        ErrorMsg := E.Message;
        Result := False;
        Output.Free;
        Exit;
      end;
      on E: Exception do
      begin
        ErrorMsg := '(generic) ' + E.Message;
        Result := False;
        Output.Free;
        Exit;
      end;
    end;
  finally
    Output.Free;
  end;
end;

end.
