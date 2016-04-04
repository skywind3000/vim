@ECHO OFF

if "%VIM_FILENAME%" == "" GOTO ERROR_NO_FILE

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
if "%VIM_FILEEXT%" == ".pro" GOTO RUN_PROLOG
if "%VIM_FILEEXT%" == ".scala" GOTO RUN_SCALA
if "%VIM_FILEEXT%" == ".erl" GOTO RUN_ERLANG
if "%VIM_FILEEXT%" == ".clj" GOTO RUN_CLOJURE
if "%VIM_FILEEXT%" == ".hs" GOTO RUN_HASKELL

if "%VIM_FILEEXT%" == ".dot" GOTO RUN_GRAPHVIZ
if "%VIM_FILEEXT%" == ".gv" GOTO RUN_GRAPHVIZ

if "%VIM_FILEEXT%" == ".bxrc" GOTO RUN_BOCHS

if "%VIM_FILEEXT%" == ".v" GOTO RUN_VERILOG
if "%VIM_FILEEXT%" == ".vl" GOTO RUN_VERILOG

echo unsupported file type %VIM_FILEEXT%
GOTO END

:RUN_MAIN
"%VIM_FILENOEXT%"
GOTO END

:RUN_PY
d:\dev\python36\python "%VIM_FILENAME%"
GOTO END

:RUN_CMD
cmd /C "%VIM_FILENAME%"
GOTO END

:RUN_NODE
node.exe "%VIM_FILENAME%"
GOTO END

:RUN_PROLOG
start d:\dev\swipl\bin\swipl-win.exe -s "%VIM_FILENAME%"
EXIT

:RUN_SCALA
SET SCALA=d:\dev\scala\scala-2.11.6
%SCALA%\bin\scala.cmd -cp %SCALA%\lib\scala-actors-2.11.0.jar;%SCALA%\lib\akka-actor_2.11-2.3.4.jar;%SCALA%\lib\*.jar "%VIM_FILENAME%"
GOTO END

:RUN_ERLANG
d:\dev\erl8.2\bin\erl.exe
EXIT
GOTO END

:RUN_CLOJURE
d:\dev\clojure-1.8.0\clojure
GOTO END

:RUN_HASKELL
D:\Dev\ghc\ghc-8.0.1\bin\ghci.exe "%VIM_FILENAME%"
GOTO END

:RUN_GRAPHVIZ
start %VIM_FILENOEXT%.png
GOTO END

:RUN_BOCHS
bochs -q -f "%VIM_FILENAME%"
GOTO END

:RUN_VERILOG
vvp "%VIM_FILEDIR%\%VIM_FILENOEXT%.vvp"

GOTO END

:ERROR_NO_FILE
echo missing filename
GOTO END

:END


