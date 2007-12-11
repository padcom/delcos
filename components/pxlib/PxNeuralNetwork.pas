// ----------------------------------------------------------------------------
// Unit        : PxNeuralNetwork.pas - a part of PxLib
// Author      : Matthias Hryniszak (based on NeuralNetwork.pas by 
//                                   Maciej Lubiñski)
// Date        : 2003-xx-xx
// Version     : 1.0
// Description : Neural network implementation
// Changes log : 2003-xx-xx - initial version
//               2005-06-15 - imported to PxLib
// ToDo        : Testing.
// ----------------------------------------------------------------------------

unit PxNeuralNetwork;

{$I PxDefines.inc}

interface

uses
  Classes, SysUtils, Math;

const
  NET_FILE_ID: Integer = $0987ABCD; // ID pliku sieci

type
  TPxNeuralNetwork = class;
  TPxNNLayer = class;

  TPxNNBaseObject = class (TObject)
  protected
    Network: TPxNeuralNetwork;
  public
    constructor Create(ANetwork: TPxNeuralNetwork); virtual;
  end;

  { klasa wagi wejscia do komórki }
  TPxNNWeight = class (TPxNNBaseObject)
    Weight : Double;
    constructor Create(ANetwork: TPxNeuralNetwork); override;
    procedure Init;
  end;

  { komorka sieci }
  TPxNNCell = class (TPxNNBaseObject)
  protected
    { aktywacja komórki }
    Activity: Double;
    { wyjscie komorki }
    Output: Double;
  public
    constructor Create(ANetwork: TPxNeuralNetwork); override;
    { wyliczenie aktywacji i wyjscia komorki }
    procedure Evaluate; virtual; abstract;
    { odczyt danych komorki ze strumienia }
    procedure LoadFromStream(S: TStream); virtual; abstract;
    { zapis danych komorki do strumienia }
    procedure SaveToStream(S: TStream); virtual; abstract;
  end;

  { komorka warstwy wejsciowej }
  TPxNNInputCell = class (TPxNNCell)
  protected
    MinInput: Double;
    Scale: Double;
    { normalizacja wejscia }
    function Normalize(Value: Double): Double;
  public
    constructor Create(ANetwork: TPxNeuralNetwork); override;
    { wyliczenie aktywacji i wyjscia komorki }
    procedure Evaluate; override;
    { ustawienie wejscia }
    procedure SetInput(Input: Double);
    { ustawienie wartosci minimalnej i maksymalnej wejsc }
    procedure SetMinMaxInput(Min, Max: Double);
    { odczyt danych komorki ze strumienia }
    procedure LoadFromStream(S: TStream); override;
    { zapis danych komorki do strumienia }
    procedure SaveToStream(S: TStream); override;
  end;

  { komorka sieci (do propagacji wstecznej bledu) }
  TPxNNBackPCell = class (TPxNNCell)
  private
    { poprzednia warstwa komorek }
    FPreviousLayer : TPxNNLayer;
  protected
    { blad komorki }
    Delta: Double;
    { wagi dochodz¹ce do komórki }
    Weights: TList;
    OldWeights: TList;
    { funkcja aktywacji komorki }
    function ActivityFunction(AActivity: Double): Double;
    { wyliczenie bledu komorki }
    procedure EvaluateDelta; virtual; abstract;
  public
    constructor Create(ANetwork: TPxNeuralNetwork; WeightCount: Integer); reintroduce;
    destructor Destroy; override;
    { propagacja bledu }
    procedure BackPropagate;
    { wyliczenie aktywacji i wyjscia komorki }
    procedure Evaluate; override;
    { ustawienie poprzedniej warstwy }
    procedure SetPreviousLayer(PreviousLayer: TPxNNLayer);
    { odczyt danych komorki ze strumienia }
    procedure LoadFromStream(S: TStream); override;
    { zapis danych komorki do strumienia }
    procedure SaveToStream(S: TStream); override;
  end;

  { komorka warstwy ukrytej }
  TPxNNHideCell = class (TPxNNBackPCell)
  private
    { nastepna warstwa sieci }
    FNextLayer: TPxNNLayer;
    { indeks komorki w warstwie }
    FMyIndex: Integer;
  public
    constructor Create(ANetwork: TPxNeuralNetwork; WeightCount, Index: Integer); reintroduce;
    { wyliczenie bledu komorki }
    procedure EvaluateDelta; override;
    { ustawienie nastepnej warstwy }
    procedure SetNextLayer(NextLayer: TPxNNLayer);
    { odczyt danych komorki ze strumienia }
    procedure LoadFromStream(S: TStream); override;
    { zapis danych komorki do strumienia }
    procedure SaveToStream(S: TStream); override;
  end;

  { komorka warstwy wyjsciowej }
  TPxNNOutputCell = class (TPxNNBackPCell)
  protected
    MinOutput: Double;
    Scale: Double;
    { oczekiwana wartosc wyjscia i wyjscie po skalowaniu }
    ExpectOutput: Double;
    { wyliczenie bledu komorki }
    procedure EvaluateDelta; override;
  public
    constructor Create(ANetwork: TPxNeuralNetwork; WeightCount: Integer); reintroduce;
    { blad kwadratowy komorki }
    function GetDeviation: Double;
    { Wyjscie Skalowane  }
    function GetOutput: Double;
    { ustawienie wartosci oczekiwanego wyjscia }
    procedure SetExpectOutput(Output: Double);
    { ustawienie min i max wartosci wyjscia }
    procedure SetMinMaxOutput(Min, Max: Double);
    { odczyt danych komorki ze strumienia }
    procedure LoadFromStream(S: TStream); override;
    { zapis danych komorki do strumienia }
    procedure SaveToStream(S: TStream); override;
  end;

  { warstwa komorek }
  TPxNNLayer = class (TPxNNBaseObject)
  protected
    function CreateEmptyCell: TPxNNCell; virtual; abstract;
  public
    { komorki w warstwie }
    Cells: TList;
    constructor Create(ANetwork: TPxNeuralNetwork); override;
    destructor Destroy; override;
    { wyliczenie aktywacji i wyjscia komorek w warstwie }
    procedure Evaluate;
    { odczyt danych warstwy ze strumienia }
    procedure LoadFromStream(S: TStream); virtual;
    { zapis danych warstwy do strumienia }
    procedure SaveToStream(S: TStream); virtual;
  end;

  { warstwa wejsciowa }
  TPxNNInputLayer = class (TPxNNLayer)
  protected
    function CreateEmptyCell: TPxNNCell; override;
  public
    constructor Create(ANetwork: TPxNeuralNetwork; CellsCount: Integer); reintroduce;
    { ustawienie wejscia o indeksie }
    procedure SetInputs(Inputs: array of Double);
    { ustawienie min i max wartosci wejscia komorce index }
    procedure SetMinMaxInputAt(Index: Integer; Min, Max: Double);
  end;

  { warstwa sieci (do propagacji wstecznej bledu) }
  TPxNNBackPLayer = class (TPxNNLayer)
    { wsteczna propagacja bledu }
    procedure BackPropagate;
    { ustawienie poprzedniej warstwy }
    procedure SetPreviousLayer(APreviousLayer: TPxNNLayer);
  end;

  { warstwa komorek ukrytych }
  TPxNNHideLayer = class (TPxNNBackPLayer)
  protected
    function CreateEmptyCell: TPxNNCell; override;
  public
    constructor Create(ANetwork: TPxNeuralNetwork; CellsCount, WeightCount: Integer); reintroduce;
    { ustawienie nastepnej warstwy }
    procedure SetNextLayer(ANextLayer: TPxNNLayer);
  end;

  { warstwa komorek ukrytych }
  TPxNNOutputLayer = class (TPxNNBackPLayer)
  protected
    function CreateEmptyCell: TPxNNCell; override;
  public
    constructor Create(ANetwork: TPxNeuralNetwork; CellsCount, WeightsCount: Integer); reintroduce;
    { blad kwadratowy wyjscia }
    function GetDeviation: Double;
    { wyjscie warstwy }
    function GetOutput(Index: Integer): Double;
    { ustawienie wyjsc }
    procedure SetOutputs(Outputs: array of Double);
    { ustawienie min i max wartosci wyjscia komorki z warstwy }
    procedure SetMinMaxOutputAt(Index: Integer; Min, Max: Double);
  end;

  { Siec neuronowa }
  TPxNeuralNetwork = class (TObject)
  private
    FLayers: TList;
    FNi: Double;
    FAlpha: Double;
    function GetDeviation: Double; virtual;
    function GetOutput(Index: Integer): Double;
  public
    constructor Create(CountIn: Integer; HiddenLayers: array of Integer; CountOut: Integer);
    destructor Destroy; override;
    { wsteczna propagacja bledu }
    procedure BackPropagate;
    { obliczenie aktywacji komorek w warstwach }
    procedure Evaluate;
    { ustawienie min i max wartosci wejscia komorce index z warstwy wejsciowej }
    procedure SetMinMaxInputAt(Index: Integer; Min, Max: Double);
    { ustawienie min i max wartosci wyjscia komorki index z warstwy wyjsciowej }
    procedure SetMinMaxOutputAt(Index: Integer; Min, Max: Double);
    { ustawienie wejsc }
    procedure SetInputs(Inputs: array of Double);
    { ustawienie wyjsc }
    procedure SetOutputs(Outputs: array of Double);
    { obsluga zapisu i odczytu z pliku }
    procedure LoadFromFile(FileName: String);
    procedure SaveToFile(FileName: String);
    { blad sieci }
    property Deviation: Double read GetDeviation;
    { wyjscie sieci }
    property Output[Index: Integer]: Double read GetOutput;
    { wspolczynniki uczenia sie sieci }
    property Alpha: Double read FAlpha write FAlpha;
    property Ni: Double read FNi write FNi;
  end;

implementation

const
//   OUT_MRG = 0.0;
//   IN_MRG  = 0.05;
   IN_MRG  = 0.025;
   OUT_MRG = 0.05;

{ TPxNNWeight }

constructor TPxNNWeight.Create(ANetwork: TPxNeuralNetwork);
begin
  inherited Create(ANetwork);
  Weight := 0.0;
end;

procedure TPxNNWeight.Init;
const
  Gen = 19423;
begin
  Weight := Random(Gen) / Gen - 0.5;
  Weight := -Weight;
end;

{ TPxNNBaseObject }

constructor TPxNNBaseObject.Create(ANetwork: TPxNeuralNetwork);
begin
  inherited Create;
  Network := ANetwork;
end;

{ TPxNNCell }

constructor TPxNNCell.Create(ANetwork: TPxNeuralNetwork);
begin
  inherited Create(ANetwork);
  Activity := 0.5 - Random;
end;

{ TPxNNInputCell }

{ Protected declarations }

function TPxNNInputCell.Normalize(Value: Double): Double;
begin
  Result := (Value - MinInput) * Scale;
end;

{ Public declarations }

constructor TPxNNInputCell.Create(ANetwork: TPxNeuralNetwork);
begin
  inherited Create(ANetwork);
  MinInput := 0.0;
  Scale := 1.0;
end;

procedure TPxNNInputCell.Evaluate;
begin
  Output := Normalize(Activity);
end;

procedure TPxNNInputCell.SetInput(Input: Double);
begin
  Activity := Input;
end;

procedure TPxNNInputCell.SetMinMaxInput(Min, Max: Double);
begin
  MinInput := Min - IN_MRG * (Max - Min);
  Scale := 1.0 / ((1.0 + 2 * IN_MRG) * (Max - Min));
end;

procedure TPxNNInputCell.LoadFromStream(S: TStream);
begin
  S.Read(MinInput, SizeOf(MinInput));
  S.Read(Scale, SizeOf(Scale));
end;

procedure TPxNNInputCell.SaveToStream(S: TStream);
begin
  S.Write(MinInput, SizeOf(MinInput));
  S.Write(Scale, SizeOf(Scale));
end;

{ TPxNNBackPCell }

{ Protected declarations }

function TPxNNBackPCell.ActivityFunction(AActivity: Double): Double;
begin
  Result := 1.0 / (1.0 + Exp(-AActivity));
end;

{ Public declarations }

constructor TPxNNBackPCell.Create(ANetwork: TPxNeuralNetwork; WeightCount: Integer);
var
  I: Integer;
  AWeight, OldWeight: TPxNNWeight;
begin
  inherited Create(ANetwork);
  FPreviousLayer := nil;
  Delta := 0.0;

  Weights := TList.Create;
  OldWeights := TList.Create;
  for I := 0 to WeightCount do
  begin
    AWeight := TPxNNWeight.Create(Network);
    AWeight.Init;
    OldWeight := TPxNNWeight.Create(Network);
    OldWeight.Weight := AWeight.Weight;
    Weights.Add(AWeight);
    OldWeights.Add(OldWeight);
  end;
end;

destructor TPxNNBackPCell.Destroy;
var
  I: Integer;
begin
  for I := 0 to OldWeights.Count - 1 do
    TObject(OldWeights[I]).Free;
  OldWeights.Free;
  for I := 0 to Weights.Count - 1 do
    TObject(Weights[I]).Free;
  Weights.Free;
  inherited Destroy;
end;

procedure TPxNNBackPCell.BackPropagate;
var
  I: Integer;
  D, T: Double;
begin
  EvaluateDelta;
  for I := 0 to FPreviousLayer.Cells.Count - 1 do
  begin
    T := Network.Alpha * (TPxNNWeight(Weights[I]).Weight - TPxNNWeight(OldWeights[I]).Weight);
    TPxNNWeight(OldWeights[i]).Weight := TPxNNWeight(Weights[I]).Weight;
    D := Network.Ni * Delta * TPxNNCell(FPreviousLayer.Cells[I]).Output;
    TPxNNWeight(Weights[I]).Weight := TPxNNWeight(Weights[I]).Weight + D + T;
  end;
  I := Weights.Count - 1;
  T := Network.Alpha * (TPxNNWeight(Weights[I]).Weight - TPxNNWeight(OldWeights[I]).Weight);
  TPxNNWeight(OldWeights[I]).Weight := TPxNNWeight(Weights[I]).Weight;
  D := Network.Ni * Delta;
  TPxNNWeight(Weights[I]).Weight := TPxNNWeight(Weights[I]).Weight + D + T;
end;

procedure TPxNNBackPCell.Evaluate;
var
  I: Integer;
begin
  I := FPreviousLayer.Cells.Count;
  Activity := TPxNNWeight(Weights[I]).Weight;
  for I := I - 1 downto 0 do
    Activity := Activity + TPxNNWeight(Weights[I]).Weight * TPxNNCell(FPreviousLayer.Cells[I]).Output;
  Output := ActivityFunction(Activity);
end;

procedure TPxNNBackPCell.SetPreviousLayer(PreviousLayer: TPxNNLayer);
begin
  FPreviousLayer := PreviousLayer;
end;

procedure TPxNNBackPCell.LoadFromStream(S: TStream);
var
  WeightsCount, I: Integer;
  AWeight, OldWeight: TPxNNWeight;
begin
  FPreviousLayer := nil;
  Delta := 0.0;

  Weights.Clear;
  OldWeights.Clear;
  S.Read(WeightsCount, Sizeof(WeightsCount));

  for I := 0 to WeightsCount - 1 do
  begin
    AWeight := TPxNNWeight.Create(Network);
    S.Read(AWeight.Weight, SizeOf(AWeight.Weight));
    OldWeight := TPxNNWeight.Create(Network);
    OldWeight.Weight := AWeight.Weight;
    Weights.Add(AWeight);
    OldWeights.Add(OldWeight);
  end;
end;

procedure TPxNNBackPCell.SaveToStream(S: TStream);
var
  WeightsCount: Integer;
  I : Integer;
begin
  WeightsCount := Weights.Count;
  S.Write(WeightsCount, Sizeof(WeightsCount));

  for I := 0 to WeightsCount - 1 do
    S.Write(TPxNNWeight(Weights[I]).Weight, SizeOf(TPxNNWeight(Weights[I]).Weight));
end;

{ TPxNNHideCell }

constructor TPxNNHideCell.Create(ANetwork: TPxNeuralNetwork; WeightCount, Index: Integer);
begin
  inherited Create(ANetwork, WeightCount);
  FMyIndex := Index;
end;

procedure TPxNNHideCell.EvaluateDelta;
var
  I: Integer;
  BackPCell: TPxNNBackPCell;
begin
  Delta := 0;
  for I := 0 to FNextLayer.Cells.Count - 1 do
  begin
    BackPCell := TPxNNBackPCell(FNextLayer.Cells[I]);
    Delta := Delta + BackPCell.Delta *
//   TPxNNWeight(BackPCell.Weights[MyIndex]).Weight;
     TPxNNWeight(BackPCell.OldWeights[FMyIndex]).Weight;
   end;
   Delta := Delta * Output * (1 - Output);
end;

procedure TPxNNHideCell.SetNextLayer(NextLayer: TPxNNLayer);
begin
  FNextLayer := NextLayer;
end;

procedure TPxNNHideCell.LoadFromStream(S: TStream);
begin
  FNextLayer := nil;
  S.Read(FMyIndex, SizeOf(FMyIndex));
  inherited LoadFromStream(S);
end;

procedure TPxNNHideCell.SaveToStream(S: TStream);
begin
  S.Write(FMyIndex, SizeOf(FMyIndex));
  inherited SaveToStream(S);
end;

{ TPxNNOutputCell }

{ Protected declarations }

procedure TPxNNOutputCell.EvaluateDelta;
begin
  Delta := (ExpectOutput - Output) * (1 - Output) * Output;
end;

{ Public declarations }

constructor TPxNNOutputCell.Create(ANetwork: TPxNeuralNetwork; WeightCount: Integer);
begin
  inherited Create(ANetwork, WeightCount);
  MinOutput := 0;
  Scale := 1;
end;

function TPxNNOutputCell.GetDeviation: Double;
begin
  Result := (Output - ExpectOutput) * (Output - ExpectOutput);
end;

function TPxNNOutputCell.GetOutput: Double;
begin
//   Result := Output / 10 + 1.0;//Ln( Output / (1.0 - Output) );
  Result := (Output / Scale) + MinOutput;
end;

procedure TPxNNOutputCell.SetExpectOutput(Output: Double);
begin
  ExpectOutput := (Output - MinOutput) * Scale;
//  (Outputa - 1) * 10; //ActivityFunction(Output);
end;

procedure TPxNNOutputCell.SetMinMaxOutput(Min, Max: Double);
begin
  MinOutput := Min - OUT_MRG * (Max - Min);
  Scale     := 1 / ((1 + 2 * OUT_MRG) * (Max - Min));
end;

procedure TPxNNOutputCell.LoadFromStream(S: TStream);
begin
  inherited LoadFromStream(S);
  S.Read(MinOutput, SizeOf(MinOutput));
  S.Read(Scale, SizeOf(Scale));
  ExpectOutput := 0;
end;

procedure TPxNNOutputCell.SaveToStream(S: TStream);
begin
  inherited SaveToStream(S);
  S.Write(MinOutput, SizeOf(MinOutput));
  S.Write(Scale, SizeOf(Scale));
end;

{ TPxNNLayer }

constructor TPxNNLayer.Create(ANetwork: TPxNeuralNetwork);
begin
  inherited Create(ANetwork);
  Cells := TList.Create;
end;

destructor TPxNNLayer.Destroy;
var
  I: Integer;
begin
  for I := 0 to Cells.Count - 1 do
    TObject(Cells[I]).Free;  
  Cells.Free;
  inherited Destroy
end;

procedure TPxNNLayer.Evaluate;
var
  I: Integer;
begin
  for I := 0 to Cells.Count - 1 do
    TPxNNCell(Cells[I]).Evaluate;
end;

procedure TPxNNLayer.LoadFromStream(S: TStream);
var
  CellsCount, I: Integer;
  Cell: TPxNNCell;
begin
  Cells.Clear;
  S.Read(CellsCount, SizeOf(CellsCount));

  for I := 0 to CellsCount - 1 do
  begin
    Cell := CreateEmptyCell;
    Cell.LoadFromStream(S);
    Cells.Add(Cell);
  end;
end;

procedure TPxNNLayer.SaveToStream(S: TStream);
var
  CellsCount, I: Integer;
begin
  CellsCount := Cells.Count;
  S.Write(CellsCount, SizeOf(CellsCount));
  for I := 0 to CellsCount - 1 do
    TPxNNCell(Cells[I]).SaveToStream(S);
end;

{ TPxNNInputLayer }

{ Protected declarations }

function TPxNNInputLayer.CreateEmptyCell: TPxNNCell;
begin
  Result := TPxNNInputCell.Create(Network);
end;

{ Public declarations }

constructor TPxNNInputLayer.Create(ANetwork: TPxNeuralNetwork; CellsCount: Integer);
var
  I: Integer;
begin
  inherited Create(ANetwork);
  for I := 1 to CellsCount do
    Cells.Add(TPxNNInputCell.Create(Network));
end;

procedure TPxNNInputLayer.SetInputs(Inputs: array of Double);
var
  I: Integer;
begin
  for I := 0 to Length(Inputs) - 1 do
    TPxNNInputCell(Cells[I]).SetInput(Inputs[I]);
end;

procedure TPxNNInputLayer.SetMinMaxInputAt(Index: Integer; Min, Max: Double);
begin
  TPxNNInputCell(Cells[Index]).SetMinMaxInput(Min, Max);
end;

{ TPxNNBackPLayer }

procedure TPxNNBackPLayer.BackPropagate;
var
  I: Integer;
begin
  for I := 0 to Cells.Count - 1 do
    TPxNNBackPCell(Cells[I]).BackPropagate;
end;

procedure TPxNNBackPLayer.SetPreviousLayer(APreviousLayer: TPxNNLayer);
var
  I: Integer;
begin
  for I := 0 to Cells.Count - 1 do
    TPxNNBackPCell(Cells[I]).SetPreviousLayer(APreviousLayer);
end;

{ TPxNNHideLayer }

{ Protected declarations }

function TPxNNHideLayer.CreateEmptyCell: TPxNNCell;
begin
  Result := TPxNNHideCell.Create(Network, 0, 0);
end;

{ Public declarations }

constructor TPxNNHideLayer.Create(ANetwork: TPxNeuralNetwork; CellsCount, WeightCount: Integer);
var
  I: Integer;
begin
  inherited Create(ANetwork);
  for I := 0 to CellsCount - 1 do
    Cells.Add(TPxNNHideCell.Create(Network, WeightCount, I));
end;

procedure TPxNNHideLayer.SetNextLayer(ANextLayer: TPxNNLayer);
var
  I: Integer;
begin
  for I := 0 to Cells.Count - 1 do
    TPxNNHideCell(Cells[I]).SetNextLayer(ANextLayer);
end;

{ TPxNNOutputLayer }

{ Protected declarations }

function TPxNNOutputLayer.CreateEmptyCell: TPxNNCell;
begin
  Result := TPxNNOutputCell.Create(Network, 0);
end;

{ Public declarations }

constructor TPxNNOutputLayer.Create(ANetwork: TPxNeuralNetwork; CellsCount, WeightsCount: Integer);
var
  I: Integer;
begin
  inherited Create(ANetwork);
  for I := 1 to CellsCount do
    Cells.Add(TPxNNOutputCell.Create(Network, WeightsCount));
end;

function TPxNNOutputLayer.GetDeviation: Double;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Cells.Count - 1 do
    Result := Result + TPxNNOutputCell(Cells[I]).GetDeviation;
end;

function TPxNNOutputLayer.GetOutput(Index: Integer): Double;
begin
  Result := TPxNNOutputCell(Cells[Index]).GetOutput;
end;

procedure TPxNNOutputLayer.SetOutputs(Outputs: array of Double);
var
  I: Integer;
begin
  for I := 0 to Length(Outputs) - 1 do
    TPxNNOutputCell(Cells[I]).SetExpectOutput(Outputs[I]);
end;

procedure TPxNNOutputLayer.SetMinMaxOutputAt(Index: Integer; Min, Max: Double);
begin
  TPxNNOutputCell(Cells[Index]).SetMinMaxOutput(Min, Max);
end;

{ TPxNeuralNetwork }

{ Private declarations }

function TPxNeuralNetwork.GetDeviation: Double;
begin
  Result := 0.5 * TPxNNOutputLayer(FLayers[FLayers.Count - 1]).GetDeviation;
end;

function TPxNeuralNetwork.GetOutput(Index: Integer): Double;
begin
  Result := TPxNNOutputLayer(FLayers[FLayers.Count - 1]).GetOutput(Index);
end;

{ Public declarations }

constructor TPxNeuralNetwork.Create(CountIn: Integer; HiddenLayers: array of Integer; CountOut: Integer);
var
  I: Integer;
begin
  inherited Create;
  { ustalenie domyslnych wspolczynnikow uczenia }
  FNi := 0.3;
  FAlpha := 0.7;
  Randomize;
  FLayers := TList.Create;
  { Warstwa wejsciowa }
  FLayers.Add(TPxNNInputLayer.Create(Self, CountIn));
//  { Pierwsza warstwa ukryta }
  { warstwy ukryte }
  for I := 0 to Length(HiddenLayers) - 1 do
  begin
    if I = 0 then
    begin
      FLayers.Add(TPxNNHideLayer.Create(Self, HiddenLayers[I], CountIn));
      TPxNNBackPLayer(FLayers[I + 1]).SetPreviousLayer(TPxNNLayer(FLayers[I]));
    end
    else
    begin
      FLayers.Add(TPxNNHideLayer.Create(Self, HiddenLayers[I], HiddenLayers[I - 1]));
      TPxNNBackPLayer(FLayers[I + 1]).SetPreviousLayer(TPxNNLayer(FLayers[I]));
      TPxNNHideLayer(FLayers[I]).SetNextLayer(TPxNNLayer(FLayers[I + 1]));
    end;
  end;
(*
  FLayers.Add(TPxNNHideLayer.Create(Self, CountHidden1, CountIn));
  TPxNNBackPLayer(FLayers[1]).SetPreviousLayer(TPxNNLayer(FLayers[0]));
  { Druga warstwa ukryta }
  FLayers.Add(TPxNNHideLayer.Create(Self, CountHidden2, CountHidden1));
  TPxNNBackPLayer(FLayers[2]).SetPreviousLayer(TPxNNLayer(FLayers[1]));
  TPxNNHideLayer(FLayers[1]).SetNextLayer(TPxNNLayer(FLayers[2]));
*)
  { Warstwa wyjsciowa }
  FLayers.Add(TPxNNOutputLayer.Create(Self, CountOut, HiddenLayers[Length(HiddenLayers) - 1]));
  TPxNNBackPLayer(FLayers[FLayers.Count - 1]).SetPreviousLayer(TPxNNLayer(FLayers[FLayers.Count - 2]));
  TPxNNHideLayer(FLayers[FLayers.Count - 2]).SetNextLayer(TPxNNLayer(FLayers[FLayers.Count - 1]));
end;

destructor TPxNeuralNetwork.Destroy;
var
  I: Integer;
begin
  for I := 0 to FLayers.Count - 1 do
    TObject(FLayers[I]).Free;
  FLayers.Free;
  inherited Destroy;
end;

procedure TPxNeuralNetwork.BackPropagate;
var
  I: Integer;
begin
  Evaluate;
  for I := FLayers.Count - 1 downto 1 do
    TPxNNBackPLayer(FLayers[I]).BackPropagate;
end;

procedure TPxNeuralNetwork.Evaluate;
var
  I: Integer;
begin
  for I := 0 to FLayers.Count - 1 do
    TPxNNLayer(FLayers[I]).Evaluate;
end;

procedure TPxNeuralNetwork.SetMinMaxInputAt(Index: Integer; Min, Max: Double);
begin
  TPxNNInputLayer(FLayers[0]).SetMinMaxInputAt(Index, Min, Max);
end;

procedure TPxNeuralNetwork.SetMinMaxOutputAt(Index: Integer; Min, Max: Double);
begin
  TPxNNOutputLayer(FLayers[FLayers.Count - 1]).SetMinMaxOutputAt(Index, Min, Max);
end;

procedure TPxNeuralNetwork.SetInputs(Inputs: array of Double);
begin
  TPxNNInputLayer(FLayers[0]).SetInputs(Inputs);
end;

procedure TPxNeuralNetwork.SetOutputs(Outputs: array of Double);
begin
  TPxNNOutputLayer(FLayers[FLayers.Count - 1]).SetOutputs(Outputs);
end;

procedure TPxNeuralNetwork.LoadFromFile(FileName: String);
var
  NeuronFile: TFileStream;
  LayersCount, I, ID: Integer;
  Layer: TPxNNLayer;
begin
  NeuronFile := TFileStream.Create(FileName, fmOpenRead );
  NeuronFile.Read(ID, SizeOf(ID));

  if ID = NET_FILE_ID then
  begin
    FLayers.Clear;
    NeuronFile.Read(LayersCount, SizeOf(LayersCount));

    { warstwa wejsciowa }
    Layer := TPxNNInputLayer.Create(Self, 0);
    Layer.LoadFromStream(NeuronFile);
    FLayers.Add(Layer);

    { warstwy ukryte }
    for I := 1 to LayersCount - 2 do
    begin
      Layer := TPxNNHideLayer.Create(Self, 0, 0);
      Layer.LoadFromStream(NeuronFile);
      FLayers.Add(Layer);
    end;

    { warstwa wyjsciowa }
    Layer := TPxNNOutputLayer.Create(Self, 0, 0);
    Layer.LoadFromStream(NeuronFile);
    FLayers.Add(Layer);

    for I := 1 to LayersCount - 2 do
    begin
      TPxNNHideLayer(FLayers[I]).SetPreviousLayer(TPxNNLayer(FLayers[I - 1]));
      TPxNNHideLayer(FLayers[I]).SetNextLayer(TPxNNLayer(FLayers[I + 1]));
    end;
    TPxNNOutputLayer(FLayers[LayersCount - 1]).SetPreviousLayer(TPxNNLayer(FLayers[LayersCount - 2]));
  end;

  NeuronFile.Free;
end;

procedure TPxNeuralNetwork.SaveToFile(FileName: String);
var
  NeuronFile: TFileStream;
  LayersCount, I: Integer;
begin
  NeuronFile := TFileStream.Create(FileName, fmCreate);
  NeuronFile.Write(NET_FILE_ID, SizeOf(NET_FILE_ID));

  LayersCount := FLayers.Count;
  NeuronFile.Write(LayersCount, SizeOf(LayersCount));
  for I := 0 to LayersCount - 1 do
    TPxNNLayer(FLayers[I]).SaveToStream(NeuronFile);

  NeuronFile.Free;
end;

end.

