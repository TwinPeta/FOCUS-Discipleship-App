# FCU app, Prompt 3 of 3: build screens 43-61, finish wiring, final QA

Prompts 1 and 2 are finished. This prompt builds the last **19 screens**, which mostly *read* the state created earlier (profiles, notifications, settings, meetings, system states), then clears every remaining placeholder and runs end-to-end QA on all 61 screens.

**The existing code is the source of truth.** Reuse its theme, `core/widgets` (including `BottomSheetScaffold`, `CelebrationScreen`, `ConfirmDialog`, `ReportFlow`, `Skeleton`, `ErrorView`, `EmptyState`, `OfflineBanner`), roles, guard chain, `NotificationRepository`, `Warning`/`Report` records, debug scenario registry and `PlaceholderScreen`. Do not re-read earlier briefs. Rules unchanged: no new packages without asking, fake repositories behind interfaces, `flutter analyze` clean, soft style (no hard shadows), small commits.

## 0. Working method (keep token use low)
1. Read `lib/`, `docs/progress.md` and **`docs/wiring.md`** once. Don't print large files back.
2. Add a "Prompt 3" section to `docs/progress.md` (checklist below) and resume from it.
3. Reply with a **plan of 12 lines or fewer** plus blocking questions, then wait for "go". Then run batches 1-6 in order without stopping unless blocked.
4. After each batch: analyze, tests, commit, report in **3 lines max**. No code in chat.
5. Unspecified details: choose the simplest option consistent with the code and record it under "Assumptions" in `docs/progress.md`.
6. Every remaining row of `docs/wiring.md` must be replaced by its real screen and deleted. **The file must be empty at the end.**

## 1. Batches

### Batch 1: People and messaging (screens 43, 54, 55, 58)
- **43 Member profile** (`/members/:id`): back, round amber/white "message" button; avatar, name, @username, role badge + **Verified** pill for mentors/super-mentors; **About** (bio); chips: institution and community; **Badges** (earned only; activity history is never shown to others). Actions: amber **Message**, outlined **Report** (-> user `ReportFlow`), outlined **Block** (confirm dialog, block, pop, snackbar with Undo). No Message/Block on your own profile. **Message** respects `MessageRepository.canMessage` (under-18 rule): disabled with the explanatory text when false.
- **54 New message** (`/messages/new`): back, "New message", search field "Search a member", sections **Your mentors** (SM/M rows with role) and **Members of {community}** (name + @username). Tap opens or creates the thread. Blocked users excluded; search filters both sections; rows that fail `canMessage` are disabled with a note. This **replaces** the old bottom sheet: delete the sheet code.
- **55 Blocked users** (`/settings/blocked`): "Blocked people cannot message you." Rows: avatar, name, @username, **Unblock**. Empty state when none. Blocking/unblocking is enforced in repositories and updates feeds, comments and inbox everywhere.
- **58 No messages yet**: empty inbox state "No messages yet" / "Say hello to a mentor or a member of your community." amber **Find a member** -> `/messages/new`.

### Batch 2: Notifications (screens 44, 45)
- **44 Notifications** (`/notifications`): back (-> hub), "Notifications", settings button (-> 45). Sections **New** (with **Mark all as read**) and **Earlier**; rows: icon tile, text, time ("Today · 9:15", "Yesterday", "Mon"), unread dot. Tap marks read and opens the target: request approved/declined -> 27/28; prayer response or "prayed for your request" -> prayer request; announcement -> General feed; meeting reminder -> Meetings; inactivity ("We missed you...") -> feed; moderator warning -> 61. Bell unread dot reflects the repository. Empty state.
- **45 Notification settings** (`/notifications/settings`): "Choose what you hear about." **Channels**: In-app (on), Email (on). **Notify me about**: Join request updates, Replies and comments, Prayer responses, Announcements, Meeting reminders (all on), Inactivity reminders (off). Amber switches, persisted via repository. A muted type must stop **new** records from being created for that user. Push delivery is out of scope; structure the code so it can be added.

### Batch 3: Prayer and testimony detail (screens 52, 53)
- **52 Prayer request** (`/prayer/:id`): author (or **Anonymous**), time + community, body, amber **I prayed** (existing once-only logic, "[8] people prayed"), **Responses** list, pinned input "Write an encouraging response" + send. The anonymous author stays anonymous everywhere, including notifications and responses.
- **53 Testimony** (`/testimony/:id`): header "Testimony" with **Reviewed** badge, title, "{name} · {university}", full text, **Encouraged** toggle button, outlined **Report** -> `ReportFlow` (target = testimony). Only `reviewed` stories open for others; pending only for the author.

### Batch 4: Settings, privacy, help, meetings (screens 46-51)
- **46 Settings** (`/settings`): back (-> profile). Top card (avatar, name, "@username · {university}") -> Edit profile. Rows (leading icon tile, title, subtitle, chevron): Edit profile ("Photo, name, phone"), Notifications ("In-app and email"), Language ("English"; one language for now), Privacy & data ("Download or delete my data"), Help & FAQ ("Answers and contact"). Outlined **Sign out** (confirm; clears the session -> `/login`) and "Version [1.0]". Long-pressing the version row opens the debug registry (`kDebugMode`).
- **47 Edit profile** (`/settings/profile`): avatar + **Change photo**; Full name, Username (uniqueness check), Phone, institution picker (same widget as the Join form); email read-only: "Email: {email} · cannot be changed here." **Save changes**, disabled until something changed and is valid.
- **48 Privacy & data** (`/settings/privacy`): "You control your information." Rows: **Download my data** ("Get a copy of your information"; fake repository, then "We will email you a copy"), My activity & badges (-> `/activity`), Blocked users (-> 55). Note: "Only you can see your activity history. Your data is kept for [24 months] after your last activity." Outlined destructive **Delete my account**.
- **49 Delete account** (`BottomSheetScaffold`, like 29): "Delete your account?" / "Your profile, posts and messages are deleted within [30 days]." / "You leave all communities. This cannot be undone." Password field "Enter your password to confirm". Amber **Keep my account**; outlined **Delete my account**, disabled until a password is entered; a wrong password shows an inline error. Success clears all data and session -> `/login`.
- **50 Help & FAQ** (`/help`): accordion list, first item open: "Why can I join only one specific community?" ("A smaller group lets mentors know you well. You stay in your general campus community, and you can change by leaving your specific one first."), "How do I join a specific community?", "How do I report a post or a person?", "How do I change my photo?". Footer "Still need help? Write to the support team." (copy the support email to the clipboard; ask before adding `url_launcher`). This is the target of `ErrorView`'s **Contact support**.
- **51 Meetings** (`/community/:id/meetings`): back (-> Info), "Meetings" / community name. **Next meeting** card (day/time, room) with **I am going** (RSVP toggle) and **Add to calendar** (stub; ask before adding a calendar package). **At the meeting?** card: "Confirm you are here. Your attendance is recorded in your activity." **I am here** is enabled only from 30 minutes before to 2 hours after the start (assumption, configurable); one check-in per meeting; records an `ActivityEvent`; clock injected so it is testable. **Past meetings** list with Attended / Missed.

### Batch 5: System states and enforcement (screens 56, 57, 59, 60, 61)
The reusable widgets already exist from prompt 1; this batch applies them everywhere and builds the enforcement screens.
- **57 Loading**, **59 Error**: audit **every** async screen (all 61) and confirm it shows `Skeleton` while loading and `ErrorView` on failure, with **Try again** re-running the failed call. Fix any that don't.
- **56 Offline**: when offline, show `OfflineBanner` on community and feed screens, show cached content marked "[saved]", tip "Turn on Data saver to use less data on slow connections.", and **disable (not hide)** composer, Post, comment, send and "I prayed" with an explanatory state. Cache the last feed and prayer wall in memory. Debug scenario "Go offline".
- **61 Moderator warning** (`/warning/:id`, full screen): "A moderator sent you a warning" / "Reason: {reason}. This message was hidden:" + preview. **I understand** (marks acknowledged, continues to the app); **Read the charter** -> `/charter`. Register as the **unacknowledged warning** guard (shown before anything else except suspension).
- **60 Account suspended** (`/suspended`, full screen, blocks everything): "Your account is suspended" / "Reason: {reason}. Until {date}." / "You can read the community charter or write to the support team if you think this is a mistake." **Read the charter**, **Sign out**. Register as the **suspended** guard (first in the chain); when `until` passes, the guard releases automatically. Suspension is set by admins only (fake flag; debug scenario).
- Final guard chain order: suspended -> unacknowledged warning -> signed out -> onboarding incomplete -> membership. Cover it with tests.

### Batch 6: Final wiring and QA across all 61 screens
- `docs/wiring.md` empty; no `PlaceholderScreen` left except none (remove the widget if unused).
- Walk every link in the design: landing -> sign-up -> hub -> request -> approved -> feed -> every tab -> post, prayer, testimony, pathway, resource viewers -> messages -> report/block -> settings -> privacy -> delete. No dead ends, correct Back behavior everywhere.
- **Integration tests** (`integration_test` is SDK-provided; ask before adding anything else) for these journeys: (1) sign up an adult through consent to the hub; (2) sign up a minor -> guardian -> messaging restricted -> guardian confirms; (3) request a community -> approved -> post in the feed -> like -> comment; (4) complete a pathway step through a quiz -> badge earned; (5) report a post -> super-mentor warns the author -> author sees the warning; (6) block a member -> thread and posts disappear; (7) delete account.
- Re-run the Prompt 1 verification on the full app: three screen sizes (320x568, 390x844, 430x932), text scale 1.3 and 2.0, profile-mode scroll on feed and messages, offline start, goldens updated.
- Release-readiness check, report only (no changes unless P0): list of debug-only code paths and confirm each is guarded by `kDebugMode`; no PII/password logging; app name/icon/splash status; anything fake that must become a real backend call, grouped by repository (this becomes my backend to-do list).

## 2. Quality bar
- No duplicated widgets; everything repeated lives in `core/widgets`. No magic numbers.
- Every async screen: loading, empty, error, offline. Every form: validation, disabled-until-valid, no double submit.
- Privacy rules enforced in the data layer: anonymity, blocking, private activity, private reflections, reviewed-only testimonies, under-18 messaging limit, muted notification types.
- Text scales to 1.3x without overflow; 44px targets; semantic labels on icon-only buttons.
- Tests (focused): block/unblock effects; notification read/mute behavior; anonymous prayer responses; attendance window with an injected clock; delete-account password check; guard chain order; offline disabling of actions.
- Finish with `flutter analyze` zero, all tests green, `docs/wiring.md` empty, and `docs/progress.md` showing all 61 screens done with assumptions listed.
