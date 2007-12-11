program Test;

{$APPTYPE CONSOLE}

uses
  Windows, Classes, SysUtils, Consts,
  PxGetText;

resourcestring
  SLabel1 = 'Form1';

begin
  LoadLanguageFile('default.po');
  Writeln(LoadResStringW(@SYesButton));
  Writeln(GetTextW('Form1'));
  Writeln(GetTextW('MS Sans Serif'));
  Writeln(GetTextW('Label1'));
  Writeln(GetTextW('Button1'));
  Writeln(GetTextW('GroupBox1'));
  Writeln(GetTextW('Action1'));
  Writeln(GetTextW('Action2'));
  Writeln(GetTextW('Action3'));
  Writeln(GetTextW('Action4'));
  Writeln(GetTextW('Action5'));
  Writeln('==================');

  UnloadAllLanguageFiles;

  LoadLanguageFile('default.mo.org');
  Writeln(GetTextW('Form1'));
  Writeln(GetTextW('MS Sans Serif'));
  Writeln(GetTextW('Label1'));
  Writeln(GetTextW('Button1'));
  Writeln(GetTextW('GroupBox1'));
  Writeln(GetTextW('Action1'));
  Writeln(GetTextW('Action2'));
  Writeln(GetTextW('Action3'));
  Writeln(GetTextW('Action4'));
  Writeln(GetTextW('Action5'));

  MessageBoxW(0, PWideChar(GetTextW('Form1')), 'Test of russian character set', 0);
  MessageBoxW(0, PWideChar(LoadResStringW(@SLabel1)), 'Test of russian character set', 0);
end.
