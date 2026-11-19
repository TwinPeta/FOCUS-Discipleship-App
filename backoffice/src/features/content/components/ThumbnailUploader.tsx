/**
 * src/features/content/components/ThumbnailUploader.tsx
 *
 * WHAT: Optional thumbnail image uploader for video content
 * REQUIREMENTS: FR-01
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

"use client";

import { useState, type ChangeEvent } from "react";
import { uploadFile } from "@/lib/upload";

interface ThumbnailUploaderProps {
  value?: string;
  onChange: (url: string) => void;
}

export function ThumbnailUploader({ value, onChange }: ThumbnailUploaderProps) {
  const [error, setError] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);

  async function handleChange(event: ChangeEvent<HTMLInputElement>) {
    setError(null);
    const file = event.target.files?.[0];
    if (!file) return;
    if (!["image/jpeg", "image/png", "image/webp"].includes(file.type)) {
      setError("Please select a JPG, PNG or WebP image.");
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      setError("Image must be 5 MB or smaller.");
      return;
    }
    setUploading(true);
    try {
      onChange(await uploadFile(file, "content_thumbnail"));
    } catch (e) {
      setError(e instanceof Error ? e.message : "Upload failed. Please try again.");
    } finally {
      setUploading(false);
    }
  }

  return (
    <div className="space-y-1.5">
      <label htmlFor="thumbnail-upload" className="block text-[13px] font-extrabold">
        Thumbnail (optional)
      </label>
      <input
        id="thumbnail-upload"
        type="file"
        accept="image/jpeg,image/png,image/webp"
        disabled={uploading}
        onChange={(e) => void handleChange(e)}
        className="block w-full text-sm file:mr-3 file:rounded-md file:border file:border-border file:bg-surface file:px-3 file:py-1.5 file:text-xs file:font-medium"
      />
      {uploading && <p className="text-xs text-muted-foreground">Uploading...</p>}
      {value && !uploading && (
        <p className="text-xs text-muted-foreground">Thumbnail uploaded.</p>
      )}
      {error && (
        <p role="alert" className="text-xs text-danger">
          {error}
        </p>
      )}
    </div>
  );
}
