/**
 * src/app/(my-community)/my-community/moderation/page.tsx
 *
 * WHAT: Level 1 moderation for own community
 * REQUIREMENTS: FR-03,FR-04,FR-05
 * SPEC: docs/features/15-super-mentor-view.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useState } from "react";
import { ArrowUpRight, CheckCircle2 } from "lucide-react";
import { AuditNotice } from "@/components/common/AuditNotice";
import {
  fetchMyCommunityOverview,
  resolveOwnReportL1,
  type OwnCommunityReport,
} from "@/features/my-community/queries";
import { ErrorState } from "@/components/feedback/ErrorState";

export default function MyCommunityModerationPage() {
  const [communityName, setCommunityName] = useState("");
  const [reports, setReports] = useState<OwnCommunityReport[]>([]);

  const [loadError, setLoadError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    fetchMyCommunityOverview().then((res) => {
      if (!active) return;
      setCommunityName(res.communityName);
      setReports(res.reports);
    })
      .catch((e: unknown) => {
        if (active) setLoadError(e instanceof Error ? e.message : "Failed to load");
      });
    return () => {
      active = false;
    };
  }, []);

  async function handleDecision(id: string, decision: "dismissed" | "escalated") {
    await resolveOwnReportL1(id, decision);
    setReports((prev) =>
      prev.map((r) => (r.id === id ? { ...r, status: decision } : r)),
    );
  }

  return (
    <div className="flex flex-col gap-5">
      {loadError && <ErrorState message={loadError} />}
      <div>
        <h1 className="text-[34px] leading-[1.05]">
          Moderation (Level 1) — {communityName || "your caregroup"}
        </h1>
        <p className="mt-1 text-sm text-muted">
          Review reports within your community. Severe violations can be escalated to Level 2 admins (suspensions and deletions require L2/System admin).
        </p>
      </div>

      <AuditNotice message="All Level 1 moderation decisions and escalations are recorded in the audit log." />

      <div className="space-y-3">
        {reports.map((report) => (
          <div
            key={report.id}
            className="flex flex-wrap items-center justify-between gap-4 rounded-xl border border-border bg-white p-4"
          >
            <div className="space-y-1">
              <div className="flex items-center gap-2">
                <span className="font-medium text-foreground">
                  {report.targetSummary}
                </span>
                <span
                  className={`rounded-full px-2 py-0.5 text-xs font-medium capitalize ${
                    report.status === "open"
                      ? "bg-primary-soft text-ink"
                      : report.status === "escalated"
                        ? "bg-danger-soft text-danger"
                        : "bg-blue-tint text-muted"
                  }`}
                >
                  {report.status}
                </span>
              </div>
              <p className="text-xs text-muted">
                Reason: {report.reason} · Reported by {report.reportedBy} on {report.createdAt}
              </p>
            </div>

            {report.status === "open" && (
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={() => handleDecision(report.id, "dismissed")}
                  className="inline-flex items-center gap-1 rounded-md border border-border bg-white px-3 py-1.5 text-xs font-medium text-foreground hover:bg-blue-tint"
                >
                  <CheckCircle2 className="h-3.5 w-3.5" aria-hidden="true" />
                  <span>Dismiss</span>
                </button>
                <button
                  type="button"
                  onClick={() => handleDecision(report.id, "escalated")}
                  className="inline-flex items-center gap-1 rounded-md bg-rose-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-rose-700"
                >
                  <ArrowUpRight className="h-3.5 w-3.5" aria-hidden="true" />
                  <span>Escalate to L2</span>
                </button>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
