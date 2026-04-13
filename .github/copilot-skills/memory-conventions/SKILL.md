---
name: memory-conventions
description: Guidelines for using memory and persistence tools effectively. Use whenever you learn something worth remembering or need to recall project context.
---

# Memory Conventions

This project has **two memory systems** for persisting knowledge across sessions. Use the right tool for the job.

## When to Use Which Tool

### `store_memory` (Built-in Tool)

Quick, self-contained facts. Each entry has: category, subject, fact, reason, citations.

**Best for:**

- Code conventions and style rules
- Verified build/test/lint commands
- User preferences
- Short architectural decisions
- File-specific notes

**Example:** _"The project uses Vitest for testing, run with `npm run test`."_

### MCP Memory Tools (`mcp-memory-sqlite`)

Rich knowledge graph with entities, relations, observations, and FTS5 search.

**Tools:** `create_entities`, `add_observations`, `delete_observations`, `search_nodes`, `search_related_nodes`, `read_graph`, `create_relations`, `get_entity_with_relations`, `delete_entity`, `delete_relation`

**Best for:**

- Structured project knowledge — entities with typed relationships
- Building a knowledge graph of the project's architecture, components, patterns, and their interconnections
- Detailed observations about how systems interact
- Anything that benefits from being queryable or having relationships to other knowledge

**Example:** Creating an entity `feature/auth` with observations about its implementation, then relating it to `component/AuthProvider` via `uses`.

## Entity Naming Conventions (MCP Memory)

Use descriptive, namespaced subjects:

| Prefix               | Purpose                               | Examples                                              |
| -------------------- | ------------------------------------- | ----------------------------------------------------- |
| `project/<name>`     | Top-level project info                | `project/yatagarasu`                                  |
| `feature/<area>`     | Feature-level knowledge               | `feature/auth`, `feature/scheduling`                  |
| `pattern/<name>`     | Recurring patterns                    | `pattern/service-layer`, `pattern/view-edit-modal`    |
| `component/<name>`   | Key component knowledge               | `component/Sidebar`, `component/DataTable`            |
| `convention/<topic>` | Code conventions                      | `convention/naming`, `convention/error-handling`      |
| `user-pref/<topic>`  | User preferences                      | `user-pref/commit-style`, `user-pref/tabs-vs-spaces`  |
| `decision/<topic>`   | Architectural decisions and rationale | `decision/state-management`, `decision/auth-strategy` |

## Relation Types

Use these standard relation types to keep the graph consistent:

- **`uses`** — A depends on or consumes B at runtime
- **`depends-on`** — A requires B to build or function
- **`implements`** — A is a concrete implementation of B
- **`part-of`** — A is a sub-component or module within B
- **`replaces`** — A supersedes or replaces B
- **`related-to`** — General association when no stronger relation applies

## Mandatory Checkpoints

### After Learning Something Significant

Persist it immediately — don't wait for the task to end. If you discover a convention, architectural boundary, or non-obvious behavior, store it right away.

### Before Session Ends

Ensure all important knowledge gathered during the session is stored. Review what you've learned and check that nothing significant was left only in the conversation context.

### When Discovering Architecture

Map entities and relationships as you explore. When you find that component A depends on service B which implements pattern C, create all three entities and their relations.

## Pre-Task Recall

Before starting a new task:

1. **Search memory** for relevant context using `search_nodes` with keywords related to the task area
2. **Check existing entities** for the feature/component being modified
3. **Review related nodes** to understand the broader context around what you're changing
4. Use recalled context to avoid re-discovering things and to stay consistent with prior decisions

## Quality Gates

Only persist facts that meet **all** of these criteria:

- **Actionable** — Will influence future code generation or review
- **Stable** — Unlikely to change with the next commit
- **Non-obvious** — Can't be trivially inferred from reading the code
- **Verified** — You've confirmed the fact is accurate (not speculative)

If a fact doesn't pass all four gates, don't store it. Noisy memory is worse than no memory.

> NOTE: If any of the rules contradict any existing coding styles, best practices, or suggestions within the current project then the rules can be overridden. However, if the rules _are_ overridden, this _must_ be **explicitly** mentioned to the user.
