/**
 * src/features/stories/components/StoryUploader.tsx
 *
 * WHAT: Upload modal for adding a new student landing story video
 * REQUIREMENTS: -
 * SPEC: docs/features/09-announcements-stories.md
 * STATUS: implemented
 */

"use client";

import { useState, type FormEvent } from "react";
import { Plus, Video, X } from "lucide-react";
import { ConsentReminder } from "./ConsentReminder";
import { createLandingStory, type LandingStory } from "../queries";

interface StoryUploaderProps {
  onStoryCreated: (story: LandingStory) => void;
}

export function StoryUploader({ onStoryCreated }: StoryUploaderProps) {
  const [open, setOpen] = useState(false);
  const [studentName, setStudentName] = useState("");
  const [institution, setInstitution] = useState("");
  const [videoUrl, setVideoUrl] = useState("");
  const [duration, setDuration] = useState("1:30");
  const [consentObtained, setConsentObtained] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);

    if (!studentName.trim() || !institution.trim() || !videoUrl.trim()) {
      setError("Please fill in student name, institution, and video URL.");
      return;
    }
    if (!consentObtained) {
      setError("You must confirm that written media consent was obtained.");
      return;
    }

    setSubmitting(true);
    try {
      const created = await createLandingStory({
        studentName: studentName.trim(),
        institution: institution.trim(),
        videoUrl: videoUrl.trim(),
        duration: duration.trim(),
        consentObtained: true,
      });
      onStoryCreated(created);
      setStudentName("");
      setInstitution("");
      setVideoUrl("");
      setConsentObtained(false);
      setOpen(false);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to add story video.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="inline-flex items-center gap-1.5 rounded-md bg-primary px-3.5 py-2 text-xs font-medium text-white hover:opacity-90"
      >
        <Plus className="h-4 w-4" />
        <span>Add story video</span>
      </button>

      {open && (
        <div
          role="dialog"
          aria-modal="true"
          aria-label="Upload landing story"
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
        >
          <form
            onSubmit={handleSubmit}
            className="w-full max-w-md space-y-4 rounded-xl border border-border bg-white p-6 shadow-xl"
          >
            <div className="flex items-center justify-between border-b border-border pb-3">
              <div className="flex items-center gap-2">
                <Video className="h-4 w-4 text-primary" />
                <h3 className="text-base font-semibold text-foreground">
                  Add Landing Story Video
                </h3>
              </div>
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="rounded p-1 text-muted hover:text-foreground"
                aria-label="Close"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            <ConsentReminder />

            {error && (
              <div role="alert" className="rounded-md border border-rose-200 bg-rose-50 p-2.5 text-xs text-rose-800">
                {error}
              </div>
            )}

            <div className="space-y-1.5">
              <label htmlFor="story-student" className="block text-xs font-medium text-muted">
                Student Name
              </label>
              <input
                id="story-student"
                type="text"
                value={studentName}
                onChange={(e) => setStudentName(e.target.value)}
                placeholder="e.g. Joshua Mukisa"
                className="w-full rounded-md border border-border px-3 py-1.5 text-xs text-foreground focus:ring-2 focus:ring-primary"
                required
              />
            </div>

            <div className="space-y-1.5">
              <label htmlFor="story-inst" className="block text-xs font-medium text-muted">
                Campus / Institution
              </label>
              <input
                id="story-inst"
                type="text"
                value={institution}
                onChange={(e) => setInstitution(e.target.value)}
                placeholder="e.g. Makerere University"
                className="w-full rounded-md border border-border px-3 py-1.5 text-xs text-foreground focus:ring-2 focus:ring-primary"
                required
              />
            </div>

            <div className="grid gap-3 sm:grid-cols-2">
              <div className="space-y-1.5">
                <label htmlFor="story-url" className="block text-xs font-medium text-muted">
                  Video URL (mp4 / stream)
                </label>
                <input
                  id="story-url"
                  type="url"
                  value={videoUrl}
                  onChange={(e) => setVideoUrl(e.target.value)}
                  placeholder="https://..."
                  className="w-full rounded-md border border-border px-3 py-1.5 text-xs text-foreground focus:ring-2 focus:ring-primary"
                  required
                />
              </div>

              <div className="space-y-1.5">
                <label htmlFor="story-dur" className="block text-xs font-medium text-muted">
                  Duration (mm:ss)
                </label>
                <input
                  id="story-dur"
                  type="text"
                  value={duration}
                  onChange={(e) => setDuration(e.target.value)}
                  placeholder="1:30"
                  className="w-full rounded-md border border-border px-3 py-1.5 text-xs text-foreground focus:ring-2 focus:ring-primary"
                  required
                />
              </div>
            </div>

            <div className="pt-1">
              <label className="flex items-start gap-2 text-xs font-medium text-foreground cursor-pointer">
                <input
                  type="checkbox"
                  checked={consentObtained}
                  onChange={(e) => setConsentObtained(e.target.checked)}
                  className="mt-0.5 h-3.5 w-3.5 rounded border-border text-primary focus:ring-primary"
                  required
                />
                <span>
                  I confirm that this student has signed a written media consent agreement.
                </span>
              </label>
            </div>

            <div className="flex justify-end gap-2 border-t border-border pt-4">
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="rounded-md border border-border px-3 py-1.5 text-xs font-medium text-foreground hover:bg-slate-50"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={submitting}
                className="rounded-md bg-primary px-3.5 py-1.5 text-xs font-medium text-white hover:opacity-90 disabled:opacity-50"
              >
                {submitting ? "Adding…" : "Add story"}
              </button>
            </div>
          </form>
        </div>
      )}
    </>
  );
}
