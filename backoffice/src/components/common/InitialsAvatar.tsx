/**
 * src/components/common/InitialsAvatar.tsx
 *
 * WHAT: Avatar used across tables and the user card: shows the photo when available,
 *       otherwise (or if the photo fails) a two-letter initials badge
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import { SmartImage } from "./SmartImage";

interface InitialsAvatarProps {
  name: string;
  avatarUrl?: string | null;
  size?: "sm" | "md" | "lg" | "xl";
  className?: string;
}

const SIZE_CLASSES = {
  sm: "h-8 w-8 text-[11px]",
  md: "h-[38px] w-[38px] text-[13px]",
  lg: "h-11 w-11 text-sm font-semibold",
  xl: "h-16 w-16 text-lg",
} as const;

export function getInitials(name: string) {
  return (
    name
      .trim()
      .split(/\s+/)
      .slice(0, 2)
      .map((part) => part[0]?.toUpperCase() ?? "")
      .join("") || "FC"
  );
}

export function InitialsAvatar({
  name,
  avatarUrl,
  size = "md",
  className = "",
}: InitialsAvatarProps) {
  const sizeClasses = SIZE_CLASSES[size];

  const initials = (
    <div
      role="img"
      aria-label={`Avatar for ${name}`}
      className={`avatar font-extrabold select-none shrink-0 ${sizeClasses} ${className}`}
    >
      {getInitials(name)}
    </div>
  );

  if (!avatarUrl) return initials;

  return (
    <SmartImage
      src={avatarUrl}
      alt={`Avatar for ${name}`}
      className={`rounded-full shrink-0 ${sizeClasses} ${className}`}
      fallback={initials}
    />
  );
}
