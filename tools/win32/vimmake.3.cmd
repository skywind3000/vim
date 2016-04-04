@ECHO OFF

if "%VIM_FILENAME%" == "" GOTO ERROR_NO_FILE

REM CD /D "%VIM_FILEDIR%"

REM CD > e:\lesson\tmp\error.log

rem d:\dev\python25\python.exe d:\dev\mingw\emake.py "%VIM_FILEDIR%/%VIM_FILENAME%" 
d:\dev\python25\python.exe d:\dev\mingw\emake.py --cfg=mingw32 "%VIM_FILEDIR%/%VIM_FILENAME%" 

GOTO END


:ERROR_NO_FILE
echo missing file name

:END
EXIT


