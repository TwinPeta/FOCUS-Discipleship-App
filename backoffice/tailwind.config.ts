/**
 * tailwind.config.ts
 *
 * WHAT: Tailwind configuration; colours map to the FCU design tokens defined as RGB channels in src/app/globals.css,
 *       so opacity modifiers (`bg-primary/20`) work.
 * SPEC: docs/brand.md
 * STATUS: implemented
 */
import type { Config } from "tailwindcss";

const token = (name: string) => `rgb(var(--${name}) / <alpha-value>)`;

const config: Config = {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        background: token("background"),
        "background-subtle": token("background-subtle"),
        surface: token("surface"),
        "surface-glass": token("surface-glass"),
        foreground: token("foreground"),
        "muted-foreground": token("muted-foreground"),
        // `text-muted` is used widely across pages; alias it to the muted text token.
        muted: token("muted-foreground"),
        ink: token("ink"),
        blue: token("blue"),
        "blue-mid": token("blue-mid"),
        "blue-light": token("blue-light"),
        "blue-soft": token("blue-soft"),
        "blue-tint": token("blue-tint"),
        primary: token("primary"),
        "primary-hover": token("primary-hover"),
        "primary-soft": token("primary-soft"),
        accent: token("accent"),
        border: token("border"),
        success: token("success"),
        "success-soft": token("success-soft"),
        warning: token("warning"),
        "warning-soft": token("warning-soft"),
        danger: token("danger"),
        "danger-soft": token("danger-soft"),
        info: token("info"),
        "info-soft": token("info-soft"),
      },
      fontFamily: { sans: ["var(--font-sans)", "system-ui", "sans-serif"] },
      borderRadius: {
        md: "12px",
        lg: "14px",
        xl: "18px",
        nav: "var(--radius-nav)",
        card: "var(--radius-card)",
      },
      boxShadow: { card: "var(--shadow-card)" },
      backgroundImage: {
        "grad-yellow": "var(--grad-yellow)",
        "grad-blue": "var(--grad-blue)",
        "grad-select": "var(--grad-select)",
      },
      width: {
        sidebar: "var(--sidebar-width)",
        "sidebar-collapsed": "var(--sidebar-collapsed-width)",
      },
      keyframes: {
        "fade-in": {
          from: { opacity: "0", transform: "translateY(4px)" },
          to: { opacity: "1", transform: "none" },
        },
      },
      animation: {
        "fade-in": "fade-in 220ms ease-out both",
      },
    },
  },
  plugins: [],
};

export default config;
