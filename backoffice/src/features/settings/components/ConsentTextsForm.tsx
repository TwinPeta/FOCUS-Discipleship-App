/**
 * src/features/settings/components/ConsentTextsForm.tsx
 *
 * WHAT: Editable consent texts for account creation, community spaces, and mentor contact
 * REQUIREMENTS: FR-10
 * SPEC: docs/features/14-settings-charter.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { fetchSettings, saveConsentTextsSettings } from "@/features/settings/queries";
import {
  consentTextsSchema,
  type ConsentTextsSettings,
} from "@/features/settings/schemas";

export function ConsentTextsForm() {
  const [saved, setSaved] = useState(false);

  const {
    register,
    handleSubmit,
    reset,
    formState: { isSubmitting },
  } = useForm<ConsentTextsSettings>({
    resolver: zodResolver(consentTextsSchema),
    defaultValues: {
      accountCreationText:
        "I agree to FOCUS Uganda processing my account details for discipleship and campus community participation.",
      communitySpacesText:
        "I consent to sharing my posts and prayer requests with members of my campus community.",
      mentorContactText:
        "I consent to being contacted by verified campus mentors for pastoral follow-up.",
    },
  });

  useEffect(() => {
    let active = true;
    fetchSettings<ConsentTextsSettings>("consents").then((saved) => {
      if (active && saved) reset(saved);
    });
    return () => {
      active = false;
    };
  }, [reset]);

  async function onSubmit(values: ConsentTextsSettings) {
    setSaved(false);
    await saveConsentTextsSettings(values);
    setSaved(true);
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      {saved && (
        <p role="status" className="text-xs font-medium text-emerald-800">
          Consent texts saved.
        </p>
      )}

      <div className="space-y-1.5">
        <label htmlFor="consent-account" className="block text-sm font-medium">
          Creating an account
        </label>
        <textarea
          id="consent-account"
          rows={2}
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
          {...register("accountCreationText")}
        />
      </div>

      <div className="space-y-1.5">
        <label htmlFor="consent-community" className="block text-sm font-medium">
          Taking part in community spaces
        </label>
        <textarea
          id="consent-community"
          rows={2}
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
          {...register("communitySpacesText")}
        />
      </div>

      <div className="space-y-1.5">
        <label htmlFor="consent-mentor" className="block text-sm font-medium">
          Being contacted by a mentor
        </label>
        <textarea
          id="consent-mentor"
          rows={2}
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
          {...register("mentorContactText")}
        />
      </div>

      <button
        type="submit"
        disabled={isSubmitting}
        className="rounded-md bg-primary px-4 py-2 text-sm font-semibold text-foreground hover:brightness-95 disabled:opacity-60"
      >
        {isSubmitting ? "Saving..." : "Save consent texts"}
      </button>
    </form>
  );
}
