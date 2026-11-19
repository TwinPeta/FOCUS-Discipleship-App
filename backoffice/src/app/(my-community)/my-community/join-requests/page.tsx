/**
 * src/app/(my-community)/my-community/join-requests/page.tsx
 *
 * WHAT: Own community join requests only
 * REQUIREMENTS: FR-03,FR-04,FR-05
 * SPEC: docs/features/15-super-mentor-view.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useState } from "react";
import { Check, X } from "lucide-react";
import {
  approveOwnJoinRequest,
  declineOwnJoinRequest,
  fetchMyCommunityOverview,
  type OwnJoinRequest,
} from "@/features/my-community/queries";
import { ErrorState } from "@/components/feedback/ErrorState";

export default function MyCommunityJoinRequestsPage() {
  const [communityName, setCommunityName] = useState("");
  const [requests, setRequests] = useState<OwnJoinRequest[]>([]);

  const [loadError, setLoadError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    fetchMyCommunityOverview().then((res) => {
      if (!active) return;
      setCommunityName(res.communityName);
      setRequests(res.pendingRequests);
    })
      .catch((e: unknown) => {
        if (active) setLoadError(e instanceof Error ? e.message : "Failed to load");
      });
    return () => {
      active = false;
    };
  }, []);

  async function handleApprove(id: string) {
    await approveOwnJoinRequest(id);
    setRequests((prev) => prev.filter((r) => r.id !== id));
  }

  async function handleDecline(id: string) {
    await declineOwnJoinRequest(id);
    setRequests((prev) => prev.filter((r) => r.id !== id));
  }

  return (
    <div className="flex flex-col gap-5">
      {loadError && <ErrorState message={loadError} />}
      <div>
        <h1 className="text-[34px] leading-[1.05]">
          Join requests — {communityName || "your caregroup"}
        </h1>
        <p className="mt-1 text-sm text-muted">
          Approve or decline students requesting to join your caregroup.
        </p>
      </div>

      {requests.length === 0 ? (
        <div className="rounded-xl border border-border bg-white p-8 text-center text-sm text-muted">
          No pending join requests for {communityName || "your caregroup"}.
        </div>
      ) : (
        <div className="overflow-x-auto rounded-xl border border-border bg-white">
          <table className="w-full border-collapse text-left text-sm">
            <thead>
              <tr className="border-b border-border bg-blue-tint text-xs font-semibold uppercase tracking-wide text-muted">
                <th className="px-4 py-3">Student</th>
                <th className="px-4 py-3">Note</th>
                <th className="px-4 py-3">Requested</th>
                <th className="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {requests.map((req) => (
                <tr key={req.id}>
                  <td className="px-4 py-3">
                    <div className="font-medium text-foreground">{req.studentName}</div>
                    <div className="text-xs text-muted">{req.email}</div>
                    {req.communityName && <div className="text-xs text-muted">{req.communityName}</div>}
                  </td>
                  <td className="px-4 py-3 text-xs text-muted">
                    {req.note ?? "—"}
                  </td>
                  <td className="px-4 py-3 text-xs text-muted">{req.requestedAt}</td>
                  <td className="px-4 py-3 text-right">
                    <div className="inline-flex items-center gap-2">
                      <button
                        type="button"
                        onClick={() => handleApprove(req.id)}
                        className="inline-flex items-center gap-1 rounded-md bg-emerald-600 px-2.5 py-1.5 text-xs font-medium text-white hover:bg-emerald-700"
                      >
                        <Check className="h-3.5 w-3.5" aria-hidden="true" />
                        <span>Approve</span>
                      </button>
                      <button
                        type="button"
                        onClick={() => handleDecline(req.id)}
                        className="inline-flex items-center gap-1 rounded-md border border-border bg-white px-2.5 py-1.5 text-xs font-medium text-foreground hover:bg-blue-tint"
                      >
                        <X className="h-3.5 w-3.5" aria-hidden="true" />
                        <span>Decline</span>
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
