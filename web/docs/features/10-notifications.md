# Notifications

**Design boards:** B22  
**BRD requirements:** FR-19, FR-05

## Problem it solves
Keeps students and staff informed and powers inactivity reminders, a core follow-up objective.

## What the web app needs
- Rules table: join request approved or declined, no activity for N days, new announcement, someone prayed for your request, report received, testimony published
- Each rule has recipient, channels (in-app, email) and an on/off toggle
- Template editor: title, message with the member's name, channels, preview
- Inactivity threshold field (default 14 days)

## Rules and edge cases
- Email channel needs a provider decision on the backend
- Super-mentor 'Send reminder' uses the inactivity template
- SMS appears in the BRD but not in the design

## To confirm
- Is SMS dropped?
- Rate limits for reminders

## Files for this feature
- `src/app/(backoffice)/notifications/page.tsx`
- `src/features/notifications/components/NotificationRuleTable.tsx`
- `src/features/notifications/components/TemplateEditor.tsx`
- `src/features/notifications/components/NotificationPreview.tsx`
- `src/features/notifications/components/InactivityDaysField.tsx`
- `src/features/notifications/queries.ts`
- `src/features/notifications/schemas.ts`
