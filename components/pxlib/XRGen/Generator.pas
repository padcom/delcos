unit Generator;

interface

uses
  Classes, SysUtils, 
  PxDTDFile;

procedure GenerateUnit(UnitName: String; DTDFile: TDTDFile; Output: TStrings);

implementation

function CapitalizeFirstLetter(S: String): String;
begin
  Result := S;
  Result[1] := UpCase(Result[1]);
end;

function HasObjects(Element: TDTDElement): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to Element.Elements.Count - 1 do
    if Element.Elements[I].Elements.Count > 0 then
    begin
      Result := True;
      Break;
    end;
end;

procedure CreateForwardDeclarations(DTDFile: TDTDFile; Output: TStrings);
var
  I: Integer;
begin
  for I := 0 to DTDFile.Elements.Count - 1 do
    if DTDFile.Elements[I].Elements.Count > 0 then
    begin
      Output.Add('  TXml' + CapitalizeFirstLetter(DTDFile.Elements[I].Name) + ' = class;');
      if DTDFile.Elements[I] <> DTDFile.Root then
        Output.Add('  TXml' + CapitalizeFirstLetter(DTDFile.Elements[I].Name) + 'List = class;');
    end;
  Output.Add('');
end;

procedure CreateRootElementInterface(Element: TDTDElement; Output: TStrings);
var
  I: Integer;
begin
  Output.Add('  TXml' + CapitalizeFirstLetter(Element.Name) + ' = class(TObject)');
  Output.Add('  private');
  for I := 0 to Element.Elements.Count - 1 do
  begin
    if Element.Elements[I].Elements.Count = 0 then
      Output.Add('    F' + CapitalizeFirstLetter(Element.Elements[I].Name) + ': String;')
    else
      Output.Add('    F' + CapitalizeFirstLetter(Element.Elements[I].Name) + ': TXml' + CapitalizeFirstLetter(Element.Elements[I].Name) + 'List;')
  end;
  Output.Add('  protected');
  Output.Add('    procedure LoadFromXml(XmlReader: TPxXmlReader);');
  Output.Add('  public');
  if HasObjects(Element) then
  begin
    Output.Add('    constructor Create;');
    Output.Add('    destructor Destroy; override;');
  end;
  for I := 0 to Element.Elements.Count - 1 do
    if Element.Elements[I].Elements.Count = 0 then
      Output.Add('    property ' + CapitalizeFirstLetter(Element.Elements[I].Name) + ': String read F' + CapitalizeFirstLetter(Element.Elements[I].Name) + ' write F' + CapitalizeFirstLetter(Element.Elements[I].Name) + ';')
    else
      Output.Add('    property ' + CapitalizeFirstLetter(Element.Elements[I].Name) + ': TXml' + CapitalizeFirstLetter(Element.Elements[I].Name) + 'List read F' + CapitalizeFirstLetter(Element.Elements[I].Name) +';');
  Output.Add('  end;');
  Output.Add('');
end;

procedure CreateElementListInterface(Element: TDTDElement; Output: TStrings);
begin
  Output.Add('  TXml' + CapitalizeFirstLetter(Element.Name) + 'List = class(TList)');
  Output.Add('  private');
  Output.Add('    function GetItem(Index: Integer): TXml' + CapitalizeFirstLetter(Element.Name) + ';');
  Output.Add('  public');
  Output.Add('    property Items[Index: Integer]: TXml' + CapitalizeFirstLetter(Element.Name) + ' read GetItem; default;');
  Output.Add('  end;');
  Output.Add('');
end;

procedure CreateElementInterface(Element: TDTDElement; Output: TStrings);
var
  I: Integer;
begin
  Output.Add('  TXml' + CapitalizeFirstLetter(Element.Name) + ' = class(TObject)');
  Output.Add('  private');
  for I := 0 to Element.Elements.Count - 1 do
  begin
    if Element.Elements[I].Elements.Count = 0 then
      Output.Add('    F' + CapitalizeFirstLetter(Element.Elements[I].Name) + ': String;')
    else
      Output.Add('    F' + CapitalizeFirstLetter(Element.Elements[I].Name) + ': TXml' + CapitalizeFirstLetter(Element.Elements[I].Name) + 'List;')
  end;
  Output.Add('  protected');
  Output.Add('    procedure LoadFromXml(XmlReader: TPxXmlReader);');
  Output.Add('  public');
  if HasObjects(Element) then
  begin
    Output.Add('    constructor Create;');
    Output.Add('    destructor Destroy; override;');
  end;
  for I := 0 to Element.Elements.Count - 1 do
    if Element.Elements[I].Elements.Count = 0 then
      Output.Add('    property ' + CapitalizeFirstLetter(Element.Elements[I].Name) + ': String read F' + CapitalizeFirstLetter(Element.Elements[I].Name) + ' write F' + CapitalizeFirstLetter(Element.Elements[I].Name) + ';')
    else
      Output.Add('    property ' + CapitalizeFirstLetter(Element.Elements[I].Name) + ': TXml' + CapitalizeFirstLetter(Element.Elements[I].Name) + 'List read F' + CapitalizeFirstLetter(Element.Elements[I].Name) +';');
  Output.Add('  end;');
  Output.Add('');
end;

procedure CreateRootElementImplementation(Element: TDTDElement; Output: TStrings);
var
  I: Integer;
begin
  Output.Add('{ TXml' + CapitalizeFirstLetter(Element.Name) + ' } ');
  Output.Add('');
  Output.Add('{ Protected declarations }');
  Output.Add('');
  //
  // LoadFromXml
  //
  Output.Add('procedure TXml' + CapitalizeFirstLetter(Element.Name) + '.LoadFromXml(XmlReader: TPxXmlReader);');
  if HasObjects(Element) then
  begin
    Output.Add('var');
    for I := 0 to Element.Elements.Count - 1 do
      if Element.Elements[I].Elements.Count > 0 then
        Output.Add('  ' + CapitalizeFirstLetter(Element.Elements[I].Name) + ': TXml' + CapitalizeFirstLetter(Element.Elements[I].Name) + ';');
  end;
  Output.Add('begin');
  Output.Add('  while XmlReader.Next <> xrtEof do');
  Output.Add('    case XmlReader.TokenType of');
  Output.Add('      xrtElementBegin:');
  Output.Add('      begin');
  for I := 0 to Element.Elements.Count - 1 do
  begin
    if I = 0 then
      Output.Add('        if XmlReader.Name = ''' + Element.Elements[I].Name + ''' then')
    else
      Output.Add('        else if XmlReader.Name = ''' + Element.Elements[I].Name + ''' then');
    Output.Add('        begin');
    Output.Add('          ' + CapitalizeFirstLetter(Element.Elements[I].Name) + ' := TXml' + CapitalizeFirstLetter(Element.Elements[I].Name) + '.Create;');
    Output.Add('          ' + CapitalizeFirstLetter(Element.Elements[I].Name) + '.LoadFromXml(XmlReader);');
    Output.Add('          Self.' + CapitalizeFirstLetter(Element.Elements[I].Name) + '.Add(' + CapitalizeFirstLetter(Element.Elements[I].Name) + ');');
    Output.Add('        end');
  end;
  Output.Add('      end;');
  Output.Add('      xrtElementEnd:');
  Output.Add('        if XmlReader.Name = ''' + Element.Name + ''' then');
  Output.Add('          Break');
  Output.Add('    end;');
  Output.Add('end;');
  Output.Add('');
  if HasObjects(Element) then
  begin
    Output.Add('{ Public declarations }');
    Output.Add('');
    //
    // Constructor
    //
    Output.Add('constructor TXml' + CapitalizeFirstLetter(Element.Name) + '.Create;');
    Output.Add('begin');
    Output.Add('  inherited Create;');
    for I := 0 to Element.Elements.Count - 1 do
      if Element.Elements[I].Elements.Count > 0 then
        Output.Add('  F' + CapitalizeFirstLetter(Element.Elements[I].Name) + ' := TXml' + CapitalizeFirstLetter(Element.Elements[I].Name) + 'List.Create;');
    Output.Add('end;');
    Output.Add('');
    //
    // Destructor
    //
    Output.Add('destructor TXml' + CapitalizeFirstLetter(Element.Name) + '.Destroy;');
    Output.Add('var');
    Output.Add('  I: Integer;');
    Output.Add('begin');
    for I := 0 to Element.Elements.Count - 1 do
      if Element.Elements[I].Elements.Count > 0 then
      begin
        Output.Add('  for I := 0 to ' + CapitalizeFirstLetter(Element.Elements[I].Name) + '.Count - 1 do');
        Output.Add('    ' + CapitalizeFirstLetter(Element.Elements[I].Name) + '[I].Free;');
        Output.Add('  FreeAndNil(F' + CapitalizeFirstLetter(Element.Elements[I].Name) + ');');
      end;
    Output.Add('  inherited Destroy;');
    Output.Add('end;');
  end;
  Output.Add('');
end;

procedure CreateElementImplementation(Element: TDTDElement; Output: TStrings);
var
  I: Integer;
  IfStarted: Boolean;
begin
  Output.Add('{ TXml' + CapitalizeFirstLetter(Element.Name) + ' } ');
  Output.Add('');
  Output.Add('{ Protected declarations }');
  Output.Add('');
  //
  // LoadFromXml
  //
  Output.Add('procedure TXml' + CapitalizeFirstLetter(Element.Name) + '.LoadFromXml(XmlReader: TPxXmlReader);');
  Output.Add('begin');
  Output.Add('  while XmlReader.Next <> xrtEof do');
  Output.Add('    case XmlReader.TokenType of');
  if HasObjects(Element) then
  begin
    Output.Add('      xrtElementBegin:');
    Output.Add('      begin');
    IfStarted := False;
    for I := 0 to Element.Elements.Count - 1 do
      if Element.Elements[I].Elements.Count > 0 then
      begin
        if not IfStarted then
          Output.Add('        if XmlReader.Name = ''' + Element.Elements[I].Name + ''' then')
        else
          Output.Add('        else if XmlReader.Name = ''' + Element.Elements[I].Name + ''' then');
        IfStarted := True;
        Output.Add('        begin');
        begin
          Output.Add('          ' + CapitalizeFirstLetter(Element.Elements[I].Name) + ' := TXml' + CapitalizeFirstLetter(Element.Elements[I].Name) + '.Create;');
          Output.Add('          ' + CapitalizeFirstLetter(Element.Elements[I].Name) + '.LoadFromXml(XmlReader);');
          Output.Add('          Self.' + CapitalizeFirstLetter(Element.Elements[I].Name) + '.Add(' + CapitalizeFirstLetter(Element.Elements[I].Name) + ');');
        end;
        Output.Add('        end');
      end;
    Output.Add('      end;');
  end;
  Output.Add('      xrtText:');
  Output.Add('      begin');
  IfStarted := False;
  for I := 0 to Element.Elements.Count - 1 do
    if Element.Elements[I].Elements.Count = 0 then
    begin
      if not IfStarted then
        Output.Add('        if XmlReader.ElementName = ''' + Element.Elements[I].Name + ''' then')
      else
        Output.Add('        else if XmlReader.ElementName = ''' + Element.Elements[I].Name + ''' then');
      IfStarted := True;
      Output.Add('          F' + CapitalizeFirstLetter(Element.Elements[I].Name) + ' := XmlReader.Value');
    end;
  Output.Add('      end;');
  Output.Add('      xrtElementEnd:');
  Output.Add('        if XmlReader.Name = ''' + Element.Name + ''' then');
  Output.Add('          Break;');
  Output.Add('    end;');
  Output.Add('end;');
  Output.Add('');
  if HasObjects(Element) then
  begin
    Output.Add('{ Public declarations }');
    Output.Add('');
    //
    // Constructor
    //
    Output.Add('constructor TXml' + CapitalizeFirstLetter(Element.Name) + '.Create;');
    Output.Add('begin');
    Output.Add('  inherited Create;');
    for I := 0 to Element.Elements.Count - 1 do
      if Element.Elements[I].Elements.Count > 0 then
        Output.Add('  F' + CapitalizeFirstLetter(Element.Elements[I].Name) + ' := TXml' + CapitalizeFirstLetter(Element.Elements[I].Name) + 'List.Create;');
    Output.Add('end;');
    Output.Add('');
    //
    // Destructor
    //
    Output.Add('destructor TXml' + CapitalizeFirstLetter(Element.Name) + '.Destroy;');
    Output.Add('var');
    Output.Add('  I: Integer;');
    Output.Add('begin');
    for I := 0 to Element.Elements.Count - 1 do
      if Element.Elements[I].Elements.Count > 0 then
      begin
        Output.Add('  for I := 0 to ' + CapitalizeFirstLetter(Element.Elements[I].Name) + '.Count - 1 do');
        Output.Add('    ' + CapitalizeFirstLetter(Element.Elements[I].Name) + '[I].Free;');
        Output.Add('  FreeAndNil(F' + CapitalizeFirstLetter(Element.Elements[I].Name) + ');');
      end;
    Output.Add('  inherited Destroy;');
    Output.Add('end;');
    Output.Add('');
  end;
end;

procedure CreateElementListImplementation(Element: TDTDElement; Output: TStrings);
begin
  Output.Add('{ TXml' + CapitalizeFirstLetter(Element.Name) + 'List } ');
  Output.Add('');
  Output.Add('{ Private declarations }');
  Output.Add('');
  Output.Add('function TXml' + CapitalizeFirstLetter(Element.Name) + 'List.GetItem(Index: Integer): TXml' + CapitalizeFirstLetter(Element.Name) + ';');
  Output.Add('begin');
  Output.Add('  Result := TObject(Get(Index)) as TXml' + CapitalizeFirstLetter(Element.Name) + ';');
  Output.Add('end;');
  Output.Add('');
end;

procedure CreateMainLoadFunctionInterface(DTDFile: TDTDFile; Output: TStrings);
begin
  Output.Add('function Load' + CapitalizeFirstLetter(DTDFile.Root.Name) + '(FileName: String): TXml' + CapitalizeFirstLetter(DTDFile.Root.Name) + ';');
  Output.Add('');
end;

procedure CreateMainLoadFunctionImplementation(DTDFile: TDTDFile; Output: TStrings);
begin
  Output.Add('function Load' + CapitalizeFirstLetter(DTDFile.Root.Name) + '(FileName: String): TXml' + CapitalizeFirstLetter(DTDFile.Root.Name) + ';');
  Output.Add('var');
  Output.Add('  XmlReader: TPxXmlReader;');
  Output.Add('begin');
  Output.Add('  Result := nil;');
  Output.Add('');
  Output.Add('  XmlReader := TPxXmlReader.Create;');
  Output.Add('  try');
  Output.Add('    XmlReader.Open(FileName);');
  Output.Add('    while XmlReader.Next <> xrtEof do');
  Output.Add('      case XmlReader.TokenType of');
  Output.Add('        xrtElementBegin:');
  Output.Add('        begin');
  Output.Add('          if XmlReader.Name = ''' + DTDFile.Root.Name + ''' then');
  Output.Add('          begin');
  Output.Add('            Result := TXml' + CapitalizeFirstLetter(DTDFile.Root.Name) + '.Create;');
  Output.Add('            Result.LoadFromXml(XmlReader);');
  Output.Add('          end');
  Output.Add('          else');
  Output.Add('            raise Exception.CreateFmt(''Error: unknown element %s'', [XmlReader.Name]);');
  Output.Add('        end;');
  Output.Add('      end;');
  Output.Add('  finally');
  Output.Add('    XmlReader.Free;');
  Output.Add('  end;');
  Output.Add('end;');
  Output.Add('');
end;

procedure GenerateUnit(UnitName: String; DTDFile: TDTDFile; Output: TStrings);
var
  I: Integer;
begin
  Output.Add('unit ' + UnitName + ';');
  Output.Add('');
  Output.Add('interface');
  Output.Add('');
  Output.Add('uses');
  Output.Add('  Classes, SysUtils, PxXmlReader;');
  Output.Add('');
  Output.Add('type');
  Output.Add('');
  Output.Add('  { Forward declarations }');
  Output.Add('');
  CreateForwardDeclarations(DTDFile, Output);
  Output.Add('  { Element''s Interface }');
  Output.Add('');
  for I := 0 to DTDFile.Elements.Count - 1 do
    if DTDFile.Elements[I] = DTDFile.Root then
      CreateRootElementInterface(DTDFile.Elements[I], Output)
    else if DTDFile.Elements[I].Elements.Count > 0 then
    begin
      CreateElementInterface(DTDFile.Elements[I], Output);
      CreateElementListInterface(DTDFile.Elements[I], Output);
    end;
  CreateMainLoadFunctionInterface(DTDFile, Output);
  Output.Add('implementation');
  Output.Add('');
  for I := 0 to DTDFile.Elements.Count - 1 do
    if DTDFile.Elements[I] = DTDFile.Root then
      CreateRootElementImplementation(DTDFile.Elements[I], Output)
    else if DTDFile.Elements[I].Elements.Count > 0 then
    begin
      CreateElementImplementation(DTDFile.Elements[I], Output);
      CreateElementListImplementation(DTDFile.Elements[I], Output);
    end;
  Output.Add('{ *** }');
  Output.Add('');
  CreateMainLoadFunctionImplementation(DTDFile, Output);
  Output.Add('end.');
end;

end.

