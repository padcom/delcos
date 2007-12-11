program test;

{$APPTYPE CONSOLE}

uses
  SysUtils, PxXmlReader;

function TokenType2Str(TT: TPxXmlReaderTokenType): String;
begin
  case TT of
    xrtProcessingInstruction:
      Result := 'xrtProcessingInstruction';
    xrtDocumentType:
      Result := 'xrtDocumentType';
    xrtComment:
      Result := 'xrtComment';
    xrtCData:
      Result := 'xrtCData';
    xrtElementBegin:
      Result := 'xrtElementBegin';
    xrtElementEnd:
      Result := 'xrtElementEnd';
    xrtElementAttribute:
      Result := 'xrtElementAttribute';
    xrtText:
      Result := 'xrtText';
    xrtEof:
      Result := 'xrtEof';
  end;
end;

procedure DumpData(Reader: TPxXmlReader);
begin
  case Reader.TokenType of
    xrtProcessingInstruction:
    begin
      Writeln('Name     : ', Reader.Name);
      Writeln('Text     : ', Reader.Value);
      Writeln('Path     : ', Reader.ElementPath);
    end;
    xrtDocumentType:
    begin
      Writeln('Name     : ', Reader.Name);
      Writeln('Text     : ', Reader.Value);
      Writeln('Path     : ', Reader.ElementPath);
    end;
    xrtComment:
    begin
      Writeln('Name     : ', Reader.Name);
      Writeln('Text     : ', Reader.Value);
      Writeln('Path     : ', Reader.ElementPath);
    end;
    xrtCData:
    begin
      Writeln('Name     : ', Reader.Name);
      Writeln('Text     : ', Reader.Value);
      Writeln('Path     : ', Reader.ElementPath);
    end;
    xrtElementBegin:
    begin
      Writeln('Name     : ', Reader.Name);
      Writeln('Text     : ', Reader.Value);
      Writeln('Path     : ', Reader.ElementPath);
    end;
    xrtElementEnd:
    begin
      Writeln('Name     : ', Reader.Name);
      Writeln('Text     : ', Reader.Value);
      Writeln('Path     : ', Reader.ElementPath);
    end;
    xrtElementAttribute:
    begin
      Writeln('Name     : ', Reader.Name);
      Writeln('Text     : ', Reader.Value);
      Writeln('Path     : ', Reader.ElementPath);
    end;
    xrtText:
    begin
      Writeln('Name     : ', Reader.Name);
      Writeln('Text     : ', Reader.Value);
      Writeln('Path     : ', Reader.ElementPath);
    end;
    xrtEof:
    begin
      Writeln('End-Of-File');
    end;
  end;
end;

var
  Reader: TPxXmlReader;

begin
  Reader := TPxXmlReader.Create;
  try
    Reader.Open(ExtractFilePath(ParamStr(0)) + 'test.xml');
    while not Reader.EndOfXml do
    begin
      Writeln('TokenType: ', TokenType2Str(Reader.TokenType));
      DumpData(Reader);
      Reader.Next;
    end;
  finally
    Reader.Free;
  end;
  Readln;
end.
