/**
 * src/features/members/components/MemberDetailPanel.tsx
 *
 * WHAT: Member detail side panel showing personal data, AuditNotice, minor flag, participation, and admin actions
 * REQUIREMENTS: FR-07, FR-10
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import { AuditNotice } from "@/components/common/AuditNotice";
import {
  changeMemberRole,
  moveMemberCommunity,
  suspendMember,
} from "@/features/members/queries";
import type { Member } from "@/features/members/schemas";
import { ROLE_LABELS } from "@/lib/permissions/roles";
import type { Role } from "@/types/enums";
import { ChangeRoleDialog } from "./ChangeRoleDialog";
import { MinorBadge } from "./MinorBadge";
import { MoveCommunityDialog } from "./MoveCommunityDialog";
import { SuspendDialog } from "./SuspendDialog";
import { useLookups } from "@/lib/hooks/useLookups";

interface MemberDetailPanelProps {
  member: Member;
  communities?: { id: string; name: string }[];
  onUpdated?: (updated: Member) => void;
  onClose?: () => void;
}

export function MemberDetailPanel({
  member,
  communities: communitiesProp,
  onUpdated,
  onClose,
}: MemberDetailPanelProps) {
  const lookups = useLookups({ communities: true });
  const communities = communitiesProp ?? lookups.communities;
  const [roleDialogOpen, setRoleDialogOpen] = useState(false);
  const [moveDialogOpen, setMoveDialogOpen] = useState(false);
  const [suspendDialogOpen, setSuspendDialogOpen] = useState(false);

  async function handleRoleChange(role: Role) {
    const updated = await changeMemberRole(member.id, role);
    onUpdated?.(updated);
  }

  async function handleMoveCommunity(communityId: string) {
    const updated = await moveMemberCommunity(member.id, communityId);
    onUpdated?.(updated);
  }

  async function handleSuspend(reason: string) {
    const updated = await suspendMember(member.id, reason);
    onUpdated?.(updated);
  }

  return (
    <aside className="space-y-5 rounded-card border border-border bg-white p-5">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h2 className="text-base font-semibold text-foreground">{member.fullName}</h2>
          <p className="text-xs text-muted-foreground">@{member.username}</p>
        </div>
        {onClose && (
          <button
            type="button"
            onClick={onClose}
            className="text-xs text-muted-foreground hover:text-foreground"
          >
            Close
          </button>
        )}
      </div>

      <AuditNotice message="Viewing member contact details and changing roles or status are recorded in the audit log." />

      {member.isMinor && <MinorBadge consentStatus={member.guardianConsentStatus} />}

      <dl className="space-y-2 text-sm">
        <div className="flex justify-between gap-2">
          <dt className="text-muted-foreground">Email</dt>
          <dd className="font-medium text-foreground">{member.email}</dd>
        </div>
        <div className="flex justify-between gap-2">
          <dt className="text-muted-foreground">Phone</dt>
          <dd className="text-foreground">{member.phone ?? "—"}</dd>
        </div>
        <div className="flex justify-between gap-2">
          <dt className="text-muted-foreground">Birthdate</dt>
          <dd className="text-foreground">{member.birthdate ?? "—"}</dd>
        </div>
        <div className="flex justify-between gap-2">
          <dt className="text-muted-foreground">Role</dt>
          <dd className="font-medium text-foreground">{ROLE_LABELS[member.role]}</dd>
        </div>
        <div className="flex justify-between gap-2">
          <dt className="text-muted-foreground">Institution</dt>
          <dd className="text-foreground">{member.institutionName}</dd>
        </div>
        <div className="flex justify-between gap-2">
          <dt className="text-muted-foreground">Community</dt>
          <dd className="text-foreground">{member.communityName ?? "General only"}</dd>
        </div>
      </dl>

      {member.participation && (
        <div className="grid grid-cols-3 gap-2 rounded-md border border-border bg-surface p-3 text-center text-xs">
          <div>
            <p className="text-base font-bold text-foreground">
              {member.participation.resourcesCompleted}
            </p>
            <p className="text-muted-foreground">Resources</p>
          </div>
          <div>
            <p className="text-base font-bold text-foreground">
              {member.participation.meetingsAttended}
            </p>
            <p className="text-muted-foreground">Meetings</p>
          </div>
          <div>
            <p className="text-base font-bold text-foreground">
              {member.participation.badgesEarned}
            </p>
            <p className="text-muted-foreground">Badges</p>
          </div>
        </div>
      )}

      <div className="flex flex-wrap gap-2 pt-2">
        <button
          type="button"
          onClick={() => setRoleDialogOpen(true)}
          className="rounded-md border border-border px-3 py-1.5 text-xs font-medium hover:bg-surface"
        >
          Change role
        </button>
        <button
          type="button"
          onClick={() => setMoveDialogOpen(true)}
          className="rounded-md border border-border px-3 py-1.5 text-xs font-medium hover:bg-surface"
        >
          Move community
        </button>
        <button
          type="button"
          onClick={() => setSuspendDialogOpen(true)}
          className="rounded-md border border-red-300 px-3 py-1.5 text-xs font-medium text-red-700 hover:bg-red-50"
        >
          Suspend
        </button>
      </div>

      <ChangeRoleDialog
        open={roleDialogOpen}
        memberName={member.fullName}
        currentRole={member.role}
        onConfirm={handleRoleChange}
        onClose={() => setRoleDialogOpen(false)}
      />
      <MoveCommunityDialog
        open={moveDialogOpen}
        memberName={member.fullName}
        currentCommunityId={member.communityId}
        communities={communities}
        onConfirm={handleMoveCommunity}
        onClose={() => setMoveDialogOpen(false)}
      />
      <SuspendDialog
        open={suspendDialogOpen}
        memberName={member.fullName}
        onConfirm={handleSuspend}
        onClose={() => setSuspendDialogOpen(false)}
      />
    </aside>
  );
}
