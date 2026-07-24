@echo off
REM --- This script executes the PowerShell command to display detailed RAM information. ---

PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "Write-Host \"`n--- RAM Module Details ---\"; Get-CimInstance -ClassName Win32_PhysicalMemory | Select-Object DeviceLocator, Manufacturer, PartNumber, SerialNumber, Speed, @{Name=\"Type\"; Expression={ switch ($_.MemoryType) { 20 { \"DDR\" } 21 { \"DDR2\" } 22 { \"DDR2 FB-DIMM\" } 24 { \"DDR3\" } 26 { \"DDR4\" } 34 { \"DDR5\" } default { \"Unknown ($($_.MemoryType))\" } } }}, @{Name=\"Capacity(GB)\"; Expression={ [math]::Round($_.Capacity / 1GB, 2) }} | Format-Table -AutoSize"

echo.
echo --- Press any key to close the window. ---
pause >nul