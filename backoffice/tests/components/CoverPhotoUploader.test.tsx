/**
 * tests/components/CoverPhotoUploader.test.tsx
 *
 * WHAT: Rejects wrong type and shows crop for 1600 x 600
 * REQUIREMENTS: -
 * SPEC: start/CONVENTIONS.md (testing section)
 * STATUS: implemented
 */

import { fireEvent, render, screen } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { CoverPhotoUploader } from "@/features/communities/components/CoverPhotoUploader";

describe("CoverPhotoUploader", () => {
  beforeEach(() => {
    vi.restoreAllMocks();
    globalThis.URL.createObjectURL = vi.fn(() => "blob:mock-cover");
  });

  it("rejects non-image file types", () => {
    const onChange = vi.fn();
    render(<CoverPhotoUploader onChange={onChange} />);

    const input = screen.getByLabelText(/cover photo/i);
    const badFile = new File(["hello"], "doc.pdf", { type: "application/pdf" });
    fireEvent.change(input, { target: { files: [badFile] } });

    expect(screen.getByRole("alert")).toHaveTextContent(/jpg or png/i);
    expect(onChange).not.toHaveBeenCalled();
  });

  it("accepts a PNG image and renders the 1600 x 600 cropper", () => {
    const onChange = vi.fn();
    render(<CoverPhotoUploader onChange={onChange} />);

    const input = screen.getByLabelText(/cover photo/i);
    const goodFile = new File(["png"], "cover.png", { type: "image/png" });
    fireEvent.change(input, { target: { files: [goodFile] } });

    expect(screen.getByTestId("cover-cropper")).toBeInTheDocument();
    expect(onChange).toHaveBeenCalledWith("blob:mock-cover");
  });
});
