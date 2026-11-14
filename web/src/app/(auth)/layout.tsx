/**
 * src/app/(auth)/layout.tsx
 *
 * WHAT: Auth shell: split layout with FCU backoffice pitch (approve requests, moderate, validate content) and form card
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

import type { ReactNode } from "react";

export default function AuthLayout({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-screen grid lg:grid-cols-2 bg-background text-foreground">
      <aside className="hidden lg:flex flex-col justify-between bg-primary p-12 text-foreground">
        <div>
          <p className="text-xs font-semibold uppercase tracking-wider">
            FCU Student Community
          </p>
          <h1 className="mt-2 text-3xl font-bold leading-tight">
            Staff Back Office
          </h1>
          <p className="mt-4 max-w-md text-sm leading-relaxed text-foreground/85">
            A calm, focused workspace for campus ministry staff and community
            leaders.
          </p>
        </div>

        <ul className="space-y-3 text-sm font-medium">
          <li>• Approve student join requests and manage communities</li>
          <li>• Validate devotionals, videos, and quizzes before publishing</li>
          <li>• Moderate reports, testimonies, and community spaces safely</li>
        </ul>

        <p className="text-xs text-foreground/75">
          All staff sign-ins and personal data actions are recorded in the audit log.
        </p>
      </aside>

      <main className="flex items-center justify-center p-6 sm:p-10">
        <div className="w-full max-w-md rounded-card border border-border bg-white p-8 shadow-sm">
          {children}
        </div>
      </main>
    </div>
  );
}
