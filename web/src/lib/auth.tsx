"use client";

import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import { ApiError, api, post, readTokens, writeTokens } from "./api";
import type { Profile, Session } from "./types";

type State = {
  /** "loading" until this browser's saved session has been checked. */
  status: "loading" | "signedIn" | "signedOut";
  user: Profile | null;
  signIn: (identifier: string, password: string) => Promise<void>;
  register: (body: Record<string, unknown>) => Promise<void>;
  /** Forgot password: sets a new password with the 6-digit code the API emailed, and signs in. */
  resetPassword: (destination: string, code: string, newPassword: string) => Promise<void>;
  signOut: () => Promise<void>;
  /** Replaces the cached profile after the student edits it. */
  setUser: (u: Profile) => void;
};

const Ctx = createContext<State | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [status, setStatus] = useState<State["status"]>("loading");
  const [user, setUser] = useState<Profile | null>(null);

  const load = useCallback(async () => {
    if (!readTokens()) {
      setUser(null);
      setStatus("signedOut");
      return;
    }
    // A saved session counts as signed in at once, so the header does not flash "Log in".
    setStatus("signedIn");
    try {
      setUser(await api<Profile>("/me"));
    } catch (e) {
      if (e instanceof ApiError && e.status === 401) {
        writeTokens(null);
        setUser(null);
        setStatus("signedOut");
      }
    }
  }, []);

  useEffect(() => {
    load();
    // Signing in or out in another tab (or a refresh that failed) updates this one too.
    const onChange = () => {
      if (!readTokens()) {
        setUser(null);
        setStatus("signedOut");
      }
    };
    const onStorage = () => load();
    window.addEventListener("fcu:session", onChange);
    window.addEventListener("storage", onStorage);
    return () => {
      window.removeEventListener("fcu:session", onChange);
      window.removeEventListener("storage", onStorage);
    };
  }, [load]);

  const accept = useCallback((s: Session) => {
    writeTokens(s);
    setUser(s.user);
    setStatus("signedIn");
  }, []);

  const value = useMemo<State>(
    () => ({
      status,
      user,
      signIn: async (identifier, password) => accept(await post<Session>("/auth/login", { identifier, password }, false)),
      register: async (body) => accept(await post<Session>("/auth/register", body, false)),
      resetPassword: async (destination, code, newPassword) =>
        accept(await post<Session>("/auth/password/reset", { destination, code, new_password: newPassword }, false)),
      setUser,
      signOut: async () => {
        const t = readTokens();
        try {
          if (t) await post("/auth/logout", { refresh_token: t.refresh_token });
        } catch {
          /* signing out locally is enough */
        }
        writeTokens(null);
        setUser(null);
        setStatus("signedOut");
      },
    }),
    [status, user, accept],
  );

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useAuth(): State {
  const v = useContext(Ctx);
  if (!v) throw new Error("useAuth must be used inside AuthProvider");
  return v;
}
