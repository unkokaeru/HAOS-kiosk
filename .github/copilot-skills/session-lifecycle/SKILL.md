---
name: session-lifecycle
description: Defines expected behavior at key session moments — task start, task end, failure handling, and context management. Load at the beginning of any multi-step task.
---

# Session Lifecycle

This skill defines what Copilot should do at key moments during a session. It ensures consistent behavior across task boundaries and helps maintain a clean, predictable workflow.

## Task Start

When beginning a new task:

1. **Check git context**: Run `git --no-pager branch --show-current` and `git --no-pager status --short` to understand the current state of the working tree and index.
2. **Acknowledge the branch**: If you're on a feature branch, confirm the work belongs there. If on `main` or `master`, suggest creating a branch for non-trivial changes.
3. **Recall relevant knowledge**: Search stored memories for context related to the task area (if memory tools are available). This avoids re-learning things the user has already taught you.
4. **Load applicable skills**: Consult the skill loading matrix in `copilot-instructions.md` and load **all** relevant skills before writing any code. Never start implementation without first checking which skills apply.

## Task End

When completing a task:

1. **Verify clean state**: Ensure all changes are committed (no uncommitted modifications). Run `git --no-pager status --short` to confirm.
2. **Persist knowledge**: If you learned something significant about the codebase — a convention, a gotcha, a structural insight — persist it using memory tools so future sessions benefit.
3. **Provide a summary**: Follow the completion communication rules in `pre-implementation`. Keep it concise: what was done, what files changed, and any follow-up items.

## On Failure

When a build, test, lint, or typecheck fails:

1. **STOP immediately** — Do not proceed to the next step. A failing pipeline means the current step is not done.
2. **Report clearly**: State exactly what failed, the error message, and which file/line if applicable. Don't paraphrase errors — include the actual output.
3. **Diagnose before fixing**: Understand the root cause before attempting a fix. Read the relevant code, check recent changes, and form a hypothesis.
4. **Don't retry blindly**: If a fix doesn't work after **2 attempts**, stop and ask the user for guidance. Repeating the same approach wastes context and time.

## Context Management

- **Monitor conversation length**: If the conversation is getting long (many back-and-forth turns, large file reads), proactively suggest starting a fresh session. Don't wait until context is exhausted.
- **Preserve context on handoff**: When suggesting a new session, provide a concise summary of:
  - What was done (completed steps)
  - What remains (pending work)
  - Key decisions made (and why)
  - Any blockers or open questions
- **Minimize context waste**: Don't re-read files you've already read in this session unless they may have changed (e.g., after an edit or a git operation). Prefer targeted line ranges over full file reads for large files.

---

> NOTE: If any of the rules contradict any existing coding styles, best practices, or suggestions within the current project then the rules can be overridden. However, if the rules _are_ overridden, this _must_ be **explicitly** mentioned to the user.
