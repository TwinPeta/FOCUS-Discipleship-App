/**
 * src/app/(backoffice)/members/new/page.tsx
 *
 * WHAT: Add user (B11): role chips and profile form beside help cards for the chosen role and what happens next
 * REQUIREMENTS: FR-05
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Check } from "lucide-react";
import { PageHeader } from "@/components/layout/PageHeader";
import { AddUserForm } from "@/features/members/components/AddUserForm";
import { ROLE_CATALOG } from "@/features/roles/role-catalog";
import { ROUTES } from "@/lib/constants/routes";
import { Role } from "@/types/enums";

function sentences(text: string): string[] {
  return text
    .split(/(?<=\.)\s+/)
    .map((t) => t.trim())
    .filter(Boolean);
}

export default function NewMemberPage() {
  const router = useRouter();
  const [role, setRole] = useState<Role>(Role.Student);
  const info = ROLE_CATALOG.find((r) => r.role === role);

  return (
    <div className="flex flex-col gap-5">
      <PageHeader
        title="Add user"
        description="Create a member account and optionally send a password setup invitation."
        backHref={ROUTES.members}
        backLabel="Back to members"
      />

      <div className="flex flex-wrap items-start gap-4">
        <section className="card flex min-w-0 flex-[999_1_540px] flex-col gap-4">
          <div className="flex flex-wrap gap-2" role="tablist">
            <button type="button" role="tab" aria-selected="true">
              Add one user
            </button>
            <Link
              href={ROUTES.memberImport}
              role="tab"
              aria-selected="false"
              className="tab"
            >
              Import from a file
            </Link>
          </div>
          <AddUserForm onSuccess={() => router.push(ROUTES.members)} onRoleChange={setRole} />
        </section>

        <aside className="flex min-w-0 flex-[1_1_280px] flex-col gap-4 lg:max-w-[360px]">
          {info && (
            <section className="card flex flex-col gap-2">
              <h2 className="eyebrow">Role: {info.name}</h2>
              <ul className="flex flex-col gap-2 text-[15px]">
                {sentences(info.description).map((line) => (
                  <li key={line} className="flex gap-2">
                    <Check className="mt-0.5 h-4 w-4 shrink-0" strokeWidth={3} aria-hidden="true" />
                    {line}
                  </li>
                ))}
              </ul>
            </section>
          )}

          <section className="card flex flex-col gap-2">
            <h2 className="eyebrow">What happens next</h2>
            <ul className="flex flex-col gap-2 text-[15px]">
              {[
                "The user receives an email with a link to set a password.",
                "The account appears in Members with the status “Invited”.",
                "The creation is recorded in the audit log.",
              ].map((line) => (
                <li key={line} className="flex gap-2">
                  <Check className="mt-0.5 h-4 w-4 shrink-0" strokeWidth={3} aria-hidden="true" />
                  {line}
                </li>
              ))}
            </ul>
          </section>

          <section className="rounded-card bg-[#FFF0B8] p-[18px] shadow-card">
            <h2 className="text-base font-black">Many users at once?</h2>
            <p className="mt-1 text-[15px]">
              Use “Import from a file” to add existing members from a spreadsheet (CSV).
            </p>
          </section>
        </aside>
      </div>
    </div>
  );
}
