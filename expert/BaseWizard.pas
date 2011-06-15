unit BaseWizard;

interface

uses
  Windows, Classes, SysUtils, ToolsAPI;
  
type
  TBaseWizard = class(TNotifierObject, IOTAWizard, IOTANotifier)
  private
    FIDString: string;
    FName: string;
  protected
    // IOTAWizard
    function GetIDString: string; virtual;
    function GetName: string; virtual;
    function GetState: TWizardState; virtual;
    procedure Execute; virtual;
    //
    function GetEditor: IOTASourceEditor;
    procedure GetSource(Source: TStream);
  public
    constructor Create(IDString, Name: String);
  end;

implementation

{ TBaseWizard }

{ Private declarations }

{ Protected declarations }

function TBaseWizard.GetIDString: string; 
begin
  Result := FIDString;
end;

function TBaseWizard.GetName: string; 
begin
  Result := FName;
end;

function TBaseWizard.GetState: TWizardState;
begin
  Result := [];
end;

procedure TBaseWizard.Execute; 
begin
end;

function TBaseWizard.GetEditor: IOTASourceEditor;
var
  ModuleServices: IOTAModuleServices;
  Module: IOTAModule;
  Intf: IOTAEditor;
  I: Integer;
begin
  Result := nil;
  
  ModuleServices := BorlandIDEServices as IOTAModuleServices;
  // Get the module interface for the current file.
  Module := ModuleServices.CurrentModule;
  // If no file is open, Module is nil.
  if Module = nil then
    Exit;

  // Get the interface to the source editor.
  for I := 0 to Module.GetModuleFileCount-1 do
  begin
    Intf := Module.GetModuleFileEditor(I);
    if Intf.QueryInterface(IOTASourceEditor, Result) = S_OK then
      Break;
  end;
end;

procedure TBaseWizard.GetSource(Source: TStream);
var
  Editor: IOTASourceEditor;
  Reader: IOTAEditReader;
  Buffer: array[0..1023] of Char;
  Position, ReadLength: Integer;
begin
  Editor := GetEditor;
  Reader := Editor.CreateReader;

  Position := 0;
  repeat
    ReadLength := Reader.GetText(Position, PChar(@Buffer), SizeOf(Buffer));
    if ReadLength > 0 then
      Source.Write(Buffer, ReadLength);
    Position := Position + ReadLength;
  until ReadLength = 0;
end;

{ Public declarations }

constructor TBaseWizard.Create(IDString, Name: String);
begin
  Assert(IDString <> '', 'Error: IDString cannot be empty');
  Assert(Name <> '', 'Error: Name cannot be empty');
  inherited Create;
  FIDString := IDString;
  FName := Name;
end;

end.
