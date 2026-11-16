"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { CodeInput } from "@/components/CodeInput";
import { SiteHeader } from "@/components/SiteHeader";
import { ApiError, post } from "@/lib/api";
import { useAuth } from "@/lib/auth";

/** Forgot password: the API emails a 6-digit code; the code plus a new password changes it and signs the student in. */
export default function ForgotPassword() {
  const { status, resetPassword } = useAuth();
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [sentTo, setSentTo] = useState("");
  const [code, setCode] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const [resent, setResent] = useState(false);

  useEffect(() => {
    if (status === "signedIn") router.replace("/dashboard");
  }, [status, router]);

  async function request(to: string) {
    setError("");
    setBusy(true);
    try {
      await post("/auth/otp/request", { channel: "email", destination: to, purpose: "password_reset" }, false);
      setSentTo(to);
      return true;
    } catch (e) {
      const err = e as ApiError;
      setError(err.status === 429 ? "You have asked for several codes. Please wait a few minutes and try again." : err.message);
      return false;
    } finally {
      setBusy(false);
    }
  }

  async function verify(e: React.FormEvent) {
    e.preventDefault();
    if (password.length < 8) return setError("Use at least 8 characters for your new password.");
    if (password !== confirm) return setError("The two passwords do not match.");
    setError("");
    setBusy(true);
    try {
      await resetPassword(sentTo, code, password);
    } catch (err) {
      const e2 = err as ApiError;
      setError(
        e2.code === "otp_invalid" ? "That code is not right or has expired. Check it, or send a new one."
          : e2.status === 429 ? "Too many attempts. Please wait a few minutes and try again."
          : e2.status === 422 ? "Use a password of 8 to 128 characters."
          : e2.message,
      );
      setBusy(false);
    }
  }

  return (
    <>
      <SiteHeader />
      <main className="auth wrap">
        <div className="auth-card">
          {sentTo ? (
            <>
              <h1>Check your email</h1>
              <p className="sub">If an account exists for <b>{sentTo}</b>, we sent it a 6-digit code. It works for 10 minutes. Enter it below with your new password. Check your spam folder if it does not arrive.</p>
              <form onSubmit={verify} noValidate>
                {error ? <div className="alert" role="alert">{error}</div> : null}
                <div className="field">
                  <label htmlFor="code">Code</label>
                  <CodeInput id="code" value={code} onChange={setCode} />
                </div>
                <div className="field">
                  <label htmlFor="new-password">New password</label>
                  <input id="new-password" name="new-password" type="password" autoComplete="new-password" value={password} onChange={(e) => setPassword(e.target.value)} />
                  <span className="hint">At least 8 characters.</span>
                </div>
                <div className="field">
                  <label htmlFor="confirm-password">New password again</label>
                  <input id="confirm-password" name="confirm-password" type="password" autoComplete="new-password" value={confirm} onChange={(e) => setConfirm(e.target.value)} />
                </div>
                <button className="btn btn-primary btn-block" type="submit" disabled={busy || code.length !== 6 || !password || !confirm}>
                  {busy ? "Saving…" : "Set new password"}
                </button>
              </form>
              <p className="alt">
                Did not get it?{" "}
                <button className="link-btn" disabled={busy} onClick={async () => { setResent(false); if (await request(sentTo)) setResent(true); }}>Send a new code</button>
                {resent ? <span className="ok-text"> Sent.</span> : null}
              </p>
              <p className="alt" style={{ marginTop: 8 }}><button className="link-btn" onClick={() => { setSentTo(""); setCode(""); setPassword(""); setConfirm(""); setError(""); }}>Use a different email</button></p>
            </>
          ) : (
            <>
              <h1>Forgot your password?</h1>
              <p className="sub">Enter your email and we will send you a code to set a new password.</p>
              <form onSubmit={(e) => { e.preventDefault(); request(email.trim().toLowerCase()); }} noValidate>
                {error ? <div className="alert" role="alert">{error}</div> : null}
                <div className="field">
                  <label htmlFor="email">Email</label>
                  <input id="email" name="email" type="email" autoComplete="email" value={email} onChange={(e) => setEmail(e.target.value)} />
                </div>
                <button className="btn btn-primary btn-block" type="submit" disabled={busy || !/^\S+@\S+\.\S+$/.test(email.trim())}>{busy ? "Sending…" : "Send me a code"}</button>
              </form>
            </>
          )}
          <p className="alt"><Link href="/login">Back to log in</Link></p>
        </div>
      </main>
    </>
  );
}
