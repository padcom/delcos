@echo off
rem see test2.exe -h for summary
test2.exe -?
pause
test2.exe -h
pause
test2.exe --help
pause
test2.exe -q -i 1234 -s 321 -l 1 -l 2 -p 1;2;3 -r a,c
pause
test2.exe --quiet --integer 1234 --string 321 --string-list 1 --string-list 2 --path 1;2;3 --set a,c
