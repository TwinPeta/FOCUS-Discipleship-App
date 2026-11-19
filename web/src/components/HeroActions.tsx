"use client";

import Link from "next/link";
import { useAuth } from "@/lib/auth";
import { ANDROID_URL, IOS_URL } from "@/lib/config";

export function DownloadButtons({ dark = false }: { dark?: boolean }) {
  const cls = `store-btn${dark ? " store-btn-dark" : ""}`;
  return (
    <>
      {ANDROID_URL ? (
        <a className={cls} href={ANDROID_URL} rel="noopener" aria-label="Download for Android">
          <i className="bx bxl-play-store" aria-hidden="true" />
          <span><small>Download for</small>Android</span>
        </a>
      ) : null}
      {IOS_URL ? (
        <a className={cls} href={IOS_URL} rel="noopener" aria-label="Download for iPhone">
          <i className="bx bxl-apple" aria-hidden="true" />
          <span><small>Download for</small>iPhone</span>
        </a>
      ) : null}
    </>
  );
}

/** Calls to action that follow the sign-in state: download, plus either "use it in your browser" or "Dashboard". */
export function HeroActions({ dark = true }: { dark?: boolean }) {
  const { status } = useAuth();
  return (
    <div className="cta-row">
      <DownloadButtons dark={dark} />
      {status === "signedIn" ? (
        <Link href="/dashboard" className="btn btn-primary">Go to your dashboard</Link>
      ) : (
        <>
          <Link href="/signup" className={dark ? "btn" : "btn btn-primary"}>Use the web app</Link>
          {dark ? null : <Link href="/login" className="btn">Log in</Link>}
        </>
      )}
    </div>
  );
}
