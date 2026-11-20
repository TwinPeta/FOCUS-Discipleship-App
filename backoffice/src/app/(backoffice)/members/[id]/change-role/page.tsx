/**
 * src/app/(backoffice)/members/[id]/change-role/page.tsx
 *
 * WHAT: Change a member's role (B33): new role chips, reason for the audit log, and what the person gains and keeps
 * REQUIREMENTS: FR-05, FR-07
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

"use client";

import { use, useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Check } from "lucide-react";
import { getInitials } from "@/components/common/InitialsAvatar";
import { PageHeader } from "@/components/layout/PageHeader";
import { RoleSelector } from "@/features/members/components/RoleSelector";
import { fetchRoles } from "@/features/roles/api";
import { useRemoteData } from "@/lib/hooks/useRemoteData";
import { changeMemberRole, fetchMember } from "@/features/members/queries";
import type { Member } from "@/features/members/schemas";
import { ROLE_CATALOG } from "@/features/roles/role-catalog";
import { ROUTES } from "@/lib/constants/routes";
import { ROLE_LABELS } from "@/lib/permissions/roles";
import type { Role } from "@/types/enums";

export default function ChangeRolePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const router = useRouter();
  const [member, setMember] = useState<Member | null>(null);
  const [role, setRole] = useState<Role | null>(null);
  const [customId, setCustomId] = useState<string | null>(null);
  const { data: rolesData } = useRemoteData(fetchRoles);
  const customRoles = (rolesData?.items ?? []).filter((r) => !r.builtIn);
  const [reason, setReason] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    fetchMember(id)
      .then((m) => {
        setMember(m);
        setRole(m.role);
        setCustomId(m.customRoleId ?? null);
      })
      .catch(() => setError("Could not load this member."));
  }, [id]);

  const current = member && ROLE_CATALOG.find((r) => r.role === member.role);
  const customPick = customRoles.find((r) => r.id === customId);
  const next = role && ROLE_CATALOG.find((r) => r.role === (customPick ? customPick.base : role));
  const currentExtras = current?.appExtras ?? [];
  const nextExtras = next?.appExtras ?? [];
  const gain = nextExtras.filter((x) => !currentExtras.includes(x));
  const lose = currentExtras.filter((x) => !nextExtras.includes(x));
  const keep = nextExtras.filter((x) => currentExtras.includes(x));
  const changed = Boolean(member && role && (role !== member.role || (customId ?? null) !== (member.customRoleId ?? null)));

  async function confirm() {
    if (!member || !role || !changed) return;
    setSaving(true);
    setError(null);
    try {
      await changeMemberRole(member.id, customId ? { customRoleId: customId } : role, reason);
      router.push(ROUTES.members);
    } catch {
      setError("Could not change the role. You cannot change your own role.");
      setSaving(false);
    }
  }

  return (
    <div className="flex flex-col gap-5">
      <PageHeader title="Change role" backHref={ROUTES.members} backLabel="Back to members" />

      {error && (
        <p role="alert" className="rounded-lg bg-danger-soft px-3.5 py-2.5 text-sm font-semibold text-danger">
          {error}
        </p>
      )}

      {member && role && (
        <div className="flex flex-wrap items-start gap-4">
          <section className="card flex min-w-0 flex-[999_1_540px] flex-col gap-4">
            <div className="flex items-center gap-3">
              <span className="avatar h-12 w-12 text-base">{getInitials(member.fullName)}</span>
              <div className="min-w-0 flex-1">
                <p className="truncate text-lg font-black">{member.fullName}</p>
                <p className="truncate text-[13px] opacity-80">
                  @{member.username} · {member.institutionName}
                </p>
              </div>
              <span className="chip">Current: {member.customRoleName ?? ROLE_LABELS[member.role]}</span>
            </div>

            <div className="flex flex-col gap-2">
              <h2 className="text-[13px] font-extrabold">New role</h2>
              <RoleSelector
                variant="chips"
                id="new-role"
                value={customId ? ("" as Role) : role}
                onChange={(r) => {
                  setRole(r);
                  setCustomId(null);
                }}
              />
              {customRoles.length > 0 && (
                <div role="radiogroup" aria-label="Custom roles" className="flex flex-wrap gap-2.5">
                  {customRoles.map((r) => {
                    const selected = customId === r.id;
                    return (
                      <button
                        key={r.id}
                        type="button"
                        role="radio"
                        aria-checked={selected}
                        onClick={() => {
                          setCustomId(r.id);
                          setRole(r.base as Role);
                        }}
                        className={`inline-flex min-h-[40px] items-center gap-2 rounded-full border-2 border-ink px-3.5 text-base ${selected ? "bg-grad-yellow font-bold" : "bg-white font-semibold"}`}
                      >
                        <span className="grid h-[18px] w-[18px] place-items-center rounded-full border-2 border-ink bg-white">
                          {selected && <span className="h-2 w-2 rounded-full bg-ink" />}
                        </span>
                        {r.name}
                      </button>
                    );
                  })}
                </div>
              )}
            </div>

            <dl className="divide-y-[1.5px] divide-border text-[15px]">
              {[
                ["Caregroup", member.communityName ?? "General caregroup only"],
                ["Campus", member.institutionName || "—"],
                ["Takes effect", "Right away"],
              ].map(([label, value]) => (
                <div key={label} className="flex justify-between gap-3 py-2">
                  <dt>{label}</dt>
                  <dd className="font-extrabold">{value}</dd>
                </div>
              ))}
            </dl>

            <div className="flex flex-col gap-1.5">
              <label htmlFor="role-reason" className="text-[13px] font-extrabold">
                Reason (kept in the audit log)
              </label>
              <textarea
                id="role-reason"
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                maxLength={500}
                className="w-full px-3.5 py-2"
              />
            </div>

            <div className="flex flex-wrap gap-2.5">
              <button type="button" onClick={confirm} disabled={!changed || saving} className="btn btn-primary">
                {saving ? "Saving…" : "Confirm change"}
              </button>
              <Link href={ROUTES.members} className="btn btn-secondary">
                Cancel
              </Link>
            </div>
          </section>

          <aside className="flex min-w-0 flex-[1_1_280px] flex-col gap-4 lg:max-w-[360px]">
            {[
              { title: "They will gain", items: gain },
              { title: "They keep", items: keep },
              { title: "They will lose", items: lose },
            ]
              .filter((g) => g.items.length > 0)
              .map((g) => (
                <section key={g.title} className="card flex flex-col gap-2">
                  <h2 className="eyebrow">{g.title}</h2>
                  <ul className="flex flex-col gap-2 text-[15px]">
                    {g.items.map((x) => (
                      <li key={x} className="flex gap-2">
                        <Check className="mt-0.5 h-4 w-4 shrink-0" strokeWidth={3} aria-hidden="true" />
                        {x}
                      </li>
                    ))}
                  </ul>
                </section>
              ))}
            <p className="notice">
              <span>
                A person has one role at a time. See the full list in the{" "}
                <Link href={ROUTES.roleMatrix} className="font-bold underline">
                  permissions matrix
                </Link>
                .
              </span>
            </p>
          </aside>
        </div>
      )}
    </div>
  );
}
