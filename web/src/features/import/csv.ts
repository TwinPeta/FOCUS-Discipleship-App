/**
 * src/features/import/csv.ts
 *
 * WHAT: Client-side CSV parsing (Papa Parse), column auto-matching and row validation
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

import Papa from "papaparse";

export const IMPORT_TARGET_FIELDS = [
  "fullName",
  "email",
  "phone",
  "institution",
  "community",
  "role",
] as const;

export type ImportTargetField = (typeof IMPORT_TARGET_FIELDS)[number];
export type ColumnMapping = Partial<Record<ImportTargetField, string>>;

export interface ParsedCsv {
  headers: string[];
  rows: Record<string, string>[];
}

export interface MappedImportRow {
  rowNumber: number;
  fullName: string;
  email: string;
  phone?: string;
  institution?: string;
  community?: string;
  role?: string;
}

export interface InvalidImportRow {
  rowNumber: number;
  raw: Record<string, string>;
  errors: string[];
}

export interface ImportValidationResult {
  validRows: MappedImportRow[];
  invalidRows: InvalidImportRow[];
  duplicateEmails: string[];
}

const FIELD_SYNONYMS: Record<ImportTargetField, string[]> = {
  fullName: ["full name", "fullname", "name", "student name"],
  email: ["email", "email address", "work email", "e-mail"],
  phone: ["phone", "phone number", "mobile", "tel"],
  institution: ["institution", "university", "school", "campus"],
  community: ["community", "group", "cell", "cu"],
  role: ["role", "user role", "type"],
};

export function parseCsvText(csvText: string): ParsedCsv {
  const result = Papa.parse<Record<string, string>>(csvText, {
    header: true,
    skipEmptyLines: true,
    transformHeader: (h) => h.trim(),
  });

  const headers = (result.meta.fields ?? []).filter(Boolean);
  return {
    headers,
    rows: result.data ?? [],
  };
}

export function autoMatchColumns(headers: string[]): ColumnMapping {
  const mapping: ColumnMapping = {};
  const normalizedHeaders = headers.map((h) => ({
    raw: h,
    norm: h.trim().toLowerCase(),
  }));

  for (const field of IMPORT_TARGET_FIELDS) {
    const synonyms = FIELD_SYNONYMS[field];
    const match = normalizedHeaders.find((h) => synonyms.includes(h.norm));
    if (match) {
      mapping[field] = match.raw;
    }
  }

  return mapping;
}

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function validateImportRows(
  rows: Record<string, string>[],
  mapping: ColumnMapping,
  options: {
    knownCommunities?: string[];
    existingEmails?: string[];
  } = {},
): ImportValidationResult {
  const knownCommunities = new Set(
    (options.knownCommunities ?? []).map((c) => c.trim().toLowerCase()),
  );
  const existingEmails = new Set(
    (options.existingEmails ?? []).map((e) => e.trim().toLowerCase()),
  );
  const seenEmails = new Set<string>();

  const validRows: MappedImportRow[] = [];
  const invalidRows: InvalidImportRow[] = [];
  const duplicateEmails: string[] = [];

  rows.forEach((raw, idx) => {
    const rowNumber = idx + 2; // 1-indexed + header row
    const get = (field: ImportTargetField) => {
      const col = mapping[field];
      return col ? (raw[col] ?? "").trim() : "";
    };

    const fullName = get("fullName");
    const email = get("email").toLowerCase();
    const phone = get("phone");
    const institution = get("institution");
    const community = get("community");
    const role = get("role") || "STUDENT";

    const errors: string[] = [];

    if (!fullName) {
      errors.push("Missing full name");
    }
    if (!email || !EMAIL_REGEX.test(email)) {
      errors.push("Missing or invalid email");
    } else if (existingEmails.has(email) || seenEmails.has(email)) {
      errors.push("Duplicate email");
      duplicateEmails.push(email);
    }

    if (
      community &&
      knownCommunities.size > 0 &&
      !knownCommunities.has(community.toLowerCase())
    ) {
      errors.push(`Unknown community: ${community}`);
    }

    if (email) {
      seenEmails.add(email);
    }

    if (errors.length > 0) {
      invalidRows.push({ rowNumber, raw, errors });
    } else {
      validRows.push({
        rowNumber,
        fullName,
        email,
        phone: phone || undefined,
        institution: institution || undefined,
        community: community || undefined,
        role,
      });
    }
  });

  return { validRows, invalidRows, duplicateEmails };
}
