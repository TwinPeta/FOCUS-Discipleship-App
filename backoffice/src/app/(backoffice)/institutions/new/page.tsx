/**
 * src/app/(backoffice)/institutions/new/page.tsx
 *
 * WHAT: Create institution page
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/03-institutions-communities.md
 * STATUS: implemented
 */

"use client";

import { useRouter } from "next/navigation";
import { InstitutionForm } from "@/features/institutions/components/InstitutionForm";
import { createInstitution } from "@/features/institutions/queries";
import type { InstitutionInput } from "@/features/institutions/schemas";
import { ROUTES } from "@/lib/constants/routes";

export default function NewInstitutionPage() {
  const router = useRouter();

  async function handleCreate(values: InstitutionInput) {
    await createInstitution(values);
    router.push(ROUTES.institutions);
    router.refresh();
  }

  return (
    <div className="flex flex-col gap-5">
      <div>
        <h1 className="text-[34px] leading-[1.05]">New campus</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Add a university or high school. A general caregroup will be created
          automatically.
        </p>
      </div>

      <div className="rounded-card border border-border bg-white p-6">
        <InstitutionForm
          onSubmit={handleCreate}
          onCancel={() => router.push(ROUTES.institutions)}
        />
      </div>
    </div>
  );
}
