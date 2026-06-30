@echo off
title Complete Backdoor Removal (Aggressive)
echo [*] Removing all traces of WindowsUpdateService...

:: Stop all PowerShell processes (except this one)
echo [*] Stopping processes...
taskkill /f /im powershell.exe /fi "pid ne %random%" 2>nul

:: Remove scheduled tasks
echo [*] Removing scheduled tasks...
schtasks /delete /tn WindowsUpdateService /f 2>nul
schtasks /delete /tn WindowsUpdateService_User /f 2>nul
schtasks /delete /tn WindowsUpdateService_Admin /f 2>nul
schtasks /delete /tn "Microsoft\Windows\WindowsUpdate\UpdateService" /f 2>nul

:: Remove registry entries
echo [*] Removing registry entries...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v WindowsUpdateService /f 2>nul
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v WindowsUpdateService /f 2>nul
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v WindowsUpdateService /f 2>nul
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v WindowsUpdateService /f 2>nul

:: Remove startup shortcuts
echo [*] Removing startup shortcuts...
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\WindowsUpdateService.lnk" /f /q 2>nul
del "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\Startup\WindowsUpdateService.lnk" /f /q 2>nul
del "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Startup\WindowsUpdateService.lnk" /f /q 2>nul

:: Delete payload folders
echo [*] Deleting payload folders...
rmdir /s /q "%ProgramData%\Microsoft\Windows\Update" 2>nul
rmdir /s /q "%APPDATA%\Microsoft\Windows\Update" 2>nul

:: Delete any remaining .ps1 files
echo [*] Deleting any remaining payload files...
del /f /q "%TEMP%\*.ps1" 2>nul
del /f /q "%ProgramData%\Microsoft\Windows\*.ps1" 2>nul
del /f /q "%APPDATA%\Microsoft\Windows\*.ps1" 2>nul

:: Remove Defender exclusions
echo [*] Removing Defender exclusions...
powershell -command "Remove-MpPreference -ExclusionPath '%ProgramData%\Microsoft\Windows\Update' -ErrorAction SilentlyContinue; Remove-MpPreference -ExclusionPath '%APPDATA%\Microsoft\Windows\Update' -ErrorAction SilentlyContinue; Remove-MpPreference -ExclusionProcess 'powershell.exe' -ErrorAction SilentlyContinue"

:: Clear event logs (optional)
echo [*] Clearing event logs...
wevtutil cl System 2>nul
wevtutil cl Security 2>nul
wevtutil cl Application 2>nul
wevtutil cl "Windows PowerShell" 2>nul

:: Reset WiFi if it was weakened
echo [*] Resetting WiFi...
netsh interface ip set address "Wi-Fi" dhcp 2>nul
netsh interface ip set dns "Wi-Fi" dhcp 2>nul
netsh interface set interface "Wi-Fi" admin=enabled 2>nul

echo [*] Cleanup complete! Rebooting in 5 seconds...
shutdown /r /t 5