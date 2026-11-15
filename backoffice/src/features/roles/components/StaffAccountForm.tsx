/**
 * src/features/roles/components/StaffAccountForm.tsx
 *
 * WHAT: Create staff account with role and optional community scope
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

"use client";

import { useState, type FormEvent } from "react";
import Link from "next/link";
import { AuditNotice } from "@/components/common/AuditNotice";
import { RoleSelector } from "@/features/members/components/RoleSelector";
import { ROUTES } from "@/lib/constants/routes";
import { ROLE_LABELS } from "@/lib/permissions/roles";
import { Role } from "@/types/enums";
import { createStaffAccount, type StaffAccountResult } from "../queries";
import { useLookups } from "@/lib/hooks/useLookups";

const STAFF_ROLES: Role[] = [
  Role.SuperMentor,
  Role.ContentAdmin,
  Role.SystemAdmin,
];


export function StaffAccountForm() {
  const { communities } = useLookups({ communities: true });
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [role, setRole] = useState<Role>(Role.ContentAdmin);
  const [communityId, setCommunityId] = useState("");
  const [sendInviteEmail, setSendInviteEmail] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [created, setCreated] = useState<StaffAccountResult | null>(null);

  const needsCommunityScope = role === Role.SuperMentor;

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);

    if (!fullName.trim()) {
      setError("Full name is required.");
      return;
    }
    if (!email.trim() || !email.includes("@")) {
      setError("A valid FOCUS staff email address is required.");
      return;
    }
    if (needsCommunityScope && !communityId) {
      setError("Super-mentors must be assigned to a community.");
      return;
    }

    setSubmitting(true);
    try {
      const result = await createStaffAccount({
        fullName: fullName.trim(),
        email: email.trim(),
        role,
        communityId: needsCommunityScope ? communityId : undefined,
        sendInviteEmail,
      });
      setCreated(result);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to create staff account.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="space-y-5 rounded-xl border border-border bg-white p-6"
    >
      <AuditNotice message="Creating a staff account and assigning elevated permissions are permanently recorded in the audit log." />

      {error && (
        <div
          role="alert"
          className="rounded-md border border-rose-200 bg-rose-50 px-3 py-2 text-sm text-rose-800"
        >
          {error}
        </div>
      )}

      {created && (
        <div
          role="status"
          className="rounded-md border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-900"
        >
          <p className="font-semibold">
            Staff account created for {created.fullName}
          </p>
          <p className="mt-1 text-xs">
            Role: {ROLE_LABELS[created.role]} · Email: {created.email}
          </p>
          <div className="mt-2">
            <Link
              href={ROUTES.roles}
              className="text-xs font-medium underline hover:no-underline"
            >
              Back to roles &amp; permissions
            </Link>
          </div>
        </div>
      )}

      <div className="grid gap-4 sm:grid-cols-2">
        <div className="space-y-1.5">
          <label htmlFor="staff-full-name" className="block text-sm font-medium text-foreground">
            Full name
          </label>
          <input
            id="staff-full-name"
            type="text"
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
            placeholder="Full name"
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground"
            required
          />
        </div>

        <div className="space-y-1.5">
          <label htmlFor="staff-email" className="block text-sm font-medium text-foreground">
            Email address
          </label>
          <input
            id="staff-email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="grace@focusuganda.org"
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground"
            required
          />
        </div>
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <div className="space-y-1.5">
          <label htmlFor="staff-role" className="block text-sm font-medium text-foreground">
            Staff role
          </label>
          <RoleSelector
            id="staff-role"
            value={role}
            onChange={setRole}
            roles={STAFF_ROLES}
          />
          <p className="text-xs text-muted">
            Only Super-mentor, Content admin, and System admin accounts can access the backoffice.
          </p>
        </div>

        {needsCommunityScope && (
          <div className="space-y-1.5">
            <label htmlFor="staff-community" className="block text-sm font-medium text-foreground">
              Assigned community
            </label>
            <select
              id="staff-community"
              value={communityId}
              onChange={(e) => setCommunityId(e.target.value)}
              className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground"
              required
            >
              <option value="">Select community…</option>
              {communities.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
            <p className="text-xs text-muted">
              Super-mentors are scoped to their own community (`(own)` in B30).
            </p>
          </div>
        )}
      </div>

      <label className="flex items-start gap-2.5 text-sm text-foreground">
        <input
          type="checkbox"
          checked={sendInviteEmail}
          onChange={(e) => setSendInviteEmail(e.target.checked)}
          className="mt-1 h-4 w-4 rounded border-border"
        />
        <span>
          Send password setup invitation email (Open Question #9: 2FA enforcement policy pending FOCUS confirmation)
        </span>
      </label>

      <div className="flex items-center justify-end gap-3 border-t border-border pt-4">
        <Link
          href={ROUTES.roles}
          className="rounded-md border border-border px-4 py-2 text-sm font-medium text-foreground hover:bg-slate-50"
        >
          Cancel
        </Link>
        <button
          type="submit"
          disabled={submitting}
          className="rounded-md bg-primary px-4 py-2 text-sm font-medium text-white hover:opacity-90 disabled:opacity-50"
        >
          {submitting ? "Creating…" : "Create staff account"}
        </button>
      </div>
    </form>
  );
}
