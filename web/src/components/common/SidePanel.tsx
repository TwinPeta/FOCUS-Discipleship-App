/**
 * src/components/common/SidePanel.tsx
 *
 * WHAT: Accessible detail and edit side panel beside tables or as slide-over on 1024px
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

"use client";

import { useEffect, type ReactNode } from "react";
import { X } from "lucide-react";

interface SidePanelProps {
  title: string;
  description?: string;
  open: boolean;
  onClose: () => void;
  children: ReactNode;
  width?: string;
}

export function SidePanel({
  title,
  description,
  open,
  onClose,
  children,
  width = "max-w-md",
}: SidePanelProps) {
  useEffect(() => {
    function handleKeyDown(e: KeyboardEvent) {
      if (e.key === "Escape" && open) {
        onClose();
      }
    }
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label={title}
      className="fixed inset-0 z-50 overflow-hidden bg-black/30 backdrop-blur-xs transition-opacity"
    >
      <div className="absolute inset-y-0 right-0 flex max-w-full pl-10">
        <div className={`w-screen ${width} bg-white shadow-2xl flex flex-col`}>
          <div className="flex items-start justify-between border-b border-border p-5">
            <div>
              <h2 className="text-base font-semibold text-foreground">{title}</h2>
              {description && (
                <p className="mt-0.5 text-xs text-muted">{description}</p>
              )}
            </div>
            <button
              type="button"
              onClick={onClose}
              aria-label="Close panel"
              className="rounded-lg p-1.5 text-muted hover:bg-slate-100 hover:text-foreground transition"
            >
              <X className="h-5 w-5" />
            </button>
          </div>

          <div className="flex-1 overflow-y-auto p-5 space-y-4">
            {children}
          </div>
        </div>
      </div>
    </div>
  );
}
