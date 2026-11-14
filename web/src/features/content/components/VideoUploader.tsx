/**
 * src/features/content/components/VideoUploader.tsx
 *
 * WHAT: Resumable video uploader up to 500 MB (tus-js-client) with progress and retry
 * REQUIREMENTS: FR-01
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

"use client";

import { useState, type ChangeEvent } from "react";
import * as tus from "tus-js-client";
import { MAX_VIDEO_BYTES } from "@/features/content/schemas";
import { publicEnv } from "@/lib/env";

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

  function startUpload(file: File) {
    setError(null);
    setProgress(0);

    const endpoint = publicEnv.NEXT_PUBLIC_UPLOAD_ENDPOINT;
    if (!endpoint) {
      // Local/mock fallback before tus upload endpoint is configured
      const mockUrl = `mock://videos/${encodeURIComponent(file.name)}`;
      setProgress(100);
      setStatus("done");
      onUploaded(mockUrl);
      return;
    }

    setStatus("uploading");
    const upload = new tus.Upload(file, {
      endpoint,
      retryDelays: [0, 3000, 5000, 10000],
      metadata: {
        filename: file.name,
        filetype: file.type,
      },
      onError: () => {
        setStatus("error");
        setError("Upload interrupted. You can retry to resume from where it stopped.");
      },
      onProgress: (bytesUploaded, bytesTotal) => {
        setProgress(Math.round((bytesUploaded / bytesTotal) * 100));
      },
      onSuccess: () => {
        setStatus("done");
        onUploaded(upload.url ?? "");
      },
    });

    upload.start();
  }

  function handleFileChange(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    if (!file) return;

    if (file.size > MAX_VIDEO_BYTES) {
      setError("Video must be 500 MB or smaller.");
      return;
    }

    setLastFile(file);
    startUpload(file);
  }

  return (
    <div className="space-y-2 rounded-md border border-border bg-surface p-4">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <label htmlFor="video-upload" className="text-sm font-medium text-foreground">
          Video file
        </label>
        <span className="text-xs text-muted-foreground">
          Up to 500 MB (lighter versions created automatically)
        </span>
      </div>

      <input
        id="video-upload"
        type="file"
        accept="video/*"
        onChange={handleFileChange}
        className="block w-full text-sm file:mr-3 file:rounded-md file:border file:border-border file:bg-white file:px-3 file:py-1.5 file:text-xs file:font-medium"
      />

      {status === "uploading" && (
        <div className="space-y-1">
          <div className="h-2 w-full overflow-hidden rounded-full bg-border">
            <div
              className="h-full bg-primary transition-all"
              style={{ width: `${progress}%` }}
            />
          </div>
          <p className="text-xs text-muted-foreground">Uploading... {progress}%</p>
        </div>
      )}

      {status === "done" && (
        <p className="text-xs font-medium text-emerald-800">
          Video ready{value ? ` (${value})` : ""}.
        </p>
      )}

      {error && (
        <div className="flex items-center justify-between gap-2">
          <p role="alert" className="text-xs text-red-700">
            {error}
          </p>
          {lastFile && (
            <button
              type="button"
              onClick={() => startUpload(lastFile)}
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
