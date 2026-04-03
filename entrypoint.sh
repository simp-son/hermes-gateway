#!/bin/bash
set -e

# Write .env from Render environment variables
cat > /root/.hermes/.env << EOF
ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
TELEGRAM_ALLOWED_USERS=${TELEGRAM_ALLOWED_USERS}
TELEGRAM_HOME_CHANNEL=${TELEGRAM_HOME_CHANNEL}
LLM_MODEL=claude-sonnet-4-6
EOF

echo "✓ Config written"
echo "✓ Starting Hermes Telegram gateway..."

# Start the gateway
hermes gateway run
