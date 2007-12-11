include delphi.inc

FOPOPTS+= variablelist.max.termlength

.PHONY: validate doc

all: clpmaker.exe doc

clean: clean-prog clean-doc

clean-prog:
	rm -f clpmaker.exe clpmaker.html

clean-doc:
	rm -f clpmaker.html clpmaker.pdf

doc: clpmaker.html clpmaker.pdf

clpmaker.exe: clpmaker.dpr
 