# Batch 6: link and Back walk (Agent B)

How it is checked: `test/navigation/link_walk_test.dart` runs on every `flutter test`. It drives the real router as an approved member of Growth Circle (and as a super-mentor for 30-32). Each screen is opened two ways:

1. **Deep link** (nothing to pop, like a notification or a shared link). Back must land on a working screen. For the screens listed in `_deepBackParent`, it must land on that exact parent.
2. **Pushed from the screen that links to it.** Back must return to exactly that screen.

A crash, an error screen, or a missing Back/Close fails the test. Screens that are still `PlaceholderScreen` are reported, not failed.

Status on 2026-11-14 (after 52 and 53 landed): **all 36 legs pass** (72 checks); 227 tests green on a clean checkout.

## Fixed in this pass (Agent B)

| Problem | Where | Fix |
|---|---|---|
| Crash: "Null check operator used on a null value" on a deep link to `/messages/:id/report` | Conversation `_scrollToBottom` ran while the page was offstage, under the report | Skip scrolling until the list has a size (`hasContentDimensions`) |
| Close / Post on a deep-linked composer called `pop()` with nothing to pop | `composer_screen.dart` | `popOr(context, feed)` |
| Same after submitting | New prayer request, Share testimony | `popOr(context, tab)` |
| Deep-link Back went to the hub instead of the parent | Post detail, content and user reports, New prayer request, Share testimony, Pathway steps, My activity | `AmberHeaderScaffold.backFallback` set to the logical parent |

New shared pieces:
- `core/router/navigation.dart` `popOr(context, fallback)`: pop, or go to the fallback when nothing can be popped. Use it for every Back, Close and "done" action.
- `AmberHeaderScaffold.backFallback` (defaults to `/communities`, so existing screens are unchanged).
- `ReportFlow.backFallback`: content reports pass their `back` route.

## For Agent A (your screens; not changed)

| Screen | Now | Suggested |
|---|---|---|
| 30 Manage (`/community/:id/manage`), deep link | Back -> `/communities` | `backFallback: '/community/$id/feed'` |
| 31 Join requests, 32 Reports to review, deep link | Back -> `/communities` | `backFallback: '/community/$id/manage'` |
| 52 Prayer request (`/prayer/:id`), deep link | Back -> `/communities` (pushed Back is correct) | `backFallback: '/community/$communityId/prayer'` |
| 53 Testimony (`/testimony/:id`), deep link | Back -> `/communities` (pushed Back is correct) | `backFallback: '/community/$communityId/testimonies'` |
| `PlaceholderScreen` (still on `/settings`, `/settings/profile`, `/help`) | deep-link Back -> `/`, which the guards bounce to the hub | Goes away when 46-50 land. Please add those routes to `_legs` in the walk test, with their parent in `_deepBackParent` (e.g. `/settings` -> `/profile`, `/settings/privacy` -> `/settings`, `/settings/blocked` -> `/settings/privacy`) |

## Deep-link Back that lands on the hub, by design

`/members/:id`, `/messages`, `/notifications`, `/profile`, `/debug`, `/communities/:id`, the shell tabs, and the devotional, quiz and document viewers when opened without `?community=`. They have no single parent, and the hub is the app's home.
