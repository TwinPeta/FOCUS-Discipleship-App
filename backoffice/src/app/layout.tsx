/**
 * src/app/layout.tsx
 *
 * WHAT: Root layout: Source Sans 3 font, metadata, client providers, toast alerts
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import type { ReactNode } from "react";
import { Source_Sans_3 } from "next/font/google";
import { Providers } from "@/providers/Providers";
import "./globals.css";

const sourceSans = Source_Sans_3({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700", "800", "900"],
  display: "swap",
  variable: "--font-sans",
});

export const metadata = {
  title: "FCU Backoffice",
  description: "Manage caregroups, mentors, content and moderation for student caregroups.",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en" className={sourceSans.variable}>
      <body className="min-h-screen bg-background font-sans text-foreground antialiased selection:bg-primary selection:text-white">
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
