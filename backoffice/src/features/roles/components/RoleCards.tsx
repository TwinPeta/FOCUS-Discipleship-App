/**
 * src/features/roles/components/RoleCards.tsx
 *
 * WHAT: One card per role (built-in and custom): where it signs in, what it does, its reach, how many people hold it
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

"use client";

import Link from "next/link";
import { ErrorState } from "@/components/feedback/ErrorState";
import { useRemoteData } from "@/lib/hooks/useRemoteData";
import { ROUTES } from "@/lib/constants/routes";
import { fetchRoles } from "../api";

export function RoleCards() {
  const { data, error, reload } = useRemoteData(fetchRoles);

  if (error) return <ErrorState message={error} onRetry={reload} />;

  return (
    <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
      {(data?.items ?? []).map((r) => (
        <article key={r.id} className="card flex flex-col gap-2.5">
          <div className="flex flex-wrap items-center gap-2.5">
            <h2 className="text-xl font-black">{r.name}</h2>
            <span className="chip">{r.where}</span>
            {!r.builtIn && <span className="chip">Custom</span>}
            {r.edited && r.builtIn && <span className="chip">Edited</span>}
          </div>
          <p className="flex-1 text-[15px] leading-snug">{r.description || "No description yet."}</p>
          <div className="flex items-center justify-between gap-3 text-sm">
            <span>
              Scope: <b>{r.scope}</b>
            </span>
            <span className="font-extrabold">
              {r.people.toLocaleString("en-US")} {r.people === 1 ? "person" : "people"}
            </span>
          </div>
          <div className="flex flex-wrap gap-2.5 pt-1">
            <Link href={ROUTES.roleDetail(r.id)} className="btn btn-secondary btn-sm">
              {r.editable ? "Edit permissions" : "View permissions"}
            </Link>
            <Link href={`${ROUTES.roleMatrix}#${r.slug}`} className="btn btn-secondary btn-sm">
              View in matrix
            </Link>
          </div>
        </article>
      ))}
    </div>
  );
}
