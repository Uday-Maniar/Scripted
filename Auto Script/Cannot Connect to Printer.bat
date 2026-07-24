@echo off
setlocal EnableDelayedExpansion

:: --- SECTION 1: ELEVATE PRIVILEGES ---
:: Checks for admin rights and re-runs as admin if necessary
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"
    echo Administrative permissions confirmed. 

---

:: --- SECTION 2: REGISTRY FIXES ---
echo Applying Registry Printer Connection Fixes... 

:: Fix for RpcAuthnLevelPrivacyEnabled 
reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Print" /v RpcAuthnLevelPrivacyEnabled /t REG_DWORD /d 0 /f 

:: Create Printers and RPC keys 
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /f 
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC" /f 

:: Apply RPC Policy Values 
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC" /v RpcOverTcp /t REG_DWORD /d 0 /f 
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC" /v RpcUseNamedPipeProtocol /t REG_DWORD /d 1 /f 

echo Registry fixes applied successfully. [cite: 2]

---

:: --- SECTION 3: WINDOWS FEATURES ---
echo Enabling Windows Printing Features and SMB1... 

:: Execute PowerShell to enable features [cite: 4]
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Enable-WindowsOptionalFeature -Online -FeatureName Printing-Foundation-Features, Printing-Foundation-LPDPrintService, Printing-Foundation-LPRPortMonitor, SMB1Protocol -All" 

echo.
echo Process complete. [cite: 4]
echo IMPORTANT: Please restart your computer for all changes to take effect. [cite: 2, 4]
pause