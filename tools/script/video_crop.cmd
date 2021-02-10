@echo off

if "%5" == "" goto HELP

set "IN=%1"
set "OUT=%~dpn1_crop%~x1"

if "%6" == "" goto NEXT
set "OUT=%6"
:NEXT


call ffmpeg -i "%IN%" -filter:v "crop=%4:%5:%2:%3" "%OUT%"

pause

goto END

:HELP
echo usage: video_crop ^<input^> ^<x^> ^<y^> ^<w^> ^<h^> [^<output^>]

:END
echo.


