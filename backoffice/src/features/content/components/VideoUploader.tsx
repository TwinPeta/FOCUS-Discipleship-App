/**
 * src/features/content/components/VideoUploader.tsx
 *
 * WHAT: Video uploader up to 500 MB with progress and retry (the file goes straight to storage, see lib/upload.ts)
 * REQUIREMENTS: FR-01
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

"use client";

import { useState, type ChangeEvent } from "react";
import { MAX_VIDEO_BYTES } from "@/features/content/schemas";
import { uploadFile } from "@/lib/upload";

interface VideoUploaderProps {
  value?: string;
  onUploaded: (url: string) => void;
}

export function VideoUploader({ value, onUploaded }: VideoUploaderProps) {
  const [progress, setProgress] = useState<number>(0);
  const [status, setStatus] = useState<"idle" | "uploading" | "done" | "error">(
    value ? "done" : "idle",
  );
  const [error, setError] = useState<string | null>(null);
  const [lastFile, setLastFile] = useState<File | null>(null);

  async function startUpload(file: File) {
    setError(null);
    setProgress(0);
    setStatus("uploading");
    try {
      const url = await uploadFile(file, "content_video", setProgress);
      setStatus("done");
      onUploaded(url);
    } catch (e) {
      setStatus("error");
      setError(e instanceof Error ? e.message : "Upload failed. Please try again.");
    }
  }

  function handleFileChange(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    if (!file) return;

    if (file.size > MAX_VIDEO_BYTES) {
      setError("Video must be 500 MB or smaller.");
      return;
    }

    setLastFile(file);
    void startUpload(file);
  }

  return (
    <div className="space-y-2 rounded-md border border-border bg-surface p-4">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <label htmlFor="video-upload" className="text-sm font-medium text-foreground">
          Video file
        </label>
        <span className="text-xs text-muted-foreground">MP4, WebM or MOV, up to 500 MB</span>
      </div>

      <input
        id="video-upload"
        type="file"
        accept="video/mp4,video/webm,video/quicktime"
        disabled={status === "uploading"}
        onChange={handleFileChange}
        className="block w-full text-sm file:mr-3 file:rounded-md file:border file:border-border file:bg-white file:px-3 file:py-1.5 file:text-xs file:font-medium"
      />

      {status === "uploading" && (
        <div className="space-y-1">
          <div className="h-2 w-full overflow-hidden rounded-full bg-border">
            <div className="h-full bg-primary transition-all" style={{ width: `${progress}%` }} />
          </div>
          <p className="text-xs text-muted-foreground">Uploading... {progress}%</p>
        </div>
      )}

      {status === "done" && <p className="text-xs font-medium text-emerald-800">Video uploaded.</p>}

      {error && (
        <div className="flex items-center justify-between gap-2">
          <p role="alert" className="text-xs text-red-700">
            {error}
          </p>
          {lastFile && status === "error" && (
            <button
              type="button"
              onClick={() => void startUpload(lastFile)}
              className="rounded border border-border bg-white px-2.5 py-1 text-xs font-medium"
            >
              Retry
            </button>
          )}
        </div>
      )}
    </div>
  );
}
