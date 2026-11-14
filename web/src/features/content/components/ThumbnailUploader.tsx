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

interface ThumbnailUploaderProps {
  value?: string;
  onChange: (url: string) => void;
}

export function ThumbnailUploader({ value, onChange }: ThumbnailUploaderProps) {
  const [error, setError] = useState<string | null>(null);

  function handleChange(event: ChangeEvent<HTMLInputElement>) {
    setError(null);
    const file = event.target.files?.[0];
    if (!file) return;
    if (!file.type.startsWith("image/")) {
      setError("Please select an image file.");
      return;
    }
    onChange(URL.createObjectURL(file));
  }

  return (
    <div className="space-y-1.5">
      <label htmlFor="thumbnail-upload" className="block text-sm font-medium text-foreground">
        Thumbnail (optional)
      </label>
      <input
        id="thumbnail-upload"
        type="file"
        accept="image/jpeg,image/png,image/webp"
        onChange={handleChange}
        className="block w-full text-sm file:mr-3 file:rounded-md file:border file:border-border file:bg-surface file:px-3 file:py-1.5 file:text-xs file:font-medium"
      />
      {value && (
        <p className="text-xs text-muted-foreground">Thumbnail selected.</p>
      )}
      {error && (
        <p role="alert" className="text-xs text-red-700">
          {error}
        </p>
      )}
    </div>
  );
}
