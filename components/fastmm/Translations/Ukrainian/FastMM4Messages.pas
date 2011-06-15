{

Fast Memory Manager: Messages

2006-07-18
Ukrainian translation by Andrey V. Shtukaturov.

}

unit FastMM4MessagesUKR;

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
  CurrentStackTraceMsg = #13#10#13#10'Поточне трасування стеку вказує на цю помилку (входження): ';
  {Memory dump message}
  MemoryDumpMsg = #13#10#13#10'Поточний дамп пам’’яті з 256 байт починаючи з адреси ';
  {Block Error Messages}
  BlockScanLogHeader = ' Виділений блок запротокольовано процедурою LogAllocatedBlocksToFile. Розмір: ';
  ErrorMsgHeader = 'FastMM виявив помилку під час ';
  GetMemMsg = 'GetMem';
  FreeMemMsg = 'FreeMem';
  ReallocMemMsg = 'ReallocMem';
  BlockCheckMsg = 'сканування звільненого блоку ';
  OperationMsg = ' операція. ';
  BlockHeaderCorruptedMsg = ' Заголовок блоку ушкоджений. ';
  BlockFooterCorruptedMsg = ' Нижня частина блоку ушкоджена. ';
  FreeModifiedErrorMsg = 'FastMM виявив що блок було модифіковано після його звільнення. ';
  DoubleFreeErrorMsg = ' Була спроба звільнити/перевиділити не виділений блок.';
  PreviousBlockSizeMsg = #13#10#13#10'Розмір попереднього блоку був: ';
  CurrentBlockSizeMsg = #13#10#13#10'Розмір блоку: ';
  StackTraceAtPrevAllocMsg = #13#10#13#10'Трасування стеку якщо цей блок був раніше виділений (входження):';
  StackTraceAtAllocMsg = #13#10#13#10'Трасування стеку під час виділення блоку (входження):';
  PreviousObjectClassMsg = #13#10#13#10'Блок був раніше використаний для об’’єкта класу: ';
  CurrentObjectClassMsg = #13#10#13#10'Блок на даний момент використовується для об’’єкта класу: ';
  PreviousAllocationGroupMsg = #13#10#13#10'Виділена група була: ';
  PreviousAllocationNumberMsg = #13#10#13#10'Виділений номер був: ';
  CurrentAllocationGroupMsg = #13#10#13#10'Виділена група стала: ';
  CurrentAllocationNumberMsg = #13#10#13#10'Виділений номер став: ';
  StackTraceAtFreeMsg = #13#10#13#10'Трасування стеку коли цей блок був раніше звільнений (входження):';
  BlockErrorMsgTitle = 'Виявлено помилку пам’’яті.';
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
  VirtualMethodErrorHeader = 'FastMM виявив спробу викликати віртуальний метод звільненого об’’єкту. Зараз буде викликане порушення доступу для переривання поточної операції.';
  InterfaceErrorHeader = 'FastMM виявив спробу використати інтерфейс звільненого об’’єкту. Зараз буде викликане порушення доступу для переривання поточної операції.';
  BlockHeaderCorruptedNoHistoryMsg = ' На жаль заголовок блоку ушкоджений і історія недоступна.';
  FreedObjectClassMsg = #13#10#13#10'Клас звільненого об’’єкту: ';
  VirtualMethodName = #13#10#13#10'Віртуальний метод: ';
  VirtualMethodOffset = 'Зсув +';
  VirtualMethodAddress = #13#10#13#10'Адреса віртуального методу: ';
  StackTraceAtObjectAllocMsg = #13#10#13#10'Трасування стеку коли пам’’ять під об’’єкт була виділена (входження):';
  StackTraceAtObjectFreeMsg = #13#10#13#10'Трасування стеку коли пам’’ять під об’’єкт була згодом звільнена (входження):';
  {Installation Messages}
  AlreadyInstalledMsg = 'FastMM4 вже встановлено.';
  AlreadyInstalledTitle = 'Вже встановлено.';
  OtherMMInstalledMsg = 'FastMM4 не може бути встановлено якщо вже встановлено інший менеджер пам’’яті.'
    + #13#10'Якщо ви бажаєте використовувати FastMM4, будь-ласка переконайтесь що FastMM4.pas є самим першим модулем в'
    + #13#10'секції "uses" вашого .dpr файлу проекту.';
  OtherMMInstalledTitle = 'Неможливо встановити FastMM4 - вже встановлено інший менеджер пам’’яті.';
  MemoryAllocatedMsg = 'FastMM4 неможливо встановити коли пам’’ять вже була '
    + 'виділена стандартним менеджером пам’’яти.'#13#10'FastMM4.pas ПОВИНЕН '
    + 'бути першим модулем у вашому файлі .dpr файлі проекту, інакше пам’’ять може '
    + 'бути виділена'#13#10'через стандартний менеджер пам’’яті перед тим як FastMM4 '
    + 'отримає контроль. '#13#10#13#10'Якщо ви використовуєте обробник особливих ситуацій, '
    + 'наприклад MadExcept (або будь-який інший інструмент що модифікує порядок ініціалізації '
    + 'модулей),'#13#10'тоді перейдіть на сторінку його конфігурації та переконайтеся, що '
    + 'FastMM4.pas модуль ініціалізується перед будь-яким іншим модулем.';
  MemoryAllocatedTitle = 'Неможливо встановити FastMM4 - Пам’’ять вже була виділена';
  {Leak checking messages}
  LeakLogHeader = 'Блок пам’’яті був виділений та не звільнений. Розмір: ';
  LeakMessageHeader = 'В цьому додатку відбуваються втрати пам’’яті.';
  SmallLeakDetail = 'Втрати блоків пам''яті маленького розміру'
{$ifdef HideExpectedLeaksRegisteredByPointer}
    + ' (за винятком очікуваних втрат пам''яті зареєстрованих по вказівнику)'
{$endif}
    + ':'#13#10;
  LargeLeakDetail = 'Розміри втрат блоків пам''яті середнього розміру'
{$ifdef HideExpectedLeaksRegisteredByPointer}
    + ' (за винятком очікуваних втрат пам''яті зареєстрованих по вказівнику)'
{$endif}
    + ': ';
  BytesMessage = ' байт: ';
  StringBlockMessage = 'String';
  LeakMessageFooter = #13#10
{$ifndef HideMemoryLeakHintMessage}
    + #13#10'Note: '
  {$ifdef RequireIDEPresenceForLeakReporting}
    + 'Ця перевірка втрати пам’’яті виконується лише у випадку одночасної роботи Delphi на тому ж комп’’ютері. '
  {$endif}
  {$ifdef FullDebugMode}
    {$ifdef LogMemoryLeakDetailToFile}
    + 'Детальна інформація про втрату и пам’’яті журналюється у текстовий файл в тому ж каталозі, що й додаток. '
    {$else}
    + 'Включіть "LogMemoryLeakDetailToFile" для того щоб отримати журнал, що містить детальну інформацію про втрату пам’’яті. '
    {$endif}
  {$else}
    + 'Для того щоб отримати журнал, що містить детальну інформацію про втрату пам’’яті, включіть умови компіляції "FullDebugMode" та "LogMemoryLeakDetailToFile". '
  {$endif}
    + 'Для того щоб виключити ці перевірки втрат пам’’яті, необхідно видалити визначення "EnableMemoryLeakReporting".'#13#10
{$endif}
    + #0;
  LeakMessageTitle = 'Виявлено втрату пам’’яті';
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
  InvalidAllocMemMsg = 'FastMM has detected a ReallocMem call after FastMM was uninstalled.';
{$endif}

implementation

end.

