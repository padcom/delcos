// ----------------------------------------------------------------------------
// Unit        : PxAviWriter.pas - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2005-04-18
// Version     : 1.0
// Description : A class to create an AVI file from a list of bitmaps
// Changes log : 2005-04-18 - initial version
// ToDo        : Testing.
// ----------------------------------------------------------------------------

unit PxAviWriter;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Forms, ActiveX;

type
  // TAVIFileInfoW record
  LONG = LongInt;
  PVOID = Pointer;

const
  // TAVIFileInfo dwFlag values
  AVIF_HASINDEX = $00000010;
  AVIF_MUSTUSEINDEX = $00000020;
  AVIF_ISINTERLEAVED = $00000100;
  AVIF_WASCAPTUREFILE = $00010000;
  AVIF_COPYRIGHTED = $00020000;
  AVIF_KNOWN_FLAGS = $00030130;

  AVIERR_UNSUPPORTED = HRESULT($80044065); // MAKE_AVIERR(101)
  AVIERR_BADFORMAT = HRESULT($80044066); // MAKE_AVIERR(102)
  AVIERR_MEMORY = HRESULT($80044067); // MAKE_AVIERR(103)
  AVIERR_INTERNAL = HRESULT($80044068); // MAKE_AVIERR(104)
  AVIERR_BADFLAGS = HRESULT($80044069); // MAKE_AVIERR(105)
  AVIERR_BADPARAM = HRESULT($8004406A); // MAKE_AVIERR(106)
  AVIERR_BADSIZE = HRESULT($8004406B); // MAKE_AVIERR(107)
  AVIERR_BADHANDLE = HRESULT($8004406C); // MAKE_AVIERR(108)
  AVIERR_FILEREAD = HRESULT($8004406D); // MAKE_AVIERR(109)
  AVIERR_FILEWRITE = HRESULT($8004406E); // MAKE_AVIERR(110)
  AVIERR_FILEOPEN = HRESULT($8004406F); // MAKE_AVIERR(111)
  AVIERR_COMPRESSOR = HRESULT($80044070); // MAKE_AVIERR(112)
  AVIERR_NOCOMPRESSOR = HRESULT($80044071); // MAKE_AVIERR(113)
  AVIERR_READONLY = HRESULT($80044072); // MAKE_AVIERR(114)
  AVIERR_NODATA = HRESULT($80044073); // MAKE_AVIERR(115)
  AVIERR_BUFFERTOOSMALL = HRESULT($80044074); // MAKE_AVIERR(116)
  AVIERR_CANTCOMPRESS = HRESULT($80044075); // MAKE_AVIERR(117)
  AVIERR_USERABORT = HRESULT($800440C6); // MAKE_AVIERR(198)
  AVIERR_ERROR = HRESULT($800440C7); // MAKE_AVIERR(199)

type
  TAVIFileInfoW = record
    dwMaxBytesPerSec, // max. transfer rate
      dwFlags, // the ever-present flags
      dwCaps,
      dwStreams,
      dwSuggestedBufferSize,
      dwWidth,
      dwHeight,
      dwScale,
      dwRate, // dwRate / dwScale == samples/second
      dwLength,
      dwEditCount: DWORD;
    szFileType: array[0..63] of WideChar; // descriptive string for file type?
  end;
  PAVIFileInfoW = ^TAVIFileInfoW;

const
  // TAVIStreamInfo dwFlag values
  AVISF_DISABLED = $00000001;
  AVISF_VIDEO_PALCHANGES = $00010000;
  AVISF_KNOWN_FLAGS = $00010001;

type
  TAVIStreamInfoA = record
    fccType,
      fccHandler,
      dwFlags, // Contains AVITF_* flags
      dwCaps: DWORD;
    wPriority,
      wLanguage: WORD;
    dwScale,
      dwRate, // dwRate / dwScale == samples/second
      dwStart,
      dwLength, // In units above...
      dwInitialFrames,
      dwSuggestedBufferSize,
      dwQuality,
      dwSampleSize: DWORD;
    rcFrame: TRect;
    dwEditCount,
      dwFormatChangeCount: DWORD;
    szName: array[0..63] of AnsiChar;
  end;
  TAVIStreamInfo = TAVIStreamInfoA;
  PAVIStreamInfo = ^TAVIStreamInfo;

  TAVIStreamInfoW = record
    fccType,
      fccHandler,
      dwFlags, // Contains AVITF_* flags
      dwCaps: DWORD;
    wPriority,
      wLanguage: WORD;
    dwScale,
      dwRate, // dwRate / dwScale == samples/second
      dwStart,
      dwLength, // In units above...
      dwInitialFrames,
      dwSuggestedBufferSize,
      dwQuality,
      dwSampleSize: DWORD;
    rcFrame: TRect;
    dwEditCount,
      dwFormatChangeCount: DWORD;
    szName: array[0..63] of WideChar;
  end;

  PAVIStream = Pointer;
  PAVIFile = Pointer;
  TAVIStreamList = array[0..0] of PAVIStream;
  PAVIStreamList = ^TAVIStreamList;
  TAVISaveCallback = function(nPercent: Integer): LONG; stdcall;

  TAVICompressOptions = packed record
    fccType: DWORD;
    fccHandler: DWORD;
    dwKeyFrameEvery: DWORD;
    dwQuality: DWORD;
    dwBytesPerSecond: DWORD;
    dwFlags: DWORD;
    lpFormat: Pointer;
    cbFormat: DWORD;
    lpParms: Pointer;
    cbParms: DWORD;
    dwInterleaveEvery: DWORD;
  end;
  PAVICompressOptions = ^TAVICompressOptions;

const
  // Palette change data record
  RIFF_PaletteChange: DWORD = 1668293411;

type
  TAVIPalChange = packed record
    bFirstEntry: byte;
    bNumEntries: byte;
    wFlags: WORD;
    peNew: array[byte] of TPaletteEntry;
  end;
  PAVIPalChange = ^TAVIPalChange;

  APAVISTREAM = array[0..1] of PAVISTREAM;
  APAVICompressOptions = array[0..1] of PAVICompressOptions;

const
  AVIERR_OK = 0;

  AVIIF_LIST = $01;
  AVIIF_TWOCC = $02;
  AVIIF_KEYFRAME = $10;

  STREAMTYPEVIDEO = $73646976; // DWORD( 'v', 'i', 'd', 's' )
  STREAMTYPEAUDIO = $73647561; // DWORD( 'a', 'u', 'd', 's' )

type
  TPixelFormat = (pfDevice, pf1bit, pf4bit, pf8bit, pf15bit, pf16bit, pf24bit, pf32bit, pfCustom);

type
  TPxAviWriter = class(TObject)
  private
    FBitmaps: TList;
    TempFileName: string;
    PFile: PAVIFile;
    FHeight: Integer;
    FWidth: Integer;
    FStretch: Boolean;
    FFrameTime: Integer;
    FFileName: string;
    FWavFileName: string;
    VideoStream: PAVISTREAM;
    AudioStream: PAVISTREAM;
    procedure AddVideo;
    procedure AddAudio;
    procedure InternalGetDIBSizes(Bitmap: HBITMAP; var InfoHeaderSize: Integer; var ImageSize: LongInt; PixelFormat: TPixelFormat);
    function InternalGetDIB(Bitmap: HBITMAP; Palette: HPALETTE; var BitmapInfo; var Bits; PixelFormat: TPixelFormat): Boolean;
    procedure InitializeBitmapInfoHeader(Bitmap: HBITMAP; var Info: TBitmapInfoHeader; PixelFormat: TPixelFormat);
    procedure SetWavFileName(Value: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Write;
    property Bitmaps: TList read FBitmaps;
  published
    property Height: Integer read FHeight write FHeight;
    property Width: Integer read FWidth write FWidth;
    property FrameTime: Integer read FFrameTime write FFrameTime;
    property Stretch: Boolean read FStretch write FStretch;
    property FileName: string read FFileName write FFileName;
    property WavFileName: string read FWavFileName write SetWavFileName;
  end;

procedure AVIFileInit; stdcall;
procedure AVIFileExit; stdcall;
function AVIFileOpen(var ppfile: PAVIFile; szFile: PChar; uMode: UINT; lpHandler: Pointer): HResult; stdcall;
function AVIFileCreateStream(pfile: PAVIFile; var ppavi: PAVISTREAM; var psi: TAVIStreamInfo): HResult; stdcall;
function AVIStreamSetFormat(pavi: PAVIStream; lPos: LONG; lpFormat: Pointer; cbFormat: LONG): HResult; stdcall;
function AVIStreamReadFormat(pavi: PAVIStream; lPos: LONG; lpFormat: Pointer; var cbFormat: LONG): HResult; stdcall;
function AVIStreamWrite(pavi: PAVIStream; lStart, lSamples: LONG; lpBuffer: Pointer; cbBuffer: LONG; dwFlags: DWORD; var plSampWritten: LONG; var plBytesWritten: LONG): HResult; stdcall;
function AVIStreamRelease(pavi: PAVISTREAM): ULONG; stdcall;
function AVIFileRelease(pfile: PAVIFile): ULONG; stdcall;
function AVIFileGetStream(pfile: PAVIFile; var ppavi: PAVISTREAM; fccType: DWORD; lParam: LONG): HResult; stdcall;
function CreateEditableStream(var ppsEditable: PAVISTREAM; psSource: PAVISTREAM): HResult; stdcall;
function AVISaveV(szFile: PChar; pclsidHandler: PCLSID; lpfnCallback: TAVISaveCallback; nStreams: Integer; pavi: APAVISTREAM; lpOptions: APAVICompressOptions): HResult; stdcall;

implementation

constructor TPxAviWriter.Create;
var
  TempDir: string;
  l: Integer;
begin
  inherited Create;
  FHeight := Screen.Height div 10;
  FWidth := Screen.Width div 10;
  FFrameTime := 1000;
  FStretch := True;
  FFileName := '';
  FBitmaps := TList.Create;
  AVIFileInit;

  SetLength(TempDir, MAX_PATH + 1);
  l := GetTempPath(MAX_PATH, PChar(TempDir));
  SetLength(TempDir, l);
  if Copy(TempDir, Length(TempDir), 1) <> '\' then
    TempDir := TempDir + '\';
  TempFileName := TempDir + '~AWTemp.avi';
end;

destructor TPxAviWriter.Destroy;
begin
  Clear;
  Bitmaps.Free;
  AviFileExit;
  inherited;
end;

procedure TPxAviWriter.Clear;
var
  I: Integer;
begin
  for I := 0 to Bitmaps.Count - 1 do
    TObject(Bitmaps[I]).Free;
  Bitmaps.Clear;
end;

procedure TPxAviWriter.Write;
var
  ExtBitmap: TBitmap;
  nstreams: Integer;
  i: Integer;
  Streams: APAVISTREAM;
  CompOptions: APAVICompressOptions;
  AVIERR: Integer;
  refcount: Integer;
begin
  AudioStream := nil;
  VideoStream := nil;

    // If no bitmaps are on the list, raise an error.
  if Bitmaps.count < 1 then
    raise Exception.Create('No bitmaps on the Bitmaps list');

    // If anything on the Bitmaps TList is not a bitmap, raise
    // an error.
  for i := 0 to Bitmaps.count - 1 do
  begin
    ExtBitmap := Bitmaps[i];
    if not (ExtBitmap is TBitmap) then
      raise Exception.Create('Bitmaps[' + IntToStr(i) + '] is not a TBitmap');
  end;

  try
    AddVideo;

    if WavFileName <> '' then
      AddAudio;

      // Create the output file.
    if WavFileName <> '' then
      nstreams := 2
    else
      nstreams := 1;

    Streams[0] := VideoStream;
    Streams[1] := AudioStream;
    CompOptions[0] := nil;
    CompOptions[1] := nil;

    AVIERR := AVISaveV(PChar(FileName),
      nil, // File handler
      nil, // Callback
      nStreams, // Number of streams
      Streams,
      CompOptions); // Compress options for VideoStream
    if AVIERR <> AVIERR_OK then
      raise Exception.Create('Unable to write output file');
  finally
    if assigned(VideoStream) then
      AviStreamRelease(VideoStream);
    if assigned(AudioStream) then
      AviStreamRelease(AudioStream);

    try
      repeat
        refcount := AviFileRelease(pFile);
      until refcount <= 0;
    except
    end;

    DeleteFile(TempFileName);
  end;
end;

procedure TPxAviWriter.AddVideo;
var
  Pstream: PAVISTREAM;
  StreamInfo: TAVIStreamInfo;
  BitmapInfo: PBitmapInfoHeader;
  BitmapInfoSize: Integer;
  BitmapSize: LongInt;
  BitmapBits: Pointer;
  Bitmap: TBitmap;
  ExtBitmap: TBitmap;
  Samples_Written: LONG;
  Bytes_Written: LONG;
  AVIERR: Integer;
  I: Integer;
begin
  // Open AVI file for write
  if AVIFileOpen(pFile, PChar(TempFileName), OF_WRITE or OF_CREATE or OF_SHARE_EXCLUSIVE, nil) <> AVIERR_OK then
    raise Exception.Create('Failed to create AVI video work file');

  // Allocate the bitmap to which the bitmaps on the Bitmaps TList will be copied.
  Bitmap := TBitmap.Create;
  Bitmap.Height := Self.Height;
  Bitmap.Width := Self.Width;

  // Write the stream header.
  try
    FillChar(StreamInfo, SizeOf(StreamInfo), 0);

    // Set frame rate and scale
    StreamInfo.dwRate := 1000;
    StreamInfo.dwScale := FFrameTime;
    StreamInfo.fccType := streamtypeVIDEO;
    StreamInfo.fccHandler := 0;
    StreamInfo.dwFlags := 0;
    StreamInfo.dwSuggestedBufferSize := 0;
    StreamInfo.rcFrame.Right := Self.Width;
    StreamInfo.rcFrame.Bottom := Self.Height;

    // Open AVI data stream
    if AVIFileCreateStream(pFile, pStream, StreamInfo) <> AVIERR_OK then
      raise Exception.Create('Failed to create AVI video stream');

    try
      // Write the bitmaps to the stream.
      for I := 0 to Bitmaps.count - 1 do
      begin
        try
          BitmapInfo := nil;
          BitmapBits := nil;

          // Copy the bitmap from the list to the AVI bitmap,
          // stretching if desired. If the caller elects not to
          // stretch, use the first pixel in the bitmap as a
          // background color in case either the height or
          // width of the source is smaller than the output.
          // If Draw fails, do a StretchDraw.
          ExtBitmap := Bitmaps[I];
          if FStretch then
            Bitmap.Canvas.StretchDraw(Rect(0, 0, Self.Width, Self.Height), ExtBitmap)
          else
          try
            with Bitmap.Canvas do
            begin
              Brush.Color := ExtBitmap.Canvas.Pixels[0, 0];
              Brush.Style := bsSolid;
              FillRect(Rect(0, 0, Bitmap.Width, Bitmap.Height));
              Draw(0, 0, ExtBitmap);
            end;
          except
            Bitmap.Canvas.StretchDraw(Rect(0, 0, Self.Width, Self.Height), ExtBitmap);
          end;

          // Determine size of DIB
          InternalGetDIBSizes(Bitmap.Handle, BitmapInfoSize, BitmapSize, pf8bit);
          if BitmapInfoSize = 0 then
            raise Exception.Create('Failed to retrieve bitmap info');

          // Get DIB header and pixel buffers
          GetMem(BitmapInfo, BitmapInfoSize);
          GetMem(BitmapBits, BitmapSize);
          InternalGetDIB(Bitmap.Handle, 0, BitmapInfo^, BitmapBits^, pf8bit);

          // On the first time through, set the stream format.
          if i = 0 then
            if AVIStreamSetFormat(pStream, 0, BitmapInfo, BitmapInfoSize) <> AVIERR_OK then
              raise Exception.Create('Failed to set AVI stream format');

          // Write frame to the video stream
          AVIERR := AVIStreamWrite(pStream, I, 1, BitmapBits, BitmapSize, AVIIF_KEYFRAME, Samples_Written, Bytes_Written);
          if AVIERR <> AVIERR_OK then
            raise Exception.Create('Failed to add frame to AVI. Err=' + IntToHex(AVIERR, 8));
        finally
          if BitmapInfo <> nil then
            FreeMem(BitmapInfo);
          if BitmapBits <> nil then
            FreeMem(BitmapBits);
        end;
      end;

      // Create the editable VideoStream from pStream.
      if CreateEditableStream(VideoStream, pStream) <> AVIERR_OK then
        raise Exception.Create('Could not create Video Stream');
    finally
      AviStreamRelease(pStream);
    end;

  finally
    Bitmap.Free;
  end;
end;

procedure TPxAviWriter.AddAudio;
var
  InputFile: PAVIFILE;
  InputStream: PAVIStream;
begin
  // Open the audio file.
  case AVIFileOpen(InputFile, PChar(WavFileName), OF_READ, nil) of
    0: ;
    AVIERR_BADFORMAT:
      raise Exception.Create('The file could not be read, indicating a corrupt file or an unrecognized format.');
    AVIERR_MEMORY:
      raise Exception.Create('The file could not be opened because of insufficient memory.');
    AVIERR_FILEREAD:
      raise Exception.Create('A disk error occurred while reading the audio file.');
    AVIERR_FILEOPEN:
      raise Exception.Create('A disk error occurred while opening the audio file.');
    REGDB_E_CLASSNOTREG:
      raise Exception.Create('According to the registry, the type of audio file specified in AVIFileOpen does not have a handler to process it.');
    else
      raise Exception.Create('Unknown error opening audio file');
  end;

   // Open the audio stream.
  try
    if AVIFileGetStream(InputFile, InputStream, 0, 0) <> AVIERR_OK then
      raise Exception.Create('Unable to get audio stream');

    // Create AudioStream as a copy of InputStream
    try
      if CreateEditableStream(AudioStream, InputStream) <> AVIERR_OK then
        raise Exception.Create('Failed to create editable AVI audio stream');
    finally
      AviStreamRelease(InputStream);
    end;
  finally
    AviFileRelease(InputFile);
  end;
end;

// --------------
// InternalGetDIB
// --------------
// Converts a bitmap to a DIB of a specified PixelFormat.
//
// Parameters:
// Bitmap	The handle of the source bitmap.
// Pal		The handle of the source palette.
// BitmapInfo	The buffer that will receive the DIB's TBitmapInfo structure.
//		A buffer of sufficient size must have been allocated prior to
//		calling this function.
// Bits		The buffer that will receive the DIB's pixel data.
//		A buffer of sufficient size must have been allocated prior to
//		calling this function.
// PixelFormat	The pixel format of the destination DIB.
//
// Returns:
// True on success, False on failure.
//
// Note: The InternalGetDIBSizes function can be used to calculate the
// nescessary sizes of the BitmapInfo and Bits buffers.
//

function TPxAviWriter.InternalGetDIB(Bitmap: HBITMAP; Palette: HPALETTE; var BitmapInfo; var Bits; PixelFormat: TPixelFormat): Boolean;
// From graphics.pas, "optimized" for our use
var
  OldPal: HPALETTE;
  DC: HDC;
begin
  InitializeBitmapInfoHeader(Bitmap, TBitmapInfoHeader(BitmapInfo), PixelFormat);
  OldPal := 0;
  DC := CreateCompatibleDC(0);
  try
    if Palette <> 0 then
    begin
      OldPal := SelectPalette(DC, Palette, False);
      RealizePalette(DC);
    end;
    Result := (GetDIBits(DC, Bitmap, 0, abs(TBitmapInfoHeader(BitmapInfo).biHeight), @Bits, TBitmapInfo(BitmapInfo), DIB_RGB_COLORS) <> 0);
  finally
    if OldPal <> 0 then
      SelectPalette(DC, OldPal, False);
    DeleteDC(DC);
  end;
end;

// -------------------
// InternalGetDIBSizes
// -------------------
// Calculates the buffer sizes nescessary for convertion of a bitmap to a DIB
// of a specified PixelFormat.
// See the GetDIBSizes API function for more info.
//
// Parameters:
// Bitmap	The handle of the source bitmap.
// InfoHeaderSize
//		The returned size of a buffer that will receive the DIB's
//		TBitmapInfo structure.
// ImageSize	The returned size of a buffer that will receive the DIB's
//		pixel data.
// PixelFormat	The pixel format of the destination DIB.
//

procedure TPxAviWriter.InternalGetDIBSizes(Bitmap: HBITMAP; var InfoHeaderSize: Integer; var ImageSize: LongInt; PixelFormat: TPixelFormat);
// From graphics.pas, "optimized" for our use
var
  Info: TBitmapInfoHeader;
begin
  InitializeBitmapInfoHeader(Bitmap, Info, PixelFormat);
  // Check for palette device format
  if Info.biBitCount > 8 then
  begin
    // Header but no palette
    InfoHeaderSize := SizeOf(TBitmapInfoHeader);
    if (Info.biCompression and BI_BITFIELDS) <> 0 then
      Inc(InfoHeaderSize, 12);
  end
  else
    // Header and palette
    InfoHeaderSize := SizeOf(TBitmapInfoHeader) + SizeOf(TRGBQuad) * (1 shl Info.biBitCount);
  ImageSize := Info.biSizeImage;
end;

// --------------------------
// InitializeBitmapInfoHeader
// --------------------------
// Fills a TBitmapInfoHeader with the values of a bitmap when converted to a
// DIB of a specified PixelFormat.
//
// Parameters:
// Bitmap	The handle of the source bitmap.
// Info		The TBitmapInfoHeader buffer that will receive the values.
// PixelFormat	The pixel format of the destination DIB.
//
{$IFDEF BAD_STACK_ALIGNMENT}
  // Disable optimization to circumvent optimizer bug...
{$IFOPT O+}
{$DEFINE O_PLUS}
{$O-}
{$ENDIF}
{$ENDIF}

procedure TPxAviWriter.InitializeBitmapInfoHeader(Bitmap: HBITMAP; var Info: TBitmapInfoHeader; PixelFormat: TPixelFormat);
// From graphics.pas, "optimized" for our use
var
  DIB: TDIBSection;
  Bytes: Integer;
  function AlignBit(Bits, BitsPerPixel, Alignment: Cardinal): Cardinal;
  begin
    Dec(Alignment);
    Result := ((Bits * BitsPerPixel) + Alignment) and not Alignment;
    Result := Result shr 3;
  end;
begin
  DIB.dsbmih.biSize := 0;
  Bytes := GetObject(Bitmap, SizeOf(DIB), @DIB);
  if Bytes = 0 then
    raise Exception.Create('Invalid bitmap');

  if (Bytes >= (SizeOf(DIB.dsbm) + SizeOf(DIB.dsbmih))) and (DIB.dsbmih.biSize >= SizeOf(DIB.dsbmih)) then
    Info := DIB.dsbmih
  else
  begin
    FillChar(Info, SizeOf(Info), 0);
    with Info, DIB.dsbm do
    begin
      biSize := SizeOf(Info);
      biWidth := bmWidth;
      biHeight := bmHeight;
    end;
  end;
  case PixelFormat of
    pf1bit:
      Info.biBitCount := 1;
    pf4bit:
      Info.biBitCount := 4;
    pf8bit:
      Info.biBitCount := 8;
    pf24bit:
      Info.biBitCount := 24;
    else
      raise Exception.Create('Invalid pixel foramt');
  end;
  Info.biPlanes := 1;
  Info.biCompression := BI_RGB; // Always return data in RGB format
  Info.biSizeImage := AlignBit(Info.biWidth, Info.biBitCount, 32) * Cardinal(abs(Info.biHeight));
end;
{$IFDEF O_PLUS}
{$O+}
{$UNDEF O_PLUS}
{$ENDIF}

procedure TPxAviWriter.SetWavFileName(Value: string);
begin
  if LowerCase(FWavFileName) <> LowerCase(Value) then
    if LowerCase(ExtractFileExt(Value)) <> '.wav' then
      raise Exception.Create('WavFileName must name a file with the .wav extension')
    else
      FWavFileName := Value;
end;

procedure AVIFileInit; stdcall; external 'avifil32.dll' name 'AVIFileInit';
procedure AVIFileExit; stdcall; external 'avifil32.dll' name 'AVIFileExit';
function AVIFileOpen; external 'avifil32.dll' name 'AVIFileOpenA';
function AVIFileCreateStream; external 'avifil32.dll' name 'AVIFileCreateStreamA';
function AVIStreamSetFormat; external 'avifil32.dll' name 'AVIStreamSetFormat';
function AVIStreamReadFormat; external 'avifil32.dll' name 'AVIStreamReadFormat';
function AVIStreamWrite; external 'avifil32.dll' name 'AVIStreamWrite';
function AVIStreamRelease; external 'avifil32.dll' name 'AVIStreamRelease';
function AVIFileRelease; external 'avifil32.dll' name 'AVIFileRelease';
function AVIFileGetStream; external 'avifil32.dll' name 'AVIFileGetStream';
function CreateEditableStream; external 'avifil32.dll' name 'CreateEditableStream';
function AVISaveV; external 'avifil32.dll' name 'AVISaveV';

end.

