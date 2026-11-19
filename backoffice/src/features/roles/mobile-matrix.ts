/**
 * src/features/roles/mobile-matrix.ts
 *
 * WHAT: B31 mobile-app feature matrix: what students, alumni, mentors and super-mentors can do in the app
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented (proposed matrix, to be validated with FOCUS Uganda)
 */

export type MobileCell = { allowed: boolean; note?: string };

export interface MobileRow {
  feature: string;
  hint?: string;
  /** Student, Alumni, Mentor, Super-mentor */
  cells: [MobileCell, MobileCell, MobileCell, MobileCell];
}

export interface MobileGroup {
  group: string;
  rows: MobileRow[];
}

export const MOBILE_ROLE_COLUMNS = ["Student", "Alumni", "Mentor", "Super-mentor"] as const;

export const MOBILE_MATRIX: MobileGroup[] = [
  {
    group: "Learn",
    rows: [
      { feature: "Browse resources and pathways", cells: [{ allowed: true }, { allowed: true }, { allowed: true }, { allowed: true }] },
      { feature: "Earn badges and keep an activity history", hint: "Only the person sees their history", cells: [{ allowed: true }, { allowed: true }, { allowed: true }, { allowed: true }] },
    ],
  },
  {
    group: "Caregroup",
    rows: [
      { feature: "Join the general caregroup", cells: [{ allowed: true, note: "automatic" }, { allowed: true, note: "automatic" }, { allowed: true, note: "automatic" }, { allowed: true, note: "automatic" }] },
      { feature: "Join a specific caregroup", hint: "Mentors and super-mentors are assigned by an admin", cells: [{ allowed: true, note: "only one" }, { allowed: true, note: "only one" }, { allowed: false }, { allowed: false }] },
      { feature: "Post, comment and react", cells: [{ allowed: true }, { allowed: true }, { allowed: true }, { allowed: true }] },
      { feature: "Prayer wall", cells: [{ allowed: true }, { allowed: true }, { allowed: true }, { allowed: true }] },
      { feature: "Share a testimony", cells: [{ allowed: true, note: "reviewed" }, { allowed: true, note: "reviewed" }, { allowed: true, note: "reviewed" }, { allowed: true, note: "reviewed" }] },
      { feature: "Delete a testimony", cells: [{ allowed: true, note: "own" }, { allowed: true, note: "own" }, { allowed: false }, { allowed: true, note: "any in caregroup" }] },
      { feature: "Meetings and attendance", cells: [{ allowed: true }, { allowed: true }, { allowed: true }, { allowed: true }] },
    ],
  },
  {
    group: "Messages",
    rows: [
      { feature: "Message members", cells: [{ allowed: true, note: "limits if under 18" }, { allowed: true, note: "limits if under 18" }, { allowed: true }, { allowed: true }] },
      { feature: "Report a post or a person", cells: [{ allowed: true }, { allowed: true }, { allowed: true }, { allowed: true }] },
      { feature: "Block a person", cells: [{ allowed: true }, { allowed: true }, { allowed: true }, { allowed: true }] },
    ],
  },
  {
    group: "Leading",
    rows: [
      { feature: "Manage tab in the caregroup", cells: [{ allowed: false }, { allowed: false }, { allowed: true, note: "reports only" }, { allowed: true }] },
      { feature: "Welcome new members", cells: [{ allowed: false }, { allowed: false }, { allowed: false }, { allowed: true }] },
      { feature: "Hide or warn on reported content", hint: "Level 1 only", cells: [{ allowed: false }, { allowed: false }, { allowed: true }, { allowed: true }] },
      { feature: "Edit meeting details", cells: [{ allowed: false }, { allowed: false }, { allowed: false }, { allowed: true }] },
      { feature: "Follow up inactive members", cells: [{ allowed: false }, { allowed: false }, { allowed: true }, { allowed: true }] },
    ],
  },
  {
    group: "Account",
    rows: [
      { feature: "Download or delete my data", cells: [{ allowed: true }, { allowed: true }, { allowed: true }, { allowed: true }] },
    ],
  },
];
