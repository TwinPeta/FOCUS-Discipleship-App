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
import { PushDeliveryCard } from "@/features/settings/components/PushDeliveryCard";
import { EmailDeliveryCard } from "@/features/settings/components/EmailDeliveryCard";
import { MinorsForm } from "@/features/settings/components/MinorsForm";
import { JoinRequestsForm } from "@/features/settings/components/JoinRequestsForm";
import { RetentionForm } from "@/features/settings/components/RetentionForm";

export default function SettingsPage() {
  return (
    <div className="flex flex-col gap-5">
      <div>
        <h1 className="text-[34px] leading-[1.05]">Settings</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Manage the community charter, legal consent texts, minor safeguarding
          rules, and data retention policy.
        </p>
      </div>

      <AuditNotice message="All changes to legal texts, safeguarding thresholds, and retention rules are recorded in the audit log." />

      <section className="rounded-card border border-border bg-white p-6">
        <h2 className="eyebrow">Caregroup charter</h2>
        <div className="mt-4">
          <CharterForm />
        </div>
      </section>

      <section className="rounded-card border border-border bg-white p-6">
        <h2 className="eyebrow">Consent texts</h2>
        <div className="mt-4">
          <ConsentTextsForm />
        </div>
      </section>

      <section className="rounded-card border border-border bg-white p-6">
        <h2 className="eyebrow">Users under 18</h2>
        <div className="mt-4">
          <MinorsForm />
        </div>
      </section>

      <section className="rounded-card border border-border bg-white p-6">
        <h2 className="eyebrow">New members</h2>
        <div className="mt-4">
          <JoinRequestsForm />
        </div>
      </section>

      <section className="rounded-card border border-border bg-white p-6">
        <h2 className="eyebrow">Data retention</h2>
        <div className="mt-4">
          <RetentionForm />
        </div>
      </section>

      <section className="rounded-card border border-border bg-white p-6">
        <h2 className="eyebrow">Email delivery</h2>
        <div className="mt-4">
          <EmailDeliveryCard />
        </div>
      </section>

      <section className="rounded-card border border-border bg-white p-6">
        <h2 className="eyebrow">Phone push notifications</h2>
        <div className="mt-4">
          <PushDeliveryCard />
        </div>
      </section>
    </div>
  );
}
