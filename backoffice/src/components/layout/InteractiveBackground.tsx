/**
 * src/components/layout/InteractiveBackground.tsx
 *
 * WHAT: Warm cream/gold ambient background with a soft glow that eases toward the pointer, over a faint dot grid.
 *       Static when the user pauses motion, prefers reduced motion, or the tab is hidden.
 *       Writes CSS variables from a rAF loop that stops when settled, so it never re-renders React.
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useRef } from "react";
import { useShell } from "./ShellContext";

const REST = { x: 0.7, y: 0.15 };

export function InteractiveBackground() {
  const { motionPaused } = useShell();
  const glowRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = glowRef.current;
    if (!el) return;

    const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
    const current = { ...REST };
    const target = { ...REST };
    let frame = 0;

    const apply = () => {
      el.style.setProperty("--mx", `${(current.x * 100).toFixed(2)}%`);
      el.style.setProperty("--my", `${(current.y * 100).toFixed(2)}%`);
    };

    const tick = () => {
      current.x += (target.x - current.x) * 0.06;
      current.y += (target.y - current.y) * 0.06;
      apply();
      const settled = Math.abs(target.x - current.x) < 0.001 && Math.abs(target.y - current.y) < 0.001;
      frame = settled ? 0 : requestAnimationFrame(tick);
    };

    const start = () => {
      if (!frame) frame = requestAnimationFrame(tick);
    };

    const isStatic = () => motionPaused || reduceMotion.matches || document.hidden;

    const onPointerMove = (event: PointerEvent) => {
      if (isStatic()) return;
      target.x = event.clientX / window.innerWidth;
      target.y = event.clientY / window.innerHeight;
      start();
    };

    const settleToRest = () => {
      target.x = REST.x;
      target.y = REST.y;
      if (isStatic()) {
        cancelAnimationFrame(frame);
        frame = 0;
        Object.assign(current, REST);
        apply();
      } else {
        start();
      }
    };

    apply();
    if (isStatic()) settleToRest();

    window.addEventListener("pointermove", onPointerMove, { passive: true });
    document.addEventListener("visibilitychange", settleToRest);
    reduceMotion.addEventListener("change", settleToRest);
    return () => {
      cancelAnimationFrame(frame);
      window.removeEventListener("pointermove", onPointerMove);
      document.removeEventListener("visibilitychange", settleToRest);
      reduceMotion.removeEventListener("change", settleToRest);
    };
  }, [motionPaused]);

  return (
    <div aria-hidden="true" className="pointer-events-none fixed inset-0 z-0 overflow-hidden bg-background">
      {/* Fixed warm wash */}
      <div
        className="absolute inset-0"
        style={{
          background:
            "radial-gradient(60rem 40rem at 0% 100%, rgb(var(--accent) / 0.35), transparent 60%)," +
            "linear-gradient(180deg, rgb(var(--background)) 0%, rgb(var(--background-subtle)) 100%)",
        }}
      />
      {/* Faint dot grid, fading toward the bottom */}
      <div
        className="absolute inset-0 opacity-60"
        style={{
          backgroundImage: "radial-gradient(rgb(var(--border) / 0.55) 1px, transparent 1px)",
          backgroundSize: "22px 22px",
          maskImage: "linear-gradient(180deg, black 0%, transparent 75%)",
          WebkitMaskImage: "linear-gradient(180deg, black 0%, transparent 75%)",
        }}
      />
      {/* Pointer-following glow */}
      <div
        ref={glowRef}
        className="absolute inset-0"
        style={{
          background:
            "radial-gradient(36rem 28rem at var(--mx, 70%) var(--my, 15%), rgb(var(--primary) / 0.16), transparent 70%)",
        }}
      />
    </div>
  );
}
