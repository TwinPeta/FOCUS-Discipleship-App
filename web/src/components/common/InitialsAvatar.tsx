/**
 * src/components/common/InitialsAvatar.tsx
 *
 * WHAT: Two-letter avatar used across tables and user card
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

interface InitialsAvatarProps {
  name: string;
  size?: "sm" | "md" | "lg";
  className?: string;
}

export function InitialsAvatar({
  name,
  size = "md",
  className = "",
}: InitialsAvatarProps) {
  const initials = name
    .trim()
    .split(/\s+/)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase() ?? "")
    .join("") || "FC";

  const sizeClasses = {
    sm: "h-7 w-7 text-[11px]",
    md: "h-9 w-9 text-xs",
    lg: "h-11 w-11 text-sm font-semibold",
  }[size];

  return (
    <div
      role="img"
      aria-label={`Avatar for ${name}`}
      className={`inline-flex items-center justify-center rounded-full bg-slate-900 font-bold text-white tracking-wider select-none shrink-0 ${sizeClasses} ${className}`}
    >
      {initials}
    </div>
  );
}
