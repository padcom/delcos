program Test;

{$APPTYPE CONSOLE}

uses
  PxSerialPort;

var
  Serial: TPxSerialPort;
  Data: Byte;

begin
  Serial := nil;
  try
    Serial := TPxSerialPort.Create('COM1');
    Writeln(Serial.Timeout);
    Writeln(Serial.BaudRate);
    Serial.BaudRate := 38400;
    Writeln(Serial.BaudRate);
    Serial.Read(Data, 1);
  //  Serial.Stream.Read()
  except
    if Serial = nil then
      Writeln('Not created');
  end;
end.


