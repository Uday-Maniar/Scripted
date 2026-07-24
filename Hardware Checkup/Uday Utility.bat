@echo off
setlocal EnableDelayedExpansion

:: --- WINDOW RESIZE ---
:: Adjusts the window size so all 28 options fit on one screen
mode con: cols=100 lines=45

:: --- ELEVATION CHECK ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:MENU
cls
color 0F
echo ====================================================================================================
:: --- CUSTOM MULTI-COLOR SIGNATURE ---
powershell -Command "Write-Host '            ULTIMATE SYSTEM ADMINISTRATION UTILITY By ' -NoNewline; Write-Host 'UDAY ' -ForegroundColor Green -NoNewline; Write-Host 'MANIAR' -ForegroundColor Magenta"
echo ====================================================================================================
echo.
powershell -Command "Write-Host ' --- PRINTER TOOLS ---' -ForegroundColor Cyan"
echo  [1] Fix Printer Error 0x0000011b          [2] Advanced Printer Fix (RPC/SMB1)
echo  [3] Printer Spooler Reset (Reg) 
echo.
powershell -Command "Write-Host ' --- NETWORK TOOLS ---' -ForegroundColor Yellow"
echo  [4] Allow Insecure Guest Auth             [5] An Extended Error Has Occured
echo  [6] Network Discovery/Sharing ON          [7] Quick Share Drive
echo  [8] Firewall / Screen Saver OFF
echo.
powershell -Command "Write-Host ' --- SYSTEM & SECURITY ---' -ForegroundColor Red"
echo  [9]  ENABLE UAC (Registry)                [10] DISABLE UAC (Registry)
echo  [11] Turn OFF Bitlocker (C: thru H:)      [12] Get BIOS Serial Number
echo  [13] Enable File Delete Confirmation      [14] Block Adobe Acrobat
echo.
powershell -Command "Write-Host ' --- HARDWARE DIAGNOSTICS ---' -ForegroundColor Green"
echo  [15] Motherboard Details                  [16] Show Computer Name (Hostname)
echo  [17] Show CPU Information                 [18] Harddisk Health Checkup
echo  [19] Show Physical HDD Details            [20] Show RAM Module Details
echo  [21] Max RAM Capacity (Motherboard)
echo.
powershell -Command "Write-Host ' --- GENERAL UTILITIES ---' -ForegroundColor Magenta"
echo  [22] Windows Activation (Online)          [23] Chris Titus Windows Utility
echo  [24] Install .NET Framework 3.5           [25] Restore Windows Photo Viewer
echo  [26] Power Settings (No Sleep)            [27] Update System Date/Time (Deep Fix)
echo.
powershell -Command "Write-Host ' --- FINAL REPORTING ---' -ForegroundColor White"
echo  [28] System Config to Excel (Fixed)       [0] EXIT
echo.
echo ====================================================================================================
set /p "selection=Selection [0-28]: "

if "%selection%"=="" goto MENU

:: Using CALL to keep the window open after a task completes
if "%selection%"=="1" call :PRINTER_11B
if "%selection%"=="2" call :ADV_PRINT
if "%selection%"=="3" call :PRINT_RESET
if "%selection%"=="4" call :GUEST_AUTH
if "%selection%"=="5" call :SMB_FIX
if "%selection%"=="6" call :NET_SET
if "%selection%"=="7" call :QUICK_SHARE
if "%selection%"=="8" call :FW_SS_OFF
if "%selection%"=="9" call :EN_UAC
if "%selection%"=="10" call :DIS_UAC
if "%selection%"=="11" call :BITLOCKER_OFF
if "%selection%"=="12" call :SERIAL
if "%selection%"=="13" call :CONFIRM_DEL
if "%selection%"=="14" call :BLOCK_ADOBE
if "%selection%"=="15" call :MB_INFO
if "%selection%"=="16" call :COMP_NAME
if "%selection%"=="17" call :CPU_INFO
if "%selection%"=="18" call :HDD_HEALTH
if "%selection%"=="19" call :HDD_INFO
if "%selection%"=="20" call :RAM_INFO
if "%selection%"=="21" call :MAX_RAM
if "%selection%"=="22" call :ACTIVATE
if "%selection%"=="23" call :CTT_UTIL
if "%selection%"=="24" call :DOTNET
if "%selection%"=="25" call :PHOTO_VIEW
if "%selection%"=="26" call :POWER_CFG
if "%selection%"=="27" call :TIME_SYNC
if "%selection%"=="28" call :SYS_EXCEL
if "%selection%"=="0" exit

goto MENU

:: --- LOGIC SECTIONS ---

:PRINTER_11B
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Print" /v RpcAuthnLevelPrivacyEnabled /t REG_DWORD /d 0 /f
net stop spooler && net start spooler
pause
goto :eof

:ADV_PRINT
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC" /v RpcOverTcp /t REG_DWORD /d 0 /f
powershell -NoProfile -ExecutionPolicy Bypass -Command "Enable-WindowsOptionalFeature -Online -FeatureName Printing-Foundation-Features, SMB1Protocol, Printing-Foundation-LPRPortMonitor, Printing-Foundation-LPDPrintService -All"
pause
goto :eof

:PRINT_RESET
net stop spooler && net start spooler
pause
goto :eof

:GUEST_AUTH
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "AllowInsecureGuestAuth" /t REG_DWORD /d 1 /f
pause
goto :eof

:SMB_FIX
powershell -NoProfile -Command "Set-SmbClientConfiguration -RequireSecuritySignature $false -Force"
pause
goto :eof

:NET_SET
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes
pause
goto :eof

:QUICK_SHARE
set /p "DRV=Drive Letter: "
set "DPATH=%DRV%:\\"
powershell -NoProfile -Command "New-SmbShare -Name '%DRV%' -Path '%DPATH%' -FullAccess Everyone"
pause
goto :eof

:FW_SS_OFF
netsh advfirewall set allprofiles state off
reg add "HKCU\Control Panel\Desktop" /v "ScreenSaveActive" /t REG_SZ /d 0 /f
pause
goto :eof

:EN_UAC
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d 1 /f
pause
goto :eof

:DIS_UAC
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d 0 /f
pause
goto :eof

:BITLOCKER_OFF
manage-bde -off c:
pause
goto :eof

:SERIAL
wmic bios get serialnumber
pause
goto :eof

:CONFIRM_DEL
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "ConfirmFileDelete" /t REG_DWORD /d 1 /f
pause
goto :eof

:BLOCK_ADOBE
netsh advfirewall firewall add rule name="Adobe Block" dir=out action=block program="C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe"
pause
goto :eof

:MB_INFO
wmic baseboard get product,Manufacturer,version,serialnumber
pause
goto :eof

:COMP_NAME
hostname
pause
goto :eof

:CPU_INFO
wmic cpu get name
pause
goto :eof

:HDD_HEALTH
powershell "Get-PhysicalDisk | Select FriendlyName, HealthStatus"
pause
goto :eof

:HDD_INFO
wmic diskdrive get model,serialnumber,size
pause
goto :eof

:RAM_INFO
wmic memorychip get capacity, speed
pause
goto :eof

:MAX_RAM
wmic memphysical get maxcapacity
pause
goto :eof

:ACTIVATE
powershell "irm https://get.activated.win | iex"
pause
goto :eof

:CTT_UTIL
powershell "irm christitus.com/win | iex"
pause
goto :eof

:DOTNET
dism /online /enable-feature /featurename:NetFx3 /all /quiet /norestart
pause
goto :eof

:PHOTO_VIEW
reg add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".jpg" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
pause
goto :eof

:POWER_CFG
powercfg -change -monitor-timeout-dc 0
powercfg -change -monitor-timeout-ac 0
powercfg -x standby-timeout-ac 0
powercfg -x standby-timeout-dc 0
powercfg -change -disk-timeout-dc 0
powercfg -change -disk-timeout-ac 0
powercfg -x -monitor-timeout-ac 0
pause
goto :eof

:TIME_SYNC
w32tm /resync
pause
goto :eof

:SYS_EXCEL
set "PSFILE=%~dp0New System Config With Escan & QH Without USB.ps1"
if exist "%PSFILE%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%PSFILE%"
) else (
    echo Error: %PSFILE% not found. Make sure the .ps1 file is in the same folder.
)
pause
goto :eof