"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { ApiError, api } from "./api";
import { useRealtime, type LiveEvent } from "./realtime";

export type Got<T> = {
  data: T | undefined;
  error: ApiError | null;
  loading: boolean;
  reload: () => Promise<void>;
  setData: (next: T | ((prev: T | undefined) => T | undefined)) => void;
};

/** How often a live page re-checks while the socket is down (it is not used while the socket is connected). */
const FALLBACK_MS = 30000;

/**
 * Loads `path` once (nothing while it is null) and reloads on demand. Keeps the last data while refreshing.
 * `live` says which pushes from the server make this data stale (a message, a notification): the page reloads on those,
 * and after a lost connection. Only while the socket is down does it check every 30 s, so nothing is missed.
 */
export function useGet<T>(path: string | null, live?: (e: LiveEvent) => boolean): Got<T> {
  const { connected, subscribe } = useRealtime();
  const [data, setData] = useState<T | undefined>(undefined);
  const [error, setError] = useState<ApiError | null>(null);
  const [loading, setLoading] = useState(!!path);
  const current = useRef(path);
  current.current = path;

  const load = useCallback(async () => {
    if (!path) return;
    try {
      const next = await api<T>(path);
      if (current.current !== path) return;
      setData(next);
      setError(null);
    } catch (e) {
      if (current.current !== path) return;
      setError(e instanceof ApiError ? e : new ApiError(0, "Something went wrong."));
    } finally {
      if (current.current === path) setLoading(false);
    }
  }, [path]);

  useEffect(() => {
    setData(undefined);
    setError(null);
    setLoading(!!path);
    load();
  }, [path, load]);

  // Pushed: reload when the server says this changed, or after the connection was lost and came back.
  useEffect(() => {
    if (!path || !live) return;
    return subscribe((e) => {
      if (e.event === "reconnected" || live(e)) load();
    });
  }, [path, live, subscribe, load]);

  // Socket down: fall back to checking now and then, only while the page is shown.
  useEffect(() => {
    if (!path || !live || connected) return;
    const id = window.setInterval(() => { if (document.visibilityState === "visible") load(); }, FALLBACK_MS);
    return () => window.clearInterval(id);
  }, [path, live, connected, load]);

  return { data, error, loading, reload: load, setData };
}

/** Runs an action with a busy flag and a message for the person when it fails. */
export function useAction() {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const run = useCallback(async (fn: () => Promise<unknown>) => {
    setBusy(true);
    setError("");
    try {
      await fn();
      return true;
    } catch (e) {
      const { messageOf } = await import("./api");
      setError(messageOf(e));
      return false;
    } finally {
      setBusy(false);
    }
  }, []);
  return { busy, error, run, setError };
}
