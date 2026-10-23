@echo off
rem Runs at logon (Startup folder). winget only: no elevation, no Windows Update
rem (the organisation's update policy owns that), no Chocolatey, no pause.
rem Relaunch minimised so no console window stays in the way.
if not "%~1"=="min" (
    start "" /min "%~f0" min
    exit /b
)
winget upgrade --all --silent --accept-source-agreements --accept-package-agreements --disable-interactivity >"%LOCALAPPDATA%\upall.log" 2>&1
