@echo off
REM --- This script executes the PowerShell command to display detailed Physical Disk information. ---

PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "Write-Host \"`n--- Physical Disk Details ---\"; Get-PhysicalDisk | Select-Object Manufacturer, Model, SerialNumber, MediaType, @{Name=\"Capacity(GB)\"; Expression={ [math]::Round($_.Size / 1GB, 2) }} | Format-Table -AutoSize"

echo.
echo --- Press any key to close the window. ---
pause >nul