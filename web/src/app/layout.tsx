/**
 * src/app/layout.tsx
 *
 * WHAT: Root layout: Source Sans 3 font, metadata, providers, toaster
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: placeholder, not implemented
 */

import type { ReactNode } from "react";
import { Source_Sans_3 } from "next/font/google";
import "./globals.css";

const sourceSans = Source_Sans_3({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700", "800", "900"],
  display: "swap",
  variable: "--font-sans",
});

export const metadata = {
  title: "FCU Backoffice",
  description: "Manage communities, mentors, content and moderation for student communities.",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en" className={sourceSans.variable}>
      <body>{children}</body>
    </html>
  );
}
