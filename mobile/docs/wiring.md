# Wiring ledger

Every control added ahead of its real screen navigates to a **registered placeholder route** (`lib/core/router/placeholder_routes.dart` → `PlaceholderScreen`). When a prompt builds the real screen, it replaces the route entry and **deletes its rows here**.

| Source screen | Control | Temporary route | Resolved in prompt |
|---|---|---|---|
| 2b My profile | **Edit profile** round button | `/settings/profile` | 3 |
| 2b My profile | **Settings** round button | `/settings` | 3 |
| 2b My profile | Camera button (keeps the working edit form for now) | `/profile/edit` | 3 (folds into `/settings/profile`) |
| 3 / 3b Hub | Notification bell (unread dot hidden) | `/notifications` | 3 |
| 5 Feed (shell header) | **Manage** (super-mentors only) | `/community/:id/manage` | 2 |
| 6 Info & members | **View meetings** | `/community/:id/meetings` | 3 |
| 9 Messages | "Full screen" link in the new-message sheet (sheet kept working) | `/messages/new` | 3 |
| 10 Conversation | Header avatar | `/members/:id` | 3 |
| 14 Prayer wall | **Respond** | `/prayer/:id` | 3 |
| 16 Testimonies | **Read story** | `/testimony/:id` | 3 |
| ErrorView (all screens) | **Contact support** | `/help` | 3 |
