# Brand and design tokens

Taken from the design file (FCU backoffice, boards B1 to B29).

| Token | Value | Use |
|---|---|---|
| `--ink` / `--foreground` | `#1F2D3D` | Text, icons, 2px outlines on buttons and fields |
| `--muted-foreground` | `#4F6074` | Secondary text |
| `--background` | `#FFFAF2` | Page cream (the page also washes from `#FFF1D4` at the top) |
| `--primary` | `#F4B400` | Primary buttons (yellow gradient `--grad-yellow`) |
| `--primary-soft` | `#FFF0B8` | Selected rows (`--grad-select`, with an ink outline) |
| `--border` | `#CFE0F3` | Hairlines, search fields |
| `--blue` / `--grad-blue` | `#1E6AB8` | Active navigation, active tabs, links, avatars |
| `--blue-soft` | `#E3F0FD` | Chips, row outlines, tints |
| `--surface` | `#FFFFFF` | Cards (18px radius, `--shadow-card`, no border) |

Design file: `caregroup-backoffice.html` (boards B1 to B33). Wording: Caregroups (was Communities), New members (was Join requests), Campuses (was Institutions).

- Font: Source Sans 3 (400 to 900), loaded with `next/font`
- Layout: 240px labelled sidebar (no top bar on desktop; a slim header and drawer below `md`), nav item height 42px with 14px radius, content padding 26px 30px, page title 34px / weight 900
- Status tokens (in `src/app/globals.css`, each with a `-soft` tint): `--success` #059669, `--warning` #D97706, `--danger` #E11D48, `--info` is the blue accent
- Components: `globals.css` has a design-system section. Use `.btn` (`.btn-primary`, `.btn-secondary`, `.btn-sm`, `.btn-lg`), `.card`, `.chip`, `.tab`, `.notice`, `.avatar`, `.eyebrow`; tables render as pill-card rows unless they carry `.plain-table`; any `role="tab"` button gets the pill-tab look. Older screens still use plain Tailwind classes that these selectors restyle.
- Source of truth for all colour values is `src/app/globals.css` (RGB channels, so `bg-primary/20` works); `tailwind.config.ts` maps them to utility names
- Known drift: many components still use default Tailwind palette classes (`bg-slate-50`, `text-emerald-800`, `bg-rose-50`, `text-red-700`, ...) instead of the tokens above, and the report charts use hard-coded `#1d4ed8`, `#10b981`, `#6366f1`, `#e2e8f0`
- TODO: logo asset, exact spacing scale, focus ring colour, check contrast of dark text on `#F4B400` and `#FDE68A`
