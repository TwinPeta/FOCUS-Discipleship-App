/**
 * src/features/badges/components/IconPicker.tsx
 *
 * WHAT: Visual icon picker for discipleship badges
 * REQUIREMENTS: FR-15,FR-20
 * SPEC: docs/features/08-pathways-badges.md
 * STATUS: implemented
 */

"use client";

import {
  Award,
  BookOpen,
  CheckCircle2,
  Flame,
  Heart,
  Shield,
  Sparkles,
  Star,
  type LucideIcon,
} from "lucide-react";

export const BADGE_ICONS: Record<string, { label: string; icon: LucideIcon }> = {
  award: { label: "Award", icon: Award },
  shield: { label: "Shield", icon: Shield },
  flame: { label: "Flame", icon: Flame },
  star: { label: "Star", icon: Star },
  sparkles: { label: "Sparkles", icon: Sparkles },
  heart: { label: "Heart", icon: Heart },
  book: { label: "Scripture", icon: BookOpen },
  check: { label: "Check", icon: CheckCircle2 },
};

interface IconPickerProps {
  value: string;
  onChange: (iconName: string) => void;
}

export function IconPicker({ value, onChange }: IconPickerProps) {
  return (
    <div className="space-y-1.5">
      <label className="block text-[13px] font-extrabold">Badge Icon</label>
      <div className="flex flex-wrap gap-2">
        {Object.entries(BADGE_ICONS).map(([key, item]) => {
          const IconComponent = item.icon;
          const isSelected = value === key;
          return (
            <button
              key={key}
              type="button"
              onClick={() => onChange(key)}
              title={item.label}
              className={`flex h-10 w-10 items-center justify-center rounded-lg border text-sm transition ${
                isSelected
                  ? "border-primary bg-primary text-white shadow-sm"
                  : "border-border bg-white text-muted hover:border-border hover:text-foreground"
              }`}
            >
              <IconComponent className="h-5 w-5" />
            </button>
          );
        })}
      </div>
    </div>
  );
}
