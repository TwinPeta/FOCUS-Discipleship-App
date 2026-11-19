/**
 * src/app/(backoffice)/privacy/layout.tsx
 *
 * WHAT: Privacy shell with tabs: guardian consents and data requests
 * REQUIREMENTS: FR-10
 * SPEC: docs/features/12-privacy-consents.md
 * STATUS: implemented
 */

"use client";

import type { ReactNode } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { AuditNotice } from "@/components/common/AuditNotice";
import { ROUTES } from "@/lib/constants/routes";

export default function PrivacyLayout({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const tabs = [
    { href: ROUTES.guardianConsents, label: "Guardian consents" },
    { href: ROUTES.dataRequests, label: "Data requests" },
  ];

  return (
    <div className="flex flex-col gap-5">
      <div>
        <h1 className="text-[34px] leading-[1.05]">Consents &amp; data requests</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Manage minor guardian consents and personal data export or deletion
          requests (30-day statutory deadline).
        </p>
      </div>


      <nav
        aria-label="Privacy sections"
        className="flex flex-wrap gap-2"
      >
        {tabs.map((tab) => {
          const active = pathname === tab.href;
          return (
            <Link
              key={tab.href}
              href={tab.href}
              className="tab"
            aria-current={active ? "page" : undefined}
            >
              {tab.label}
            </Link>
          );
        })}
      </nav>

      <AuditNotice message="All consent reminders, data exports, and deletions are recorded in the audit log." />

      {children}
    </div>
  );
}
