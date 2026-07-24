@echo off
:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Run PowerShell command to get BIOS serial number
powershell -Command "Get-WmiObject -Class Win32_Bios | Select-Object -ExpandProperty SerialNumber"
pause
