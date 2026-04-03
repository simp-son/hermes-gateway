FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# System deps
RUN apt-get update && apt-get install -y \
    curl git python3 python3-pip python3-venv \
    build-essential libssl-dev libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Hermes — skip interactive setup wizard
RUN curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh \
    | bash -s -- --skip-setup

ENV PATH="/root/.local/bin:/root/.hermes/hermes-agent/venv/bin:$PATH"

# Create config dirs
RUN mkdir -p /root/.hermes/skills

# Copy config and skills
COPY config.yaml /root/.hermes/config.yaml
COPY skills/ /root/.hermes/skills/

# Entrypoint writes .env from env vars and starts gateway
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
