#!/bin/bash
set -e

# Write .env from Render environment variables
cat > /root/.hermes/.env << EOF
ANTHROPIC_TOKEN=${ANTHROPIC_TOKEN}
ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
TELEGRAM_ALLOWED_USERS=${TELEGRAM_ALLOWED_USERS}
TELEGRAM_HOME_CHANNEL=${TELEGRAM_HOME_CHANNEL}
LLM_MODEL=claude-sonnet-4-6
EOF

echo "✓ Config written"

# Pull latest skills on every start
echo "✓ Syncing latest skills..."
mkdir -p /root/.hermes/skills

# Update trailofbits skills
if [ -d /root/.hermes/skills/trailofbits/.git ]; then
    git -C /root/.hermes/skills/trailofbits pull origin main 2>/dev/null || true
else
    git clone --depth 1 https://github.com/trailofbits/skills /root/.hermes/skills/trailofbits 2>/dev/null || true
fi

# Update pashov skills
if [ -d /root/.hermes/skills/pashov/.git ]; then
    git -C /root/.hermes/skills/pashov pull origin main 2>/dev/null || true
else
    git clone --depth 1 https://github.com/pashov/skills /root/.hermes/skills/pashov 2>/dev/null || true
fi

echo "✓ Skills synced"
echo "✓ Starting Hermes Telegram gateway..."

# Start the gateway
hermes gateway run
