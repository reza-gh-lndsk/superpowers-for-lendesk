---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** This should be run in a dedicated worktree (created by brainstorming skill).

**Save plans to:** `.headless-plans/implementation/YYYY-MM-DD-<feature-name>.md` (see Context Detection below)

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:headless-driven-development (container) or superpowers:subagent-driven-development (interactive) to implement this plan task-by-task.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

**Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

**Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

**Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

**Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## Remember
- Exact file paths always
- Complete code in plan (not "add validation")
- Exact commands with expected output
- Reference relevant skills with @ syntax
- DRY, YAGNI, TDD, frequent commits

## Context Detection

Before writing the plan, detect your context:

```bash
git rev-parse --git-dir 2>/dev/null  # outputs .git if inside a repo; empty if at workspace root
```

**Single-repo context** (`.git` exists in current directory):

1. Write plan to `.headless-plans/implementation/YYYY-MM-DD-<feature-name>.md`
2. Create and publish the JIRA branch:
   ```bash
   git checkout -b <JIRA-KEY>
   mkdir -p .headless-plans/design .headless-plans/implementation
   # copy design doc from brainstorming if it exists at workspace level
   git add .headless-plans/
   git commit -m "planning: add implementation plan for <JIRA-KEY>"
   git push -u origin <JIRA-KEY>
   ```

**Workspace context** (no `.git` in current directory, subdirs are repos):

Identify which repos are involved from the brainstorming conversation — do not ask.

For each involved repo:

1. Write a self-sufficient plan to `<repo>/.headless-plans/implementation/YYYY-MM-DD-<feature-name>.md`
   - Each plan covers only that repo — zero cross-repo references
   - The implementer for that repo will never see the other repos' plans
2. Copy the design doc from the workspace `.headless-plans/design/` into the repo:
   ```bash
   mkdir -p <repo>/.headless-plans/design <repo>/.headless-plans/implementation
   cp .headless-plans/design/*.md <repo>/.headless-plans/design/
   ```
3. Create and publish the JIRA branch in that repo:
   ```bash
   git -C <repo> checkout -b <JIRA-KEY>
   git -C <repo> add .headless-plans/
   git -C <repo> commit -m "planning: add implementation plan for <JIRA-KEY>"
   git -C <repo> push -u origin <JIRA-KEY>
   ```

Repeat for every involved repo. Each ends up with its own JIRA branch containing both the design doc and its self-sufficient implementation plan.

## Execution Handoff

After saving the plan, offer execution choice:

**"Plan complete and saved to `.headless-plans/implementation/<filename>.md` in each involved repo (branch: `<JIRA-KEY>`). Two execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

**Which approach?"**

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development
- Stay in this session
- Fresh subagent per task + code review

**If Parallel Session chosen:**
- Guide them to open new session in worktree
- **REQUIRED SUB-SKILL:** New session uses superpowers:executing-plans
