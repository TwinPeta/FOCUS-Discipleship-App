/**
 * tailwind.config.ts
 *
 * WHAT: Tailwind configuration; colours map to the FCU design tokens defined as CSS variables in src/app/globals.css.
 * SPEC: docs/brand.md
 * STATUS: baseline
 */
import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        background: "var(--background)",
        surface: "var(--surface)",
        foreground: "var(--foreground)",
        "muted-foreground": "var(--muted-foreground)",
        primary: "var(--primary)",
        "primary-soft": "var(--primary-soft)",
        accent: "var(--accent)",
        border: "var(--border)",
      },
      fontFamily: { sans: ["var(--font-sans)", "system-ui", "sans-serif"] },
      borderRadius: { nav: "var(--radius-nav)", card: "var(--radius-card)" },
      width: { sidebar: "var(--sidebar-width)" },
    },
  },
  plugins: [],
};

export default config;
