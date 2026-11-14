# Wiring ledger

Every control added ahead of its real screen navigates to a **registered placeholder route** (`lib/core/router/placeholder_routes.dart` → `PlaceholderScreen`). When a prompt builds the real screen, it replaces the route entry and **deletes its rows here**.

| Source screen | Control | Temporary route | Resolved in prompt |
|---|---|---|---|
