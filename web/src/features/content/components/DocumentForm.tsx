/**
 * src/features/content/components/DocumentForm.tsx
 *
 * WHAT: PDF / study guide document uploader
 * REQUIREMENTS: FR-01
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

"use client";

import type { ChangeEvent } from "react";

interface DocumentFormProps {
  documentUrl: string;
  onChange: (url: string) => void;
}

export function DocumentForm({ documentUrl, onChange }: DocumentFormProps) {
  function handleFileChange(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    if (!file) return;
    onChange(`mock://documents/${encodeURIComponent(file.name)}`);
  }

  return (
    <div className="space-y-2 rounded-md border border-border bg-surface p-4">
      <label htmlFor="document-upload" className="block text-sm font-medium text-foreground">
        Study guide or document (PDF)
      </label>
      <input
        id="document-upload"
        type="file"
        accept=".pdf,.doc,.docx,application/pdf"
        onChange={handleFileChange}
        className="block w-full text-sm file:mr-3 file:rounded-md file:border file:border-border file:bg-white file:px-3 file:py-1.5 file:text-xs file:font-medium"
      />
      {documentUrl && (
        <p className="text-xs font-medium text-emerald-800">
          Document attached ({documentUrl}).
        </p>
      )}
    </div>
  );
}
