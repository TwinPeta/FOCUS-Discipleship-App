/**
 * src/lib/hooks/useRemoteData.ts
 *
 * WHAT: Loads one object from the API for a screen (loading / error / retry). There is no placeholder data:
 *       until the API answers, `data` is null, and if it fails `error` says why.
 * REQUIREMENTS: FR-07
 * STATUS: implemented
 */

"use client";

import { useCallback, useEffect, useRef, useState, type Dispatch, type SetStateAction } from "react";

export interface RemoteData<T> {
  data: T | null;
  setData: Dispatch<SetStateAction<T | null>>;
  loading: boolean;
  error: string | null;
  reload: () => void;
}

export function useRemoteData<T>(load: () => Promise<T>, deps: readonly unknown[] = []): RemoteData<T> {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [attempt, setAttempt] = useState(0);
  const loadRef = useRef(load);
  loadRef.current = load;

  useEffect(() => {
    let active = true;
    setLoading(true);
    setError(null);
    loadRef
      .current()
      .then((res) => {
        if (!active) return;
        setData(res);
        setLoading(false);
      })
      .catch((err: unknown) => {
        if (!active) return;
        setError(err instanceof Error ? err.message : "Failed to load");
        setLoading(false);
      });
    return () => {
      active = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [attempt, ...deps]);

  const reload = useCallback(() => setAttempt((n) => n + 1), []);
  return { data, setData, loading, error, reload };
}
