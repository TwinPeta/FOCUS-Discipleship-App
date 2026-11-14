/**
 * src/features/communities/components/MeetingFields.tsx
 *
 * WHAT: Reusable meeting day, time, and place inputs (also used by super-mentors)
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/03-institutions-communities.md
 * STATUS: implemented
 */

"use client";

import type { UseFormRegister } from "react-hook-form";
import type { CommunityInput } from "@/features/communities/schemas";

interface MeetingFieldsProps {
  register: UseFormRegister<CommunityInput>;
}

const DAYS = [
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
  "Sunday",
];

export function MeetingFields({ register }: MeetingFieldsProps) {
  return (
    <div className="grid gap-4 sm:grid-cols-3">
      <div className="space-y-1.5">
        <label htmlFor="meetingDay" className="block text-sm font-medium text-foreground">
          Meeting day
        </label>
        <select
          id="meetingDay"
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
          {...register("meetingDay")}
        >
          <option value="">Select day</option>
          {DAYS.map((day) => (
            <option key={day} value={day}>
              {day}
            </option>
          ))}
        </select>
      </div>

      <div className="space-y-1.5">
        <label htmlFor="meetingTime" className="block text-sm font-medium text-foreground">
          Meeting time
        </label>
        <input
          id="meetingTime"
          type="time"
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
          {...register("meetingTime")}
        />
      </div>

      <div className="space-y-1.5">
        <label htmlFor="meetingPlace" className="block text-sm font-medium text-foreground">
          Meeting place
        </label>
        <input
          id="meetingPlace"
          type="text"
          placeholder="e.g. St. Augustine Chapel"
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
          {...register("meetingPlace")}
        />
      </div>
    </div>
  );
}
