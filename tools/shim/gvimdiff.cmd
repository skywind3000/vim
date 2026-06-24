@echo off

if "%2" == "" GOTO HELP

call "C:\Program Files (x86)\Vim\gvim.exe" --remote-send "<ESC>:tabe %~f1<cr>:vert diffsplit %~f2<CR>"
REM call "C:\Program Files (x86)\Vim\vim92\gvim.exe" --remote-send ":call foreground()<CR>"
call "C:\Program Files (x86)\Vim\gvim.exe" --cmd "call remote_foreground('GVIM') | quit!"

GOTO :EXIT


:HELP
echo usage: gvimdiff {file1} {file2}

:EXIT
echo.

