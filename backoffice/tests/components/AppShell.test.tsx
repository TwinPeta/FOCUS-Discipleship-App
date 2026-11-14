/**
 * tests/components/AppShell.test.tsx
 *
 * WHAT: Sidebar collapse/expand persistence, command palette open/search/keyboard navigation
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import { render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { CommandPalette } from "@/components/layout/CommandPalette";
import { ShellProvider } from "@/components/layout/ShellContext";
import { Sidebar } from "@/components/layout/Sidebar";
import { SessionProvider } from "@/providers/SessionProvider";
import { MemberStatus, Role } from "@/types/enums";
import type { Session } from "@/types/user";

const pushMock = vi.fn();

vi.mock("next/navigation", () => ({
  usePathname: () => "/communities",
  useRouter: () => ({ push: pushMock, refresh: vi.fn() }),
}));

const session = (role: Role): Session => ({
  user: {
    id: "u1",
    email: "grace@example.org",
    fullName: "Grace Nakato",
    role,
    status: MemberStatus.Active,
  },
});

function renderShell(ui: React.ReactNode, role: Role = Role.SystemAdmin) {
  return render(
    <SessionProvider session={session(role)}>
      <ShellProvider>{ui}</ShellProvider>
    </SessionProvider>,
  );
}

describe("Sidebar", () => {
  beforeEach(() => window.localStorage.clear());

  it("starts collapsed and remembers when expanded", async () => {
    const user = userEvent.setup();
    const { unmount } = renderShell(<Sidebar />);

    const toggle = screen.getByRole("button", { name: /expand sidebar/i });
    expect(toggle).toHaveAttribute("aria-expanded", "false");

    await user.click(toggle);
    expect(screen.getByRole("button", { name: /collapse sidebar/i })).toHaveAttribute("aria-expanded", "true");
    expect(window.localStorage.getItem("fcu-sidebar-expanded")).toBe("1");

    unmount();
    renderShell(<Sidebar />);
    expect(await screen.findByRole("button", { name: /collapse sidebar/i })).toBeInTheDocument();
  });

  it("marks the current section and keeps labels available to screen readers", () => {
    renderShell(<Sidebar />);
    const link = screen.getByRole("link", { name: "Communities" });
    expect(link).toHaveAttribute("aria-current", "page");
  });

  it("hides admin-only links from content admins", () => {
    renderShell(<Sidebar />, Role.ContentAdmin);
    expect(screen.queryByRole("link", { name: "Members" })).not.toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Content library" })).toBeInTheDocument();
  });
});

describe("CommandPalette", () => {
  beforeEach(() => pushMock.mockReset());

  it("opens with Ctrl+K, filters, and navigates with Enter", async () => {
    const user = userEvent.setup();
    renderShell(<CommandPalette />);

    await user.keyboard("{Control>}k{/Control}");
    const input = await screen.findByRole("combobox", { name: /search pages and actions/i });

    await user.type(input, "instit");
    const options = within(screen.getByRole("listbox")).getAllByRole("option");
    expect(options[0]).toHaveTextContent("Institutions");
    expect(options[0]).toHaveAttribute("aria-selected", "true");

    await user.keyboard("{ArrowDown}");
    expect(options[1]).toHaveAttribute("aria-selected", "true");
    expect(options[1]).toHaveTextContent("Add institution");

    await user.keyboard("{Enter}");
    expect(pushMock).toHaveBeenCalledWith("/institutions/new");
  });

  it("shows a helpful empty state", async () => {
    const user = userEvent.setup();
    renderShell(<CommandPalette />);
    await user.keyboard("{Control>}k{/Control}");
    await user.type(await screen.findByRole("combobox"), "zzzz");
    expect(screen.getByText(/no matches/i)).toBeInTheDocument();
  });
});
