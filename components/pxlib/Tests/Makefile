include delphi.inc

all: Test.exe
	$(MAKE) -C PxBase all
	$(MAKE) -C PxXmlReader all

clean: clean-prog

clean-prog:
	rm -f Test.exe
	$(MAKE) -C PxBase clean
	$(MAKE) -C PxXmlReader clean

