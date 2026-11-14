/**
 * src/features/account/components/SessionsList.tsx
 *
 * WHAT: Signed-in devices list with sign-out per session
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useState } from "react";
import { Laptop } from "lucide-react";
import { fetchActiveSessions, revokeSession } from "@/features/account/queries";
import type { StaffSessionDevice } from "@/types/user";

export function SessionsList() {
  const [sessions, setSessions] = useState<StaffSessionDevice[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [revokingId, setRevokingId] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    fetchActiveSessions()
      .then((list) => {
        if (active) setSessions(list);
      })
      .catch(() => {
        if (active) setError("Unable to load active sessions.");
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, []);

  async function handleSignOut(id: string) {
    setRevokingId(id);
    try {
      await revokeSession(id);
      setSessions((prev) => prev.filter((item) => item.id !== id));
    } catch {
      setError("Failed to sign out that session.");
    } finally {
      setRevokingId(null);
    }
  }

  if (loading) {
    return <p className="text-sm text-muted-foreground">Loading active sessions...</p>;
  }

  if (error) {
    return (
      <p role="alert" className="text-sm text-red-700">
        {error}
      </p>
    );
  }

  if (sessions.length === 0) {
    return <p className="text-sm text-muted-foreground">No other active sessions.</p>;
  }

  return (
    <ul className="divide-y divide-border rounded-md border border-border bg-white">
      {sessions.map((item) => (
        <li
          key={item.id}
          className="flex flex-wrap items-center justify-between gap-3 px-4 py-3 text-sm"
        >
          <div className="flex items-start gap-3">
            <Laptop className="mt-0.5 h-4 w-4 text-muted-foreground" aria-hidden="true" />
            <div>
              <p className="font-medium text-foreground">
                {item.deviceName}
                {item.current && (
                  <span className="ml-2 rounded-full bg-primary-soft px-2 py-0.5 text-xs font-semibold text-foreground">
                    This device
                  </span>
                )}
              </p>
              <p className="text-xs text-muted-foreground">
                {[item.browser, item.os, item.location, item.ipAddress]
                  .filter(Boolean)
                  .join(" · ")}
              </p>
            </div>
          </div>

          {!item.current && (
            <button
              type="button"
              onClick={() => handleSignOut(item.id)}
              disabled={revokingId === item.id}
              className="rounded-md border border-border px-3 py-1.5 text-xs font-medium text-foreground hover:bg-surface disabled:opacity-60"
            >
              {revokingId === item.id ? "Signing out..." : "Sign out"}
            </button>
          )}
        </li>
      ))}
    </ul>
  );
}
