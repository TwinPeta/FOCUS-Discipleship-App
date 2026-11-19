/**
 * src/features/communities/components/CoverPhotoUploader.tsx
 *
 * WHAT: Cover photo uploader with JPG/PNG validation, size limit, and 1600x600 cropper
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/03-institutions-communities.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useRef, useState, type ChangeEvent } from "react";
import Cropper, { type Area } from "react-easy-crop";
import { uploadFile } from "@/lib/upload";

export const COVER_RECOMMENDED_WIDTH = 1600;
export const COVER_RECOMMENDED_HEIGHT = 600;
export const COVER_ASPECT = COVER_RECOMMENDED_WIDTH / COVER_RECOMMENDED_HEIGHT;
export const MAX_COVER_BYTES = 5 * 1024 * 1024;
export const ALLOWED_COVER_TYPES = ["image/jpeg", "image/png"];

interface CoverPhotoUploaderProps {
  value?: string;
  /** Called with the address of the uploaded image (and the crop that produced it). */
  onChange: (url: string, cropArea?: Area) => void;
  disabled?: boolean;
}

export function CoverPhotoUploader({
  value,
  onChange,
  disabled = false,
}: CoverPhotoUploaderProps) {
  const [previewUrl, setPreviewUrl] = useState<string>(value ?? "");
  const [error, setError] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);
  const [crop, setCrop] = useState({ x: 0, y: 0 });
  const [zoom, setZoom] = useState(1);
  const picked = useRef(false); // true once the user chose a file (an existing remote cover is never re-uploaded)
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const latest = useRef({ onChange });
  latest.current = { onChange };

  useEffect(() => () => {
    if (timer.current) clearTimeout(timer.current);
  }, []);

  async function upload(blob: Blob, area?: Area) {
    setError(null);
    setUploading(true);
    try {
      latest.current.onChange(await uploadFile(blob, "cover_photo"), area);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Upload failed. Please try again.");
    } finally {
      setUploading(false);
    }
  }

  function handleFileChange(event: ChangeEvent<HTMLInputElement>) {
    setError(null);
    const file = event.target.files?.[0];
    if (!file) return;

    if (!ALLOWED_COVER_TYPES.includes(file.type)) {
      setError("Please upload a JPG or PNG image.");
      return;
    }

    if (file.size > MAX_COVER_BYTES) {
      setError("Image must be 5 MB or smaller.");
      return;
    }

    picked.current = true;
    setPreviewUrl(URL.createObjectURL(file));
    void upload(file); // saved straight away; moving the crop below replaces it with the cropped version
  }

  /** Renders the chosen area at the recommended size and uploads that. */
  function scheduleCrop(area: Area) {
    if (!picked.current) return;
    if (timer.current) clearTimeout(timer.current);
    timer.current = setTimeout(async () => {
      try {
        const image = new Image();
        image.src = previewUrl;
        await image.decode();
        const canvas = document.createElement("canvas");
        canvas.width = COVER_RECOMMENDED_WIDTH;
        canvas.height = COVER_RECOMMENDED_HEIGHT;
        canvas.getContext("2d")?.drawImage(image, area.x, area.y, area.width, area.height, 0, 0, canvas.width, canvas.height);
        const blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, "image/jpeg", 0.9));
        if (blob && blob.size <= MAX_COVER_BYTES) await upload(blob, area);
      } catch {
        // the full image uploaded on selection stays in place
      }
    }, 700);
  }

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <label htmlFor="cover-photo-input" className="text-sm font-medium text-foreground">
          Cover photo
        </label>
        <span className="text-xs text-muted-foreground">
          Recommended {COVER_RECOMMENDED_WIDTH} x {COVER_RECOMMENDED_HEIGHT} px (JPG or PNG, max 5 MB)
        </span>
      </div>

      <input
        id="cover-photo-input"
        type="file"
        accept="image/jpeg,image/png"
        disabled={disabled}
        onChange={handleFileChange}
        className="block w-full text-sm text-foreground file:mr-3 file:rounded-md file:border file:border-border file:bg-surface file:px-3 file:py-1.5 file:text-xs file:font-medium hover:file:bg-primary-soft disabled:opacity-60"
      />

      {uploading && <p className="text-xs text-muted-foreground">Uploading...</p>}
      {error && (
        <p role="alert" className="text-xs text-danger">
          {error}
        </p>
      )}

      {previewUrl && (
        <div className="space-y-2">
          <div
            data-testid="cover-cropper"
            className="relative h-48 w-full overflow-hidden rounded-md border border-border bg-stone-900"
          >
            <Cropper
              image={previewUrl}
              crop={crop}
              zoom={zoom}
              aspect={COVER_ASPECT}
              onCropChange={setCrop}
              onZoomChange={setZoom}
              onCropComplete={(_, croppedAreaPixels) => scheduleCrop(croppedAreaPixels)}
            />
          </div>
          <div className="flex items-center gap-3">
            <label htmlFor="cover-zoom" className="text-xs text-muted-foreground">
              Zoom
            </label>
            <input
              id="cover-zoom"
              type="range"
              min={1}
              max={3}
              step={0.1}
              value={zoom}
              onChange={(e) => setZoom(Number(e.target.value))}
              className="w-40 accent-primary"
            />
          </div>
        </div>
      )}
    </div>
  );
}
