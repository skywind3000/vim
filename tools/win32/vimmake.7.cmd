@ECHO OFF

if "%VIM_FILENAME%" == "" GOTO ERROR_NO_FILE

REM CD /D "%VIM_FILEDIR%"

d:\dev\python25\python.exe d:\dev\mingw\emake.py --ini=d:\software\android-toolchain\android-9\emake.ini "%VIM_FILEPATH%"

GOTO END


:ERROR_NO_FILE
echo missing file name

:END



