FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y \
    curl git python3 python3-pip python3-venv \
    build-essential libssl-dev libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Hermes to /opt/hermes instead of ~/.hermes
# so the volume mount at /root/.hermes doesn't wipe it
ENV HERMES_INSTALL_DIR=/opt/hermes/hermes-agent
RUN curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh \
    | bash -s -- --skip-setup

ENV PATH="/opt/hermes/hermes-agent/venv/bin:/root/.local/bin:$PATH"

RUN mkdir -p /app/skills /app/memories
COPY config.yaml /app/config.yaml
COPY skills/ /app/skills/
COPY memories/ /app/memories/

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
