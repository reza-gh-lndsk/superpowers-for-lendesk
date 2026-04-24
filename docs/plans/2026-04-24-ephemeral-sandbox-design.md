# Ephemeral Sandbox for Headless Agent Implementation

**Date:** 2026-04-24
**Status:** Design approved

## Problem

The current workflow requires the developer to manually approve permissions during each
`executing-plans` session. Blanket auto-approval is a security risk (e.g. a malicious npm
package could access the host OS). The goal is full agent autonomy inside a disposable
environment with zero blast radius on the host.

## Solution Overview

Each implementation task runs inside an ephemeral Docker container scoped to one repo.
The container has full permissions internally. The only things that escape it are:
- A git branch pushed to GitHub
- A pull request created via `gh`
- A log file written to a host-mounted volume

After the PR is confirmed created, the container is destroyed.

## Pre-Container Phase (Brainstorming + Planning)

Before the container runs, the developer:

1. Runs brainstorming + `writing-plans` at the workspace root
2. A JIRA-keyed branch is created per repo involved (e.g. `FINMO-1234`)
3. The implementation plan for that repo is committed and pushed to the branch
4. The branch is published to remote

The plan being on the branch means the container only needs to clone the repo and
check out the branch - the plan is already there.

## Container Lifecycle

```
Host script:
  docker build (or use cached image)
  docker run --env ANTHROPIC_API_KEY --env GITHUB_TOKEN \
             --env REPO_URL --env BRANCH --env PLAN_PATH \
             --volume ./logs:/logs \
             → entrypoint script inside container

  Wait for container exit code:
    0   → gh pr create --base main --head $BRANCH → print PR URL → done
    non-0 → print failure summary, dump log path → skip PR creation

  docker rm (cleanup)
```

```
Container entrypoint script:
  git clone $REPO_URL
  git checkout $BRANCH
  claude [run headless-driven-development with $PLAN_PATH]
  exit $?
```

The host script uses Claude's exit code as the source of truth.
The branch being on remote is a consequence of success, not the signal.

## Logging

Two layers:

**Container stdout/stderr** streamed to host via volume mount:
```
logs/FINMO-1234-repo-name-20260424T143000.log
```
Captured even if the container crashes.

**FAILED.md on the branch** (written by the agent on failure):
```markdown
## Failed at task: <task name>
## Reason: <what went wrong>
## Last verification output:
<test/lint output>
## What's needed to proceed:
<missing context or clarification>
```
Visible on GitHub without pulling locally.

## New Skill: `headless-driven-development`

A variant of `subagent-driven-development` with two key differences:

**1. No human interaction path**
The implementer subagent cannot ask questions. If it cannot proceed without
clarification, it must write FAILED.md and stop. The plan must be self-sufficient.

**2. No `finishing-a-development-branch`**
After all tasks complete, the agent commits, pushes, and exits 0.
PR creation is handled by the host script via `gh`.

Everything else (two-stage review per task, fresh subagent per task, FAILED.md
on any failure) is inherited from `subagent-driven-development`.

## Docker Image Contents

- Ubuntu LTS base
- `git`, `gh` CLI
- Node.js LTS + npm
- Python (as needed per repo)
- Claude Code CLI (`claude`)
- Superpowers plugin installed and configured

API keys and GitHub tokens are passed as environment variables at runtime.
The GitHub token should be a fine-grained PAT scoped to the specific repo
with `contents: write` and `pull_requests: write` only.

## Iteration 1 Constraints

- Unit tests and lint only - no external infrastructure dependencies
- One container per repo per task
- Human coordinates multi-repo work at review time
- Questions from implementer = container exits non-zero (plan must be self-sufficient)

## Future Work

- Skill-based trigger (replace manual script)
- Richer container images for repos with infrastructure dependencies
- Parallel containers for multi-repo tasks
- Automatic retry with enriched plan context on failure
