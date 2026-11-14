# FCU app, Prompt 2 of 3: build screens 21-42

Prompt 1 (audit, small changes, foundations) is finished. This prompt builds **22 screens** that *create* app state: accounts, membership results, learning progress, content reports and moderation. **Do not build screens 43-61** (prompt 3).

**The existing code is the source of truth.** Reuse its theme, `core/widgets`, router, repositories, `Skeleton`/`ErrorView`/`EmptyState`/`OfflineBanner`, roles, guard chain, debug scenario registry and `PlaceholderScreen`. Do not re-read earlier briefs. Rules unchanged: no new packages without asking, fake repositories behind interfaces, `flutter analyze` clean, soft style (no hard shadows), small commits.

## 0. Working method (keep token use low)
1. Read `lib/`, `docs/progress.md` and **`docs/wiring.md`** once. Don't print large files back.
2. Add a "Prompt 2" section to `docs/progress.md` (checklist below) and resume from it.
3. Reply with a **plan of 12 lines or fewer** plus blocking questions, then wait for "go". Then run batches 1-5 in order without stopping unless blocked.
4. After each batch: analyze, tests, commit, report in **3 lines max**. No code in chat.
5. Unspecified details: choose the simplest option consistent with the code and record it under "Assumptions" in `docs/progress.md`.
6. **Wiring ledger:** every row of `docs/wiring.md` marked "resolved in 2" must be replaced by its real screen and deleted from the file. Rows for prompt 3 stay on `PlaceholderScreen(owner: 3)`.

## 1. Overrides to earlier behavior
- The Join form no longer creates the account. Flow: `/join` (Step 1 of 3) -> `/join/password` (Step 2) -> `/join/verify` (Step 2) -> `/join/consent` (Step 3) -> [`/join/guardian` if under 18] -> hub. The account and profile are created **only** after charter acceptance. Remove the `TODO(prompt2)`.
- The debug link on the pending hub is removed; use the debug registry scenarios "Approve my request" / "Decline my request" instead.
- Remove the debug-only "Mark step complete" and "attended meeting" shortcuts; completion now happens through the real viewers.
- Report flow becomes **one generic `ReportFlow`** with a target type (user, post, comment, prayer, testimony). Refactor the existing user report (screens 11/12) and build the post-content skin (41/42) on it.
- The badge snackbar becomes the **Badge earned** screen (38).

## 2. New shared widgets (build first, reuse everywhere)
`BottomSheetScaffold` (white, radius 28 top corners, 44x5 `inputBorder` handle, 50% ink scrim), `CelebrationScreen` (centered 112px amber circle with icon, 34/w900 title, body, stacked buttons), `OtpField` (6 boxes), `PasswordField` (show/hide + live rule checklist), `ReportFlow` scaffold, `ConfirmDialog`.

## 3. Batches

### Batch 1: Sign-up, sign-in, recovery (screens 21-26)
`StepProgress` is reused. Keep input in a `SignUpController` so Back never loses data. **Passwords are never logged or kept in plain text in app state.** `AuthRepository` is a fake; the session lives in memory (ask before adding secure storage). Register the **signed-out** and **onboarding-incomplete** guards in the chain; Back to landing from login is allowed.
- **21 Secure your account** (`/join/password`, Step 2 of 3): "Secure your account" / "Choose a password for your account." Password (placeholder "At least 10 characters"), Repeat password, live checklist: "At least 10 characters", "A letter and a number", mismatch error. **Continue** -> verify.
- **22 Check your email** (`/join/verify`, Step 2 of 3): "We sent a 6-digit code to {email}." Six single-digit boxes: auto-advance, backspace moves back, pasting 6 digits fills all, numeric keyboard, autofill hint. "Did not get it?" + **Send a new code** (30s cooldown). **Verify email**. Max 5 attempts, then a 10-minute lock with a clear message. Fake code `123456` in debug.
- **23 Before you join** (`/join/consent`, Step 3 of 3): "Please read and accept to continue." **Community charter** card with placeholder rules and **Read the full charter** (-> read-only `/charter` page, reused by prompt 3). Three check rows: "I accept the community charter" (**required**), "I agree to take part in community spaces" (**required**), "I agree that a mentor may contact me" (optional). **Render all three unchecked** (the mockup shows them pre-ticked; consent must be an explicit action). If the user is under 18, show the row "Under 18? A parent or guardian must confirm." **Join my campus** is disabled until both required boxes are ticked; on press it creates the account + profile, joins the campus General community, and goes to the hub (or to the guardian screen if under 18).
- **24 Ask your guardian** (`/join/guardian`): "Because you are under 18, a parent or guardian needs to say yes." Fields: Guardian full name, Guardian email (valid and different from the user's own), Relationship. Note about the emailed link and the messaging limit. **Send request** -> hub with `GuardianRequest.status = pending`. Add scenario "Guardian confirms" in the debug registry.
- **Under-18 rule, enforced in `MessageRepository`, not only the UI:** until the guardian is confirmed, the user can browse but **cannot start or reply to conversations with adults** (mentors and super-mentors included). Expose `canMessage(target)` so UI can disable the composer with "Waiting for your guardian's confirmation". Put the rule behind one flag (I will confirm it with FCU's safeguarding policy).
- **25 Sign in** (`/login`): FCU logo block, "Welcome back" / "Sign in to see your communities.", Email, Password (show/hide), **Forgot password?**, amber **Sign in**, "New here?" + **Explore communities** -> `/join`. One generic error ("Email or password is incorrect") that never reveals which part is wrong.
- **26 Forgot password** (`/forgot-password`): back, "Enter your email and we will send you a link.", Email, spam note, **Send reset link**, **Back to sign in**. Show the **same** success message whether or not the email exists.

### Batch 2: Membership results and notification records (screens 27-29)
- **27 Request approved** (`/request/approved`, `CelebrationScreen`): "You are in!" / "Welcome to **{community}**. {super-mentor} approved your request." Two cream rows: meeting day/time and room. **Open my community** -> feed; **Say hello to my mentor** -> conversation with the super-mentor (respect `canMessage`).
- **28 Request declined** (`/request/declined`): "Request not accepted" / "The super-mentor could not add you to {community} this time. {optional message}" / "You can request another specific community. You are still part of your general campus community." **Choose another community** -> hub (status back to `none`); **Go to my campus** -> General feed.
- Show 27/28 **once**, when the status changes (next app open or from the notification), then mark `seen`. Debug scenarios "Approve my request", "Decline my request".
- **29 Leave community** (`BottomSheetScaffold` over the Info screen): "Leave {community}?" with three rows: "You lose access to its feed, prayer wall and resources." / "Your posts stay unless you delete them." / "You can then request another specific community. You can be in only one." Amber **Stay in {community}** (closes); outlined **Leave community** -> repository sets status `none`, hub, snackbar. Leaving is a legal transition approved -> none; the membership guard then redirects community routes.
- **Notification records only (no screen; the screen is prompt 3):** create `NotificationRepository` + `AppNotification(type, targetRoute, createdAt, readAt)`. Emit records for: request approved/declined, "prayed for your request", announcement (debug), meeting reminder (debug), inactivity (debug), moderator warning. Show the unread dot on the hub bell (the bell already exists from prompt 1).

### Batch 3: Learning content (screens 33-38) and pathway wiring
All viewers: back button to Resources (or to the pathway), a cream **Next in pathway** tile when opened from a pathway step, pinned primary action at the bottom.
- **33 Video** (`/resources/video/:id`): 230 high player (44px white round back button top-left, central 68px white play button with 2.5px ink border, bottom progress bar 8px with white track/amber fill and a white time chip "[2:10] / [8:00]"). Below: chips (Video honey, topic cream), title 28/w900, description, white **Quality** card with chips **Auto** / **Data saver** (data saver lowers quality and disables autoplay), Next-in-pathway tile, pinned amber **Mark as complete**. No video package: build a `PlaybackController` interface with a fake that simulates play/pause/progress (ask before adding `video_player`). Remember the resume position.
- **34 Devotional** (`/devotional/:id`): title; chips (Devotional, Bible reference, "[5 min read]"); two paragraphs; cream "To think about" card; **Your reflection** text area ("Write your thoughts (only you see this)"), saved privately through the repository; pinned **Mark as read**.
- **35 Quiz** (`/quiz/:id`): header with title, "Question 2 of 10", progress; question; four radio rows (selected = honey fill + 2px ink border); **Check answer** -> options show correct/incorrect with ink border plus check/cross icons (no red/green, they are not in the palette); **Next question**; the last one goes to the result. Back asks for confirmation (progress is lost).
- **36 Quiz result** (`/quiz/:id/result`): large "[8]/[10]" + "correct", "Well done!" / "You passed this quiz." Pass mark 70% (assumption; configurable); below it show "Not quite yet" + **Try again**. If a badge was earned: tappable card "New badge: {name}" -> 38. **Review my answers** (quiz in review mode), **Back to resources**.
- **37 Document** (`/document/:id`): title, "[PDF] · [2 MB]", viewer area with "Page 1 of [12]" (placeholder page; ask before adding a PDF package), **Download** (stub snackbar for now), pinned **Mark as done**.
- **38 Badge earned** (`/badge/:id/earned`, `CelebrationScreen`): "New badge", badge name, reason ("You finished [3] quizzes. Keep going!"). **See my badges** -> `/activity`; **Continue** -> previous screen. Queue several badges.
- **Wiring:** completing anything records an `ActivityEvent`, advances the pathway step (strictly sequential, unlocks the next, completes the pathway on the last step) and re-evaluates badges with the existing rules; Resources and pathway **Continue** open the correct viewer by step type.

### Batch 4: Post detail, content reports (screens 39-42)
- **39 Post & comments** (`/post/:id`): back, "..." (-> 40); author row (avatar + name tappable -> `/members/:id`, a prompt 3 placeholder; "{time} · {community}"), caption, optional photo, counts row (likes, comments), comments list (avatar, "name · time", text), pinned input "Write a comment" + send. Optimistic like and comment. Hide comments from blocked users. Disabled (not hidden) while offline.
- **40 Post options** (`BottomSheetScaffold`): **Report post** -> report; **Hide this post** (hidden for me, with Undo snackbar); **Copy link** (copy a placeholder deep link to the clipboard); **Cancel**. Authors also see **Delete post** (confirm).
- **41 Report content** (`ReportFlow`, target = post): "Report this post" / "You are reporting a post by **{name}**." / "What is wrong?" Same five reasons as the user report, optional details, **Send report** (disabled until a reason is chosen).
- **42 Report sent**: "Report sent" / "Thank you for helping keep the community safe. A moderator will review it." **Back to community**, **Hide this post**.
- Reports from comments, prayer requests and testimonies reuse the same flow and land in the same queue.

### Batch 5: Super-mentor tools (screens 30-32)
Only super-mentors of that community can reach these routes (guard + repository check).
- **30 Manage {community}** (`/community/:id/manage`, "Only super-mentors see this."): four tappable cards with live counters: **Join requests** ("Approve or decline students") -> 31; **Reports to review** ("Level 1 moderation") -> 32; **Members to follow up** ("No activity for 14+ days"; a list of members with a message button each, computed from activity events); **Meeting details** ("Tuesday · 5:00 PM · {room}"). Footer: "Cover photos and community creation are managed by the admin team."
- **31 Join requests**: "A student can be in only one specific community." Rows: initials, name, "@username · {institution}", date, amber **Approve**, outlined **Decline**. If the student is already in another specific community: note "Already in {community}" and **Approve** is disabled. Approve sets `approved` and creates the student's notification; Decline opens a dialog for an optional message, sets `declined` and notifies.
- **32 Reports to review**: "You can hide content and warn members. Admins handle suspensions." Cards: "{Post|Comment|Prayer request} by {name}", **Level 1** pill, "{date} · Reported by {reporter}", content preview, "[2] reports · {reason}", actions **Hide**, **Warn author**, **Keep**, **Escalate to admin**. Each action records an outcome and removes the case from the queue. **Hide** hides the content for everyone; **Warn author** creates a `Warning(reason, preview, acknowledged:false)` (the warning *screen* is prompt 3) and a notification; **Escalate** moves it to a fake admin queue.

## 4. New data (immutable, `copyWith`)
`Account`, `AuthSession`, `SignUpDraft`, `GuardianRequest(status)`, `Consent`, `JoinRequest(student, status, message?, seen)`, `AppNotification`, `QuizQuestion`, `QuizAttempt`, `Reflection`, `Comment`, `Report(targetType, targetId, reason, details?)`, `ModerationCase(level, reports, outcome)`, `Warning`.

## 5. Quality bar
- No duplicated sheet, dialog, header or button code; shared pieces live in `core/widgets`. Every async screen uses `Skeleton`, `ErrorView`, `EmptyState` and handles offline.
- Forms: validation, disabled-until-valid, no double submit, loading state on buttons, correct keyboard types and autofill hints, nothing hidden by the keyboard.
- Safety enforced in the data layer: under-18 messaging limit, same reset-link message for known/unknown emails, generic login error, password never logged, role checks in repositories.
- Text scales to 1.3x without overflow; 44px targets; semantic labels on icon-only buttons; no color-only meaning.
- Tests (focused): password rules and OTP behavior (attempts, lock, cooldown); consent requires the two boxes; under-18 branch and messaging restriction; guard order for signed-out/onboarding; approve/decline/leave transitions and one-time result screens; quiz scoring and pass mark; pathway sequencing and badge rules; report -> queue -> each outcome; only super-mentors reach 30-32.
- Finish: `flutter analyze` zero, tests green, every "resolved in 2" row cleared from `docs/wiring.md`, `docs/progress.md` updated (done, assumptions, stubs left).
