FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y \
    curl git python3 python3-pip python3-venv \
    build-essential libssl-dev libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Hermes
RUN curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh \
    | bash -s -- --skip-setup

# Find and print where hermes ended up
RUN find / -name "hermes" -type f 2>/dev/null | head -5 && echo "---" && which hermes || true

ENV PATH="/root/.hermes/hermes-agent/venv/bin:/root/.local/bin:$PATH"

RUN mkdir -p /app/skills /app/memories
COPY config.yaml /app/config.yaml
COPY skills/ /app/skills/
COPY memories/ /app/memories/

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
