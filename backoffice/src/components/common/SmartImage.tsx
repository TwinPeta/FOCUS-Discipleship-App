/**
 * src/components/common/SmartImage.tsx
 *
 * WHAT: Image with shimmer placeholder, blur-to-sharp reveal and graceful fallback when the URL fails
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useRef, useState, type ReactNode } from "react";
import { ImageOff } from "lucide-react";

interface SmartImageProps {
  src: string;
  alt: string;
  /** Classes for the outer box (size, rounding). */
  className?: string;
  /** Classes for the <img> itself (e.g. object-cover). */
  imgClassName?: string;
  /** Above-the-fold hero images: load eagerly with high fetch priority. Otherwise lazy. */
  priority?: boolean;
  /** Rendered instead of the default icon when the image fails to load. */
  fallback?: ReactNode;
}

type Status = "loading" | "loaded" | "error";

export function SmartImage({
  src,
  alt,
  className = "",
  imgClassName = "object-cover",
  priority = false,
  fallback,
}: SmartImageProps) {
  const imgRef = useRef<HTMLImageElement>(null);
  const [status, setStatus] = useState<Status>("loading");

  useEffect(() => {
    // Reset when src changes; handle images already decoded from cache before hydration.
    const img = imgRef.current;
    if (img?.complete && img.naturalWidth > 0) setStatus("loaded");
    else setStatus("loading");
  }, [src]);

  if (status === "error" || !src) {
    return (
      <>
        {fallback ?? (
          <div
            role="img"
            aria-label={alt}
            className={`flex items-center justify-center bg-background-subtle text-muted-foreground ${className}`}
          >
            <ImageOff className="h-1/3 w-1/3 max-h-6 max-w-6" aria-hidden="true" />
          </div>
        )}
      </>
    );
  }

  return (
    <div className={`relative overflow-hidden ${className}`}>
      {status === "loading" && <div className="fcu-shimmer absolute inset-0" aria-hidden="true" />}
      {/* eslint-disable-next-line @next/next/no-img-element -- arbitrary user-supplied URLs */}
      <img
        ref={imgRef}
        src={src}
        alt={alt}
        decoding="async"
        {...(priority ? { fetchPriority: "high" as const } : { loading: "lazy" as const })}
        onLoad={() => setStatus("loaded")}
        onError={() => setStatus("error")}
        className={`h-full w-full transition-[opacity,filter] duration-300 ease-out ${
          status === "loaded" ? "opacity-100 blur-0" : "opacity-0 blur-sm"
        } ${imgClassName}`}
      />
    </div>
  );
}
