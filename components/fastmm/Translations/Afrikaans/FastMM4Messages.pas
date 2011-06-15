{

Fast Memory Manager: Messages

Afrikaans translation by Pierre le Riche.

}

unit FastMM4Messages;

interface

{$Include FastMM4Options.inc}

const
  {The name of the debug info support DLL}
  FullDebugModeLibraryName = 'FastMM_FullDebugMode.dll';
  {Event log strings}
  LogFileExtension = '_MemoryManager_EventLog.txt'#0;
  CRLF = #13#10;
  EventSeparator = '--------------------------------';
  {Class name messages}
  UnknownClassNameMsg = 'Onbekend';
  {Stack trace Message}
  CurrentStackTraceMsg = #13#10#13#10'Die huidige stapel spoor wat aanleiding gegee het tot hierdie fout (terugkeer adresse): ';
  {Memory dump message}
  MemoryDumpMsg = #13#10#13#10'Huidige geheue inhoud: 256 grepe vanaf adres ';
  {Block Error Messages}
  BlockScanLogHeader = 'Geallokeerde blok gelys deur LogAllocatedBlocksToFile. The grootte is: ';
  ErrorMsgHeader = 'FastMM het ''n fout teegekom in die uitvoer van ''n ';
  GetMemMsg = 'GetMem';
  FreeMemMsg = 'FreeMem';
  ReallocMemMsg = 'ReallocMem';
  BlockCheckMsg = 'ongebruikte blok toets';
  OperationMsg = ' proses. ';
  BlockHeaderCorruptedMsg = 'Die merker voor die blok is beskadig. ';
  BlockFooterCorruptedMsg = 'Die merker na die blok is beskadig. ';
  FreeModifiedErrorMsg = 'FastMM het gevind dat ''n blok verander is sedert dit vrygestel is. ';
  DoubleFreeErrorMsg = '''n Poging is aangewend om ongebruikte ''blok vry te stel of te herallokeer.';
  PreviousBlockSizeMsg = #13#10#13#10'Die vorige blok grootte was: ';
  CurrentBlockSizeMsg = #13#10#13#10'Die blok grootte is: ';
  StackTraceAtPrevAllocMsg = #13#10#13#10'Stapel spoor van toe die blok voorheen geallokeer is (terugkeer adresse):';
  StackTraceAtAllocMsg = #13#10#13#10'Stapel spoor van toe die blok geallokeer is (terugkeer adresse):';
  PreviousObjectClassMsg = #13#10#13#10'Die blok is voorheen gebruik vir ''n objek van die klas: ';
  CurrentObjectClassMsg = #13#10#13#10'Die blok word huidiglik gebruik vir ''n objek van die klas: ';
  PreviousAllocationGroupMsg = #13#10#13#10'Die allokasie groep was: ';
  PreviousAllocationNumberMsg = #13#10#13#10'Die allokasie nommer was: ';
  CurrentAllocationGroupMsg = #13#10#13#10'Die allokasie groep is: ';
  CurrentAllocationNumberMsg = #13#10#13#10'Die allokasie nommer is: ';
  StackTraceAtFreeMsg = #13#10#13#10'Stapel spoor van toe die blok voorheen vrygestel is (terugkeer adresse):';
  BlockErrorMsgTitle = 'Geheue Fout';
  {Virtual Method Called On Freed Object Errors}
  StandardVirtualMethodNames: array[1 + vmtParent div 4 .. -1] of PChar = (
    'SafeCallException',
    'AfterConstruction',
    'BeforeDestruction',
    'Dispatch',
    'DefaultHandler',
    'NewInstance',
    'FreeInstance',
    'Destroy');
  VirtualMethodErrorHeader = 'FastMM het ''n poging onderskep om ''n virtuele funksie of prosedure van ''n vrygestelde objek te roep. ''n Toegangsfout sal nou veroorsaak word om die proses te onderbreek.';
  InterfaceErrorHeader = 'FastMM het ''n poging onderskep om ''n koppelvlak van ''n vrygestelde objek te gebruik. ''n Toegangsfout sal nou veroorsaak word om die proses te onderbreek.';
  BlockHeaderCorruptedNoHistoryMsg = ' Ongelukkig is die merker voor die blok beskadig en dus is geen blok geskiedenis beskikbaar nie.';
  FreedObjectClassMsg = #13#10#13#10'Vrygestelde objek klas: ';
  VirtualMethodName = #13#10#13#10'Virtuele funksie/prosedure: ';
  VirtualMethodOffset = 'VMT Adres +';
  VirtualMethodAddress = #13#10#13#10'Virtuele funksie/prosedure address: ';
  StackTraceAtObjectAllocMsg = #13#10#13#10'Stapel spoor van toe die blok geallokeer is (terugkeer adresse):';
  StackTraceAtObjectFreeMsg = #13#10#13#10'Stapel spoor van toe die blok vrygestel is (terugkeer adresse):';
  {Installation Messages}
  AlreadyInstalledMsg = 'FastMM4 is alreeds geïnstalleer.';
  AlreadyInstalledTitle = 'Alreeds geïnstalleer.';
  OtherMMInstalledMsg = 'FastMM4 kan nie geïnstalleer word nie, want ''n ander '
    + 'derde party geheuebestuurder is alreeds geïnstalleer.'#13#10'Indien jy FastMM4 wil gebruik, '
    + 'verseker asb. dat FastMM4.pas die eerste leêr is in die "uses"'
    + #13#10'afdeling van jou projek se .dpr leêr.';
  OtherMMInstalledTitle = 'FastMM4 kan nie geïnstalleer word nie - ''n ander geheue bestuurder is alreeds geïnstalleer';
  MemoryAllocatedMsg = 'FastMM4 kan nie geïnstalleer word nie aangesien geheue reeds '
    + 'geallokeer is deur die verstek geheue bestuurder.'#13#10'FastMM4.pas MOET '
    + 'die eerste leêr wees in jou projek se .dpr leêr, andersins mag geheie geallokeer word'
    + ''#13#10'deur die verstek geheue bestuurder voordat FastMM4 '
    + 'beheer verkry. '#13#10#13#10'As jy ''n foutvanger soos MadExcept gebruik '
    + '(of enigiets wat die peuter met die inisialiseringsvolgorder van eenhede),'
    + #13#10' gaan in sy opstelling bladsy in en verseker dat FastMM4.pas eerste geïnisialiseer word.';
  MemoryAllocatedTitle = 'FastMM4 kan nie geïnstalleer word nie - geheue is alreeds geallokeer';
  {Leak checking messages}
  LeakLogHeader = '''n Geheue blok het gelek. Die grootte is: ';
  LeakMessageHeader = 'Hierdie program het geheue gelek. ';
  SmallLeakDetail = 'Die klein blok lekkasies is'
{$ifdef HideExpectedLeaksRegisteredByPointer}
    + ' (verwagte lekkasies geregistreer deur wyser is uitgesluit)'
{$endif}
    + ':'#13#10;
  LargeLeakDetail = 'Die groottes van medium en groot blok lekkasies is'
{$ifdef HideExpectedLeaksRegisteredByPointer}
    + ' (verwagte lekkasies geregistreer deur wyser is uitgesluit)'
{$endif}
    + ': ';
  BytesMessage = ' grepe: ';
  StringBlockMessage = 'String';
  LeakMessageFooter = #13#10
{$ifndef HideMemoryLeakHintMessage}
    + #13#10'Nota: '
  {$ifdef RequireIDEPresenceForLeakReporting}
    + 'Die geheie lekkasie toets word slegs gedoen indien Delphi op daardie tydstip op die masjien loop. '
  {$endif}
  {$ifdef FullDebugMode}
    {$ifdef LogMemoryLeakDetailToFile}
    + 'Lekkasie detail word gelog na ''n teks leêr in dieselfde gids as hierdie program. '
    {$else}
    + 'Sit "LogMemoryLeakDetailToFile" aan om ''n gedetailleerde verslag oor al die geheue lekkasies na teksleêr te skryf. '
    {$endif}
  {$else}
    + 'Sit die "FullDebugMode" en "LogMemoryLeakDetailToFile" opsies aan om ''n gedetailleerde verslag oor al die geheue lekkasies na teksleêr te skryf. '
  {$endif}
    + 'Om die lekkasie toets te deaktiveer, sit die "EnableMemoryLeakReporting" opsie af.'#13#10
{$endif}
    + #0;
  LeakMessageTitle = 'Geheue Lekkasie';
{$ifdef UseOutputDebugString}
  FastMMInstallMsg = 'FastMM has been installed.';
  FastMMInstallSharedMsg = 'Sharing an existing instance of FastMM.';
  FastMMUninstallMsg = 'FastMM has been uninstalled.';
  FastMMUninstallSharedMsg = 'Stopped sharing an existing instance of FastMM.';
{$endif}
{$ifdef DetectMMOperationsAfterUninstall}
  InvalidOperationTitle = 'MM Operation after uninstall.';
  InvalidGetMemMsg = 'FastMM has detected a GetMem call after FastMM was uninstalled.';
  InvalidFreeMemMsg = 'FastMM has detected a FreeMem call after FastMM was uninstalled.';
  InvalidReallocMemMsg = 'FastMM has detected a ReallocMem call after FastMM was uninstalled.';
  InvalidAllocMemMsg = 'FastMM has detected an AllocMem call after FastMM was uninstalled.';
{$endif}

implementation

end.

