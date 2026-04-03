Installed skill repos:
- ~/.hermes/skills/trailofbits/ — cloned from github.com/trailofbits/skills (60 skills, security/audit/fuzzing/blockchain)
- ~/.hermes/skills/pashov/ — cloned from github.com/pashov/skills (solidity-auditor + x-ray)
- ~/.hermes/skills/trailofbits/slither/ — custom-created Slither skill (not from a repo, hand-crafted from crytic/slither CLAUDE.md)
§
Nunchi exchange audit cron job is set up (job ID 85dabca91e58), runs every 12h, delivers to Telegram. Awaiting 24/7 server setup — recommended Oracle Cloud Free Tier. Gateway must be running for Telegram bot to work.

evm-exploit-kb skill created at trailofbits/evm-exploit-kb — covers 500+ DeFi exploits, 2025 hacks (ByBit, Cetus, Balancer), C4/Sherlock patterns. Wired into pashov solidity-auditor as agent 9.

layer3xyz/cubes audit completed — 10 findings including: ERC1155 arg swap (95), excess ETH to treasury (95), withdraw/sweepToTreasury desync (90), GAS_CAP DoS (90), missing quest-active check (90).
§
Render deploy setup: ~/hermes-render/ has Dockerfile + config.yaml + entrypoint.sh + render.yaml for 24/7 Telegram gateway. Needs: rm -rf skills/pashov/.git skills/trailofbits/.git then git push to simp-son/hermes-gateway (private). Render Starter $7/mo as Background Worker. Env vars needed: ANTHROPIC_API_KEY, TELEGRAM_BOT_TOKEN, TELEGRAM_ALLOWED_USERS, TELEGRAM_HOME_CHANNEL. Entrypoint should clone skills fresh from GitHub instead of baking them in.
§
Active cron jobs:
- immunefi-contest-hunter (ID: 7c579d1f321d) — every 12h — picks new C4/Sherlock/Immunefi contest, clones, audits with evm-exploit-kb, saves missed patterns to memory, reports to Telegram
- exploit-kb-updater (ID: a91fb073a577) — every 24h — scrapes new disclosures, patches evm-exploit-kb SKILL.md, saves new patterns to memory, reports to Telegram