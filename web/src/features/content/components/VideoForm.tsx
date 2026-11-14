/**
 * src/features/content/components/VideoForm.tsx
 *
 * WHAT: Video upload fields (VideoUploader + ThumbnailUploader)
 * REQUIREMENTS: FR-01
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

"use client";

import { ThumbnailUploader } from "./ThumbnailUploader";
import { VideoUploader } from "./VideoUploader";

interface VideoFormProps {
  videoUrl: string;
  onVideoUrlChange: (url: string) => void;
  thumbnailUrl: string;
  onThumbnailUrlChange: (url: string) => void;
}

export function VideoForm({
  videoUrl,
  onVideoUrlChange,
  thumbnailUrl,
  onThumbnailUrlChange,
}: VideoFormProps) {
  return (
    <div className="space-y-4">
      <VideoUploader value={videoUrl} onUploaded={onVideoUrlChange} />
      <ThumbnailUploader value={thumbnailUrl} onChange={onThumbnailUrlChange} />
    </div>
  );
}
