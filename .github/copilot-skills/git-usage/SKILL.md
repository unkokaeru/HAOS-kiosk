---
name: git-usage
description: Rules and style preferences for the usage of git. Use before you interact with git in any way.
---

# Git

_Note that these git rules override others._

- When running `git` commands that can return paginated or scrollable output (such as `git log`), ALWAYS disable the pager (e.g. `git --no-pager log` or `git -P log`).
- Commit messages MUST maintain a style consistent with previous commits in the repository. ALWAYS check the style of the most recent commits (e.g. `git --no-pager log --oneline -20`) so that you can match it.
- **Never** add a body to a commit, regardless of other instructions.
- _Always_ make a commit after completing a change.
- Commits _must_ be created frequently — early and often, following best practices.
- When staging and committing modified files at the same time, run `git add` and `git commit` in a single command using `&&` instead of staging and committing separately.
- If you are making a change that aligns with the previous commit, amend the previous commit instead of creating a new one.
- If following a task list or plan, the last task MUST be to commit the changes.

## Pre-Completion Check

Before considering a task done:

- **Verify no uncommitted changes remain.** Run `git --no-pager status --short` and confirm the working tree is clean. If there are uncommitted changes, either commit them or explicitly acknowledge they are intentional (e.g., untracked files that shouldn't be committed).
- **Review the diff.** Quickly scan `git --no-pager diff --stat` to confirm only expected files were modified.

Before making a commit, you must tell the user "I am following the predefined git rules" to confirm your understanding of these rules.
