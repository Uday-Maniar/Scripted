@echo off
set "command=%~dpnx0"

:: 1. Check for Administrator privileges
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Requesting administrative privileges...
    :: Re-launch the script using PowerShell with 'RunAs' verb
    powershell -Command "Start-Process '%command%' -Verb RunAs"
    exit /b
)

:: 2. Execute the PowerShell command
echo Administrative privileges confirmed.
echo Running PowerShell command: Set-SmbClientConfiguration -RequireSecuritySignature $false
echo.

:: NOTE: The '$false' does NOT need to be escaped here, 
:: as the entire string is passed to powershell.exe which interprets it correctly.
powershell -NoProfile -Command "Set-SmbClientConfiguration -RequireSecuritySignature $false -Force"

IF %ERRORLEVEL% EQU 0 (
    echo.
    echo SUCCESS: SMB Client Security Signature requirement has been disabled.
) ELSE (
    echo.
    echo ERROR: The PowerShell command failed. Check the output above for details.
)


exit /b