---
name: testing-conventions
description: Testing standards and tooling for this project. Use when writing tests, running the test suite, or setting up test infrastructure.
---

# Testing Conventions

## Test Framework

- **Vitest** (not Jest) — Vite-native, configured in `vite.config.ts`
- Run tests: `npm run test` (single run) or `npm run test:watch` (watch mode)
- Browser testing: `@vitest/browser` with Playwright
- Coverage: `@vitest/coverage-v8`

## Architecture Tests

`source/__tests__/architecture.test.ts` automatically enforces project standards including file size limits, function size limits, naming conventions, TSDoc coverage, and import organization. These tests run as part of `npm run test` — any new code must pass them.

## Test File Location

- Co-locate test files with their source: `ComponentName.test.tsx` next to `ComponentName.tsx`
- Shared test utilities and fixtures go in `source/__tests__/`

## Storybook

- Every UI component should have a story: `ComponentName.stories.tsx`
- Run Storybook: `npm run storybook` (dev on port 6006)
- Build Storybook: `npm run build-storybook` (outputs to `public/storybook`)
- Accessibility auditing is enabled via `@storybook/addon-a11y`
- Visual regression testing available via Chromatic integration

## Validation Pipeline

The full quality gate before any work is considered done:

```bash
npm run validate   # Runs all of these in sequence:
#   1. npm run typecheck   — TypeScript compilation
#   2. npm run lint         — ESLint checks
#   3. npm run format       — Prettier formatting
#   4. npm run test         — Vitest test suite
```

All four must pass. Do not skip any step.

## Supabase Tests

- Database tests live in `supabase/tests/` (Deno test runner)
- Migration validation: `scripts/check-migration-timestamps.js`
- Sample data for testing: `supabase/comprehensive-sample-data.sql`
