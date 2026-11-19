/**
 * src/features/roles/role-catalog.ts
 *
 * WHAT: The six roles with what each one does, where it signs in and how far its reach goes (B9, B32)
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

import { Role } from "@/types/enums";

export interface RoleInfo {
  role: Role;
  slug: string;
  name: string;
  where: string;
  description: string;
  scope: string;
  /** Where people with this role sign in */
  app: boolean;
  backoffice: boolean;
  backofficeLimited?: boolean;
  appExtras?: string[];
}

export const ROLE_CATALOG: RoleInfo[] = [
  {
    role: Role.Student,
    slug: "student",
    name: "Student",
    where: "App",
    description:
      "Browses content, joins the general caregroup and one specific caregroup, posts, prays, shares testimonies and writes to members.",
    scope: "Own account",
    app: true,
    backoffice: false,
  },
  {
    role: Role.Alumni,
    slug: "alumni",
    name: "Alumni",
    where: "App",
    description: "Former student. Reads content and joins conversations. Can be invited later to become a mentor.",
    scope: "Own account",
    app: true,
    backoffice: false,
  },
  {
    role: Role.Mentor,
    slug: "mentor",
    name: "Mentor",
    where: "App",
    description:
      "Helps the super-mentor guide a caregroup. Can hide or warn on content reported in the caregroup (level 1).",
    scope: "Own caregroup",
    app: true,
    backoffice: false,
    appExtras: ["Hide or warn on content"],
  },
  {
    role: Role.SuperMentor,
    slug: "super-mentor",
    name: "Super-mentor",
    where: "App + Backoffice (limited)",
    description:
      "Leads a caregroup. Welcomes new members, edits meeting details, follows up members, handles level 1 reports and can delete testimonies.",
    scope: "Own caregroup",
    app: true,
    backoffice: true,
    backofficeLimited: true,
    appExtras: ["Manage tab in the caregroup", "Welcome new members", "Hide or warn on content"],
  },
  {
    role: Role.ContentAdmin,
    slug: "content-admin",
    name: "Content admin",
    where: "Backoffice",
    description: "Creates, validates and publishes content, pathways, badges and announcements. Reviews testimonies.",
    scope: "All campuses",
    app: false,
    backoffice: true,
  },
  {
    role: Role.SystemAdmin,
    slug: "system-admin",
    name: "System admin",
    where: "Backoffice",
    description:
      "Manages users, roles, caregroups, campuses, settings, data requests and the audit log.",
    scope: "All campuses",
    app: false,
    backoffice: true,
  },
];

export function roleBySlug(slug: string): RoleInfo | undefined {
  return ROLE_CATALOG.find((r) => r.slug === slug);
}
