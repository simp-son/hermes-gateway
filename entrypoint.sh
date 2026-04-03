#!/bin/bash
set -e

# Always write .env from Render environment variables
mkdir -p /root/.hermes
cat > /root/.hermes/.env << EOF
ANTHROPIC_TOKEN=${ANTHROPIC_TOKEN}
ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
TELEGRAM_ALLOWED_USERS=${TELEGRAM_ALLOWED_USERS}
TELEGRAM_HOME_CHANNEL=${TELEGRAM_HOME_CHANNEL}
LLM_MODEL=claude-sonnet-4-6
EOF

echo "✓ Credentials written"

# Seed config on first boot (persistent disk is empty)
if [ ! -f /root/.hermes/config.yaml ]; then
    echo "✓ First boot — seeding config and skills..."
    cp /app/config.yaml /root/.hermes/config.yaml

    mkdir -p /root/.hermes/skills
    cp -r /app/skills/. /root/.hermes/skills/

    # Pull latest trailofbits and pashov
    git clone --depth 1 https://github.com/trailofbits/skills /root/.hermes/skills/trailofbits 2>/dev/null || true
    git clone --depth 1 https://github.com/pashov/skills /root/.hermes/skills/pashov 2>/dev/null || true

    echo "✓ First boot setup complete"
else
    echo "✓ Persistent data found — skipping seed"
    # Just update credentials, keep everything else
fi

echo "✓ Skills available:"
ls /root/.hermes/skills/

echo "✓ Starting Hermes Telegram gateway..."
hermes gateway run
