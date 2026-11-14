/**
 * src/features/my-community/components/PendingRequestsMini.tsx
 *
 * WHAT: Pending requests with approve and decline
 * REQUIREMENTS: FR-03,FR-04,FR-05
 * SPEC: docs/features/15-super-mentor-view.md
 * STATUS: implemented
 */

"use client";

import Link from "next/link";
import { ArrowRight, Check, X } from "lucide-react";
import { ROUTES } from "@/lib/constants/routes";
import type { OwnJoinRequest } from "../queries";

interface PendingRequestsMiniProps {
  requests: OwnJoinRequest[];
  onApprove: (id: string) => void;
  onDecline: (id: string) => void;
}

export function PendingRequestsMini({
  requests,
  onApprove,
  onDecline,
}: PendingRequestsMiniProps) {
  return (
    <section className="space-y-3 rounded-xl border border-border bg-white p-5">
      <div className="flex items-center justify-between gap-2">
        <div>
          <h2 className="text-base font-semibold text-foreground">
            Pending join requests
          </h2>
          <p className="text-xs text-muted">
            Students requesting to join your community.
          </p>
        </div>
        <Link
          href={ROUTES.myCommunityJoinRequests}
          className="inline-flex items-center gap-1 text-xs font-medium text-primary hover:underline"
        >
          <span>See all</span>
          <ArrowRight className="h-3.5 w-3.5" aria-hidden="true" />
        </Link>
      </div>

      {requests.length === 0 ? (
        <p className="text-sm text-muted">No pending join requests right now.</p>
      ) : (
        <div className="divide-y divide-border rounded-lg border border-border">
          {requests.map((req) => (
            <div
              key={req.id}
              className="flex flex-wrap items-center justify-between gap-3 px-4 py-3 text-sm"
            >
              <div>
                <p className="font-medium text-foreground">{req.studentName}</p>
                <p className="text-xs text-muted">
                  {req.email} · Requested {req.requestedAt}
                </p>
              </div>
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={() => onApprove(req.id)}
                  className="inline-flex items-center gap-1 rounded-md bg-emerald-600 px-2.5 py-1.5 text-xs font-medium text-white hover:bg-emerald-700"
                >
                  <Check className="h-3.5 w-3.5" aria-hidden="true" />
                  <span>Approve</span>
                </button>
                <button
                  type="button"
                  onClick={() => onDecline(req.id)}
                  className="inline-flex items-center gap-1 rounded-md border border-border bg-white px-2.5 py-1.5 text-xs font-medium text-foreground hover:bg-slate-50"
                >
                  <X className="h-3.5 w-3.5" aria-hidden="true" />
                  <span>Decline</span>
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </section>
  );
}
