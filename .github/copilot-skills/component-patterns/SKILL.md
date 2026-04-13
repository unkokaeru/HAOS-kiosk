---
name: component-patterns
description: React component authoring conventions for this project. Use when creating or modifying React components.
---

# Component Patterns

## Project Structure

- All source code lives under `source/` with path alias `@/` → `./source/`
- Components are organized by feature domain: `source/components/{domain}/`
- Shared UI primitives live in `source/components/ui/` (shadcn/ui, built on Radix UI)
- Common cross-cutting components live in `source/components/common/`
- Pages live in `source/pages/` and are organized by route group

## Component Authoring Rules

- **Functional components only** — no class components (except `ErrorBoundary`)
- All props must have explicit TypeScript interface or type definitions
- Co-locate related files together:
  ```
  Feature/
  ├── ComponentName.tsx
  ├── ComponentName.test.tsx
  ├── ComponentName.stories.tsx
  ├── hooks.ts
  ├── types.ts
  ├── constants.ts
  └── index.ts
  ```

## UI Primitives (shadcn/ui)

- Use existing components from `@/components/ui/` before creating new ones
- Use the `combineClassNames()` utility from `@/lib/core/utils` for class name merging
- Follow the compound component pattern used by Radix UI:
  ```tsx
  <Dialog>
    <DialogTrigger />
    <DialogContent>
      <DialogHeader />
      <DialogFooter />
    </DialogContent>
  </Dialog>
  ```
- Never modify `ui/` components directly for feature-specific behavior — wrap them instead

## Error Handling

Three levels of error boundaries exist — use the appropriate level:

- **App-level** — catches everything, in `App.tsx`
- **Route-level** — `RouteErrorBoundary` for page-level crashes
- **Feature-level** — `FeatureErrorBoundary` for isolating individual features

Use `withErrorBoundary(Component, FallbackComponent)` HOC or the `useErrorHandler()` hook.

## Code Splitting

- All pages MUST be lazy-loaded using `React.lazy()` with `<Suspense>`
- Heavy libraries (PDF, charts) are already isolated into separate chunks — keep them lazy
