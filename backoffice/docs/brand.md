# Brand and design tokens

Taken from the design file (FCU backoffice, boards B1 to B29).

| Token | Value | Use |
|---|---|---|
| `--primary` | `#F4B400` | Sidebar, primary buttons |
| `--background` | `#FFFDF5` | Page background (cream) |
| `--background-subtle` | `#FEF9E7` | Subtle panels |
| `--primary-soft` | `#FFF3C4` | Selected rows, soft highlights |
| `--accent` | `#FDE68A` | Badges, hover |
| `--border` | `#E6D48A` | Borders, dividers |
| `--foreground` | `#0F172A` | Text (slate-900) |
| `--muted-foreground` | `#475569` | Secondary text, placeholders (slate-600) |
| `--surface` | `#FFFFFF` | Cards, inputs, active nav item |

- Font: Source Sans 3 (400 to 900), loaded with `next/font`
- Layout: 240px sidebar, nav item height 42px with 14px radius, desktop design at 1280px
- Status tokens (in `src/app/globals.css`, each with a `-soft` tint): `--success` #059669, `--warning` #D97706, `--danger` #E11D48, `--info` #0284C7
- Source of truth for all colour values is `src/app/globals.css` (RGB channels, so `bg-primary/20` works); `tailwind.config.ts` maps them to utility names
- Known drift: many components still use default Tailwind palette classes (`bg-slate-50`, `text-emerald-800`, `bg-rose-50`, `text-red-700`, ...) instead of the tokens above, and the report charts use hard-coded `#1d4ed8`, `#10b981`, `#6366f1`, `#e2e8f0`
- TODO: logo asset, exact spacing scale, focus ring colour, check contrast of dark text on `#F4B400` and `#FDE68A`
