/**
 * src/types/user.ts
 *
 * WHAT: Session user and member types (until generated from OpenAPI)
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import type { MemberStatus, Role } from "./enums";

export interface SessionUser {
  id: string;
  email: string;
  fullName: string;
  avatarUrl?: string | null;
  role: Role;
  status: MemberStatus;
  /** Primary community ID for community-scoped roles (e.g. Super-mentor) */
  communityId?: string | null;
  /** Optional list of community IDs if a user is scoped to specific communities */
  communityIds?: string[];
  communityName?: string | null;
}

export interface Session {
  user: SessionUser;
  expiresAt?: string;
}

export interface StaffSessionDevice {
  id: string;
  deviceName: string;
  browser?: string;
  os?: string;
  ipAddress?: string;
  location?: string;
  lastActiveAt: string;
  current: boolean;
}
