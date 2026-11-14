# Shared UI and brand

**Design boards:** all  
**BRD requirements:** FR-12

## Problem it solves
Consistent, simple interface for non-technical staff.

## What the web app needs
- Yellow sidebar (240px) with grouped navigation, active item white, user card and sign out
- Tokens: #F4B400 primary, #FFFBEA background, #FFF3C4 soft, #FDE68A accent, #E6D48A border, #111111 text, #6A6A6A muted; font Source Sans 3
- Table plus side panel pattern, tabs with counts, status pills, confirm dialogs, dropzones
- Consistent loading, empty and error states

## Rules and edge cases
- Desktop first (1280px design) but usable at 1024px and tablet
- Check contrast of text on yellow surfaces
- Status colours are not defined in the design yet

## To confirm
- Logo and exact status colours
- Dark mode (not designed)

## Files for this feature
- `src/app/layout.tsx`
- `src/app/globals.css`
- `src/app/not-found.tsx`
- `src/app/error.tsx`
- `src/app/global-error.tsx`
- `src/app/loading.tsx`
- `src/app/forbidden/page.tsx`
- `src/components/layout/AppShell.tsx`
- `src/components/layout/Sidebar.tsx`
- `src/components/layout/nav-config.ts`
- `src/components/layout/PageHeader.tsx`
- `src/components/layout/UserCard.tsx`
- `src/components/data-table/DataTable.tsx`
- `src/components/data-table/DataTablePagination.tsx`
- `src/components/data-table/StatusPill.tsx`
- `src/components/common/SidePanel.tsx`
- `src/components/common/FilterBar.tsx`
- `src/components/common/TabsWithCount.tsx`
- `src/components/common/InitialsAvatar.tsx`
- `src/components/common/FileDropzone.tsx`
- `src/components/common/ConfirmDialog.tsx`
- `src/components/common/DateRangeSelect.tsx`
- `src/components/common/ExportMenu.tsx`
- `src/components/common/AuditNotice.tsx`
- `src/components/feedback/EmptyState.tsx`
- `src/components/feedback/ErrorState.tsx`
- `src/components/feedback/Skeletons.tsx`
- `src/components/feedback/ForbiddenState.tsx`
- `src/components/ui/README.md`
- `src/hooks/useDebounce.ts`
- `src/hooks/useUrlState.ts`
- `src/lib/api/client.ts`
- `src/lib/api/schema.d.ts`
- `src/lib/api/errors.ts`
- `src/lib/api/query-keys.ts`
- `src/lib/query-client.ts`
- `src/lib/env.ts`
- `src/lib/utils.ts`
- `src/lib/format/date.ts`
- `src/lib/constants/routes.ts`
- `src/lib/logger.ts`
- `src/lib/monitoring/sentry.ts`
- `src/instrumentation.ts`
- `src/types/enums.ts`
- `src/types/user.ts`
- `src/providers/Providers.tsx`
- `src/providers/QueryProvider.tsx`
- `src/providers/SessionProvider.tsx`
