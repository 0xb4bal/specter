#!/bin/bash
# SPECTER HTB Agent — Setup Script
# Run once after cloning. Configures Hermes profile, sets tokens, installs gateway.

set -e

GREEN='\033[0;32m' CYAN='\033[0;36m' YELLOW='\033[1;33m' RED='\033[0;31m' NC='\033[0m'

echo -e "${CYAN}"
cat << 'BANNER'
 ███████╗██████╗ ███████╗ ██████╗████████╗███████╗██████╗
 ██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝██╔════╝██╔══██╗
 ███████╗██████╔╝█████╗  ██║        ██║   █████╗  ██████╔╝
 ╚════██║██╔═══╝ ██╔══╝  ██║        ██║   ██╔══╝  ██╔══██╗
 ███████║██║     ███████╗╚██████╗   ██║   ███████╗██║  ██║
 ╚══════╝╚═╝     ╚══════╝ ╚═════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
 HTB Agent — Powered by Hermes + DeepSeek V4 Pro
BANNER
echo -e "${NC}"

# ── Check Hermes installed ──────────────────────────────────────────────────
if ! command -v hermes &>/dev/null; then
    echo -e "${RED}[!] Hermes not installed.${NC}"
    echo "    Run: curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash"
    exit 1
fi
echo -e "${GREEN}[✓] Hermes found: $(hermes --version 2>/dev/null || echo 'installed')${NC}"

# ── Set up HERMES_HOME for SPECTER profile ──────────────────────────────────
SPECTER_HOME="$HOME/.hermes-specter"
mkdir -p "$SPECTER_HOME/memories" "$SPECTER_HOME/skills" "$SPECTER_HOME/cron"
echo -e "${GREEN}[✓] SPECTER_HOME: $SPECTER_HOME${NC}"

# ── Copy SOUL.md to HERMES_HOME ─────────────────────────────────────────────
cp SOUL.md "$SPECTER_HOME/SOUL.md"
echo -e "${GREEN}[✓] SOUL.md installed${NC}"

# ── Configure provider (DeepSeek) ───────────────────────────────────────────
echo ""
echo -e "${YELLOW}[?] Enter your DeepSeek API key:${NC}"
read -s -p "    DEEPSEEK_API_KEY: " DEEPSEEK_KEY
echo ""
echo "DEEPSEEK_API_KEY=$DEEPSEEK_KEY" >> "$SPECTER_HOME/.env"
HERMES_HOME=$SPECTER_HOME hermes config set model "deepseek/deepseek-chat-v4-pro"
HERMES_HOME=$SPECTER_HOME hermes config set provider "deepseek"
echo -e "${GREEN}[✓] DeepSeek V4 Pro configured${NC}"

# ── HTB API token ───────────────────────────────────────────────────────────
echo -e "${YELLOW}[?] Enter your HTB App Token (from HTB Dashboard → Settings → API Key):${NC}"
read -s -p "    HTB_TOKEN: " HTB_KEY
echo ""
echo "HTB_TOKEN=$HTB_KEY" > state/.htb_token
echo "HTB_TOKEN=$HTB_KEY" >> "$SPECTER_HOME/.env"
echo -e "${GREEN}[✓] HTB API token saved${NC}"

# ── Telegram bot ────────────────────────────────────────────────────────────
echo -e "${YELLOW}[?] Enter your SPECTER Telegram bot token (from @BotFather):${NC}"
read -s -p "    TELEGRAM_TOKEN: " TG_TOKEN
echo ""
echo -e "${YELLOW}[?] Your Telegram user ID (from @userinfobot):${NC}"
read -p "    TELEGRAM_ALLOWED_USERS: " TG_USER
echo "TELEGRAM_TOKEN=$TG_TOKEN" >> "$SPECTER_HOME/.env"
echo "TELEGRAM_ALLOWED_USERS=$TG_USER" >> "$SPECTER_HOME/.env"
HERMES_HOME=$SPECTER_HOME hermes config set telegram.enabled true
echo -e "${GREEN}[✓] Telegram bot configured${NC}"

# ── Install Python deps ──────────────────────────────────────────────────────
pip install requests --break-system-packages -q 2>/dev/null || true
echo -e "${GREEN}[✓] Python dependencies installed${NC}"

# ── Make tools executable ────────────────────────────────────────────────────
chmod +x tools/*.py tools/*.sh 2>/dev/null || true

# ── Install skills to Hermes profile ────────────────────────────────────────
# Hermes picks up skills from external_dirs in config.yaml
# Also add to HERMES_HOME skills for discovery
mkdir -p "$SPECTER_HOME/skills"
for skill_dir in skills/*/; do
    skill_name=$(basename "$skill_dir")
    mkdir -p "$SPECTER_HOME/skills/htb/$skill_name"
    cp "$skill_dir/SKILL.md" "$SPECTER_HOME/skills/htb/$skill_name/SKILL.md"
    echo -e "  ${GREEN}[✓]${NC} Skill installed: /$skill_name"
done

# ── Setup cron jobs ──────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}[*] Setting up cron jobs...${NC}"

# Cron 1: Machine IP monitor (every 5 min, only wakes agent if IP changed)
# Uses wakeAgent pattern for cost efficiency
cat > /tmp/specter_ip_check.sh << 'CRONSCRIPT'
#!/bin/bash
# Pre-check script: only wake agent if IP actually changed
STATE_FILE="$(dirname "$0")/../state/session.json"
if [ ! -f "$STATE_FILE" ]; then
    echo '{"wakeAgent": false}'
    exit 0
fi
STORED_IP=$(python3 -c "import json; d=json.load(open('$STATE_FILE')); print(d.get('target',{}).get('ip',''))" 2>/dev/null)
LIVE_IP=$(python3 tools/htb.py ip 2>/dev/null)
if [ "$STORED_IP" = "$LIVE_IP" ] || [ -z "$LIVE_IP" ]; then
    echo '{"wakeAgent": false}'
else
    echo "{\"wakeAgent\": true, \"context\": {\"old_ip\": \"$STORED_IP\", \"new_ip\": \"$LIVE_IP\"}}"
fi
CRONSCRIPT
chmod +x /tmp/specter_ip_check.sh

echo -e "${YELLOW}[*] Register cron jobs after gateway starts:${NC}"
cat << 'CRONJOBS'
  # Run these in hermes chat after gateway is up:

  /cron add "every 5m" "Check if HTB machine IP changed. If context shows old_ip and new_ip differ: update /etc/hosts, state/.env, state/session.json with new IP. Send Telegram: IP updated OLD → NEW" --skill htb-api

  /cron add "every 6h" "Search HackerOne and Bugcrowd for any scope updates on my tracked programs in wiki/programs/. Compare to previous state. If changes found: notify Telegram with exact changes."

CRONJOBS

# ── Start gateway ────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  SPECTER setup complete!${NC}"
echo ""
echo -e "  Start SPECTER:  ${CYAN}HERMES_HOME=~/.hermes-specter hermes${NC}"
echo -e "  Start gateway:  ${CYAN}HERMES_HOME=~/.hermes-specter hermes gateway start${NC}"
echo -e "  Telegram:       Message your SPECTER bot to begin"
echo ""
echo -e "  First message to send:"
echo -e "  ${YELLOW}\"Start machine TwoMillion and begin Phase 1 recon\"${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
