/**
 * src/features/roles/queries.ts
 *
 * WHAT: Roles, B30 permission matrix data, and staff account queries and mutations
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

import { Role } from "@/types/enums";
import { mutate } from "@/lib/api/mutate";

export type PermissionCode = "V" | "C" | "E" | "A" | "D" | "X";

export interface MatrixCell {
  codes: PermissionCode[];
  ownOnly?: boolean;
}

export interface MatrixRow {
  module: string;
  cells: Record<Role, MatrixCell>;
}

export interface MatrixGroup {
  group: string;
  rows: MatrixRow[];
}

export const B30_LEGEND: { code: PermissionCode; label: string }[] = [
  { code: "V", label: "View" },
  { code: "C", label: "Create" },
  { code: "E", label: "Edit" },
  { code: "A", label: "Approve or validate" },
  { code: "D", label: "Delete" },
  { code: "X", label: "Export" },
];

export const B30_ROLE_ORDER: Role[] = [
  Role.Student,
  Role.Alumni,
  Role.Mentor,
  Role.SuperMentor,
  Role.ContentAdmin,
  Role.SystemAdmin,
];

function cell(
  codes: PermissionCode[] = [],
  ownOnly = false,
): MatrixCell {
  return { codes, ownOnly };
}

export const B30_PERMISSION_GROUPS: MatrixGroup[] = [
  {
    group: "Overview",
    rows: [
      {
        module: "Dashboard",
        cells: {
          [Role.Student]: cell(),
          [Role.Alumni]: cell(),
          [Role.Mentor]: cell(),
          [Role.SuperMentor]: cell(["V"], true),
          [Role.ContentAdmin]: cell(["V"]),
          [Role.SystemAdmin]: cell(["V"]),
        },
      },
      {
        module: "Reports & exports",
        cells: {
          [Role.Student]: cell(),
          [Role.Alumni]: cell(),
          [Role.Mentor]: cell(),
          [Role.SuperMentor]: cell(["V"], true),
          [Role.ContentAdmin]: cell(["V", "X"]),
          [Role.SystemAdmin]: cell(["V", "X"]),
        },
      },
    ],
  },
  {
    group: "Community",
    rows: [
      {
        module: "Join requests",
        cells: {
          [Role.Student]: cell(),
          [Role.Alumni]: cell(),
          [Role.Mentor]: cell(),
          [Role.SuperMentor]: cell(["V", "A"], true),
          [Role.ContentAdmin]: cell(["V"]),
          [Role.SystemAdmin]: cell(["V", "A"]),
        },
      },
      {
        module: "Communities & meetings",
        cells: {
          [Role.Student]: cell(),
          [Role.Alumni]: cell(),
          [Role.Mentor]: cell(),
          [Role.SuperMentor]: cell(["V", "E"], true),
          [Role.ContentAdmin]: cell(["V"]),
          [Role.SystemAdmin]: cell(["V", "C", "E", "D"]),
        },
      },
      {
        module: "Cover photos",
        cells: {
          [Role.Student]: cell(),
          [Role.Alumni]: cell(),
          [Role.Mentor]: cell(),
          [Role.SuperMentor]: cell(),
          [Role.ContentAdmin]: cell(),
          [Role.SystemAdmin]: cell(["E"]),
        },
      },
      {
        module: "Institutions",
        cells: {
          [Role.Student]: cell(),
          [Role.Alumni]: cell(),
          [Role.Mentor]: cell(),
          [Role.SuperMentor]: cell(),
          [Role.ContentAdmin]: cell(["V"]),
          [Role.SystemAdmin]: cell(["V", "C", "E", "D"]),
        },
      },
      {
        module: "Members",
        cells: {
          [Role.Student]: cell(),
          [Role.Alumni]: cell(),
          [Role.Mentor]: cell(["V"], true),
          [Role.SuperMentor]: cell(["V"], true),
          [Role.ContentAdmin]: cell(),
          [Role.SystemAdmin]: cell(["V", "C", "E", "D"]),
        },
      },
      {
        module: "Role changes",
        cells: {
          [Role.Student]: cell(),
          [Role.Alumni]: cell(),
          [Role.Mentor]: cell(),
          [Role.SuperMentor]: cell(),
          [Role.ContentAdmin]: cell(),
          [Role.SystemAdmin]: cell(["A"]),
        },
      },
    ],
  },
  {
    group: "Content",
    rows: [
      {
        module: "Content library",
        cells: {
          [Role.Student]: cell(),
          [Role.Alumni]: cell(),
          [Role.Mentor]: cell(),
          [Role.SuperMentor]: cell(),
          [Role.ContentAdmin]: cell(["V", "C", "E", "A", "D"]),
          [Role.SystemAdmin]: cell(["V", "C", "E", "A", "D"]),
        },
      },
      {
        module: "Pathways & badges",
        cells: {
          [Role.Student]: cell(),
          [Role.Alumni]: cell(),
          [Role.Mentor]: cell(),
          [Role.SuperMentor]: cell(),
          [Role.ContentAdmin]: cell(["V", "C", "E", "D"]),
          [Role.SystemAdmin]: cell(["V", "C", "E", "D"]),
        },
      },
      {
        module: "Announcements",
        cells: {
          [Role.Student]: cell(),
          [Role.Alumni]: cell(),
          [Role.Mentor]: cell(),
          [Role.SuperMentor]: cell(["C"], true),
          [Role.ContentAdmin]: cell(["V", "C", "E", "D"]),
          [Role.SystemAdmin]: cell(["V", "C", "E", "D"]),
        },
      },
      {
        module: "Notification rules",
        cells: {
          [Role.Student]: cell(),
          [Role.Alumni]: cell(),
          [Role.Mentor]: cell(),
          [Role.SuperMentor]: cell(),
          [Role.ContentAdmin]: cell(["V", "E"]),
          [Role.SystemAdmin]: cell(["V", "E"]),
        },
      },
    ],
  },
  {
    group: "Safety",
    rows: [
      {
        module: "Moderation level 1",
        cells: {
          [Role.Student]: cell(),
          [Role.Alumni]: cell(),
          [Role.Mentor]: cell(["A"], true),
          [Role.SuperMentor]: cell(["A"], true),
          [Role.ContentAdmin]: cell(["V"]),
          [Role.SystemAdmin]: cell(["V"]),
        },
      },
      {
        module: "Moderation level 2",
        cells: {
          [Role.Student]: cell(),
          [Role.Alumni]: cell(),
          [Role.Mentor]: cell(),
          [Role.SuperMentor]: cell(),
          [Role.ContentAdmin]: cell(["A"]),
          [Role.SystemAdmin]: cell(["A", "D"]),
        },
      },
      {
        module: "Testimony review",
        cells: {
          [Role.Student]: cell(),
          [Role.Alumni]: cell(),
          [Role.Mentor]: cell(),
          [Role.SuperMentor]: cell(),
          [Role.ContentAdmin]: cell(["A"]),
          [Role.SystemAdmin]: cell(["A"]),
        },
      },
      {
        module: "Consents & data requests",
        cells: {
          [Role.Student]: cell(),
          [Role.Alumni]: cell(),
          [Role.Mentor]: cell(),
          [Role.SuperMentor]: cell(),
          [Role.ContentAdmin]: cell(),
          [Role.SystemAdmin]: cell(["A"]),
        },
      },
    ],
  },
  {
    group: "Admin",
    rows: [
      {
        module: "Audit log",
        cells: {
          [Role.Student]: cell(),
          [Role.Alumni]: cell(),
          [Role.Mentor]: cell(),
          [Role.SuperMentor]: cell(),
          [Role.ContentAdmin]: cell(),
          [Role.SystemAdmin]: cell(["V", "X"]),
        },
      },
      {
        module: "Settings",
        cells: {
          [Role.Student]: cell(),
          [Role.Alumni]: cell(),
          [Role.Mentor]: cell(),
          [Role.SuperMentor]: cell(),
          [Role.ContentAdmin]: cell(),
          [Role.SystemAdmin]: cell(["E"]),
        },
      },
    ],
  },
];

export interface StaffAccountInput {
  fullName: string;
  email: string;
  role: Role;
  communityId?: string;
  sendInviteEmail: boolean;
}

export interface StaffAccountResult {
  id: string;
  fullName: string;
  email: string;
  role: Role;
  communityId: string | null;
  createdAt: string;
}

export async function createStaffAccount(
  input: StaffAccountInput,
): Promise<StaffAccountResult> {
  return mutate<StaffAccountResult>("/roles/staff", "POST", input);
}
