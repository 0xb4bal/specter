---
name: recon
description: >
  Phase 1 reconnaissance for HTB machines. Runs nmap, web enum, service
  fingerprinting. Auto-saves all findings to MEMORY.md and wiki/targets/.
  Checks session_search for prior knowledge on this tech stack before scanning.
version: 1.0.0
platforms: [linux, macos]
metadata:
  hermes:
    tags: [htb, recon, nmap, pentest]
    category: htb
    requires_toolsets: [terminal]
---

# Skill: /recon — Phase 1 Reconnaissance

## When to Use

Trigger: fresh machine, or `/recon` command, or phase = RECON.
Always run session_search first to check if we have prior knowledge.

## Pre-Recon: Check Prior Knowledge

Before running any tool, query session history:

```
session_search: "nmap results [MACHINE_NAME]"
session_search: "Apache [version found in nmap]"
session_search: "techniques that worked [OS type]"
```

If relevant past sessions found: load context, skip redundant steps.

## Step 0: Verify Target

```bash
/htb-api          # verify IP is current, load $TARGET
ping -c 1 $TARGET
export SESSION="$(cat state/session.json | python3 -c "import sys,json; print(json.load(sys.stdin).get('session_id','default'))")"
mkdir -p raw/$SESSION
```

## Step 1: Fast Scan

```bash
nmap -sV -sC -T4 --open $TARGET \
  -oN raw/$SESSION/nmap_fast.txt \
  -oG raw/$SESSION/nmap_fast.grep
cat raw/$SESSION/nmap_fast.txt
```

Parse output immediately — save every open port to MEMORY.md:
```
memory(action="add", target="memory",
       content="[MACHINE_NAME] ports: 22/ssh OpenSSH 8.2, 80/http Apache 2.4.41")
```

## Step 2: Full Port Scan (background)

```bash
nmap -p- -T4 --min-rate 5000 $TARGET \
  -oN raw/$SESSION/nmap_full.txt &
echo "Full scan running in background PID $!"
```

## Step 3: Service Enum (based on Step 1 results)

### Web (port 80/443/8080/8443)
```bash
# Fingerprint
whatweb $TARGET
curl -si http://$TARGET | head -20

# Robots/sitemap
curl -s http://$TARGET/robots.txt
curl -s http://$TARGET/sitemap.xml

# Directory enum
gobuster dir -u http://$TARGET \
  -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt \
  -o raw/$SESSION/gobuster.txt -t 40 -q
```

### SMB (port 445/139)
```bash
crackmapexec smb $TARGET
enum4linux -a $TARGET 2>/dev/null | tee raw/$SESSION/enum4linux.txt
smbclient -L \\\\$TARGET -N 2>/dev/null
```

### FTP (port 21)
```bash
nmap --script ftp-anon,ftp-syst -p 21 $TARGET
ftp -n $TARGET << 'EOF'
user anonymous anonymous@test.com
ls
bye
EOF
```

### SSH (port 22)
```bash
nmap --script ssh-auth-methods,ssh-hostkey -p 22 $TARGET
```

## Step 4: Save All Findings

After each tool, save findings to MEMORY.md. After all steps complete:

```bash
python3 tools/save.py ingest nmap raw/$SESSION/nmap_fast.txt
python3 tools/save.py ingest gobuster raw/$SESSION/gobuster.txt
```

Update wiki/targets/MACHINE_NAME.md with full port table.

## Post-Recon Memory Update

```
memory(action="replace", target="memory",
       old_text="[MACHINE_NAME] ports:",
       content="[MACHINE_NAME] ports: [FULL LIST] | stack: [TECH] | phase: ENUM")
```

## Skill Self-Improvement

After completing recon on a machine:
- If a technique worked better than documented: patch this SKILL.md
- If a service needed special flags: add to the relevant section
- Use: skill_manage(action="patch", name="recon", old_string="...", new_string="...")

## Verification

Recon is complete when:
- [ ] All open ports identified (fast + full scan done)
- [ ] Service versions recorded in MEMORY.md
- [ ] Web paths enumerated (if HTTP present)
- [ ] wiki/targets/MACHINE.md updated
- [ ] Phase set to ENUM in state/session.json
