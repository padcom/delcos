// ----------------------------------------------------------------------------
// Unit        : PxFarPlugin - a part of PxLib
// Author      : Matthias Hryniszak
// Date        : 2004-10-18
// Version     : 1.0
// Description : Far Manager API (uses original API from Far Manager distr.)
// Changes log : 2004-10-26 - Preinitial version
// Remarks     : - Before anything initialize the PxFarPluginClass variable !!!
//               - Enumeration prefixes are created by adding first letters
//                 (lower-case) to "fp" prefix (FarPlugin, lower-case)
//               - to create a plugin create a new class inherited from
//                 TPxFarPlugin and override apriopriate methods.
// Doc         :
//
//               +------------------------+
//               |   TPxFarPlugin class   |
//               +------------------------+
//
//               procedure ClosePlugin; virtual;
//               -------------------------------
//
//               The ClosePlugin function closes an open plugin instance.
//
//
//               function Compare(const Item1, Item2: PPluginPanelItem; Mode: TPxFarPluginSortMode): Integer; virtual;
//               -----------------------------------------------------------------------------------------------------
//
//               A plugin can export the function Compare to override the default file panel sorting algorithm.
//
//               Mode
//                 Sort mode (see TPxFarPluginSortMode).
//               Item1, Item2
//                 Pointers to PluginPanelItem structures to compare.
//
//               Return value
//                 This function returns an int value that is
//                   -1 if Item1 < Item2
//                    0 if Item1 == Item2
//                    1 if Item1 > Item2
//                   -2 if the default FAR compare function should be used for this sort mode (default).
//
//
//               class function Configure(ItemNumber: Integer): LongBool; virtual;
//               -----------------------------------------------------------------
//
//               The Configure function allows the user to configure the plugin module.
//               It is called when one of the items exported by this plugin to the Plugin configuration menu is selected.
//
//               ItemNumber
//                 The number of selected item in the list of items exported by this plugin to the Plugin configuration
//                 menu.
//
//               Return value
//                 If the function succeeds, the return value must be True in this case FAR updates the panels.
//                 If the configuration is canceled by user, False should be returned.
//
//
//               function DeleteFiles(PanelItems: PPluginPanelItemArr; ItemsNumber: Integer; OpMode: TPxFarPluginOperationModes): Integer;
//               -------------------------------------------------------------------------------------------------------------------------
//
//               The DeleteFiles function is called to delete files in the file system emulated by the plugin.
//
//               PanelItem
//                 Points to an array of PluginPanelItem structures. Each structure describes a file to delete.
//               ItemsNumber
//                 Number of PluginPanelItem structures in the PanelItem array.
//               OpMode
//                 Combination of the operation mode flags. This function should process the flag OPM_SILENT.
//
//               Return value
//                 If the function succeeds, the return value must be 0. If the function fails, 1 should be returned.
//
//
//               procedure ExitFar; virtual;
//               ---------------------------
//
//               The ExitFAR function is called before FAR exits. In this function plugins can release all used resources.
//
//
//               procedure FreeFindData(PanelItems: PPluginPanelItemArr; ItemsNumber: Integer); virtual;
//               ---------------------------------------------------------------------------------------
//
//               The FreeFindData function is called to release the data allocated by GetFindData.
//
//               PanelItem
//                 Points to an array of PluginPanelItem structures previously allocated by GetFindData.
//               ItemsNumber
//                 Number of PluginPanelItem structures in the PanelItem array.
//
//
//               procedure FreeVirtualFindData(PanelItems: PPluginPanelItemArr; ItemsNumber: Integer); virtual;
//               ----------------------------------------------------------------------------------------------
//
//               The FreeVirtualFindData function is called to release the data allocated by GetVirtualFindData.
//
//               PanelItem
//                 Points to an array of PluginPanelItem structures previously allocated by GetFindData.
//               ItemsNumber
//                 Number of PluginPanelItem structures in the PanelItem array.
//
//
//               function GetString(StrId: Integer): PChar;
//               ------------------------------------------
//
//               The GetString function returns a string according to the given string
//
//
//               class function GetMinFarVersion: Integer; virtual;
//
//               The GetMinFarVersion is called once after loading the plugin and before SetStartupInfo is called.
//               It must return the minimum FAR version required for the plugin to work correctly. If the required version
//               is greater than the current FAR version, no other functions will be called and the plugin will be unloaded.
//
//
//               Return value
//                 This function must return an integer in the form 0xZZZZAABB, where AA is the major version, BB is the
//                 minor version and ZZZZ is the build number. Thus, if a plugin requires FAR version 1.70 build 321
//                 (beta 2), it must return 0x01410146. If the version of FAR is not important for a plugin, it should
//                 return 0 or not export this function at all.
//
//               Remarks
//                 It is recommended to use the function MakeFarVersion to construct the version number returned from this
//                 function. For example
//                   Result := MakeFarVersion(1,70,591);
//                 for a plugin that requires FAR 1.70 build 591 or later
//
//
//               function GetFiles(PanelItems: PPluginPanelItemArr; ItemsNumber: Integer; Move: Integer; DestPath: PAnsiChar; OpMode: TPxFarPluginOperationModes): Integer; virtual;
//               -------------------------------------------------------------------------------------------------------------------------------------------------------------------
//
//               The GetFiles function is called to get files from the file system emulated by the plugin.
//
//               PanelItem
//                 Points to an array of PluginPanelItem structures. Each structure describes a file to get.
//               ItemsNumber
//                 Number of PluginPanelItem structures in the PanelItem array.
//               Move
//                 If zero, files should be copied, if nonzero - moved.
//               DestPath
//                 Destination path to put files. If OpMode flag fpomSilent is not set, you can allow the user to change
//                 it, but in that case the new path must be copied to DestPath.
//               OpMode
//                 Combination of the operation mode flags. This function should be ready to process fpomSilent, fpomFind,
//                 fpomView and fpomEdit flags. Also it can process fpomDescription and fpomTopLevel to speed up operation
//                 if necessary.
//               Return value
//                 If the function succeeds, the return value must be 1. If the function fails, 0 should be returned.
//                 If the function was interrupted by the user, it should return -1.
//
//               Remarks
//                 If the operation is failed, but part of the files was successfully processed, the plugin can remove
//                 selection only from the processed files. To perform it, the plugin should clear the PPIF_SELECTED flag
//                 for processed items in the PluginPanelItem list passed to the function.
//
//
//               function GetFindData(var PanelItem: PPluginPanelItemArr; var ItemsNumber: Integer; OpMode: TPxFarPluginOperationModes): Integer; virtual;
//               -----------------------------------------------------------------------------------------------------------------------------------------
//
//               The GetFindData function is called to get the list of files in the current directory of the file system
//               emulated by the plugin.
//
//               PanelItem
//                 Points to a variable that receives the address of a PluginPanelItem structures array.
//               ItemsNumber
//                 Points to a variable that receives the number of PluginPanelItem structures.
//               OpMode
//                 Combination of the operation mode flags. This function should be ready to process OPM_FIND flag.
//
//               Return value
//                 If the function succeeds, the return value must be TRUE. If the function fails, FALSE should be returned.
//                 If GetFindData returns FALSE, the plugin will be closed.
//               Remarks
//                 The plugin is responsible for allocating the memory for the PluginPanelItem structures. If it allocates
//                 some memory, it should also export the function FreeFindData to free that memory.
//
//
//               procedure GetOpenPluginInfo(var Info: TOpenPluginInfo); virtual;
//               ----------------------------------------------------------------
//
//               The GetOpenPluginInfo function is called to get the information about an open plugin instance.
//
//               Info
//                 Points to an OpenPluginInfo structure that should be filled by this function.
//
//               Remarks
//                 The OpenPluginInfo structure passed to this function is already filled with zeros. The plugin is
//                 required to fill the StructSize field of the structure.
//
//
//               class procedure GetPluginInfo(var Info: TPluginInfo); virtual;
//               --------------------------------------------------------------
//
//               The GetPluginInfo function is called to get general plugin information.
//
//               Info
//                 Points to an OpenPluginInfo structure that should be filled by this function.
//
//               Remarks
//                 The PluginInfo structure passed to this function is already filled with zeros. The plugin is required
//                 to fill the StructSize field of the structure. This function is called:
//                   - before the plugin commands menu (F11) is shown;
//                   - before the disks menu (Alt-F1/Alt-F2) is shown;
//                   - before the plugins configuration menu is shown;
//                   - when a command with a prefix is entered in the command line (for example, net:\\share).
//
//
//               function GetVirtualFindData(var pPanelItem: PPluginPanelItemArr; var pItemsNumber: Integer; Path: String): Integer; virtual;
//               ----------------------------------------------------------------------------------------------------------------------------
//
//               The GetVirtualFindData function can be used to return a list of files to show in another file panel
//               in addition to the real files.
//
//               pPanelItem
//                 Points to a variable that receives the address of an array of PluginPanelItem structures.
//               pItemsNumber
//                 Points to a variable that receives the number of PluginPanelItem structures.
//               Path
//                 Path for which the list of files is returned (the current directory on another panel). The path is
//                 terminated with a backslash.
//
//               Return value
//                 If the function succeeds, the return value must be True.
//                 If the function fails, False should be returned.
//
//               Remarks
//                 This function can be used to implement "delayed file copying". When delayed copying is used, the files
//                 copied from a plugin panel to a file panel are shown on the file panel immediately, but the physical
//                 copy operation is performed later, when the plugin is closed or a special command is executed.
//                 Delayed copying can be useful, for example, for plugins supporting Arvid.
//
//
//               function MakeDirectory(Name: String; OpMode: TPxFarPluginOperationModes): Integer; virtual;
//               -------------------------------------------------------------------------------------------
//
//               The MakeDirectory function is called to create a new directory in the file system emulated by the plugin.
//
//               Name
//                 Name of the directory. If OpMode flag OPM_SILENT is not set, you can allow the user to change it, but
//                 in that case the new name must be copied to Name.
//               OpMode
//                 Combination of the operation mode flags. This function should be ready to process fpomSilent flag.
//
//               Return value
//                 If the function succeeds, the return value must be 1.
//                 If the function fails, 0 should be returned.
//                 If the function was interrupted by the user, it should return -1.
//
//
//               class function OpenFilePlugin(Name: String; Data: Pointer; DataSize: Integer): THandle; virtual;
//               ------------------------------------------------------------------------------------------------
//
//               The OpenFilePlugin function is called to open a plugin which emulates a file system based on a file
//               passed to this function (for example, an archive).
//
//               Name
//                 Points to the full name of the file (including the path). This pointer is valid only until return, so
//                 if the plugin will process this file, it should copy this name to an internal variable.
//                 The OpenFilePlugin function is also called when the user is going to create a new file (when Shift-F1
//                 is pressed). In that case Name is NULL and other parameters are undefined. If a plugin does not support
//                 creating new files, it must return INVALID_HANDLE_VALUE, otherwise it must return the handle of a new
//                 plugin instance that must be ready to process GetOpenPluginInfo and PutFiles functions. If Name is NULL,
//                 the plugin needs to request Name from the user in the PutFiles function.
//               Data
//                 Points to data from the beginning of the file. It can be used to detect file type. The plugin must
//                 not change this data.
//               DataSize
//                 Size of the passed file data. Currently it can be from 0 to 128Kb, depending on file size, but you
//                 should be ready to process any other value.
//
//               Return value
//                 If the plugin will process the passed file, the return value must be new plugin handle.
//                 If this file type is not supported, the return value must be INVALID_HANDLE_VALUE.
//                 If operation is interrupted by the user, the value -2 (cast to the HANDLE type) should be returned.
//
//               Remarks
//                 When Enter is pressed on a selected file, FAR queries all plugins that export this function. The plugins
//                 are queried in alphabetic order (sorted by the DLL name). When a plugin returns a value different from
//                 INVALID_HANDLE_VALUE, FAR stops querying other plugins.
//
//
//               class function OpenPlugin(OpenFrom: TPxFarPluginOpenFrom; Item: Integer): THandle; virtual;
//               -------------------------------------------------------------------------------------------
//
//               The OpenPlugin is called to create a new plugin instance.
//
//               OpenFrom
//                 Identifies how the plugin is invoked.
//               Item
//                 For fpofDiskMenu, fpofPluginsMenu, fpofEditor, fpofViewer Item is a position of the activated plugin
//                 item in the exported items list in disks or plugins menu. If a plugin exports only one item, this
//                 field is always 0.
//                 For fpofFindList Item is 0.
//                 For fpofShortCut Item contains the address of a string that was passed in the ShortcutData member of
//                 the OpenPluginInfo structure, when saving the shortcut. The plugin can use it to store any additional
//                 information about its current state. It is not necessary to save the information about the current
//                 directory, because it is restored by FAR when using folder shortcuts.
//                 For fpofCommandLineItem contains address of a string containing the command line entered by the user.
//                 Plugin command prefix is not included to this string, unless the PF_FULLCMDLINE flag is set in the
//                 PluginInfo structure when the GetPluginInfo function is called. For example, if a plugin defined the
//                 prefix ftp and the user entered ftp://ftp.abc.com, Item will point to //ftp.abc.com.
//                 However, if PF_FULLCMDLINE is set, Item will point to ftp://ftp.abc.com.
//
//               Return value
//                 If the function succeeds, the return value is a plugin handle. This handle will be passed later to
//                 other plugin functions to allow them to distinguish different plugin instances. Handle format is not
//                 important for FAR, it can be the address of a new plugin class object, or the address of a structure
//                 with plugin data, or an array index, or something else.
//                 If the function fails, the return value must be INVALID_HANDLE_VALUE.
//
//               Remarks
//                 Note that you can use this function to implement FAR commands that work without creating new panels.
//                 Just perform all necessary actions here and return INVALID_HANDLE_VALUE.
//
//
//               function ProcessEvent(Event: TPxFarPluginEventType; Param: Pointer): Integer; virtual;
//               --------------------------------------------------------------------------------------
//
//               The ProcessEvent function informs plugin about different FAR events and allows to process some of them.
//
//               Event
//                Event type (see TPxFarPluginEventType)
//               Param
//                 Points to data dependent on event type. Read events description for concrete information.
//
//               Return value
//                 Return value depends on event type. Read events description for concrete information.
//                 Return 0 for unknown event types.
//
//
//               function ProcessHostFile(PanelItem: PPluginPanelItemArr; ItemsNumber: Integer; OpMode: TPxFarPluginOperationModes): Integer; virtual;
//               -------------------------------------------------------------------------------------------------------------------------------------
//
//               The ProcessHostFile function is called to perform FAR Archive commands. It is recommended to use this
//               function to perform additional operations on the file that is handled by a file processing plugin.
//
//               PanelItem
//                 Points to an array of PluginPanelItem structures. Each structure corresponds to a selected file in the
//                 plugin panel.
//               ItemsNumber
//                 Number of PluginPanelItem structures in PanelItem array.
//               OpMode
//                 Combination of the operation mode flags. For this function it is either [] or fpomTopLevel.
//
//               Return value
//                 If the function succeeds, the return value must be 1. If the function fails, 0 should be returned.
//
//               Remarks
//                 1. If the operation failed, but part of files was successfully processed, plugin can remove selection only
//                    from the processed files. To perform it, the plugin should clear PPIF_SELECTED flag in processed items in
//                    the PluginPanelItem list passed to the function.
//                 2. When Shift-F3 is pressed on a file in a file panel, the following sequence of calls is made:
//                    - OpenFilePlugin()
//                    - GetFindData() with the fpomTopLevel operation mode
//                    - ProcessHostFile() with the list of items returned from GetFindData()
//                    - FreeFindData()
//                    - ClosePlugin().
//
//
//               function ProcessKey(Key: Integer; ControlState: TPxFarPluginControlStates): Integer; virtual;
//               ---------------------------------------------------------------------------------------------
//
//               The ProcessKey function allows to override standard control keys processing in a plugin panel.
//
//               Key
//                 Virtual key code.
//               ControlState
//                 Indicates control keys state. Combination of fpcsControl, fpcsAlt, fpcsShift flags.
//                 For example, when Shift-F7 is pressed, Key is equal to VK_F7 and ControlState is equal to fpksShift.
//
//               Return value
//                 Return 0 to use standard FAR key processing. If the plugin processes the key combination by itself,
//                 it should return 1.
//
//               Remarks
//                 In FAR versions before 1.63, this function didn't allow to handle the full range of virtual key codes.
//
//
//               function PutFiles(PanelItem: PPluginPanelItemArr; ItemNumber: Integer; Move: Integer; OpMode: TPxFarPluginOperationModes): Integer; virtual;
//               --------------------------------------------------------------------------------------------------------------------------------------------
//
//               The PutFiles function is called to put files to the file system emulated by the plugin.
//
//               PanelItem
//                 Points to an array of PluginPanelItem structures. Each structure describes a file to put.
//               ItemsNumber
//                 Number of PluginPanelItem structures in the PanelItem array.
//               Move
//                 If zero, files should be copied, if nonzero - moved.
//               OpMode
//                 Combination of the operation mode flags. This function should be ready to process fpomSilent flag.
//                 Also it can process fmomDescription.
//                 If fpomSilent is not set, you can ask the user for confirmation and allow to edit destination path.
//
//               Return value
//                 If the function succeeds, the return value must be 1 or 2.
//                 If the return value is 1, FAR tries to position the cursor to the most recently created file on the
//                 active panel.
//                 If the plugin returns 2, FAR does not perform any positioning operations. (The special handling for
//                 the return value 2 has been added in FAR 1.70 beta 5.)
//                 If the function fails, 0 should be returned. If the function was interrupted by the user, it should
//                 return -1.
//
//               Remarks
//                 If the operation is failed, but part of the files was successfully processed, the plugin can remove
//                 selection only from the processed files. To perform it, plugin should clear PPIF_SELECTED flag for
//                 processed items in the PluginPanelItem list passed to function.
//
//
//               function SetDirectory(Dir: String; OpMode: TPxFarPluginOperationModes): Integer; virtual;
//               -----------------------------------------------------------------------------------------
//
//               The SetDirectory function is called to set the current directory in the file system emulated by the
//               plugin.
//
//               Dir
//                 Directory name. Usually contains only the name, without full path. To provide basic functionality the
//                 plugin should also process the names '..' and '\'.
//                 For correct restoring of current directory after using Search from the root folder mode in the Find
//                 File dialog, the plugin should be able to process full directory name returned in the GetOpenPluginInfo
//                 function.
//               OpMode
//                 Combination of the operation mode flags. This function should be ready to process the fpomFind flag.
//                 If the fpomFind flag is set, the function is called from Find file or another directory scanning
//                 command, and the plugin must not perform any actions except changing directory and returning 1 if
//                 successful or 0 if it is impossible to change the directory. (The plugin should not try to close or
//                 update the panels, ask the user for confirmations, show messages and so on.)
//
//               Return value
//                 If the function succeeds, the return value must be 1. If the function fails, 0 should be returned.
//
//
//               function SetFindList(PanelItem: PPluginPanelItemArr; ItemsNumber: Integer): Integer; virtual;
//               ---------------------------------------------------------------------------------------------
//
//               The SetFindList function is called to put the file names found by the Find file command to the file
//               system emulated by the plugin. The files should not be physically copied or changed.
//
//               PanelItem
//                 Points to an array of PluginPanelItem structures. Each structure describes a file to put.
//               ItemsNumber
//                 Number of PluginPanelItem structures in the PanelItem array.
//
//               Return value
//                 If the function succeeds, the return value must be 1. If the function fails, 0 should be returned.
//
//               Remarks
//                 1. This function is typically used by the Temporary panel plugin.
//                 2. Before calling this function, FAR calls the OpenPlugin function. The SetFindList function is called
//                    only after the successful return from OpenPlugin.
//
//
//               class procedure SetStartupInfo(var Info: TPluginStartupInfo);
//               -------------------------------------------------------------
//
//               The SetStartupInfo function is called once, before all other functions, but after the GetMinFarVersion
//               function. This function gives the plugin information necessary for further operation.
//
//               Info
//                 Points to a PluginStartupInfo structure. This pointer is valid only until return, so the structure
//                 must be copied to an internal variable for further usage.
//
//
// ToDo        : Testing, examples.
// ---------------------------------------------------------------------------- }

unit PxFarPlugin;

{$I PxDefines.inc}

interface

uses
  Windows, Classes, SysUtils, FarPlugin;

type
  // Identifies how the plugin is invoked. Can be one of the following values:
  TPxFarPluginOpenFrom = (
    // Open from the disks menu.
    fpofDiskMenu    = OPEN_DISKMENU,
    // Open from the plugins menu.
    fpofPluginsmenu = OPEN_PLUGINSMENU,
    // Open from the "Find File" dialog. The plugin will be called with this identifier only if it
    // exports the SetFindList function, and SetFindList will be called only if OpenPlugin returns
    // a valid handle.
    fpofFindList    = OPEN_FINDLIST,
    // Open using a folder shortcut command.
    fpofShortcut    = OPEN_SHORTCUT,
    // Open from the FAR command line.This type is used if the plugin has defined a command prefix
    // in the GetPluginInfo function, and this prefix, followed by a colon, is found in the command
    // line.
    fpofCommandLine = OPEN_COMMANDLINE,
    // Open from FAR editor.
    fpofEditor      = OPEN_EDITOR,
    // Open from FAR viewer.
    fpofViewer      = OPEN_VIEWER
  );

  // todo: TPxFarPluginSortMode type description
  TPxFarPluginSortMode = (
    fpsmDefault        = SM_DEFAULT,
    fpsmUnsorted       = SM_UNSORTED,
    fpsmName           = SM_NAME,
    fpsmExtension      = SM_EXT,
    fpsmLastModTime    = SM_MTIME,
    fpsmCreationTime   = SM_CTIME,
    fpsmLastAccessTime = SM_ATIME,
    fpsmSize           = SM_SIZE,
    fpsmDescription    = SM_DESCR,
    fpsmOwner          = SM_OWNER,
    fpsmCompressedSize = SM_COMPRESSEDSIZE,
    fpsmNumLinks       = SM_NUMLINKS
  );

  // The OpMode parameter passes to plugin additional information about function mode and place,
  // from which it was called. It can be a combination of the following values:
  TPxFarPluginOperationMode = (
    // Plugin should minimize user requests if possible, because the called function is only a part
    // of a more complex file operation.
    fpomSilent         = OPM_SILENT,
    // Plugin function is called from Find file or another directory scanning command.
    // Screen output has to be minimized
    fpomFind           = OPM_FIND,
    // Plugin function is called as part of a file view operation.
    fpomView           = OPM_VIEW,
    // Plugin function is called as part of a file view operation activated from the quick view panel
    // (activated by pressing Ctrl-Q in the file panels).
    fpomQuickView      = OPM_QUICKVIEW,
    // Plugin function is called as part of a file edit operation.
    fpomEdit           = OPM_EDIT,
    // Plugin function is called to get or put file with file descriptions.
    fpomDescription    = OPM_DESCR,
    // All files in host file of file based plugin should be processed. This flag is set when executing
    // Shift-F2 and Shift-F3 FAR commands outside of host file. Passed to plugin functions files list
    // also contains all necessary information, so plugin can either ignore this flag or use it to speed
    // up processing.
    fpomTopLevel       = OPM_TOPLEVEL
  );
  TPxFarPluginOperationModes = set of TPxFarPluginOperationMode;

  // Event type. Can be one of the following values:
  TPxFarPluginEventType = (
    // Panel view mode is changed.Param points to a null-terminated string specifying new column types, for example,
    // N,S,D,T. Return value must be 0.
    fpetChangeViewmode = FE_CHANGEVIEWMODE,
    // A panel is about to redraw. Param is equal to nil. Return 0 to use the FAR redraw routine or 1 to disable it.
    // In the latter case the plugin must redraw the panel itself.
    fpetRedraw         = FE_REDRAW,
    // Sent every few seconds. A plugin can use this event to request panel updating and redrawing, if necessary.
    // Param is equal to nil. Return value must be 0.
    fpetIdle           = FE_IDLE,
    // A panel is about to close. Param is equal to nil. Return 0 to close panel or 1 to disable it.
    fpetClose          = FE_CLOSE,
    // Ctrl-Break is pressed. Param currently can be only CTRL_BREAK_EVENT. Return value must be 0.
    // Processing of this event is performed in separate thread, so the plugin must be careful when performing console
    // input or output and must not use FAR service functions.
    fpetBreak          = FE_BREAK,
    // About to execute a command from the FAR command line. Param points to the command text. The plugin should return
    // 0 to allow standard command execution or 1 if it is going to process the command internally.
    fpetCommand        = FE_COMMAND
  );

  // Far manager control key states
  TPxFarPluginControlState = (
    // Control
    fpcsControl        = PKF_CONTROL,
    // Alt
    fpcsAlt            = PKF_ALT,
    // Shift
    fpcsShift          = PKF_SHIFT
  );
  TPxFarPluginControlStates = set of TPxFarPluginControlState;

  TPxFarPlugin = class (TObject)
  private
    FHandle: THandle;
  protected
    procedure ClosePlugin; virtual;
    function Compare(const Item1, Item2: PPluginPanelItem; Mode: TPxFarPluginSortMode): Integer; virtual;
    class function Configure(ItemNumber: Integer): LongBool; virtual;
    function DeleteFiles(PanelItems: PPluginPanelItemArr; ItemsNumber: Integer; OpMode: TPxFarPluginOperationModes): Integer;
    procedure ExitFar; virtual;
    procedure FreeFindData(PanelItems: PPluginPanelItemArr; ItemsNumber: Integer); virtual;
    procedure FreeVirtualFindData(PanelItems: PPluginPanelItemArr; ItemsNumber: Integer); virtual;
    function GetString(StrId: Integer): PChar;
    class function GetMinFarVersion: Integer; virtual;
    function GetFiles(PanelItems: PPluginPanelItemArr; ItemsNumber: Integer; Move: Integer; DestPath: PAnsiChar; OpMode: TPxFarPluginOperationModes): Integer; virtual;
    function GetFindData(var PanelItem: PPluginPanelItemArr; var ItemsNumber: Integer; OpMode: TPxFarPluginOperationModes): Integer; virtual;
    procedure GetOpenPluginInfo(var Info: TOpenPluginInfo); virtual;
    class procedure GetPluginInfo(var Info: TPluginInfo); virtual;
    function GetVirtualFindData(var pPanelItem: PPluginPanelItemArr; var pItemsNumber: Integer; Path: String): Integer; virtual;
    function MakeDirectory(Name: String; OpMode: TPxFarPluginOperationModes): Integer; virtual;
    class function OpenFilePlugin(Name: String; Data: Pointer; DataSize: Integer): THandle; virtual;
    class function OpenPlugin(OpenFrom: TPxFarPluginOpenFrom; Item: Integer): THandle; virtual;
    function ProcessEvent(Event: TPxFarPluginEventType; Param: Pointer): Integer; virtual;
    function ProcessHostFile(PanelItem: PPluginPanelItemArr; ItemsNumber: Integer; OpMode: TPxFarPluginOperationModes): Integer; virtual;
    function ProcessKey(Key: Integer; ControlState: TPxFarPluginControlStates): Integer; virtual;
    function PutFiles(PanelItem: PPluginPanelItemArr; ItemNumber: Integer; Move: Integer; OpMode: TPxFarPluginOperationModes): Integer; virtual;
    function SetDirectory(Dir: String; OpMode: TPxFarPluginOperationModes): Integer; virtual;
    function SetFindList(PanelItem: PPluginPanelItemArr; ItemsNumber: Integer): Integer; virtual;
    class procedure SetStartupInfo(var Info: TPluginStartupInfo);

  public
    constructor Create(AHandle: THandle); virtual;
    destructor Destroy; override;
    property Handle: THandle read FHandle;
  end;

  TPxFarPluginClass = class of TPxFarPlugin;

  TPxFarPluginList = class (TList)
  private
    function GetItem(Index: Integer): TPxFarPlugin;
  public
    property Items[Index: Integer]: TPxFarPlugin read GetItem; default;
  end;

// ---------------------------------------------------------------------------------------
// Export functions.
// Use the "exports" clausule in library project file to export the functions you want.
// Use them in form
//   _function_name name 'function_name'
// to get rid of the underscore.
//
//
// Here is a full, ready to use list of avaible exports:
//
//  _ClosePlugin name 'ClosePlugin',
//  _Compare name 'Compare',
//  _Configure name 'Configure',
//  _DeleteFiles name 'DeleteFiles',
//  _ExitFar name 'ExitFar;',
//  _FreeFindData name 'FreeFindData',
//  _FreeVirtualFindData name 'FreeVirtualFindData',
//  _GetMinFarVersion name 'GetMinFarVersion:',
//  _GetFiles name 'GetFiles',
//  _GetFindData name 'GetFindData',
//  _GetOpenPluginInfo name 'GetOpenPluginInfo',
//  _GetPluginInfo name 'GetPluginInfo',
//  _GetVirtualFindData name 'GetVirtualFindData',
//  _MakeDirectory name 'MakeDirectory',
//  _OpenFilePlugin name 'OpenFilePlugin',
//  _OpenPlugin name 'OpenPlugin',
//  _ProcessEvent name 'ProcessEvent',
//  _ProcessHostFile name 'ProcessHostFile',
//  _ProcessKey name 'ProcessKey',
//  _PutFiles name 'PutFiles',
//  _SetDirectory name 'SetDirectory',
//  _SetFindList name 'SetFindList',
//  _SetStartupInfo name 'SetStartupInfo';
// ---------------------------------------------------------------------------------------

procedure _ClosePlugin(Plugin: THandle); stdcall;
function  _Compare(Plugin: THandle; const Item1, Item2: PPluginPanelItem; Mode: TPxFarPluginSortMode): Integer; stdcall;
function  _Configure(ItemNumber: Integer): LongBool; stdcall;
function  _DeleteFiles(Plugin: THandle; PanelItems: PPluginPanelItemArr; ItemsNumber: Integer; OpMode: TPxFarPluginOperationModes): Integer; stdcall;
procedure _ExitFar; stdcall;
procedure _FreeFindData(Plugin: THandle; PanelItems: PPluginPanelItemArr; ItemsNumber: Integer); stdcall;
procedure _FreeVirtualFindData(Plugin: THandle; PanelItems: PPluginPanelItemArr; ItemsNumber: Integer); stdcall;
function  _GetMinFarVersion: Integer; stdcall;
function  _GetFiles(Plugin: THandle; PanelItems: PPluginPanelItemArr; ItemsNumber: Integer; Move: Integer; DestPath: PAnsiChar; OpMode: TPxFarPluginOperationModes): Integer; stdcall;
function  _GetFindData(Plugin: THandle; var PanelItem: PPluginPanelItemArr; var ItemsNumber: Integer; OpMode: TPxFarPluginOperationModes): Integer; stdcall;
procedure _GetOpenPluginInfo(Plugin: THandle; var Info: TOpenPluginInfo); stdcall;
procedure _GetPluginInfo(var Info: TPluginInfo); stdcall;
function  _GetVirtualFindData(Plugin: THandle; var pPanelItem: PPluginPanelItemArr; var pItemsNumber: Integer; Path: PAnsiChar): Integer; stdcall;
function  _MakeDirectory(Plugin: THandle; Name: PAnsiChar; OpMode: TPxFarPluginOperationModes): Integer; stdcall;
function  _OpenFilePlugin(Name: PAnsiChar; Data: Pointer; DataSize: Integer): THandle; stdcall;
function  _OpenPlugin(OpenFrom: TPxFarPluginOpenFrom; Item: Integer): THandle; stdcall;
function  _ProcessEvent(Plugin: THandle; Event: TPxFarPluginEventType; Param: Pointer): Integer; stdcall;
function  _ProcessHostFile(Plugin: THandle; PanelItem: PPluginPanelItemArr; ItemsNumber: Integer; OpMode: TPxFarPluginOperationModes): Integer; stdcall;
function  _ProcessKey(Plugin: THandle; Key: Integer; ControlState: TPxFarPluginControlStates): Integer; stdcall;
function  _PutFiles(Plugin: THandle; PanelItem: PPluginPanelItemArr; ItemNumber: Integer; Move: Integer; OpMode: TPxFarPluginOperationModes): Integer; stdcall;
function  _SetDirectory(Plugin: THandle; Dir: PAnsiChar; OpMode: TPxFarPluginOperationModes): Integer; stdcall;
function  _SetFindList(Plugin: THandle; PanelItem: PPluginPanelItemArr; ItemsNumber: Integer): Integer; stdcall;
procedure _SetStartupInfo(var Info: TPluginStartupInfo); stdcall;

var
  PxFarPluginClass: TPxFarPluginClass;
  Instances: TPxFarPluginList = nil;
  FarAPI: TPluginStartupInfo;

implementation

{ Forward declarations }

function GetInstance(Handle: THandle): TPxFarPlugin; forward;

{ TPxFarPlugin }

{ Private declarations }

{ Protected declarations }

procedure TPxFarPlugin.ClosePlugin;
begin
end;

function TPxFarPlugin.Compare(const Item1, Item2: PPluginPanelItem; Mode: TPxFarPluginSortMode): Integer;
begin
  Result := -2;
end;

class function TPxFarPlugin.Configure(ItemNumber: Integer): LongBool;
begin
  Result := False;
end;

function TPxFarPlugin.DeleteFiles(PanelItems: PPluginPanelItemArr; ItemsNumber: Integer; OpMode: TPxFarPluginOperationModes): Integer;
begin
  Result := 0;
end;

procedure TPxFarPlugin.ExitFar;
begin
end;

procedure TPxFarPlugin.FreeFindData(PanelItems: PPluginPanelItemArr; ItemsNumber: Integer);
begin
end;

procedure TPxFarPlugin.FreeVirtualFindData(PanelItems: PPluginPanelItemArr; ItemsNumber: Integer);
begin
end;

function TPxFarPlugin.GetString(StrId: Integer): PChar;
begin
  Result := FarAPI.GetMsg(FARAPI.ModuleNumber, StrId);
end;

class function TPxFarPlugin.GetMinFarVersion: Integer;
begin
  // by default all versions are supported
  Result := 0;
end;

function TPxFarPlugin.GetFiles(PanelItems: PPluginPanelItemArr; ItemsNumber: Integer; Move: Integer; DestPath: PAnsiChar; OpMode: TPxFarPluginOperationModes): Integer;
begin
  Result := 0;
end;

function TPxFarPlugin.GetFindData(var PanelItem: PPluginPanelItemArr; var ItemsNumber: Integer; OpMode: TPxFarPluginOperationModes): Integer;
begin
  Result := 0;
end;

procedure TPxFarPlugin.GetOpenPluginInfo(var Info: TOpenPluginInfo);
begin
  // no default processing
end;

class procedure TPxFarPlugin.GetPluginInfo(var Info: TPluginInfo);
begin
  // no default processing
end;

function TPxFarPlugin.GetVirtualFindData(var pPanelItem: PPluginPanelItemArr; var pItemsNumber: Integer; Path: String): Integer;
begin
  Result := 0;
end;

function TPxFarPlugin.MakeDirectory(Name: String; OpMode: TPxFarPluginOperationModes): Integer;
begin
  Result := 0;
end;

class function TPxFarPlugin.OpenFilePlugin(Name: String; Data: Pointer; DataSize: Integer): THandle;
begin
  Result := INVALID_HANDLE_VALUE;
end;

class function TPxFarPlugin.OpenPlugin(OpenFrom: TPxFarPluginOpenFrom; Item: Integer): THandle;
begin
  Result := INVALID_HANDLE_VALUE;
end;

function TPxFarPlugin.ProcessEvent(Event: TPxFarPluginEventType; Param: Pointer): Integer;
begin
  Result := 0;
end;

function TPxFarPlugin.ProcessHostFile(PanelItem: PPluginPanelItemArr; ItemsNumber: Integer; OpMode: TPxFarPluginOperationModes): Integer;
begin
  Result := 0;
end;

function TPxFarPlugin.ProcessKey(Key: Integer; ControlState: TPxFarPluginControlStates): Integer;
begin
  Result := 0;
end;

function TPxFarPlugin.PutFiles(PanelItem: PPluginPanelItemArr; ItemNumber: Integer; Move: Integer; OpMode: TPxFarPluginOperationModes): Integer;
begin
  Result := 0;
end;

function TPxFarPlugin.SetDirectory(Dir: String; OpMode: TPxFarPluginOperationModes): Integer;
begin
  Result := 0;
end;

function TPxFarPlugin.SetFindList(PanelItem: PPluginPanelItemArr; ItemsNumber: Integer): Integer;
begin
  Result := 0;
end;

class procedure TPxFarPlugin.SetStartupInfo(var Info: TPluginStartupInfo);
begin
end;

{ Public declarations }

constructor TPxFarPlugin.Create(AHandle: THandle);
begin
  inherited Create;
  FHandle := AHandle;
end;

destructor TPxFarPlugin.Destroy;
begin
  FHandle := 0;
  inherited Destroy;
end;

{ TPxFarPluginList }

{ Private declarations }

function TPxFarPluginList.GetItem(Index: Integer): TPxFarPlugin;
begin
  Result := TObject(Get(Index)) as TPxFarPlugin;
end;

{ Export functions }

procedure _ClosePlugin(Plugin: THandle);
var
  Instance: TPxFarPlugin;
begin
  Instance := GetInstance(Plugin);
  if Assigned(Instance) then
  begin
    Instance.ClosePlugin;
    Instance.Free;
    Instances.Remove(Instance);
  end;
end;

function _Compare(Plugin: THandle; const Item1, Item2: PPluginPanelItem; Mode: TPxFarPluginSortMode): Integer;
var
  Instance: TPxFarPlugin;
begin
  Instance := GetInstance(Plugin);
  if Assigned(Instance) then
    Result := Instance.Compare(Item1, Item2, Mode)
  else
    Result := -2;
end;

function _Configure(ItemNumber: Integer): LongBool;
begin
  Result := PxFarPluginClass.Configure(ItemNumber);
end;

function _DeleteFiles(Plugin: THandle; PanelItems: PPluginPanelItemArr; ItemsNumber: Integer; OpMode: TPxFarPluginOperationModes): Integer;
var
  Instance: TPxFarPlugin;
begin
  Instance := GetInstance(Plugin);
  if Assigned(Instance) then
    Result := Instance.DeleteFiles(PanelItems, ItemsNumber, OpMode)
  else
    Result := 0;
end;

procedure _ExitFar;
var
  I: Integer;
begin
  for I := 0 to Instances.Count - 1 do
    Instances[I].ExitFar;
end;

procedure _FreeFindData(Plugin: THandle; PanelItems: PPluginPanelItemArr; ItemsNumber: Integer);
var
  Instance: TPxFarPlugin;
begin
  Instance := GetInstance(Plugin);
  if Assigned(Instance) then
    Instance.FreeFindData(PanelItems, ItemsNumber)
end;

procedure _FreeVirtualFindData(Plugin: THandle; PanelItems: PPluginPanelItemArr; ItemsNumber: Integer);
var
  Instance: TPxFarPlugin;
begin
  Instance := GetInstance(Plugin);
  if Assigned(Instance) then
    Instance.FreeVirtualFindData(PanelItems, ItemsNumber)
end;

function _GetMinFarVersion: Integer;
begin
  Result := PxFarPluginClass.GetMinFarVersion;
end;

function _GetFiles(Plugin: THandle; PanelItems: PPluginPanelItemArr; ItemsNumber: Integer; Move: Integer; DestPath: PAnsiChar; OpMode: TPxFarPluginOperationModes): Integer;
var
  Instance: TPxFarPlugin;
begin
  Instance := GetInstance(Plugin);
  if Assigned(Instance) then
    Result := Instance.GetFiles(PanelItems, ItemsNumber, Move, DestPath, OpMode)
  else
    Result := 0;
end;

function _GetFindData(Plugin: THandle; var PanelItem: PPluginPanelItemArr; var ItemsNumber: Integer; OpMode: TPxFarPluginOperationModes): Integer;
var
  Instance: TPxFarPlugin;
begin
  Instance := GetInstance(Plugin);
  if Assigned(Instance) then
    Result := Instance.GetFindData(PanelItem, ItemsNumber, OpMode)
  else
    Result := 0;
end;

procedure _GetOpenPluginInfo(Plugin: THandle; var Info: TOpenPluginInfo);
var
  Instance: TPxFarPlugin;
begin
  Instance := GetInstance(Plugin);
  if Assigned(Instance) then
    Instance.GetOpenPluginInfo(Info)
end;

procedure _GetPluginInfo(var Info: TPluginInfo);
begin
  PxFarPluginClass.GetPluginInfo(Info);
end;

function _GetVirtualFindData(Plugin: THandle; var pPanelItem: PPluginPanelItemArr; var pItemsNumber: Integer; Path: PAnsiChar): Integer;
var
  Instance: TPxFarPlugin;
begin
  Instance := GetInstance(Plugin);
  if Assigned(Instance) then
    Result := Instance.GetVirtualFindData(pPanelItem, pItemsNumber, Path)
  else
    Result := 0;
end;

function _MakeDirectory(Plugin: THandle; Name: PAnsiChar; OpMode: TPxFarPluginOperationModes): Integer;
var
  Instance: TPxFarPlugin;
begin
  Instance := GetInstance(Plugin);
  if Assigned(Instance) then
    Result := Instance.MakeDirectory(Name, OpMode)
  else
    Result := 0;
end;

function _OpenFilePlugin(Name: PAnsiChar; Data: Pointer; DataSize: Integer): THandle;
begin
  Result := INVALID_HANDLE_VALUE;
end;

function _OpenPlugin(OpenFrom: TPxFarPluginOpenFrom; Item: Integer): THandle;
var
  Plugin: TPxFarPlugin;
begin
  Result := PxFarPluginClass.OpenPlugin(OpenFrom, Item);
  if Result <> INVALID_HANDLE_VALUE then
  begin
    Plugin := PxFarPluginClass.Create(Result);
    Instances.Add(Plugin);
  end;
end;

function _ProcessEvent(Plugin: THandle; Event: TPxFarPluginEventType; Param: Pointer): Integer;
var
  Instance: TPxFarPlugin;
begin
  Instance := GetInstance(Plugin);
  if Assigned(Instance) then
    Result := Instance.ProcessEvent(Event, Param)
  else
    Result := 0;
end;

function _ProcessHostFile(Plugin: THandle; PanelItem: PPluginPanelItemArr; ItemsNumber: Integer; OpMode: TPxFarPluginOperationModes): Integer;
var
  Instance: TPxFarPlugin;
begin
  Instance := GetInstance(Plugin);
  if Assigned(Instance) then
    Result := Instance.ProcessHostFile(PanelItem, ItemsNumber, OpMode)
  else
    Result := 0;
end;

function _ProcessKey(Plugin: THandle; Key: Integer; ControlState: TPxFarPluginControlStates): Integer;
var
  Instance: TPxFarPlugin;
begin
  Instance := GetInstance(Plugin);
  if Assigned(Instance) then
    Result := Instance.ProcessKey(Key, ControlState)
  else
    Result := 0;
end;

function _PutFiles(Plugin: THandle; PanelItem: PPluginPanelItemArr; ItemNumber: Integer; Move: Integer; OpMode: TPxFarPluginOperationModes): Integer;
var
  Instance: TPxFarPlugin;
begin
  Instance := GetInstance(Plugin);
  if Assigned(Instance) then
    Result := Instance.PutFiles(PanelItem, Itemnumber, Move, OpMode)
  else
    Result := 0;
end;

function _SetDirectory(Plugin: THandle; Dir: PChar; OpMode: TPxFarPluginOperationModes): Integer;
var
  Instance: TPxFarPlugin;
begin
  Instance := GetInstance(Plugin);
  if Assigned(Instance) then
    Result := Instance.SetDirectory(Dir, OpMode)
  else
    Result := 0;
end;

function _SetFindList(Plugin: THandle; PanelItem: PPluginPanelItemArr; ItemsNumber: Integer): Integer;
var
  Instance: TPxFarPlugin;
begin
  Instance := GetInstance(Plugin);
  if Assigned(Instance) then
    Result := Instance.SetFindList(PanelItem, ItemsNumber)
  else
    Result := 0;
end;

procedure _SetStartupInfo(var Info: TPluginStartupInfo);
begin
  Move(Info, FARAPI, SizeOf(FARAPI));
  PxFarPluginClass.SetStartupInfo(Info);
end;

{ Internal procedures }

procedure Initialize;
begin
  PxFarPluginClass := TPxFarPlugin;
  Instances := TPxFarPluginList.Create;
end;

procedure Finalize;
var
  I: Integer;
begin
  for I := 0 to Instances.Count - 1 do
    Instances[I].Free;
  FreeAndNil(Instances);
end;

function GetInstance(Handle: THandle): TPxFarPlugin;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Instances.Count - 1 do
    if Instances[I].Handle = Handle then
    begin
      Result := Instances[I];
      Break;
    end;
end;

initialization
  Initialize;

finalization
  Finalize;

end.
