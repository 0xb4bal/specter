---
name: report
description: >
  Generate a complete HTB writeup and submit to wiki. Reads from MEMORY.md,
  wiki/targets/, and session history to compile the full attack chain.
  Produces markdown writeup ready to share.
version: 1.0.0
platforms: [linux, macos]
metadata:
  hermes:
    tags: [htb, report, writeup]
    category: htb
---

# Skill: /report — HTB Writeup Generator

## When to Use

After machine is fully owned (user + root flags captured).

## Procedure

### Step 1: Gather All Data

```
session_search: "[MACHINE_NAME] recon"
session_search: "[MACHINE_NAME] exploit"
session_search: "[MACHINE_NAME] privesc"
```

Read:
- wiki/targets/MACHINE_NAME.md
- wiki/flags/MACHINE_NAME.md
- state/session.json (full findings)
- MEMORY.md (technique entries)

### Step 2: Generate Writeup

Write to `wiki/reports/MACHINE_NAME_writeup.md`:

```markdown
# HTB Writeup: MACHINE_NAME

**OS:** Linux/Windows | **Difficulty:** Easy/Medium/Hard
**Owned:** DATE | **Time:** HH:MM
**User flag:** HTB{...} | **Root flag:** HTB{...}

## Attack Chain

```
Recon → [SERVICE] → [VULN] → Initial Access → [PRIVESC] → Root
```

## Enumeration

[Summarize key nmap/web findings]

## Exploitation — Initial Access

[Exact commands that worked, with output snippets]

## Privilege Escalation

[Exact commands that worked, with output snippets]

## Lessons Learned

[What to try first on similar stacks next time]

## Tools Used

| Tool | Purpose | Command |
|------|---------|---------|
```

### Step 3: Update Memory with Writeup Path

```
memory(action="add", target="memory",
       content="[MACHINE_NAME] writeup: wiki/reports/MACHINE_NAME_writeup.md")
```

### Step 4: Telegram Notification

Send writeup summary to Telegram bot automatically.

## Verification

Writeup complete when:
- [ ] Full attack chain documented
- [ ] Exact commands reproducible
- [ ] Lessons learned section written
- [ ] Memory updated with writeup path
- [ ] wiki/index.md updated with machine entry
