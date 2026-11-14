# Conventions

## File header comment
Every placeholder starts with:
```ts
/**
 * <path>
 *
 * WHAT: what this file is for
 * REQUIREMENTS: FR-xx
 * SPEC: docs/features/<feature>.md
 * STATUS: placeholder, not implemented
 */
```
When you implement a file keep WHAT and SPEC and change STATUS to `implemented`.

## Structure rules
- Routes in `src/app` stay thin: compose feature components and load initial data. Logic lives in `src/features/<feature>`.
- Shared UI goes in `src/components`. Feature-only UI stays inside the feature.
- All HTTP goes through `src/lib/api/client.ts`.
- Paths come from `src/lib/constants/routes.ts`.
- Enums and API types come from the generated schema; `src/types/enums.ts` is temporary.

## Screen patterns (from the design)
- **Table plus side panel:** list on the left, detail or edit panel beside it (`SidePanel`): members, communities, institutions, content review, badges, notifications, pathways.
- **Tabs with counts** (`TabsWithCount`) for status filters. Tab, filters and page live in the URL (`useUrlState`).
- **Audit notice:** screens that touch personal data or take moderation, export or sanction actions show `AuditNotice`, and the backend must really write the audit entry.
- **Confirm dialogs** for suspend, delete, reinstate, role change, bulk approve.
- **Every list** has loading, empty and error states.

## Permissions and scope
- `src/lib/permissions` decides what to show (matrix C/M/V/A). The backend enforces everything.
- Super-mentors are scope-locked to their community: the backend filters, the UI uses `scope.ts` to hide cross-community controls (community filters, create community, cover photo).
- Sidebar items come from `nav-config.ts`, filtered by role.
- Route protection happens in `middleware.ts` (coarse) and each shell layout (server check).

## Forms
- React Hook Form + Zod schemas in each feature's `schemas.ts`.
- Password rules are shared via `features/auth/password-rules.ts`.
- Uploads: `FileDropzone` for images and documents, `VideoUploader` for resumable video upload; show progress and handle retry.

## Text
- English only in v1. Keep copy simple and consistent with the design file.

## Accessibility and layout
- Desktop first (design is 1280px), but tables and panels must not break on 1024px and tablet widths.
- Visible focus, labelled inputs, sufficient contrast on yellow surfaces (check with axe).

## Testing
- Unit: permissions, scope, password rules, workflow transitions, CSV import, join request conflicts.
- Component: forms with rules (login, quiz builder, step list, cover uploader).
- Playwright: flows in `tests/e2e/` plus axe checks. Every feature gets MSW handlers and fixtures.
