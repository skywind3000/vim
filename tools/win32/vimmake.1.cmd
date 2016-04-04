@ECHO OFF

if "%VIM_FILENAME%" == "" GOTO ERROR_NO_FILE
if "%VIM_RUNONCE%" == "1" GOTO ERROR_ONCE

SET VIM_RUNONCE=1

CD /D "%VIM_FILEDIR%"

if "%VIM_FILEEXT%" == ".c" GOTO RUN_MAIN
if "%VIM_FILEEXT%" == ".cpp" GOTO RUN_MAIN
if "%VIM_FILEEXT%" == ".cc" GOTO RUN_MAIN
if "%VIM_FILEEXT%" == ".cxx" GOTO RUN_MAIN

if "%VIM_FILEEXT%" == ".py" GOTO RUN_PY
if "%VIM_FILEEXT%" == ".pyw" GOTO RUN_PY

if "%VIM_FILEEXT%" == ".bat" GOTO RUN_CMD
if "%VIM_FILEEXT%" == ".cmd" GOTO RUN_CMD

if "%VIM_FILEEXT%" == ".js" GOTO RUN_NODE

echo unsupported file type %VIM_FILEEXT%
GOTO END

:RUN_MAIN
"%VIM_FILENOEXT%"
GOTO END

:RUN_PY
python "%VIM_FILENAME%"
GOTO END

:RUN_CMD
cmd /C "%VIM_FILENAME%"
GOTO END

:RUN_NODE
node.exe "%VIM_FILENAME%"
GOTO END

:ERROR_NO_FILE
echo missing filename
GOTO END

:ERROR_ONCE
echo can't run itself
GOTO END

:END


