/**
 * src/components/common/FileDropzone.tsx
 *
 * WHAT: Accessible drag-and-drop file upload area with type and size limits
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

"use client";

import { useRef, useState, type DragEvent, type ChangeEvent } from "react";
import { UploadCloud } from "lucide-react";

interface FileDropzoneProps {
  accept?: string;
  maxSizeMb?: number;
  onFileSelected: (file: File) => void;
  helperText?: string;
}

export function FileDropzone({
  accept = "image/*,.pdf,.doc,.docx",
  maxSizeMb = 10,
  onFileSelected,
  helperText = "Drag & drop file here or click to browse",
}: FileDropzoneProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [isDragging, setIsDragging] = useState(false);
  const [error, setError] = useState<string | null>(null);

  function validateAndSelect(file: File) {
    setError(null);
    if (file.size > maxSizeMb * 1024 * 1024) {
      setError(`File exceeds maximum size of ${maxSizeMb}MB.`);
      return;
    }
    onFileSelected(file);
  }

  function handleDragOver(e: DragEvent) {
    e.preventDefault();
    setIsDragging(true);
  }

  function handleDragLeave() {
    setIsDragging(false);
  }

  function handleDrop(e: DragEvent) {
    e.preventDefault();
    setIsDragging(false);
    const file = e.dataTransfer.files[0];
    if (file) validateAndSelect(file);
  }

  function handleChange(e: ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (file) validateAndSelect(file);
  }

  return (
    <div className="space-y-2">
      <div
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
        onDrop={handleDrop}
        onClick={() => inputRef.current?.click()}
        className={`flex flex-col items-center justify-center rounded-xl border-2 border-dashed p-6 text-center cursor-pointer transition ${
          isDragging
            ? "border-primary bg-primary-soft/50"
            : "border-border bg-slate-50/50 hover:bg-slate-50 hover:border-slate-300"
        }`}
      >
        <UploadCloud className="h-8 w-8 text-muted mb-2" />
        <p className="text-xs font-semibold text-foreground">{helperText}</p>
        <p className="mt-1 text-[11px] text-muted">Max file size: {maxSizeMb}MB</p>
        <input
          ref={inputRef}
          type="file"
          accept={accept}
          onChange={handleChange}
          className="sr-only"
        />
      </div>
      {error && (
        <p role="alert" className="text-xs text-rose-600">
          {error}
        </p>
      )}
    </div>
  );
}
