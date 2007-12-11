// ----------------------------------------------------------------------------
// Unit        : PxDTDFile.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2006-06-16
// Version     : 1.0
// Description : Set of classes to read definitions from DTD file
// Changes log : 2006-06-16 - initial version
// ToDo        : Testing, comments in code.
// ----------------------------------------------------------------------------
  
unit PxDTDFile;

{$I PxDefines.inc}

interface

uses
  Classes, SysUtils, RegExpr;

const
  RX_DTD_ELEMENT   = '<!ELEMENT\s*(\w+)\s*\((.*?)\)>';
  RX_DTD_ATTRIBUTE = '<!ATTLIST\s*(\w+)\s*(\w+)\s*(([\w#]+)|(\([\w| ]+\)))\s*(.+?)>';

type
  TDTDElementList = class;

  TDTDAttributeType = (atCDATA, atValueSet, atID, atIDREF, atIDREFS, atNMTOKEN, atNMTOKENS, atENTITY, atENTITIES, atNOTATION);

  TDTDAttribute = class (TObject)
  private
    FName: String;
    FElementName: String;
    FAttributeType: TDTDAttributeType;
    FAttributeValues: TStrings;
    FDefaultValue: String;
    FImplied: Boolean;
    FRequired: Boolean;
    FFixed: Boolean;
    FFixedValue: String;
  public
    constructor Create;
    destructor Destroy; override;
    property Name: String read FName;
    property ElementName: String read FElementName;
    property AttributeType: TDTDAttributeType read FAttributeType;
    property AttributeValues: TStrings read FAttributeValues;
    property DefaultValue: String read FDefaultValue;
    property Implied: Boolean read FImplied;
    property Required: Boolean read FRequired;
    property Fixed: Boolean read FFixed;
    property FixedValue: String read FFixedValue;
  end;

  TDTDAttributeList = class (TList)
  private
    function GetItem(Index: Integer): TDTDAttribute;
  public
    property Items[Index: Integer]: TDTDAttribute read GetItem; default;
  end;

  TDTDElement = class (TObject)
  private
    FName: String;
    FDefinition: String;
    FElements: TDTDElementList;
    FAttributes: TDTDAttributeList;
    FOptional: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    property Name: String read FName;
    property Definition: String read FDefinition;
    property Elements: TDTDElementList read FElements;
    property Attributes: TDTDAttributeList read FAttributes;
    property Optional: Boolean read FOptional;
  end;

  TDTDElementList = class (TList)
  private
    function GetItem(Index: Integer): TDTDElement;
  public
    property Items[Index: Integer]: TDTDElement read GetItem; default;
  end;

  TDTDFile = class (TObject)
  private
    FRoot: TDTDElement;
    FElements: TDTDElementList;
    FAttributes: TDTDAttributeList;
  protected
    procedure ClearElements;
    procedure ClearAttributes;
    procedure LoadElements(Source: String);
    procedure LoadAttributes(Source: String);
    procedure ProcessDTDElement(Name, Definition: String);
    procedure ProcessDTDAttribute(ElementName, Name, Type_, Default: String);
    procedure ResolveRelations(Root: TDTDElement; Elements: TDTDElementList; Attributes: TDTDAttributeList);
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromFile(FileName: String);
    property Root: TDTDElement read FRoot;
    property Elements: TDTDElementList read FElements;
    property Attributes: TDTDAttributeList read FAttributes;
  end;

function DTDAttributeTypeToStr(Value: TDTDAttributeType): String;
{$IFDEF DEBUG}
function DTDAttributeToStr(Attribute: TDTDAttribute): String;
{$ENDIF}

implementation

{ TDTDAttribute }

{ Private declarations }

{ Public declarations }

constructor TDTDAttribute.Create;
begin
  inherited Create;
  FAttributeValues := TStringList.Create;
end;

destructor TDTDAttribute.Destroy;
begin
  FreeAndNil(FAttributeValues);
  inherited Destroy;
end;

{ TDTDAttributeList }

{ Private declarations }

function TDTDAttributeList.GetItem(Index: Integer): TDTDAttribute;
begin
  Result := TObject(Get(Index)) as TDTDAttribute;
end;

{ TDTDElement }

{ Private declarations }

{ Public declarations }

constructor TDTDElement.Create;
begin
  inherited Create;
  FElements := TDTDElementList.Create;
  FAttributes := TDTDAttributeList.Create;
end;

destructor TDTDElement.Destroy;
begin
  FreeAndNil(FAttributes);
  FreeAndNil(FElements);
  inherited Destroy;
end;

{ TDTDElementList }

{ Private declarations }

function TDTDElementList.GetItem(Index: Integer): TDTDElement;
begin
  Result := TObject(Get(Index)) as TDTDElement;
end;

{ TDTDFile }

{ Private declarations }

{ Protected declarations }

procedure TDTDFile.ClearElements;
var
  I: Integer;
begin
  for I := 0 to Elements.Count - 1 do
    Elements[I].Free;
  Elements.Clear;
  FRoot := nil;
end;

procedure TDTDFile.ClearAttributes;
var
  I: Integer;
begin
  for I := 0 to Attributes.Count - 1 do
    Attributes[I].Free;
  Attributes.Clear;
end;

procedure TDTDFile.ProcessDTDElement(Name, Definition: String);
var
  Element: TDTDElement;
begin
  Element := TDTDElement.Create;
  if Name[Length(Name)] = '?' then
  begin
    Element.FOptional := True;
    Delete(Name, Length(Name), 1);
  end
  else
    Element.FOptional := False;
  Element.FName := Name;
  Element.FDefinition := Definition;
  Elements.Add(Element);
  if Root = nil then
    FRoot := Element;
end;

procedure TDTDFile.ProcessDTDAttribute(ElementName, Name, Type_, Default: String);
var
  Attribute: TDTDAttribute;
begin
  Attribute := TDTDAttribute.Create;
  Attribute.FName := Name;
  Attribute.FElementName := ElementName;
  if Type_ = 'CDATA' then
    Attribute.FAttributeType := atCDATA
  else if Type_ = 'ID' then
    Attribute.FAttributeType := atID
  else if Type_ = 'IDREF' then
    Attribute.FAttributeType := atIDREF
  else if Type_ = 'IDREFS' then
    Attribute.FAttributeType := atIDREFS
  else if Type_ = 'NMTOKEN' then
    Attribute.FAttributeType := atNMTOKEN
  else if Type_ = 'NMTOKENS' then
    Attribute.FAttributeType := atNMTOKENS
  else if Type_ = 'ENTITY' then
    Attribute.FAttributeType := atENTITY
  else if Type_ = 'ENTITIES' then
    Attribute.FAttributeType := atENTITIES
  else if Type_ = 'NOTATION' then
    Attribute.FAttributeType := atNOTATION
  else if (Type_[1] = '(') and (Type_[Length(Type_)] = ')') then
  begin
    Delete(Type_, 1, 1);
    Delete(Type_, Length(Type_), 1);
    Attribute.FAttributeType := atValueSet;
    Attribute.FAttributeValues.Delimiter := '|';
    Attribute.FAttributeValues.DelimitedText := Type_;
  end
  else
    raise Exception.CreateFmt('Invalid attribute type %s', [Type_]);
  if Default = '#IMPLIED' then
    Attribute.FImplied := True
  else if Default = '#REQUIRED' then
    Attribute.FRequired := True
  else if Copy(Default, 1, 6) = '#FIXED' then
  begin
    Delete(Default, 1, 6);
    Default := Trim(Default);
    if (Default[1] = '"') and (Default[Length(Default)] = '"') then
    begin
      Delete(Default, 1, 1);
      Delete(Default, Length(Default), 1);
      Attribute.FFixed := True;
      Attribute.FFixedValue := Default;
    end
    else
      raise Exception.Create('Error: value in double quotes expected');
  end
  else if (Default[1] = '"') and (Default[Length(Default)] = '"') then
  begin
    Delete(Default, 1, 1);
    Delete(Default, Length(Default), 1);
    Attribute.FDefaultValue := Default;
  end;
  Attributes.Add(Attribute);
end;

procedure TDTDFile.LoadElements(Source: String);
var
  R: TRegExpr;
  Found: Boolean;
begin
  R := TRegExpr.Create;
  try
    R.Expression := RX_DTD_ELEMENT;
    Found := R.Exec(Source);
    while Found do
    begin
      ProcessDTDElement(R.Match[1], R.Match[2]);
      Found := R.ExecNext;
    end;
  finally
    R.Free;
  end;
end;

procedure TDTDFile.LoadAttributes(Source: String);
var
  R: TRegExpr;
  Found: Boolean;
begin
  R := TRegExpr.Create;
  try
    R.Expression := RX_DTD_ATTRIBUTE;
    Found := R.Exec(Source);
    while Found do
    begin
      ProcessDTDAttribute(R.Match[1], R.Match[2], R.Match[3], R.Match[6]);
      Found := R.ExecNext;
    end;
  finally
    R.Free;
  end;
end;

procedure TDTDFile.ResolveRelations(Root: TDTDElement; Elements: TDTDElementList; Attributes: TDTDAttributeList);
var
  I, J: Integer;
  Element: TDTDElement;
  SubElements: TStrings;
begin
  SubElements := TStringList.Create;
  try
    // subelements
    SubElements.Delimiter := ',';
    SubElements.DelimitedText := Root.Definition;
    for I := 0 to SubElements.Count - 1 do
    begin
      SubElements[I] := Trim(SubElements[I]);
      if (SubElements[I] <> '') and (SubElements[I] <> '#PCDATA') then
      begin
        Element := nil;
        for J := 0 to Elements.Count - 1 do
          if Elements[J].Name = Trim(SubElements[I]) then
          begin
            Element := Elements[J];
            Break;
          end;
        Assert(Element <> nil, 'Error: undefined element ' + SubElements[I]);
        Root.Elements.Add(Element);
      end;
    end;
  finally
    SubElements.Free;
  end;

  // attributes
  for I := 0 to Attributes.Count - 1 do
    if Attributes[I].ElementName = Root.Name then
      Root.Attributes.Add(Attributes[I]);
end;

{ Public declarations }

constructor TDTDFile.Create;
begin
  inherited Create;
  FElements := TDTDElementList.Create;
  FAttributes := TDTDAttributeList.Create;
end;

destructor TDTDFile.Destroy;
begin
  ClearAttributes;
  ClearElements;
  FreeAndNil(FAttributes);
  FreeAndNil(FElements);
  inherited Destroy;
end;

procedure TDTDFile.LoadFromFile(FileName: String);
var
  Source: TStrings;
  I: Integer;
begin
  ClearElements;
  Source := TStringList.Create;
  try
    Source.LoadFromFile(FileName);
    LoadElements(Source.Text);
    LoadAttributes(Source.Text);
  finally
    Source.Free;
  end;

  for I := 0 to Elements.Count - 1 do
    ResolveRelations(Elements[I], Elements, Attributes);
end;

{ *** }

function DTDAttributeTypeToStr(Value: TDTDAttributeType): String;
begin
  case Value of
    atCDATA:
      Result := 'CDATA';
    atValueSet:
      Result := 'ValueSet';
    atID:
      Result := 'ID';
    atIDREF:
      Result := 'IDREF';
    atIDREFS:
      Result := 'IDREFS';
    atNMTOKEN:
      Result := 'NMTOKEN';
    atNMTOKENS:
      Result := 'NMTOKENS';
    atENTITY:
      Result := 'ENTITY';
    atENTITIES:
      Result := 'ENTITIES';
    atNOTATION:
      Result := 'NOTATION';
  end;
end;

{$IFDEF DEBUG}
function DTDAttributeToStr(Attribute: TDTDAttribute): String;
var
  I: Integer;
begin
  Result := Format('%s::%s ', [Attribute.FElementName, Attribute.FName]);
  case Attribute.AttributeType of
    atCDATA:
    begin
      Result := Result + 'CDATA';
      if Attribute.DefaultValue <> '' then
        Result := Result + ' DEFAULT "' + Attribute.DefaultValue + '"';
    end;
    atValueSet:
    begin
      Result := Result + 'SET (';
      for I := 0 to Attribute.AttributeValues.Count - 1 do
      begin
        if I > 0 then
          Result := Result + '|';
        Result := Result + Attribute.AttributeValues[I];
      end;
      Result := Result + ')';
    end;
    atID:
      Result := Result + 'ID';
    atIDREF:
      Result := Result + 'IDREF';
    atIDREFS:
      Result := Result + 'IDREFS';
    atNMTOKEN:
      Result := Result + 'NMTOKEN';
    atNMTOKENS:
      Result := Result + 'NMTOKENS';
    atENTITY:
      Result := Result + 'ENTITY';
    atENTITIES:
      Result := Result + 'ENTITIES';
    atNOTATION:
      Result := Result + 'NOTATION';
  end;

  if Attribute.Implied then
    Result := Result + ' IMPLIED';
  if Attribute.Required then
    Result := Result + ' REQUIRED';
  if Attribute.Fixed then
    Result := Result + ' FIXED "' + Attribute.FixedValue + '"';
end;
{$ENDIF}

end.

