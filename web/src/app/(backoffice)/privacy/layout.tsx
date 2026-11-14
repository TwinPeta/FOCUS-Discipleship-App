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
    <div className="space-y-6 p-6">
      <div>
        <h1 className="text-2xl font-bold text-foreground">Privacy &amp; consents</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Manage minor guardian consents and personal data export or deletion
          requests (30-day statutory deadline).
        </p>
      </div>

      <AuditNotice message="All consent reminders, data exports, and deletions are recorded in the audit log." />

      <nav
        aria-label="Privacy sections"
        className="flex gap-2 border-b border-border pb-2"
      >
        {tabs.map((tab) => {
          const active = pathname === tab.href;
          return (
            <Link
              key={tab.href}
              href={tab.href}
              className={`rounded-md px-3 py-1.5 text-sm font-medium ${
                active
                  ? "bg-primary text-foreground"
                  : "text-muted-foreground hover:bg-surface"
              }`}
            >
              {tab.label}
            </Link>
          );
        })}
      </nav>

      {children}
    </div>
  );
}
