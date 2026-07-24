@echo off
:: Check for administrative privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    goto MAIN
) else (
    echo Requesting administrative privileges...
    goto UACPrompt
)

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "cmd.exe", "/c %~s0", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /b

:MAIN
cls
echo =======================================================
echo     Windows 10/11 Network Path Error 0x80070035 Fix
echo =======================================================
echo.

:: VIDEO ADDITION: Disable SMB Client Digitally Sign Communications (Always)
echo [1/7] Disabling SMB Client Digitally Signed Communications...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v RequireSecureNegotiate /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >nul 2>&1
:: The direct policy mapping for "Digitally sign communications (always)"
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v EnableSecuritySignature /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v RequireSecuritySignature /t REG_DWORD /d 0 /f >nul 2>&1
echo Done.
echo.

:: VIDEO ADDITION: Turn Off Password Protected Sharing (All Networks fallback)
echo [2/7] Turning off Password Protected Sharing...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v everyoneincludesanonymous /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v ForceGuest /t REG_DWORD /d 0 /f >nul 2>&1
echo Done.
echo.

:: STEP 1: Enable SMBv1 Client
echo [3/7] Enabling SMB 1.0/CIFS Client...
dism /online /Enable-Feature /FeatureName:SMB1Protocol-Client /NoRestart
echo.

:: STEP 2 & 3: Change NetBIOS Settings via Registry for all network adapters
echo [4/7] Enabling NetBIOS over TCP/IP...
for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" /s ^| findstr /i "NetbiosOptions"') do (
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\%%a" /v NetbiosOptions /t REG_DWORD /d 1 /f >nul 2>&1
)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v AllowMultipleNetworkInterfaces /t REG_DWORD /d 1 /f >nul 2>&1
echo.

:: STEP 4: Enable and Start Crucial Network Services
echo [5/7] Configuring and starting required network services...

echo Starting Function Discovery Provider Host...
sc config fdPHost start= auto
net start fdPHost >nul 2>&1

echo Starting Function Discovery Resource Publication...
sc config FDResPub start= auto
net start FDResPub >nul 2>&1

echo Starting SSDP Discovery...
sc config SSDPSRV start= auto
net start SSDPSRV >nul 2>&1

echo Starting UPnP Device Host...
sc config upnphost start= auto
net start upnphost >nul 2>&1

echo Starting TCP/IP NetBIOS Helper...
sc config lmhosts start= auto
net start lmhosts >nul 2>&1
echo.

:: STEP 5: Allow Insecure Guest Logins
echo [6/7] Enabling Insecure Guest Logons (Lanman Workstation)...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v AllowInsecureGuestAuth /t REG_DWORD /d 1 /f
echo.

:: STEP 6: Refresh network stack configuration
echo [7/7] Flushing DNS and resetting Winsock...
ipconfig /flushdns >nul
netsh winsock reset >nul
echo.

echo =======================================================
echo ALL ACTIONS COMPLETED!
echo =======================================================
echo A system restart is highly recommended for changes to bind.
echo.
set /p choice="Would you like to restart your PC now? (Y/N): "
if /i "%choice%"=="Y" shutdown /r /t 5
if /i "%choice%"=="y" shutdown /r /t 5

exit