/**
 * src/providers/SessionProvider.tsx
 *
 * WHAT: Makes the staff session available to client components
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

"use client";

import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import type { Session, SessionUser } from "@/types/user";

interface SessionContextValue {
  session: Session | null;
  user: SessionUser | null;
  /** Optimistically patch the current user (e.g. after editing the profile) until the server session refreshes. */
  updateUser: (patch: Partial<SessionUser>) => void;
}

const SessionContext = createContext<SessionContextValue>({
  session: null,
  user: null,
  updateUser: () => {},
});

interface SessionProviderProps {
  session?: Session | null;
  children: ReactNode;
}

export function SessionProvider({ session = null, children }: SessionProviderProps) {
  const [patch, setPatch] = useState<Partial<SessionUser>>({});

  // A fresh server session replaces any local patch.
  useEffect(() => {
    setPatch({});
  }, [session]);

  const updateUser = useCallback((next: Partial<SessionUser>) => {
    setPatch((prev) => ({ ...prev, ...next }));
  }, []);

  const value = useMemo<SessionContextValue>(() => {
    const user = session?.user ? { ...session.user, ...patch } : null;
    return { session: session && user ? { ...session, user } : session, user, updateUser };
  }, [session, patch, updateUser]);

  return <SessionContext.Provider value={value}>{children}</SessionContext.Provider>;
}

export function useSessionContext() {
  return useContext(SessionContext);
}
