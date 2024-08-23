@echo off

if "%1" == "" goto HELP

set "IN=%1"
set "OUT=%~dpn1.x265.mp4"

if "%2" == "" goto NEXT
set "OUT=%2"
:NEXT

call ffmpeg -i "%IN%" -c:v libx265 -strict -2 -c:a aac ^
	-pix_fmt yuv420p -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" ^
	"%OUT%"

pause

goto END

:HELP
echo usage: video_convert_to_x265 ^<input^> [^<output^>]

:END
echo.



