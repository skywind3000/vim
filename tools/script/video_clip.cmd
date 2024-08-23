@echo off

if "%3" == "" goto HELP

set "IN=%1"
set "OUT=%~dpn1_clip%~x1"

if "%4" == "" goto NEXT
set "OUT=%4"
:NEXT

call ffmpeg -i "%IN%" -ss "%2" -to "%3" -c:a copy -c:v copy "%OUT%"

pause

goto END

:HELP
echo usage: video_clip ^<input^> ^<from ^(00:00:00.000^)^> ^<to ^(00:10:00.000^)^> [^<output^>]

:END
echo.


