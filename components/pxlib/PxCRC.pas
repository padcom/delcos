// ----------------------------------------------------------------------------
// Unit        : PxCRC.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2004-10-11
// Version     : 1.0
// Description : CRC computation routines.
// Changes log : 2004-10-11 - initial version
//               2005-03-29 - translated from C to pure Pascal because of the
//                            different object file formats (dcc and fpc)
// ToDo        : Testing.
// ----------------------------------------------------------------------------

unit PxCRC;

{$I PxDefines.inc}

interface

uses
  SysUtils;

// generates a CRC16 checksum from the given block of data
function CRCCompute(Data: Pointer; Count: LongWord): Word;

implementation

function CRCCompute(Data: Pointer; Count: LongWord): Word;
const
  POLYNOMINAL = $8005;
  INITIAL_REMAINDER = $0000;
  FINAL_XOR_VALUE = $0000;
  WIDTH = (8 * SizeOf(Word));
  TOPBIT = (1 shl (WIDTH - 1));
  CRCTable: array[0..255] of Word = (
    $0000, $8005, $800F, $000A, $801B, $001E, $0014, $8011, $8033, $0036, $003C, $8039, $0028, $802D, $8027, $0022,
    $8063, $0066, $006C, $8069, $0078, $807D, $8077, $0072, $0050, $8055, $805F, $005A, $804B, $004E, $0044, $8041,
    $80C3, $00C6, $00CC, $80C9, $00D8, $80DD, $80D7, $00D2, $00F0, $80F5, $80FF, $00FA, $80EB, $00EE, $00E4, $80E1,
    $00A0, $80A5, $80AF, $00AA, $80BB, $00BE, $00B4, $80B1, $8093, $0096, $009C, $8099, $0088, $808D, $8087, $0082,
    $8183, $0186, $018C, $8189, $0198, $819D, $8197, $0192, $01B0, $81B5, $81BF, $01BA, $81AB, $01AE, $01A4, $81A1,
    $01E0, $81E5, $81EF, $01EA, $81FB, $01FE, $01F4, $81F1, $81D3, $01D6, $01DC, $81D9, $01C8, $81CD, $81C7, $01C2,
    $0140, $8145, $814F, $014A, $815B, $015E, $0154, $8151, $8173, $0176, $017C, $8179, $0168, $816D, $8167, $0162,
    $8123, $0126, $012C, $8129, $0138, $813D, $8137, $0132, $0110, $8115, $811F, $011A, $810B, $010E, $0104, $8101,
    $8303, $0306, $030C, $8309, $0318, $831D, $8317, $0312, $0330, $8335, $833F, $033A, $832B, $032E, $0324, $8321,
    $0360, $8365, $836F, $036A, $837B, $037E, $0374, $8371, $8353, $0356, $035C, $8359, $0348, $834D, $8347, $0342,
    $03C0, $83C5, $83CF, $03CA, $83DB, $03DE, $03D4, $83D1, $83F3, $03F6, $03FC, $83F9, $03E8, $83ED, $83E7, $03E2,
    $83A3, $03A6, $03AC, $83A9, $03B8, $83BD, $83B7, $03B2, $0390, $8395, $839F, $039A, $838B, $038E, $0384, $8381,
    $0280, $8285, $828F, $028A, $829B, $029E, $0294, $8291, $82B3, $02B6, $02BC, $82B9, $02A8, $82AD, $82A7, $02A2,
    $82E3, $02E6, $02EC, $82E9, $02F8, $82FD, $82F7, $02F2, $02D0, $82D5, $82DF, $02DA, $82CB, $02CE, $02C4, $82C1,
    $8243, $0246, $024C, $8249, $0258, $825D, $8257, $0252, $0270, $8275, $827F, $027A, $826B, $026E, $0264, $8261,
    $0220, $8225, $822F, $022A, $823B, $023E, $0234, $8231, $8213, $0216, $021C, $8219, $0208, $820D, $8207, $0202);
var
  Offset: LongWord;
  B: Byte;
  Remainder: Word;
begin
  //
  // Set the initial remainder value
  //
  Remainder := INITIAL_REMAINDER;

  //
  // Divide the message by the polynominal, a bit at a time.
  //
  for Offset := 0 to Count - 1 do
  begin
    B := (Remainder shr (WIDTH - 8)) xor PByteArray(Data)^[Offset];
    Remainder := CRCTable[B] xor (Remainder shl 8);
  end;

  //
  // The final remainder is the CRC result
  //
  Result := Remainder xor FINAL_XOR_VALUE;
end;

end.

