@ECHO OFF

if "%VIM_FILENAME%" == "" GOTO ERROR_NO_FILE

CD /D "%VIM_FILEDIR%"

rem d:\dev\python25\python.exe d:\software\android-toolchain\nbuild.py run d:\software\android-toolchain\android-9\emake.ini "%VIM_FILENAME%"
d:\dev\mingw\bin\gcc -O3 -Wall "%VIM_FILENAME%" -o "%VIM_FILENOEXT%.exe" -lstdc++ -lgdi32 -lwinmm

GOTO END


:ERROR_NO_FILE
echo missing file name

:END



