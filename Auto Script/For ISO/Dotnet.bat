@echo off
echo Enabling .NET Framework 3.5 with WCF...

REM Check for administrative privileges
fltmc >nul 2>&1 || (
    echo.
    echo This script requires administrative privileges.
    echo Please right-click the script and select "Run as administrator".
    pause >nul
    exit /b 1
)

REM Enable .NET Framework 3.5 (includes .NET 2.0 and 3.0)
echo Enabling .NET Framework 3.5 core components...
DISM /Online /Enable-Feature /FeatureName:NetFx3 /All /Quiet /NoRestart
if %errorlevel% neq 0 (
    echo.
    echo Error: Failed to enable .NET Framework 3.5 core components.
    echo Please check the DISM log file for details:
    echo %windir%\Logs\DISM\dism.log
    goto :end
)

REM Enable WCF HTTP Activation (Optional, but commonly needed for WCF)
echo Enabling WCF HTTP Activation...
DISM /Online /Enable-Feature /FeatureName:WCF-HTTP-Activation /Quiet /NoRestart /all
if %errorlevel% neq 0 (
    echo.
    echo Error: Failed to enable WCF HTTP Activation.  WCF may not function correctly.
    echo Please check the DISM log file for details:
    echo %windir%\Logs\DISM\dism.log
    goto :end
)

REM Enable WCF Non-HTTP Activation (Optional, for protocols like TCP, Named Pipes)
echo Enabling WCF Non-HTTP Activation...
DISM /Online /Enable-Feature /FeatureName:WCF-NonHTTP-Activation /Quiet /NoRestart /all
if %errorlevel% neq 0 (
    echo.
    echo Error: Failed to enable WCF Non-HTTP Activation.  Some WCF protocols may not function.
    echo Please check the DISM log file for details:
    echo %windir%\Logs\DISM\dism.log
    goto :end
)

echo.
echo .NET Framework 3.5 and WCF features enabled successfully.
echo A restart is required to complete the installation.
exit
:end
