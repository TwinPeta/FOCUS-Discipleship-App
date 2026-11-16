import type { Metadata, Viewport } from "next";
import localFont from "next/font/local";
import { AuthProvider } from "@/lib/auth";
import "./globals.css";

// The same typeface the mobile app ships (mobile/assets/fonts).
const brand = localFont({
  variable: "--font-brand",
  display: "swap",
  src: [
    { path: "../fonts/BricolageGrotesque-Regular.ttf", weight: "400" },
    { path: "../fonts/BricolageGrotesque-Medium.ttf", weight: "500" },
    { path: "../fonts/BricolageGrotesque-SemiBold.ttf", weight: "600" },
    { path: "../fonts/BricolageGrotesque-Bold.ttf", weight: "700" },
    { path: "../fonts/BricolageGrotesque-ExtraBold.ttf", weight: "800" },
  ],
});

export const metadata: Metadata = {
  title: { default: "FCU Student Community", template: "%s · FCU Student Community" },
  description:
    "Connect with students on your campus who share your values, learn together and grow with mentors. On your phone or in your browser.",
};

export const viewport: Viewport = { themeColor: "#F5CE3E", width: "device-width", initialScale: 1 };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={brand.variable}>
      <body>
        <AuthProvider>{children}</AuthProvider>
      </body>
    </html>
  );
}
