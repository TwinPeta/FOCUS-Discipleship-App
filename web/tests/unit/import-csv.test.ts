/**
 * tests/unit/import-csv.test.ts
 *
 * WHAT: CSV parsing, column matching, row validation (missing email, unknown community)
 * REQUIREMENTS: -
 * SPEC: start/CONVENTIONS.md (testing section)
 * STATUS: implemented
 */

import { describe, expect, it } from "vitest";
import {
  autoMatchColumns,
  parseCsvText,
  validateImportRows,
} from "@/features/import/csv";

describe("CSV member import", () => {
  it("parses CSV headers and auto-matches common column names", () => {
    const csv = [
      "Full Name,Email Address,Phone Number,Institution,Community,Role",
      "Jane Doe,jane@mak.ac.ug,+256700000001,Makerere University,Science CU,STUDENT",
    ].join("\n");

    const parsed = parseCsvText(csv);
    expect(parsed.headers).toHaveLength(6);
    expect(parsed.rows).toHaveLength(1);

    const mapping = autoMatchColumns(parsed.headers);
    expect(mapping.fullName).toBe("Full Name");
    expect(mapping.email).toBe("Email Address");
    expect(mapping.phone).toBe("Phone Number");
    expect(mapping.institution).toBe("Institution");
    expect(mapping.community).toBe("Community");
    expect(mapping.role).toBe("Role");
  });

  it("flags missing email, duplicate email, and unknown community", () => {
    const rows = [
      {
        "Full Name": "Valid Student",
        Email: "valid@mak.ac.ug",
        Community: "Science CU",
      },
      {
        "Full Name": "Missing Email",
        Email: "",
        Community: "Science CU",
      },
      {
        "Full Name": "Duplicate Student",
        Email: "valid@mak.ac.ug",
        Community: "Science CU",
      },
      {
        "Full Name": "Bad Community",
        Email: "other@mak.ac.ug",
        Community: "Unknown CU",
      },
    ];

    const result = validateImportRows(
      rows,
      { fullName: "Full Name", email: "Email", community: "Community" },
      { knownCommunities: ["Science CU", "Law CU"] },
    );

    expect(result.validRows).toHaveLength(1);
    expect(result.validRows[0]?.email).toBe("valid@mak.ac.ug");
    expect(result.invalidRows).toHaveLength(3);
    expect(result.invalidRows[0]?.errors).toContain("Missing or invalid email");
    expect(result.invalidRows[1]?.errors).toContain("Duplicate email");
    expect(result.invalidRows[2]?.errors).toContain("Unknown community: Unknown CU");
  });
});
