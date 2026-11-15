# Start here

## What this repo is
The staff back office for the FCU Student Community App: manage institutions and communities, approve join requests, manage members and staff, validate and publish content, build quizzes and pathways, moderate, handle consents and data requests, and report. It follows the 29 design screens (B1 to B29). Each source file is a placeholder with a header comment saying what it is for.

## Prerequisites
- Node.js 20+
- pnpm 9 (`corepack enable`)

## First run
```bash
pnpm install
cp .env.example .env.local        # API_BASE_URL must point at a running API (see ../api/README.md)
pnpm dev                          # http://localhost:3000
```

## Working with the backend
1. Ask the backend developer for `openapi.yaml` (even a draft). Put it in `../docs/openapi.yaml`.
2. `pnpm api:generate` creates `src/lib/api/schema.d.ts`.
3. There is no mock mode: every screen reads and writes the real API. Run it locally with `cd ../api && npm start` (start it with `ADMIN_EMAIL` and `ADMIN_PASSWORD` set to create the first admin, then add data in the back office).
4. Browser calls go through `src/app/api/proxy/[...path]` so tokens stay in httpOnly cookies.
5. `docs/api-needs.md` lists what the screens need from the API.

## Two shells, one app
| Shell | Route group | Roles | Scope |
|---|---|---|---|
| Back office | `(backoffice)` | System admin, content admin (nav filtered by role) | Everything allowed by the permission matrix |
| My community | `(my-community)` | Super-mentor | Their own community only |

## Commands
| Command | Purpose |
|---|---|
| `pnpm dev` | Dev server |
| `pnpm typecheck` | TypeScript check |
| `pnpm lint` | ESLint |
| `pnpm test` | Unit and component tests (Vitest) |
| `pnpm test:e2e` | Playwright e2e and accessibility tests |
| `pnpm api:generate` | Regenerate API types from OpenAPI |

## Map of the repo
| Path | What lives there |
|---|---|
| `src/app/` | Routes: `(auth)`, `(backoffice)`, `(my-community)`, `api/` |
| `src/features/` | One module per feature: components, queries, schemas |
| `src/components/` | Shared UI: layout, data-table, common (side panel, filters, dropzone), feedback, shadcn `ui/` |
| `src/lib/` | API client, auth, permissions and scope, env, logging |
| `tests/` | Unit, component, e2e, a11y |
| `docs/` | Screen map, feature specs, API needs, permissions, brand, design vs BRD |
| `start/` | This folder |

## Read next
1. `CONVENTIONS.md`
2. `BUILD-ORDER.md`
3. `OPEN-QUESTIONS.md` and `../docs/design-vs-brd.md`
