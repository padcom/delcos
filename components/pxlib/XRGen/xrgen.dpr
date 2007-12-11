program xrgen;

{$APPTYPE CONSOLE}

{$IFOPT D+}
  {$DEFINE DEBUG}
{$ELSE}
  {$UNDEF DEBUG}
{$ENDIF}

uses
  Classes, SysUtils,
  PxGetText in '..\PxGetText.pas',
  PxResources in '..\PxResources.pas',
  PxSettings in '..\PxSettings.pas',
  PxCommandLine in '..\PxCommandLine.pas',
  PxUtils in '..\PxUtils.pas',
  PxXmlReader in '..\PxXmlReader.pas',
  PxDTDFile in '..\PxDTDFile.pas',
  Options in 'Options.pas',
  Generator in 'Generator.pas';

{$IFDEF DEBUG}
procedure DumpDTD(Root: TDTDElement; Indent: String);
var
  I: Integer;
begin
  Writeln(Indent, Root.Name);
  for I := 0 to Root.Attributes.Count - 1 do
    Writeln(Indent, '- ', DTDAttributeToStr(Root.Attributes[I]));
  for I := 0 to Root.Elements.Count - 1 do
    DumpDTD(Root.Elements[I], Indent + '  ');
end;
{$ENDIF}

var
  DTD: TDTDFile;
  Output: TStrings;

begin
  DTD := TDTDFile.Create;
  try
    DTD := TDTDFile.Create;
    DTD.LoadFromFile('codes.dtd');
{$IFDEF DEBUG}
    DumpDTD(DTD.Root, '');
{$ENDIF}
    Output := TStringList.Create;
    try
      GenerateUnit(TOptions.Instance.UnitName, DTD, Output);
      Output.SaveToFile(TOptions.Instance.UnitName + '.pas');
    finally
      Output.Free;
    end;
  finally
    DTD.Free;
  end;
end.

