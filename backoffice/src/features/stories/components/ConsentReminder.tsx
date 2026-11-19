/**
 * src/features/stories/components/ConsentReminder.tsx
 *
 * WHAT: Reminder banner regarding written student consent for public landing stories
 * REQUIREMENTS: -
 * SPEC: docs/features/09-announcements-stories.md
 * STATUS: implemented
 */

import { ShieldAlert } from "lucide-react";

export function ConsentReminder() {
  return (
    <div
      role="note"
      className="flex items-start gap-2.5 rounded-lg border border-primary bg-primary-soft p-3.5 text-xs text-ink"
    >
      <ShieldAlert className="mt-0.5 h-4 w-4 shrink-0 text-amber-700" aria-hidden="true" />
      <div>
        <p className="font-semibold">Written Consent Required (Open Question #13)</p>
        <p className="mt-0.5 text-ink">
          Before uploading and publishing a student testimonial video on the public landing page (&quot;Hear it from students&quot;), verify that you have obtained and archived a signed written media consent agreement.
        </p>
      </div>
    </div>
  );
}
