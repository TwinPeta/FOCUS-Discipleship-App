/**
 * src/lib/permissions/matrix.ts
 *
 * WHAT: Design matrix (C consult, M modify, V validate, A administer) as data; UI gating only
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

import { Role } from "@/types/enums";

export type PermissionResource =
  | "content"
  | "pathways"
  | "community"
  | "coverPhotos"
  | "joinRequests"
  | "communitySpaces"
  | "reports"
  | "dashboards"
  | "members";

export type PermissionAction =
  | "consult"
  | "modify"
  | "validate"
  | "administer"
  | "moderateL1"
  | "reviewL1"
  | "reviewL2"
  | "report";

export interface ResourcePermissionRule {
  actions: PermissionAction[];
  ownOnly?: boolean;
}

export type RolePermissionMap = Partial<Record<PermissionResource, ResourcePermissionRule>>;

/**
 * Proposed permission matrix from design board B9 (docs/roles-permissions.md).
 * The backend enforces every rule; this mirrors it for UI gating only.
 */
export const PERMISSION_MATRIX: Record<Role, RolePermissionMap> = {
  [Role.Student]: {
    content: { actions: ["consult"] },
    pathways: { actions: ["consult"] },
    community: { actions: ["consult"] },
    communitySpaces: { actions: ["consult", "modify"] },
    reports: { actions: ["report"] },
  },
  [Role.Mentor]: {
    content: { actions: ["consult"] },
    pathways: { actions: ["consult"] },
    community: { actions: ["consult"] },
    communitySpaces: { actions: ["moderateL1"] },
    reports: { actions: ["reviewL1"] },
    dashboards: { actions: ["consult"], ownOnly: true },
  },
  [Role.SuperMentor]: {
    content: { actions: ["consult"] },
    pathways: { actions: ["consult"] },
    community: { actions: ["consult", "modify"], ownOnly: true },
    joinRequests: { actions: ["consult", "validate"], ownOnly: true },
    communitySpaces: { actions: ["moderateL1"], ownOnly: true },
    reports: { actions: ["reviewL1"], ownOnly: true },
    dashboards: { actions: ["consult"], ownOnly: true },
    members: { actions: ["consult"], ownOnly: true },
  },
  [Role.Alumni]: {
    content: { actions: ["consult"] },
    pathways: { actions: ["consult"] },
  },
  [Role.ContentAdmin]: {
    content: { actions: ["consult", "modify", "validate"] },
    pathways: { actions: ["consult", "modify", "validate"] },
    community: { actions: ["consult"] },
    coverPhotos: { actions: ["consult", "modify"] },
    joinRequests: { actions: ["consult"] },
    communitySpaces: { actions: ["consult"] },
    reports: { actions: ["consult", "reviewL2"] },
    dashboards: { actions: ["consult"] },
  },
  [Role.SystemAdmin]: {
    content: { actions: ["administer"] },
    pathways: { actions: ["administer"] },
    community: { actions: ["administer"] },
    coverPhotos: { actions: ["administer"] },
    joinRequests: { actions: ["administer"] },
    communitySpaces: { actions: ["administer"] },
    reports: { actions: ["administer"] },
    dashboards: { actions: ["administer"] },
    members: { actions: ["administer"] },
  },
};
