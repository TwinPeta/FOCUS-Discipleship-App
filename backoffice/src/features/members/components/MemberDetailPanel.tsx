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
import Link from "next/link";
import { X } from "lucide-react";
import { ROUTES } from "@/lib/constants/routes";
import { getInitials } from "@/components/common/InitialsAvatar";
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

  const rows: [string, string][] = [
    ["Email", member.email],
    ["Phone", member.phone ?? "—"],
    ["Birthdate", member.birthdate ?? "—"],
    ["Country", member.country ?? "—"],
    ["Campus", member.institutionName || "—"],
    ["Year", member.yearOfStudy ? `Year ${member.yearOfStudy}` : "—"],
    ["Local church", member.localChurch ?? "—"],
  ];

  return (
    <aside className="card flex min-w-0 flex-[1_1_320px] flex-col gap-3 lg:sticky lg:top-4 lg:max-w-[360px]">
      <div className="flex items-center gap-3.5">
        <div className="avatar h-16 w-16 shrink-0 bg-[#FFCB3D] bg-none text-lg text-ink" role="img" aria-label={`Avatar for ${member.fullName}`}>
          {getInitials(member.fullName)}
        </div>
        <div className="min-w-0 flex-1">
          <h2 className="truncate text-[22px] font-black leading-tight">{member.fullName}</h2>
          <p className="text-sm opacity-80">@{member.username}</p>
          <div className="mt-1.5 flex flex-wrap gap-1.5">
            <span className="chip">{member.customRoleName ?? ROLE_LABELS[member.role]}</span>
            {member.isMinor && <MinorBadge consentStatus={member.guardianConsentStatus} />}
          </div>
        </div>
        {onClose && (
          <button type="button" onClick={onClose} aria-label="Close details" className="self-start rounded-md p-1 hover:bg-blue-soft">
            <X className="h-5 w-5" aria-hidden="true" />
          </button>
        )}
      </div>

      <dl className="divide-y-[1.5px] divide-border text-[15px]">
        {rows.map(([label, value]) => (
          <div key={label} className="flex justify-between gap-3 py-2">
            <dt>{label}</dt>
            <dd className="min-w-0 break-words text-right font-extrabold">{value}</dd>
          </div>
        ))}
      </dl>

      {member.isMinor && (
        <div className="rounded-xl bg-[#FFF8E6] p-3 text-sm">
          <p className="eyebrow mb-1">Parent or guardian</p>
          {member.guardian?.name ? (
            <dl className="space-y-0.5">
              <div className="flex justify-between gap-2">
                <dt>Name</dt>
                <dd className="font-extrabold">
                  {member.guardian.name}
                  {member.guardian.relationship ? ` (${member.guardian.relationship})` : ""}
                </dd>
              </div>
              <div className="flex justify-between gap-2">
                <dt>Phone</dt>
                <dd className="font-extrabold">{member.guardian.phone ?? "—"}</dd>
              </div>
              <div className="flex justify-between gap-2">
                <dt>Email</dt>
                <dd className="font-extrabold">{member.guardian.email ?? "—"}</dd>
              </div>
            </dl>
          ) : (
            <p>Not given yet in the app.</p>
          )}
        </div>
      )}

      <div>
        <p className="eyebrow mb-1.5">Caregroups</p>
        <div className="flex flex-wrap gap-1.5">
          <span className="chip">General caregroup</span>
          {member.communityName && <span className="chip">{member.communityName}</span>}
        </div>
      </div>

      {member.participation && (
        <div>
          <p className="eyebrow mb-1">Participation</p>
          <p className="text-[15px]">
            {member.participation.resourcesCompleted} resources completed · {member.participation.meetingsAttended} meetings attended · {member.participation.badgesEarned} badges
          </p>
        </div>
      )}

      <AuditNotice message="Viewing member contact details and changing roles or status are recorded in the audit log." />

      <div className="flex flex-wrap gap-2.5">
        <Link href={ROUTES.memberChangeRole(member.id)} className="btn btn-primary">
          Change role
        </Link>
        <button type="button" onClick={() => setMoveDialogOpen(true)} className="btn btn-secondary">
          Move caregroup
        </button>
        <button type="button" onClick={() => setSuspendDialogOpen(true)} className="btn btn-secondary">
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
