#$Id: Makefile,v 1.4 2001/02/16 00:56:06 juanco Exp $
ROOT=..\..

include $(ROOT)\Rules.mak

structure:
	$(DCC) -B diffunit\Project1.dpr 
	$(DCC) -B -DTESTING diffunit\Project1Test.dpr
	$(DCC) -B sameunit\Project1.dpr 
	$(DCC) -B -DTESTING sameunit\Project1Test.dpr

