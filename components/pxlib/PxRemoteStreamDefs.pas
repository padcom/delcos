// ----------------------------------------------------------------------------
// Unit        : PxRemoteStreamDefs.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2005-02-01
// Version     : 1.0
// Description : Remote stream - definitions
// Changes log : 2005-02-01 - initial version
// ToDo        : Testing, comments in code.
// ----------------------------------------------------------------------------

unit PxRemoteStreamDefs;

{$I PxDefines.inc}

interface

uses
  Windows, Winsock, Classes, SysUtils,
{$IFDEF VER130}
  PxDelphi5,
{$ENDIF}  
  PxBase;
  
const
  PX_REMOTE_STREAM_PORT = 7010;

  PX_USER_SPACE_SIZE    = 1500-40-2;

  PX_RES_OK             = 0;
  PX_RES_ERROR          = 1;

  PX_CMD_OPEN           = 1;
  PX_CMD_SET_SIZE       = 2;
  PX_CMD_READ           = 3;
  PX_CMD_WRITE          = 4;
  PX_CMD_SEEK           = 5;
  PX_CMD_GET_FILE_AGE   = 6;
  PX_CMD_CLOSE          = 7;
  PX_CMD_DELETE         = 8;

type
  TPxRemoteStreamHeader = packed record
    Command : Word;
  end;

  TPxRemoteStreamPacket = packed record
    Command : Word;
    Data    : array[0..PX_USER_SPACE_SIZE-1] of Byte;
  end;

  PPxRemoteStreamResponse = ^TPxRemoteStreamResponse;
  TPxRemoteStreamResponse = packed record
    Header  : TPxRemoteStreamHeader;
  end;

  PPxRemoteStreamOpenFilePacket = ^TPxRemoteStreamOpenFilePacket;
  TPxRemoteStreamOpenFilePacket = packed record
    Header  : TPxRemoteStreamHeader;
    Mode    : Word;
    Backup  : Byte; // 0 - don't make a backup copy; 1 - make a backup copy 
    FileName: array[0..31] of Char;
  end;

  PPxRemoteStreamSetSizePacket = ^TPxRemoteStreamSetSizePacket;
  TPxRemoteStreamSetSizePacket = packed record
    Header  : TPxRemoteStreamHeader;
    NewSize : Int64;
  end;

  PPxRemoteStreamReadRequestPacket = ^TPxRemoteStreamReadRequestPacket;
  TPxRemoteStreamReadRequestPacket = packed record
    Header  : TPxRemoteStreamHeader;
    Count   : Int64;
  end;

  PPxRemoteStreamReadResponsePacket = ^TPxRemoteStreamReadResponsePacket;
  TPxRemoteStreamReadResponsePacket = packed record
    Header  : TPxRemoteStreamHeader;
    Count   : Int64;
    Data    : array[0..PX_USER_SPACE_SIZE-8-1] of Byte;
  end;

  PPxRemoteStreamWritePacket = ^TPxRemoteStreamWritePacket;
  TPxRemoteStreamWritePacket = packed record
    Header  : TPxRemoteStreamHeader;
    Count   : Int64;
    Data    : array[0..PX_USER_SPACE_SIZE-8-1] of Byte;
  end;

  PPxRemoteStreamWriteResponse = ^TPxRemoteStreamWriteResponse;
  TPxRemoteStreamWriteResponse = packed record
    Header  : TPxRemoteStreamHeader;
    Count   : Int64;
  end;

  PPxRemoteStreamSeekRequestPacket = ^TPxRemoteStreamSeekRequestPacket;
  TPxRemoteStreamSeekRequestPacket = packed record
    Header  : TPxRemoteStreamHeader;
    Offset  : Int64;
    Origin  : TSeekOrigin;
  end;

  PPxRemoteStreamSeekResponsePacket = ^TPxRemoteStreamSeekResponsePacket;
  TPxRemoteStreamSeekResponsePacket = packed record
    Header  : TPxRemoteStreamHeader;
    Offset  : Int64;
  end;

  PPxRemoteStreamGetFileAgeRequest = ^TPxRemoteStreamGetFileAgeRequest;
  TPxRemoteStreamGetFileAgeRequest = packed record
    Header  : TPxRemoteStreamHeader;
  end;

  PPxRemoteStreamGetFileAgeResponse = ^TPxRemoteStreamGetFileAgeResponse;
  TPxRemoteStreamGetFileAgeResponse = packed record
    Header  : TPxRemoteStreamHeader;
    FileAge : TDateTime;
  end;

  PPxRemoteStreamDeleteFilePacket = ^TPxRemoteStreamDeleteFilePacket;
  TPxRemoteStreamDeleteFilePacket = packed record
    Header  : TPxRemoteStreamHeader;
    Backup  : Byte; // 0 - don't make a backup copy; 1 - make a backup copy
    FileName: array[0..31] of Char;
  end;

type
  EPxRemoteStreamException = class (EPxException);

implementation

procedure Initialize;
var
  WSAData: TWSAData;
begin
  WSAStartup($101, WSAData);
end;

procedure Finalize;
begin
  WSACleanup;
end;

initialization
  Initialize;

finalization
  Finalize;

end.
