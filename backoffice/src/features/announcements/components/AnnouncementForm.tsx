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
import {
  createAnnouncement,
  type Announcement,
} from "../queries";
import { useLookups } from "@/lib/hooks/useLookups";

interface AnnouncementFormProps {
  onCreated: (announcement: Announcement) => void;
  userCommunityId?: string | null; // For scoped super-mentors
}

export function AnnouncementForm({ onCreated, userCommunityId }: AnnouncementFormProps) {
  const { communities } = useLookups({ communities: true });
  const [title, setTitle] = useState("");
  const [message, setMessage] = useState("");
  const [audienceType, setAudienceType] = useState<"all" | "community">(
    userCommunityId ? "community" : "all",
  );
  const [communityId, setCommunityId] = useState<string>(
    userCommunityId ?? "",
  );
  const selectedCommunityId = communityId || communities[0]?.id || "";
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
        communityId: audienceType === "community" ? selectedCommunityId : null,
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
    <form onSubmit={handleSubmit} className="card flex flex-col gap-4">
      <h2 className="text-[22px] font-black">New announcement</h2>

      {error && (
        <div role="alert" className="rounded-md border border-danger/40 bg-danger-soft p-2.5 text-xs text-danger">
          {error}
        </div>
      )}

      <div className="grid gap-4 sm:grid-cols-2">
        <div className="space-y-1.5">
          <label htmlFor="ann-audience" className="block text-[13px] font-extrabold">
            Audience
          </label>
          <select
            id="ann-audience"
            value={audienceType}
            disabled={Boolean(userCommunityId)}
            onChange={(e) => setAudienceType(e.target.value as "all" | "community")}
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary"
          >
            <option value="all">All caregroups</option>
            <option value="community">Specific Caregroup</option>
          </select>
        </div>

        {audienceType === "community" && (
          <div className="space-y-1.5">
            <label htmlFor="ann-community" className="block text-[13px] font-extrabold">
              Select Caregroup
            </label>
            <select
              id="ann-community"
              value={selectedCommunityId}
              disabled={Boolean(userCommunityId)}
              onChange={(e) => setCommunityId(e.target.value)}
              className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary"
            >
              {communities.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </div>
        )}
      </div>

      <div className="space-y-1.5">
        <label htmlFor="ann-title" className="block text-[13px] font-extrabold">
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
        <label htmlFor="ann-message" className="block text-[13px] font-extrabold">
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
          <label htmlFor="ann-timing" className="block text-[13px] font-extrabold">
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
            <label htmlFor="ann-scheduled-time" className="block text-[13px] font-extrabold">
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
