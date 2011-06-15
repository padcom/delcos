program UsageTrackerDemo;

uses
  FastMM4,
  Forms,
  DemoForm in 'DemoForm.pas' {fDemo};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfDemo, fDemo);
  Application.Run;
end.
