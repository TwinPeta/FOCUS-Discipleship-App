/**
 * src/features/bible/components/BibleLinkSelect.tsx
 *
 * WHAT: Dropdown to link content or quiz to a Bible character or text
 * REQUIREMENTS: FR-01
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useState } from "react";
import { fetchBibleLinks, type BibleLinkOption } from "@/features/bible/queries";

interface BibleLinkSelectProps {
  id?: string;
  value: string;
  onChange: (value: string) => void;
  options?: BibleLinkOption[];
}

export function BibleLinkSelect({
  id = "bible-link-select",
  value,
  onChange,
  options: provided,
}: BibleLinkSelectProps) {
  const [loaded, setLoaded] = useState<BibleLinkOption[]>([]);
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    if (provided) return;
    let active = true;
    fetchBibleLinks()
      .then((list) => active && setLoaded(list))
      .catch(() => active && setFailed(true));
    return () => {
      active = false;
    };
  }, [provided]);

  const options = provided ?? loaded;
  const hasValue = !value || options.some((o) => o.label === value);
  return (
    <>
      <select
        id={id}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
      >
        <option value="">Select Bible character or text</option>
        {!hasValue && <option value={value}>{value}</option>}
        {options.map((opt) => (
          <option key={opt.id} value={opt.label}>
            {opt.label}
          </option>
        ))}
      </select>
      {failed && (
        <p role="alert" className="mt-1 text-xs text-danger">
          Could not load the Bible list. Refresh to try again.
        </p>
      )}
    </>
  );
}
