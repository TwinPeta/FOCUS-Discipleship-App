/**
 * src/lib/hooks/useRemoteItems.ts
 *
 * WHAT: Holds a list in local state, seeded with `initial`, and replaces it with the backend's list once loaded
 * REQUIREMENTS: FR-07
 * SPEC: docs/api-needs.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useRef, useState, type Dispatch, type SetStateAction } from "react";

export interface RemoteState {
  loading: boolean;
  error: string | null;
}

/**
 * Same shape as `useState(initial)` so tables keep their local optimistic updates,
 * but the list is loaded from the API on mount. If the request fails the seed list
 * stays in place and `error` is set.
 */
export function useRemoteItems<T>(
  initial: T[],
  load: () => Promise<T[]>,
): [T[], Dispatch<SetStateAction<T[]>>, RemoteState] {
  const [items, setItems] = useState<T[]>(initial);
  const [state, setState] = useState<RemoteState>({ loading: true, error: null });
  const loadRef = useRef(load);
  loadRef.current = load;

  useEffect(() => {
    let active = true;
    loadRef
      .current()
      .then((list) => {
        if (!active) return;
        setItems(list);
        setState({ loading: false, error: null });
      })
      .catch((err: unknown) => {
        if (!active) return;
        setState({
          loading: false,
          error: err instanceof Error ? err.message : "Failed to load",
        });
      });
    return () => {
      active = false;
    };
  }, []);

  return [items, setItems, state];
}
