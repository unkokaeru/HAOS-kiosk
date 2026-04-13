---
name: code-quality
description: Code quality standards and architecture rules enforced in this project. Use when writing or reviewing code.
---

# Code Quality & Architecture Rules

## Enforced Limits

- **Max file size:** 500 lines (warning at 300 lines)
- **Max function size:** ~50 lines
- These limits are automatically enforced by architecture tests in `source/__tests__/architecture.test.ts`

## TypeScript Strict Mode

The project enforces full strict mode (`tsconfig.json`):

- `"strict": true` — enables all strict checks
- `"noImplicitAny": true` — never use `any`; use `unknown` with type guards instead
- `"noUnusedParameters": true` — remove unused function parameters
- `"noUnusedLocals": true` — remove unused variables
- `"strictNullChecks": true` — handle null/undefined explicitly
- `"forceConsistentCasingInFileNames": true` — respect OS file casing

## Naming Conventions

- **Components:** PascalCase (`ErrorBoundary.tsx`)
- **Hooks:** camelCase with `use` prefix (`useStaffSync.ts`)
- **Services:** kebab-case with `.service.ts` suffix (`feedback.service.ts`)
- **Contexts:** PascalCase with `Context` suffix (`WorkOrderContext.tsx`)
- **Constants:** UPPER_SNAKE_CASE (`CACHE_CONFIG`)
- **Types/Interfaces:** PascalCase, prefix interfaces with `I` (`IServiceResult`)
- **Never use temporal or obsolete naming** — no `new_`, `old_`, `temp_` prefixes, and never reference features, concepts, or workflows that no longer exist in the codebase. When replacing something, replace the name entirely rather than prefixing the replacement
- **Never use single-letter variable names** — not even for loop counters, callbacks, or destructured parameters. Use descriptive names: `index` not `i`, `element` not `e`, `key`/`value` not `k`/`v`, `event` not `e`, `error` not `e`
- **Never use abbreviations or shortenings** — write out full words. Use `appointment` not `appt`, `configuration` not `config` (unless it's part of an established API or library name you don't control), `notification` not `notif`, `button` not `btn`, `message` not `msg`, `parameter` not `param`. If a name feels too long, that's a sign the function or variable is doing too much — refactor instead of abbreviating

## Constants, Magic Values & Single Source of Truth

- **Never hardcode magic numbers, strings, URLs, keys, or any configurable value inline** — extract them to a named constant or configuration entry
- **Every value must be defined in exactly one place.** It should never be the case that making a change requires editing multiple files or locations. If a value is used in more than one place, it must come from a single source
- Constants are organized by domain in `source/constants/{domain}/`
- Build-time configuration lives in `source/config/` files
- See `docs/architecture/MAGIC_NUMBERS.md` for the project's documented constants
- Central config values (cache TTL, retry counts, timeouts) live in `source/constants/`
- When encountering an existing hardcoded value, extract it as part of your current work — don't leave it for later

## Import Organization

Order imports with blank lines between groups:

1. React and standard library
2. Third-party packages
3. Local imports using the `@/` alias — never use relative paths like `../../`

## Documentation

- TSDoc/JSDoc comments are required on exported functions, components, and interfaces
- Architecture decisions are recorded in `docs/adr/`
- Feature specifications live in `docs/features/`

## Legacy Code & Cleanup

- **Actively clean up legacy code when you encounter it.** Do not leave outdated patterns, dead code, unused imports, or deprecated approaches in files you touch
- If a file you're working in contains legacy patterns, old workarounds, or code that doesn't follow current conventions — fix it as part of your work
- Remove any temporary files, debug logging, or scaffolding after completing a task
- When refactoring, ensure no orphaned files, unused exports, or broken references remain

## Project Structure

- **Maintain a logical, nested directory structure** — group related files under descriptive directories
- Files that serve a similar purpose should be organized together under a shared parent directory
- Never leave files in a flat directory when they could be logically grouped (e.g., `constants/auth/`, `constants/business/`, not dozens of files in `constants/`)
- When creating new features, follow the established domain-based organization pattern — don't dump files at the top level
- If an existing directory is getting too flat or disorganized, restructure it as part of your work

## Validation

Before considering any work complete, run `npm run validate` (typecheck → lint → format → test). All four checks must pass.
