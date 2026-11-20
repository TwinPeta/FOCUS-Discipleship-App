/**
 * tests/components/MatrixEditor.test.tsx
 *
 * WHAT: The role permission grid: ticking a permission adds View too, clearing View clears the rest, scope can be own
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { MatrixEditor } from "@/features/roles/components/MatrixEditor";

const modules = ["Dashboard", "Members"];

describe("MatrixEditor", () => {
  it("adds View when a higher permission is ticked", async () => {
    const onChange = vi.fn();
    render(<MatrixEditor modules={modules} value={{}} onChange={onChange} />);
    await userEvent.click(screen.getByLabelText("Edit Members"));
    expect(onChange).toHaveBeenCalledWith({ Members: { codes: ["V", "E"], own: undefined } });
  });

  it("clears the module when View is unticked", async () => {
    const onChange = vi.fn();
    render(<MatrixEditor modules={modules} value={{ Members: { codes: ["V", "E"] } }} onChange={onChange} />);
    await userEvent.click(screen.getByLabelText("View Members"));
    expect(onChange).toHaveBeenCalledWith({});
  });

  it("limits a module to the person's own caregroup", async () => {
    const onChange = vi.fn();
    render(<MatrixEditor modules={modules} value={{ Members: { codes: ["V"] } }} onChange={onChange} />);
    await userEvent.selectOptions(screen.getByLabelText("Scope for Members"), "own");
    expect(onChange).toHaveBeenCalledWith({ Members: { codes: ["V"], own: true } });
  });

  it("cannot be changed when read-only", () => {
    render(<MatrixEditor modules={modules} value={{ Members: { codes: ["V"] } }} onChange={vi.fn()} disabled />);
    expect(screen.getByLabelText("View Members")).toBeDisabled();
  });
});
