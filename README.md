# SPECTER — HTB Penetration Testing Agent

> Autonomous Hack The Box agent powered by **Hermes** + **DeepSeek V4 Pro**

[![Hermes](https://img.shields.io/badge/Powered%20by-Hermes%20Agent-blueviolet?style=flat-square)](https://github.com/NousResearch/hermes-agent)
[![DeepSeek](https://img.shields.io/badge/Model-DeepSeek%20V4%20Pro-blue?style=flat-square)](https://platform.deepseek.com)
[![HTB](https://img.shields.io/badge/Platform-HackTheBox-9FEF00?style=flat-square&logo=hackthebox&logoColor=black)](https://hackthebox.com)
[![Telegram](https://img.shields.io/badge/Interface-Telegram%20Bot-26A5E4?style=flat-square&logo=telegram)](https://core.telegram.org/bots)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

```
 ███████╗██████╗ ███████╗ ██████╗████████╗███████╗██████╗
 ██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝██╔════╝██╔══██╗
 ███████╗██████╔╝█████╗  ██║        ██║   █████╗  ██████╔╝
 ╚════██║██╔═══╝ ██╔══╝  ██║        ██║   ██╔══╝  ██╔══██╗
 ███████║██║     ███████╗╚██████╗   ██║   ███████╗██║  ██║
 ╚══════╝╚═╝     ╚══════╝ ╚═════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
```

SPECTER is a fully autonomous HTB penetration testing agent built on [Hermes Agent](https://github.com/NousResearch/hermes-agent) — the self-improving AI agent framework from Nous Research. Unlike Claude Code-based agents, SPECTER has **persistent cross-session memory**, **self-improving skills**, **Telegram-native notifications**, and **automatic IP continuity** when HTB resets machines.

---

## Why Hermes Over Claude Code

| Feature | Claude Code | SPECTER (Hermes) |
|---------|------------|-----------------|
| Memory across sessions | ❌ Starts blank every time | ✅ MEMORY.md — persists every finding |
| Self-improving skills | ❌ Static skill files | ✅ Skills patch themselves after each machine |
| Cross-session search | ❌ No history | ✅ FTS5 SQLite — recall any past session |
| Telegram interface | ❌ Terminal only | ✅ Native gateway — full conversation from phone |
| Cron automation | ❌ Manual triggers only | ✅ Scheduled IP monitor, auto-checkpoint |
| IP change handling | ❌ Manual /etc/hosts edit | ✅ HTB API auto-resolves, zero user input |
| Flag auto-submission | ❌ Manual | ✅ Regex detects + submits via HTB API |
| Context window recovery | ❌ Start over | ✅ Checkpoint every 8 iterations, resume anywhere |

---

## How It Works

```
┌─────────────────────────────────────────────────────────┐
│                      SPECTER LOOP                       │
│                                                         │
│  Telegram ──► Hermes Gateway ──► DeepSeek V4 Pro        │
│                     │                                   │
│              SOUL.md (identity)                         │
│              AGENTS.md (project context)                │
│              MEMORY.md (persistent findings)            │
│              skills/ (evolving playbooks)               │
│                     │                                   │
│  OBSERVE → HYPOTHESIZE → PLAN → EXECUTE → REFINE        │
│                     │                                   │
│  HTB API ◄──────────┤ auto-submit flags                 │
│  /etc/hosts ◄───────┤ auto-update on IP change          │
│  Telegram ◄─────────┘ flag capture / checkpoint notify  │
└─────────────────────────────────────────────────────────┘
```

### The IP Change Problem — Solved

When HTB resets a machine and assigns a new IP (same machine, different address), SPECTER handles it automatically:

1. Cron job polls HTB API every 5 minutes (`wakeAgent: false` when no change → zero LLM cost)
2. On IP change detected: updates `/etc/hosts`, `state/.env`, `MEMORY.md` entry
3. Sends Telegram: `🔄 TwoMillion IP updated: 10.10.11.227 → 10.10.11.235`
4. Continues from last checkpoint — no context lost

You never touch `/etc/hosts` manually.

---

## Features

### 🧠 Persistent Memory (Hermes-Native)

SPECTER's `MEMORY.md` grows with every machine:

```
active_machine: TwoMillion (10.10.11.227)
last_phase: PRIVESC
TwoMillion ports: 22/ssh OpenSSH 8.2, 80/http Apache 2.4.41
TwoMillion owned via: LFI → log poisoning → RCE, then sudo /usr/bin/dd SUID
[TECHNIQUE] LFI log poison works on: Apache, Nginx with error logging
[TECHNIQUE] sudo dd privesc: copy /etc/passwd, add root user
```

Next machine on Apache → SPECTER tries LFI first because it remembers.

### ⚡ Self-Improving Skills

After owning a machine, SPECTER patches its own skill files:

```python
skill_manage(action="patch", name="exploit",
             old_string="# LFI payloads",
             new_string="# LFI payloads\n# ✓ Apache 2.4.41: /var/log/apache2/access.log via User-Agent")
```

Skills get smarter with every engagement. Never re-derive what already worked.

### 📱 Telegram Interface

Talk to SPECTER from your phone while it works. All notifications fire automatically:

```
You:      Start machine TwoMillion and begin recon

SPECTER:  Machine spawned. IP: 10.10.11.227
          Nmap fast scan running.
          
          Ports: 22/ssh, 80/http
          Apache 2.4.41 on port 80.
          Running feroxbuster.

SPECTER:  🚩 TwoMillion USER FLAG: HTB{r3v3rs3_3ng1n33r1ng_...}
          
SPECTER:  ☠️ TwoMillion ROOT FLAG: HTB{4dm1n_t0k3n_...}
SPECTER:  🎯 OWNED: TwoMillion — user+root in 2h 14m
```

### 🕐 Cron Automation

Two scheduled jobs run without any user interaction:

**IP Monitor** (every 5 min) — uses `wakeAgent: false` when IP unchanged, meaning near-zero cost to run constantly. Wakes the agent only when the IP actually changes.

**Checkpoint saver** (every 8 iterations) — writes compressed state to `wiki/sessions/`, sends Telegram summary. Restart any session from any checkpoint.

---

## Project Structure

```
specter-htb/
├── SOUL.md                    ← Agent identity (Hermes global personality)
├── AGENTS.md                  ← Project context (loaded at every session start)
├── config.yaml                ← Hermes config: DeepSeek, Telegram, cron, skills
├── setup.sh                   ← One-command setup wizard
├── .env.example               ← Environment variables template
│
├── skills/                    ← Hermes SKILL.md files (slash commands)
│   ├── htb-api/SKILL.md       → /htb-api   (spawn, IP resolve, flag submit)
│   ├── recon/SKILL.md         → /recon     (nmap, web enum, service fingerprint)
│   ├── exploit/SKILL.md       → /exploit   (web, network, Metasploit)
│   ├── privesc/SKILL.md       → /privesc   (Linux + Windows LPE)
│   └── report/SKILL.md        → /report    (HTB writeup generator)
│
├── wiki/                      ← LLM-maintained knowledge base
│   ├── targets/               ← One .md per HTB machine
│   ├── techniques/            ← Reusable attack patterns
│   ├── sessions/              ← Checkpoint files (resume points)
│   └── flags/                 ← Captured flags archive
│
├── state/
│   ├── session.json           ← Current machine, phase, findings, iteration count
│   ├── scope.txt              ← Authorized IP ranges (HTB standard ranges pre-loaded)
│   └── .htb_token             ← HTB API token (gitignored)
│
└── tools/
    ├── htb.py                 ← HTB API v4: spawn/ip/reset/submit-flag
    └── save.py                ← Auto-save engine + checkpoint generator
```

### How Hermes Context Files Work Here

| File | Hermes Role | What SPECTER Uses It For |
|------|-------------|--------------------------|
| `SOUL.md` | Global personality | Agent identity — loaded every session, every platform |
| `AGENTS.md` | Project context | Session start protocol, architecture, memory strategy |
| `skills/*/SKILL.md` | Slash commands | `/recon`, `/exploit`, `/privesc`, `/report`, `/htb-api` |
| `MEMORY.md` | Persistent memory | Cross-session findings, owned machines, technique patterns |

---

## Prerequisites

- [Hermes Agent](https://github.com/NousResearch/hermes-agent) installed
- [DeepSeek API key](https://platform.deepseek.com) (V4 Pro)
- [HTB App Token](https://app.hackthebox.com/profile/settings) (Settings → API Key → App Token)
- Telegram bot token from [@BotFather](https://t.me/botfather)
- HTB VPN connected (`tun0` interface)
- Python 3.10+ with `requests` library

---

## Quick Start

### 1. Install Hermes

```bash
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
source ~/.bashrc
```

### 2. Clone and Setup

```bash
git clone https://github.com/YOUR_USERNAME/specter-htb
cd specter-htb
chmod +x setup.sh
./setup.sh
```

The setup wizard will ask for:
- DeepSeek API key
- HTB App Token
- Telegram bot token + your user ID

### 3. Start SPECTER

```bash
# Start the Hermes gateway (runs in background, enables Telegram)
HERMES_HOME=~/.hermes-specter hermes gateway start

# Or run interactive CLI
HERMES_HOME=~/.hermes-specter hermes
```

### 4. Begin a Machine (via Telegram or CLI)

```
Start machine TwoMillion and begin recon
```

SPECTER resolves the machine name → spawns it → gets IP → updates `/etc/hosts` → begins Phase 1.

---

## Slash Commands

Inside any Hermes session (CLI or Telegram):

| Command | What it does |
|---------|--------------|
| `/htb-api` | Verify/refresh target IP, spawn machine, submit flags |
| `/recon` | Phase 1: nmap, web enum, service fingerprint |
| `/exploit` | Phase 3: web/network exploitation, reverse shells |
| `/privesc` | Phase 5: Linux/Windows privilege escalation |
| `/report` | Generate HTB writeup from wiki + memory |
| `/compress` | Compress context when approaching token limit |
| `/skills` | List all available skills |
| `/cron list` | Show scheduled jobs |

---

## Session Flow

```
                    You: "Start TwoMillion"
                           │
              ┌────────────▼────────────┐
              │   /htb-api              │
              │   Resolve name → ID     │
              │   Spawn machine         │
              │   Get IP (poll API)     │
              │   Update /etc/hosts     │
              │   Save to MEMORY.md     │
              └────────────┬────────────┘
                           │
              ┌────────────▼────────────┐
              │   /recon                │
              │   Check MEMORY.md first │  ← Did we do this stack before?
              │   nmap fast + full      │
              │   Web/SMB/SSH enum      │
              │   Save all to MEMORY    │
              └────────────┬────────────┘
                           │
              ┌────────────▼────────────┐
              │   /exploit              │
              │   Check session_search  │  ← What worked on Apache 2.4.x?
              │   Try proven techniques │
              │   Get shell             │
              │   Flag detected → auto  │
              │   submit + Telegram     │
              └────────────┬────────────┘
                           │
              ┌────────────▼────────────┐
              │   /privesc              │
              │   Run linpeas           │
              │   Check memory for LPE  │
              │   Escalate to root      │
              │   Root flag → auto      │
              │   submit + Telegram     │
              └────────────┬────────────┘
                           │
              ┌────────────▼────────────┐
              │   /report               │
              │   Compile writeup       │
              │   Update skills (patch) │
              │   Update MEMORY.md      │
              └─────────────────────────┘
```

---

## Configuration

### DeepSeek V4 Pro (default)

```yaml
# config.yaml
model: deepseek/deepseek-chat-v4-pro
provider: deepseek
```

### Switch Model

```bash
HERMES_HOME=~/.hermes-specter hermes model
# Interactive picker — change to any Hermes-supported model
# Works with: OpenRouter, Anthropic, OpenAI, local endpoints
```

### Telegram Setup

1. Message [@BotFather](https://t.me/botfather) → `/newbot` → name it "SPECTER HTB"
2. Copy the token into setup.sh when prompted
3. Get your user ID from [@userinfobot](https://t.me/userinfobot)
4. Start the gateway: `HERMES_HOME=~/.hermes-specter hermes gateway start`
5. Send any message to your bot to activate it

---

## Memory Architecture

SPECTER uses two Hermes memory files stored in `~/.hermes-specter/memories/`:

**MEMORY.md** (~800 tokens) — agent's working notes:
```
active_machine: TwoMillion (10.10.11.227)
last_phase: PRIVESC | iteration: 12
TwoMillion ports: 22/ssh, 80/http Apache 2.4.41
TwoMillion owned via: LFI log poison → RCE → sudo dd privesc
[TECH] Apache 2.4.41 — check LFI first, /var/log paths work
```

**USER.md** (~500 tokens) — your preferences:
```
Prefers caveman output mode
HTB focus: medium/hard Linux machines
Notify Telegram on every flag, every checkpoint
```

Memory is bounded (2,200 chars max) and auto-consolidated. The agent manages it — you don't.

---

## Security

- HTB API token stored in `state/.htb_token` (gitignored)
- Never stored in MEMORY.md or wiki/
- Scope enforcement: only targets listed in `state/scope.txt` are tested
- All actions logged to `wiki/log.md` (audit trail)
- Responsible use: HTB lab machines only

---

## Inspired By

| Project | What was taken |
|---------|---------------|
| [Hermes Agent](https://github.com/NousResearch/hermes-agent) | Agent runtime, skills system, memory, Telegram gateway, cron |
| [PHANTOM HTB Agent](https://github.com/YOUR_USERNAME/phantom) | HTB methodology, recursive loop, wiki pattern |
| [Karpathy autoresearch](https://github.com/karpathy/autoresearch) | Observe → hypothesize → execute recursive loop |
| [LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) | Three-layer knowledge architecture |

---

## License

MIT — see [LICENSE](LICENSE)

**For authorized use on HTB lab machines only. Never test systems without explicit written permission.**
