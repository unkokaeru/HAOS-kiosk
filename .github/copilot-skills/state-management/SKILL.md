---
name: state-management
description: State management and data fetching patterns used in this project. Use when working with application state, contexts, forms, or server data.
---

# State Management Patterns

## Server State — React Query (TanStack)

- **All server-derived data** must use React Query — never raw `useState` + `useEffect` for fetching
- Default configuration: 5-minute stale time, 3 retries with exponential backoff
- Cache config constants are in `source/constants/time/durations.ts` and `source/constants/auth/session.ts`
- React Query is provided at the app root via `QueryClientProvider`

## UI State — React Context with SOLID Principles

Domain-specific contexts follow interface segregation (SOLID ISP):

- Each context exposes **separate read and write interfaces**:
  - `IWorkOrderReadContext` / `IWorkOrderWriteContext`
  - `IAppointmentReadContext` / `IAppointmentWriteContext`
  - `IStaffReadContext` / `IStaffContext`
- Granular capability interfaces: `IRefreshable`, `ICreatable`, `IUpdatable`, `IDeletable`
- Type guards for runtime capability checking: `hasWorkOrderReadCapability()`, `hasErrorHandling()`

### Context Organization

- Domain contexts: `source/contexts/` (WorkOrder, Appointment, Staff, Mileage, Task, Modal)
- Auth context: `SupabaseAuthContext` for authentication state
- Config contexts: `PlatformSettingsContext`, `ConfigurationContext`, `ThemeContext`
- Composition: `CombinedDataProviders` wraps all domain contexts for convenience

### When to Use What

| Data Type             | Tool            | Example                                |
| --------------------- | --------------- | -------------------------------------- |
| Server/DB data        | React Query     | Fetching appointments, clients, staff  |
| Shared UI state       | React Context   | Sidebar state, theme, modal visibility |
| Form state            | React Hook Form | Any user input form                    |
| Local component state | `useState`      | Toggles, temporary UI state            |

## Forms — React Hook Form + Zod

- All forms use React Hook Form with `@hookform/resolvers` for Zod integration
- Zod schemas are organized by domain (e.g., `appointment-schemas.ts`, `client-schemas.ts`)
- Schema files live alongside their feature or in a shared schemas directory
- Always validate with Zod — never trust client input without schema validation

## Data Flow

```
Supabase DB
    ↓
Supabase Client (source/lib/supabase/)
    ↓
Services (source/services/) — via IServiceResult<T>
    ↓
Context Providers (source/contexts/) — read/write interfaces
    ↓
Custom Hooks (source/hooks/) — React Query + business logic
    ↓
Components — consume via hooks or useContext
```
