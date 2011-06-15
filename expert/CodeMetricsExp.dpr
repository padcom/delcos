library CodeMetricsExp;

uses
  ShareMem,
  ToolsAPI,
  CodeMetrics in 'CodeMetrics.pas' {CodeMetrics.dfm},
  BaseWizard in 'BaseWizard.pas',
  CodeMetricsWizard in 'CodeMetricsWizard.pas',
  SourceComplexityCalculator in 'SourceComplexityCalculator.pas';

var
  FExpertIndex: Integer;

procedure FinalizeWizard;
begin
  (BorlandIDEServices as IOTAWizardServices).RemoveWizard(FExpertIndex);
end;

function InitWizard(const BorlandIDEServices: IBorlandIDEServices; RegisterProc: TWizardRegisterProc; var Terminate: TWizardTerminateProc): Boolean; stdcall;
begin
  Terminate := FinalizeWizard;
  RegisterProc(TCodeMetricsWizard.Create as IOTAWizard);
//  FExpertIndex := (BorlandIDEServices as IOTAWizardServices).AddWizard(THelloWizard.Create as IOTAWizard);
  Result := (FExpertIndex >= 0);
end;

exports
  InitWizard name WizardEntryPoint;

end.
