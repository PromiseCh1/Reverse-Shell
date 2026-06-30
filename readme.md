# Reverse Shell & Persistence Toolkit

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.6+](https://img.shields.io/badge/python-3.6+-blue.svg)](https://www.python.org/downloads/)
[![Windows 10/11](https://img.shields.io/badge/Windows-10%2F11-brightgreen.svg)](https://www.microsoft.com/windows)

A stealthy, persistent reverse‑shell framework for Windows, designed for red‑team exercises and educational use. It provides remote command execution, live screen streaming, WiFi manipulation, network blocking, DNS flushing, and a low‑level keylogger – all with multi‑layered persistence and evasion techniques.

---

## 🧠 Features

| Feature | Description |
|---------|-------------|
| **Interactive Shell** | Run any PowerShell / CMD command on the victim. |
| **Live Screen Streaming** | Continuous screenshot stream (press `q` to stop). |
| **Single Screenshot** | Capture one frame and display it. |
| **WiFi Control** | Turn off/on, weaken (break internet), or fix (restore). |
| **Internet Block** | Add a firewall rule to block all outbound traffic. |
| **Internet Unblock** | Remove the blocking rule. |
| **DNS Flush** | Clear the DNS cache (force fresh lookups). |
| **Keylogger** | Hook‑based global keylogger (start/stop/dump/clear). |
| **Multi‑Layer Persistence** | Registry (HKCU + HKLM), Scheduled Tasks, Startup Folder. |
| **Stealth** | AMSI bypass, Defender exclusion, hidden VBS launcher, no console windows. |
| **Auto‑Reconnect** | The payload retries every 10‑30 seconds if the connection drops. |

---

## 🏗️ Architecture
[Attacker Machine] [Victim Machine]
(Python Listener) ←──TCP─── (PowerShell Payload)
Port: 7777 Persistence: Registry + Task Scheduler + Startup
Menu‑driven CLI Hidden process (VBS wrapper)
OpenCV for screen display AMSI bypass & Defender exclusions

text

- The **listener** (`listener.py`) runs on the attacker’s system (Kali/Linux) and accepts one incoming TCP connection.
- The **payload** (`payload.ps1`) connects outbound to the listener, sends system info, and waits for commands.
- All commands are sent as plain text; screenshots are transmitted as base64‑encoded JPEG lines.
- The payload automatically reconnects if the connection drops.

---

## ⚙️ Requirements

### Attacker (Kali / Linux)

- Python 3.6+
- OpenCV and NumPy for screen display:
  ```bash
  sudo apt install python3-opencv python3-numpy   # Kali / Debian
  # or
  pip install opencv-python numpy                # (if using a virtual environment)
Victim (Windows 10/11)
PowerShell (built‑in)

Administrative privileges (recommended for full features, but not strictly required)
🚀 Deployment
1. Attacker Setup
bash
# Clone the repository
git clone https://github.com/your-username/Reverse-Shell.git
cd Reverse-Shell

# Start the listener (default port 7777)
python3 listener/listener.py
The listener will display:

text
[*] Listening on 0.0.0.0:7777
[*] Waiting for victim connection...
2. Victim Installation
Copy payload/payload.ps1 and installer/install.cmd to the victim machine (e.g., via USB).

Right‑click install.cmd and select "Run as administrator".

The installer will:

Copy the payload to %ProgramData%\Microsoft\Windows\Update\

Create a VBS wrapper for silent execution

Add Windows Defender exclusion for the payload folder

Set persistence via:

Registry (HKCU and HKLM)

Scheduled Task (startup and logon)

Startup Folder shortcut

Launch the payload immediately

After reboot, the payload will automatically reconnect to your listener.

💻 Usage
Once a victim connects, the listener displays a menu:

text
==================================================
 C2 Controller
==================================================
  1. Shell
  2. Single Screenshot
  3. Screen Stream (loop)
  4. WiFi Control
  5. Block Internet
  6. Unblock Internet
  7. DNS Flush
  8. Exit
Select:
Option	Action
1. Shell	Enter interactive command mode (type exit to return).
2. Single Screenshot	Capture one frame and display it in an OpenCV window.
3. Screen Stream	Continuously capture screenshots until you press q in the window.
4. WiFi Control	Submenu to turn off/on, weaken, or fix WiFi.
5. Block Internet	Block all outbound traffic via Windows Firewall.
6. Unblock Internet	Remove the blocking rule.
7. DNS Flush	Clear the DNS cache.
8. Exit	Shut down the listener.
You can also send commands directly from the shell (option 1) without using the menu.

📖 Command Reference
Command	Description
whoami, dir, ipconfig, etc.	Any PowerShell/CMD command
screenshot	Capture one frame and display it
wifioff / wifion	Disable / enable WiFi adapter
wifiweak	Break internet (set static IP + wrong DNS)
wififix	Restore DHCP and correct DNS
block	Block all outbound traffic
unblock	Remove the blocking rule
dnsflush	Flush DNS cache
keylog_start	Start the keylogger (global hook)
keylog_stop	Stop the keylogger
keylog_dump	Retrieve captured keystrokes (saved to keylog/ folder)
keylog_clear	Clear the in‑memory keylog buffer
cd <path>	Change working directory
exit	Close the connection (payload will reconnect later)
🧹 Cleanup
To completely remove the backdoor from a victim machine, run cleanup/cleanup.cmd as Administrator. It will:

Stop any running instances of the backdoor

Delete all scheduled tasks

Remove Registry entries (HKCU and HKLM)

Delete Startup shortcuts

Remove payload folders and files

Remove Windows Defender exclusions

Delete firewall rules (InternetBlock, BlockAllOut)

Reset WiFi settings (if they were weakened)

Clear event logs (optional)

If the standard cleanup fails, use the more aggressive cleanup/nuke.cmd.

Manual Verification
After cleanup, run these commands to confirm:

cmd
schtasks /query | findstr UpdateService
reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v WindowsUpdateService
dir "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\WindowsUpdateService.lnk"
dir "%ProgramData%\Microsoft\Windows\Update"
netsh advfirewall firewall show rule name="InternetBlock"
powershell -command "Get-MpPreference | Select-Object -ExpandProperty ExclusionPath"
All should return "not found" or empty.

🛡️ Stealth & Evasion Techniques
Technique	Implementation
AMSI Bypass	Disables AMSI scanning using reflection.
Defender Exclusion	install.cmd adds the payload folder to exclusions.
Silent Execution	VBS wrapper launches PowerShell with WindowStyle=0.
Low‑Level Keylogger	Uses WH_KEYBOARD_LL hook to capture keys globally.
Persistence	Three independent mechanisms ensure survival after reboot.
Process Hiding	The payload runs as a regular PowerShell process with no visible console.
Random Reconnect	Waits 10‑30 seconds before retrying a lost connection.
Log Cleaning	cleanup.cmd clears Windows event logs to remove traces.
⚠️ Disclaimer
This tool is for educational and authorized security testing only. Unauthorized use on systems you do not own or lack explicit permission to test is illegal. The authors are not responsible for any misuse or damage caused by this software. Always obtain written consent from the system owner before deploying any red‑team tool.

📄 License
This project is licensed under the MIT License – you are free to use, modify, and distribute it, provided that the original copyright notice is retained.

🤝 Contributing
Contributions are welcome! Please open an issue or submit a pull request for any improvements, bug fixes, or new features.

📬 Contact
For questions or suggestions, open an issue on the GitHub repository or contact the maintainer directly.