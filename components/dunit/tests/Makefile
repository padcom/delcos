#$Id: Makefile,v 1.4 2001/02/16 00:56:06 juanco Exp $
ROOT=..

include $(ROOT)\\Rules.mak

bin:
	-$(MKDIR) $(BIN_DIR)
	$(DCC) -B -E$(BIN_DIR) UnitTests.dpr

test:
	$(DCC) -CC -B UnitTests.dpr
	$(BIN_DIR)\\UnitTests.exe -text-mode
