# FCU mobile — Roadmap v2 (design refresh + review fixes)

Sources: the new design `mobile/FCU Student  Review.html` (69 screens; bundled, open it in a browser), the review list from the product owner (11 items, 2026-11-15) and the brand rules below. Process (claims, git rules, quality bar) is unchanged: `docs/collaboration.md`.

## Brand rules (apply everywhere)
- **Font:** Bricolage Grotesque for the whole app. Bundle it in `assets/google_fonts/` (runtime font fetching is off). Headings 700–800, titles 600–700, body 400–500 (review item 8).
- **Colour:** gradient `#F5CE3E` → `#E5A90A`. The **light end `#F5CE3E`** is the normal surface (headers, primary buttons, chips); the **dark end `#E5A90A`** is for emphasis only (active tab, selected state, key call to action, badges). Ink `#111111` on both. No new hard shadows.
- **Colour modes:** Light, Dark and System (review item 3). Dark keeps the amber gradient for accents on a near-black surface.

## Decisions taken from the design (differs from the current app)
- **Bottom navigation = Home | Communities | Messages | Profile**, plus a **Create** button that opens the Create menu (screen 66). This replaces the 3-tab bar shipped on 2026-11-15.
- **Home** gets quick links: General · your circle · Prayer wall · Testimonies · **Learn** (resources in the General community, review item 7).
- **Likes and comments show the count only, no words** (review item 6), e.g. ♡ 24 · 💬 6.
- **New feature: Questions & answers** (Create · Question, 64, 65, 67) and **Search** (62).
- **Settings:** the profile card already opens Edit profile, so the duplicate "Edit profile" row goes (review item 11).

## Please confirm (my reading of open items)
| # | Item | Proposed meaning |
|---|---|---|
| 1 | Permissions for access | Ask for camera/photo permission at the moment it is needed, with a short reason first; if refused, explain and offer "Open settings". Not role permissions (those exist). |
| 2 | Scroll behaviour on Home | The amber header collapses as you scroll so the feed uses the full screen; quick links stay pinned under it. |
| 4 | Auto slider for videos | A horizontal video carousel (Home "Learn" and Resources) that auto-advances every 5 s, pauses on touch, no autoplay with sound. |
| 5 | Document size 10 MB | Documents come back (PDF, DOC/DOCX, PPT/PPTX) with a **10 MB** limit; photos stay **2 MB** at 80% quality. Where: composer and Resources. |
| 9 | Notifications workflow | End to end with the backend: created by the server, delivered in-app (and later push), tap opens the right screen, read/unread syncs, muting respected. |
| 10 | Use the phone's emojis | Remove the custom emoji panel; the emoji button opens the phone's own emoji keyboard. |

## Phases and owners

### Phase 0 — Design foundation (Agent A, ~1 day, **blocks visual work**)
| ID | Task | Done when |
|---|---|---|
| A0.1 | Bricolage Grotesque bundled; `AppTextStyles` re-based on it with the heading weights | golden tests regenerated; no Source Sans 3 left |
| A0.2 | `AppColors` gradient tokens (`amberLight` `#F5CE3E`, `amberDark` `#E5A90A`, `AppGradients.brand`) replacing `#F4B400`; headers and primary buttons use the gradient | contrast ≥ 4.5:1 for ink text checked |
| A0.3 | Dark theme + Light/Dark/System setting (stored locally) | every screen readable in dark; layout matrix passes in both |

Agent B may start B1–B3 logic during Phase 0, but rebases on A0 before styling.

### Phase 1 — Parallel build
**Agent A — shell, Home, feeds, settings**
| ID | Review # | Task |
|---|---|---|
| A1.1 | design | 4-tab bottom nav + centre Create button; Create menu (66) routes to the four composers |
| A1.2 | 2 | Home collapsing header and scroll behaviour (also the community shell) |
| A1.3 | 7 | Home quick links incl. **Learn** = Resources for the General community |
| A1.4 | 6 | Count-only likes/comments on PostCard, post detail, Q&A answers |
| A1.5 | 4 | Auto-advancing video carousel (Home Learn + Resources) |
| A1.6 | 11, 3 | Settings: remove the duplicate row; add Appearance (Light/Dark/System) |
| A1.7 | design | Restyle remaining screens to the design (feed, community tabs, profile, hub) |

**Agent B — creating, uploads, Q&A, search, notifications**
| ID | Review # | Task |
|---|---|---|
| B1.1 | design | Unified composer with tabs Post · Question · Prayer · Story ("Create · …" screens) |
| B1.2 | design | Q&A: Ask (anonymous option), Question & answers (64; mentor answers first, Follow), Write an answer (65), Questions to answer (67; Answer / Pass, filters) |
| B1.3 | design | Search (62): recent, communities, people |
| B1.4 | 5 | `UploadPolicy`: documents back, 10 MB max (PDF/DOC/DOCX/PPT/PPTX); photos 2 MB/80% unchanged |
| B1.5 | 10 | Phone emoji keyboard instead of the custom panel |
| B1.6 | 1 | Runtime permissions (camera/photos) with reason, denied state and "Open settings"; Android manifest + iOS plist |
| B1.7 | 9 | Notifications workflow against the backend (with Joseph) |

**Backend (Joseph) — needed by Agent B**
| ID | For | Endpoint(s) |
|---|---|---|
| J1 | B1.2 | questions, answers, follow, pass, "questions for you" |
| J2 | B1.3 | search (communities, people) |
| J3 | B1.4 | document upload ≤ 10 MB, photo ≤ 2 MB, type checks server-side |
| J4 | B1.7 | notification creation/delivery, read state, preferences |
| J5 | A1.3 | resources for the General community |

### Phase 2 — Integration and QA (both agents)
- Walk every screen in the new design side by side with the app (both colour modes).
- Re-run the link walk (B), layout matrix and goldens (A), integration journeys incl. Q&A (A).
- New debug APK and iOS check; release report updated.

## Rules for this roadmap
- Claim each task ID in `docs/collaboration.md` before starting; one task (or one small group) per commit, with tests.
- A owns `core/theme`, `core/widgets/app_bottom_nav.dart`, shells, Home, feed widgets, Settings. B owns composers, `core/media`, Q&A, search, notifications. Touching the other's files: small, announced in the commit message.
- If the design and this roadmap disagree, the design wins for layout; this roadmap wins for brand rules.
