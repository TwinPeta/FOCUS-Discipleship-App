# Wiring ledger

Every control added ahead of its real screen navigates to a **registered placeholder route** (`lib/core/router/placeholder_routes.dart` → `PlaceholderScreen`). When a prompt builds the real screen, it replaces the route entry and **deletes its rows here**.

| Source screen | Control | Temporary route | Resolved in prompt |
|---|---|---|---|

## Pending entry points

Real routes that still need a way in (kept out of the table above, which only lists placeholders):

- `/search` (screen 62, B1.3), for **Agent A**: add a 44px search icon button (semantic label "Search") to the Home / Communities header that calls `context.push('/search')`. The route exists; only the icon is missing.
