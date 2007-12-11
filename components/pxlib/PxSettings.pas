// ----------------------------------------------------------------------------
// Unit        : PxSettings - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2004-10-10
// Version     : 1.0
// Description ; Definition of file name to store settings
// Changes log ; 2004-10-10 - Initial version
//               2004-12-22 - Moved ConfigPath variable from Initialization
//                            to the interface section so that it'll be
//                            accesible for others
//               2005-03-31 - changed GetIniFile to IniFile for easier use.
//               2006-02-24 - added hierarchical retrieval of settings.
// ToDo        : Testing.
//               Consider implementing ReadSection and ReadSectionValues. 
// ----------------------------------------------------------------------------

unit PxSettings;

{$I PxDefines.inc}

interface

uses
  Classes, SysUtils, IniFiles;

type
  TPxIniFileList = class;

  //
  // The way settings are discovered is:
  //   1. Check to see if there's a application-specific config file with the
  //      queried value in it. If so then read the vaule and return it
  //   2. Check to see if there's a directory/application -specific
  //      configuration file with the value. If so then read and return it.
  //   3. Check to see if there's a config file within the application's folder
  //      with the specific queried value. If so then read and return it.
  //   4. Return the default value.
  //
  TPxIniFile = class (TIniFile)
  private
    FIniFiles: TPxIniFileList;
  protected
    procedure CreateIniFiles(Default, Ext: String); virtual;
    property IniFiles: TPxIniFileList read FIniFiles;
  public
    constructor Create(Default: String);
    destructor Destroy; override;
    function ReadString(const Section, Ident, Default: string): string; override;
    procedure WriteString(const Section, Ident, Value: String); override;
  end;

  TPxIniFileList = class (TList)
  private
    function GetItem(Index: Integer): TCustomIniFile;
  public
    property Items[Index: Integer]: TCustomIniFile read GetItem; default;
  end;

//
// This procedure sets the global name of .ini file to look for.
// It requires the file name without path. If the given string contains path
// it will be truncated.
//
procedure SetIniFileName(Default: String);

//
// This function returns an instance of TPxIniFile for the application
//
function IniFile: TPxIniFile;

implementation

{ TPxIniFile }

{ Protected declarations }

procedure TPxIniFile.CreateIniFiles(Default, Ext: String);
begin
  //
  // most importand files goes first - least ones last
  //
  // Current folder:
  //   named after exe
  //   named after default (if differs from the one named after exe)
  // Executable folder:
  //   named after exe
  //   named after default (if differs from the one named after exe)
  // System folder:
  //   named after exe
  //   named after default (if differs from the one named after exe)
  //
  
  // application specific file in current folder
  IniFiles.Add(
    TIniFile.Create(Format('%s\%s', [
      GetCurrentDir,
      ChangeFileExt(ExtractFileName(ParamStr(0)), Ext)
    ]))
  );
  // check if a default file name is specified
  if Default <> '' then
  begin
    // default file in current folder
    if ExtractFileName(Default) <> ChangeFileExt(ExtractFileName(ParamStr(0)), Ext) then
      IniFiles.Add(TIniFile.Create(GetCurrentDir + '\' + ExtractFileName(Default)));
    // application-specific file in executable folder
    IniFiles.Add(TIniFile.Create(ChangeFileExt(ParamStr(0), Ext)));
    // default file in executable folder
    IniFiles.Add(TIniFile.Create(ExtractFilePath(ParamStr(0)) + ExtractFileName(Default)));
    // application-specific file in system (mostly C:\Windows) folder
    IniFiles.Add(TIniFile.Create(ChangeFileExt(ExtractFileName(ParamStr(0)), Ext)));
    // default file in system (mostly C:\Windows) folder
    IniFiles.Add(TIniFile.Create(ChangeFileExt(ExtractFileName(Default), Ext)));
  end
  else if GetCurrentDir <> ExtractFilePath(ParamStr(0)) then
  begin
    // application-specific file in executable folder
    IniFiles.Add(TIniFile.Create(ChangeFileExt(ParamStr(0), Ext)));
    // application-specific file in system (mostly C:\Windows) folder
    IniFiles.Add(TIniFile.Create(ChangeFileExt(ExtractFileName(ParamStr(0)), Ext)));
  end
  else
    // application-specific file in system (mostly C:\Windows) folder
    IniFiles.Add(TIniFile.Create(ChangeFileExt(ExtractFileName(ParamStr(0)), Ext)));
end;

{ Public declarations }

constructor TPxIniFile.Create(Default: String);
var
  Ext: String;
begin
  // normalize settings file extension
  if Default <> '' then
  begin
    Ext := ExtractFileExt(Default);
    if AnsiSameText(Ext, '.exe') or AnsiSameText(Ext, '.dll') then
      Default := ChangeFileExt(Default, '.ini');
    // determinate the extension of settings file (default: .ini)
    Ext := ExtractFileExt(Default);
    if Ext = '' then
      Ext := '.ini';
  end
  else
    Ext := '.ini';

  // use the calculated extension to compute default settings file
  inherited Create(GetCurrentDir + ChangeFileExt(ExtractFileName(ParamStr(0)), Ext));

  // create a list of ini files
  FIniFiles := TPxIniFileList.Create;
  CreateIniFiles(Default, Ext);
end;

destructor TPxIniFile.Destroy;
var
  I: Integer;
begin
  for I := 0 to IniFiles.Count - 1 do
    IniFiles[I].Free;
  FreeAndNil(FIniFiles);
  inherited Destroy;
end;

function TPxIniFile.ReadString(const Section, Ident, Default: string): string;
var
  I: Integer;
begin
  Result := Default;
  for I := 0 to IniFiles.Count - 1 do
    if IniFiles[I].ValueExists(Section, Ident) then
    begin
      Result := IniFiles[I].ReadString(Section, Ident, Default);
      Break;
    end;
end;

procedure TPxIniFile.WriteString(const Section, Ident, Value: String);
begin
  Assert(IniFiles.Count > 0, 'Error: no settings file in list');
  IniFiles[0].WriteString(Section, Ident, Value);
end;

{ TPxIniFileList }

{ Private declarations }

function TPxIniFileList.GetItem(Index: Integer): TCustomIniFile;
begin
  Result := TObject(Get(Index)) as TCustomIniFile;
end;

{ *** }

var
  _IniFile: TPxIniFile = nil;

procedure SetIniFileName(Default: String);
begin
  if Assigned(_IniFile) then
    FreeAndNil(_IniFile);
  _IniFile := TPxIniFile.Create(Default);
end;

function IniFile: TPxIniFile;
begin
  Result := _IniFile;
end;

{ *** }

initialization
{$IFDEF FPC}
  _IniFile := TPxIniFile.Create(ChangeFileExt(ParamStr(0), '.ini'));
{$ELSE}  
  _IniFile := TPxIniFile.Create('');
{$ENDIF}  

finalization
  FreeAndNil(_IniFile);

end.
