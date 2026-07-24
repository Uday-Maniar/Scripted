@echo off
:: Check for Admin rights; if not, restart as Admin
fltmc >nul 2>&1 || (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Run the command with TLS 1.2 forced and execution policy bypassed
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm https://get.activated.win | iex"

pause