# Design (B1-B29) versus BRD v0.1

The back office design is more specific than the BRD and differs from it in places. Use this to decide what to build and what to confirm.

## 1. Product shape
| Topic | BRD | Design | Impact |
|---|---|---|---|
| Web app audience | Responsive web for all users (FR-12) | Staff-only back office ("Authorised staff only") | Student-facing web pages removed from the scaffold. Confirm (Q1) |
| Student experience | Web and native app | Flutter mobile app | Members, library, cohorts, downloads, offline are not in this repo |
| Name | FOCUS Uganda | FCU, Fellowship of Christian Unions | Confirm (Q2) |

## 2. Domain model
| Topic | BRD | Design |
|---|---|---|
| Groups | Cohorts (campus, year, group) | General community per institution plus specific communities (one per student) with super-mentor and mentors |
| Joining | Join cohort / assigned | Request to join, approved by super-mentor; conflicts when already in a community |
| Institutions | Campuses | Institutions: universities and high schools (so minors are expected) |
| Roles | Student, leader, associate, content admin, system admin | Student, mentor, super-mentor, alumni, content admin, system admin |
| Community info | Not described | Meeting day, time, place, cover photo (managed only in back office) |

## 3. Things the design needs that the BRD ranks lower (or omits)
| Feature | BRD priority | In the design |
|---|---|---|
| Pathways | Should (FR-15) | B6 |
| Badges | Could (FR-20) | B21 |
| Notifications | Could (FR-19) | B22, and needed for inactivity reminders (FR-05 Must) |
| Testimonies moderation | Could (FR-22) | B16 |
| Prayer and post moderation | Should (FR-13) | B17 |
| Announcements and landing stories | Not in BRD | B8 |
| Scheduled reports, PDF export | "Exportable periodic reports" proposed | B20 |
| Institutions, bulk CSV import | Import only if an existing database exists | B15, B24 |

## 4. Things the BRD asks for that the design does not show
| BRD item | Status |
|---|---|
| Mentor/mentee matching and verification (FR-14) | Not designed. Settings mention "mentors must be verified" |
| Phone number login with SMS OTP (FR-16) | Staff use work email and password; may belong to the mobile app |
| Keyword and tag search for members (FR-17) | Content has tags and search in the back office only |
| Calendar of events (FR-21) | Not designed (announcements only) |
| Meeting attendance | Used by KPIs and a badge, but no screen records it |
| Personal activity history (FR-18) | Mobile app concern |
| Data export and backup (Section 5.5) | Per-user exports are in data requests; no system backup screen |
| Content approver roles (doctrinal committee) | Reduced to a "Validator" field |

## 5. Rules in the design that resolve BRD open questions (confirm with FOCUS)
- Minor age threshold is a setting, default 18, with guardian consent tracking (B19, B23).
- Retention: inactive accounts kept 24 months, deletion requests answered in 30 days (B19).
- Inactivity: 14 days (B1, B22, B29).
- Moderation: two levels, with reasons, authors and dates kept (B18).
- Password rules for staff: at least 10 characters, letter and number, differs from previous (B28).
- Audit: sign-ins, viewing personal data, exports, suspensions, approvals, publishing, cover changes (B26).

## 6. Permission matrix differences
The design matrix uses C/M/V/A and adds Mentor and Super-mentor. The BRD matrix uses V/E/A/Ad and has Leader and Associate. Treat the design matrix as the working one and validate it. Open points: Alumni missing; content admin "Review L2" versus admin-only suspend; mentor back office access.
