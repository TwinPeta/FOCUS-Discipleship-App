# Roles and audit log

**Design boards:** B9, B26  
**BRD requirements:** FR-07

## Problem it solves
Makes permissions visible and keeps every sensitive action accountable.

## What the web app needs
- Permission matrix (C consult, M modify, V validate, A administer) for student, mentor, super-mentor, content admin, system admin
- Add staff account with role and community scope
- Audit log: when, who, action, target, place; search, action, role and period filters; export
- Recent audit preview on the roles page

## Rules and edge cases
- Audit log cannot be edited or deleted; exporting it is also audited
- Matrix is a proposal to be validated with FOCUS Uganda
- Audited actions include sign-ins, viewing personal data, exports, suspensions, approvals, publishing and cover changes

## To confirm
- Is the matrix editable or fixed?
- Audit retention period

## Files for this feature
- `src/app/(backoffice)/roles/page.tsx`
- `src/app/(backoffice)/roles/staff/new/page.tsx`
- `src/app/(backoffice)/audit-log/page.tsx`
- `src/features/roles/components/PermissionMatrix.tsx`
- `src/features/roles/components/StaffAccountForm.tsx`
- `src/features/roles/components/AuditPreview.tsx`
- `src/features/roles/queries.ts`
- `src/features/audit/components/AuditTable.tsx`
- `src/features/audit/components/AuditFilters.tsx`
- `src/features/audit/components/ExportAuditButton.tsx`
- `src/features/audit/queries.ts`
- `src/lib/permissions/roles.ts`
- `src/lib/permissions/matrix.ts`
- `src/lib/permissions/can.ts`
- `src/lib/permissions/scope.ts`
