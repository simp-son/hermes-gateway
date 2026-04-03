FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# System deps
RUN apt-get update && apt-get install -y \
    curl git python3 python3-pip python3-venv \
    build-essential libssl-dev libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Hermes
RUN curl -sSL https://hermes.sh/install | bash

ENV PATH="/root/.hermes/bin:/root/.local/bin:$PATH"

# Create config dirs
RUN mkdir -p /root/.hermes

# Copy config and skills
COPY config.yaml /root/.hermes/config.yaml
COPY skills/ /root/.hermes/skills/

# These come from Render environment variables at runtime
# ANTHROPIC_API_KEY, TELEGRAM_BOT_TOKEN, TELEGRAM_ALLOWED_USERS, TELEGRAM_HOME_CHANNEL

# Write .env from environment variables at startup
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
