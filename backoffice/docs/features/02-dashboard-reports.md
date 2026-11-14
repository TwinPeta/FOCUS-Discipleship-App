# Dashboard and reports

**Design boards:** B1, B20  
**BRD requirements:** FR-04

## Problem it solves
Admins can see activity and what needs attention without hunting through screens; reports can be shared with stakeholders.

## What the web app needs
- Dashboard KPIs with change versus previous 30 days: active members, new members, resources completed, open reports
- Weekly activity chart (logins and completions)
- Needs your attention: pending join requests, reports to review, testimonies awaiting moderation, content in review, each linking to its queue
- Inactive members (14+ days) with community and Send reminder
- Reports: filters (period, campus, community), members over time, completions by content type, most active communities, meetings attended, reports handled and average answer time
- Export PDF and CSV; scheduled reports (weekly, monthly) emailed to recipients

## Rules and edge cases
- Exports are audited
- Super-mentors never see this screen; they get the scoped KPIs in My community
- Empty states for new installs with no data
- Scheduled reports are executed by the backend; the UI only manages schedules

## To confirm
- Where is meeting attendance recorded?
- Definition of active and inactive (design uses 14 days)

## Files for this feature
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
