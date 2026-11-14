/**
 * src/components/common/ModalDialog.tsx
 *
 * WHAT: Thin wrapper over native <dialog>.showModal(): focus trapping, Esc to close, backdrop click to close,
 *       top-layer rendering and CSS entry/exit animation (see .fcu-dialog in globals.css)
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useRef, type ReactNode } from "react";

interface ModalDialogProps {
  open: boolean;
  onClose: () => void;
  /** id of the element that names the dialog */
  labelledBy: string;
  /** Classes for the dialog box (position, size). Content padding belongs on children. */
  className?: string;
  variant?: "center" | "drawer";
  children: ReactNode;
}

export function ModalDialog({
  open,
  onClose,
  labelledBy,
  className = "",
  variant = "center",
  children,
}: ModalDialogProps) {
  const ref = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const dialog = ref.current;
    if (!dialog) return;
    if (open && !dialog.open) dialog.showModal();
    if (!open && dialog.open) dialog.close();
  }, [open]);

  return (
    <dialog
      ref={ref}
      aria-labelledby={labelledBy}
      onClose={onClose}
      // A click whose target is the <dialog> itself landed on the backdrop.
      onClick={(event) => event.target === event.currentTarget && onClose()}
      className={`fcu-dialog ${variant === "drawer" ? "fcu-dialog--drawer" : ""} bg-transparent p-0 text-foreground backdrop:bg-transparent ${className}`}
    >
      {children}
    </dialog>
  );
}
