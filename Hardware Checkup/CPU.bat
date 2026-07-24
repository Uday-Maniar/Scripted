@echo off
title Processor Information
color 

echo.
echo ========================================================
echo        *** Central Processing Unit (CPU) Info ***
echo ========================================================
echo.

REM WMIC command to get selected CPU properties
wmic cpu get Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed /format:table

echo.
echo ========================================================
echo.

REM Optional: Get current CPU load percentage
echo Current CPU Load Percentage:
wmic cpu get LoadPercentage /value | find "LoadPercentage"

echo.
echo ========================================================
echo.
pause