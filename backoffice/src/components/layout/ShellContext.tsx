/**
 * src/components/layout/ShellContext.tsx
 *
 * WHAT: Shared UI state for the app shell: sidebar expanded/mobile-open, command palette, profile dialog,
 *       and ambient background motion. Preferences persist in localStorage.
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";

const SIDEBAR_KEY = "fcu-sidebar-expanded";
const MOTION_KEY = "fcu-motion-paused";

interface ShellState {
  sidebarExpanded: boolean;
  toggleSidebar: () => void;
  mobileNavOpen: boolean;
  setMobileNavOpen: (open: boolean) => void;
  paletteOpen: boolean;
  setPaletteOpen: (open: boolean) => void;
  profileOpen: boolean;
  setProfileOpen: (open: boolean) => void;
  motionPaused: boolean;
  toggleMotion: () => void;
}

const ShellContext = createContext<ShellState | null>(null);

function readFlag(key: string): boolean {
  try {
    return window.localStorage.getItem(key) === "1";
  } catch {
    return false;
  }
}

function writeFlag(key: string, value: boolean) {
  try {
    window.localStorage.setItem(key, value ? "1" : "0");
  } catch {
    /* storage unavailable (private mode); preference just won't persist */
  }
}

export function ShellProvider({ children }: { children: ReactNode }) {
  // Collapsed by default; read stored preference after mount to avoid hydration mismatch.
  const [sidebarExpanded, setSidebarExpanded] = useState(false);
  const [motionPaused, setMotionPaused] = useState(false);
  const [mobileNavOpen, setMobileNavOpen] = useState(false);
  const [paletteOpen, setPaletteOpen] = useState(false);
  const [profileOpen, setProfileOpen] = useState(false);

  useEffect(() => {
    setSidebarExpanded(readFlag(SIDEBAR_KEY));
    setMotionPaused(readFlag(MOTION_KEY));
  }, []);

  const toggleSidebar = useCallback(() => {
    setSidebarExpanded((prev) => {
      writeFlag(SIDEBAR_KEY, !prev);
      return !prev;
    });
  }, []);

  const toggleMotion = useCallback(() => {
    setMotionPaused((prev) => {
      writeFlag(MOTION_KEY, !prev);
      return !prev;
    });
  }, []);

  // Global Ctrl/Cmd+K opens the command palette.
  useEffect(() => {
    function onKeyDown(event: KeyboardEvent) {
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
        event.preventDefault();
        setProfileOpen(false);
        setPaletteOpen((open) => !open);
      }
    }
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, []);

  const value = useMemo<ShellState>(
    () => ({
      sidebarExpanded,
      toggleSidebar,
      mobileNavOpen,
      setMobileNavOpen,
      paletteOpen,
      setPaletteOpen,
      profileOpen,
      setProfileOpen,
      motionPaused,
      toggleMotion,
    }),
    [sidebarExpanded, toggleSidebar, mobileNavOpen, paletteOpen, profileOpen, motionPaused, toggleMotion],
  );

  return <ShellContext.Provider value={value}>{children}</ShellContext.Provider>;
}

export function useShell(): ShellState {
  const ctx = useContext(ShellContext);
  if (!ctx) throw new Error("useShell must be used inside <ShellProvider>");
  return ctx;
}
