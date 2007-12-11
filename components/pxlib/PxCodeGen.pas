// ----------------------------------------------------------------------------
// Unit : CodeGen.pas
// Autor: Maciej "Padcom" Hryniszak
// Data : 2003-11-10 - pierwsza wersja pliku.
// Opis : Definicja podstawowych typów danych do wykorzystania w trakcie 
//        tworzenia generatora
//        kodu Ÿród³owego dla jêzyka Object Pascal.
// Uwagi: todo.
// ToDo : Opis, uwagi, sposób u¿ycia.
// ----------------------------------------------------------------------------

unit PxCodeGen;

interface

{$I PxDefines.inc}

uses
  Classes, SysUtils, PxXmlFile;

type
  EGeneratorException = class (Exception);
  
  TPxCGBaseList = class;
  TPxCGOutput = class;

  TPxCGBaseClass = class of TPxCGBase;

  TPxCGConditional = class (TObject)
  private
    FNames: TStrings;
  public
    constructor Create(ANames: array of String);
    destructor Destroy; override;
    property Names: TStrings read FNames;
  end;

  TPxCGObject = class (TObject)
  private
    FXMLItem: TPxXMLItem;
  protected
    function IsValidName(S: String): Boolean;
    function IsValidNumber(S: String): Boolean;
    procedure ReadParams; virtual;
  public
    constructor Create(AXmlItem: TPxXMLItem);
    property Xml: TPxXMLItem read FXmlItem;
  end;

  TPxCGBase = class (TPxCGObject)
  private
    FOwner: TPxCGBase;
    FItems: TPxCGBaseList;
  protected
    function CreateList(ItemName: String; ItemClass: TPxCGBaseClass): TPxCGBaseList;
    function GetTypeName(Prefix, Name, Suffix: String): String;
    function GetPTypeName(Prefix, Name, Suffix: String): String;
    procedure AddUnits(Output: TPxCGOutput); virtual;
    procedure AddRemarks(Output: TPxCGOutput); virtual;
  public
    constructor Create(AOwner: TPxCGBase; AXMLItem: TPxXMLItem); virtual;
    destructor Destroy; override;
    procedure CreateInterface(Output: TPxCGOutput); virtual;
    procedure CreateImplementation(Output: TPxCGOutput); virtual;
    property Owner: TPxCGBase read FOwner;
    property Items: TPxCGBaseList read FItems;
  end;

  TPxCGBaseList = class (TList)
  private
    function GetItem(Index: Integer): TPxCGBase;
  public
    property Items[Index: Integer]: TPxCGBase read GetItem; default;
  end;

  TPxCGOutput = class (TObject)
  private
    FLines: TStrings;
    FItems: TPxCGBaseList;
    FUsesList: TStrings;
    FRemarks: TStrings;
    FIdent: Integer;
    procedure OptimizeUsesList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddLine(S: String);
    procedure AddBegin;
    procedure AddEnd;
    procedure AddEndNoColone;
    procedure AddPrivate;
    procedure AddProtected;
    procedure AddPublic;
    procedure AddPublished;
    procedure DecIndent;
    procedure IncIndent;
    procedure GenerateFile(UnitName: String);
    property Lines: TStrings read FLines;
    property Items: TPxCGBaseList read FItems;
    property UsesList: TStrings read FUsesList;
    property Remarks: TStrings read FRemarks;
    property Ident: Integer read FIdent write FIdent;
  end;

implementation

{ TPxCGConditional }

constructor TPxCGConditional.Create(ANames: array of String);
var
  I: Integer;
begin
  inherited Create;
  FNames := TStringList.Create;
  for I := 0 to Length(ANames) - 1 do
    Names.Add(UpperCase(ANames[I]));
end;

destructor TPxCGConditional.Destroy;
begin
  FNames.Free;
  inherited Destroy;
end;

{ TPxCGObject }

{ Protected declarations }

function TPxCGObject.IsValidName(S: String): Boolean;
begin
  Result := (S <> '') and (UpCase(S[1]) in ['A'..'Z']) and (UpperCase(S) <> 'NAME') and (UpperCase(S) <> 'ASSTRING') and (UpperCase(S) <> 'ASINTEGER') and (UpperCase(S) <> 'ASFLOAT') and (UpperCase(S) <> 'ASBOOLEAN'){$IFDEF IDENT_RESOLVER} and (UpperCase(S) <> 'RECORDID'){$ENDIF};
end;

function TPxCGObject.IsValidNumber(S: String): Boolean;
begin
  Result := (S <> '') and (UpCase(S[1]) in ['0'..'9']);
end;

procedure TPxCGObject.ReadParams;
begin
end;

{ Public declarations }

constructor TPxCGObject.Create(AXmlItem: TPxXMLItem);
begin
  inherited Create;
  FXMLItem := AXmlItem;
end;

{ TPxCGBase }

{ Private declarations }

{ Protected declarations }

function TPxCGBase.CreateList(ItemName: String; ItemClass: TPxCGBaseClass): TPxCGBaseList;
var
  I: Integer;
  Item: TPxCGBase;
begin
  Result := TPxCGBaseList.Create;
  for I := 0 to Xml.ItemCount - 1 do
    if Xml.Items[I].IsItemName(ItemName) then
    begin
      Item := ItemClass.Create(Self, Xml.Items[I]);
      Result.Add(Item);
    end;
end;

function TPxCGBase.GetTypeName(Prefix, Name, Suffix: String): String;
begin
  Result := 'T' + Prefix + Name + Suffix;
end;

function TPxCGBase.GetPTypeName(Prefix, Name, Suffix: String): String;
begin
  Result := 'P' + Prefix + Name + Suffix;
end;

procedure TPxCGBase.AddUnits(Output: TPxCGOutput);
begin
end;

procedure TPxCGBase.AddRemarks(Output: TPxCGOutput);
begin
end;

{ Public declarations }

constructor TPxCGBase.Create(AOwner: TPxCGBase; AXMLItem: TPxXMLItem);
begin
  inherited Create(AXMLItem);
  FItems := TPxCGBaseList.Create;
  FOwner := AOwner;
  ReadParams;
  if Assigned(Owner) then
    Owner.Items.Add(Self);
end;

destructor TPxCGBase.Destroy;
var
  I: Integer;
begin
  for I := 0 to Items.Count - 1 do
    Items[I].Free;
  Items.Free;
  inherited Destroy;
end;

procedure TPxCGBase.CreateInterface(Output: TPxCGOutput);
begin
end;

procedure TPxCGBase.CreateImplementation(Output: TPxCGOutput);
begin
end;

{ TPxCGBaseList }

{ Private declarations }

function TPxCGBaseList.GetItem(Index: Integer): TPxCGBase;
begin
  Result := TObject(inherited Items[Index]) as TPxCGBase;
end;

{ TPxCGOutput }

{ Private declarations }

procedure TPxCGOutput.OptimizeUsesList;
var
  I, J: Integer;
  Changed: Boolean;
begin
  I := 0;
  while I < UsesList.Count do
  begin
    for J := I + 1 to UsesList.Count - 1 do
      if UpperCase(UsesList[I]) = UpperCase(UsesList[J]) then
      begin
        UsesList.Delete(J);
        Dec(I);
        Break;
      end;
    Inc(I);
  end;
  repeat
    Changed := False;
    for I := 0 to UsesList.Count - 2 do
      if ((not Assigned(UsesList.Objects[I])) and Assigned(UsesList.Objects[I + 1])) or
         (Assigned(UsesList.Objects[I]) and Assigned(UsesList.Objects[I + 1]) and (TPxCGConditional(UsesList.Objects[I]).Names.Text < TPxCGConditional(UsesList.Objects[I + 1]).Names.Text)) then
      begin
        UsesList.Exchange(I, I + 1);
        Changed := True;
      end;
  until not Changed;
end;

{ Public declarations }

constructor TPxCGOutput.Create;
begin
  inherited Create;
  FLines := TStringList.Create;
  FItems := TPxCGBaseList.Create;
  FUsesList := TStringList.Create;
  FRemarks := TStringList.Create;
end;

destructor TPxCGOutput.Destroy;
var
  I: Integer;
begin
  FRemarks.Free;
  for I := 0 to FUsesList.Count - 1 do
    if Assigned(FUsesList.Objects[I]) then
      FUsesList.Objects[I].Free;
  FUsesList.Free;
  FItems.Free;
  FLines.Free;
  inherited Destroy;
end;

procedure TPxCGOutput.AddLine(S: String);
var
  I: Integer;
begin
  for I := 1 to FIdent do
    S := '  ' + S;
  Lines.Add(S);
end;

procedure TPxCGOutput.DecIndent;
begin
  if FIdent > 0 then Dec(FIdent);
end;

procedure TPxCGOutput.IncIndent;
begin
  Inc(FIdent);
end;

procedure TPxCGOutput.AddBegin;
begin
  AddLine('begin');
  IncIndent;
end;

procedure TPxCGOutput.AddEnd;
begin
  DecIndent;
  AddLine('end;');
end;

procedure TPxCGOutput.AddEndNoColone;
begin
  DecIndent;
  AddLine('end');
end;

procedure TPxCGOutput.AddPrivate;
begin
  AddLine('private');
  IncIndent;
end;

procedure TPxCGOutput.AddProtected;
begin
  AddLine('protected');
  IncIndent;
end;

procedure TPxCGOutput.AddPublic;
begin
  AddLine('public');
  IncIndent;
end;

procedure TPxCGOutput.AddPublished;
begin
  AddLine('published');
  IncIndent;
end;

procedure TPxCGOutput.GenerateFile(UnitName: String);
var
  I, J: Integer;
  S: String;
  ActDef: String;
  ActCond: TPxCGConditional;
begin
  for I := 0 to Items.Count - 1 do
    Items[I].AddRemarks(Self);

  Lines.Add('unit ' + UnitName + ';');
  Lines.Add('');
  Lines.Add('{ --------------------------------------------------------------------------------------------');
  Lines.Add('  Unit   : ' + UnitName + '.pas');
  Lines.Add('  Author : Automatic Code Generator "' + ExtractFileName(ParamStr(0)) + '"');
  Lines.Add('  Data   : ' + FormatDateTime('YYYY-MM-DD, HH:MM', Now));
  Lines.Add('  Descr  : This unit is automatically generated using ' + ExtractFileName(ParamStr(0)) + '.');
  Lines.Add('  Remarks: DO NOT MODIFY BY HAND !');
  for I := 0 to Remarks.Count - 1 do
    Lines.Add('           ' + IntToStr(I + 1) + '. ' + Remarks[I]);
  Lines.Add(' -------------------------------------------------------------------------------------------- }');
  Lines.Add('');

  Lines.Add('interface');
  Lines.Add('');

  for I := 0 to Items.Count - 1 do
    Items[I].AddUnits(Self);

  OptimizeUsesList;
  S := ''; ActDef := ''; ActCond := nil;
  for I := 0 to UsesList.Count - 1 do
  begin
    if S <> '' then S := S + ', ';
    if (ActDef = '') and Assigned(UsesList.Objects[I]) then
    begin
      ActCond := TPxCGConditional(UsesList.Objects[I]);
      ActDef := ActCond.Names.Text;
      if S <> '' then S := S + #13#10;
      for J := 0 to ActCond.Names.Count - 1 do
        S := S + '{$IFDEF ' + ActCond.Names[J] + '}' + #13#10;
      S := S + '  ';
    end
    else if (ActDef <> '') and Assigned(UsesList.Objects[I]) and (TPxCGConditional(UsesList.Objects[I]).Names.Text <> ActDef) then
    begin
      for J := 0 to ActCond.Names.Count - 1 do
        S := S + #13#10 + '{$ENDIF}';
      ActCond := TPxCGConditional(UsesList.Objects[I]);
      ActDef := ActCond.Names.Text;
//      S := S + '{$IFDEF ' + ActDef + '}' + #13#10 + '  ';
      for J := 0 to ActCond.Names.Count - 1 do
        S := S + #13#10 + '{$IFDEF ' + ActCond.Names[J] + '}';
      S := S + #13#10 + '  ';
    end
    else if (ActDef <> '') and (not Assigned(UsesList.Objects[I])) then
    begin
      ActDef := '';
      for J := 0 to ActCond.Names.Count - 1 do
        S := S + #13#10 + '{$ENDIF}';
      S := S + #13#10 + '  ';
    end
    else if S = '' then S := '  ';
    S := S + UsesList[I];
  end;
  if ActDef <> '' then
    for J := 0 to ActCond.Names.Count - 1 do
      S := S + #13#10 + '{$ENDIF}';
  if S <> '' then
  begin
    Lines.Add('uses');
    Lines.Add(S + ';');
    Lines.Add('');
  end;
  for I := 0 to Items.Count - 1 do
  begin
    Items[I].CreateInterface(Self);
    Lines.Add('');
  end;

  Lines.Add('implementation');
  Lines.Add('');
  for I := 0 to Items.Count - 1 do
  begin
    Items[I].CreateImplementation(Self);
    Lines.Add('');
  end;

  Lines.Add('end.');
end;

end.

