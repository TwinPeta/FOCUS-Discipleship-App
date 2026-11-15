/**
 * src/app/(auth)/login/page.tsx
 *
 * WHAT: B10 Login: work email, password, keep me signed in, forgot password link
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

import { redirect } from "next/navigation";
import { LoginForm } from "@/features/auth/components/LoginForm";
import { getServerSession } from "@/lib/auth/session";
import { getHomeRouteForRole } from "@/lib/constants/routes";

interface LoginPageProps {
  searchParams: Promise<{ returnTo?: string; error?: string }>;
}

export default async function LoginPage({ searchParams }: LoginPageProps) {
  const params = await searchParams;

  // Someone who is already signed in has no reason to see the form (a stale cookie does not count: the API decides)
  const session = await getServerSession();
  if (session) redirect(getHomeRouteForRole(session.user.role));

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-xl font-bold text-foreground">Sign in</h2>
        <p className="mt-1 text-sm text-muted-foreground">
          Use your staff work email and password to continue.
        </p>
      </div>

      <LoginForm
        returnTo={params.returnTo ?? null}
        initialError={params.error ?? null}
      />
    </div>
  );
}
