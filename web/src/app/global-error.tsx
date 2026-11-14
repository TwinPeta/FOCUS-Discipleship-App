/**
 * src/app/global-error.tsx
 *
 * WHAT: Root error boundary fallback
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: placeholder, not implemented
 */

"use client";

export default function GlobalError({ reset }: { error: Error; reset: () => void }) {
  return (
    <html lang="en">
      <body>
        <p>Something went wrong.</p>
        <button onClick={reset}>Try again</button>
      </body>
    </html>
  );
}
