#!/usr/bin/env bash
set -euo pipefail

[[ -d /logs ]] || { echo "[sandbox] ERROR: /logs volume not mounted"; exit 1; }

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

echo "[sandbox] Adding superpowers marketplace..."
claude plugin marketplace add https://github.com/reza-gh-lndsk/superpowers-for-lendesk.git 2>&1
echo "[sandbox] Installing superpowers plugin..."
claude plugin install superpowers 2>&1

echo "[sandbox] Starting Claude Code..."
set +e
timeout 7200 claude --dangerously-skip-permissions -p \
  "Use superpowers:headless-driven-development to implement the plan at $PLAN_PATH"
CLAUDE_EXIT=$?
set -e

# Check for FAILED.md as the authoritative failure signal
if [[ -f "/workspace/repo/FAILED.md" ]]; then
  echo "[sandbox] FAILED.md detected - implementation did not complete"
  echo "[sandbox] Contents:"
  cat /workspace/repo/FAILED.md
  exit 1
fi

echo "[sandbox] Claude exited with code: $CLAUDE_EXIT"
exit $CLAUDE_EXIT
