@echo off
title Complete Backdoor Removal
echo [*] Removing all traces of the backdoor...

:: Stop any running PowerShell instances that might be the backdoor
echo [*] Stopping processes...
taskkill /f /im powershell.exe /fi "windowtitle eq Windows Update Service*" 2>nul
taskkill /f /im powershell.exe /fi "windowtitle eq Windows Update*" 2>nul
taskkill /f /im wscript.exe /fi "windowtitle eq Windows Update*" 2>nul

:: Remove Scheduled Tasks
echo [*] Removing scheduled tasks...
schtasks /delete /tn WindowsUpdateService /f 2>nul
schtasks /delete /tn WindowsUpdateService_User /f 2>nul
schtasks /delete /tn Microsoft\Windows\WindowsUpdate\UpdateService /f 2>nul

:: Remove Registry Entries (HKCU and HKLM)
echo [*] Removing registry entries...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v WindowsUpdateService /f 2>nul
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v WindowsUpdateService /f 2>nul
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v WindowsUpdateService /f 2>nul
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v WindowsUpdateService /f 2>nul

:: Remove Startup Shortcuts
echo [*] Removing startup shortcuts...
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\WindowsUpdateService.lnk" /f /q 2>nul
del "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\Startup\WindowsUpdateService.lnk" /f /q 2>nul

:: Delete the payload folders
echo [*] Deleting payload files and folders...
rmdir /s /q "%ProgramData%\Microsoft\Windows\Update" 2>nul
rmdir /s /q "%APPDATA%\Microsoft\Windows\Update" 2>nul
del /f /q "%TEMP%\*.ps1" 2>nul
del /f /q "%TEMP%\payload_log.txt" 2>nul

:: Remove any leftover VBS wrapper
del /f /q "%ProgramData%\Microsoft\Windows\Update\launcher.vbs" 2>nul

:: Remove Windows Defender exclusions
echo [*] Removing Defender exclusions...
powershell -command "Remove-MpPreference -ExclusionPath '%ProgramData%\Microsoft\Windows\Update' -ErrorAction SilentlyContinue; Remove-MpPreference -ExclusionPath '%APPDATA%\Microsoft\Windows\Update' -ErrorAction SilentlyContinue; Remove-MpPreference -ExclusionProcess 'powershell.exe' -ErrorAction SilentlyContinue"

:: Delete the firewall rule (if any from block command)
echo [*] Removing firewall rules...
netsh advfirewall firewall delete rule name="InternetBlock" 2>nul
netsh advfirewall firewall delete rule name="BlockAllOut" 2>nul

:: Reset WiFi settings (if they were weakened)
echo [*] Resetting WiFi...
netsh interface ip set address "Wi-Fi" dhcp 2>nul
netsh interface ip set dns "Wi-Fi" dhcp 2>nul
netsh interface set interface "Wi-Fi" admin=enabled 2>nul

:: Clear event logs (optional, to hide traces)
echo [*] Clearing event logs...
wevtutil cl System 2>nul
wevtutil cl Security 2>nul
wevtutil cl Application 2>nul
wevtutil cl "Windows PowerShell" 2>nul

echo [*] Cleanup complete! Rebooting in 5 seconds...
shutdown /r /t 5