# Requirements traceability

Generated from the file header comments. Keep it updated when files are added.

| FR | Requirement | Files |
|---|---|---|
| FR-01 | Content library | 29 |
| FR-02 | Automatic logging of access/participation (mobile app; back office shows the results) | 0 |
| FR-03 | Cohorts (communities) | 35 |
| FR-04 | Leader/admin dashboard | 29 |
| FR-05 | Follow-up with inactivity alerts | 19 |
| FR-06 | Multi-region, low connectivity (mobile app) | 0 |
| FR-07 | Role and permission management | 61 |
| FR-08 | Content approval workflow | 23 |
| FR-09 | Reporting and moderation | 20 |
| FR-10 | Consent and minors | 16 |
| FR-11 | Native mobile app (Flutter, separate repo) | 0 |
| FR-12 | Responsive web platform (staff back office, desktop first) | 48 |
| FR-15 | Structured pathways (Should) | 16 |
| FR-19 | Notifications (Could) | 7 |
| FR-20 | Progress badges (Could) | 16 |

FR-02 (logging), FR-06 (offline) and FR-11 (native app) are delivered by the mobile app and backend. Screens with no BRD requirement (announcements, landing stories, institutions) are marked `-`.

## FR-01: Content library
- `src/app/(backoffice)/content/page.tsx`
- `src/app/(backoffice)/content/new/page.tsx`
- `src/app/(backoffice)/content/[id]/page.tsx`
- `src/features/content/components/ContentTable.tsx`
- `src/features/content/components/ContentFilters.tsx`
- `src/features/content/components/ContentTypeSwitch.tsx`
- `src/features/content/components/ReviewPanel.tsx`
- `src/features/content/components/WorkflowStatusBadge.tsx`
- `src/features/content/components/ApprovalTrail.tsx`
- `src/features/content/components/ValidatorField.tsx`
- `src/features/content/components/DetailsFields.tsx`
- `src/features/content/components/VideoForm.tsx`
- `src/features/content/components/VideoUploader.tsx`
- `src/features/content/components/ThumbnailUploader.tsx`
- `src/features/content/components/DevotionalForm.tsx`
- `src/features/content/components/DocumentForm.tsx`
- `src/features/content/components/PathwayPicker.tsx`
- `src/features/content/components/PublishingCard.tsx`
- `src/features/content/workflow.ts`
- `src/features/content/queries.ts`
- `src/features/content/schemas.ts`
- `src/features/bible/components/BibleLinkSelect.tsx`
- `src/features/bible/queries.ts`
- `src/features/quiz/components/QuizBuilder.tsx`
- `src/features/quiz/components/QuestionEditor.tsx`
- `src/features/quiz/components/OptionList.tsx`
- `src/features/quiz/components/QuizSettings.tsx`
- `src/features/quiz/components/QuizSummary.tsx`
- `src/features/quiz/schemas.ts`

## FR-02: Automatic logging of access/participation (mobile app; back office shows the results)
- Not in this repo

## FR-03: Cohorts (communities)
- `src/app/(backoffice)/institutions/page.tsx`
- `src/app/(backoffice)/institutions/new/page.tsx`
- `src/app/(backoffice)/communities/page.tsx`
- `src/app/(backoffice)/communities/new/page.tsx`
- `src/app/(backoffice)/communities/[id]/page.tsx`
- `src/features/institutions/components/InstitutionTable.tsx`
- `src/features/institutions/components/InstitutionForm.tsx`
- `src/features/institutions/queries.ts`
- `src/features/institutions/schemas.ts`
- `src/features/communities/components/CommunityTable.tsx`
- `src/features/communities/components/CommunityForm.tsx`
- `src/features/communities/components/CoverPhotoUploader.tsx`
- `src/features/communities/components/MeetingFields.tsx`
- `src/features/communities/components/TeamPicker.tsx`
- `src/features/communities/queries.ts`
- `src/features/communities/schemas.ts`
- `src/app/(backoffice)/join-requests/page.tsx`
- `src/features/join-requests/components/JoinRequestTable.tsx`
- `src/features/join-requests/components/BulkApproveBar.tsx`
- `src/features/join-requests/components/ConflictBadge.tsx`
- `src/features/join-requests/components/DeclineDialog.tsx`
- `src/features/join-requests/components/RuleNotice.tsx`
- `src/features/join-requests/queries.ts`
- `src/app/(my-community)/layout.tsx`
- `src/app/(my-community)/my-community/page.tsx`
- `src/app/(my-community)/my-community/join-requests/page.tsx`
- `src/app/(my-community)/my-community/members/page.tsx`
- `src/app/(my-community)/my-community/moderation/page.tsx`
- `src/app/(my-community)/my-community/resources/page.tsx`
- `src/features/my-community/components/CommunityKpis.tsx`
- `src/features/my-community/components/PendingRequestsMini.tsx`
- `src/features/my-community/components/NextMeetingCard.tsx`
- `src/features/my-community/components/FollowUpList.tsx`
- `src/features/my-community/components/WriteToGroupDialog.tsx`
- `src/features/my-community/queries.ts`

## FR-04: Leader/admin dashboard
- `src/app/(backoffice)/layout.tsx`
- `src/app/(backoffice)/dashboard/page.tsx`
- `src/app/(backoffice)/reports/page.tsx`
- `src/features/dashboard/components/KpiCard.tsx`
- `src/features/dashboard/components/WeeklyActivityChart.tsx`
- `src/features/dashboard/components/NeedsAttention.tsx`
- `src/features/dashboard/components/InactiveMembersList.tsx`
- `src/features/dashboard/queries.ts`
- `src/features/reports/components/ReportFilters.tsx`
- `src/features/reports/components/MembersOverTimeChart.tsx`
- `src/features/reports/components/CompletionsByTypeChart.tsx`
- `src/features/reports/components/ActiveCommunitiesList.tsx`
- `src/features/reports/components/ExportButtons.tsx`
- `src/features/reports/components/ScheduledReportsTable.tsx`
- `src/features/reports/components/ScheduleReportDialog.tsx`
- `src/features/reports/queries.ts`
- `src/features/reports/schemas.ts`
- `src/app/(my-community)/layout.tsx`
- `src/app/(my-community)/my-community/page.tsx`
- `src/app/(my-community)/my-community/join-requests/page.tsx`
- `src/app/(my-community)/my-community/members/page.tsx`
- `src/app/(my-community)/my-community/moderation/page.tsx`
- `src/app/(my-community)/my-community/resources/page.tsx`
- `src/features/my-community/components/CommunityKpis.tsx`
- `src/features/my-community/components/PendingRequestsMini.tsx`
- `src/features/my-community/components/NextMeetingCard.tsx`
- `src/features/my-community/components/FollowUpList.tsx`
- `src/features/my-community/components/WriteToGroupDialog.tsx`
- `src/features/my-community/queries.ts`

## FR-05: Follow-up with inactivity alerts
- `src/app/(backoffice)/notifications/page.tsx`
- `src/features/notifications/components/NotificationRuleTable.tsx`
- `src/features/notifications/components/TemplateEditor.tsx`
- `src/features/notifications/components/NotificationPreview.tsx`
- `src/features/notifications/components/InactivityDaysField.tsx`
- `src/features/notifications/queries.ts`
- `src/features/notifications/schemas.ts`
- `src/app/(my-community)/layout.tsx`
- `src/app/(my-community)/my-community/page.tsx`
- `src/app/(my-community)/my-community/join-requests/page.tsx`
- `src/app/(my-community)/my-community/members/page.tsx`
- `src/app/(my-community)/my-community/moderation/page.tsx`
- `src/app/(my-community)/my-community/resources/page.tsx`
- `src/features/my-community/components/CommunityKpis.tsx`
- `src/features/my-community/components/PendingRequestsMini.tsx`
- `src/features/my-community/components/NextMeetingCard.tsx`
- `src/features/my-community/components/FollowUpList.tsx`
- `src/features/my-community/components/WriteToGroupDialog.tsx`
- `src/features/my-community/queries.ts`

## FR-06: Multi-region, low connectivity (mobile app)
- Not in this repo

## FR-07: Role and permission management
- `src/app/page.tsx`
- `src/app/(auth)/layout.tsx`
- `src/app/(auth)/login/page.tsx`
- `src/app/(auth)/forgot-password/page.tsx`
- `src/app/(auth)/reset-password/page.tsx`
- `src/app/(backoffice)/account/page.tsx`
- `src/features/auth/components/LoginForm.tsx`
- `src/features/auth/components/ForgotPasswordForm.tsx`
- `src/features/auth/components/ResetPasswordForm.tsx`
- `src/features/auth/components/PasswordRules.tsx`
- `src/features/auth/password-rules.ts`
- `src/features/auth/hooks/useSession.ts`
- `src/features/auth/schemas.ts`
- `src/features/account/components/ProfileForm.tsx`
- `src/features/account/components/ChangePasswordForm.tsx`
- `src/features/account/components/SessionsList.tsx`
- `src/features/account/queries.ts`
- `src/lib/auth/session.ts`
- `src/lib/auth/cookies.ts`
- `src/lib/auth/guards.ts`
- `src/lib/auth/redirects.ts`
- `src/middleware.ts`
- `src/app/api/proxy/[...path]/route.ts`
- `src/app/api/health/route.ts`
- `src/app/(backoffice)/members/page.tsx`
- `src/app/(backoffice)/members/new/page.tsx`
- `src/app/(backoffice)/members/import/page.tsx`
- `src/app/(backoffice)/members/[id]/page.tsx`
- `src/features/members/components/MemberTable.tsx`
- `src/features/members/components/MemberFilters.tsx`
- `src/features/members/components/MemberDetailPanel.tsx`
- `src/features/members/components/ChangeRoleDialog.tsx`
- `src/features/members/components/MoveCommunityDialog.tsx`
- `src/features/members/components/SuspendDialog.tsx`
- `src/features/members/components/AddUserForm.tsx`
- `src/features/members/components/RoleSelector.tsx`
- `src/features/members/components/MinorBadge.tsx`
- `src/features/members/queries.ts`
- `src/features/members/schemas.ts`
- `src/features/import/components/ImportStepper.tsx`
- `src/features/import/components/UploadStep.tsx`
- `src/features/import/components/MapColumnsStep.tsx`
- `src/features/import/components/ReviewStep.tsx`
- `src/features/import/components/RunStep.tsx`
- `src/features/import/csv.ts`
- `src/features/import/queries.ts`
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

## FR-08: Content approval workflow
- `src/app/(backoffice)/content/page.tsx`
- `src/app/(backoffice)/content/new/page.tsx`
- `src/app/(backoffice)/content/[id]/page.tsx`
- `src/features/content/components/ContentTable.tsx`
- `src/features/content/components/ContentFilters.tsx`
- `src/features/content/components/ContentTypeSwitch.tsx`
- `src/features/content/components/ReviewPanel.tsx`
- `src/features/content/components/WorkflowStatusBadge.tsx`
- `src/features/content/components/ApprovalTrail.tsx`
- `src/features/content/components/ValidatorField.tsx`
- `src/features/content/components/DetailsFields.tsx`
- `src/features/content/components/VideoForm.tsx`
- `src/features/content/components/VideoUploader.tsx`
- `src/features/content/components/ThumbnailUploader.tsx`
- `src/features/content/components/DevotionalForm.tsx`
- `src/features/content/components/DocumentForm.tsx`
- `src/features/content/components/PathwayPicker.tsx`
- `src/features/content/components/PublishingCard.tsx`
- `src/features/content/workflow.ts`
- `src/features/content/queries.ts`
- `src/features/content/schemas.ts`
- `src/features/bible/components/BibleLinkSelect.tsx`
- `src/features/bible/queries.ts`

## FR-09: Reporting and moderation
- `src/app/(backoffice)/moderation/layout.tsx`
- `src/app/(backoffice)/moderation/page.tsx`
- `src/app/(backoffice)/moderation/reports/page.tsx`
- `src/app/(backoffice)/moderation/testimonies/page.tsx`
- `src/app/(backoffice)/moderation/posts/page.tsx`
- `src/app/(backoffice)/moderation/sanctions/page.tsx`
- `src/features/moderation/components/CommunityFilter.tsx`
- `src/features/moderation/components/ModerationTabs.tsx`
- `src/features/moderation/components/ReportQueue.tsx`
- `src/features/moderation/components/ReportDetail.tsx`
- `src/features/moderation/components/TestimonyQueue.tsx`
- `src/features/moderation/components/TestimonyReview.tsx`
- `src/features/moderation/components/PostQueue.tsx`
- `src/features/moderation/components/PostReview.tsx`
- `src/features/moderation/components/SanctionsTable.tsx`
- `src/features/moderation/components/ReinstateDialog.tsx`
- `src/features/moderation/components/ModerationActions.tsx`
- `src/features/moderation/components/EscalationInfo.tsx`
- `src/features/moderation/queries.ts`
- `src/features/moderation/schemas.ts`

## FR-10: Consent and minors
- `src/app/(backoffice)/privacy/layout.tsx`
- `src/app/(backoffice)/privacy/page.tsx`
- `src/app/(backoffice)/privacy/guardian-consents/page.tsx`
- `src/app/(backoffice)/privacy/data-requests/page.tsx`
- `src/features/privacy/components/GuardianConsentTable.tsx`
- `src/features/privacy/components/DataRequestsTable.tsx`
- `src/features/privacy/components/ProcessRequestDialog.tsx`
- `src/features/privacy/components/DeadlineBadge.tsx`
- `src/features/privacy/queries.ts`
- `src/app/(backoffice)/settings/page.tsx`
- `src/features/settings/components/CharterForm.tsx`
- `src/features/settings/components/ConsentTextsForm.tsx`
- `src/features/settings/components/MinorsForm.tsx`
- `src/features/settings/components/RetentionForm.tsx`
- `src/features/settings/queries.ts`
- `src/features/settings/schemas.ts`

## FR-11: Native mobile app (Flutter, separate repo)
- Not in this repo

## FR-12: Responsive web platform (staff back office, desktop first)
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

## FR-15: Structured pathways (Should)
- `src/app/(backoffice)/pathways/page.tsx`
- `src/app/(backoffice)/pathways/new/page.tsx`
- `src/app/(backoffice)/pathways/[id]/page.tsx`
- `src/app/(backoffice)/badges/page.tsx`
- `src/features/pathways/components/PathwayList.tsx`
- `src/features/pathways/components/PathwayEditor.tsx`
- `src/features/pathways/components/StepList.tsx`
- `src/features/pathways/components/AddStepDialog.tsx`
- `src/features/pathways/components/UnlockRuleSelect.tsx`
- `src/features/pathways/queries.ts`
- `src/features/pathways/schemas.ts`
- `src/features/badges/components/BadgeTable.tsx`
- `src/features/badges/components/BadgeForm.tsx`
- `src/features/badges/components/RuleSelect.tsx`
- `src/features/badges/components/IconPicker.tsx`
- `src/features/badges/queries.ts`

## FR-19: Notifications (Could)
- `src/app/(backoffice)/notifications/page.tsx`
- `src/features/notifications/components/NotificationRuleTable.tsx`
- `src/features/notifications/components/TemplateEditor.tsx`
- `src/features/notifications/components/NotificationPreview.tsx`
- `src/features/notifications/components/InactivityDaysField.tsx`
- `src/features/notifications/queries.ts`
- `src/features/notifications/schemas.ts`

## FR-20: Progress badges (Could)
- `src/app/(backoffice)/pathways/page.tsx`
- `src/app/(backoffice)/pathways/new/page.tsx`
- `src/app/(backoffice)/pathways/[id]/page.tsx`
- `src/app/(backoffice)/badges/page.tsx`
- `src/features/pathways/components/PathwayList.tsx`
- `src/features/pathways/components/PathwayEditor.tsx`
- `src/features/pathways/components/StepList.tsx`
- `src/features/pathways/components/AddStepDialog.tsx`
- `src/features/pathways/components/UnlockRuleSelect.tsx`
- `src/features/pathways/queries.ts`
- `src/features/pathways/schemas.ts`
- `src/features/badges/components/BadgeTable.tsx`
- `src/features/badges/components/BadgeForm.tsx`
- `src/features/badges/components/RuleSelect.tsx`
- `src/features/badges/components/IconPicker.tsx`
- `src/features/badges/queries.ts`
