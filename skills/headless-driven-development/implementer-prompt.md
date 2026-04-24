# Implementer Subagent Prompt Template (Headless)

Use this template when dispatching an implementer subagent inside the headless sandbox.

```
Task tool (general-purpose):
  description: "Implement Task N: [task name]"
  prompt: |
    You are implementing Task N: [task name] inside a headless Docker container.
    There is no human present. Do not ask questions.

    ## Task Description

    [FULL TEXT of task from plan - paste it here, do not make subagent read the file]

    ## Context

    [Scene-setting: where this fits, dependencies, architectural context]

    ## If You Cannot Proceed

    If the task description is missing information you need to implement it:

    1. Write FAILED.md to the repo root:
       ```
       ## Failed at task: N - [task name]
       ## Reason: [specific missing information]
       ## Last verification output: N/A
       ## What is needed to proceed: [exactly what is missing]
       ```
    2. `git add FAILED.md && git commit -m "ci: implementation blocked - see FAILED.md"`
    3. `git push origin HEAD`
    4. Stop.

    ## Your Job

    1. Implement exactly what the task specifies
    2. Write tests (follow TDD - red, green, refactor)
    3. Verify implementation works (run tests and lint)
    4. If verification fails after one self-correction attempt: write FAILED.md (see above) and stop
    5. Commit your work
    6. Self-review
    7. Report back

    Work from: [directory]

    ## Before Reporting Back: Self-Review

    Review your work with fresh eyes:

    **Completeness:**
    - Did I fully implement everything in the spec?
    - Are there edge cases I did not handle?

    **Quality:**
    - Is this my best work?
    - Are names clear and accurate?

    **Discipline:**
    - Did I avoid overbuilding (YAGNI)?
    - Did I follow existing patterns in the codebase?

    **Testing:**
    - Do tests verify actual behavior (not just mock behavior)?
    - Did I follow TDD?
    - Are tests comprehensive?

    Fix any issues found before reporting.

    ## Report Format

    When done:
    - What you implemented
    - Test results (exact output)
    - Files changed
    - Self-review findings (if any)
    - If you wrote FAILED.md: what was missing and what is needed
```
