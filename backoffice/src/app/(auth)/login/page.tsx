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
    <>
      <div>
        <h2 className="text-4xl font-black leading-[1.05] tracking-[-0.02em]">Sign in</h2>
        <p className="mt-1.5 text-[17px] opacity-85">Authorised staff only.</p>
      </div>

      <LoginForm
        returnTo={params.returnTo ?? null}
        initialError={params.error ?? null}
      />
    </>
  );
}
