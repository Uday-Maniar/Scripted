@echo off
echo [1/5] Enabling Network Discovery...
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes

echo [2/5] Enabling File and Printer Sharing...
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes

echo [3/5] Enabling Public Folder Sharing (Read/Write for Everyone)...
:: This registry key controls the Public Folder sharing toggle in the Control Panel
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "everyoneincludesanonymous" /t REG_DWORD /d 1 /f
:: Granting permissions to the actual Public folder path
icacls "C:\Users\Public" /grant Everyone:(OI)(CI)F /T

echo [4/5] Setting 128-bit Encryption & Turning OFF Password Protection...
reg add "HKLM\System\CurrentControlSet\Control\Lsa\MSV1_0" /v "NtlmMinClientSec" /t REG_DWORD /d 536870912 /f
reg add "HKLM\System\CurrentControlSet\Control\Lsa\MSV1_0" /v "NtlmMinServerSec" /t REG_DWORD /d 536870912 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "restrictnullsessaccess" /t REG_DWORD /d 0 /f
net user guest /active:yes

echo [5/5] DISABLING FIREWALL (Domain, Private, and Public)...
netsh advfirewall set allprofiles state off

echo Restarting network services to apply changes...
net stop lanmanserver /y
net start lanmanserver
net start browse

echo --------------------------------------------------------
echo Done! Network is now wide open for sharing.
echo --------------------------------------------------------
pause