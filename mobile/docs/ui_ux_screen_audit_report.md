# FCU Student Community App — UI/UX \& Feature Completeness Audit Report

**Target app:** Flutter mobile app (`mobile/`)  
**Reference design:** [FCU Student Community App – Mobile Design.html](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/FCU%20Student%20Community%20App%20–%20Mobile%20Design.html)  
**Quality checks observed in this session:**

* `flutter analyze`: **No issues found** (ran in 14.3s)
* `flutter test --no-pub -r compact`: **237 / 237 tests passed** (includes golden regression tests for screens 1–5 in [screens\_golden\_test.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/test/golden/screens_golden_test.dart))
* [placeholder\_routes.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/core/router/placeholder_routes.dart): **0 placeholder routes remaining**
* [wiring.md](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/docs/wiring.md): **0 unwired items remaining**

\---

## Executive Summary

> \[!IMPORTANT]
> \*\*Scope of the HTML design file vs. the implemented app:\*\*  
> `FCU Student Community App – Mobile Design.html` contains \*\*22 artboards\*\* covering \*\*Screens 1–20 plus variants 2b and 3b\*\*. Screens \*\*21–61\*\* were added via Prompt 2 \& Prompt 3 specifications without visual artboards in that HTML file. Additionally, several parts of Screens 1–20 were intentionally revised by Prompt 2 \& Prompt 3 (e.g., multi-step sign-up, Settings/Notifications buttons, reporting flow, removing prototype shortcut links).

### Overall Verdict

1. **Route \& UI coverage:** All 61 screens and routes are implemented and wired in [app\_router.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/core/router/app_router.dart); no `PlaceholderScreen` routes remain active.
2. **Design system \& visual fidelity (Screens 1–20):** Core tokens ([AppColors](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/core/theme/app_colors.dart), [AppTextStyles](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/core/theme/app_text_styles.dart) using `Source Sans 3`, [AppShadows](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/core/theme/app_shadows.dart)) closely match the HTML mockups, including the "bold" (`2.5px` ink border + hard `4,4` shadow) landing style and the "soft" inner-app card style. However, there are **12 concrete visual/UX discrepancies** on Screens 1–20 + 2b + 3b (documented below).
3. **Partial implementations \& stubs (Screens 1–61):** All 21 repository providers in [repository\_providers.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/core/providers/repository_providers.dart) are in-memory `Fake\*` implementations. Beyond the persistence layer, **8 user-facing features are currently stubbed or partially implemented** (most notably multi-attachment post rendering, testimony video/photo persistence \& playback, document PDF rendering/download, calendar export, push notifications, and charter legal copy).

\---

## 1\. Visual \& UX Comparison: HTML Artboards (Screens 1–20, 2b, 3b) vs. Flutter App

### Summary Matrix

|#|Screen|Design File Match|Verdict|Notes|
|-|-|-|-|-|
|1|Landing|`01\_1\_Landing\_scrolls.html`|**Partial / Stubs**|Visuals match closely; extra `Sign in` pill (intentional Prompt 2); hero collage \& story play buttons show `"Videos coming soon"`; ASCII `->` in CTA|
|2|Join form|`02\_2\_Join\_form.html`|**Matches (Intentional Spec Change)**|`"Submit"` changed to `"Continue"` for 3-step auth/verification/consent flow|
|2b|My profile|`03\_2b\_My\_profile\_photo.html`|**UI Mismatches**|Community cards honey/amber instead of white; activity card missing left star tile; header title slightly off-center after adding Settings button|
|3|Communities hub|`04\_3\_Communities\_hub.html`|**Matches (Minor Addition)**|Added unread notification bell in [hub\_header.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/community/presentation/widgets/hub_header.dart) (Prompt 2)|
|3b|Request pending|`05\_3b\_Request\_pending.html`|**UI Mismatches**|Heading stays `"Find a specific community"` (HTML: `"Other specific communities"`); locked cards still show `>` chevron instead of lock icon|
|4|Community detail \& request|`06\_4\_Community\_detail\_amp\_request.html`|**High Fidelity**|Cover art, overlapping translucent badge, chips, leadership rows, pinned bar \& footnote match cleanly|
|5|Specific community feed|`08\_5\_Specific\_community\_feed.html`|**Header \& Media Mismatch**|Header cover painter dimmed by 55% amber overlay; non-first-photo `media` renders generic placeholder box; super-mentor Manage button added|
|6|Info, members \& chat|`10\_6\_Info\_members\_amp\_chat.html`|**Matches + Prompt 2/3 Additions**|Added `"View meetings"` and `"Leave community"` buttons; online avatars stacked instead of spaced row|
|7|Resources|`12\_7\_Resources.html`|**High Fidelity**|Type filter chips, 2-up topic tiles, `Start` CTA on quiz rows match; 2 minor copy tweaks (`Lives and lessons` -> `People of faith`, `Study by passage` -> `Key passages`)|
|8|General community feed|`14\_8\_General\_community\_feed.html`|**Label Mismatch**|Scope toggle says `"Specific community"` instead of joined community name (e.g., `"Growth Circle"`)|
|9|Messages inbox|`16\_9\_Messages\_inbox.html`|**High Fidelity**|Amber header, search, role chips, thread cards, unread badge match|
|10|Conversation|`18\_10\_Conversation.html`|**High Fidelity**|Matches header, day pill, bubble shapes/colors; placeholder copy `"Type a message…"` vs `"Write a message"`|
|11|Report a user|`20\_11\_Report\_a\_user.html`|**High Fidelity**|Shared [ReportFlow](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/messaging/presentation/report_flow.dart) + screenshot picker matches mockup|
|12|Report sent|`21\_12\_Report\_sent.html`|**High Fidelity**|[CelebrationScreen](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/core/widgets/celebration_screen.dart) matches circle check, copy, and stacked actions|
|13|New post composer|`22\_13\_New\_post\_composer.html`|**Matches + Attachment Gap**|Toolbar, emoji grid, community pill match; video/doc/multi-photo attachments aren't properly previewed on feed/detail|
|14|Prayer wall|`07\_14\_Prayer\_wall.html`|**UI Mismatches**|Pray count folded inside `"N prayed"` button instead of right-aligned `N prayed` label beside `"I prayed"`; extra report flag added|
|15|New prayer request|`09\_15\_New\_prayer\_request.html`|**High Fidelity**|Matches header, text area, anonymous check row, helper note, and pinned CTA|
|16|Testimonies|`11\_16\_Testimonies.html`|**UI Mismatches + Video Stub**|Pending banner below header instead of above; `"Read story"` missing underline; video duration has literal brackets \& no border; video play is a SnackBar stub|
|17|Share a testimony|`13\_17\_Share\_a\_testimony.html`|**Functional Bug / Partial**|Photo \& video pickers update button labels in UI, **but** [**ShareTestimonyScreen.\_submit**](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/testimony/presentation/share_testimony_screen.dart#L67-L85) **discards `\_photoName` and `\_videoName`** when constructing `Testimony`|
|18|Pathways|`15\_18\_Pathways.html`|**Minor Contrast Deviation**|Progress bar fill is ink (`#111111`) instead of amber (`#F4B400`) inside the current-pathway card \& header|
|19|Pathway steps|`17\_19\_Pathway\_steps.html`|**UI Mismatches**|Completed steps have a `2px` ink border around the whole card (HTML: white card with no border; only current step gets `#FDE68A` + `2px` border); progress bar is ink instead of amber|
|20|My activity \& badges|`19\_20\_My\_activity\_amp\_badges.html`|**High Fidelity**|Info banner, earned solid vs dashed locked badges, and activity rows match closely|

\---

### Detailed Screen-by-Screen Findings (HTML Mockups vs. Flutter)

#### 1\. Landing (`01\_1\_Landing\_scrolls.html` vs. [landing\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/landing/presentation/landing_screen.dart) \& widgets)

* **What matches:** Hero amber background (`#F4B400`) with `2.5px` ink bottom border, `42x42` rounded-square `FCU` badge, rotated `-2deg` white pill around `Succeed.`, bold `2.5px` ink border + `4,4` hard shadow on cards, horizontal student story cards, 3-step join section + General/Specific mini cards, and final amber CTA card.
* **Discrepancies \& stubs:**

  * **Video playback stub:** Tapping the hero collage play circle ([landing\_hero\_section.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/landing/presentation/widgets/landing_hero_section.dart#L45-L49)) or any student story card ([stories\_section.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/landing/presentation/widgets/stories_section.dart#L93-L96)) displays a `'Videos coming soon'` SnackBar instead of opening a video player.
  * **CTA arrow glyph:** [landing\_hero\_section.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/landing/presentation/widgets/landing_hero_section.dart#L54) uses literal ASCII `'Explore communities ->'` instead of a vector arrow / Unicode `→`.
  * **Intentional Prompt 2 addition:** Top logo row adds `\_SignInPill()` (`'Sign in'` -> `/login`), which was absent from `01\_1\_Landing\_scrolls.html`.

#### 2\. Join Form (`02\_2\_Join\_form.html` vs. [join\_form\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/profile/presentation/join_form_screen.dart))

* **What matches:** Back button, 3-step amber/cream progress bar (`Step 1 of 3`), `76x76` circular dashed photo upload (`JoinPhotoPicker`) positioned alongside title/subtitle, field order (Full name, Username with `@` prefix, Birthdate + Country row, Email, Phone, University/High school toggle + dropdown), and pinned bottom bar.
* **Intentional Prompt 2 changes:** Primary CTA changed from `'Submit'` to `'Continue'` to route into `/join/password` (Screen 21), `/verify` (Screen 22), `/consent` (Screen 23), or `/guardian` (Screen 24). Edit mode is handled by dedicated Screen 47 ([edit\_profile\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/profile/presentation/edit_profile_screen.dart)) at `/settings/profile` (with `/profile/edit` redirecting there).

#### 3\. My Profile (`03\_2b\_My\_profile\_photo.html` vs. [my\_profile\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/profile/presentation/my_profile_screen.dart))

* **Discrepancies:**

  1. **Community cards background/icon mismatch:** HTML shows both `"General community"` and `"Growth Circle"` under `"My communities"` as **white cards** (`#FFFFFF`) with colored icon squares (`#FDE68A` / `#F4B400`). Flutter ([my\_profile\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/profile/presentation/my_profile_screen.dart#L255-L353)) colors the General row `AppColors.honey` (`#FDE68A`) with a white icon box, and the approved Specific row `AppColors.amber` (`#F4B400`) with a white initials box.
  2. **Missing star icon tile on `"My activity \& badges"`:** HTML renders a `44x44` rounded white star-icon square on the left side of the amber `"My activity \& badges"` card; Flutter's `\_ActivityRow` ([my\_profile\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/profile/presentation/my_profile_screen.dart#L389-L423)) omits that leading icon tile and adds a `"See your history and progress"` subtitle not in the HTML.
  3. **Header centering shift:** HTML has only `Edit profile` (pencil) on the right so `"My profile"` sits dead-center. Prompt 2 added the `Settings` gear button next to `Edit profile`, but left `SizedBox(width: 52)` on the left ([my\_profile\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/profile/presentation/my_profile_screen.dart#L111-L133)), shifting `"My profile"` visually to the left of center.

#### 4\. Communities Hub \& Pending Variant (`04\_3\_Communities\_hub.html` \& `05\_3b\_Request\_pending.html` vs. [communities\_hub\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/community/presentation/communities_hub_screen.dart) \& [community\_list\_card.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/community/presentation/widgets/community_list_card.dart))

* **Intentional Prompt 2 updates:** Added `\_NotificationBell()` to [hub\_header.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/community/presentation/widgets/hub_header.dart#L37) and removed the `Prototype: super-mentor approves` link.
* **Discrepancies on Screen 3b (Pending):**

  1. **Section title not updated when pending:** HTML `05\_3b` changes the section header to **`"Other specific communities"`** when a request is pending. Flutter ([communities\_hub\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/community/presentation/communities_hub_screen.dart#L121-L124)) always displays `'Find a specific community'`.
  2. **Locked cards show chevron instead of lock icon:** HTML `05\_3b` shows a **lock icon** on the trailing side of the dimmed (`opacity: 0.5`) community cards. Flutter's [community\_list\_card.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/community/presentation/widgets/community_list_card.dart#L79-L86) still renders `Icons.chevron\_right\_rounded` when `enabled == false`.

#### 5\. Shared Community \& General Header Chrome (`07`, `08`, `10`, `11`, `12`, `14`, `15` vs. [community\_header\_chrome.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/core/widgets/community_header_chrome.dart) \& [general\_shell.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/core/widgets/general_shell.dart))

* **Dimmed cover illustration:** [community\_header\_chrome.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/core/widgets/community_header_chrome.dart#L57) lays `AppColors.amber.withValues(alpha: 0.55)` over the vector `CommunityCoverPainter`, washing out the crisp white/honey/cream geometric cover art visible in the HTML mockups (`08\_5`, `14\_8`, etc.).
* **Screen 8 scope switcher label:** HTML `14\_8\_General\_community\_feed.html` displays the user's joined community name (e.g., `Growth Circle`) on the right half of the `General | Growth Circle` switcher. [general\_shell.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/core/widgets/general_shell.dart#L45) hardcodes `'Specific community'` even when `hasApprovedSpecific` is true.
* **Screen 6 Info \& Members additions:** HTML `10\_6` shows only `Community info`, `Online now` spaced row, and `Members` list. Flutter ([info\_members\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/community/presentation/info_members_screen.dart#L100-L192)) adds `"View meetings"` (Screen 51), overlapping stacked online avatars, and a red-outlined `"Leave community"` button (Prompt 2/3 feature additions).

#### 6\. Feed Cards, Detail, \& Composer (`08`, `13`, `14` vs. [post\_card.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/core/widgets/post_card.dart), [post\_detail\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/feed/presentation/post_detail_screen.dart), [composer\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/feed/presentation/composer_screen.dart))

* **Non-first-photo attachments are stubbed visually:** [ComposerScreen.\_submit](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/feed/presentation/composer_screen.dart#L272-L276) allows attaching up to 4 items across photos, videos, and documents, placing the first photo in `post.photo` and everything else in `post.media`. However:

  * [PostCard](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/core/widgets/post_card.dart#L138-L154) renders any non-empty `media` list as a single fixed `160px` cream rectangle with `Icons.image\_outlined` (it neither displays actual local file thumbnails, nor distinguishes videos/documents, nor plays/opens them).
  * [PostDetailScreen](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/feed/presentation/post_detail_screen.dart#L165-L180) only renders `post.photo` and ignores `post.media` completely.

#### 7\. Prayer Wall (`07\_14\_Prayer\_wall.html` vs. [prayer\_wall\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/prayer/presentation/prayer_wall_screen.dart))

* **Button count placement:** HTML displays an amber `"I prayed"` button, an outlined `"Respond"` button, and a **right-aligned `8 prayed` text counter** at the end of the row. Flutter ([prayer\_wall\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/prayer/presentation/prayer_wall_screen.dart#L201-L212)) combines the count into the button label (`'${request.prayedCount} prayed'` when `> 0`), removing both the static `"I prayed"` label once prayed>0 and the right-aligned counter. (Prompt 2 also added `ReportIconButton` top-right.)

#### 8\. Testimonies \& Share Testimony (`11\_16\_Testimonies.html` \& `13\_17\_Share\_a\_testimony.html` vs. [testimonies\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/testimony/presentation/testimonies_screen.dart) \& [share\_testimony\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/testimony/presentation/share_testimony_screen.dart))

* **Pending review banner position:** HTML places `"Your story is awaiting review by the moderators."` **above** the `"Testimonies"` title + `"Share your story"` button. Flutter ([testimonies\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/testimony/presentation/testimonies_screen.dart#L48-L59)) puts `TabSectionHeader` first and `InfoBanner` below it.
* **`\_VideoTestimonyCard` visual \& functional gaps:**

  * HTML has a `2px solid #111` border on the top-left duration pill; Flutter omits the border and interpolates `'\[$duration]'` ([testimonies\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/testimony/presentation/testimonies_screen.dart#L162-L176)).
  * Tapping a video testimony logs `ActivityType.videoWatched` and shows a `'Video player coming soon'` SnackBar ([testimonies\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/testimony/presentation/testimonies_screen.dart#L144-L149)) instead of playing a video.
* **`"Read story"` link styling:** HTML underlines `"Read story"`; Flutter ([testimonies\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/testimony/presentation/testimonies_screen.dart#L320-L326)) omits `TextDecoration.underline`.
* **Media discarded on testimony submission:** [ShareTestimonyScreen](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/testimony/presentation/share_testimony_screen.dart#L34-L85) lets users pick `\_photoName` and `\_videoName` via `ImagePicker` and updates button labels, **but `\_submit()` hardcodes `type: TestimonyType.story` and never saves the photo or video reference onto `Testimony`**.

#### 9\. Pathways \& Pathway Steps (`15\_18\_Pathways.html` \& `17\_19\_Pathway\_steps.html` vs. [pathway\_progress\_bar.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/pathways/presentation/widgets/pathway_progress_bar.dart) \& [pathway\_steps\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/pathways/presentation/pathway_steps_screen.dart))

* **Progress bar fill color:** HTML renders an amber (`#F4B400`) fill inside the `2px` ink-bordered white track on both Screen 18 and Screen 19. [PathwayProgressBar](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/pathways/presentation/widgets/pathway_progress_bar.dart#L31) fills with `AppColors.ink` (`#111111`).
* **Completed step borders on Screen 19:** HTML shows white borderless cards for completed steps (only the `40x40` amber check circle has a `2px` border) and reserves the `2px` card border + `#FDE68A` fill exclusively for the **current** step. [PathwayStepsScreen](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/pathways/presentation/pathway_steps_screen.dart#L115-L126) applies `Border.all(color: AppColors.ink, width: 2)` to **both** completed and current steps.

\---

## 2\. Stubs, Placeholders \& Partially Implemented Features (All 61 Screens)

Even though all 61 routes now render real Flutter widgets, several screens and infrastructure layers rely on **in-memory fakes or UI stubs** rather than real device/backend implementations:

### A. App-Wide Persistence \& Backend Layer (Not Implemented Yet)

* **All 21 repositories in** [**repository\_providers.dart**](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/core/providers/repository_providers.dart) are bound to in-memory `Fake\*` implementations (`FakeAuthRepository`, `FakeProfileRepository`, `FakePostRepository`, `FakeMessagingRepository`, `FakeNotificationRepository`, `FakePrivacyRepository`, etc.) using seeded fixtures and hardcoded debug helpers (e.g., `FakeAuthRepository.fakeCode = '123456'`, `fakePasswordDigest`).
* **Connectivity (**[**connectivity\_service.dart**](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/core/connectivity/connectivity_service.dart)**):** Uses `FakeConnectivityService` (toggled only via debug scenarios in [debug\_scenarios.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/core/debug/debug_scenarios.dart)) rather than real platform connectivity (e.g., `connectivity\_plus`).

### B. Screen-Level Stubs \& Partial Features

1. **Screen 1 – Landing videos (**[**landing\_hero\_section.dart**](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/landing/presentation/widgets/landing_hero_section.dart#L45-L49)**,** [**stories\_section.dart**](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/landing/presentation/widgets/stories_section.dart#L93-L96)**):**

   * **Status:** Stubbed (`'Videos coming soon'` SnackBar).
2. **Screen 13 \& Feeds – Multi-media / video / document attachments (**[**composer\_screen.dart**](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/feed/presentation/composer_screen.dart#L272-L276)**,** [**post\_card.dart**](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/core/widgets/post_card.dart#L138-L154)**,** [**post\_detail\_screen.dart**](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/feed/presentation/post_detail_screen.dart#L165-L180)**):**

   * **Status:** Partial. Non-primary photos, videos, and documents render as an unclickable cream box with a generic image icon on feed cards and are omitted on `PostDetailScreen`.
3. **Screen 16 \& 17 – Testimonies video playback \& media upload (**[**testimonies\_screen.dart**](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/testimony/presentation/testimonies_screen.dart#L144-L149)**,** [**share\_testimony\_screen.dart**](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/testimony/presentation/share_testimony_screen.dart#L67-L85)**):**

   * **Status:** Video playback is stubbed (`'Video player coming soon'` SnackBar); testimony submission picks photo/video files in local state but does not attach them to the submitted `Testimony`.
4. **Screen 33 – Video player (**[**video\_screen.dart**](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/learning/presentation/video_screen.dart#L21-L76)**):**

   * **Status:** Simulated playback. Driven by `FakePlaybackController` (progress timer on an amber/honey box) with no actual video decoder/player package; Quality toggle (`Auto` / `Data saver`) only toggles autoplay/state without changing a real video stream.
5. **Screen 37 – Document viewer \& download (**[**document\_screen.dart**](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/learning/presentation/document_screen.dart#L13-L103)**):**

   * **Status:** Placeholder \& stub. Renders a `"Page X of Y"` icon card rather than an actual PDF renderer, and the `Download` button shows `'Downloads are coming soon.'`.
6. **Screen 45 – Push notifications (**[**notification\_preferences.dart**](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/notifications/domain/notification_preferences.dart#L30-L38)**,** [**notification\_channels.dart**](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/notifications/data/notification_channels.dart)**):**

   * **Status:** Partial. `DeliveryChannel` only exposes `In-app` and `Email` (via `FakeEmailChannel` storing sent notifications in memory); Push notifications are explicitly omitted as out of scope for now.
7. **Screen 51 – Add meeting to calendar (**[**meetings\_screen.dart**](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/meetings/presentation/meetings_screen.dart#L130-L138)**):**

   * **Status:** Stubbed (`'Adding to your calendar is coming soon.'` SnackBar).
8. **Community Charter \& Support Email (**[**charter\_screen.dart**](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/auth/presentation/charter_screen.dart#L19-L40)**,** [**app\_info.dart**](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/core/config/app_info.dart#L5)**):**

   * **Status:** Placeholder copy. All four sections of `CharterScreen` still contain literal `\[Placeholder]` prefixes in user-visible body copy, and `supportEmail` is noted as a placeholder mailbox.

\---

## 3\. Recommended Prioritized Action List

1. **Fix functional/data-loss UI gaps first:**

   * Wire picked photo/video fields in [share\_testimony\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/testimony/presentation/share_testimony_screen.dart) into `Testimony` (or add media fields to the model) instead of dropping `\_photoName`/`\_videoName`.
   * Render `post.media` (additional photos, video badges, document rows) properly in [post\_card.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/core/widgets/post_card.dart) and [post\_detail\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/feed/presentation/post_detail_screen.dart).
2. **Tighten Screen 1–20 UI fidelity to match the HTML mockups:**

   * Update Screen 3b pending state ([communities\_hub\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/community/presentation/communities_hub_screen.dart) + [community\_list\_card.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/community/presentation/widgets/community_list_card.dart)) to change heading to `"Other specific communities"` and swap the trailing `>` chevron for a lock icon when `enabled == false`.
   * Update [general\_shell.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/core/widgets/general_shell.dart) so the right segment shows the user's approved specific community name instead of `"Specific community"`.
   * Fix [my\_profile\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/profile/presentation/my_profile_screen.dart) card colors (white cards for communities, star icon tile on amber activity card, balanced header centering).
   * Remove the `2px` ink border from completed steps on [pathway\_steps\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/pathways/presentation/pathway_steps_screen.dart), move the pending banner above the header \& underline `"Read story"` on [testimonies\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/testimony/presentation/testimonies_screen.dart), and decide whether [prayer\_wall\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/prayer/presentation/prayer_wall_screen.dart) should restore the separate right-aligned `N prayed` label.
3. **Replace remaining copy \& media stubs before release:**

   * Replace `\[Placeholder]` text in [charter\_screen.dart](file:///F:/website%20backup/projects/FOCUS/FOCUS-Discipleship-App/mobile/lib/features/auth/presentation/charter_screen.dart) with approved FCU charter text.
   * Integrate real video playback (`Landing`, `Testimonies`, `VideoScreen`), PDF viewer + download (`DocumentScreen`), and calendar export (`MeetingsScreen`) alongside backend repository replacements.

