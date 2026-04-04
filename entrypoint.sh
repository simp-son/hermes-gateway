#!/bin/bash
set -e

# Ensure hermes is on PATH
export PATH="/root/.hermes/hermes-agent/venv/bin:/root/.local/bin:$PATH"

mkdir -p /root/.hermes

# Always write credentials
cat > /root/.hermes/.env << EOF
ANTHROPIC_TOKEN=${ANTHROPIC_TOKEN}
ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
TELEGRAM_ALLOWED_USERS=${TELEGRAM_ALLOWED_USERS}
TELEGRAM_HOME_CHANNEL=${TELEGRAM_HOME_CHANNEL}
LLM_MODEL=claude-sonnet-4-6
EOF
echo "✓ Credentials written"

# Seed on first boot
if [ ! -f /root/.hermes/config.yaml ]; then
    echo "✓ First boot — seeding..."
    cp /app/config.yaml /root/.hermes/config.yaml

    mkdir -p /root/.hermes/skills
    cp -r /app/skills/. /root/.hermes/skills/

    # Seed memory
    mkdir -p /root/.hermes/memories
    cp /app/memories/MEMORY.md /root/.hermes/memories/MEMORY.md
    cp /app/memories/USER.md /root/.hermes/memories/USER.md

    # Pull latest skills
    git clone --depth 1 https://github.com/trailofbits/skills /root/.hermes/skills/trailofbits 2>/dev/null || true
    git clone --depth 1 https://github.com/pashov/skills /root/.hermes/skills/pashov 2>/dev/null || true

    echo "✓ First boot complete"
else
    echo "✓ Persistent data found — skipping seed"
fi

echo "✓ Skills: $(ls /root/.hermes/skills/ | wc -l) directories"
echo "✓ Starting Hermes Telegram gateway..."
exec hermes gateway run
