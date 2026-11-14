/**
 * src/features/my-community/components/NextMeetingCard.tsx
 *
 * WHAT: Next meeting day, time, place with edit details
 * REQUIREMENTS: FR-03,FR-04,FR-05
 * SPEC: docs/features/15-super-mentor-view.md
 * STATUS: implemented
 */

"use client";

import { useState, type FormEvent } from "react";
import { Calendar, Edit2 } from "lucide-react";
import { updateNextMeeting, type NextMeetingDetails } from "../queries";

interface NextMeetingCardProps {
  meeting: NextMeetingDetails;
  onUpdated: (next: NextMeetingDetails) => void;
}

export function NextMeetingCard({ meeting, onUpdated }: NextMeetingCardProps) {
  const [editing, setEditing] = useState(false);
  const [day, setDay] = useState(meeting.day);
  const [time, setTime] = useState(meeting.time);
  const [place, setPlace] = useState(meeting.place);
  const [saving, setSaving] = useState(false);

  async function handleSave(e: FormEvent) {
    e.preventDefault();
    setSaving(true);
    try {
      const saved = await updateNextMeeting({
        day: day.trim(),
        time: time.trim(),
        place: place.trim(),
      });
      onUpdated(saved);
      setEditing(false);
    } finally {
      setSaving(false);
    }
  }

  return (
    <section className="space-y-3 rounded-xl border border-border bg-white p-5">
      <div className="flex items-center justify-between gap-2">
        <div className="flex items-center gap-2">
          <Calendar className="h-4 w-4 text-primary" aria-hidden="true" />
          <h2 className="text-base font-semibold text-foreground">Next meeting</h2>
        </div>
        {!editing && (
          <button
            type="button"
            onClick={() => setEditing(true)}
            className="inline-flex items-center gap-1 rounded-md border border-border px-2.5 py-1 text-xs font-medium text-foreground hover:bg-slate-50"
          >
            <Edit2 className="h-3 w-3" aria-hidden="true" />
            <span>Edit details</span>
          </button>
        )}
      </div>

      {editing ? (
        <form onSubmit={handleSave} className="space-y-3">
          <div className="grid gap-3 sm:grid-cols-2">
            <div className="space-y-1">
              <label htmlFor="meeting-day" className="block text-xs font-medium text-muted">
                Day
              </label>
              <input
                id="meeting-day"
                type="text"
                value={day}
                onChange={(e) => setDay(e.target.value)}
                className="w-full rounded-md border border-border px-3 py-1.5 text-sm text-foreground"
                required
              />
            </div>
            <div className="space-y-1">
              <label htmlFor="meeting-time" className="block text-xs font-medium text-muted">
                Time
              </label>
              <input
                id="meeting-time"
                type="time"
                value={time}
                onChange={(e) => setTime(e.target.value)}
                className="w-full rounded-md border border-border px-3 py-1.5 text-sm text-foreground"
                required
              />
            </div>
          </div>

          <div className="space-y-1">
            <label htmlFor="meeting-place" className="block text-xs font-medium text-muted">
              Place
            </label>
            <input
              id="meeting-place"
              type="text"
              value={place}
              onChange={(e) => setPlace(e.target.value)}
              className="w-full rounded-md border border-border px-3 py-1.5 text-sm text-foreground"
              required
            />
          </div>

          <div className="flex justify-end gap-2">
            <button
              type="button"
              onClick={() => setEditing(false)}
              className="rounded-md border border-border px-3 py-1.5 text-xs font-medium text-foreground hover:bg-slate-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={saving}
              className="rounded-md bg-primary px-3 py-1.5 text-xs font-medium text-white hover:opacity-90 disabled:opacity-50"
            >
              {saving ? "Saving…" : "Save"}
            </button>
          </div>
        </form>
      ) : (
        <dl className="grid gap-2 text-sm sm:grid-cols-3">
          <div>
            <dt className="text-xs text-muted">Day</dt>
            <dd className="font-medium text-foreground">{meeting.day}</dd>
          </div>
          <div>
            <dt className="text-xs text-muted">Time</dt>
            <dd className="font-medium text-foreground">{meeting.time}</dd>
          </div>
          <div>
            <dt className="text-xs text-muted">Place</dt>
            <dd className="font-medium text-foreground">{meeting.place}</dd>
          </div>
        </dl>
      )}
    </section>
  );
}
