@echo off
:: Check for administrative privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Running with Administrator privileges...
) else (
    echo [ERROR] Please right-click and Run as Administrator.
    pause
    exit /b
)

echo ---------------------------------------------------------
echo 1. BLOCKING FIREWALL TRAFFIC (IN/OUT)
echo ---------------------------------------------------------
:: Define the path (Adjust if your Acrobat is in a different folder)
set "AcroPath=C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe"
set "ArmPath=C:\Program Files (x86)\Common Files\Adobe\ARM\1.0\AdobeARM.exe"

netsh advfirewall firewall add rule name="Adobe Acrobat - Block Out" dir=out action=block program="%AcroPath%" enable=yes
netsh advfirewall firewall add rule name="Adobe Acrobat - Block In" dir=in action=block program="%AcroPath%" enable=yes
netsh advfirewall firewall add rule name="Adobe ARM - Block Out" dir=out action=block program="%ArmPath%" enable=yes
netsh advfirewall firewall add rule name="Adobe ARM - Block In" dir=in action=block program="%ArmPath%" enable=yes

echo ---------------------------------------------------------
echo 2. STOPPING AND DISABLING SERVICES
echo ---------------------------------------------------------
:: Stopping Acrobat Update Service
sc stop AdobeARMservice
sc config AdobeARMservice start= disabled

:: Stopping Genuine Integrity Service
sc stop AGSService
sc config AGSService start= disabled

echo ---------------------------------------------------------
echo 3. DISABLING SCHEDULED TASKS
echo ---------------------------------------------------------
schtasks /change /tn "Adobe Acrobat Update Task" /disable
schtasks /change /tn "AdobeGCInvoker-1.0" /disable

echo ---------------------------------------------------------
echo DONE! Adobe Acrobat is now restricted from the internet.
echo ---------------------------------------------------------
pause