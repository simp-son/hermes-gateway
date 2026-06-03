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
OPENAI_CODEX_ACCESS_TOKEN=${OPENAI_CODEX_ACCESS_TOKEN}
OPENAI_CODEX_REFRESH_TOKEN=${OPENAI_CODEX_REFRESH_TOKEN}
CODEX_ACCESS_TOKEN=${CODEX_ACCESS_TOKEN}
CODEX_REFRESH_TOKEN=${CODEX_REFRESH_TOKEN}
HERMES_CODEX_ACCESS_TOKEN=${HERMES_CODEX_ACCESS_TOKEN}
HERMES_CODEX_REFRESH_TOKEN=${HERMES_CODEX_REFRESH_TOKEN}
HERMES_AGENT_TIMEOUT=600
EOF
echo "✓ Credentials written"

# Seed Hermes' own OpenAI Codex OAuth store from deployment env vars.
# Hermes reads Codex OAuth credentials from /root/.hermes/auth.json, not
# directly from process env or ~/.codex/auth.json.
python3 << 'PYEOF'
import json
import os
from datetime import datetime, timezone
from pathlib import Path

access = (
    os.environ.get("OPENAI_CODEX_ACCESS_TOKEN")
    or os.environ.get("CODEX_ACCESS_TOKEN")
    or os.environ.get("HERMES_CODEX_ACCESS_TOKEN")
    or os.environ.get("OPENCODE_OAUTH_ACCESS_TOKEN")
    or ""
).strip()
refresh = (
    os.environ.get("OPENAI_CODEX_REFRESH_TOKEN")
    or os.environ.get("CODEX_REFRESH_TOKEN")
    or os.environ.get("HERMES_CODEX_REFRESH_TOKEN")
    or os.environ.get("OPENCODE_OAUTH_REFRESH_TOKEN")
    or ""
).strip()

if access and refresh:
    auth_path = Path("/root/.hermes/auth.json")
    try:
        auth_store = json.loads(auth_path.read_text()) if auth_path.exists() else {}
    except Exception:
        auth_store = {}

    now = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    auth_store["version"] = auth_store.get("version", 1)
    providers = auth_store.setdefault("providers", {})
    providers["openai-codex"] = {
        "tokens": {
            "access_token": access,
            "refresh_token": refresh,
        },
        "last_refresh": now,
        "auth_mode": "chatgpt",
        "label": os.environ.get("OPENAI_CODEX_LABEL", "Railway OAuth"),
    }
    auth_store["active_provider"] = "openai-codex"

    pool = auth_store.setdefault("credential_pool", {})
    entries = pool.setdefault("openai-codex", [])
    seeded = {
        "id": "railway-openai-codex-oauth",
        "label": os.environ.get("OPENAI_CODEX_LABEL", "Railway OAuth"),
        "auth_type": "oauth",
        "priority": 0,
        "source": "device_code",
        "access_token": access,
        "refresh_token": refresh,
        "last_refresh": now,
    }
    replaced = False
    for i, entry in enumerate(entries):
        if isinstance(entry, dict) and entry.get("id") == seeded["id"]:
            entries[i] = seeded
            replaced = True
            break
    if not replaced:
        entries.insert(0, seeded)

    suppressed = auth_store.get("suppressed_sources")
    if isinstance(suppressed, dict):
        sources = suppressed.get("openai-codex")
        if isinstance(sources, list) and "device_code" in sources:
            sources.remove("device_code")
        if isinstance(sources, list) and not sources:
            suppressed.pop("openai-codex", None)
        if not suppressed:
            auth_store.pop("suppressed_sources", None)

    auth_path.write_text(json.dumps(auth_store, indent=2) + "\n")
    print("✓ OpenAI Codex OAuth credentials seeded")
else:
    print("✓ OpenAI Codex OAuth credentials not configured")
PYEOF

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
