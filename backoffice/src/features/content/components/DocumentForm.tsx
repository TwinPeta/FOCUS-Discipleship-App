/**
 * src/features/content/components/DocumentForm.tsx
 *
 * WHAT: Study guide / document upload (PDF or Word, up to 25 MB)
 * REQUIREMENTS: FR-01
 * STATUS: implemented
 */

"use client";

import { useState, type ChangeEvent } from "react";
import { uploadFile } from "@/lib/upload";

interface DocumentFormProps {
  documentUrl: string;
  onChange: (url: string) => void;
}

const MAX_DOCUMENT_BYTES = 25 * 1024 * 1024;

export function DocumentForm({ documentUrl, onChange }: DocumentFormProps) {
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleFileChange(event: ChangeEvent<HTMLInputElement>) {
    setError(null);
    const file = event.target.files?.[0];
    if (!file) return;
    if (file.size > MAX_DOCUMENT_BYTES) {
      setError("Document must be 25 MB or smaller.");
      return;
    }
    setUploading(true);
    try {
      onChange(await uploadFile(file, "content_document"));
    } catch (e) {
      setError(e instanceof Error ? e.message : "Upload failed. Please try again.");
    } finally {
      setUploading(false);
    }
  }

  return (
    <div className="space-y-2 rounded-md border border-border bg-surface p-4">
      <label htmlFor="document-upload" className="block text-sm font-medium text-foreground">
        Study guide or document (PDF or Word, up to 25 MB)
      </label>
      <input
        id="document-upload"
        type="file"
        accept=".pdf,.doc,.docx,application/pdf,application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        disabled={uploading}
        onChange={(e) => void handleFileChange(e)}
        className="block w-full text-sm file:mr-3 file:rounded-md file:border file:border-border file:bg-white file:px-3 file:py-1.5 file:text-xs file:font-medium"
      />
      {uploading && <p className="text-xs text-muted-foreground">Uploading...</p>}
      {documentUrl && !uploading && (
        <p className="text-xs font-medium text-emerald-800">Document attached.</p>
      )}
      {error && (
        <p role="alert" className="text-xs text-red-700">
          {error}
        </p>
      )}
    </div>
  );
}
