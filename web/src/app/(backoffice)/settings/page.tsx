/**
 * src/app/(backoffice)/settings/page.tsx
 *
 * WHAT: B19 Settings: community charter, consent texts, minors rules, data retention
 * REQUIREMENTS: FR-10
 * SPEC: docs/features/14-settings-charter.md
 * STATUS: implemented
 */

import { AuditNotice } from "@/components/common/AuditNotice";
import { CharterForm } from "@/features/settings/components/CharterForm";
import { ConsentTextsForm } from "@/features/settings/components/ConsentTextsForm";
import { MinorsForm } from "@/features/settings/components/MinorsForm";
import { RetentionForm } from "@/features/settings/components/RetentionForm";

export default function SettingsPage() {
  return (
    <div className="mx-auto max-w-4xl space-y-6 p-6">
      <div>
        <h1 className="text-2xl font-bold text-foreground">Settings</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Manage the community charter, legal consent texts, minor safeguarding
          rules, and data retention policy.
        </p>
      </div>

      <AuditNotice message="All changes to legal texts, safeguarding thresholds, and retention rules are recorded in the audit log." />

      <section className="rounded-card border border-border bg-white p-6">
        <h2 className="text-base font-semibold text-foreground">Community charter</h2>
        <div className="mt-4">
          <CharterForm />
        </div>
      </section>

      <section className="rounded-card border border-border bg-white p-6">
        <h2 className="text-base font-semibold text-foreground">Consent texts</h2>
        <div className="mt-4">
          <ConsentTextsForm />
        </div>
      </section>

      <section className="rounded-card border border-border bg-white p-6">
        <h2 className="text-base font-semibold text-foreground">Users under 18</h2>
        <div className="mt-4">
          <MinorsForm />
        </div>
      </section>

      <section className="rounded-card border border-border bg-white p-6">
        <h2 className="text-base font-semibold text-foreground">Data retention</h2>
        <div className="mt-4">
          <RetentionForm />
        </div>
      </section>
    </div>
  );
}
