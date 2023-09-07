@echo off
title pt tool help
setlocal enabledelayedexpansion

echo runing "adb devices"
REM Run the "adb devices" command and store the output in a variable
for /f "tokens=*" %%a in ('adb devices') do (
  set "output=%%a"
)

::Check device is present or not

if "%output%" == "List of devices attached" (
 echo No Device Found
 echo Waiting for 5 seconds...
 timeout /t 5 /nobreak >nul
 exit
)

::filter device ID

REM Split the output by spaces and store the required part in a variable
for /f "tokens=1" %%b in ('echo !output!') do (
  set "dev=%%b"
)

::Check test app installed or not
echo running "Checking Test App"

REM Run the "adb shell pm list packages | grep co.poynt.maximtest" command and store the output in variable
for /f "tokens=*" %%a in ('adb shell pm list packages ^| grep co.poynt.maximtest') do (
  set "mode=%%a"
)

if "%mode%"=="package:co.poynt.maximtest" (
  set mode=test
) else (
  set mode=km
)

echo.
echo Device - !dev!
echo Mode - !mode!
echo.
echo Changing Environment Variables
if not "%device%"=="0" setx POYNT_DEVICE %dev%
if not "%mode%"=="0" setx POYNT_MODE %mode%

echo.
echo Environment variables saved

goto main

:SetFromReg
    "%WinDir%\System32\Reg" QUERY "%~1" /v "%~2" > "%TEMP%\_envset.tmp" 2>NUL
    for /f "usebackq skip=2 tokens=2,*" %%A IN ("%TEMP%\_envset.tmp") do (
        echo/set %~3=%%B
    )
    goto :EOF

:: Get a list of environment variables from registry
:GetRegEnv
    "%WinDir%\System32\Reg" QUERY "%~1" > "%TEMP%\_envget.tmp"
    for /f "usebackq skip=2" %%A IN ("%TEMP%\_envget.tmp") do (
        if /I not "%%~A"=="Path" (
            call :SetFromReg "%~1" "%%~A" "%%~A"
        )
    )
    goto :EOF

:main
    echo/@echo off >"%TEMP%\_env.cmd"

    :: Slowly generating final file
    call :GetRegEnv "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" >> "%TEMP%\_env.cmd"
    call :GetRegEnv "HKCU\Environment">>"%TEMP%\_env.cmd" >> "%TEMP%\_env.cmd"

    :: Special handling for PATH - mix both User and System
    call :SetFromReg "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" Path Path_HKLM >> "%TEMP%\_env.cmd"
    call :SetFromReg "HKCU\Environment" Path Path_HKCU >> "%TEMP%\_env.cmd"

    :: Caution: do not insert space-chars before >> redirection sign
    echo/set Path=%%Path_HKLM%%;%%Path_HKCU%% >> "%TEMP%\_env.cmd"

    :: Cleanup
    del /f /q "%TEMP%\_envset.tmp" 2>nul
    del /f /q "%TEMP%\_envget.tmp" 2>nul

    :: Set these variables
    call "%TEMP%\_env.cmd"

    echo.
    echo Starting PT Tool...
    echo.

pt

:end
echo Bye!
