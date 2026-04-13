---
name: skill-maintenance
description: Rules for maintaining, creating, and amending Copilot skills. Use when you notice recurring patterns, style preferences, convention changes, or gaps in existing skills that should be captured for future sessions.
---

# Skill Maintenance

Copilot skills live in `.github/copilot-skills/`. Each skill is a **folder** (kebab-case name) containing a `SKILL.md` file with YAML frontmatter (`name`, `description`) followed by Markdown instructions. They are the project's living style guide — they should evolve as the project evolves.

## When to Propose a Skill Change

Watch for these signals while working:

- **Recurring corrections** — the user keeps asking for the same thing that isn't captured in a skill
- **New conventions** — a pattern emerges (new library adopted, naming shift, architectural decision) that future sessions should follow
- **Style preferences** — the user expresses a preference (e.g., "always do X", "never do Y") that applies broadly
- **Outdated rules** — a skill references patterns, files, libraries, or conventions that no longer exist in the codebase
- **Missing coverage** — you encounter a domain or workflow with no relevant skill (e.g., a new integration, deployment pattern, or toolchain)

## How to Propose Changes

1. **Always ask the user before creating or modifying a skill.** Explain what you noticed and why you think a skill change is warranted. Never silently create or amend skills.
2. Frame it as: _"I've noticed [pattern/preference]. Should I capture this as a Copilot skill so future sessions follow it automatically?"_
3. If the user agrees, proceed with the change. If they decline, respect that and move on.

## Creating a New Skill

- Create a new folder with a kebab-case name (e.g., `deployment-patterns/`)
- Inside the folder, create a `SKILL.md` file
- Include YAML frontmatter with `name` (matching the folder name) and `description` (a clear sentence explaining when the skill should be loaded)
- The `description` field is critical — it determines when Copilot loads the skill. Make it specific enough to trigger in the right contexts but broad enough not to be missed
- Write rules as actionable directives, not suggestions. Use **bold** for key phrases
- Reference actual project file paths, commands, and patterns — not hypothetical ones
- Keep each skill focused on a single domain. If the content spans multiple concerns, split it into separate skills

## Amending an Existing Skill

- Before editing, read all existing skills to check for contradictions or duplication with the proposed change
- Each rule must have exactly **one canonical home**. If a rule is relevant to multiple skills, put the detailed version in the most relevant skill and keep only a brief actionable reference in others
- When a convention changes (e.g., migrating from one library to another), update every skill that references the old convention — not just the primary one
- Remove rules that reference deleted files, deprecated libraries, or abandoned patterns

## Skill Hygiene Rules

- **No duplication** — never state the same rule in full detail in more than one skill
- **No contradictions** — if two skills disagree, resolve it before committing
- **Self-contained** — each skill must make sense if loaded alone (since Copilot may not load all skills for every prompt). Brief cross-references are fine; depending on another skill for critical context is not
- **Commit skill changes separately** from feature work, with a descriptive commit message (e.g., "Add deployment-patterns skill for Vercel conventions")
