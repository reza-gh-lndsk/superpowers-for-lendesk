#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/logs/${JIRA_BRANCH}-$(date +%Y%m%dT%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[sandbox] Starting at $(date)"
echo "[sandbox] Repo: $REPO_URL"
echo "[sandbox] Branch: $JIRA_BRANCH"
echo "[sandbox] Plan: $PLAN_PATH"

# Configure gh CLI with token
echo "$GITHUB_TOKEN" | gh auth login --with-token

# Configure git to use token for HTTPS
git config --global credential.helper '!f() { echo "username=x-token"; echo "password=$GITHUB_TOKEN"; }; f'

# Clone and checkout
echo "[sandbox] Cloning repo..."
git clone "$REPO_URL" /workspace/repo
cd /workspace/repo
git checkout "$JIRA_BRANCH"
echo "[sandbox] On branch: $(git branch --show-current)"

# Configure Claude Code to use mounted superpowers plugin
mkdir -p /root/.claude
cat > /root/.claude/settings.json <<EOF
{
  "enabledPlugins": {
    "superpowers@local": true
  },
  "extraKnownMarketplaces": {
    "local": {
      "source": {
        "source": "directory",
        "path": "/superpowers"
      }
    }
  }
}
EOF

echo "[sandbox] Starting Claude Code..."
claude --dangerously-skip-permissions -p \
  "Use superpowers:headless-driven-development to implement the plan at $PLAN_PATH"
CLAUDE_EXIT=$?

# Check for FAILED.md as the authoritative failure signal
if [[ -f "/workspace/repo/FAILED.md" ]]; then
  echo "[sandbox] FAILED.md detected - implementation did not complete"
  echo "[sandbox] Contents:"
  cat /workspace/repo/FAILED.md
  exit 1
fi

echo "[sandbox] Claude exited with code: $CLAUDE_EXIT"
exit $CLAUDE_EXIT
