/**
 * src/features/settings/components/PushDeliveryCard.tsx
 *
 * WHAT: Shows whether phone push is set up, how many phones are registered, what happened to recent pushes,
 *       and sends a real test to the signed-in administrator's phone (the answer is the provider's own)
 * REQUIREMENTS: FR-10
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import { apiClient } from "@/lib/api/client";
import { useRemoteData } from "@/lib/hooks/useRemoteData";

interface PushStatus {
  configured: boolean;
  enabled: boolean;
  projectId: string | null;
  devices: { total: number; android: number; ios: number };
  recent: { at: string; user?: string; platform?: string | null; ok: boolean; error?: string }[];
}

export function PushDeliveryCard() {
  const { data, loading, error, reload } = useRemoteData(() => apiClient<PushStatus>("/push/status"));
  const [sending, setSending] = useState(false);
  const [result, setResult] = useState<{ ok: boolean; message: string } | null>(null);

  async function sendTest() {
    setSending(true);
    setResult(null);
    try {
      const out = await apiClient<{ sent: number }>("/push/test", { method: "POST", body: JSON.stringify({}) });
      setResult({ ok: true, message: `Test sent to ${out.sent} phone${out.sent === 1 ? "" : "s"}. It should arrive within a few seconds.` });
    } catch (e) {
      setResult({ ok: false, message: e instanceof Error ? e.message : "The test failed." });
    } finally {
      setSending(false);
      reload();
    }
  }

  if (loading && !data) return <p className="text-sm text-muted-foreground">Loading...</p>;
  if (error || !data) {
    return (
      <p role="alert" className="text-sm text-muted-foreground">
        Only system administrators can see phone push. {error ?? ""}
      </p>
    );
  }

  return (
    <div className="space-y-4 text-sm">
      <dl className="grid gap-x-6 gap-y-1 sm:grid-cols-[auto_1fr]">
        <dt className="text-muted-foreground">Phone push</dt>
        <dd className={data.enabled ? "text-emerald-800" : "font-medium text-red-700"}>
          {data.enabled
            ? `Connected (Firebase project ${data.projectId})`
            : data.configured
              ? "Switched off (PUSH_ENABLED=false)"
              : "Not set up: add the Firebase key (FCM_SERVICE_ACCOUNT_JSON) on the server"}
        </dd>
        <dt className="text-muted-foreground">Phones registered</dt>
        <dd>
          {data.devices.total} ({data.devices.android} Android, {data.devices.ios} iPhone)
        </dd>
      </dl>

      <div className="flex flex-wrap items-center gap-3">
        <button
          type="button"
          onClick={() => void sendTest()}
          disabled={sending}
          className="rounded-md bg-primary px-4 py-2 text-sm font-semibold text-foreground hover:brightness-95 disabled:opacity-60"
        >
          {sending ? "Sending..." : "Send a test to my phone"}
        </button>
        {result && (
          <p role={result.ok ? "status" : "alert"} className={result.ok ? "text-emerald-800" : "text-red-700"}>
            {result.message}
          </p>
        )}
      </div>

      <div>
        <h3 className="font-medium text-foreground">Recent pushes</h3>
        {data.recent.length === 0 ? (
          <p className="mt-1 text-muted-foreground">Nothing sent since the server started.</p>
        ) : (
          <ul className="mt-1 divide-y divide-border rounded-md border border-border">
            {data.recent.map((r, i) => (
              <li key={`${r.at}-${i}`} className="flex flex-wrap items-center justify-between gap-2 px-3 py-2">
                <span>
                  <span className={r.ok ? "text-emerald-800" : "font-medium text-red-700"}>{r.ok ? "Delivered" : "Failed"}</span>{" "}
                  · {r.platform ?? "phone"} · {r.user}
                  {r.error && <span className="block text-xs text-red-700">{r.error}</span>}
                </span>
                <span className="text-xs text-muted-foreground">{new Date(r.at).toLocaleString()}</span>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
