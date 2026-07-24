@echo off
:: Check for administrative privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Administrative privileges confirmed. Starting cleanup...
    echo ---------------------------------------------------------
) else (
    echo CRITICAL ERROR: This script must be run as an Administrator!
    echo Right-click the script and select "Run as administrator".
    echo ---------------------------------------------------------
    pause
    exit /b
)

:: 1. Clear User Temp Folder (%temp%)
echo [1/6] Cleaning User Temp Folder...
del /q /f /s "%temp%\*.*" >nul 2>&1
for /d %%i in ("%temp%\*") do rmdir /q /s "%%i" >nul 2>&1

:: 2. Clear System Temp Folder (C:\Windows\Temp)
echo [2/6] Cleaning System Temp Folder...
del /q /f /s "C:\Windows\Temp\*.*" >nul 2>&1
for /d %%i in ("C:\Windows\Temp\*") do rmdir /q /s "%%i" >nul 2>&1

:: 3. Clear Prefetch Folder
echo [3/6] Cleaning Prefetch Folder...
del /q /f /s "C:\Windows\Prefetch\*.*" >nul 2>&1
for /d %%i in ("C:\Windows\Prefetch\*") do rmdir /q /s "%%i" >nul 2>&1

:: 4. Clear Windows Update Cache (SoftwareDistribution)
echo [4/6] Cleaning Windows Update Cache...
echo Stopping Windows Update Service...
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1

del /q /f /s "C:\Windows\SoftwareDistribution\Download\*.*" >nul 2>&1
for /d %%i in ("C:\Windows\SoftwareDistribution\Download\*") do rmdir /q /s "%%i" >nul 2>&1

echo Restarting Windows Update Service...
net start wuauserv >nul 2>&1
net start bits >nul 2>&1

:: 5. Clear Windows Log Files
echo [5/6] Cleaning Windows Log Files...
del /q /f /s "C:\Windows\Logs\*.*" >nul 2>&1

:: 6. Run Windows Built-in Disk Cleanup (Silent Mode)
echo [6/6] Launching Windows Disk Cleanup Manager...
:: This runs the standard manager preset. To fully automate, look up 'sageset' and 'sagerun' options.
cleanmgr /sagerun:1

echo ---------------------------------------------------------
echo Cleanup Complete! Any remaining files were locked and in use by Windows.
pause