@ECHO OFF

if "%VIM_FILENAME%" == "" GOTO ERROR_NO_FILE

if "%VIM_FILEEXT%" == ".c" GOTO COMPILE_C
if "%VIM_FILEEXT%" == ".cc" GOTO COMPILE_CPP
if "%VIM_FILEEXT%" == ".cpp" GOTO COMPILE_CPP
if "%VIM_FILEEXT%" == ".h" GOTO COMPILE_C
if "%VIM_FILEEXT%" == ".cxx" GOTO COMPILE_CPP
if "%VIM_FILEEXT%" == ".erl" GOTO COMPILE_ERLANG
if "%VIM_FILEEXT%" == ".gv" GOTO COMPILE_GV
if "%VIM_FILEEXT%" == ".dot" GOTO COMPILE_GV
if "%VIM_FILEEXT%" == ".v" GOTO COMPILE_VERILOG
if "%VIM_FILEEXT%" == ".vl" GOTO COMPILE_VERILOG

:COMPILE_C
REM CD /D "%VIM_FILEDIR%"
d:\dev\mingw32\bin\gcc -Wall -O1 -finline-functions -g "%VIM_FILEPATH%" -o "%VIM_FILEDIR%/%VIM_FILENOEXT%" -lwinmm -lstdc++ -lgdi32 -lws2_32 -mavx -static 
GOTO END

:COMPILE_CPP
REM CD /D "%VIM_FILEDIR%"
d:\dev\mingw32\bin\gcc -Wall -O1 -finline-functions -g -std=c++11 "%VIM_FILEPATH%" -o "%VIM_FILEDIR%/%VIM_FILENOEXT%" -lwinmm -lstdc++ -lgdi32 -lws2_32 -mavx -static
GOTO END

:COMPILE_ERLANG
d:\dev\erl8.2\bin\erlc.exe -W -o "%VIM_FILEDIR%" "%VIM_FILEPATH%"
GOTO END

:COMPILE_GV
echo dot "%VIM_FILEPATH%" -Tpng -o "%VIM_FILEDIR%\%VIM_FILENOEXT%.png"
d:\dev\tools\graphviz\bin\dot "%VIM_FILEPATH%" -Tpng -o "%VIM_FILEDIR%\%VIM_FILENOEXT%.png"
GOTO END

:COMPILE_VERILOG
d:\dev\iverilog\bin\iverilog -o "%VIM_FILEDIR%\%VIM_FILENOEXT%.vvp" "%VIM_FILEPATH%"
GOTO END

:ERROR_NO_FILE
echo missing file name

:END


