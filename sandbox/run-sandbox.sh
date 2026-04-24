#!/usr/bin/env bash
set -euo pipefail

# Usage: ./run-sandbox.sh <repo-url> <jira-branch> <plan-path>
# Example: ./run-sandbox.sh https://github.com/lendesk/finmo-app FINMO-1234 docs/plans/2026-04-24-my-feature.md

REPO_URL="${1:?Usage: $0 <repo-url> <jira-branch> <plan-path>}"
JIRA_BRANCH="${2:?Usage: $0 <repo-url> <jira-branch> <plan-path>}"
PLAN_PATH="${3:?Usage: $0 <repo-url> <jira-branch> <plan-path>}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
LOGS_DIR="$SCRIPT_DIR/logs"
IMAGE_NAME="finmo-sandbox"

# Validate .env exists
if [[ ! -f "$ENV_FILE" ]]; then
  echo "[host] ERROR: $ENV_FILE not found. Copy .env.example to .env and fill in values."
  exit 1
fi

mkdir -p "$LOGS_DIR"

echo "[host] Building sandbox image..."
docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"

echo "[host] Running sandbox container..."
echo "[host] Repo:   $REPO_URL"
echo "[host] Branch: $JIRA_BRANCH"
echo "[host] Plan:   $PLAN_PATH"

CONTAINER_ID=$(docker run -d \
  --env-file "$ENV_FILE" \
  --env REPO_URL="$REPO_URL" \
  --env JIRA_BRANCH="$JIRA_BRANCH" \
  --env PLAN_PATH="$PLAN_PATH" \
  --volume "$LOGS_DIR:/logs" \
  "$IMAGE_NAME")

echo "[host] Container started: $CONTAINER_ID"
echo "[host] Streaming logs..."
docker logs -f "$CONTAINER_ID" &
LOGS_PID=$!

# Wait for container to finish
docker wait "$CONTAINER_ID" > /dev/null
EXIT_CODE=$(docker inspect "$CONTAINER_ID" --format='{{.State.ExitCode}}')
kill $LOGS_PID 2>/dev/null || true

echo ""
echo "[host] Container exited with code: $EXIT_CODE"

if [[ "$EXIT_CODE" == "0" ]]; then
  echo "[host] Implementation succeeded. Creating PR..."
  REPO_NAME=$(basename "$REPO_URL" .git)
  GITHUB_TOKEN=$(grep '^GITHUB_TOKEN=' "$ENV_FILE" | cut -d= -f2-)
  export GITHUB_TOKEN
  PR_URL=$(gh pr create \
    --repo "lendesk/$REPO_NAME" \
    --base main \
    --head "$JIRA_BRANCH" \
    --title "$JIRA_BRANCH: implementation" \
    --body "Automated implementation via sandbox agent.")
  echo "[host] PR created: $PR_URL"
else
  LOG_FILE=$(ls -t "$LOGS_DIR"/${JIRA_BRANCH}-*.log 2>/dev/null | head -1 || echo "no log found")
  echo "[host] Implementation FAILED."
  echo "[host] Log: $LOG_FILE"
  echo "[host] Check FAILED.md on the $JIRA_BRANCH branch for details."
fi

echo "[host] Cleaning up container..."
docker rm "$CONTAINER_ID" > /dev/null

echo "[host] Done."
exit "$EXIT_CODE"
