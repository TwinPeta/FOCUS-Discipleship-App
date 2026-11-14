# Roles and permissions

Source: design board B9 (proposed matrix, to be validated). C = consult, M = modify, V = validate, A = administer.

| Resource | Student | Mentor | Super-mentor | Content admin | System admin |
|---|---|---|---|---|---|
| Content library | C | C | C | M / V | A |
| Pathways | C | C | C | M / V | A |
| Community info and schedule | C | C | M (own) | C | A |
| Cover photos | - | - | - | M | A |
| Join requests | - | - | V (own) | C | A |
| Feed, prayer wall, testimonies | C / M | Moderate L1 | Moderate L1 | C | A |
| Reports and suspensions | Report | Review L1 | Review L1 | Review L2 | A |
| Dashboards and exports | - | C (own) | C (own) | C | A |
| Members and roles | - | - | C (own) | - | A |

## Back office access
- System admin: everything.
- Content admin: content, pathways, cover photos, level 2 review, dashboards (read). Nav filtered by `nav-config.ts`.
- Super-mentor: the `(my-community)` shell, own community only.
- Student, mentor, alumni: mobile app only (mentor access to the back office is an open question).

## Open
- Alumni missing from the matrix.
- Content admin "Review L2" versus admin-only suspend/delete.
- The server enforces every rule; `src/lib/permissions` mirrors it for the UI, ideally from `/me` capabilities.
