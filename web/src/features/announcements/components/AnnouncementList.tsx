/**
 * src/features/announcements/components/AnnouncementList.tsx
 *
 * WHAT: List of announcements with audience, status and timing
 * REQUIREMENTS: -
 * SPEC: docs/features/09-announcements-stories.md
 * STATUS: implemented
 */

import { Calendar, Globe, Users } from "lucide-react";
import type { Announcement } from "../queries";

export function AnnouncementList({ announcements }: { announcements: Announcement[] }) {
  if (announcements.length === 0) {
    return (
      <div className="rounded-xl border border-border bg-white p-8 text-center text-sm text-muted">
        No announcements posted yet. Use the composer above to share an update.
      </div>
    );
  }

  return (
    <div className="space-y-3">
      <h3 className="text-sm font-semibold text-foreground">Recent Announcements</h3>
      <div className="divide-y divide-border rounded-xl border border-border bg-white shadow-sm">
        {announcements.map((ann) => (
          <article key={ann.id} className="p-4 space-y-2 hover:bg-slate-50/50">
            <div className="flex flex-wrap items-center justify-between gap-2 text-xs">
              <div className="flex items-center gap-2">
                <span
                  className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 font-medium ${
                    ann.audienceType === "all"
                      ? "bg-sky-50 text-sky-800"
                      : "bg-purple-50 text-purple-800"
                  }`}
                >
                  {ann.audienceType === "all" ? (
                    <Globe className="h-3 w-3" />
                  ) : (
                    <Users className="h-3 w-3" />
                  )}
                  <span>{ann.communityName}</span>
                </span>

                <span
                  className={`inline-flex rounded-full px-2 py-0.5 font-medium capitalize ${
                    ann.status === "published"
                      ? "bg-emerald-50 text-emerald-800"
                      : "bg-amber-50 text-amber-800"
                  }`}
                >
                  {ann.status}
                </span>
              </div>

              <div className="flex items-center gap-1.5 text-muted">
                <Calendar className="h-3.5 w-3.5" />
                <span>
                  {ann.scheduledFor
                    ? `Scheduled for: ${new Date(ann.scheduledFor).toLocaleString()}`
                    : `Posted: ${ann.createdAt}`}
                </span>
              </div>
            </div>

            <h4 className="text-sm font-semibold text-foreground">{ann.title}</h4>
            <p className="text-xs text-foreground/80 leading-relaxed whitespace-pre-line">
              {ann.message}
            </p>

            <div className="text-[11px] text-muted pt-1">
              Author: {ann.authorName}
            </div>
          </article>
        ))}
      </div>
    </div>
  );
}
