{

Fast Memory Manager: Messages

belarussian translation by dzmitry[li]
mailto:dzmitry@biz.by
Ёлектронна€ карта горада Ћ≥да


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
  UnknownClassNameMsg = 'Unknown';
  {Stack trace Message}
  CurrentStackTraceMsg = #13#10#13#10'Ѕ€гуча€ трас≥роҐка стэка паказвае на гэтую памылку (уваходжанне): ';
  {Memory dump message}
  MemoryDumpMsg = #13#10#13#10'Ѕ€гучы дамп пам€ц≥ з 256 байт пачынальна з адрасу ';
  {Block Error Messages}
  BlockScanLogHeader = 'Allocated block logged by LogAllocatedBlocksToFile. The size is: ';
  ErrorMsgHeader = 'FastMM вы€в≥Ґ памылку падчас ';
  GetMemMsg = 'GetMem';
  FreeMemMsg = 'FreeMem';
  ReallocMemMsg = 'ReallocMem';
  BlockCheckMsg = 'сканаванн€ вызваленага блоку';
  OperationMsg = ' аперацы€. ';
  BlockHeaderCorruptedMsg = '«агаловак блока пашкоджаны. ';
  BlockFooterCorruptedMsg = 'Ќ≥жн€€ частка блока пашкоджана. ';
  FreeModifiedErrorMsg = 'FastMM вы€в≥Ґ што блок быҐ мадыф≥каваны пасл€ €го вызваленн€. ';
  DoubleFreeErrorMsg = 'Ѕыла распачата спроба вызвал≥ць/перавызвал≥ць невылучаны блок.';
  PreviousBlockSizeMsg = #13#10#13#10'ѕамер пап€рэдн€га блока быҐ: ';
  CurrentBlockSizeMsg = #13#10#13#10'ѕамер блока: ';
  StackTraceAtPrevAllocMsg = #13#10#13#10'“рас≥роҐка стэка кал≥ гэты блок быҐ раней вылучаны (уваходжанне):';
  StackTraceAtAllocMsg = #13#10#13#10'“рас≥роҐка стэка пры вылучэнн≥ блока (уваходжанне):';
  PreviousObjectClassMsg = #13#10#13#10'Ѕлок быҐ раней скарыстаны дл€ аб''екта класа: ';
  CurrentObjectClassMsg = #13#10#13#10'Ѕлок у ц€перашн≥ час выкарыстоҐваецца дл€ аб''екта класа: ';
  PreviousAllocationGroupMsg = #13#10#13#10'The allocation group was: ';
  PreviousAllocationNumberMsg = #13#10#13#10'The allocation number was: ';
  CurrentAllocationGroupMsg = #13#10#13#10'The allocation group is: ';
  CurrentAllocationNumberMsg = #13#10#13#10'The allocation number is: ';
  StackTraceAtFreeMsg = #13#10#13#10'“рас≥роҐка стэка кал≥ гэты блок быҐ раней вызвалены (уваходжанне):';
  BlockErrorMsgTitle = '¬ы€Ґлена€ памылка пам€ц≥.';
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
  VirtualMethodErrorHeader = 'FastMM вы€в≥Ґ спробу выкл≥каць в≥ртуальны метад вызваленага аб''екта. «араз будзе выкл≥кана парушэнне доступу дл€ перапыненн€ б€гучай аперацы≥.';
  InterfaceErrorHeader = 'FastMM вы€в≥Ґ спробу выкарыстаць ≥нтэрфейс вызваленага аб''екта. «араз будзе выкл≥кана парушэнне доступу дл€ перапыненн€ б€гучай аперацы≥.';
  BlockHeaderCorruptedNoHistoryMsg = ' Ќажаль загаловак блока пашкоджаны ≥ г≥сторы€ не даступна€.';
  FreedObjectClassMsg = #13#10#13#10' лас вызваленага аб''екта: ';
  VirtualMethodName = #13#10#13#10'¬≥ртуальны метад: ';
  VirtualMethodOffset = '«рушэнне +';
  VirtualMethodAddress = #13#10#13#10'јдрас в≥ртуальнага метаду: ';
  StackTraceAtObjectAllocMsg = #13#10#13#10'“рас≥роҐка стэка кал≥ пам€ць пад аб''ект была вылучана (уваходжанне):';
  StackTraceAtObjectFreeMsg = #13#10#13#10'“рас≥роҐка стэка кал≥ пам€ць пад аб''ект была пасл€ вызвалена (уваходжанне):';
  {Installation Messages}
  AlreadyInstalledMsg = 'FastMM4 ужо Ґстал€ваны.';
  AlreadyInstalledTitle = '”жо Ґстал€ваны.';
  OtherMMInstalledMsg = 'FastMM4 не можа быць устал€ваны пры Ґстал€ваным ≥ншым мэнэджэру пам€ц≥.'
    + #13#10' ал≥ вы жадаеце выкарыстоҐваць FastMM4, кал≥ ласка ҐпэҐн≥цес€ што FastMM4.pas з''€Ґл€ецца самым першым модулем у'
    + #13#10'секцы≥ "uses" вашага ''s .dpr файла праекту.';
  OtherMMInstalledTitle = 'Ќемагчыма Ґстал€ваць FastMM4 - ужо Ґстал€ваны ≥ншы мэнэджэр пам€ц≥.';
  MemoryAllocatedMsg = 'FastMM4 немагчыма Ґстал€ваць кал≥ пам€ць ужо была '
    + 'вылучана€ стандартным мэнэджэрам пам€ц≥.'#13#10'FastMM4.pas ѕј¬≤Ќ≈Ќ '
    + 'быць першым модулем у вашым файле''s .dpr файле праекту, ≥накш пам€ць можа '
    + 'быць вылучана'#13#10'праз стандартны мэнэджэр пам€ц≥ перад тым €к FastMM4 '
    + 'атрымае кантроль. '#13#10#13#10' ал≥ вы выкарыстаеце апрацоҐшчык выключэнн€Ґ '
    + 'тыпу MadExcept (або любую ≥нша€ прыладу, €ка€ мадыф≥куе парадак ≥н≥цы€л≥зацы≥ '
    + 'модул€Ґ),'#13#10'то перайдз≥це Ґ старонку €го канф≥гурацы≥ ≥ ҐпэҐн≥цес€, што '
    + 'FastMM4.pas модуль ≥н≥цы€л≥зуецца перад любым ≥ншым модулем.';
  MemoryAllocatedTitle = 'Ќе магчыма Ґстал€ваць FastMM4 - ѕам€ць ужо была вылучана';
  {Leak checking messages}
  LeakLogHeader = 'Ѕлок пам€ц≥ быҐ вылучаны ≥ не вызвалены. ѕамер: ';
  LeakMessageHeader = '” гэтай праграме адбываюцца Ґцечк≥ пам€ц≥. ';
  SmallLeakDetail = '”цечк≥ блокаҐ малага памеру'
{$ifdef HideExpectedLeaksRegisteredByPointer}
    + ' (выключаючы чаканы€ Ґцечк≥ зарэг≥страваны€ па паказальн≥ку)'
{$endif}
    + ':'#13#10;
  LargeLeakDetail = 'ѕамеры Ґцечак блокаҐ с€рэдн€га памеру'
{$ifdef HideExpectedLeaksRegisteredByPointer}
    + ' (выключаючы чаканы€ Ґцечк≥ зарэг≥страваны€ па паказальн≥ку)'
{$endif}
    + ': ';
  BytesMessage = ' байтаҐ: ';
  StringBlockMessage = 'String';
  LeakMessageFooter = #13#10
{$ifndef HideMemoryLeakHintMessage}
    + #13#10'Note: '
  {$ifdef RequireIDEPresenceForLeakReporting}
    + '√эта€ праверка Ґцечк≥ пам€ц≥ вырабл€ецца тольк≥ Ґ выпадку адначасовай працы Delphi на тым жа кампутары. '
  {$endif}
  {$ifdef FullDebugMode}
    {$ifdef LogMemoryLeakDetailToFile}
    + 'ƒэталЄва€ ≥нфармацы€ аб уцечках пам€ц≥ журналюецца Ґ тэкставы файл у тым жа каталогу, што ≥ праграма. '
    {$else}
    + '”ключыце "LogMemoryLeakDetailToFile" дл€ атрыманн€ часоп≥са, €к≥ зм€шчае дэталЄвую ≥нфармацыю аб уцечках пам€ц≥. '
    {$endif}
  {$else}
    + 'ƒл€ атрыманн€ часоп≥са, €к≥ зм€шчае дэталЄвую ≥нфармацыю аб уцечках пам€ц≥, уключыце Ґмовы камп≥л€цы≥ "FullDebugMode" ≥ "LogMemoryLeakDetailToFile". '
  {$endif}
    + 'ƒл€ выключэнн€ гэтых праверак уцечк≥ пам€ц≥, прыб€рыце значэнне "EnableMemoryLeakReporting".'#13#10
{$endif}
    + #0;
  LeakMessageTitle = '¬ы€Ґлена Ґцечка пам€ц≥';
{$ifdef UseOutputDebugString}
  FastMMInstallMsg = 'FastMM быҐ устал€ваны.';
  FastMMInstallSharedMsg = 'Sharing an existing instance of FastMM.';
  FastMMUninstallMsg = 'FastMM быҐ дэ≥нстал€ваны.';
  FastMMUninstallSharedMsg = 'Stopped sharing an existing instance of FastMM.';
{$endif}
{$ifdef DetectMMOperationsAfterUninstall}
  InvalidOperationTitle = 'MM аперацы≥ пасл€ дэ≥нстал€цы≥.';
  InvalidGetMemMsg = 'FastMM вызначыҐ, што GetMem выкл≥кацца пасл€ таго €к FastMM быҐ дэ≥нстал€ваны.';
  InvalidFreeMemMsg = 'FastMM вызначыҐ, што FreeMem выкл≥кацца пасл€ таго €к FastMM быҐ дэ≥нстал€ваны.';
  InvalidReallocMemMsg = 'FastMM вызначыҐ, што ReallocMem выкл≥кацца пасл€ таго €к FastMM быҐ дэ≥нстал€ваны.';
  InvalidAllocMemMsg = 'FastMM вызначыҐ, што ReallocMem выкл≥кацца пасл€ таго €к FastMM быҐ дэ≥нстал€ваны.';
{$endif}

implementation

end.
