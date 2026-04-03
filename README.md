# Hermes Telegram Gateway on Render

24/7 Hermes Agent gateway for Telegram.

## Deploy to Render

1. Push this repo to GitHub (private repo recommended)
2. Go to https://render.com → New → Background Worker
3. Connect your GitHub repo
4. Set these environment variables in Render dashboard:
   - ANTHROPIC_API_KEY
   - TELEGRAM_BOT_TOKEN
   - TELEGRAM_ALLOWED_USERS
   - TELEGRAM_HOME_CHANNEL
5. Deploy

That's it. Bot runs 24/7, receives cron job reports, responds to messages.

## Plan
Use Render Starter plan ($7/month) — Background Worker stays alive always.
Free plan spins down after inactivity — NOT suitable for a gateway.
