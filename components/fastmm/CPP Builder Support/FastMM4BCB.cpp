/*

Fast Memory Manager: BCB support 1.01

Description:
 FastMM support unit for BCB6 1.0. Loads FastMM4 on startup of the Borland C++
 Builder application or DLL.

Usage:
 1) Under the Project -> Options -> Linker menu uncheck "Use Dynamic RTL"
    (sorry, won't work with the RTL DLL).
 2) Add FastMM4.pas to your project and build it so that FastMM4.hpp is
    created.
 3) Add FastMM4BCB.cpp to your project.
 FastMM will now install itself on startup and replace the RTL memory manager.

Acknowledgements:
 - Jarek Karciarz, Vladimir Ulchenko (Vavan) and Bob Gonder for their help in
   implementing the BCB support.

Notes:
  FastMM cannot uninstall itself under BCB, so memory leak checking is not
  available. Also, since it cannot be uninstalled you should only use it in
  dynamically loaded DLLs that will be sharing the main application's MM -
  otherwise memory will be leaked every time you unload the DLL. Unfortunately
  there is nothing I can do about the situation. The __exit procedure in exit.c
  calls all finalization routines before it has properly freed all memory. With
  live pointers still around, FastMM cannot uninstall itself. Not a good
  situation, and the only solution I see at this stage would be to patch the
  RTL.

Change log:
 Version 1.00 (15 June 2005):
  - Initial release. Due to limitations of BCB it cannot be uninstalled (thus
    no leak checking and not useable in DLLs unless the DLL always shares the
    main application's MM). Thanks to Jarek Karciarz, Vladimir Ulchenko and Bob
    Gonder for their help.
 Version 1.01 (6 August 2005):
  - Fixed a regression bug (Thanks to Omar Zelaya).

*/

#pragma hdrstop
#include "FastMM4.hpp"

void BCBInstallFastMM()
{
  InitializeMemoryManager();
  if (CheckCanInstallMemoryManager())
  {
    InstallMemoryManager();
  }
}
#pragma startup BCBInstallFastMM 0

void BCBUninstallFastMM()
{
  //Sadly we cannot uninstall here since there are still live pointers.
}
#pragma exit BCBUninstallFastMM 0


