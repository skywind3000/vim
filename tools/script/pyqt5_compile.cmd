@echo off

if "%1" == "" goto HELP

set "IN=%1"
set "EXT=%~x1"
set "LOCATE=%~dp1"
set "OUT1=%~dpn1.py"
set "OUT2=%~dpn1_rc.py"

:: echo %IN%
:: echo %EXT%
:: echo %OUT1%
:: echo %OUT2%
:: goto END

if /i "%EXT%"==".ui" goto UIC
if /i "%EXT%"==".qrc" goto QRC

goto END

:UIC
pyuic5 "%IN%" -o "%OUT1%"
goto DONE

:QRC
cd /d "%LOCATE%"
pyrcc5 "%IN%" -o "%OUT2%"
goto DONE

:HELP
echo Usage: %0 ^[*.ui^|*.qrc^]
goto END

:DONE
if not "%ERRORLEVEL%" == "0" pause

:END
echo.


