/**
 * tests/components/QuizBuilder.test.tsx
 *
 * WHAT: Each question needs a correct answer; pass mark bounds
 * REQUIREMENTS: -
 * SPEC: start/CONVENTIONS.md (testing section)
 * STATUS: implemented
 */

import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { QuizBuilder } from "@/features/quiz/components/QuizBuilder";

describe("QuizBuilder", () => {
  it("shows validation errors when question has no correct answer or pass mark is out of bounds", async () => {
    const user = userEvent.setup();
    const onSave = vi.fn();
    render(<QuizBuilder onSave={onSave} />);

    await user.type(screen.getByLabelText(/quiz title/i), "Faith Quiz");
    await user.selectOptions(
      screen.getByLabelText(/bible character or text/i),
      "David (Character)",
    );

    const passMarkInput = screen.getByLabelText(/pass mark/i);
    await user.clear(passMarkInput);
    await user.type(passMarkInput, "150");

    await user.click(screen.getByRole("button", { name: /save quiz/i }));

    expect(
      await screen.findByText(/pass mark must be between 0 and 100/i),
    ).toBeInTheDocument();
    expect(
      await screen.findByText(/select the correct answer/i),
    ).toBeInTheDocument();
    expect(onSave).not.toHaveBeenCalled();
  });

  it("saves when title, Bible link, pass mark, options, and correct answer are valid", async () => {
    const user = userEvent.setup();
    const onSave = vi.fn().mockResolvedValue(undefined);
    render(<QuizBuilder onSave={onSave} />);

    await user.type(screen.getByLabelText(/quiz title/i), "Faith Quiz");
    await user.selectOptions(
      screen.getByLabelText(/bible character or text/i),
      "David (Character)",
    );
    await user.type(screen.getByLabelText(/question prompt/i), "Who defeated Goliath?");
    await user.type(screen.getByLabelText(/option 1 text/i), "David");
    await user.type(screen.getByLabelText(/option 2 text/i), "Saul");
    await user.click(screen.getByLabelText(/mark option 1 as correct/i));

    await user.click(screen.getByRole("button", { name: /save quiz/i }));

    expect(onSave).toHaveBeenCalledTimes(1);
    expect(await screen.findByText(/quiz saved/i)).toBeInTheDocument();
  });
});
