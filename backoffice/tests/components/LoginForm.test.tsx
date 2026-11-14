/**
 * tests/components/LoginForm.test.tsx
 *
 * WHAT: Login validation and error states
 * REQUIREMENTS: -
 * SPEC: start/CONVENTIONS.md (testing section)
 * STATUS: implemented
 */

import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { LoginForm } from "@/features/auth/components/LoginForm";

const pushMock = vi.fn();
const refreshMock = vi.fn();

vi.mock("next/navigation", () => ({
  useRouter: () => ({
    push: pushMock,
    refresh: refreshMock,
  }),
}));

describe("LoginForm", () => {
  beforeEach(() => {
    vi.restoreAllMocks();
    pushMock.mockReset();
    refreshMock.mockReset();
  });

  it("shows validation errors when submitted empty", async () => {
    const user = userEvent.setup();
    render(<LoginForm />);

    await user.click(screen.getByRole("button", { name: /sign in/i }));

    expect(await screen.findByText(/work email is required/i)).toBeInTheDocument();
    expect(await screen.findByText(/password is required/i)).toBeInTheDocument();
  });

  it("shows suspended account message when initialError is suspended", () => {
    render(<LoginForm initialError="suspended" />);
    expect(
      screen.getByText(/your staff account has been suspended/i),
    ).toBeInTheDocument();
  });

  it("shows generic invalid credentials message on 401", async () => {
    const user = userEvent.setup();
    vi.spyOn(globalThis, "fetch").mockResolvedValueOnce(
      new Response(JSON.stringify({ message: "Unauthorized" }), { status: 401 }),
    );

    render(<LoginForm />);
    await user.type(screen.getByLabelText(/work email/i), "staff@focusuganda.org");
    await user.type(screen.getByLabelText(/^password$/i), "WrongPass123");
    await user.click(screen.getByRole("button", { name: /sign in/i }));

    expect(
      await screen.findByText(/invalid work email or password/i),
    ).toBeInTheDocument();
  });

  it("redirects super-mentors to /my-community on successful login", async () => {
    const user = userEvent.setup();
    vi.spyOn(globalThis, "fetch").mockResolvedValueOnce(
      new Response(
        JSON.stringify({ user: { role: "SUPER_MENTOR" } }),
        { status: 200 },
      ),
    );

    render(<LoginForm />);
    await user.type(screen.getByLabelText(/work email/i), "mentor@focusuganda.org");
    await user.type(screen.getByLabelText(/^password$/i), "ValidPass123");
    await user.click(screen.getByRole("button", { name: /sign in/i }));

    await waitFor(() => {
      expect(pushMock).toHaveBeenCalledWith("/my-community");
    });
  });
});
