program delcos;

{$APPTYPE CONSOLE}

uses
  Classes, SysUtils, IniFiles,
  PascalParser,
  Options in 'cui\Options.pas',
  OptionsValidator in 'cui\OptionsValidator.pas',
  SourceTreeWalker in 'core\SourceTreeWalker.pas',
  SourceTreeDumperVisitor in 'core\SourceTreeDumperVisitor.pas',
  UnitRegistry in 'core\UnitRegistry.pas',
  CommentRemovalVisitor in 'core\CommentRemovalVisitor.pas',
  WhitespaceRemovalVisitor in 'core\WhitespaceRemovalVisitor.pas',
  IncludeParser in 'core\IncludeParser.pas',
  ProjectUnitsRegistratorVisitor in 'core\ProjectUnitsRegistratorVisitor.pas',
  UsesTreeBuilderVisitor in 'core\UsesTreeBuilderVisitor.pas',
  CyclomaticComplexityCalculatorVisitor in 'core\CyclomaticComplexityCalculatorVisitor.pas';

procedure DumpCyclomaticComplexity;
var
  Methods: TMethodList;
  Units: TStrings;
  I, J: Integer;
begin
  Units := TStringList.Create;
  try
    TUnitRegistry.Instance.GetProjectRegisteredUnitsNames(Units);
    for I := 0 to Units.Count - 1 do
    begin
      Methods := TMethodList.Create;
      try
        TSourceTreeWalker.Create.Walk(TUnitRegistry.Instance.UnitParser[Units[I]].Root, TCyclomaticComplexityCalculatorVisitor.Create(Methods) as INodeVisitor);
        for J := 0 to Methods.Count - 1 do
          Writeln(Units[I], '::', Methods[J].Name, '  (CC = ', Methods[J].CyclomaticComplexity, ')');
      finally
        Methods.Free;
      end;
    end;
  finally
    Units.Free;
  end;
end;

function ExtractUnitNameFromFileName(FileName: String): String;
begin
  Result := ExtractFileName(FileName);
  Result := Copy(Result, 1, Length(Result) - Length(ExtractFileExt(Result)));
end;

procedure DumpIncludes;
var
  I, J: Integer;
  Units, AllIncludes, Includes: TStrings;
begin
  AllIncludes := TStringList.Create;
  try
    Includes := TStringList.Create;
    try
      Units := TStringList.Create;
      try
        TUnitRegistry.Instance.GetAllRegisteredUnitsNames(Units);
        for I := 0 to Units.Count - 1 do
        begin
          TUnitRegistry.Instance.GetUnitIncludes(Units[I], Includes);
          for J := 0 to Includes.Count - 1 do
            if AllIncludes.IndexOf(UpperCase(Trim(Includes[J]))) = -1 then
              AllIncludes.Add(UpperCase(Trim(Includes[J])))
        end;
      finally
        Units.Free;
      end;
    finally
      Includes.Free;
    end;

    Write(AllIncludes.Text);
  finally
    AllIncludes.Free;
  end;
end;

var
  Output: TStrings;
  RootUnit: String;

begin
  with TSourceTreeWalker.Create do
  begin
    RootUnit := ExtractUnitNameFromFileName(TOptions.Instance.InputFile);
    TUnitRegistry.Instance.RegisterUnit(RootUnit, TOptions.Instance.InputFile, True);
    with TUnitRegistry.Instance.UnitParser[RootUnit] do
    begin
      Walk(Root, TProjectUnitsRegistratorVisitor.Create as INodeVisitor);

      Output := TStringList.Create;
      try
        if TOptions.Instance.DumpDebugTree then
          Walk(Root, TSourceTreeDumperVisitor.Create(Output) as INodeVisitor);
        if TOptions.Instance.DumpUsesTree then
        begin
          Walk(Root, TUsesTreeBuilderVisitor.Create(vmSimple, Output) as INodeVisitor);
          Write(Output.Text);
          DumpIncludes;
        end;
        if TOptions.Instance.DumpAdvancedUsesTree then
        begin
          Walk(Root, TUsesTreeBuilderVisitor.Create(vmFull, Output) as INodeVisitor);
          Write(Output.Text);
          DumpIncludes;
        end;

        if TOptions.Instance.DumpCyclomaticComplexity then
          DumpCyclomaticComplexity;
      finally
        Output.Free;
      end;
    end;
  end;
end.



