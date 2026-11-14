/**
 * src/features/announcements/components/AnnouncementForm.tsx
 *
 * WHAT: Composer for creating announcements targeting general or specific community
 * REQUIREMENTS: -
 * SPEC: docs/features/09-announcements-stories.md
 * STATUS: implemented
 */

"use client";

import { useState, type FormEvent } from "react";
import { Megaphone } from "lucide-react";
import {
  createAnnouncement,
  MOCK_COMMUNITIES_SELECT,
  type Announcement,
} from "../queries";

interface AnnouncementFormProps {
  onCreated: (announcement: Announcement) => void;
  userCommunityId?: string | null; // For scoped super-mentors
}

export function AnnouncementForm({ onCreated, userCommunityId }: AnnouncementFormProps) {
  const [title, setTitle] = useState("");
  const [message, setMessage] = useState("");
  const [audienceType, setAudienceType] = useState<"all" | "community">(
    userCommunityId ? "community" : "all",
  );
  const [communityId, setCommunityId] = useState<string>(
    userCommunityId ?? MOCK_COMMUNITIES_SELECT[0].id,
  );
  const [publishTiming, setPublishTiming] = useState<"now" | "scheduled">("now");
  const [scheduledFor, setScheduledFor] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);

    if (!title.trim()) {
      setError("Title is required.");
      return;
    }
    if (!message.trim()) {
      setError("Message content is required.");
      return;
    }
    if (publishTiming === "scheduled" && !scheduledFor) {
      setError("Please pick a scheduled date and time.");
      return;
    }

    setSubmitting(true);
    try {
      const created = await createAnnouncement({
        title: title.trim(),
        message: message.trim(),
        audienceType,
        communityId: audienceType === "community" ? communityId : null,
        publishTiming,
        scheduledFor: publishTiming === "scheduled" ? scheduledFor : undefined,
      });
      onCreated(created);
      setTitle("");
      setMessage("");
      setScheduledFor("");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to create announcement.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4 rounded-xl border border-border bg-white p-5 shadow-sm">
      <div className="flex items-center gap-2">
        <Megaphone className="h-5 w-5 text-primary" />
        <h2 className="text-base font-semibold text-foreground">Compose Announcement</h2>
      </div>

      {error && (
        <div role="alert" className="rounded-md border border-rose-200 bg-rose-50 p-2.5 text-xs text-rose-800">
          {error}
        </div>
      )}

      <div className="grid gap-4 sm:grid-cols-2">
        <div className="space-y-1.5">
          <label htmlFor="ann-audience" className="block text-xs font-medium text-muted">
            Target Audience
          </label>
          <select
            id="ann-audience"
            value={audienceType}
            disabled={Boolean(userCommunityId)}
            onChange={(e) => setAudienceType(e.target.value as "all" | "community")}
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary"
          >
            <option value="all">All Fellowship Communities</option>
            <option value="community">Specific Community</option>
          </select>
        </div>

        {audienceType === "community" && (
          <div className="space-y-1.5">
            <label htmlFor="ann-community" className="block text-xs font-medium text-muted">
              Select Community
            </label>
            <select
              id="ann-community"
              value={communityId}
              disabled={Boolean(userCommunityId)}
              onChange={(e) => setCommunityId(e.target.value)}
              className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary"
            >
              {MOCK_COMMUNITIES_SELECT.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </div>
        )}
      </div>

      <div className="space-y-1.5">
        <label htmlFor="ann-title" className="block text-xs font-medium text-muted">
          Title
        </label>
        <input
          id="ann-title"
          type="text"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="e.g. National Conference Registration Open"
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary"
          required
        />
      </div>

      <div className="space-y-1.5">
        <label htmlFor="ann-message" className="block text-xs font-medium text-muted">
          Message body
        </label>
        <textarea
          id="ann-message"
          rows={3}
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          placeholder="Announcement text to be displayed on student feed..."
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary"
          required
        />
      </div>

      <div className="grid gap-4 sm:grid-cols-2 pt-1">
        <div className="space-y-1.5">
          <label htmlFor="ann-timing" className="block text-xs font-medium text-muted">
            Publish Timing
          </label>
          <select
            id="ann-timing"
            value={publishTiming}
            onChange={(e) => setPublishTiming(e.target.value as "now" | "scheduled")}
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary"
          >
            <option value="now">Publish immediately</option>
            <option value="scheduled">Schedule for later date</option>
          </select>
        </div>

        {publishTiming === "scheduled" && (
          <div className="space-y-1.5">
            <label htmlFor="ann-scheduled-time" className="block text-xs font-medium text-muted">
              Scheduled Date & Time
            </label>
            <input
              id="ann-scheduled-time"
              type="datetime-local"
              value={scheduledFor}
              onChange={(e) => setScheduledFor(e.target.value)}
              className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary"
              required
            />
          </div>
        )}
      </div>

      <div className="flex justify-end pt-2">
        <button
          type="submit"
          disabled={submitting}
          className="rounded-md bg-primary px-4 py-2 text-xs font-medium text-white hover:opacity-90 disabled:opacity-50"
        >
          {submitting ? "Posting…" : publishTiming === "now" ? "Publish Announcement" : "Schedule Announcement"}
        </button>
      </div>
    </form>
  );
}
