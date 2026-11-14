/**
 * tests/setup.ts
 *
 * WHAT: Vitest setup: jest-dom matchers, MSW lifecycle
 * REQUIREMENTS: -
 * SPEC: start/CONVENTIONS.md (testing section)
 * STATUS: implemented
 */

import "@testing-library/jest-dom/vitest";
import { cleanup } from "@testing-library/react";
import { afterEach } from "vitest";

afterEach(() => {
  cleanup();
});
