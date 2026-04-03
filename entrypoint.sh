#!/bin/bash
set -e

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

# Seed config on first boot
if [ ! -f /root/.hermes/config.yaml ]; then
    cp /app/config.yaml /root/.hermes/config.yaml
    echo "✓ Config seeded"
fi

# Seed memory on first boot
if [ ! -f /root/.hermes/memories/MEMORY.md ]; then
    mkdir -p /root/.hermes/memories
    cp /app/memories/MEMORY.md /root/.hermes/memories/MEMORY.md
    cp /app/memories/USER.md /root/.hermes/memories/USER.md
    echo "✓ Memory seeded"
fi

# Seed skills on first boot
if [ ! -d /root/.hermes/skills/trailofbits ]; then
    mkdir -p /root/.hermes/skills
    cp -r /app/skills/. /root/.hermes/skills/
    git clone --depth 1 https://github.com/trailofbits/skills /root/.hermes/skills/trailofbits 2>/dev/null || true
    git clone --depth 1 https://github.com/pashov/skills /root/.hermes/skills/pashov 2>/dev/null || true
    echo "✓ Skills seeded"
fi

# Start health server in background (required for Render Web Service + persistent disk)
python3 /app/health.py &
echo "✓ Health server started on :8080"

echo "✓ Starting Hermes Telegram gateway..."
hermes gateway run
