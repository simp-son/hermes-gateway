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

# Skills are already baked into the image at /root/.hermes/skills/
# Just update trailofbits and pashov if they exist
echo "✓ Updating skills..."
git -C /root/.hermes/skills/trailofbits pull origin main --ff-only 2>/dev/null || echo "trailofbits: using baked version"
git -C /root/.hermes/skills/pashov pull origin main --ff-only 2>/dev/null || echo "pashov: using baked version"

echo "✓ Skills ready"
echo "Skills available:"
ls /root/.hermes/skills/

echo "✓ Starting Hermes Telegram gateway..."
hermes gateway run
