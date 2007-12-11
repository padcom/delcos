{$IFOPT D-}
  {$DEFINE FINALVERSION}
  {$DEFINE RELEASE}
{$ELSE}
  {$DEFINE DEBUG}
{$ENDIF}

{$IFDEF RELEASE}
  {$DEFINE FINALVERSION}
{$ENDIF}

{$IFDEF FINALVERSION}
  {$UNDEF DEBUG}
{$ENDIF}

{$IFDEF VER130}
  {$DEFINE DELPHI}
{$ENDIF}
{$IFDEF VER140}
  {$DEFINE DELPHI}
{$ENDIF}
{$IFDEF VER150}
  {$DEFINE DELPHI}
{$ENDIF}
{$IFDEF VER160}
  {$DEFINE DELPHI}
{$ENDIF}
{$IFDEF VER170}
  {$DEFINE DELPHI}
{$ENDIF}
{$IFDEF VER180}
  {$DEFINE DELPHI}
{$ENDIF}
{$IFDEF VER190}
  {$DEFINE DELPHI}
{$ENDIF}

{$IFDEF DELPHI}
  //
  // DELPHI SPECIFIC SETTING
  //

  //
  // Enable huge strings (string is by default an AnsiString) 
  //
  {$H+}

  //
  // Use this if you want the standard LoadResString function to be replaced
  // with the one that reads the resource string and translates it. This
  // allows RTL resource strings to be translated but it is importand to use
  // the LoadResStringW function instead of directly assigning a value from
  // resource string contant because LoadResString doesn't make use of
  // WideStrings and therefore it's less flexible.
  // Under FPC this is not the case as there all resources have to be translated
  // with LoadResString/LoadResStringW.
  //
  {.$DEFINE HOOK_LOADRESSTRING}

  //
  // PxGetText engine - use HASH table to speed-up the text search
  //
  {.$DEFINE USE_HASH_TABLE}

  {$IFDEF VER150}
    //
    // Disable the warning about some platform-dependent units that PxLib is using
    // This library has never ment to be portable!
    //
    {$WARN SYMBOL_PLATFORM OFF}
    {$WARN UNSAFE_TYPE OFF}
    {$WARN UNSAFE_CAST OFF}
    {$WARN UNSAFE_CODE OFF}

    //
    // MathParser unit conversion functions.
    // They are available only under Delphi.
    //
    {$DEFINE USE_UNIT_CONVERSIONS}
  {$ENDIF}
{$ENDIF}

{$IFDEF FPC}
  //
  // FREEPASCAL COMPILER SPECIFIC SETTINGS
  //
  
  // 
  // Turn on Delphi compatibility mode
  //
  {$MODE DELPHI}
  
  //
  // Disabled because of lack of the StrToConvUnit, ConvertTo and ConvertFrom functions
  //
  {$UNDEF USE_UNIT_CONVERSIONS}
{$ENDIF}

//
// This enables the initialization section of PxLog to automaticaly startup the log
// subsystem. If for whatever reason this should not be enabled at startup clear this
// define and to start logging use PxLog.Initialize;
//
{.$DEFINE AUTO_ENABLE_LOGGING}

