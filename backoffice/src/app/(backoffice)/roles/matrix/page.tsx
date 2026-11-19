/**
 * src/app/(backoffice)/roles/matrix/page.tsx
 *
 * WHAT: Permissions matrix (B30 Backoffice modules, B31 mobile app features) behind two tabs
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import { PageHeader } from "@/components/layout/PageHeader";
import { MobileMatrix } from "@/features/roles/components/MobileMatrix";
import { PermissionMatrix } from "@/features/roles/components/PermissionMatrix";
import { ROUTES } from "@/lib/constants/routes";

type MatrixTab = "backoffice" | "app";

export default function PermissionsMatrixPage() {
  const [tab, setTab] = useState<MatrixTab>("backoffice");

  return (
    <div className="flex flex-col gap-5">
      <PageHeader
        title={tab === "backoffice" ? "Permissions matrix" : "Permissions: mobile app"}
        backHref={ROUTES.roles}
        backLabel="Back to roles"
      />

      <div className="flex flex-wrap gap-2" role="tablist">
        <button type="button" role="tab" aria-selected={tab === "backoffice"} onClick={() => setTab("backoffice")}>
          Backoffice modules
        </button>
        <button type="button" role="tab" aria-selected={tab === "app"} onClick={() => setTab("app")}>
          Mobile app features
        </button>
      </div>

      {tab === "backoffice" ? <PermissionMatrix /> : <MobileMatrix />}
    </div>
  );
}
