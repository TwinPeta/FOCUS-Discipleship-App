"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { SiteHeader } from "@/components/SiteHeader";
import { ApiError } from "@/lib/api";
import { useAuth } from "@/lib/auth";

export default function LoginPage() {
  const { status, signIn } = useAuth();
  const router = useRouter();
  const [identifier, setIdentifier] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const [show, setShow] = useState(false);

  useEffect(() => {
    if (status === "signedIn") router.replace("/dashboard");
  }, [status, router]);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setBusy(true);
    try {
      await signIn(identifier.trim(), password);
    } catch (err) {
      const e2 = err as ApiError;
      setError(
        e2.status === 401 ? "That email, phone or username and password do not match."
          : e2.status === 429 ? "Too many attempts. Please wait a few minutes and try again."
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
          <h1>Welcome back</h1>
          <p className="sub">Log in with the same account you use in the mobile app.</p>
          <form onSubmit={onSubmit} noValidate>
            {error ? <div className="alert" role="alert">{error}</div> : null}
            <div className="field">
              <label htmlFor="identifier">Email, phone or username</label>
              <input id="identifier" name="identifier" autoComplete="username" required value={identifier}
                onChange={(e) => setIdentifier(e.target.value)} />
            </div>
            <div className="field">
              <label htmlFor="password">Password</label>
              <div style={{ display: "flex", gap: 8 }}>
                <input id="password" name="password" type={show ? "text" : "password"} autoComplete="current-password" required value={password}
                  style={{ flex: 1 }} onChange={(e) => setPassword(e.target.value)} />
                <button type="button" className="btn btn-sm" aria-pressed={show} onClick={() => setShow((v) => !v)}>{show ? "Hide" : "Show"}</button>
              </div>
            </div>
            <button className="btn btn-primary btn-block" type="submit" disabled={busy || !identifier || !password}>
              {busy ? "Logging in…" : "Log in"}
            </button>
          </form>
          <p className="alt"><Link href="/forgot-password">Forgot your password?</Link></p>
          <p className="alt" style={{ marginTop: 8 }}>New here? <Link href="/signup">Create an account</Link></p>
        </div>
      </main>
    </>
  );
}
