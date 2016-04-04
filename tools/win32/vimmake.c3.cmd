@echo off

cd /D "%VIM_FILEDIR%"

call d:/dev/vc2010/vcvarsall.cmd cl.exe -nologo -O2 "%VIM_FILEPATH%" 



