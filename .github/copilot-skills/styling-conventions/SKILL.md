---
name: styling-conventions
description: UI styling and design system conventions for this project. Use when writing styles, creating UI components, or working with the design system.
---

# Styling & Design System

## TailwindCSS

- **TailwindCSS 3** with PostCSS — configured in `tailwind.config.ts`
- Dark mode: class-based (`darkMode: ["class"]`) — toggled via `ThemeContext`
- Global styles and Tailwind directives are in `source/index.css`

## Class Name Merging

**Always use `combineClassNames()` from `@/lib/core/utils`** for combining class names:

```tsx
import { combineClassNames } from "@/lib/core/utils";

<div className={combineClassNames("base-classes", conditional && "conditional-classes", className)} />;
```

This uses clsx + tailwind-merge under the hood to properly handle Tailwind class conflicts.

## shadcn/ui Component Library

- Base color: **zinc** with CSS variables enabled
- Components live in `source/components/ui/`
- Configuration: `components.json` at repo root
- When adding new primitives, use the shadcn/ui CLI or follow existing patterns

## Color System

- The project has a documented color system — see `docs/architecture/COLOR_SYSTEM.md`
- Use semantic color variables (defined via CSS custom properties) over raw color values
- Ensure all new UI respects both light and dark themes

## Icons

- **Lucide React** is the only icon library — do not introduce others
- Icons are tree-shakeable, import individually: `import { Icon } from "lucide-react"`

## Animation

- **Complex animations:** Framer Motion (`framer-motion`)
- **Simple transitions:** `tailwindcss-animate` utility classes
- Keep animations subtle and purposeful — this is a professional healthcare platform

## Notifications

- **Toast notifications:** Sonner (`sonner`) — use the existing toast hook at `source/hooks/ui/use-toast.ts`

## Responsive Design

- Mobile-first approach using Tailwind breakpoints
- Detect mobile via `use-mobile.tsx` hook
- Compact mode toggle available via `useCompactMode.tsx` hook
- Breakpoints: xs (375px), sm (640px), md (768px), lg (1024px), xl (1280px), 2xl (1536px)

## Layout

- Resizable panels: `react-resizable-panels`
- Grid layouts: `react-grid-layout` (used in customizable dashboard)
- Virtual scrolling: `@tanstack/react-virtual` for large lists
