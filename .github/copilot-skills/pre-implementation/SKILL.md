---
name: pre-implementation
description: Core workflow rules for making code changes. Use whenever implementing, modifying, or creating code in this project.
---

# Implementation Workflow

These rules apply to ALL code changes in this project.

## Pre-Implementation Checks

Before writing any code, perform these checks:

- **Git context**: Run `git --no-pager branch --show-current` and `git --no-pager status --short` to confirm you're on the correct branch with a clean (or acknowledged) working tree
- **Memory recall**: If memory tools are available, search for stored knowledge related to the task area — previous decisions, known patterns, or relevant conventions may save time and prevent duplicate work
- **Skill loading**: Verify you've loaded all applicable skills per the matrix in `copilot-instructions.md`

## Never Assume Code Is Current

- **Do not assume the code you're touching is up-to-date, follows best practices, or is error-free.** Always read and evaluate the actual state of files before modifying them
- If you encounter errors, outdated patterns, or convention violations in any file you touch — **fix them**, even if unrelated to your current task
- Unrelated fixes must be committed separately with their own descriptive commit message — never mixed with your main task commits
- If unrelated fixes are substantial, use a parallel agent to handle them concurrently while you continue with the primary task

## Parallel Execution

- **Always look for opportunities to parallelize work.** If multiple files need changes that don't depend on each other, make them simultaneously
- Run independent investigations, searches, and file reads in parallel rather than sequentially
- When unrelated fixes are needed alongside your main task, delegate them to a separate agent running in parallel
- Run linting, type checking, and tests concurrently where the tooling supports it

## Implementation Loop

After each change, perform the following steps in order:

1. Review the implementation plan.
2. Begin making changes, following the plan.
   1. If tests do not already cover the changes you have made, create them. All new code MUST be covered if applicable. This applies to both unit and integration tests.
3. Run linting/formatting checks to validate your code.
   1. If linting fails, go back to the first step. DO NOT CONTINUE UNLESS LINTING PASSES.
4. Run unit tests to validate all functionality behaves as expected.
   1. If unit tests fail, go back to the first step. DO NOT CONTINUE UNLESS UNIT TESTS PASS.
5. If applicable, persist your progress (e.g. update memory, notes, or session state).
6. Suggest updates to any of the aforementioned rules or instructions to include any new information you have gained. Refer to them by their `.md` filename where possible.
7. If there are integration tests available, run those to validate that your changes are functional throughout the whole application chain.
   1. If integration tests fail, go back to the first step. DO NOT CONTINUE UNLESS INTEGRATION TESTS PASS.
8. Validate all of your changes. Go through each change and determine if the functionality is necessary, maintainable, and falls within the scope of the given task.
   1. If you have made changes that do not align with this rule, make adjustments, make TODOs, go back to the first step. DO NOT CONTINUE UNLESS ALL CHANGES ARE FUNCTIONAL.
9. Commit your changes, following the git rules defined in `git-usage`.

_NOTE: If tests do not exist in the current workspace, or if the change is the creation/adjustment of a small script, then tests are NOT required._

After each "atomic change", make a commit (and persist progress). Always ensure that all tests pass _before_ making any commits.

If you encounter any other issues as you go, or the user asks you to do something that is not in the scope of the original plan, add those tasks or requests as TODOs (in memory, in a comment, or in a `TODO.md` file).

Once all steps in the plan have been completed, ALL tests pass, progress is persisted (if needed), instruction suggestions have been made, and everything is committed, THEN AND ONLY THEN can you consider the task complete.

## Task Completion Communication

When finishing a task, **always provide the user with a clear summary** that includes:

- **What was completed** — list each change made, files created/modified/deleted
- **What was fixed incidentally** — any unrelated issues you cleaned up along the way
- **How to test it** — specific steps the user can take to verify the changes work (e.g., commands to run, pages to visit, workflows to trigger, expected outcomes)
- **Any caveats or follow-ups** — things the user should be aware of or remaining work if applicable

Never end with just "done" — the user should be able to confidently verify your work themselves.

## Session Management

**If the conversation is getting long, proactively suggest starting a fresh session to keep token usage low.** Pass all gathered context, references, and established rules into the new session.

> NOTE: If any of the rules contradict any existing coding styles, best practices, or suggestions within the current project then the rules can be overridden. However, if the rules _are_ overridden, this _must_ be **explicitly** mentioned to the user.
