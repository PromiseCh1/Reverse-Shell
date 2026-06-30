# 🔁 Reverse Shell & Persistence Toolkit

> A stealthy, persistent C2 framework for Windows – built for red‑team exercises and cybersecurity education.  
> Provides remote shell, screen streaming, WiFi control, network blocking, DNS flush, and keylogging – with multi‑layer persistence and evasion.

---

## 🧠 Features

-  **Interactive Shell** – Run any PowerShell/CMD command.
-  **Live Screen Streaming** – Continuous screenshots (press `q` to stop).
-  **Single Screenshot** – Capture one frame.
-  **WiFi Control** – Turn on/off, weaken, or fix.
-  **Internet Block** – Block all outbound traffic via firewall.
-  **Internet Unblock** – Remove the rule.
-  **DNS Flush** – Clear DNS cache.
-  **Keylogger** – Global hook (start/stop/dump/clear).
-  **Multi‑Layer Persistence** – Registry, Scheduled Tasks, Startup Folder.
-  **Stealth** – AMSI bypass, Defender exclusion, hidden VBS launcher.
-  **Auto‑Reconnect** – Retries every 10‑30 sec.

---

## 🏗️ Architecture

```
[Attacker]  <──TCP───>  [Victim]
  Python Listener          PowerShell Payload
  Port: 7777               Persistence: Registry + Task Scheduler + Startup
  Menu-driven CLI          Hidden VBS wrapper
```

---

## 📁 Project Structure

```
Reverse-Shell/
├── payload/
│   └── payload.ps1          # Main backdoor
├── installer/
│   └── install.cmd          # One‑click installer
├── cleanup/
│   ├── cleanup.cmd          # Standard removal
│   └── nuke.cmd             # Aggressive removal
├── listener/
│   └── listener.py          # Python C2 listener
└── README.md
```

---

## ⚙️ Requirements

- **Attacker** – Python 3.6+, OpenCV & NumPy  
  `sudo apt install python3-opencv python3-numpy`
- **Victim** – Windows 10/11, PowerShell (admin recommended)

---

## 🚀 Quick Start

### 1. Attacker (Kali)
```bash
git clone https://github.com/your-username/Reverse-Shell.git
cd Reverse-Shell
python3 listener/listener.py
```

### 2. Victim (Windows)
- Copy `payload.ps1` and `install.cmd` to victim.
- **Run `install.cmd` as Administrator**.
- The payload installs persistence and connects immediately.

---

## 💻 Usage

Listener menu:

```
  1. Shell
  2. Single Screenshot
  3. Screen Stream (loop)
  4. WiFi Control
  5. Block Internet
  6. Unblock Internet
  7. DNS Flush
  8. Exit
```

Or type commands directly in the shell.

---

## 📖 Command Reference

| Command | Action |
|---------|--------|
| `whoami`, `dir`, etc. | Any PowerShell/CMD command |
| `screenshot` | Capture one frame |
| `wifioff` / `wifion` | Disable / enable WiFi |
| `wifiweak` | Break internet |
| `wififix` | Restore DHCP |
| `block` / `unblock` | Block/unblock outbound traffic |
| `dnsflush` | Flush DNS cache |
| `keylog_start / stop / dump / clear` | Keylogger control |
| `cd <path>` | Change directory |
| `exit` | Close connection (auto‑reconnect) |

---

## 🧹 Cleanup

Run `cleanup/cleanup.cmd` as Administrator to remove all traces.  
For stubborn leftovers, use `cleanup/nuke.cmd`.

---

## 🛡️ Stealth & Evasion

- AMSI bypass
- Defender exclusion (added by installer)
- Silent VBS launcher
- Three persistence mechanisms
- Auto‑reconnect with jitter

---

## ⚠️ Disclaimer

**For educational and authorised testing only.**  
Unauthorised use is illegal. Obtain explicit written permission before deploying.

---

## 📄 License

MIT – free to use, modify, and distribute with attribution.

---

*Happy (ethical) hacking!* 🚀
Author: Promiseeeeeeee!!!
