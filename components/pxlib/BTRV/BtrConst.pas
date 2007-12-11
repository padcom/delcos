//-----------------------------------------------------------------------------
//
//  Copyright 1982-2001 Pervasive Software Inc. All Rights Reserved
//
//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
// BTRCONST.PAS
//   This is the Pascal constants unit for Btrieve 6.x under MS Windows
//   and DOS.  Include this file in the USES clause of your application.
//   For examples, see:
//     MS Windows: btrsampw.pas
//     DOS:        btrsampd.pas
//     Delphi:     btrsam16.pas, btrsam32.pas
//-----------------------------------------------------------------------------

unit BtrConst;

interface

const
  
  //
  // Size Constants
  //
  ACS_SIZE              = 265;    // alternate collating sequence size 
  ACS_FILLER_SIZE       = 260;
  ACS_BYTE_MAP_SIZE     = 256;
  ACS_NAME_SIZE         = 8;
  ISR_TABLE_NAME_SIZE   = 16;
  ISR_FILLER_SIZE       = 248;

  BLOB_HEADER_LEN       = $0014; // record chunk offset 

  MAX_DATABUF_SIZE      = 57000;

  MIN_PAGE              = 512;
  MAX_PAGE              = 4096;
  MAX_KEY_SIZE          = 255;
  MAX_KEY_SEG           = 119;
  OWNER_NAME_SIZE       = 8+1;   // 8 characters + binary 0 
  POS_BLOCK_SIZE        = 128;
  PHYSICAL_POS_BUF_LEN  = 4;     // data buf size for Get Position  
  MAX_FIXED_RECORD_LEN  = 4088;  // maximum fixed record length     
  MAX_STATBUF_SIZE      = 33455; // B_STAT maximum data buffer size 
  MAX_FILE_NAME_LENGTH  = 64;

  //
  // 'Chunk' API Constatnts
  //
  GET_SIGNATURE_INDEX          = $00000004;
  GET_NUM_CHUNKS_INDEX         = $00000008;
  GET_CHUNK_OFFSET_INDEX       = 12;
  GET_CHUNK_LEN_INDEX          = 16;
  GET_USER_DATA_PTR_INDEX      = 20;
 
  UPDATE_SIGNATURE_INDEX       = $00000000;
  UPDATE_NUM_CHUNKS_INDEX      = $00000004;
  UPDATE_CHUNK_OFFSET_INDEX    = $00000008;
  UPDATE_CHUNK_LEN_INDEX       = $00000012;
  UPDATE_USER_DATA_PTR_INDEX   = $00000016;

  RECTANGLE_DIRECT_SIGN        = $80000002;
  RECTANGLE_INDIRECT_SIGN      = $80000003;
  APPEND_TO_BLOB               = $20000000;
  GET_DRTC_XTRACTOR_KEY        = $FFFFFFFE;
  NEXT_IN_BLOB                 = $40000000;
  XTRACTR_INDIRECT_SIGN        = $80000001;
  XTRACTR_DIRECT_SIGN          = $80000000;
  TRUNC_SIGN                   = $80000004;
  PARTS_OF_KEY                 = $00800000;
  TRUNC_AFTER_UPDATE           = $00400000;
  CHUNK_NOBIAS_MASK = (NEXT_IN_BLOB or APPEND_TO_BLOB or PARTS_OF_KEY or TRUNC_AFTER_UPDATE) xor $FFFFFFFF;

  CHUNK_NO_INTERNAL_CURRENCY   = $0001;
  MUST_READ_DATA_PAGE          = $0002;
  NO_INTERNAL_CURRENCY         = 0;

  //
  // Operation Codes
  //
  B_OPEN              = 0;
  B_CLOSE             = 1;
  B_INSERT            = 2;
  B_UPDATE            = 3;
  B_DELETE            = 4;
  B_GET_EQUAL         = 5;
  B_GET_NEXT          = 6;
  B_GET_PREVIOUS      = 7;
  B_GET_GT            = 8;
  B_GET_GE            = 9;
  B_GET_LT            = 10;
  B_GET_LE            = 11;
  B_GET_FIRST         = 12;
  B_GET_LAST          = 13;
  B_CREATE            = 14;
  B_STAT              = 15;
  B_EXTEND            = 16;
  B_SET_DIR           = 17;
  B_GET_DIR           = 18;
  B_BEGIN_TRAN        = 19;
  B_END_TRAN          = 20;
  B_ABORT_TRAN        = 21;
  B_GET_POSITION      = 22;
  B_GET_DIRECT        = 23;
  B_STEP_NEXT         = 24;
  B_STOP              = 25;
  B_VERSION           = 26;
  B_UNLOCK            = 27;
  B_RESET             = 28;
  B_SET_OWNER         = 29;
  B_CLEAR_OWNER       = 30;
  B_BUILD_INDEX       = 31;
  B_DROP_INDEX        = 32;
  B_STEP_FIRST        = 33;
  B_STEP_LAST         = 34;
  B_STEP_PREVIOUS     = 35;
  B_GET_NEXT_EXTENDED = 36;
  B_GET_PREV_EXTENDED = 37;
  B_STEP_NEXT_EXT     = 38;
  B_STEP_PREVIOUS_EXT = 39;
  B_EXT_INSERT        = 40;
  B_MISC_DATA         = 41;
  B_CONTINUOUS        = 42;
  B_SEEK_PERCENT      = 44;
  B_GET_PERCENT       = 45;
  B_CHUNK_UPDATE      = 53;
  B_EXTENDED_STAT     = 65;

  //
  // Operation Bias Codes
  //
  S_WAIT_LOCK    = 100;
  S_NOWAIT_LOCK  = 200;  // function code bias for lock                
  M_WAIT_LOCK    = 300;  // function code bias for multiple loop lock  
  M_NOWAIT_LOCK  = 400;  // function code bias for multiple lock       
 
  WAIT_T         = 119;  // begin transaction with wait (same as 19)   
  NOWAIT_T       = 219;  // begin transaction with nowait              
  WAIT3_T        = 319;  // begin transaction with wait (same as 19)   
  NOWAIT4_T      = 419;  // begin transaction with nowait              
  CCURR_T_BIAS   = 1000; // function code bias for consurrent trans    
  NOWRITE_WAIT   = 500;  // function code bias when ins/del/upd should 

  //
  // Key Number Bias Codes & Special Key Codes
  // The hexadecimal values below are unsigned values
  //
  KEY_BIAS                            = 50;
  DROP_BUT_NO_RENUMBER                = $80;   // key num bias for Drop  
                                               // Preserves key #s       
  CREATE_SUPPLEMENTAL_AS_THIS_KEY_NUM = $80;   // key bias for Create SI 
  CREATE_NEW_FILE                     = $FF;
  DONT_CREATE_WITH_TTS                = $FE;
  CREATE_NEW_FILE_NO_TTS              = $FD;
  IGNORE_KEY                          = $FFFF; // ignore the key number 

  //
  // Btrieve File Open Modes
  // The hexadecimal values below are unsigned values
  //
  NORMAL       = $00; // normal mode        
  ACCELERATED  = $FF; // accelerated mode   
  EXCLUSIVE    = $FC; // exclusive mode     
  MINUSONE     = $FF; // byte value for -1  
  READONLY     = $FE; // read only mode     

  //
  // Btrieve Return Codes
  //
  B_NO_ERROR                          = 0;
  B_INVALID_FUNCTION                  = 1;
  B_IO_ERROR                          = 2;
  B_FILE_NOT_OPEN                     = 3;
  B_KEY_VALUE_NOT_FOUND               = 4;
  B_DUPLICATE_KEY_VALUE               = 5;
  B_INVALID_KEYNUMBER                 = 6;
  B_DIFFERENT_KEYNUMBER               = 7;
  B_POSITION_NOT_SET                  = 8;
  B_END_OF_FILE                       = 9;
  B_MODIFIABLE_KEYVALUE_ERROR         = 10;
  B_FILENAME_BAD                      = 11;                                                  
  B_FILE_NOT_FOUND                    = 12;
  B_EXTENDED_FILE_ERROR               = 13;
  B_PREIMAGE_OPEN_ERROR               = 14;
  B_PREIMAGE_IO_ERROR                 = 15;
  B_EXPANSION_ERROR                   = 16;
  B_CLOSE_ERROR                       = 17;
  B_DISKFULL                          = 18;
  B_UNRECOVERABLE_ERROR               = 19;
  B_RECORD_MANAGER_INACTIVE           = 20;
  B_KEYBUFFER_TOO_SHORT               = 21;
  B_DATALENGTH_ERROR                  = 22;
  B_POSITIONBLOCK_LENGTH              = 23;
  B_PAGE_SIZE_ERROR                   = 24;
  B_CREATE_IO_ERROR                   = 25;
  B_NUMBER_OF_KEYS                    = 26;
  B_INVALID_KEY_POSITION              = 27;
  B_INVALID_RECORD_LENGTH             = 28;
  B_INVALID_KEYLENGTH                 = 29;
  B_NOT_A_BTRIEVE_FILE                = 30;
  B_FILE_ALREADY_EXTENDED             = 31;
  B_EXTEND_IO_ERROR                   = 32;
  B_BTR_CANNOT_UNLOAD                 = 33;
  B_INVALID_EXTENSION_NAME            = 34;
  B_DIRECTORY_ERROR                   = 35;
  B_TRANSACTION_ERROR                 = 36;
  B_TRANSACTION_IS_ACTIVE             = 37;
  B_TRANSACTION_FILE_IO_ERROR         = 38;
  B_END_TRANSACTION_ERROR             = 39;
  B_TRANSACTION_MAX_FILES             = 40;
  B_OPERATION_NOT_ALLOWED             = 41;
  B_INCOMPLETE_ACCEL_ACCESS           = 42;
  B_INVALID_RECORD_ADDRESS            = 43;
  B_NULL_KEYPATH                      = 44;
  B_INCONSISTENT_KEY_FLAGS            = 45;
  B_ACCESS_TO_FILE_DENIED             = 46;
  B_MAXIMUM_OPEN_FILES                = 47;
  B_INVALID_ALT_SEQUENCE_DEF          = 48;
  B_KEY_TYPE_ERROR                    = 49;
  B_OWNER_ALREADY_SET                 = 50;
  B_INVALID_OWNER                     = 51;
  B_ERROR_WRITING_CACHE               = 52;
  B_INVALID_INTERFACE                 = 53;
  B_VARIABLE_PAGE_ERROR               = 54;
  B_AUTOINCREMENT_ERROR               = 55;
  B_INCOMPLETE_INDEX                  = 56;
  B_EXPANED_MEM_ERROR                 = 57;
  B_COMPRESS_BUFFER_TOO_SHORT         = 58;
  B_FILE_ALREADY_EXISTS               = 59;
  B_REJECT_COUNT_REACHED              = 60;
  B_SMALL_EX_GET_BUFFER_ERROR         = 61;
  B_INVALID_GET_EXPRESSION            = 62;
  B_INVALID_EXT_INSERT_BUFF           = 63;
  B_OPTIMIZE_LIMIT_REACHED            = 64;
  B_INVALID_EXTRACTOR                 = 65;
  B_RI_TOO_MANY_DATABASES             = 66;
  B_RIDDF_CANNOT_OPEN                 = 67;
  B_RI_CASCADE_TOO_DEEP               = 68;
  B_RI_CASCADE_ERROR                  = 69;
  B_RI_VIOLATION                      = 71;
  B_RI_REFERENCED_FILE_CANNOT_OPEN    = 72;
  B_RI_OUT_OF_SYNC                    = 73;
  B_END_CHANGED_TO_ABORT              = 74;
  B_RI_CONFLICT                       = 76;
  B_CANT_LOOP_IN_SERVER               = 77;
  B_DEAD_LOCK                         = 78;
  B_PROGRAMMING_ERROR                 = 79;
  B_CONFLICT                          = 80;
  B_LOCKERROR                         = 81;
  B_LOST_POSITION                     = 82;
  B_READ_OUTSIDE_TRANSACTION          = 83;
  B_RECORD_INUSE                      = 84;
  B_FILE_INUSE                        = 85;
  B_FILE_TABLE_FULL                   = 86;
  B_NOHANDLES_AVAILABLE               = 87;
  B_INCOMPATIBLE_MODE_ERROR           = 88;
  
  B_DEVICE_TABLE_FULL                 = 90;
  B_SERVER_ERROR                      = 91;
  B_TRANSACTION_TABLE_FULL            = 92;
  B_INCOMPATIBLE_LOCK_TYPE            = 93;
  B_PERMISSION_ERROR                  = 94;
  B_SESSION_NO_LONGER_VALID           = 95;
  B_COMMUNICATIONS_ERROR              = 96;
  B_DATA_MESSAGE_TOO_SMALL            = 97;
  B_INTERNAL_TRANSACTION_ERROR        = 98;
  B_REQUESTER_CANT_ACCESS_RUNTIME     = 99;
  B_NO_CACHE_BUFFERS_AVAIL            = 100;
  B_NO_OS_MEMORY_AVAIL                = 101;
  B_NO_STACK_AVAIL                    = 102;
  B_CHUNK_OFFSET_TOO_LONG             = 103;
  B_LOCALE_ERROR                      = 104;
  B_CANNOT_CREATE_WITH_BAT            = 105;
  B_CHUNK_CANNOT_GET_NEXT             = 106;
  B_CHUNK_INCOMPATIBLE_FILE           = 107;
  
  B_TRANSACTION_TOO_COMPLEX           = 109;
  
  B_ARCH_BLOG_OPEN_ERROR              = 110;
  B_ARCH_FILE_NOT_LOGGED              = 111;
  B_ARCH_FILE_IN_USE                  = 112;
  B_ARCH_LOGFILE_NOT_FOUND            = 113;
  B_ARCH_LOGFILE_INVALID              = 114;
  B_ARCH_DUMPFILE_ACCESS_ERROR        = 115;
  
  B_NO_SYSTEM_LOCKS_AVAILABLE         = 130;
  B_FILE_FULL                         = 132;
  B_MORE_THAN_5_CONCURRENT_USERS      = 133;
  
  B_ISR_READ_ERROR                    = 134; // Old definition     
  B_ISR_NOT_FOUND                     = 134; // New definition     
  
  B_ISR_FORMAT_INVALID                = 135; // No Longer returned 
  B_ACS_NOT_FOUND                     = 136;
  B_CANNOT_CONVERT_RP                 = 137;
  B_INVALID_NULL_INDICATOR            = 138;
  B_INVALID_KEY_OPTION                = 139;
  B_INCOMPATIBLE_CLOSE                = 140;
  B_INVALID_USERNAME                  = 141;
  B_INVALID_DATABASE                  = 142;
  B_NO_SSQL_RIGHTS                    = 143;
  B_ALREADY_LOGGED_IN                 = 144;
  B_NO_DATABASE_SERVICES              = 145;
  B_DUPLICATE_SYSTEM_KEY              = 146;
  B_LOG_SEGMENT_MISSING               = 147;
  B_ROLL_FORWARD_ERROR                = 148;
  B_SYSTEM_KEY_INTERNAL               = 149;
  B_DBS_INTERNAL_ERROR                = 150;
  B_NESTING_DEPTH_ERROR               = 151;
  
  
  B_INVALID_PARAMETER_TO_MKDE         = 160;
  
  B_USER_COUNT_LIMIT_EXCEEDED         = 161;
  
  // Windows Client Return codes
  B_LOCK_PARM_OUTOFRANGE              = 1001;
  B_MEM_ALLOCATION_ERR                = 1002;
  B_MEM_PARM_TOO_SMALL                = 1003;
  B_PAGE_SIZE_PARM_OUTOFRANGE         = 1004;
  B_INVALID_PREIMAGE_PARM             = 1005;
  B_PREIMAGE_BUF_PARM_OUTOFRANGE      = 1006;
  B_FILES_PARM_OUTOFRANGE             = 1007;
  B_INVALID_INIT_PARM                 = 1008;
  B_INVALID_TRANS_PARM                = 1009;
  B_ERROR_ACC_TRANS_CONTROL_FILE      = 1010;
  B_COMPRESSION_BUF_PARM_OUTOFRANGE   = 1011;
  B_INV_N_OPTION                      = 1012;
  B_TASK_LIST_FULL                    = 1013;
  B_STOP_WARNING                      = 1014;
  B_POINTER_PARM_INVALID              = 1015;
  B_ALREADY_INITIALIZED               = 1016;
  B_REQ_CANT_FIND_RES_DLL             = 1017;
  B_ALREADY_INSIDE_BTR_FUNCTION       = 1018;
  B_CALLBACK_ABORT                    = 1019;
  B_INTF_COMM_ERROR                   = 1020;
  B_FAILED_TO_INITIALIZE              = 1021;
  
  // Btrieve requester status codes
  B_INSUFFICIENT_MEM_ALLOC            = 2001;
  B_INVALID_OPTION                    = 2002;
  B_NO_LOCAL_ACCESS_ALLOWED           = 2003;
  B_SPX_NOT_INSTALLED                 = 2004;
  B_INCORRECT_SPX_VERSION             = 2005;
  B_NO_AVAIL_SPX_CONNECTION           = 2006;
  B_INVALID_PTR_PARM                  = 2007;
  B_CANT_CONNECT_TO_615               = 2008;
  B_CANT_LOAD_MKDE_ROUTER             = 2009;
  B_UT_THUNK_NOT_LOADED               = 2010;
  B_NO_RESOURCE_DLL                   = 2011;
  B_OS_ERROR                          = 2012;
  
  // MKDE Router status codes
  B_MK_ROUTER_MEM_ERROR               = 3000;
  B_MK_NO_LOCAL_ACCESS_ALLOWED        = 3001;
  B_MK_NO_RESOURCE_DLL                = 3002;
  B_MK_INCOMPAT_COMPONENT             = 3003;
  B_MK_TIMEOUT_ERROR                  = 3004;
  B_MK_OS_ERROR                       = 3005;
  B_MK_INVALID_SESSION                = 3006;
  B_MK_SERVER_NOT_FOUND               = 3007;
  B_MK_INVALID_CONFIG                 = 3008;
  B_MK_NETAPI_NOT_LOADED              = 3009;
  B_MK_NWAPI_NOT_LOADED               = 3010;
  B_MK_THUNK_NOT_LOADED               = 3011;
  B_MK_LOCAL_NOT_LOADED               = 3012;
  B_MK_PNSL_NOT_LOADED                = 3013;
  B_MK_CANT_FIND_ENGINE               = 3014;
  B_MK_INIT_ERROR                     = 3015;
  B_MK_INTERNAL_ERROR                 = 3016;
  B_MK_LOCAL_MKDE_DATABUF_TOO_SMALL   = 3017;
  B_MK_CLOSED_ERROR                   = 3018;
  B_MK_SEMAPHORE_ERROR                = 3019;
  B_MK_LOADING_ERROR                  = 3020;
  B_MK_BAD_SRB_FORMAT                 = 3021;
  B_MK_DATABUF_LEN_TOO_LARGE          = 3022;
  B_MK_TASK_TABLE_FULL                = 3023;
  B_MK_INVALID_OP_ON_REMOTE           = 3034;
  
  // PNSL status codes
  B_NL_FAILURE                        = 3101;
  B_NL_NOT_INITIALIZED                = 3102;
  B_NL_NAME_NOT_FOUND                 = 3103;
  B_NL_PERMISSION_ERROR               = 3104;
  B_NL_NO_AVAILABLE_TRANSPORT         = 3105;
  B_NL_CONNECTION_FAILURE             = 3106;
  B_NL_OUT_OF_MEMORY                  = 3107;
  B_NL_INVALID_SESSION                = 3108;
  B_NL_MORE_DATA                      = 3109;
  B_NL_NOT_CONNECTED                  = 3110;
  B_NL_SEND_FAILURE                   = 3111;
  B_NL_RECEIVE_FAILURE                = 3112;
  B_NL_INVALID_SERVER_TYPE            = 3113;
  B_NL_SRT_FULL                       = 3114;
  B_NL_TRANSPORT_FAILURE              = 3115;
  B_NL_RCV_DATA_OVERFLOW              = 3116;
  B_NL_CST_FULL                       = 3117;
  B_NL_INVALID_ADDRESS_FAMILY         = 3118;
  B_NL_NO_AUTH_CONTEXT_AVAILABLE      = 3119;
  B_NL_INVALID_AUTH_TYPE              = 3120;
  B_NL_INVALID_AUTH_OBJECT            = 3121;
  B_NL_AUTH_LEN_TOO_SMALL             = 3122;

  // 
  // File flag definitions
  // The hexadecimal values below are unsigned values.
  //
  VAR_RECS                = $0001;
  BLANK_TRUNC             = $0002;
  PRE_ALLOC               = $0004;
  DATA_COMP               = $0008;
  KEY_ONLY                = $0010;
  BALANCED_KEYS           = $0020;
  FREE_10                 = $0040;
  FREE_20                 = $0080;
  FREE_30                 = FREE_10 or FREE_20;
  DUP_PTRS                = $0100;
  INCLUDE_SYSTEM_DATA     = $0200;
  SPECIFY_KEY_NUMS        = $0400;
  VATS_SUPPORT            = $0800;
  NO_INCLUDE_SYSTEM_DATA  = $1200;

  //
  // Key Flag Definitions
  // The hexadecimal values below are unsigned values
  //
  KFLG_DUP                  = $0001; // Duplicates allowed mask 
  KFLG_MODX                 = $0002; // Modifiable key mask 
  KFLG_BIN                  = $0004; // Binary or extended key type mask 
  KFLG_NUL                  = $0008; // Null key mask 
  KFLG_SEG                  = $0010; // Segmented key mask 
  KFLG_ALT                  = $0020; // Alternate collating sequence mask 
  KFLG_NUMBERED_ACS         = $0420; // Use numbered ACS in File 
  KFLG_NAMED_ACS            = $0C20; // Use named ACS in File 
  KFLG_DESC_KEY             = $0040; // Key stored descending mask 
  KFLG_REPEAT_DUPS_KEY      = $0080; // Dupes handled w/ unique suffix 
  KFLG_EXTTYPE_KEY          = $0100; // Extended key types are specified 
  KFLG_MANUAL_KEY           = $0200; // Manual key which can be optionally null 
                                     // (then key is not inc. in B-tree) 
  KFLG_NOCASE_KEY           = $0400; // Case insensitive key 
  KFLG_KEYONLY_FILE         = $4000; // key only type file 
  KFLG_PENDING_KEY          = $8000; // Set during a create or drop index 
  KFLG_ALLOWABLE_KFLAG_PRE6 = $037F; // before ver 6.0, no nocase. 


  //
  // Extended Key Types
  //
  STRING_TYPE          = 0;
  INTEGER_TYPE         = 1;
  IEEE_TYPE            = 2;
  DATE_TYPE            = 3;
  TIME_TYPE            = 4;
  DECIMAL_TYPE         = 5;
  MONEY_TYPE           = 6;
  LOGICAL_TYPE         = 7;
  NUMERIC_TYPE         = 8;
  BFLOAT_TYPE          = 9;
  LSTRING_TYPE         = 10;
  ZSTRING_TYPE         = 11;
  UNSIGNED_BINARY_TYPE = 14;
  AUTOINCREMENT_TYPE   = 15;
  STS                  = 17;
  NUMERIC_SA           = 18;
  CURRENCY_TYPE        = 19;
  TIMESTAMP_TYPE       = 20;
  WSTRING_TYPE         = 25;
  WZSTRING_TYPE        = 26;


  //
  // ACS Signature Types
  //
  ALT_ID               = $AC;
  COUNTRY_CODE_PAGE_ID = $AD;
  ISR_ID               = $AE;

implementation

end.

