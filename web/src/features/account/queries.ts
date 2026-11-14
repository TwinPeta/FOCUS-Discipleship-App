/**
 * src/features/account/queries.ts
 *
 * WHAT: Profile, password and sessions queries and mutations
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

import type { StaffSessionDevice } from "@/types/user";

export interface UpdateProfilePayload {
  fullName: string;
  avatarUrl?: string | null;
}

export interface ChangePasswordPayload {
  currentPassword: string;
  newPassword: string;
}

export async function updateProfile(payload: UpdateProfilePayload): Promise<void> {
  const res = await fetch("/api/proxy/account/profile", {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    throw new Error("Failed to update profile");
  }
}

export async function changePassword(payload: ChangePasswordPayload): Promise<void> {
  const res = await fetch("/api/proxy/account/password", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    const body = (await res.json().catch(() => ({}))) as { message?: string };
    throw new Error(body.message || "Failed to change password");
  }
}

export async function fetchActiveSessions(): Promise<StaffSessionDevice[]> {
  const res = await fetch("/api/proxy/account/sessions", {
    cache: "no-store",
  });
  if (!res.ok) {
    throw new Error("Failed to load active sessions");
  }
  const data = (await res.json()) as { sessions?: StaffSessionDevice[] };
  return data.sessions ?? [];
}

export async function revokeSession(sessionId: string): Promise<void> {
  const res = await fetch(`/api/proxy/account/sessions/${sessionId}`, {
    method: "DELETE",
  });
  if (!res.ok) {
    throw new Error("Failed to sign out session");
  }
}
