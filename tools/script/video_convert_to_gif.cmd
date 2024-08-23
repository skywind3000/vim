@echo off

if "%1" == "" goto HELP

set "IN=%1"
set "OUT=%~dpn1.gif"

if "%2" == "" goto NEXT
set "OUT=%2"
:NEXT

call ffmpeg -i "%IN%" -an -c:v gif "%OUT%"

pause

goto END

:HELP
echo usage: video_convert_to_gif ^<input^> [^<output^>]

:END
echo.



