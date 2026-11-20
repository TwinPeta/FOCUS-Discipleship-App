/**
 * src/features/settings/components/EmailDeliveryCard.tsx
 *
 * WHAT: Shows whether email is set up, what recently happened to sent emails, and sends a real test message
 *       (the answer is the email provider's own, so a wrong key or an unverified sender is spelled out)
 * REQUIREMENTS: FR-10
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import { apiClient } from "@/lib/api/client";
import { ApiError } from "@/lib/api/errors";
import { useRemoteData } from "@/lib/hooks/useRemoteData";

interface EmailStatus {
  configured: boolean;
  from: string;
  replyTo: string | null;
  backofficeUrl: string;
  notificationEmails: boolean;
  problems: string[];
  recent: { at: string; template: string; to: string; ok: boolean; id?: string; error?: string }[];
}

export function EmailDeliveryCard() {
  const { data, loading, error, reload } = useRemoteData(() => apiClient<EmailStatus>("/email/status"));
  const [sending, setSending] = useState(false);
  const [result, setResult] = useState<{ ok: boolean; message: string } | null>(null);

  async function sendTest() {
    setSending(true);
    setResult(null);
    try {
      const out = await apiClient<{ to: string }>("/email/test", { method: "POST", body: JSON.stringify({}) });
      setResult({ ok: true, message: `Test email sent to ${out.to}. Check that inbox (and spam).` });
    } catch (e) {
      setResult({ ok: false, message: e instanceof ApiError || e instanceof Error ? e.message : "The test failed." });
    } finally {
      setSending(false);
      reload();
    }
  }

  if (loading && !data) return <p className="text-sm text-muted-foreground">Loading...</p>;
  if (error || !data) {
    return (
      <p role="alert" className="text-sm text-muted-foreground">
        Only system administrators can see email delivery. {error ?? ""}
      </p>
    );
  }

  return (
    <div className="space-y-4 text-sm">
      <dl className="grid gap-x-6 gap-y-1 sm:grid-cols-[auto_1fr]">
        <dt className="text-muted-foreground">Email service</dt>
        <dd className={data.configured ? "text-ink" : "font-medium text-danger"}>
          {data.configured ? "Connected (API key set)" : "Not set up: RESEND_API_KEY is missing"}
        </dd>
        <dt className="text-muted-foreground">Sends from</dt>
        <dd>{data.from}</dd>
        <dt className="text-muted-foreground">Links point to</dt>
        <dd>{data.backofficeUrl}</dd>
        <dt className="text-muted-foreground">Notification emails</dt>
        <dd>{data.notificationEmails ? "On" : "Off"}</dd>
      </dl>

      {data.problems.length > 0 && (
        <ul role="alert" className="space-y-1 rounded-md border border-danger/40 bg-danger-soft p-3 text-danger">
          {data.problems.map((p) => (
            <li key={p}>{p}</li>
          ))}
        </ul>
      )}

      <div className="flex flex-wrap items-center gap-3">
        <button
          type="button"
          onClick={() => void sendTest()}
          disabled={sending}
          className="rounded-md bg-primary px-4 py-2 text-sm font-semibold text-foreground hover:brightness-95 disabled:opacity-60"
        >
          {sending ? "Sending..." : "Send me a test email"}
        </button>
        {result && (
          <p role={result.ok ? "status" : "alert"} className={result.ok ? "text-ink" : "text-danger"}>
            {result.message}
          </p>
        )}
      </div>

      <div>
        <h3 className="font-medium text-foreground">Recent emails</h3>
        {data.recent.length === 0 ? (
          <p className="mt-1 text-muted-foreground">Nothing sent since the server started.</p>
        ) : (
          <ul className="mt-1 divide-y divide-border rounded-md border border-border">
            {data.recent.map((r, i) => (
              <li key={`${r.at}-${i}`} className="flex flex-wrap items-center justify-between gap-2 px-3 py-2">
                <span>
                  <span className={r.ok ? "text-ink" : "font-medium text-danger"}>{r.ok ? "Sent" : "Failed"}</span>{" "}
                  · {r.template} · {r.to}
                  {r.error && <span className="block text-xs text-danger">{r.error}</span>}
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
