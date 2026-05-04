# SPECTER — HTB Agent Project Context
# AGENTS.md — loaded by Hermes from working directory at startup

## Project: SPECTER HTB Agent

This is an HTB penetration testing workspace.
Every file in this directory is part of the SPECTER agent system.

## Architecture

```
specter-htb/
├── SOUL.md                    ← Hermes personality (loaded globally)
├── AGENTS.md                  ← This file (loaded at session start)
├── skills/                    ← Hermes SKILL.md files (slash commands)
│   ├── recon/SKILL.md         → /recon
│   ├── exploit/SKILL.md       → /exploit
│   ├── privesc/SKILL.md       → /privesc
│   ├── web/SKILL.md           → /web
│   ├── windows/SKILL.md       → /windows
│   ├── report/SKILL.md        → /report
│   └── htb-api/SKILL.md       → /htb-api
├── wiki/                      ← Persistent knowledge base
│   ├── targets/               ← One .md per HTB machine
│   ├── techniques/            ← Reusable attack patterns
│   ├── sessions/              ← Checkpoint files
│   └── flags/                 ← Captured flags
├── state/                     ← Runtime state
│   ├── session.json           ← Current machine, phase, findings
│   ├── scope.txt              ← Authorized IPs
│   └── .htb_token             ← HTB API token (gitignored)
└── tools/                     ← Python helpers
    ├── htb.py                 ← HTB API: start/ip/reset/submit
    └── save.py                ← Auto-save findings + checkpoints
```

## Session Start Protocol

EVERY session begins with this sequence — no exceptions:

```
1. Read MEMORY.md (check active_machine, last_ip, current_phase)
2. Run: python3 tools/htb.py ip  (verify/refresh TARGET IP from HTB API)
3. Run: source state/.env        (load TARGET, MACHINE_NAME into shell)
4. Check: wiki/sessions/ for latest checkpoint if resuming
5. Set phase context and begin loop
```

## How IP Changes Are Handled (Manual Mode)

When HTB resets a machine and gives a new IP:
- You check MEMORY.md for `active_machine` name
- You run `python3 tools/htb.py ip` which calls HTB API and returns current IP
- You update /etc/hosts automatically
- You update state/.env and state/session.json
- You continue from last checkpoint
- User never touches /etc/hosts manually

If HTB API is unavailable:
- You ask user to paste the new IP once: "What's the new IP for [machine_name]?"
- You then do all the above automatically
- You save new IP to MEMORY.md entry for that machine

## Recursive Loop

```
ITERATION N:
  OBSERVE    → Last tool output + MEMORY.md + session.json
  HYPOTHESIZE → 3 ranked attack vectors
  PLAN       → Exact command for top vector
  EXECUTE    → Run tool (Hermes auto-saves skill improvements)
  REFINE     → null: update wiki, loop / hit: announce + escalate
```

## Memory Usage Rules

Agent uses Hermes MEMORY.md for:
- `active_machine: NAME (IP)` — always current
- `last_phase: RECON/ENUM/EXPLOIT/PRIVESC` — survives context resets
- `MACHINE flags: user=X root=X` — permanent record
- `[MACHINE] owned via: TECHNIQUE` — technique that worked
- `[TECHNIQUE] works on: STACK` — cross-machine learning

Agent uses session_search for:
- "What did we try on [machine_name]?"
- "Which technique worked on Apache 2.4.x?"
- "What was the privesc path for Linux with SUID bash?"

## Skill Auto-Improvement

After every machine owned:
1. Review which techniques worked
2. Patch the relevant SKILL.md with the exact commands that worked
3. Note what failed so future sessions skip those paths

This is how SPECTER gets smarter over time — not just with each conversation
but across every machine ever touched.

## Telegram Notifications (Auto-Sent)

These fire without being asked:
- Flag captured: `🚩 [MACHINE] USER FLAG: HTB{...}`
- Flag captured: `☠️ [MACHINE] ROOT FLAG: HTB{...}`  
- Checkpoint saved: `💾 Checkpoint saved — [MACHINE] Phase [X] Iteration [N]`
- Machine owned: `🎯 OWNED: [MACHINE] — user+root in [TIME]`
- IP changed: `🔄 [MACHINE] IP updated: OLD → NEW`

## Output Format

```xml
<thinking>[chain of thought — what do findings show, what are 3 vectors, why this one]</thinking>
<phase>[RECON|ENUM|EXPLOIT|POST_EXPLOIT|PRIVESC]</phase>
<plan>[selected vector, exact command]</plan>
<saved>[what was auto-saved to MEMORY.md this iteration]</saved>
<state>
TARGET: $TARGET | MACHINE: $MACHINE_NAME | PHASE: X | ITER: N
PORTS: N | VULNS: N | USER: ✓/✗ | ROOT: ✓/✗
</state>
```
