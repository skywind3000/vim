@ECHO OFF

if "%VIM_FILENAME%" == "" GOTO ERROR_NO_FILE

CD /D "%VIM_FILEDIR%"

d:\dev\python25\python.exe d:\software\android-toolchain\nbuild.py run d:\software\android-toolchain\android-9\emake.ini "%VIM_FILENAME%"

GOTO END


:ERROR_NO_FILE
echo missing file name

:END



