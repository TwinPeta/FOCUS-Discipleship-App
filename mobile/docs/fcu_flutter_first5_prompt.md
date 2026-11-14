# Build the first 5 screens of the FCU Student Community App (Flutter)

## 0. How to work
1. Read this whole brief first. Then write a short plan (folder structure, packages, build order) and wait for my "go" before coding. If anything below is ambiguous, list your questions together in that plan instead of guessing.
2. Build one screen at a time, in the order in section 6. After each screen: run `flutter analyze`, fix every issue, make sure it runs, and commit (`feat(<screen>): ...`).
3. Match the design closely, but write idiomatic Flutter. Do not translate HTML/CSS literally.
4. Do not add features, screens, packages or backend calls that are not in this brief. Out-of-scope destinations get a placeholder (section 5).

## 1. Product context
FCU (Fellowship of Christian Unions) is a student community app for university and high-school students, launching in Uganda, Kenya and Rwanda. Tagline: "Changing Students, Transforming Societies."

Core concept, which drives the logic of the screens:
- Every student automatically belongs to the **General community** of their campus (open to all).
- Each student may belong to **exactly one Specific community**: a small group led by a **super-mentor** (plus mentors) that meets in person weekly.
- To join a specific community the student sends a **request**, which the super-mentor approves. While a request is pending, every other specific community is locked.

## 2. Scope
**In scope (5 screens + 2 state variants):**

| # | Screen | Variant |
|---|--------|---------|
| 1 | Landing (scrolling marketing page) | |
| 2 | Join form: "Create your profile" | 2b: My profile (after the profile exists) |
| 3 | Communities hub | 3b: Request pending |
| 4 | Community detail & request to join | |
| 5 | Specific community feed | |

**Out of scope, build placeholders only:** General feed, Messages, Composer (new post), Prayer, Testimonies, Pathways, Resources, Community Info & members, My activity & badges. Each is a route that shows a simple "Coming soon" screen with a back button, so navigation never dead-ends.

## 3. Technical decisions (change nothing here without asking me)
- Flutter stable, Dart null-safe, Material 3 as the base but fully custom-themed. Target iOS and Android, portrait. The design artboard is **390 x 844**; layouts must be responsive (use flexible widgets; never hard-code the screen width).
- Packages: `go_router` (navigation), `flutter_riverpod` (state), `google_fonts` (Source Sans 3), `image_picker` (profile photo). Keep other dependencies to a minimum and tell me before adding any.
- Structure: feature-first (`lib/features/<feature>/{data,domain,presentation}`) plus `lib/core/{theme,widgets,router,utils}`.
- **No real backend yet.** Put all data behind repository interfaces (e.g. `ProfileRepository`, `CommunityRepository`, `MembershipRepository`) with in-memory fake implementations and simulated latency (about 400 ms). I will swap in a real backend later, so the UI must never touch the fakes directly.
- Icons: simple rounded line icons, 2 px stroke, matching the design's style (Material Symbols Rounded/Outlined is fine).
- The illustrated artwork (landing characters, cover art) should be drawn with `CustomPaint`/vector shapes, not bitmaps. Specs below.

## 4. Design system

### 4.1 Colors
```dart
class AppColors {
  static const amber      = Color(0xFFF4B400); // primary
  static const honey      = Color(0xFFFDE68A); // secondary fill, chips, tiles
  static const cream      = Color(0xFFFFF3C4); // light fill, info banners, dividers
  static const page       = Color(0xFFFFFBEA); // app background (landing, hub, feed, profile)
  static const white      = Color(0xFFFFFFFF); // cards; also bg of Join form and Detail screens
  static const ink        = Color(0xFF111111); // all text, borders, icons
  static const inputBorder= Color(0xFFE6D48A);
  static const placeholder= Color(0xFF6A6A6A);
}
```
Text is always `ink`. De-emphasised text uses ink at 80–85% opacity, not a grey.

### 4.2 Typography
Font: **Source Sans 3** via `google_fonts`, weights 400-900. Letter-spacing in the design is in em; convert to logical px (em x font size).

| Use | Size / weight | Notes |
|-----|---------------|-------|
| Landing hero headline | 56 / w900 | height 0.94, letterSpacing -1.96 |
| Landing section H2 | 38 / w900 | height 1.0, letterSpacing -1.14 |
| Landing final CTA H2 | 40 / w900 | height 0.98 |
| Hub university title | 32 / w900 | height 1.02, letterSpacing -0.64 |
| Profile name | 28 / w900 | |
| Join form title | 28 / w900 | height 1.1, letterSpacing -0.56 |
| Detail title | 26 / w900 | |
| Section heading in app screens | 20 / w900 | |
| Card title | 17 / w800 | |
| Body | 14-16 / w400-500 | line height about 1.4-1.55 |
| Field label | 12 / w700 | |
| Chip / badge | 11-12 / w700 | |
| Eyebrow (hub "WELCOME, …") | 13 / w800 | UPPERCASE, letterSpacing 0.08em |

### 4.3 Two visual styles (important)
The design uses two distinct looks. Implement both as reusable widgets/decorations:
- **Bold style (Landing only):** 2.5 px `ink` border, hard offset shadow `Offset(4,4)` in `ink` with **zero blur**, big radii (cards 22-28, buttons 18, pills fully round).
- **Soft style (all other screens):** flat white cards, no border, radius 16-20, shadow `0 1px 3px rgba(17,17,17,0.10)` on feed cards only. Primary buttons are amber, radius 16, height 54, w800 16 px, no border.

Other shared radii: inputs 12 (Join form) / 16 (search), header bottom corners 28, avatars/pills fully round.

### 4.4 Shared widgets to create in `core/widgets`
`AppPrimaryButton` (amber, 54 h, with loading + disabled states), `BoldButton` (white, bordered, hard shadow, for landing), `AppTextField` (label above, 46 h, 1.5 px `inputBorder`, radius 12, error state), `InitialsAvatar` (circle or rounded square, optional photo), `InfoBanner` (cream, radius 14, leading icon), `Chip` pill (honey/cream), `RoundIconButton` (44 x 44 white circle, back/edit/camera), `SegmentedToggle` (cream track, amber selected pill), `StepProgress` (3 bars), `ComingSoonScreen`.
Every tappable target is at least 44 x 44.

## 5. Navigation (go_router)

```
/                      -> 1 Landing
/join                  -> 2 Join form
/communities           -> 3 Communities hub (3b is a state of this same screen)
/communities/:id       -> 4 Community detail & request
/community/:id/feed    -> 5 Specific community feed
/profile               -> 2b My profile
placeholders: /general-feed, /messages, /compose, /community/:id/{prayer,testimonies,pathways,resources,info}, /activity
```
Flow: Landing -> Join -> (Submit) -> Hub -> Detail -> (Request) -> Hub in Pending state -> (approved) -> Feed. The avatar button on the hub opens Profile. Back buttons must pop correctly; Submit and Request use `go`/`replace` where the previous screen should not be reachable by Back (e.g. after submitting the Join form, Back must not return to it).

## 6. Screens

### 6.1 Landing (`/`), scrolling, page background `page`
Entire page scrolls vertically. Use the **Bold style**.

1. **Hero** (amber background, bottom border 2.5 ink, padding 20/24/36/24, 18 gap):
   - Logo row: 42 x 42 white rounded-square (radius 12, bordered) with "FCU" (w900, 15), next to "Fellowship of / Christian Unions" on two lines (w800, 16).
   - Headline, three lines: "Find your people." / "Grow." / then "Succeed." inside a white bordered chip (radius 12, horizontal padding 12) **rotated -2 degrees**.
   - Sub-copy (20, w500): "Connect with students on your campus who share your values, learn together and build the future you want."
   - **Illustration collage**, about 342 x 290, centered, three tilted cards (bordered, radius 22, hard shadow), each containing a simple cartoon student (head circle, shoulders, smile; flat amber/white/honey fills, 3 px ink outlines):
     left card 122x160 cream, rotated -6 degrees; right card 122x160 white, rotated +5 degrees; center card 170x230 honey, rotated +2 degrees with a white circular **play button** (52 px) in the middle. Three white pill "stickers" with hard shadow: "Connect" (rotated -8 degrees, top-left), "Learn" (+7 degrees, top-right), "Succeed" (-3 degrees, bottom-center).
   - Primary `BoldButton` "Explore communities ->" (62 h) -> `/join`.
   - Text link with small play icon, underlined: "Watch student stories" -> smooth-scrolls to the stories section.
2. **Marquee strip** (white, bottom border, 12 vertical padding): "CONNECT ● LEARN ● GROW ● SUCCEED ● CONNECT ● LEARN", w900 22. Make it a slow looping marquee; respect reduced-motion (static if enabled).
3. **"Campus life is better together"**: three horizontal cards (white, bordered, radius 22, hard shadow, padding 16): amber 56 px icon tile + title (w900 22) + one-line description.
   - Connect: "Meet students on your campus who share your values." (people icon)
   - Learn: "Videos, guides and quizzes to grow, in class and beyond." (book icon)
   - Succeed: "Mentors who cheer you on toward your goals." (bar-chart icon)
4. **"Hear it from students"** + "Short video stories from students like you.": horizontal scroller of 3 cards, each 250 wide (bordered, radius 24, hard shadow): 250 px art area (amber / honey / cream backgrounds, cartoon student, white play button, duration chip top-left "[0:45]" "[1:10]" "[0:55]") and caption under it: quote placeholder in w800 18 ("[Student quote about finding friends]" / "...learning" / "...mentorship") and "[Student name] · [University]" (third one says "[High school]"). Keep the bracketed placeholders. Tapping play shows a snackbar "Videos coming soon"; load card data from a `StoriesRepository` fake.
5. **"Join in 3 steps"**: numbered amber circles (48 px, bordered) with title + description:
   1. Create your profile: "Add your photo and details in a minute."
   2. Enter your campus: "You join the general community automatically."
   3. Pick one specific community: "A smaller group with mentors. One per student."
   Then two side-by-side mini cards: **General** (white): "Everyone on your campus, open to all." and **Specific** (honey): "Your small group with a super-mentor."
6. **Final CTA card** (amber, bordered, radius 28, hard shadow): "Ready to meet your people?" (40), "Changing Students, Transforming Societies.", and a `BoldButton` "Explore communities" -> `/join`.

### 6.2 Join form (`/join`), white background
Fixed header + scrollable form + pinned Submit button. The form must scroll and stay usable with the keyboard open.
- Back button (44 x 44, arrow). Under it: `StepProgress` (3 bars, first amber, other two cream) with "Step 1 of 3" (12, w600). Make `currentStep` a parameter.
- Title row: left "Create your profile" (28) + "Tell us who you are to join your campus community."; right a **76 px circular photo picker** (cream fill, dashed 2 px ink border, person icon, small amber "+" badge bottom-right with white border) with "Add photo" caption below. Tap -> `image_picker` (gallery/camera sheet). After picking, show the photo in the circle.
- Fields (label above, 46 h, radius 12, border `inputBorder`):
  - Full name, placeholder "e.g. Grace Namuli"
  - Username, placeholder "@username"
  - Two columns: Birthdate (placeholder "DD / MM / YYYY", use a date picker or masked input) and Country (dropdown: Uganda, Kenya, Rwanda)
  - Email, placeholder "you@example.com" (email keyboard)
  - Phone number, placeholder "+256 700 000 000" (phone keyboard)
  - "I study at": `SegmentedToggle` with **University** (default) and **High school**
  - Institution dropdown. Label and options follow the toggle: "University" -> placeholder "Select your university"; "High school" -> "High school" / "Select your high school". Seed fake lists per country (a handful of real-looking examples each; I'll replace them later).
- **Submit** (amber, 54 h) pinned at the bottom.
- Validation (on submit and on blur): all fields required; email format; phone format (digits, optional +, sensible length); username 3-20 chars, letters/numbers/underscore, `@` is shown but not stored; birthdate must be a real date and the user must be at least 13. Inline error text under the field, same style for every field. Photo is optional.
- On valid submit: show loading on the button, call `ProfileRepository.createProfile`, set the user as automatically joined to the General community of their institution, then `go('/communities')`.

### 6.2b My profile (`/profile`), page background
- Amber header, bottom corners 28. Row: back button, centered "My profile" (w800 18), white round **edit** button. Below: **112 px avatar** (white fill, 4 px white border, initials fallback e.g. "GN", or the photo) with a 44 px white camera button (2 px ink border) at bottom-right that changes the photo. Then the full name (28, w900) and `@username` (16, w600).
- White card (radius 20) with 4 rows separated by 1 px cream lines: Email, Phone, Country, University (label at 75% opacity left, value w700 right).
- "My communities" (20): a row for **General community** (honey tile, "Joined automatically") -> `/general-feed`; a row for the member's specific community if any (amber tile with initials, name, "Your specific community") -> its feed; if they have none, show a dashed-outline row "Pick a specific community" -> `/communities`.
- Amber row "My activity & badges" / "See your history and progress" with chevron -> `/activity` placeholder.
- Edit button: open an edit mode or reuse the Join form pre-filled (tell me which you chose in the plan).

### 6.3 Communities hub (`/communities`), page background
Soft style. Content under the header scrolls.
- **Header** (amber, bottom corners 28, padding 24/20/22): top-right a 48 px white round avatar with initials (-> `/profile`); eyebrow "WELCOME, [FIRST NAME]" (use the real first name); university name as H1 (32); subtitle "Two ways to belong: the whole campus, and a smaller group with mentors."
- "My communities" (20) then a **2-column grid**:
  - Left, **General community**: amber card, radius 20, min height 132, white 40 px icon tile, "General community" (two lines), "Joined · Open". Tap -> `/general-feed`.
  - Right, **Specific community** slot, 3 states (see below).
- "Find a specific community" (20), an `InfoBanner`: "You can join **only one** specific community. Choose the one that fits you best." (bold "only one"), a **search field** (50 h, radius 16, leading search icon, placeholder "Search by name, day or place") that filters live by name, day and place.
- Community cards (white, radius 20, padding 14): 48 px rounded-square initials tile (first amber, rest honey), name (w800 17), "Super-mentor: [Name]", chips: day and time ("Tue · 5:00 PM", honey, w700) and room ("[Room]", cream), trailing chevron. Tap -> `/communities/:id`. Seed data: **Growth Circle** (Tue 5:00 PM), **Life & Faith Circle** (Thu 6:30 PM), **Freshers Connect** (Fri 4:00 PM).
- Show an empty state when search has no results.

**Membership states of the specific slot** (one screen, driven by `MembershipStatus`):
| State | Right card | Banner | Search | List |
|---|---|---|---|---|
| `none` | White, **dashed 2 px ink border**, honey icon tile, "Specific community", "Only 1 allowed · Pick below" | "You can join only one…" | enabled | all communities, tappable |
| `pending` (3b) | Honey fill, initials tile, community name, "Pending approval" (w700) | "Request sent to the super-mentor. Other communities are locked until you get an answer. You can join **only one**." | **disabled** | requested community removed; the rest at 50% opacity and **not tappable** |
| `approved` | Amber card, "Joined", tap -> its feed | hide banner | hide search + list (or collapse) | Not shown in the design; make a sensible choice and tell me |

In **debug builds only** (`kDebugMode`), in the pending state show a small underlined link "Prototype: super-mentor approves" that flips the status to `approved` and goes to the feed. This stands in for the real approval until the backend exists.

### 6.4 Community detail (`/communities/:id`), white background
- **Cover** (200 h, full width): vector art on honey background: amber circle (center 250,120 r70), white circle (318,96 r64), cream circle (372,140 r52), small amber circle (318,70 r14) and an amber half-circle "shoulders" shape under it (a stylised person). Draw it with `CustomPaint` scaled to width. White 44 px round back button top-left. Over the bottom of the cover, a white 92%-opacity card (radius 16, padding 10/12, 16 px margin) with a 48 px amber initials tile ("GC"), community name (26, w900) and "[University] · Specific community".
- Scrollable body (padding 24): **About** (15, w800) + description paragraph (14, line height 1.55, 88% opacity); **In-person meeting**: two cream rows (radius 14) with icons: calendar "Every Tuesday · 5:00 PM", pin "[Meeting room, building]"; **Leadership**: avatar rows: amber circle "SM" + "[Super-mentor name]" / "Super-mentor", honey circle "M" + "[Mentor name]" / "Mentor".
- **Pinned bottom bar** (top border 1 px cream, padding 14/24/24): `AppPrimaryButton` "Request to join" + caption "You can join only one specific community. Your request goes to the super-mentor for approval, and you will be notified." (12, centered).
- Tap "Request to join": show loading, call `MembershipRepository.requestToJoin(communityId)`, set status `pending`, then return to the hub in the pending state. If the user already has a pending/approved membership, the button is disabled with explanatory caption.
- Use the real community data (name, initials, schedule, room, leaders) from the repository. Bracketed text is placeholder data.

### 6.5 Specific community feed (`/community/:id/feed`), page background
- **Header block** (amber, clipped, the cover art from 6.4 sits **behind** it as a decorative background, `BoxFit.cover`, non-interactive), padding 16/20/0:
  1. Row: white 44 px round back button (-> `/communities`); a translucent white panel (92% opacity, radius 12) with community name (w800 20) and a status row with a small circle and "12 members online now"; white rounded 44 px **messages** button (-> `/messages`).
  2. **Scope switch**: white track (radius 15, padding 4), two equal segments: "General" (-> `/general-feed`) and the community name "Growth Circle" (selected: amber, w800).
  3. **Tab bar**, horizontally scrollable on a 92%-white strip with top radius 14: Feed (selected, 3 px ink underline, w800), Prayer, Testimonies, Pathways, Resources, "Info & members". Non-feed tabs go to placeholders.
- **Feed list** (scrolls, padding 16, 12 gap):
  - **Composer row card** (white, radius 16, soft shadow): "You" avatar (38 px, cream), a pill-shaped fake input (44 h, 1.5 px `inputBorder`, "Share something…") and three small icons on the right (video, emoji, heart). Tap anywhere -> `/compose`.
  - **Post cards** (white, radius 16, padding 14, soft shadow): avatar (40 px, initials), author name (w800 14), relative time (12, 80% opacity), optional **role badge** pill ("Super-mentor" honey, "Mentor" cream), body text (14, line height 1.5), and an action row "Like" (heart) and "Comment" (bubble). Seed three posts: super-mentor announcement (2 h ago), mentor encouragement (Yesterday), member post with no badge or actions (2 days ago, prayer request or testimony).
  - Like toggles with local optimistic state; Comment goes to a placeholder.
  - Pull-to-refresh and a proper empty state.
- **FAB**: amber 60 px circle, 2.5 px ink border, hard shadow (3,3), plus icon, bottom-right (16 px inset) -> `/compose`.
- Only **members with `approved` status** can reach this route; otherwise redirect to the hub.

## 7. Data models (keep them simple, with `copyWith` and immutable fields)
`UserProfile` (id, fullName, username, birthdate, country, email, phone, institutionType [university/highSchool], institutionName, photoPath?), `Community` (id, name, initials, type [general/specific], institutionId, description, meetingDay, meetingTime, room, superMentor: Person, mentors: List<Person>), `Person` (id, name, role), `Membership` (communityId, status [none/pending/approved/rejected]), `Post` (id, author: Person, role badge?, body, createdAt, likeCount, likedByMe), `StoryVideo` (id, quote, authorName, institution, duration).
`rejected` has no design yet: on rejection, return the slot to `none` and show a dismissible banner "Your request wasn't approved. You can choose another community." (flag this as my assumption in your summary).

## 8. Quality bar
- Colors, radii, font weights and spacing come from the theme/tokens, with no magic numbers scattered in widgets.
- All text scales with the system font size without overflow (test at 1.3x). Long names ellipsize.
- Screen-reader labels on every icon-only button (back, edit, camera, messages, FAB, play).
- Loading, empty and error states exist for every async screen.
- Write widget tests for: Join form validation, hub state switching (`none`/`pending`/`approved`), search filtering, and the "only one specific community" rule.
- Run `flutter analyze` with zero warnings and format with `dart format`.
- When finished, give me: the folder tree, how to run it, every assumption you made, and everything left as placeholder.
