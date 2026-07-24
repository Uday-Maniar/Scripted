net stop w32time

w32tm /config /manualpeerlist:"time.windows.com" /syncfromflags:manual /update

net start w32time

w32tm /resync