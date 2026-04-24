FROM node:20-bookworm-slim

# Install OS dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    python3 \
    python3-pip \
    ca-certificates \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install gh CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code@2.1.119

# Create non-root user (--dangerously-skip-permissions blocks on root)
RUN useradd -m -s /bin/bash sandbox

# Configure git identity for sandbox user
RUN git config --global user.email "agent@sandbox.local" \
    && git config --global user.name "Sandbox Agent"
RUN su sandbox -c 'git config --global user.email "agent@sandbox.local" && git config --global user.name "Sandbox Agent"'

# Set up directories owned by sandbox user
RUN mkdir -p /workspace /logs && chown sandbox:sandbox /workspace /logs

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER sandbox
WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
