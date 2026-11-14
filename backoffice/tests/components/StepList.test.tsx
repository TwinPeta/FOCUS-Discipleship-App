/**
 * tests/components/StepList.test.tsx
 *
 * WHAT: Pathway step reordering and required flags
 * REQUIREMENTS: FR-15,FR-20
 * SPEC: start/CONVENTIONS.md (testing section)
 * STATUS: implemented
 */

import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { StepList } from "@/features/pathways/components/StepList";
import type { PathwayStep } from "@/features/pathways/queries";

const SAMPLE_STEPS: PathwayStep[] = [
  {
    id: "s-1",
    contentId: "c-1",
    title: "Step One: Getting Started",
    contentType: "devotional",
    order: 0,
    required: true,
  },
  {
    id: "s-2",
    contentId: "c-2",
    title: "Step Two: Watch Video",
    contentType: "video",
    order: 1,
    required: false,
  },
];

describe("StepList component", () => {
  it("renders steps with titles and required states", () => {
    const handleChange = vi.fn();
    render(<StepList steps={SAMPLE_STEPS} onChange={handleChange} />);

    expect(screen.getByText("Step One: Getting Started")).toBeInTheDocument();
    expect(screen.getByText("Step Two: Watch Video")).toBeInTheDocument();

    const checkbox1 = screen.getByLabelText("Required flag for Step One: Getting Started") as HTMLInputElement;
    const checkbox2 = screen.getByLabelText("Required flag for Step Two: Watch Video") as HTMLInputElement;

    expect(checkbox1.checked).toBe(true);
    expect(checkbox2.checked).toBe(false);
  });

  it("toggles the required flag when checkbox is clicked", async () => {
    const user = userEvent.setup();
    const handleChange = vi.fn();
    render(<StepList steps={SAMPLE_STEPS} onChange={handleChange} />);

    const checkbox1 = screen.getByLabelText("Required flag for Step One: Getting Started");
    await user.click(checkbox1);

    expect(handleChange).toHaveBeenCalledTimes(1);
    const updated = handleChange.mock.calls[0][0];
    expect(updated[0].required).toBe(false);
    expect(updated[1].required).toBe(false);
  });

  it("reorders steps when move down is clicked", async () => {
    const user = userEvent.setup();
    const handleChange = vi.fn();
    render(<StepList steps={SAMPLE_STEPS} onChange={handleChange} />);

    const moveDownButtons = screen.getAllByRole("button", { name: "Move step down" });
    await user.click(moveDownButtons[0]);

    expect(handleChange).toHaveBeenCalledTimes(1);
    const updated = handleChange.mock.calls[0][0];
    expect(updated[0].id).toBe("s-2");
    expect(updated[0].order).toBe(0);
    expect(updated[1].id).toBe("s-1");
    expect(updated[1].order).toBe(1);
  });
});
