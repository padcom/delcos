// ----------------------------------------------------------------------------
// Unit        : PxProfiler.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2005-03-22
// Version     : 1.0
// Description : A basic time/counter-based profiler.
// Changes log : 2005-03-22 - initial version
//               2005-03-23 - added counting the amount of call times.
// ToDo        : Testing.
// Suggestions : It's best to add all profiling code (calls to the SetItemMark
//               and the uses item) under the conditional define PROFILER 
//               so that profiling can be disabled at once. 
// ----------------------------------------------------------------------------

unit PxProfiler;

{$I PxDefines.inc}

interface

uses
  Windows, Classes, SysUtils, 
  PxResources;

type
  //
  // Profiler item.
  //
  TPxProfilerItem = class (TObject)
  private
    FName: String;
    FTotalTime: TDateTime;
    FLastTime: TDateTime;
    FMarkTime: TDateTime;
    FCounter: Double;
    function GetLastTimeStr: String;
    function GetTotalTimeStr: String;
    function GetCounter: Integer;
  public
    constructor Create(AName: String);
    // used to add a time slice to the element
    procedure AddTime(Time: TDateTime);
    // used to perform timing in a Mark-Mark base
    procedure SetTimeMark(Mark: TDateTime);
    // name of the profiler item
    property Name: String read FName;
    // last added time slice
    property LastTime: TDateTime read FLastTime;
    property LastTimeStr: String read GetLastTimeStr;
    // total time used by this item
    property TotalTime: TDateTime read FTotalTime;
    property TotalTimeStr: String read GetTotalTimeStr;
    // total count a procedure has been called
    property Counter: Integer read GetCounter;
  end;

  // 
  // A list of profiler items
  //
  TPxProfilerItemList = class (TList)
  private
    function GetItem(Index: Integer): TPxProfilerItem;
    function GetItemByName(Name: String): TPxProfilerItem;
  public
    property Items[Index: Integer]: TPxProfilerItem read GetItem; default;
    property ItemByName[Name: String]: TPxProfilerItem read GetItemByName; 
  end;

  //
  // Main profiler object
  //
  TPxProfiler = class (TObject)
  private
    FItems: TPxProfilerItemList;
    function GetTotalTime: TDateTime;
    function GetTotalTimeStr: String;
  public
    constructor Create;
    destructor Destroy; override;
    // add a time slice to the item identified by name
    procedure AddItemTime(Name: String; Time: TDateTime);
    // add a time slice to the item in a Mark-Mark base
    procedure SetItemMark(Name: String);
    // sort all items by time (most absorbing first)
    procedure SortItemsByTime;
    // sort all items by name (ASCII character order, case-insensitive)
    procedure SortItemsByName;
    // show profiling results in a console text window
    procedure DisplayProfilingResults;
    procedure DisplayProfilingResultsByTime;
    procedure DisplayProfilingResultsByName;
    // all profiler items
    property Items: TPxProfilerItemList read FItems;
    // total time used by profiled items
    property TotalTime: TDateTime read GetTotalTime;
    property TotalTimeStr: String read GetTotalTimeStr;
  end;

var
  Profiler: TPxProfiler = nil;

implementation

uses
  PxGetText;

{ TPxProfilerItem }

{ Private declarations }

function TPxProfilerItem.GetLastTimeStr: String;
begin
  Result := FormatDateTime('NN:SS:ZZZ', LastTime);
end;

function TPxProfilerItem.GetTotalTimeStr: String;
begin
  Result := FormatDateTime('NN:SS:ZZZ', TotalTime);
end;

function TPxProfilerItem.GetCounter: Integer;
begin
  Result := Trunc(FCounter);
end;
  
{ Public declarations }

constructor TPxProfilerItem.Create(AName: String);
begin
  inherited Create;
  FName := AName;
  FLastTime := 0;
  FTotalTime := 0;
  FCounter := 0;
end;

procedure TPxProfilerItem.AddTime(Time: TDateTime);
begin
  FLastTime := Time;
  FTotalTime := FTotalTime + Time;
  FCounter := FCounter + 1;
end;

procedure TPxProfilerItem.SetTimeMark(Mark: TDateTime);
begin
  if FMarkTime <> 0 then
  begin
    AddTime(Mark - FMarkTime);
    FMarkTime := 0;
  end
  else
    FMarkTime := Mark;
  FCounter := FCounter + 0.5;
end;

{ TPxProfilerItemList }

{ Private declarations }

function TPxProfilerItemList.GetItem(Index: Integer): TPxProfilerItem;
begin
  Result := TObject(Get(Index)) as TPxProfilerItem;
end;

function TPxProfilerItemList.GetItemByName(Name: String): TPxProfilerItem;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Count - 1 do
    if AnsiSameText(Items[I].Name, Name) then
    begin
      Result := Items[I];
      Break;
    end;
end;

{ Public declarations }

{ TPxProfiler }

{ Private declarations }

function TPxProfiler.GetTotalTime: TDateTime;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Items.Count - 1 do
    Result := Result + Items[I].TotalTime;
end;

function TPxProfiler.GetTotalTimeStr: String;
begin
  Result := FormatDateTime('NN:SS:ZZZ', TotalTime);
end;

{ Public declarations }

constructor TPxProfiler.Create;
begin
  inherited Create;
  FItems := TPxProfilerItemList.Create;
end;

destructor TPxProfiler.Destroy; 
var
  I: Integer;
begin
  for I := 0 to Items.Count - 1 do
    Items[I].Free;
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TPxProfiler.AddItemTime(Name: String; Time: TDateTime);
var
  TmpItem: TPxProfilerItem;
begin
  TmpItem := Items.ItemByName[Name];
  if TmpItem = nil then
    TmpItem := Items[Items.Add(TPxProfilerItem.Create(Name))];
  TmpItem.AddTime(Time)
end;

procedure TPxProfiler.SetItemMark(Name: String);
var
  TmpMark: TDateTime;
  TmpItem: TPxProfilerItem;
begin
  TmpMark := Now;
  TmpItem := Items.ItemByName[Name];
  if TmpItem = nil then
    TmpItem := Items[Items.Add(TPxProfilerItem.Create(Name))];
  // Hint: to minimize the time diferences caused by the GetItemByName function
  //       the actual time is taken twice according to the situation we are being
  //       called from.
  if TmpItem.FMarkTime <> 0 then
    TmpItem.SetTimeMark(TmpMark)
  else
    TmpItem.SetTimeMark(Now);
end;

function CompareItemsByTime(P1, P2: Pointer): Integer;
var
  Item1: TPxProfilerItem absolute P1;
  Item2: TPxProfilerItem absolute P2;
begin
  if Item1.TotalTime < Item2.TotalTime then Result := 1
  else if Item1.TotalTime > Item2.TotalTime then Result := -1
  else Result := 0;
end;

procedure TPxProfiler.SortItemsByTime;
begin
  Items.Sort(@CompareItemsByTime);
end;

function CompareItemsByName(P1, P2: Pointer): Integer;
var
  Item1: TPxProfilerItem absolute P1;
  Item2: TPxProfilerItem absolute P2;
begin
  Result := AnsiCompareText(Item1.Name, Item2.Name);
end;

procedure TPxProfiler.SortItemsByName;
begin
  Items.Sort(@CompareItemsByName);
end;

procedure TPxProfiler.DisplayProfilingResults;
  function GetStrLen(S: String; Len: Integer): String;
  begin
    while Length(S) < Len do
      S := S + ' ';
    Result := S;
  end;
var
  I: Integer;
begin
  if not IsConsole then
    AllocConsole;
  Writeln(LoadResString(@SProfilingResults));
  for I := 0 to Profiler.Items.Count - 1 do
    Writeln(GetStrLen(Profiler.Items[I].Name, 60), ': ', Profiler.Items[I].TotalTimeStr);
  Writeln('-----------------------------------------------------------------------');
  Writeln(GetStrLen(LoadResString(@STotalTime), 60), ': ', Profiler.TotalTimeStr);
end;

procedure TPxProfiler.DisplayProfilingResultsByTime;
begin
  SortItemsByTime;
  DisplayProfilingResults;
end;

procedure TPxProfiler.DisplayProfilingResultsByName;
begin
  SortItemsByName;
  DisplayProfilingResults;
end;

initialization
  Profiler := TPxProfiler.Create;

finalization
  FreeAndNil(Profiler);

end.
