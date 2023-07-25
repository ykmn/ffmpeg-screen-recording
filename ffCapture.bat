@echo off
:: ffmpeg Screen Capture
:: captures desktop screen and send stream via RTMP to %server%
:: only video, no sound captured
:: 2020-06-06 - v1.00 Initial version
:: 2023-07-25 - v1.01 Typo fixes
cd "%~dp0"

:: 'Mount' assuming workstation name ot another ID of a recording session.
:: You can have one server recording video from different workstations, so
:: set mount name and port here
set mount=europa-vi-ctrl
set server=localhost:8889


cls
echo ffmpeg Screen Capture v1.01 [2023-07-25]
echo.
if not exist "%~dp0\log\." mkdir "%~dp0\log"
if not exist "%~dp0\ffmpeg\ffmpeg.exe" (
  echo There's no ffmpeg.exe in .\ffmpeg folder.
  echo Please download Windows ffmpeg binaries and put *.exe and *.dll from 'bin' to .\ffmpeg
  echo URL: https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl-shared.zip
  powershell -NoProfile -ExecutionPolicy unrestricted -Command "(New-Object Net.WebClient).DownloadFile('https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl-shared.zip', 'ffmpeg-master-latest-win64-gpl-shared.zip')"
  pause
  exit
)
if not exist "%~dp0\ffmpeg\." mkdir "%~dp0\ffmpeg"
title ffCapture for %mount%


:loop
:: parsing current date and time assuming the region settings in Windows DD.MM.YYYY :)
set YEAR=%DATE:~-4%
set MONTH=%DATE:~3,2%
if "%MONTH:~0,1%" == " " set MONTH=0%MONTH:~1,1%
set DAY=%DATE:~0,2%
if "%DAY:~0,1%" == " " set DAY=0%DAY:~1,1%
set HOUR=%TIME:~0,2%
if "%HOUR:~0,1%" == " " set HOUR=0%HOUR:~1,1%
set MINS=%TIME:~3,2%
set SECS=%TIME:~6,2%
set FFREPORT=file=log/ffCapture-%mount%-%YEAR%%MONTH%%DAY%.log:level=32


echo Deleting logs older than 30 days
forfiles /p "log" /s /d -30 /c "cmd /c del @file" > nul
echo *** %YEAR%-%MONTH%-%DAY% %MINS%:%HOUR%:%SECS% Old logs deleted >> log\ffServer-%mount%-%YEAR%%MONTH%%DAY%.log
echo.

echo Running ffmpeg for screen capture.
ffmpeg\ffmpeg.exe ^
        -f gdigrab -rtbufsize 100M -framerate 4 -probesize 10M -draw_mouse 1 ^
        -i desktop -c:v libx264 -r 12 -preset ultrafast -tune zerolatency ^
        -crf 25 -pix_fmt yuv420p -loglevel "warning" ^
        -f flv rtmp://%server%/live/%mount%

:: -f gdigrab�� ������� ������� ������ Windows;
:: -rtbufsize 100M�� ����� ��� �����. ���������� � ������ ������ ���� ������ � ������, ����� �� ���� ��������� ������. ������� ����� ������� ���������� ����� � ����������� ������, � ����� FFmpeg ��� �������� ��� � �����.
:: -framerate 12�� ������� ������ ��� ������� ������;
:: -probesize 10M�� ���������� ������ ����������� FFmpeg ��� ������������� ������;
:: -draw_mouse 1�� ����������� �������� ����;
:: -i desktop�� ������� FFmpeg ���������� ���� �����;
:: -c:v libx264�� ������� ����� � ������ MP4 ������� x264;
:: -r 12�� ����� ������� ����� � �������� 12 ������ � �������;
:: -preset ultrafast�� ������� ������, ����� ����� �� ���������� � ��������� ����������, ��� ����� ������� (��� ������ ������ ��� ���������);
:: -tune zerolatency�� ����� ������ x264 ��� ��������� �����������;
:: -crf 25�� �������� ������������� ����� (������� �������� � ���� �����, ������� � �����);
:: -pix_fmt yuv420p�� �������� ������ ��������������� �����;
:: -f flv rtmp://address.com:1935/live/rtmp_stream�� ������ � ����� � ������ "rtmp_stream" � �������� ��� �� ������

echo Restarting capture in 2 seconds,
choice /T 2 /C axq /N /D x /M "Press Q to quit."
if errorlevel 3 echo "Q pressed, bye" & goto:quit

goto:loop

:quit
echo *** %YEAR%-%MONTH%-%DAY% %MINS%:%HOUR%:%SECS% Q pressed >> log\ffCapture-%mount%-%YEAR%%MONTH%%DAY%.log
