@echo off

cd /D "%VIM_FILEDIR%"

call d:/dev/vc2015/vcvarsall.cmd cl.exe -nologo -O2 -std=c++11 "%VIM_FILEPATH%" 



