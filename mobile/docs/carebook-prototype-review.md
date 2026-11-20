# Carebook prototype review (2026-11-20)

Source: `mobile/carebook-mobile-prototype-1.html` (79 screens, plain HTML).
It replaces `mobile/FCU Student  Review.html` as the design to match.
Status per item: `[ ]` to do, `[x]` done, `[?]` needs a decision first.

---

## Part A: changes that touch every screen (do these first)

### A1. New colour palette (biggest change)

The app is honey/amber with black text today. The prototype is **cream page, navy text,
gold buttons, blue for "selected" and links**. Values taken from the prototype:

| Role | Prototype (light) | App today (light) |
|---|---|---|
| Page background | `#FFFAF2`, with a top fade `#FFF1D4 → #FFFAF2` (at 34%) | `page #FFFBEA` |
| Card / sheet | `#FFFFFF` | `white #FFFFFF` (same) |
| Main text and icons | **navy `#1F2D3D`** | `ink #111111` |
| Muted text | `#5B6B7D`, `#6B7C90` | `inkDeemphasized85/80` |
| Input / card border | `#CFE0F3` (light blue) | `inputBorder #E6D48A` (gold) |
| Soft blue fill (info banners, icon tiles) | `#E3F0FD` | none |
| Blue chip / avatar / icon tile | gradient `#E8F2FD → #CFE3F8` | none |
| **Primary blue** (selected tab or chip, links, progress bars, active nav, checkboxes) | `#1E6AB8` | none (amberDark today) |
| Blue gradient (selected chip, active nav pill, "18 or older", Quiz result, Join done 2nd button) | `#1E6AB8 → #2A74C0 → #4C98E6` | none |
| **Gold CTA gradient** (primary buttons, + Create button, Next meeting card, General caregroup card) | `#FFCB3D → #F4B400 → #EE9A00` | `#F5CE3E → #E5A90A` |
| Gold accent (flat) | `#F4B400` | `amber #F5CE3E` |
| Soft gold card (notices, mentor avatar, "Still need help?") | `#FFF0B8 → #FDE68A` | `cream / honey` |
| Hub and profile header | `#FFEDB0 → #FFD25E → #F5B72E` | brand gradient |
| Sub-page header (Settings, Help, Messages, Meetings…) | `#C9E0F9 → #E6F1FC → #FFE9A8` (blue to soft yellow) | amber header |
| Celebration (Badge, Join done, You are in!) | `#FFE9A8 → #FFD25E → #F4B400` | brand gradient |
| XP star / small orange | `#FFB36B` | none |
| Skeleton | `#EEEDE8` | same |
| Placeholder | `#6A6A6A` | same |
| Text on gold buttons | navy `#1F2D3D` | ink |

- [ ] Add blue roles to `AppPalette` (`primary`, `primaryGradient`, `blueSoft`, `blueChip`, `border`, `muted`) and retune the gold roles to the new values.
- [ ] Change `ink` to `#1F2D3D` and `inputBorder` to `#CFE0F3`.
- [ ] New gradients in `AppGradients`: `cta` (gold), `primary` (blue), `chip` (blue soft), `goldSoft`, `hubHeader`, `pageHeader` (blue→yellow), `celebration`, `pageFade`.
- [ ] **Dark theme:** the prototype only shows light. We need dark values for every new role (a navy-black page, slightly lighter cards, a lighter blue `#4C98E6`-ish for selected states and links so they stay readable, and the same gold CTA a bit deeper). Render every screen in light and dark, as before.
- [ ] Remove literal colours left on screens while doing this.

### A2. New font
- [ ] The prototype uses **Source Sans 3** (400–900). The app bundles Bricolage Grotesque. Bundle Source Sans 3 (OFL) in `assets/fonts`, update `AppFonts.family` and pubspec. Headings in the prototype are 800–900, so ship the 800 and 900 weights too.

### A3. New names in the text
- [?] **"Community" becomes "Caregroup"** everywhere the user can see it (about 260 strings in `lib/features`). Examples: "Caregroups" tab, "General caregroup", "Join caregroup", "Leave caregroup", "Caregroup charter", "Search posts, people, caregroups".
- [?] The page title says **"Carebook"**. The screens still show "FCU · Fellowship of Christian Unions". Is the app name (launcher label, `title: 'FCU'`) changing to Carebook, or only "communities" to "caregroups"?
- [ ] "University or Institute" becomes **"campus"** in the text ("Your campus", "Which campus are you on?").
- [ ] Back office and API wording should follow (labels only; route and table names can stay `community`).

### A4. Shared widgets
- [ ] **Bottom nav:** white floating bar (radius 30, shadow). The active tab is a blue-gradient pill around the icon with the label under it. The centre **+** is a raised gold-gradient square button. Tabs: Home · Caregroups · + · Messages · Profile.
- [ ] **Caregroup header** (feed, prayer wall, testimonies, resources, pathways, info): white bar with the name, "[12] online · Tue 5:00 PM", and three round soft-blue buttons: **theme toggle (sun)**, search, bell with a gold dot. The theme toggle in the header is new.
- [ ] **Section tabs:** white pills with a light-blue border. The selected one is a blue gradient with white text (today it's amber).
- [ ] **Sub-page header** (Settings, Help, Messages, Meetings, Activity, Privacy, Manage, New members, Reports, Notifications, Member profile, Quiz): back arrow, large navy 900-weight title, and a subtitle on the blue-to-yellow gradient, which fades into the cream page.
- [ ] **Buttons:** primary = gold gradient, navy text, radius about 14. Secondary = white with a 2px navy border. Tertiary = blue underlined link.
- [ ] **Info banner:** soft blue `#E3F0FD` with a blue "i" icon (today it's cream/amber).
- [ ] **Icon tiles in list rows:** a rounded square with the blue chip gradient and a blue icon (Settings, Privacy, Create menu, Search, Manage).
- [ ] **Avatars:** initials on the blue chip gradient. The super-mentor gets a gold gradient and the mentor soft gold. Online dot is gold.
- [ ] **Role badges:** "Super-mentor" on gold, "Mentor" on soft gold, "Member" and "General caregroup" on soft blue.
- [ ] **Counters** (unread, Manage counts): gold circle with navy number.
- [ ] **Inputs:** white, 1.5px `#CFE0F3` border, radius 12–14, leading icon in muted navy.
- [ ] **Bottom sheets** (Leave, Delete account, Delete testimony, Create menu, Post options): white sheet, small blue grab handle, ✓ list of consequences, gold primary and outlined secondary buttons.

---

## Part B: screen by screen

Legend: **C** = colour/style only · **W** = wording · **F** = how it works (behaviour or data).

### Onboarding and sign-in

**1 · Landing** — C, W
- [ ] Gold hero `#FFEFB8 → #FFD25E → #F4B400` with a blue circle in the top right. "Grow. Succeed." is in blue `#1E6AB8`.
- [ ] Buttons: "Explore caregroups →" (white pill), "▶ Watch student stories" (blue link), Sign in (white pill, top right).
- [ ] Phone preview mock shows "General caregroup" with gold/blue bars.
- [ ] Copy: "Join in 3 steps": 1 Create your profile, 2 Enter your campus, 3 Pick one specific caregroup. "General / Specific" cards. Final call to action: "Ready to meet your people?" with "Changing Students, Transforming Societies."

**2 · Join: name and email (Step 1 of 5)** — F, C, W (new flow)
- [ ] **The sign-up is now a 5-step wizard with points (XP)** instead of one long form:
  1. Name + email (0 XP) → 2. Campus + year (10 XP) → 3. Password (20 XP) → 4. Age + charter, or guardian if under 18 (30 XP) → 5. Verify email (40 XP) → **Done: badge "Newcomer", +50 XP · Level 1**.
- [ ] Each step has: a back button, a blue progress bar, an XP pill (gold, star) top right, "STEP n OF 5" in blue caps, a **smiley mascot + speech-bubble card** with the title and subtitle, the fields, then "+10 XP when you continue" above a gold **Next →** button.
- [ ] Step 1 asks only Full name + Email ("Only the basics now. You can add the rest later and earn points.").
- [ ] Replaces `/join/start` "Before you start" and the sectioned `join_form_screen` (username, birthdate, country, phone and church move to Profile tasks, see below).

**2b · Join: campus and year (Step 2)** — F
- [ ] Campus dropdown "Select your campus" plus **year chips**: 1st, 2nd, 3rd, 4th, 5th year +, Postgraduate (selected = blue gradient).
- [?] No "University / Institute" switch and no "type in an unlisted institute" option in the prototype. Keep ours?

**2c · Join: password (Step 3)** — F, C
- [ ] "Lock it with a password". Hint "At least 10 characters". **3-bar strength meter** in blue, a message ("Good one! Almost a strong password") and a checklist (At least 10 characters, A letter and a number).
- [?] We currently require 8+ characters? Check the API rule and match it to 10.

**2d · Join: age and charter (Step 4)** — F
- [ ] "How old are you?" with two buttons, **18 or older / Under 18**, instead of a birthdate. Under 18 goes to 2f.
- [ ] Charter card with "Read the full charter" plus two required checkboxes (blue). The **optional "a mentor may contact me" box is gone**.
- [ ] Button "Create my account →" (the account is created here, before verify).

**2f · Join: guardian (Step 4, under 18)** — W, C
- [ ] Fields: Guardian full name, Guardian email, Relationship. Note "We email them a link to confirm. You can browse meanwhile." Button "Send request →".

**2e · Join: verify email (Step 5)** — C
- [ ] 6 boxes for the code (blue border). "Did not get it? Send a new code" (blue link). "Verify and finish →".
- [?] Our resend countdown ring isn't in the prototype. Keep it.

**2g · Join: done (badge)** — F, new screen
- [ ] Celebration: gold gradient, confetti, white star circle, blue pill "BADGE UNLOCKED: NEWCOMER", "You are all set, [Name]!", "+50 XP · Level 1" card, outlined blue "Complete my profile" and blue-gradient "Not now, join my campus".

**Profile task hub · Complete your profile** — F, new screen
- [ ] Gold header with a 40% ring, "Earn up to +60 XP". "To do": Add a photo (+20), About you (+20), Contact (+10), Local church (+10). "Done": Name and email, Campus and year (blue ticks). Footer: "Finish everything to unlock the Profile pro badge."
- [ ] Replaces our "Complete your profile" pop-up. It's opened from a "Complete your profile · Earn +60 XP and a badge" card on Home and My profile.

**Profile task: photo / about you / contact / local church** — F, new screens
- [ ] Same wizard look, with "Profile 60%" in place of the XP pill and a "PROFILE TASK" label.
- [ ] Photo: dashed blue circle with a camera and a gold +, "Take a photo" / "Choose from gallery". About you: Username, Birthdate ("We use it to keep the caregroup safe for students under 18"), Country. Contact: Phone ("never shown to other members"). Church: search dropdown, "Not in the list? Type its name", checkbox "I do not attend a local church yet", and the note "Only your caregroup leaders see it".

**25 · Sign in** — C, W
- [ ] Blue-to-yellow header with the FCU logo, "Welcome back", "Sign in to see your caregroups.". Blue links "Forgot password?" and "Explore caregroups". Gold "Sign in" at the bottom.

**26 · Forgot password** — C, W
- [?] The prototype says "**we will send you a link**" ("Send reset link"). We built a two-step code screen. Keep the code flow and change only the colours?

**23 consent / 24 guardian (old numbers)** — merged into 2d and 2f above.

### Caregroups (communities)

**3 · Caregroups hub** — C, W
- [ ] Gold header: "WELCOME, [FIRST NAME]", the campus name as the large title (the prototype brings back the **campus name**; we had removed the university name), "Two ways to belong: the whole campus, and a smaller group with mentors.", bell and avatar in white circles.
- [ ] "My caregroups": a **gold General card** ("Joined · Open") and a **dashed "Specific caregroup" card** ("Only 1 allowed · Pick below").
- [ ] "Find a specific caregroup", a blue info banner ("You can join **only one**…"), search "Search by name, day or place", and caregroup cards (initials tile, super-mentor, blue day/time chip, room chip, chevron).
- [?] The prototype hub has no chat icon next to the bell (we added one). Keep it?

**3b · Hub after joining** — C, F
- [ ] The specific card becomes soft gold "Growth Circle · Joined". "Other specific caregroups": the other caregroups are greyed out with a lock. The banner says "You joined Growth Circle. Other caregroups are locked unless you leave it.". A gold "Open my caregroup" button sits at the bottom.

**4 · Caregroup detail** — F, C
- [ ] **Join is instant**: "Join caregroup", with "You join instantly and can leave at any time." There's **no request or approval step**.
- [ ] Gold art header with a white name card. About, In-person meeting (two soft-blue rows: day/time and place), Leadership.
- [?] This drops the join-request approval (and the back-office `autoApprove` setting). Confirm the product wants instant join only.

**27 · Joined ("You are in!")** — C, W: replaces "request approved". Celebration gold, meeting card, "Open my caregroup", "Say hello to my mentor".
**28 · Already in a caregroup ("You can only be in one")** — F, W: replaces "request declined". Buttons "Leave Growth Circle" and "Go to my caregroup".
**29 · Leave caregroup** — C, W: sheet "Leave Growth Circle?" with a ✓ list. "Stay in Growth Circle" (gold) and "Leave caregroup" (outlined).

**5 · Caregroup feed** — C
- [ ] New header (A4). Tabs: General · Growth Circle · Prayer wall · Testimonies · Pathways · Resources · Meetings · Info & members.
- [ ] Share row: avatar + "What do you want to share?".
- [ ] **Gold "NEXT MEETING" card** with a calendar icon and a chevron.
- [ ] Post cards: soft-blue like/comment pills with counts, plus share and bookmark icons. Question cards get a gold "✎ Answer" button and "[5] answers".
- [?] Our share row also has question and prayer shortcuts. The prototype shows only the input.

**6 · Info, members & chat** — C, F
- [ ] "Caregroup info" card: description, blue chips (Every Tuesday · 5:00 PM, room), blue links "View meetings" and "Leave caregroup".
- [ ] "Online now": avatar row with gold dots, "+8", and "12 online".
- [ ] Members list with a **gold message button** on each row.

**8 · Home (General caregroup)** — C, F
- [ ] Header "General caregroup · [Your campus] · [34] online", with search and bell (no theme toggle here). Tabs: General · Growth Circle · Prayer wall · Testimonies · **Learn**.
- [ ] **"Complete your profile · Earn +60 XP and a badge"** card with a 40% ring (opens the profile task hub).
- [ ] "Campus team · Announcement" post card style.

**14 · Prayer wall** — C, F
- [ ] Title "Prayer wall" with a gold "+ Share a request" button.
- [ ] Each card: gold "♡ I prayed", outlined "Respond", "[8] prayed". Anonymous shows a "?" avatar.
- [?] The prototype has no Search or "⋯" sections menu on the prayer wall (we added them). Keep them.

**16 · Testimonies** — C
- [ ] Blue banner "Your story is awaiting review by the moderators. **Delete**".
- [ ] Gold "+ Share your story". The video card has a gold thumbnail, a play button and a [2:10] pill. Story cards have a "✓ Reviewed" chip and a blue "Read story" link.

**18 · Pathways** — C: "My current pathway" card (blue), "All pathways" list with In progress / Start / locked rows.
**19 · Pathway steps** — C: step list with gold done/current markers and a "Continue" button on the current step.
**7 · Resources** — C, F
- [ ] Filter chips All / Videos / Devotionals / Quizzes / Documents (selected = blue).
- [?] The prototype **brings back the "Bible characters" (gold) and "Bible texts" (soft gold) boxes**. We removed them on 2026-11-17. Bring them back?
- [ ] "Latest" rows: blue icon tile, small caps type label (VIDEO, DEVOTIONAL…), and a gold "Start" button on quizzes.
**51 · Meetings** — C, F
- [ ] Gold "NEXT MEETING" card with **"I am going"** and **"Add to calendar"** (white buttons). "At the meeting?" card with "I am here" (check-in). Past meetings with Attended/Missed chips.
- [?] Do we have the "I am going" (RSVP) and "Add to calendar" features? Check the API.

### Super-mentor

**30 · Manage** — C, W: "Manage Growth Circle · Only super-mentors see this." Rows with blue icon tiles and gold counters: New members, Reports to review, Testimonies, **Members to follow up (No activity for 14+ days)**, Meeting details. Blue note "Cover photos and caregroup creation are managed by the admin team."
- [?] "Members to follow up" is new. Does the API have a last-activity query?
**31 · New members** — F: instead of approving requests: "**Say hello** / **Remove**" per new member, plus a "Moved from Life & Faith Circle" notice. This goes with instant join (screen 4).
**32 · Reports** — C: the open report is a gold card with a "Level 1" chip and four buttons (Hide in gold, then Warn author, Keep, Escalate to admin).
**Testimony (super-mentor view)** + **Delete testimony (super-mentor)** — F: "Delete testimony" with an optional reason. "The author is told why… The action is saved in the audit log."

### Create

**66 · Create menu** — C: sheet with 5 rows (blue icon tiles): Ask a question, Answer a question, Write a post, Prayer request, Share a story, and Cancel.
**Create · Post / Question / Prayer / Story** — C, W
- [ ] Top bar: ✕ "Create" with a gold action button (Post / Ask / Post / **Submit**). Type chips Post · Question · Prayer · Story (selected = blue gradient). Author row with a blue "General caregroup ▾" target chip.
- [ ] Post: toolbar photo / video / document / emoji (the emoji button turns gold), an emoji grid, "1 photo", and a gold photo preview with ✕.
- [?] The composer toolbar shows **video and document** for posts. Today we allow a photo only.
- [ ] Question: "Tips for a good question" box and "Ask anonymously". Prayer: "Post anonymously" and the blue note "Your caregroup will be able to pray and respond.". Story: Title, Your story, Photo / Video (blue soft buttons), consent checkbox, blue moderation note.
**65 · Write an answer** — C: ✕ Answer + gold Post, the question on top, a photo button, "Be kind and helpful".
**67 · Questions for you** — C: chips All / General / Growth Circle (prototype chips, not our "⋯" menu), and a gold Answer + outlined Pass on each card.
**64 · Question & answers** — C, F: gold "Answer" and outlined "🔔 Follow". A "Mentor" chip on mentor answers, which are shown first. Like/comment pills.

### Posts, prayer, testimony

**39 · Post & comments** — C: post header, like/comment pills, comment list, and a "Write a comment" bar with a send button.
**40 · Post options** — C: sheet with Report post, Hide this post, Copy link, Cancel.
**52 · Prayer request** — C: "♡ I prayed · [8] people prayed", Responses, "Write an encouraging response".
**53 · Testimony** — C: gold art header, "Testimony" and "Reviewed" chips, gold "♡ Encouraged" and outlined "Report". Owner section "Your story: Edit / Delete".
**Delete testimony** (own) — C, W.

### Learning

**33 · Video** — C, F: the player has a "Quality: Auto / **Data saver**" toggle, a "Next in pathway" card and "Mark as complete".
**34 · Devotional** — C: "To think about" soft-gold card and a "Your reflection (only you see this)" input. "Mark as read".
**35 · Quiz** — C: blue-to-yellow header, gold progress bar, answer rows (the selected row is a soft gold fill with a navy border), gold "Check answer".
**36 · Quiz result** — C: **blue gradient** top with a white score circle, "Well done!", a "New badge" row, "Review my answers", "Back to resources".
**37 · Document** — C: page preview, "Download", "Mark as done".
**38 · Badge earned** — C: celebration gold.

### Messages

**9 · Inbox** — C, F
- [ ] Blue-to-yellow header "Messages" with a ✎ new-message button and a white search field.
- [ ] Filter chips **All / Mentors / Members** shown as chips (we moved them into "⋯" and added Unread).
- [ ] Rows: role chip under the name (Super-mentor gold, Mentor soft gold, Member/General caregroup soft blue), gold unread counter, gold presence dot.
**10 · Conversation** — C: gold-gradient bubbles for my messages, white for theirs, a "Today" divider, and a gold send button.
**54 · New message** — C: "Your mentors" then "Members of Growth Circle".
**58 · No messages yet** — C: soft-gold icon and "Find a member".
**11 · Report a user / 12 Report sent / 41 Report content / 42 Report sent (content)** — C: radio rows with a blue border, soft-gold selected state, optional details, "Screenshot of the chat · Upload", gold "Send report". (Keep our "no default reason" decision.)

### Profile and settings

**2b · My profile** — C, F
- [ ] Gold header: back arrow, "My profile", **theme toggle (sun)** and an edit pencil in white circles, a large initials photo with a camera badge, "[Full name]" and "@username".
- [ ] "Complete your profile" card. A details list: Email, Phone, **Country**, Campus, Year, Local church. "My caregroups" rows. "My activity & badges" row.
**47 · Edit profile** — W: fields Full name, Username, Phone, Campus, Local church, Year. "Email … cannot be changed here".
**20 · My activity & badges** — C: blue privacy note, badge circles (gold earned, dashed grey locked), recent activity rows with blue icon tiles.
**43 · Member profile** — C, F: blue-to-yellow header, "Mentor" and "Verified" chips, About with campus and caregroup chips, Badges. Gold "Message", outlined "Report" and "Block".
**46 · Settings** — C, F
- [ ] Rows: profile card, Edit profile, Notifications, **Language (English)**, Privacy & data, Help & FAQ. "Sign out" and "Version [1.0]".
- [?] **Language** is new. Is it only English for now (a row that shows "English")?
- [ ] Keep our "App updates" row (it isn't in the prototype, but we shipped it in beta.3).
**45 · Notification settings** — C: Channels (In-app, Email) and topics including **Meeting reminders** and **Inactivity reminders**.
**44 · Notifications** — C: "New" (soft-gold rows) and "Earlier", with "Mark all as read".
**48 · Privacy & data** — C: Download my data, My activity & badges, Blocked users, the 24-month note, "Delete my account".
**49 · Delete account** — C, W: sheet with password, gold "Keep my account" and outlined "Delete my account".
**55 · Blocked users** — C. **50 · Help & FAQ** — C, W: the first question is "Why can I join only one specific caregroup?", plus the soft-gold "Still need help?" card.
**62 · Search** — C: Recent, Caregroups, People rows with blue icon tiles.

### System states

**56 · Offline** — C: "You are offline · Showing saved content. Posting is paused.", Retry, a Data saver tip.
**57 · Loading** — C: skeletons on the blue-to-yellow header and the cream page.
**59 · Error** — C. **60 · Account suspended** — C: blue-to-yellow screen, "Read the charter" (gold), "Sign out". **61 · Moderator warning** — C.

---

## Part C: decisions needed before building

1. Rename "Community" to "Caregroup" everywhere (app + back office text)? Is the app name changing to "Carebook"?
2. Sign-up as a 5-step wizard with **XP points, levels and badges** (Newcomer, Profile pro). Points need API support (store XP and level per user). Build it for real, or show the steps without points first?
3. Username, birthdate, country, phone and church move out of sign-up into optional profile tasks. Age becomes "18 or older / Under 18". OK?
4. **Instant join** for specific caregroups, with no approval (super-mentor gets "New members: Say hello / Remove"). Remove the request flow and `autoApprove`?
5. Bring back the Bible characters / Bible texts boxes on Resources?
6. Keep our extras that aren't in the prototype: chat icon on the hub, prayer wall Search + "⋯", Unread inbox filter, reset code (not link), resend countdown, App updates row.
7. New features that need the API: meeting RSVP + Add to calendar, Members to follow up (14+ days), Language setting, video/document in posts, Data saver video quality, Follow a question.

## Part D: suggested order of work

1. A1 palette + A2 font + A4 shared widgets (one change; most screens update by themselves). Render light and dark.
2. A3 wording (after decision 1).
3. Hub, feed, Home and nav (most-seen screens).
4. New sign-up wizard + profile tasks (after decisions 2–3).
5. Caregroup join changes (after decision 4).
6. Remaining screens in the order of Part B; small colour checks only.
