# Suggested build order

Specs are in `docs/features/`. Screen numbers (B1 to B29) refer to the design file.

## Phase 0: Foundation
- [ ] `pnpm install`, env, CI green
- [ ] Tokens in `globals.css`, shadcn base components (button, input, select, tabs, dialog, checkbox, switch, toast)
- [ ] Providers, API client, query client, env, logger, Sentry
- [ ] MSW setup
- [ ] AppShell, Sidebar (nav-config), PageHeader, DataTable, SidePanel, FilterBar, TabsWithCount, StatusPill, EmptyState, ErrorState

## Phase 1: Staff access (01) B10, B25, B27, B28
- [ ] Login, forgot password, reset password with rules checklist
- [ ] Session, cookies, proxy route, middleware, guards
- [ ] My account (profile, password, sessions)
- [ ] Permission matrix, `can`, scope rules

## Phase 2: Institutions, communities, join requests (03, 04) B15, B3, B14, B2
- [ ] Institutions list and edit panel
- [ ] Communities list, create, edit, cover photo with crop
- [ ] Join requests: tabs, single approve and decline, bulk approve, conflict badge

## Phase 3: Members and users (05) B4, B11, B24
- [ ] Members list, filters, detail panel (audit notice)
- [ ] Add user (including minor guardian consent), change role, move community, suspend
- [ ] CSV import in four steps

## Phase 4: Content and validation (06, 07) B5, B12, B13
- [ ] Content list, status tabs, filters
- [ ] Details, video upload, devotional editor, document upload
- [ ] Workflow transitions, review panel, approval trail
- [ ] Quiz builder

## Phase 5: Moderation (11) B7, B16, B17, B18
- [ ] Moderation tabs and community filter
- [ ] Reports, testimonies, prayer and posts, sanctions with reinstate
- [ ] Level 1 and level 2 actions by role

## Phase 6: Privacy and settings (12, 14) B23, B19
- [ ] Guardian consents with reminders, data requests with deadlines
- [ ] Charter, consent texts, minors, retention settings

## Phase 7: Roles, audit, dashboard (13, 02) B9, B26, B1, B20
- [ ] Permission matrix view, add staff account
- [ ] Audit log with filters and export
- [ ] Dashboard KPIs, attention list, inactive members
- [ ] Reports and statistics, exports, scheduled reports

## Phase 8: Super-mentor view (15) B29
- [ ] Scoped shell and home, own join requests, members, moderation, resources, write to group

## Phase 9: Engagement tooling (08, 09, 10) B6, B21, B8, B22
- [ ] Pathways with drag reorder and unlock rule, badges
- [ ] Announcements and landing stories
- [ ] Notification rules and templates (needed by inactivity reminders)

## Phase 10: Hardening
- [ ] Accessibility pass, 1024px layouts, security headers and CSP, error monitoring checks

## Blocked until answered
See `OPEN-QUESTIONS.md`: attendance source (dashboard, badges), mentor access (Phase 8), level 2 moderation rights (Phase 5), guardian consent collection (Phase 6), upload protocol (Phase 4), v1 scope of Phase 9.
