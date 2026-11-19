"use client";

import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from "react";
import { API_URL } from "./config";
import { readTokens, refreshSession } from "./api";
import { useAuth } from "./auth";

/** One push from the server (`api/src/realtime/socket.js`). `reconnected` is added here, after a gap. */
export type LiveEvent = { event: string; data: Record<string, unknown>; at?: string };
type Handler = (e: LiveEvent) => void;

type Ctx = { connected: boolean; subscribe: (h: Handler) => () => void; publish: (e: LiveEvent) => void };
const RealtimeCtx = createContext<Ctx>({ connected: false, subscribe: () => () => undefined, publish: () => undefined });

const BACKOFF = [1000, 2000, 5000, 10000, 30000];
const UNAUTHORIZED = 4401;

/** `http(s)://host/v1` becomes `ws(s)://host/v1/realtime`. */
export function realtimeUrl(token: string): string {
  const base = API_URL.replace(/^http/, "ws");
  return `${base}/realtime?token=${encodeURIComponent(token)}`;
}

/**
 * Keeps one WebSocket open while the student is signed in: messages, notifications and join requests arrive as they
 * happen, so pages load their data once and update from these events. It reconnects with a growing wait, renews the
 * session when the server says the token is old, and after a gap tells listeners to reload what they may have missed.
 */
export function RealtimeProvider({ children }: { children: React.ReactNode }) {
  const { status } = useAuth();
  const [connected, setConnected] = useState(false);
  const handlers = useRef(new Set<Handler>());

  const subscribe = useCallback((h: Handler) => {
    handlers.current.add(h);
    return () => {
      handlers.current.delete(h);
    };
  }, []);

  /** Tells this tab's pages about a change the student made themselves (reading a chat), which the server does not push back. */
  const publish = useCallback((e: LiveEvent) => handlers.current.forEach((h) => h(e)), []);

  useEffect(() => {
    if (status !== "signedIn") return;
    let stopped = false;
    let socket: WebSocket | null = null;
    let attempt = 0;
    let timer: number | undefined;
    let hadConnection = false;
    let refreshedFor401 = false;

    const emit = (e: LiveEvent) => handlers.current.forEach((h) => h(e));

    function open() {
      if (stopped) return;
      const tokens = readTokens();
      if (!tokens) return;
      let ws: WebSocket;
      try {
        ws = new WebSocket(realtimeUrl(tokens.access_token));
      } catch {
        return schedule();
      }
      socket = ws;
      ws.onopen = () => {
        attempt = 0;
        refreshedFor401 = false;
        setConnected(true);
        // Anything pushed while we were away is gone: ask pages to reload once.
        if (hadConnection) emit({ event: "reconnected", data: {} });
        hadConnection = true;
      };
      ws.onmessage = (m) => {
        try {
          const e = JSON.parse(String(m.data)) as LiveEvent;
          if (e && typeof e.event === "string") emit({ ...e, data: e.data && typeof e.data === "object" ? e.data : {} });
        } catch {
          /* not one of ours */
        }
      };
      ws.onerror = () => undefined;
      ws.onclose = async (ev) => {
        if (socket !== ws) return;
        socket = null;
        setConnected(false);
        if (stopped) return;
        if (ev.code === UNAUTHORIZED && !refreshedFor401) {
          refreshedFor401 = true;
          const next = await refreshSession(tokens.access_token);
          if (stopped) return;
          if (next) return open();
          return; // the session is over; signing in again starts a new socket
        }
        schedule();
      };
    }

    function schedule() {
      if (stopped) return;
      const wait = BACKOFF[Math.min(attempt, BACKOFF.length - 1)];
      attempt++;
      timer = window.setTimeout(open, wait);
    }

    // Back online, or the tab is shown again: do not wait out the backoff.
    const wake = () => {
      if (stopped || socket || document.visibilityState === "hidden") return;
      window.clearTimeout(timer);
      attempt = 0;
      open();
    };
    window.addEventListener("online", wake);
    document.addEventListener("visibilitychange", wake);
    open();

    return () => {
      stopped = true;
      window.clearTimeout(timer);
      window.removeEventListener("online", wake);
      document.removeEventListener("visibilitychange", wake);
      const ws = socket;
      socket = null;
      ws?.close();
      setConnected(false);
    };
  }, [status]);

  const value = useMemo(() => ({ connected, subscribe, publish }), [connected, subscribe, publish]);
  return <RealtimeCtx.Provider value={value}>{children}</RealtimeCtx.Provider>;
}

export const useRealtime = () => useContext(RealtimeCtx);

/** Runs `handler` for every push whose name is in `events` (plus `reconnected` when `catchUp`). */
export function useLive(events: string[], handler: Handler, catchUp = true) {
  const { subscribe } = useRealtime();
  const ref = useRef(handler);
  ref.current = handler;
  const key = events.join("|");
  useEffect(
    () =>
      subscribe((e) => {
        if (events.includes(e.event) || (catchUp && e.event === "reconnected")) ref.current(e);
      }),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [subscribe, key, catchUp],
  );
}

/** Ready-made "this changed" tests for `useGet`. Defined once, so a page's data is not reloaded needlessly. */
export const onMessage = (e: LiveEvent) => e.event === "message.created" || e.event === "message.read" || e.event === "local.messages";
export const onNotification = (e: LiveEvent) => e.event === "notification.created" || e.event === "local.notifications";
export const onJoinRequest = (e: LiveEvent) => e.event === "join_request.created" || e.event === "join_request.decided";
