// ----------------------------------------------------------------------------
// Unit        : PxNdisProt.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2005-03-23
// Version     : 1.0
// Description : Interface to NDISPROT RAW ethernet protocol driver (from DDK)
// Changes log : 2005-03-23 - initial version
// ToDo        : Testing.
// ----------------------------------------------------------------------------
  
unit PxNdisProt;

{$I PxDefines.inc}

interface

uses
  Windows, SysUtils, Winsock,
{$IFDEF VER130}
  PxDelphi5, 
{$ENDIF}
  PxBase;

const
  //
  // Maximum Transfer Unit (the biggest packet there is possible to receive
  // and send - counted together with header!).
  //
  ETH_MTU = 1500;

type
  //
  // Ethernet address (binary representation)
  //
  TETHAddress  = array[0..5] of Byte;
  
  //
  // Protocol (TETHPacket.Header.Protocol field)
  //
  TETHProtocol = Word;

  //
  // Packet header. This is always received and MUST ALWAYS be send
  // if sending data through raw protocol!
  //
  TETHHeader = packed record
    Destination: TETHAddress;
    Source     : TETHAddress;
    Protocol   : TETHProtocol;
  end;

  // 
  // To make it easier to pack all the data here is a complete
  // definition of how the data "written" via ethernet protocol are
  // to be outlined.
  //
  PETHPacket = ^TETHPacket;
  TETHPacket = packed record
    Header: TETHHeader;
    Data  : array[0..ETH_MTU - SizeOf(TETHHeader) - 1] of Byte;
  end;

  IP_ADDR = UINT32;

  PIPFrame = ^TIPFrame;
  TIPFrame = packed record
    version_ihl      : UINT8;
    service_type     : UINT8;
    total_length     : UINT16;
    identification   : UINT16;
    flags_frag_offset: UINT16;
    ttl              : UINT8;
    protocol         : UINT8;
    checksum         : UINT16;
    source_addr      : IP_ADDR;
    dest_addr        : IP_ADDR;
  end;

  PUDPFrame = ^TUDPFrame;
  TUDPFrame = packed record
    sport            : UINT16; // Source port
    dport            : UINT16; // Destination port
    tlen             : UINT16; // Total len (UDP part)
    checksum         : UINT16; // Checksum
    BufIndex         : UINT16; // Data offsett from the start
  end;

const
  MAX_TCP_OPTLEN = 40;
  
type

  PTCPFrame = ^TTCPFrame;
  TTCPFrame = packed record
    sport            : UINT16; // Source port
    dport            : UINT16; // Destination port
    seqno            : UINT32; // Sequence number
    ackno            : UINT32; // Acknowledgement number
    hlen_flags       : UINT16; // Header length and flags
    window           : UINT16; // Size of window
    checksum         : UINT16; // TCP packet checksum
    urgent           : UINT16; // Urgent pointer
    opt              : array[0..MAX_TCP_OPTLEN + 1] of UINT8;// Option field
    BufIndex         : UINT16; // Next offset from the start of
  end;

//
// utility functions
//

// open a handle to the raw protocol and bind it into given device.
// device must be in form \DEVICE\{GUID}.
function NdisProtOpen(Device: PWideChar): THandle;
// closes a handle to the ndis protocol
function NdisProtClose(Handle: THandle): Boolean;
// check if there are some data to be received
function NdisProtDataAvaible(Handle: THandle): Boolean;
// wait until some data are to be received
function NdisProtWaitForData(Handle: THandle): Boolean;
// read data into the specified buffer
function NdisProtReadData(Handle: THandle; var Packet: TETHPacket): DWORD;
// write data from the specified buffer
function NdisProtWriteData(Handle: THandle; Source, Destination: TETHAddress; Protocol: TETHProtocol; var Buffer; BufferSize: DWORD): DWORD;
// convert a ethernet address to string
function EthAddressToString(Address: TETHAddress): String;
// convert a protocol to string
function EthProtocolToString(Protocol: Word): String;
// convert a string to ethernet address
function StringToEthAddress(S: String): TETHAddress;
// dump a given ethernet packet frame
function NdisProtDumpFrame(Packet: TETHPacket; DataSize: DWORD; DumpData: Boolean): Boolean;

implementation

const
  RAW_PROT_DEVICE: String = '\\.\\NdisProt';
  FILE_DEVICE_NETWORK = $00000012;
  FSCTL_NdisProt_BASE  = FILE_DEVICE_NETWORK;
  METHOD_BUFFERED     = 0;
  FILE_READ_ACCESS    = $0001;
  FILE_WRITE_ACCESS   = $0002;

function CTL_CODE(DeviceType, Func, Method, Access: WORD): DWORD;
begin
  Result := (DeviceType shl 16) or (Access shl 14) or (Func shl 2) or Method;
end;

function _NdisProt_CTL_CODE(Func, Method, Access: DWORD): DWORD;
begin
  Result := CTL_CODE(FSCTL_NdisProt_BASE, Func, Method, Access);
end;

function IOCTL_NdisProt_OPEN_DEVICE: DWORD;
begin
  Result := _NdisProt_CTL_CODE($200, METHOD_BUFFERED, FILE_READ_ACCESS or FILE_WRITE_ACCESS);
end;

function IOCTL_NdisProt_QUERY_OID_VALUE: DWORD;
begin
  Result := _NdisProt_CTL_CODE($201, METHOD_BUFFERED, FILE_READ_ACCESS or FILE_WRITE_ACCESS);
end;

function IOCTL_NdisProt_SET_OID_VALUE: DWORD;
begin
  Result := _NdisProt_CTL_CODE($205, METHOD_BUFFERED, FILE_READ_ACCESS or FILE_WRITE_ACCESS);
end;

function IOCTL_NdisProt_QUERY_BINDING: DWORD;
begin
  Result := _NdisProt_CTL_CODE($203, METHOD_BUFFERED, FILE_READ_ACCESS or FILE_WRITE_ACCESS);
end;

function IOCTL_NdisProt_BIND_WAIT: DWORD;
begin
  Result := _NdisProt_CTL_CODE($204, METHOD_BUFFERED, FILE_READ_ACCESS or FILE_WRITE_ACCESS);
end;

{ Utility functions }

function NdisProtOpen(Device: PWideChar): THandle;
var
  BytesReturned: DWORD;
begin
  //
  // Open the device
  //
  Result := CreateFile(PChar(RAW_PROT_DEVICE), GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if Result = INVALID_HANDLE_VALUE then
    Exit;

  //
  // Wait for the driver to finish binding.
  //
  if not DeviceIoControl(Result, IOCTL_NdisProt_BIND_WAIT, nil, 0, nil, 0, BytesReturned, nil) then
  begin
    CloseHandle(Result);
    Result := INVALID_HANDLE_VALUE;
  end;

  if not DeviceIoControl(Result, IOCTL_NdisProt_OPEN_DEVICE, Device, Length(Device) * SizeOf(WideChar), nil, 0, BytesReturned, nil) then
  begin
    CloseHandle(Result);
    Result := INVALID_HANDLE_VALUE;
  end;
end;

function NdisProtClose(Handle: THandle): Boolean;
begin
  Result := CloseHandle(Handle);
end;

function NdisProtDataAvaible(Handle: THandle): Boolean;
var
  Size: DWORD;
begin
  GetFileSize(Handle, @Size);
  Result := Size > 0;
  if Result then
    Beep;
//  Result := WaitForSingleObject(Handle, 0) = WAIT_OBJECT_0;
end;

function NdisProtWaitForData(Handle: THandle): Boolean;
begin
  Result := WaitForSingleObject(Handle, 0) = WAIT_OBJECT_0;
end;

function NdisProtReadData(Handle: THandle; var Packet: TETHPacket): DWORD;
begin
  Result := 0;
  ReadFile(Handle, Packet, SizeOf(Packet), Result, nil);
  if Result >= SizeOf(TETHHeader) then
  begin
    Packet.Header.Protocol := ntohs(Packet.Header.Protocol);
    Result := Result - SizeOf(TETHHeader);
  end;
end;

function NdisProtWriteData(Handle: THandle; Source, Destination: TETHAddress; Protocol: TETHProtocol; var Buffer; BufferSize: DWORD): DWORD;
var
  Packet: TETHPacket;
begin
  Result := 0;
  Packet.Header.Source := Source;
  Packet.Header.Destination := Destination;
  Packet.Header.Protocol := htons(Protocol);
  Move(Buffer, Packet.Data, BufferSize);
  WriteFile(Handle, Packet, BufferSize + SizeOf(TETHHeader), Result, nil);
end;

function EthAddressToString(Address: TETHAddress): String;
begin
  Result := Format('%.02x:%.02x:%.02x:%.02x:%.02x:%.02x', [
    Address[0],
    Address[1],
    Address[2],
    Address[3],
    Address[4],
    Address[5]
  ]);
end;

function EthProtocolToString(Protocol: Word): String;
begin
  case Protocol of
    $0800: Result := 'IP';
    $0806: Result := 'ARP';
    $8035: Result := 'RARP';
    else Result := Format('%.04x', [Protocol]);
  end;
end;

function IpProtocolToString(Protocol: Word): String;
begin
  case Protocol of
    1: Result := 'ICMP';
    6: Result := 'TCP';
    17: Result := 'UDP';
    else Result := Format('%.04x', [Protocol]);
  end;
end;

function StringToEthAddress(S: String): TETHAddress;
const
  INVALID_ETH_ADDRESS: TETHAddress = (255, 255, 255, 255, 255, 255);
var
  V1, V2, V3, V4, V5, V6: Integer;
begin
  if TryStrToInt('$' + S[1] + S[2], V1) and
     TryStrToInt('$' + S[4] + S[5], V2) and
     TryStrToInt('$' + S[7] + S[8], V3) and
     TryStrToInt('$' + S[10] + S[11], V4) and
     TryStrToInt('$' + S[13] + S[14], V5) and
     TryStrToInt('$' + S[16] + S[17], V6) then
  begin
    Result[0] := V1;
    Result[1] := V2;
    Result[2] := V3;
    Result[3] := V4;
    Result[4] := V5;
    Result[5] := V6;
  end
  else
    Result := INVALID_ETH_ADDRESS;
end;

const
  IP_UDP = 17;
  IP_TCP = 6;

function NdisProtDumpFrame(Packet: TETHPacket; DataSize: DWORD; DumpData: Boolean): Boolean;
var
  I, P: Integer;
  S: String;
  ip_frame: PIPFrame;
  udp: PUDPFrame;
begin
  Result := DataSize > 0;
  if DataSize > 0 then
  begin
    Writeln('S=', EthAddressToString(Packet.Header.Source), '  D=', EthAddressToString(Packet.Header.Destination), '  C=', DataSize, '  P=', EthProtocolToString(Packet.Header.Protocol));
    case Packet.Header.Protocol of
      $0800: // IP
      begin
        ip_frame := @Packet.Data;
        Writeln('IP : version_ihl      = ', ip_frame^.version_ihl);
        Writeln('IP : service_type     = ', ip_frame^.service_type);
        Writeln('IP : total_length     = ', ntohs(ip_frame^.total_length));
        Writeln('IP : identification   = ', ip_frame^.identification);
        Writeln('IP : flags_frag_offse = ', ip_frame^.flags_frag_offset);
        Writeln('IP : ttl              = ', ip_frame^.ttl);
        Writeln('IP : protocol         = ', IpProtocolToString(ip_frame^.protocol));
        Writeln('IP : checksum         = ', ip_frame^.checksum);
        Writeln('IP : source_addr      = ', PByteArray(@ip_frame^.source_addr)^[0], '.', PByteArray(@ip_frame^.source_addr)^[1], '.', PByteArray(@ip_frame^.source_addr)^[2], '.', PByteArray(@ip_frame^.source_addr)^[3]);
        Writeln('IP : dest_addr        = ', PByteArray(@ip_frame^.dest_addr)^[0], '.', PByteArray(@ip_frame^.dest_addr)^[1], '.', PByteArray(@ip_frame^.dest_addr)^[2], '.', PByteArray(@ip_frame^.dest_addr)^[3]);
        case ip_frame^.protocol of
          1: Writeln('    ICMP data not displayed');
          17:
          begin
            udp := Pointer(Integer(ip_frame) + SizeOf(TIPFrame));
            Writeln('UDP: sport            = ', ntohs(udp^.sport));
            Writeln('UDP: dport            = ', ntohs(udp^.dport));
            Writeln('UDP: tlen             = ', ntohs(udp^.tlen));
            Writeln('UDP: checksum         = ', ntohs(udp^.checksum));
            Writeln('UDP: BufIndex         = ', udp^.BufIndex);
          end;
        end;
      end;
    end;
    if DumpData and (DataSize > SizeOf(TETHHeader)) then
    begin
      // display content of this packet
      P := 0;
      for I := 0 to DataSize - 1 do
      begin
        if P = 0 then
          Write(Format('0x%.04x  ', [I]));
        Write(Format('%.02x ', [Packet.Data[I]]));
        if Packet.Data[I] > 32 then
          S := S + Chr(Packet.Data[I])
        else
          S := S + ' ';
        Inc(P);
        if P = 16 then
        begin
          Writeln('  ', S);
          S := '';
          P := 0;
        end;
      end;
      Writeln;
    end;
  end;
  Writeln;
end;

end.
