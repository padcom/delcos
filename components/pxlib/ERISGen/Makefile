all: ERISGen.exe ExampleFile.pas

DCC=dcc32

clean:
	rm -f *.~* 
	rm -f *.dcu
	rm -f *.dsk
	rm -f ExampleFile.pas
	rm -f ERISGen.exe

install: ERISGen.exe
	install ERISGen.exe $(BINPATH)

uninstall:
	rm -f $(BINPATH)/ERISGen.exe

ERISGen.exe: ERISGen.dpr
	dcc32 -q -b -n. -dFINALVERSION -u.. ERISGen.dpr
	upx -9 $@

ExampleFile.pas: Example.xdf
	ERISGen.exe -q -i Example.xdf

