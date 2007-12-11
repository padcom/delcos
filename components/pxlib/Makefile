include delphi.inc

all: PxLib.bpl
	$(MAKE) -C CLPMaker all
	$(MAKE) -C crccalc all
	$(MAKE) -C ERISGen all
	$(MAKE) -C Tests all
	$(MAKE) -C XRGen all

clean: clean-lib

clean-lib:
	rm -f PxLib.bpl PxLib.dcp
	$(MAKE) -C CLPMaker clean
	$(MAKE) -C crccalc clean
	$(MAKE) -C ERISGen clean
	$(MAKE) -C Tests clean
	$(MAKE) -C XRGen clean

PxLib.bpl: PxLib.dpk pxlib.mo 
