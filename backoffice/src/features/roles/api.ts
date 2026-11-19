/**
 * src/features/roles/api.ts
 *
 * WHAT: Roles and their permission matrix from the API: list, create, edit, reset and delete (custom roles)
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

import { apiClient } from "@/lib/api/client";
import { mutate } from "@/lib/api/mutate";
import type { PermissionCode } from "./queries";

export interface MatrixCellDef {
  codes: PermissionCode[];
  own?: boolean;
}
export type RoleMatrix = Record<string, MatrixCellDef>;

export interface RoleDef {
  id: string;
  slug: string;
  name: string;
  description: string;
  builtIn: boolean;
  /** Built-in role the people with this role sign in as */
  base: string;
  editable: boolean;
  renamable: boolean;
  deletable: boolean;
  edited: boolean;
  where: string;
  scope: string;
  people: number;
  matrix: RoleMatrix;
}

export interface RolesResponse {
  items: RoleDef[];
  modules: string[];
}

export const MODULE_HINTS: Record<string, string> = {
  "Caregroups & meetings": "Info, schedule, team",
  Members: "Personal data is audited",
  "Content library": "Author and validator recorded",
  "Moderation level 1": "Hide, warn, escalate",
  "Moderation level 2": "Suspend, delete",
};

export const fetchRoles = () => apiClient<RolesResponse>("/roles");
export const fetchRoleDef = (id: string) => apiClient<RoleDef>(`/roles/${id}`);

export interface RoleInputValues {
  name?: string;
  description?: string;
  base?: "CONTENT_ADMIN" | "SUPER_MENTOR";
  matrix?: RoleMatrix;
}
export const createRole = (v: RoleInputValues) => mutate<RoleDef>("/roles", "POST", v, "create the role");
export const updateRole = (id: string, v: RoleInputValues) => mutate<RoleDef>(`/roles/${id}`, "PUT", v, "save the role");
export const resetRole = (id: string) => mutate<RoleDef>(`/roles/${id}/reset`, "POST", undefined, "reset the role");
export const deleteRole = (id: string) => mutate(`/roles/${id}`, "DELETE", undefined, "delete the role");
