"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { ApiError, api } from "./api";

export type Got<T> = {
  data: T | undefined;
  error: ApiError | null;
  loading: boolean;
  reload: () => Promise<void>;
  setData: (next: T | ((prev: T | undefined) => T | undefined)) => void;
};

/** Loads `path` (nothing while it is null) and reloads on demand or every `pollMs`. Keeps the last data while refreshing. */
export function useGet<T>(path: string | null, pollMs = 0): Got<T> {
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
    if (!path || !pollMs) return;
    const tick = () => { if (document.visibilityState === "visible") load(); };
    const id = window.setInterval(tick, pollMs);
    return () => window.clearInterval(id);
  }, [path, pollMs, load]);

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
