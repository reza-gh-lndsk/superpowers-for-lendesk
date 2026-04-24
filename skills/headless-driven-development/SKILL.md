---
name: headless-driven-development
description: Use when executing implementation plans inside a headless container with no human present - zero interaction variant of subagent-driven-development
---

# Headless-Driven Development

Execute plan by dispatching fresh subagent per task inside a headless environment.
No human interaction. Any blocker → write FAILED.md → stop.

**Core principle:** Self-sufficient plan + fresh subagent per task + two-stage review = autonomous implementation

## Headless Contract

You are running inside an ephemeral Docker container. There is no human present.

- **Never** ask a question or wait for input
- **Never** call `finishing-a-development-branch` (PR is created externally)
- If you cannot proceed on a task: write FAILED.md to repo root, commit it, push. The container will detect FAILED.md and exit non-zero.
- If all tasks complete: push all commits, exit 0

The plan must be self-sufficient. If it is not, FAILED.md is the feedback mechanism.

## FAILED.md Format

Write this file to the repo root when stopping early:

```markdown
## Failed at task: <task name and number>
## Reason: <specific reason - missing context, test failure, etc.>
## Last verification output:
<paste exact test/lint/command output>
## What is needed to proceed:
<specific missing information or clarification>
```

After writing the file:
```bash
git add FAILED.md && git commit -m "ci: implementation blocked - see FAILED.md"
git push origin HEAD
```
Stop. The container detects FAILED.md on the branch.

## When to Use

This skill runs inside a Docker sandbox container only. Do not use in interactive sessions.
Use `subagent-driven-development` for interactive sessions with a human present.

## The Process

```dot
digraph process {
    rankdir=TB;

    subgraph cluster_per_task {
        label="Per Task";
        "Dispatch implementer subagent" [shape=box];
        "Implementer implements, tests, commits, self-reviews" [shape=box];
        "Write FAILED.md, commit, push" [shape=box style=filled fillcolor=salmon];
        "Dispatch spec reviewer subagent" [shape=box];
        "Spec compliant?" [shape=diamond];
        "Implementer fixes spec gaps" [shape=box];
        "Dispatch code quality reviewer subagent" [shape=box];
        "Quality approved?" [shape=diamond];
        "Implementer fixes quality issues" [shape=box];
        "Mark task complete in TodoWrite" [shape=box];
    }

    "Read plan, extract all tasks, create TodoWrite" [shape=box];
    "More tasks remain?" [shape=diamond];
    "Push all commits, exit 0" [shape=box style=filled fillcolor=lightgreen];

    "Read plan, extract all tasks, create TodoWrite" -> "Dispatch implementer subagent";
    "Dispatch implementer subagent" -> "Implementer implements, tests, commits, self-reviews";
    "Implementer implements, tests, commits, self-reviews" -> "Write FAILED.md, commit, push" [label="cannot proceed"];
    "Implementer implements, tests, commits, self-reviews" -> "Dispatch spec reviewer subagent" [label="done"];
    "Dispatch spec reviewer subagent" -> "Spec compliant?";
    "Spec compliant?" -> "Implementer fixes spec gaps" [label="no"];
    "Implementer fixes spec gaps" -> "Dispatch spec reviewer subagent" [label="re-review"];
    "Spec compliant?" -> "Dispatch code quality reviewer subagent" [label="yes"];
    "Dispatch code quality reviewer subagent" -> "Quality approved?";
    "Quality approved?" -> "Implementer fixes quality issues" [label="no"];
    "Implementer fixes quality issues" -> "Dispatch code quality reviewer subagent" [label="re-review"];
    "Quality approved?" -> "Mark task complete in TodoWrite" [label="yes"];
    "Mark task complete in TodoWrite" -> "More tasks remain?";
    "More tasks remain?" -> "Dispatch implementer subagent" [label="yes"];
    "More tasks remain?" -> "Push all commits, exit 0" [label="no"];
}
```

## Prompt Templates

- `./implementer-prompt.md` - Dispatch implementer subagent (headless variant)
- `./spec-reviewer-prompt.md` - Dispatch spec compliance reviewer
- `./code-quality-reviewer-prompt.md` - Dispatch code quality reviewer

## Completion

When all tasks are done:

```bash
git push origin HEAD
```

Then stop. The absence of FAILED.md signals success to the container. Do not call `finishing-a-development-branch`. The host script handles PR creation.

## Red Flags

**Never:**
- Ask a question or pause for human input
- Call `finishing-a-development-branch`
- Create a PR (host script does this)
- Skip writing FAILED.md before stopping (it is the signal the container uses to detect failure and the primary debugging artifact)
- Dispatch multiple implementation subagents in parallel (conflicts)
- Make subagent read plan file (provide full text instead)
- Skip spec compliance review before code quality review (wrong order)
- Accept "close enough" on spec compliance

**If implementer cannot proceed:**
- Write FAILED.md with specific reason and what is needed
- `git add FAILED.md && git commit -m "ci: implementation blocked - see FAILED.md"`
- `git push origin HEAD`
- Stop. The container detects FAILED.md on the branch and handles the non-zero exit.

**If mid-task verification fails (tests, lint):**
- Implementer attempts one self-correction
- If still failing after one attempt: write FAILED.md, commit, push, stop. The container detects FAILED.md.
- Note: this cap applies to test/lint failures only, not to spec or quality review cycles (those loop until approved).

## Integration

**Required before running:**
- Plan must be committed to the JIRA branch and self-sufficient
- Branch must exist on remote

**Subagents should use:**
- `superpowers:test-driven-development` - for each implementation task
