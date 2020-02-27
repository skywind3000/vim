@echo off
setlocal EnableDelayedExpansion
set "HomeDir=%~dp0"
set "AsyncTask=%HomeDir%asynctask.py"

python "%AsyncTask%" %*
echo.

