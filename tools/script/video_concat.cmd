@echo off

if "%2" == "" goto HELP

set "IN1=%1"
set "IN2=%2"
set "OUT=%~dpn1_%~dpn2_merged.%~x1"

if "%3" == "" goto NEXT
set "OUT=%3"
:NEXT

call ffmpeg -i "%IN1%" -i "%IN2%" ^
	-filter_complex "[0:v][0:a][1:v][1:a]concat=n=2:v=1:a=1[outv][outa]" ^
   	-map "[outv]" -map "[outa]" "%OUT%"

pause

goto END

:HELP
echo usage: video_concat ^<input1^> ^<input2^> [^<output^>]

:END
echo.



