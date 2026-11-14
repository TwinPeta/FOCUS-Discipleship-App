/**
 * src/providers/SessionProvider.tsx
 *
 * WHAT: Makes the staff session available to client components
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

"use client";

import { createContext, useContext, type ReactNode } from "react";
import type { Session, SessionUser } from "@/types/user";

interface SessionContextValue {
  session: Session | null;
  user: SessionUser | null;
}

const SessionContext = createContext<SessionContextValue>({
  session: null,
  user: null,
});

interface SessionProviderProps {
  session?: Session | null;
  children: ReactNode;
}

export function SessionProvider({ session = null, children }: SessionProviderProps) {
  return (
    <SessionContext.Provider
      value={{
        session,
        user: session?.user ?? null,
      }}
    >
      {children}
    </SessionContext.Provider>
  );
}

export function useSessionContext() {
  return useContext(SessionContext);
}
