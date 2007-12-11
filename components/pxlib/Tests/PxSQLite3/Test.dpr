program Test;

{$APPTYPE CONSOLE}

uses
  Classes, SysUtils,
  PxSQLite3 in '..\..\PxSQLite3.pas';

function Res2Str(Res: Integer): String;
begin
  case Res of
    SQLITE_OK            : Result := 'Success';
    SQLITE_ERROR         : Result := 'SQL error or missing database';
    SQLITE_INTERNAL      : Result := 'An internal logic error in SQLite';
    SQLITE_PERM          : Result := 'Access permission denied';
    SQLITE_ABORT         : Result := 'Callback routine requested an abort';
    SQLITE_BUSY          : Result := 'The database file is locked';
    SQLITE_LOCKED        : Result := 'A table in the database is locked';
    SQLITE_NOMEM         : Result := 'A malloc() failed';
    SQLITE_READONLY      : Result := 'Attempt to write a readonly database';
    SQLITE_INTERRUPT     : Result := 'Operation terminated by sqlite3_interrupt(';
    SQLITE_IOERR         : Result := 'Some kind of disk I/O error occurred';
    SQLITE_CORRUPT       : Result := 'The database disk image is malformed';
    SQLITE_NOTFOUND      : Result := '(Internal Only) Table or record not found';
    SQLITE_FULL          : Result := 'Insertion failed because database is full';
    SQLITE_CANTOPEN      : Result := 'Unable to open the database file';
    SQLITE_PROTOCOL      : Result := 'Database lock protocol error';
    SQLITE_EMPTY         : Result := 'Database is empty';
    SQLITE_SCHEMA        : Result := 'The database schema changed';
    SQLITE_TOOBIG        : Result := 'Too much data for one row of a table';
    SQLITE_CONSTRAINT    : Result := 'Abort due to contraint violation';
    SQLITE_MISMATCH      : Result := 'Data type mismatch';
    SQLITE_MISUSE        : Result := 'Library used incorrectly';
    SQLITE_NOLFS         : Result := 'Uses OS features not supported on host';
    SQLITE_AUTH          : Result := 'Authorization denied';
    SQLITE_FORMAT        : Result := 'Auxiliary database format error';
    SQLITE_RANGE         : Result := '2nd parameter to sqlite3_bind out of range';
    SQLITE_NOTADB        : Result := 'File opened that is not a database file';
    SQLITE_ROW           : Result := 'sqlite3_step() has another row ready';
    SQLITE_DONE          : Result := 'sqlite3_step() has finished executing';
    else                   Result := Format('Unknown result (%d)', [Res]);
  end;
end;

var
  Row: Integer = 0;

function SelectCallback(User: Pointer; FieldCount: Integer; Data, Fields: PPChar): Integer; cdecl;
var
  I: Integer;
begin
  Write('Row=', Row, #9); Inc(Row);
  for I := 0 to FieldCount - 1 do
  begin
    Write(Fields^, '=', Data^);
    if I < FieldCount - 1 then
      Write(';')
    else
      Writeln;
    Inc(Fields);
    Inc(Data);
  end;
  Result := 0;
end;

var
  DB : psqlite3;
  Err: PChar;
  Res: Integer;

begin
  // Delete the database file if already exists
  if FileExists('test.db') then
  begin
    Write('Previous database exists - deleting...');
    DeleteFile('test.db');
    Writeln('Success');
  end;
  // 0. Query SQLite version
  Writeln('SQLite version ', sqlite3_libversion);
  // 1. Create database
  Writeln('Create database...', Res2Str(sqlite3_open('test.db', DB)));
  // 2. Begin transaction
  Writeln('Begin transaction...', Res2Str(sqlite3_exec(db, 'BEGIN TRANSACTION', nil, nil, @Err)));
  // 3. Create table
  Writeln('Create table...', Res2Str(sqlite3_exec(db, 'CREATE TABLE ttest (i INTEGER PRIMARY KEY, s TEXT)', nil, nil, @Err)));
  // 4. End transaction
  Writeln('End transaction...', Res2Str(sqlite3_exec(db, 'COMMIT', nil, nil, @Err)));
  // 5. Begin transaction
  Writeln('Begin transaction...', Res2Str(sqlite3_exec(db, 'BEGIN TRANSACTION', nil, nil, @Err)));
  // 6. Insert data
  Writeln('Insert data...', Res2Str(sqlite3_exec(db, 'INSERT INTO ttest VALUES (1, "ROW 1")', nil, nil, @Err)));
  Writeln('Insert data...', Res2Str(sqlite3_exec(db, 'INSERT INTO ttest VALUES (2, "ROW 2")', nil, nil, @Err)));
  Writeln('Insert data...', Res2Str(sqlite3_exec(db, 'INSERT INTO ttest VALUES (3, "ROW 3")', nil, nil, @Err)));
  // 7. End transaction
  Writeln('End transaction...', Res2Str(sqlite3_exec(db, 'COMMIT', nil, nil, @Err)));
  // 8. Query data
  Writeln('Query data...');
  Res := sqlite3_exec(db, 'SELECT * FROM ttest', @SelectCallback, nil, @Err);
  Writeln(Res2Str(Res));
  // 9. Close database
  Writeln('Close database...', Res2Str(sqlite3_close(DB)));
end.
