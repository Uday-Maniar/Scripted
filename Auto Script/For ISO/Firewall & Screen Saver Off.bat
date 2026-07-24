@echo off
echo Requesting administrative privileges to open Command Prompt and disable Firewall...
:: Launch a new Command Prompt window with administrative privileges and execute the command
powershell -Command "Start-Process cmd -ArgumentList '/c netsh advfirewall set allprofiles state off' -Verb RunAs"
powershell -Command "Start-Process cmd -ArgumentList '/c powercfg -change -monitor-timeout-dc 0'
powershell -Command "Start-Process cmd -ArgumentList '/c powercfg -change -monitor-timeout-ac 0'
powershell -Command "Start-Process cmd -ArgumentList '/c powercfg -x standby-timeout-ac 0'
powershell -Command "Start-Process cmd -ArgumentList '/c powercfg -x standby-timeout-dc 0'
powershell -Command "Start-Process cmd -ArgumentList '/c powercfg -change -disk-timeout-dc 0'
powershell -Command "Start-Process cmd -ArgumentList '/c powercfg -change -disk-timeout-ac 0'
exit