---
name: htb-api
description: >
  HTB API integration — spawn machines by name, get live IP, handle IP
  changes after resets, submit flags. Use this at the start of every session
  and whenever the machine IP may have changed.
version: 1.0.0
platforms: [linux, macos]
metadata:
  hermes:
    tags: [htb, hackthebox, api, pentest]
    category: htb
    requires_toolsets: [terminal]
    required_environment_variables:
      - name: HTB_TOKEN
        prompt: "Your HTB App Token (from HTB Dashboard → Settings → API Key → App Token)"
        help: "Get from https://app.hackthebox.com/profile/settings"
        required_for: machine spawn, IP lookup, flag submission
---

# Skill: /htb-api — HTB Machine Lifecycle

## When to Use

- At session start to get/verify TARGET IP
- After machine reset when IP may have changed
- To spawn a new machine by name
- To submit captured flags
- When user says "machine was reset" or pastes a new IP

## IP Change Handling (Core Feature)

When HTB resets a machine and gives a new IP — this is what SPECTER does
automatically instead of asking the user to edit /etc/hosts:

```bash
# Step 1: Get live IP from HTB API
python3 tools/htb.py ip
# → Returns current IP, updates /etc/hosts, updates state/.env

# Step 2: Load the new environment
source state/.env
echo "Target updated: $TARGET ($MACHINE_NAME)"

# Step 3: Update MEMORY.md
# memory(action="replace", target="memory",
#        old_text="active_machine:",
#        content="active_machine: $MACHINE_NAME ($TARGET)")
```

If HTB API returns no active machine:
```bash
# Ask user ONCE for the new IP
# "Machine was reset — paste the new IP:"
# Then: python3 tools/htb.py set-ip $NEW_IP $MACHINE_NAME
```

## Session Start Sequence

Run this at the beginning of every session:

```bash
# 1. Check what machine we're working on (from MEMORY)
# Read MEMORY.md active_machine entry

# 2. Get current IP (handles changes automatically)
python3 tools/htb.py ip

# 3. Load environment
source state/.env

# 4. Verify connectivity
ping -c 1 $TARGET && echo "Target reachable: $TARGET"
```

## Start a Machine by Name

```bash
python3 tools/htb.py start "MachineName"
# → Resolves machine ID via API
# → Spawns machine
# → Polls until IP is available (up to 3 min)
# → Updates /etc/hosts: IP  machinename.htb
# → Writes state/.env with TARGET, MACHINE_NAME, MACHINE_ID
# → Creates wiki/targets/MachineName.md
# → Saves to MEMORY: active_machine: MachineName (IP)
```

## Get Current IP (Most Used)

```bash
python3 tools/htb.py ip
# → Calls GET /api/v4/machine/active
# → If IP changed: updates /etc/hosts, state/.env, MEMORY.md
# → Prints new IP
```

## Submit Flag (Auto-called when HTB{} detected)

```bash
python3 tools/htb.py submit-flag user "HTB{flag_value}"
python3 tools/htb.py submit-flag root "HTB{flag_value}"
# → Calls POST /api/v4/machine/own
# → On success: updates wiki/flags/, state/session.json
# → Triggers Telegram notification automatically
```

## Reset Machine

```bash
python3 tools/htb.py reset
# → Calls POST /api/v4/vm/reset
# → Waits 30s
# → Calls ip to get new IP
# → Updates /etc/hosts, state/.env, MEMORY.md
```

## Verification

After running `python3 tools/htb.py ip`:
- `echo $TARGET` should show current IP
- `ping -c 1 $TARGET` should respond
- `cat /etc/hosts | grep htb` should show updated entry
- MEMORY.md `active_machine:` entry should match

## Pitfalls

- HTB_TOKEN must be App Token format (not JWT)
- VPN must be connected (tun0 must exist)
- If machine shows "no active machine" after reset: machine may still be
  spawning — wait 60s and retry `python3 tools/htb.py ip`
- Rate limit: don't poll more than once per 10s
