@echo off
REM --- RAM Information Tool ---
REM This script runs two sequential PowerShell commands to display comprehensive memory details.

ECHO.
ECHO =======================================================
ECHO           1. MAX MOTHERBOARD RAM CAPACITY
ECHO =======================================================
ECHO.

REM --- Command 1: Get Max System Memory Capacity ---
REM Note: MaxCapacity is returned in KB, so we divide by 1024*1024 (1MB) to get GB.
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance -ClassName Win32_PhysicalMemoryArray | Select-Object MemoryDevices, @{Name=\"MaxCapacity(GB)\"; Expression={[math]::truncate($_.MaxCapacity / 1048576)}} | Format-List"

ECHO.
ECHO =======================================================
ECHO             2. INSTALLED RAM MODULE DETAILS
ECHO =======================================================
ECHO.

REM --- Command 2: Get Details for Installed Modules ---
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "Write-Host \"--- RAM Module Details ---\"; Get-CimInstance -ClassName Win32_PhysicalMemory | Select-Object DeviceLocator, Manufacturer, PartNumber, SerialNumber, Speed, @{Name=\"Type\"; Expression={ switch ($_.MemoryType) { 20 { \"DDR\" } 21 { \"DDR2\" } 22 { \"DDR2 FB-DIMM\" } 24 { \"DDR3\" } 26 { \"DDR4\" } 34 { \"DDR5\" } default { \"Unknown ($($_.MemoryType))\" } } }}, @{Name=\"Capacity(GB)\"; Expression={ [math]::Round($_.Capacity / 1GB, 2) }} | Format-Table -AutoSize"

echo.
echo --- Operation complete. Press any key to close the window. ---
pause >nul