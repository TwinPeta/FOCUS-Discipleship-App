import type { Metadata, Viewport } from "next";
import { Source_Sans_3 } from "next/font/google";
import { AuthProvider } from "@/lib/auth";
import "boxicons/css/boxicons.min.css";
import "./globals.css";

// Same typeface as the back office.
const brand = Source_Sans_3({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700", "800", "900"],
  display: "swap",
  variable: "--font-brand",
});

export const metadata: Metadata = {
  title: { default: "FCU Student Community", template: "%s · FCU Student Community" },
  description:
    "Connect with students on your campus who share your values, learn together and grow with mentors. On your phone or in your browser.",
};

export const viewport: Viewport = { themeColor: "#FFFAF2", width: "device-width", initialScale: 1 };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={brand.variable}>
      <body>
        <AuthProvider>{children}</AuthProvider>
      </body>
    </html>
  );
}
