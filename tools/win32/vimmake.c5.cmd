@echo off
set PATH=d:\dev\mingw64\bin;$PATH

rem d:\dev\mingw64\bin\gcc -Wall -O3 -S "%VIM_FILEPATH%" -o "%VIM_FILEDIR%/%VIM_FILENOEXT%.exe" 
rem d:\dev\mingw64\bin\gcc --version

call d:\dev\vc2017\vcvarsall.cmd cl.exe -nologo -O2 /arch:AVX "%VIM_FILEPATH%" -o "%VIM_FILEDIR%/%VIM_FILENOEXT%.exe"





