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
      <div className="card p-8 text-center text-sm text-muted-foreground">
        No announcements posted yet. Use the composer above to share an update.
      </div>
    );
  }

  return (
    <div className="space-y-3">
      <h3 className="eyebrow">Recent announcements</h3>
      <div className="card divide-y-[1.5px] divide-border">
        {announcements.map((ann) => (
          <article key={ann.id} className="p-4 space-y-2 hover:bg-blue-tint">
            <div className="flex flex-wrap items-center justify-between gap-2 text-xs">
              <div className="flex items-center gap-2">
                <span
                  className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 font-medium ${
                    ann.audienceType === "all"
                      ? "bg-blue-soft text-ink"
                      : "bg-blue-soft text-ink"
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
                      ? "bg-blue-soft text-ink"
                      : "bg-primary-soft text-ink"
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
