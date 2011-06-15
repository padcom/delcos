#$Id: Makefile,v 1.4 2001/02/16 00:56:05 juanco Exp $
ROOT=..\..

include $(ROOT)\Rules.mak

structure:
	$(DCC) -B -CC testXpgen.dpr 
	$(BIN_DIR)\testXpgen.exe

guitest:
	$(DCC) -B -CG testXpgen.dpr 
	$(BIN_DIR)\testXpgen.exe  
