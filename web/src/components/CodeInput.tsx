"use client";

/** One field for the 6-digit code the API emails. Digits only. */
export function CodeInput({ id, value, onChange }: { id: string; value: string; onChange: (v: string) => void }) {
  return (
    <input id={id} name="code" inputMode="numeric" autoComplete="one-time-code" pattern="[0-9]{6}" maxLength={6} placeholder="6-digit code"
      style={{ letterSpacing: "0.3em", fontWeight: 700 }} value={value} onChange={(e) => onChange(e.target.value.replace(/\D/g, "").slice(0, 6))} />
  );
}
