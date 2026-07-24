@echo off
:: Check for administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process -FilePath '%0' -Verb RunAs"
    exit /b
)

:: Run the Chris Titus Tech Windows Utility command in PowerShell
echo Running CTT Windows Utility as Administrator...
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://christitus.com/win | iex"

pause