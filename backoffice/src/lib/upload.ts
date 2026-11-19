/**
 * src/lib/upload.ts
 *
 * WHAT: Uploads one file for the back office and returns its permanent address. The API decides where the bytes go:
 *       straight to Cloudflare R2 (signed URL) or, in local development, through the API itself.
 * REQUIREMENTS: FR-07
 * STATUS: implemented
 */

import { apiClient } from "@/lib/api/client";
import { ApiError } from "@/lib/api/errors";

export type UploadPurpose =
  | "cover_photo"
  | "content_thumbnail"
  | "avatar"
  | "content_video"
  | "content_document"
  | "story_video";

interface MediaSlot {
  media_id: string;
  url: string;
  direct: boolean;
  upload_url: string | null;
  upload_headers: Record<string, string>;
}

function send(
  url: string,
  file: Blob,
  headers: Record<string, string>,
  onProgress?: (percent: number) => void,
): Promise<void> {
  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    xhr.open("PUT", url);
    for (const [name, value] of Object.entries(headers)) xhr.setRequestHeader(name, value);
    xhr.upload.onprogress = (e) => {
      if (e.lengthComputable) onProgress?.(Math.round((e.loaded / e.total) * 100));
    };
    xhr.onload = () =>
      xhr.status >= 200 && xhr.status < 300
        ? resolve()
        : reject(new ApiError("The file could not be uploaded. Please try again.", xhr.status));
    xhr.onerror = () => reject(new ApiError("Upload interrupted. Check your connection and try again.", 0));
    xhr.send(file);
  });
}

export async function uploadFile(
  file: Blob,
  purpose: UploadPurpose,
  onProgress?: (percent: number) => void,
): Promise<string> {
  const contentType = file.type || "application/octet-stream";
  const slot = await apiClient<MediaSlot>("/media", {
    method: "POST",
    body: JSON.stringify({ purpose, content_type: contentType, size_bytes: file.size }),
  });

  // R2: the browser talks to the bucket directly. Local dev: the bytes go through the proxy to the API.
  const target = slot.direct && slot.upload_url ? slot.upload_url : `/api/proxy/media/${slot.media_id}/upload`;
  await send(target, file, slot.upload_headers, onProgress);

  const done = await apiClient<{ url: string }>(`/media/${slot.media_id}/complete`, { method: "POST" });
  return done.url;
}
