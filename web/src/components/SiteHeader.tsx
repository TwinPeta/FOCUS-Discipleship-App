"use client";

import Link from "next/link";
import { useAuth } from "@/lib/auth";

/** Header shared by every page. Signed-in students see "Dashboard" in place of "Log in" and "Sign up". */
export function SiteHeader({ variant = "public" }: { variant?: "public" | "dashboard" }) {
  const { status, signOut } = useAuth();
  return (
    <header className="site-header">
      <div className="wrap">
        <Link href="/" className="logo" aria-label="FCU Student Community, home">
          <span className="logo-mark" aria-hidden="true">FCU</span>
          <span className="logo-text">Student Community</span>
        </Link>
        <nav className="nav" aria-label="Account">
          <div className="nav-slot">
            {variant === "dashboard" ? (
              <button type="button" className="btn btn-sm" onClick={() => signOut()}>Log out</button>
            ) : status === "signedIn" ? (
              <Link href="/dashboard" className="btn btn-primary btn-sm">Dashboard</Link>
            ) : status === "signedOut" ? (
              <>
                <Link href="/login" className="btn btn-ghost btn-sm">Log in</Link>
                <Link href="/signup" className="btn btn-primary btn-sm">Sign up</Link>
              </>
            ) : null}
          </div>
        </nav>
      </div>
    </header>
  );
}
