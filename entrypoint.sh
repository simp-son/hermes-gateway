#!/bin/bash
set -e

export PATH="/opt/hermes/hermes-agent/venv/bin:/root/.local/bin:$PATH"

mkdir -p /root/.hermes

# Default memory repo per service (override via MEMORY_REPO_URL env var)
MEMORY_REPO_URL="${MEMORY_REPO_URL:-simp-son/hermes-memory}"

# Always write credentials
cat > /root/.hermes/.env << EOF
OPENCODE_GO_API_KEY=${OPENCODE_GO_API_KEY}
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
TELEGRAM_ALLOWED_USERS=${TELEGRAM_ALLOWED_USERS}
TELEGRAM_HOME_CHANNEL=${TELEGRAM_HOME_CHANNEL}
MEMORY_REPO_PAT=${MEMORY_REPO_PAT}
HERMES_AGENT_TIMEOUT=600
EOF
echo "✓ Credentials written"

# Pull latest memory from GitHub
echo "✓ Pulling memory from ${MEMORY_REPO_URL}..."
mkdir -p /root/.hermes/memories
if [ -n "${MEMORY_REPO_PAT}" ]; then
    git config --global user.email "hermes@deploy.sh"
    git config --global user.name "Hermes"

    if [ -d /root/.hermes/memory-repo/.git ]; then
        git -C /root/.hermes/memory-repo pull origin master --ff-only 2>/dev/null || true
    else
        git clone --depth 1 https://simp-son:${MEMORY_REPO_PAT}@github.com/${MEMORY_REPO_URL}.git \
            /root/.hermes/memory-repo 2>/dev/null || true
    fi

    # Copy memory files into place
    cp /root/.hermes/memory-repo/MEMORY.md /root/.hermes/memories/MEMORY.md 2>/dev/null || true
    cp /root/.hermes/memory-repo/USER.md /root/.hermes/memories/USER.md 2>/dev/null || true
    cp /root/.hermes/memory-repo/state.db /root/.hermes/state.db 2>/dev/null || true
    echo "✓ Memory loaded"
fi

# Always overwrite config from image (ensures provider updates take effect)
echo "✓ Updating config..."
cp /app/config.yaml /root/.hermes/config.yaml

# Override model/provider/base_url from env vars if set (allows different models per Railway service)
python3 << 'PYEOF'
import os, sys
cfg_path = "/root/.hermes/config.yaml"
# Ensure PyYAML is available
try:
    import yaml
except ImportError:
    os.system("pip install pyyaml -q")
    import yaml

with open(cfg_path, "r") as f:
    cfg = yaml.safe_load(f)

model = cfg.setdefault("model", {})
if os.environ.get("LLM_MODEL"):
    model["default"] = os.environ["LLM_MODEL"]
    print(f"✓ Model set to: {os.environ['LLM_MODEL']}")
if os.environ.get("LLM_PROVIDER"):
    model["provider"] = os.environ["LLM_PROVIDER"]
    print(f"✓ Provider set to: {os.environ['LLM_PROVIDER']}")
if os.environ.get("LLM_BASE_URL"):
    model["base_url"] = os.environ["LLM_BASE_URL"]
    print(f"✓ Base URL set to: {os.environ['LLM_BASE_URL']}")
if os.environ.get("LLM_API_MODE"):
    model["api_mode"] = os.environ["LLM_API_MODE"]
    print(f"✓ API mode set to: {os.environ['LLM_API_MODE']}")

with open(cfg_path, "w") as f:
    yaml.dump(cfg, f, default_flow_style=False, sort_keys=False)
PYEOF

# Seed skills on first boot only
if [ ! -d /root/.hermes/skills/pashov ]; then
    echo "✓ First boot — seeding skills..."
    mkdir -p /root/.hermes/skills
    cp -r /app/skills/. /root/.hermes/skills/ 2>/dev/null || true
    git clone --depth 1 https://github.com/trailofbits/skills /root/.hermes/skills/trailofbits 2>/dev/null || true
    git clone --depth 1 https://github.com/pashov/skills /root/.hermes/skills/pashov 2>/dev/null || true
    echo "✓ Skills seeded"
else
    echo "✓ Skills found — skipping seed"
fi

# Background job: push memory to GitHub every 30 min
if [ -n "${MEMORY_REPO_PAT}" ]; then
    (while true; do
        sleep 1800
        cd /root/.hermes/memory-repo
        cp /root/.hermes/memories/MEMORY.md ./MEMORY.md 2>/dev/null || true
        cp /root/.hermes/memories/USER.md ./USER.md 2>/dev/null || true
        cp /root/.hermes/state.db ./state.db 2>/dev/null || true
        git add -A
        git diff --cached --quiet || git commit -m "memory sync $(date +%Y-%m-%d_%H:%M)" && git push origin master 2>/dev/null || true
    done) &
    echo "✓ Memory auto-sync started (every 30 min)"
fi

echo "✓ Skills: $(ls /root/.hermes/skills/ | wc -l) directories"
echo "✓ Starting Hermes Telegram gateway..."
exec hermes gateway run