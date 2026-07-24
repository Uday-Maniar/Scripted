@echo off
:: Check for administrative privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Administrative privileges confirmed.
) else (
    echo [ERROR] Please right-click this file and select "Run as Administrator".
    pause
    exit /b
)

echo Adding registry entry to fix error 0x0000011b...
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print" /v RpcAuthnLevelPrivacyEnabled /t REG_DWORD /d 0 /f

echo Restarting Print Spooler service...
net stop spooler
net start spooler

echo.
echo Process complete. Please restart your computer for changes to fully take effect.
pause
