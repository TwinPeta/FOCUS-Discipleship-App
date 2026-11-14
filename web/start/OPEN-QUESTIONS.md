# Open questions

Answer with FOCUS Uganda / FCU and the backend developer, then record the decision here.

| # | Question | Blocks | Decision |
|---|---|---|---|
| 1 | Is the web app staff-only? The BRD (FR-12) expects a responsive web platform for students too, but the design is a staff back office and students use the Flutter app. | Whether any student-facing web pages are needed | |
| 2 | Product and organisation name: BRD says FOCUS Uganda, design says FCU (Fellowship of Christian Unions). | Branding, copy, repo name | |
| 3 | Which of pathways, badges, announcements, landing stories, scheduled reports and notifications are in v1? The BRD lists several as Should or Could, but they are designed. | Build order Phase 9, API scope | |
| 4 | Do mentors (not super-mentors) sign in to the back office? The matrix gives mentors level 1 moderation and own dashboards, but only a super-mentor view is designed. | Phase 5, Phase 8 | |
| 5 | Is the content "Validator" (pastor or committee) a user who signs in and validates, or a name recorded by the content admin? Can the author also validate? | Content workflow, roles | |
| 6 | Where is meeting attendance recorded? KPIs and the "Faithful attendee" badge use meetings attended, but no screen captures attendance. | Dashboard, reports, badges | |
| 7 | Level 2 moderation: the matrix gives content admin "Review L2", but suspend and delete are described as admin actions. Can a content admin suspend or delete? | Moderation actions by role | |
| 8 | Minors: age threshold is a setting (default 18). How is guardian consent collected (link to guardian, upload, in person) and what does "Received" mean? What is limited for minors? | Add user, guardian consents, settings | |
| 9 | Staff accounts: who creates super-mentors and admins, by invitation email? Is two-factor sign-in required for staff? | Roles page, login | |
| 10 | Video: upload protocol (tus or S3 multipart), supported formats, who creates the lighter versions, and where videos are hosted. | VideoUploader, CSP | |
| 11 | Bible characters and texts list: static data or editable in the back office? | BibleLinkSelect | |
| 12 | Notifications: in-app and email only in the design; the BRD mentions SMS. Is SMS dropped? Who sends email? | Notifications, inactivity reminders | |
| 13 | Landing stories: how is the student's written consent recorded? | Stories | |
| 14 | CSV import: duplicate handling, default role, send invitations automatically? | Import | |
| 15 | Retention: what happens after 24 months of inactivity (delete, anonymise)? | Settings, privacy | |
