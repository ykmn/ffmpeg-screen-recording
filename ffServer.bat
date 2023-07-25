@echo off
:: ffmpeg RTMP Server
:: receives rtmpRTMP stream and saves it to a new file every 1 hour
:: 2020-06-06 - v1 Initial version
:: 2023-07-25 - v1.01 Typo fixes
cd /d "%~dp0"


:: 'Mount' assuming workstation name ot another ID of a recording session.
:: You need to run separate ffServer for each mount, however you may run it
:: on the same port, so set the port here:
set server=localhost:8889

cls
echo ffmpeg Screen Capture Server v1.01 [2023-07-25]
:: get mount name via %1 parameter: ffServer.bat europa-vi-ctrl
if (%1xx) EQU (xx) (
  set mount=EUROPA-VI-CTRL
  echo Usage: ffServer.bat [mountname]
  echo where [mountname] is ID of the recording session.
  echo.
  echo Mountname is not specified, so the hardcoded value will be used.
  echo If it is not okay press Ctrl+C to stop the script, otherwise
  pause
) else (
  set mount=%1
)
title ffServer for %mount%


if not exist "%~dp0\log\." mkdir "%~dp0\log"
if not exist "%~dp0\%mount%\." mkdir "%~dp0\%mount%"
if not exist "%~dp0\ffmpeg\ffmpeg.exe" (
  echo There's no ffmpeg.exe in .\ffmpeg folder.
  echo Please download Windows ffmpeg binaries and put *.exe and *.dll from 'bin' to .\ffmpeg
  echo URL: https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl-shared.zip
  powershell -NoProfile -ExecutionPolicy unrestricted -Command "(New-Object Net.WebClient).DownloadFile('https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl-shared.zip', 'ffmpeg-master-latest-win64-gpl-shared.zip')"
  pause
  exit
)
if not exist "%~dp0\ffmpeg\." mkdir "%~dp0\ffmpeg"

:loop
:: parsing current date and time assuming it's the Russian region settings in Windows DD.MM.YYYY :)
set YEAR=%DATE:~-4%
set MONTH=%DATE:~3,2%
if "%MONTH:~0,1%" == " " set MONTH=0%MONTH:~1,1%
set DAY=%DATE:~0,2%
if "%DAY:~0,1%" == " " set DAY=0%DAY:~1,1%
set HOUR=%TIME:~0,2%
if "%HOUR:~0,1%" == " " set HOUR=0%HOUR:~1,1%
set MINS=%TIME:~3,2%
set SECS=%TIME:~6,2%
set FFREPORT=file=LOG/ffServer-%mount%-%YEAR%%MONTH%%DAY%.log:level=32


echo.
echo Deleting logs older than 30 days
forfiles /p "log" /s /d -30 /c "cmd /c del @file" > nul
echo *** %YEAR%-%MONTH%-%DAY% %MINS%:%HOUR%:%SECS% Old logs deleted >> log\ffServer-%mount%-%YEAR%%MONTH%%DAY%.log
echo.
echo Deleting videos older than 30 days
forfiles /p "%mount%" /s /d -30 /c "cmd /c del @file" > nul
echo *** %YEAR%-%MONTH%-%DAY% %MINS%:%HOUR%:%SECS% Old videos deleted >> log\ffServer-%mount%-%YEAR%%MONTH%%DAY%.log
echo.

echo Running ffmpeg as listening server.
ffmpeg\ffmpeg ^
        -f flv -listen 1 -i rtmp://%server%/live/%mount% -c copy ^
	-f segment -segment_time 3600 -strftime 1 -loglevel "warning" ^
	"%mount%\%mount% %%Y%%m%%d-%%H-%%M-%%S.mp4"

echo Restarting server in 2 seconds.
choice /T 2 /C axq /N /D x /M "Press Q to quit."
if errorlevel 3 echo "Q pressed, bye" & goto:quit
goto:loop

:quit
echo *** %YEAR%-%MONTH%-%DAY% %MINS%:%HOUR%:%SECS% Q pressed >> log\ffServer-%mount%-%YEAR%%MONTH%%DAY%.log
