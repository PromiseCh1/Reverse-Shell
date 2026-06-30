<#
.SYNOPSIS
    Checks if the reverse‑shell backdoor is installed, persistent, and running.
.DESCRIPTION
    Scans for payload file, registry entries, scheduled tasks, startup shortcut,
    running PowerShell process with the payload command line, and active network connection.
.PARAMETER AttackerIP
    The attacker IP to check for active connection (default: 192.168.100.32).
.PARAMETER Port
    The listener port (default: 7777).
.EXAMPLE
    .\checker.ps1
    .\checker.ps1 -AttackerIP 10.0.0.5 -Port 4444
#>

param(
    [string]$AttackerIP = "192.168.100.32",
    [int]$Port = 7777
)

Write-Host "=== Backdoor Installation Checker ===" -ForegroundColor Cyan

# ---------- Helper Functions ----------
function Test-PathExists {
    param($Path)
    if (Test-Path $Path) { return $true } else { return $false }
}

function Get-RegistryValue {
    param($Path, $Name)
    try {
        $value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
        return $value.$Name
    } catch {
        return $null
    }
}

function Write-Status {
    param($CheckName, $Result)
    if ($Result) {
        Write-Host "  [$([char]0x2714)] $CheckName" -ForegroundColor Green
    } else {
        Write-Host "  [$([char]0x2718)] $CheckName" -ForegroundColor Red
    }
}

# ---------- 1. Payload File ----------
$payloadFile = "$env:ProgramData\Microsoft\Windows\Update\WindowsUpdateService.ps1"
$fileExists = Test-PathExists -Path $payloadFile
Write-Status -CheckName "Payload file exists: $payloadFile" -Result $fileExists

# ---------- 2. Registry (HKCU) ----------
$regHKCU = Get-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WindowsUpdateService"
$regHKCUExists = ($regHKCU -ne $null)
Write-Status -CheckName "Registry HKCU Run entry exists" -Result $regHKCUExists

# ---------- 3. Registry (HKLM) ----------
$regHKLM = Get-RegistryValue -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "WindowsUpdateService"
$regHKLMExists = ($regHKLM -ne $null)
Write-Status -CheckName "Registry HKLM Run entry exists" -Result $regHKLMExists

# ---------- 4. Scheduled Tasks ----------
$task1 = Get-ScheduledTask -TaskName "WindowsUpdateService" -ErrorAction SilentlyContinue
$task2 = Get-ScheduledTask -TaskName "WindowsUpdateService_User" -ErrorAction SilentlyContinue
$taskExists = ($task1 -ne $null -or $task2 -ne $null)
Write-Status -CheckName "Scheduled tasks (WindowsUpdateService*)" -Result $taskExists

# ---------- 5. Startup Folder Shortcut ----------
$startupShortcut = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\WindowsUpdateService.lnk"
$shortcutExists = Test-PathExists -Path $startupShortcut
Write-Status -CheckName "Startup folder shortcut exists" -Result $shortcutExists

# ---------- 6. Running PowerShell Process ----------
$processes = Get-CimInstance -Class Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue
$payloadProcess = $null
if ($processes) {
    foreach ($proc in $processes) {
        if ($proc.CommandLine -match "WindowsUpdateService.ps1") {
            $payloadProcess = $proc
            break
        }
    }
}
$processRunning = ($payloadProcess -ne $null)
Write-Status -CheckName "PowerShell process running with payload" -Result $processRunning

# ---------- 7. Active Network Connection ----------
$conn = netstat -ano | Select-String "$AttackerIP:$Port" | Select-String "ESTABLISHED"
$connectionActive = ($conn -ne $null)
Write-Status -CheckName "Active TCP connection to $AttackerIP : $Port" -Result $connectionActive

# ---------- 8. Defender Exclusion (may require admin) ----------
$exclusionPaths = (Get-MpPreference -ErrorAction SilentlyContinue).ExclusionPath
$defenderExcluded = $false
if ($exclusionPaths) {
    foreach ($path in $exclusionPaths) {
        if ($path -match "Update" -or $path -match "ProgramData") {
            $defenderExcluded = $true
            break
        }
    }
}
if ($defenderExcluded) {
    Write-Status -CheckName "Defender exclusion for payload folder" -Result $true
} else {
    Write-Status -CheckName "Defender exclusion for payload folder" -Result $false
}

# ---------- Summary ----------
Write-Host "`n--- Summary ---" -ForegroundColor Cyan
$allInstalled = ($fileExists -and ($regHKCUExists -or $regHKLMExists -or $taskExists -or $shortcutExists))
$allRunning = ($processRunning -and $connectionActive)

if ($allInstalled -and $allRunning) {
    Write-Host "[+] Backdoor is INSTALLED and ACTIVE (connected)." -ForegroundColor Green
} elseif ($allInstalled -and -not $allRunning) {
    Write-Host "[!] Backdoor is INSTALLED but NOT CURRENTLY CONNECTED." -ForegroundColor Yellow
    Write-Host "    - Start the listener on $AttackerIP : $Port and wait for reconnection (10-30 sec)." -ForegroundColor Yellow
} elseif (-not $allInstalled) {
    Write-Host "[-] Backdoor is NOT INSTALLED or has been removed." -ForegroundColor Red
} else {
    Write-Host "[?] Partially installed – re‑run the installer." -ForegroundColor Magenta
}