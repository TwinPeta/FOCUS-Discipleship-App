/**
 * src/app/(auth)/layout.tsx
 *
 * WHAT: Sign-in layout: yellow brand panel (Backoffice, three promises, caregroup illustration) beside the form column
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

import type { ReactNode } from "react";
import { BookOpen, Check, ShieldCheck } from "lucide-react";

const PROMISES = [
  { icon: Check, text: "Welcome new members" },
  { icon: ShieldCheck, text: "Moderate reports and stories" },
  { icon: BookOpen, text: "Validate and publish content" },
];

export default function AuthLayout({ children }: { children: ReactNode }) {
  return (
    <div className="flex min-h-screen flex-wrap bg-gradient-to-b from-[#FFF1D4] via-[#FFFAF2] via-[34%] to-[#FFFAF2] text-ink">
      <aside className="hidden min-h-[560px] min-w-0 flex-[1_1_420px] flex-col justify-between gap-7 bg-[linear-gradient(135deg,#FFEDB0_0%,#FFD25E_55%,#F5B72E_130%)] px-12 py-10 lg:flex">
        <div className="flex items-center gap-3">
          <span className="grid h-12 w-12 place-items-center rounded-[14px] bg-white text-base font-black">FCU</span>
          <span className="text-lg font-extrabold leading-[1.05]">
            Fellowship of
            <br />
            Christian Unions
          </span>
        </div>

        <div className="flex flex-col gap-4">
          <h1 className="text-[56px] leading-[0.96] tracking-[-0.035em]">Backoffice</h1>
          <p className="max-w-[420px] text-[21px] leading-[1.35]">
            Manage caregroups, mentors, content and moderation for student caregroups.
          </p>
          <ul className="mt-1.5 flex flex-col gap-2.5">
            {PROMISES.map(({ icon: Icon, text }) => (
              <li key={text} className="flex items-center gap-3 text-lg font-bold">
                <span className="grid h-9 w-9 flex-none place-items-center rounded-[10px] bg-white">
                  <Icon className="h-5 w-5" aria-hidden="true" />
                </span>
                {text}
              </li>
            ))}
          </ul>
        </div>

        <svg viewBox="0 0 420 110" width="100%" height="110" aria-hidden="true" className="block max-w-[420px]">
          <circle cx="70" cy="70" r="52" fill="#FDE68A" />
          <circle cx="190" cy="62" r="62" fill="#1F2D3D" />
          <circle cx="320" cy="76" r="48" fill="#E3F0FD" />
          <circle cx="190" cy="40" r="14" fill="#F4B400" />
          <path d="M164 90c0-16 11-26 26-26s26 10 26 26z" fill="#F4B400" />
        </svg>
      </aside>

      <main className="auth-form flex min-w-0 flex-[1_1_420px] items-center justify-center bg-[#F5F6F8] px-6 py-10 sm:px-12">
        <div className="flex w-full max-w-[420px] flex-col gap-[18px]">{children}</div>
      </main>
    </div>
  );
}
