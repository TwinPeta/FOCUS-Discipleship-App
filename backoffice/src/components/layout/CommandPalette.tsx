/**
 * src/components/layout/CommandPalette.tsx
 *
 * WHAT: Ctrl/Cmd+K palette: search and jump to any page, run quick "create" actions, or change preferences.
 *       Results are filtered by the user's role. Arrow keys move, Enter runs, Esc closes.
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useId, useMemo, useRef, useState, type KeyboardEvent } from "react";
import { useRouter } from "next/navigation";
import {
  CornerDownLeft,
  LogOut,
  PanelLeft,
  Pause,
  Play,
  Search,
  UserCircle,
  type LucideIcon,
} from "lucide-react";
import { ModalDialog } from "@/components/common/ModalDialog";
import { useSession } from "@/features/auth/hooks/useSession";
import { useSignOut } from "@/features/auth/hooks/useSignOut";
import { getNavGroupsForRole, getQuickActions } from "./nav-config";
import { useShell } from "./ShellContext";

export interface Command {
  id: string;
  label: string;
  section: "Pages" | "Quick actions" | "Preferences";
  icon: LucideIcon;
  hint?: string;
  keywords?: string[];
  run: () => void;
}

/** Every word typed must appear somewhere in the label, hint, keywords or section. Label matches rank first. */
export function filterCommands(commands: Command[], query: string): Command[] {
  const words = query.toLowerCase().trim().split(/\s+/).filter(Boolean);
  if (words.length === 0) return commands;

  return commands
    .filter((cmd) => {
      const haystack = [cmd.label, cmd.hint, cmd.section, ...(cmd.keywords ?? [])].join(" ").toLowerCase();
      return words.every((word) => haystack.includes(word));
    })
    .map((cmd, index) => {
      const label = cmd.label.toLowerCase();
      const score = label.startsWith(words[0]) ? 0 : label.includes(words[0]) ? 1 : 2;
      return { cmd, score, index };
    })
    .sort((a, b) => a.score - b.score || a.index - b.index)
    .map(({ cmd }) => cmd);
}

export function CommandPalette() {
  const router = useRouter();
  const { user } = useSession();
  const { signOut } = useSignOut();
  const {
    paletteOpen,
    setPaletteOpen,
    setProfileOpen,
    sidebarExpanded,
    toggleSidebar,
    motionPaused,
    toggleMotion,
  } = useShell();

  const [query, setQuery] = useState("");
  const [activeIndex, setActiveIndex] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);
  const listRef = useRef<HTMLUListElement>(null);
  const baseId = useId();
  const titleId = `${baseId}-title`;
  const listId = `${baseId}-list`;

  const close = () => setPaletteOpen(false);

  const commands = useMemo<Command[]>(() => {
    const go = (href: string) => () => router.push(href);
    const pages: Command[] = getNavGroupsForRole(user?.role).flatMap((group) =>
      group.items.map((item) => ({
        id: `page:${item.href}`,
        label: item.label,
        section: "Pages" as const,
        icon: item.icon,
        hint: item.description,
        keywords: [...(item.keywords ?? []), group.group],
        run: go(item.href),
      })),
    );
    const actions: Command[] = getQuickActions(user?.role).map((item) => ({
      id: `action:${item.href}`,
      label: item.label,
      section: "Quick actions" as const,
      icon: item.icon,
      keywords: item.keywords,
      run: go(item.href),
    }));
    const prefs: Command[] = [
      {
        id: "pref:profile",
        label: "View my profile",
        section: "Preferences",
        icon: UserCircle,
        keywords: ["account", "avatar", "photo", "name"],
        run: () => setProfileOpen(true),
      },
      {
        id: "pref:sidebar",
        label: sidebarExpanded ? "Collapse sidebar" : "Expand sidebar",
        section: "Preferences",
        icon: PanelLeft,
        keywords: ["menu", "navigation", "rail"],
        run: toggleSidebar,
      },
      {
        id: "pref:motion",
        label: motionPaused ? "Resume background motion" : "Pause background motion",
        section: "Preferences",
        icon: motionPaused ? Play : Pause,
        keywords: ["animation", "reduce", "accessibility"],
        run: toggleMotion,
      },
      {
        id: "pref:signout",
        label: "Sign out",
        section: "Preferences",
        icon: LogOut,
        keywords: ["logout", "log out", "exit"],
        run: () => void signOut(),
      },
    ];
    return [...pages, ...actions, ...prefs];
  }, [router, user?.role, sidebarExpanded, motionPaused, toggleSidebar, toggleMotion, setProfileOpen, signOut]);

  const results = useMemo(() => filterCommands(commands, query), [commands, query]);

  // Reset each time the palette opens.
  useEffect(() => {
    if (paletteOpen) {
      setQuery("");
      setActiveIndex(0);
      requestAnimationFrame(() => inputRef.current?.focus());
    }
  }, [paletteOpen]);

  useEffect(() => setActiveIndex(0), [query]);

  // Keep the highlighted row visible.
  useEffect(() => {
    const el = listRef.current?.querySelector<HTMLElement>(`[data-index="${activeIndex}"]`);
    el?.scrollIntoView?.({ block: "nearest" });
  }, [activeIndex]);

  function runCommand(cmd: Command | undefined) {
    if (!cmd) return;
    close();
    cmd.run();
  }

  function onKeyDown(event: KeyboardEvent<HTMLInputElement>) {
    if (results.length === 0) return;
    if (event.key === "ArrowDown") {
      event.preventDefault();
      setActiveIndex((i) => (i + 1) % results.length);
    } else if (event.key === "ArrowUp") {
      event.preventDefault();
      setActiveIndex((i) => (i - 1 + results.length) % results.length);
    } else if (event.key === "Home") {
      event.preventDefault();
      setActiveIndex(0);
    } else if (event.key === "End") {
      event.preventDefault();
      setActiveIndex(results.length - 1);
    } else if (event.key === "Enter") {
      event.preventDefault();
      runCommand(results[activeIndex]);
    }
  }

  const activeId = results[activeIndex] ? `${baseId}-opt-${activeIndex}` : undefined;

  return (
    <ModalDialog
      open={paletteOpen}
      onClose={close}
      labelledBy={titleId}
      className="mx-auto mb-auto mt-[10vh] w-[min(640px,calc(100vw-2rem))]"
    >
      <div className="overflow-hidden rounded-2xl border border-border/70 bg-surface shadow-2xl">
        <h2 id={titleId} className="sr-only">
          Search pages and actions
        </h2>

        <div className="flex items-center gap-3 border-b border-border/60 px-4">
          <Search className="h-5 w-5 shrink-0 text-muted-foreground" aria-hidden="true" />
          <input
            ref={inputRef}
            type="text"
            role="combobox"
            aria-expanded="true"
            aria-controls={listId}
            aria-activedescendant={activeId}
            aria-autocomplete="list"
            aria-label="Search pages and actions"
            placeholder="Where do you want to go?"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={onKeyDown}
            className="h-14 w-full bg-transparent text-base text-foreground outline-none placeholder:text-muted-foreground"
          />
          <kbd className="hidden shrink-0 rounded border border-border bg-background-subtle px-1.5 py-0.5 text-[11px] font-semibold text-muted-foreground sm:inline">
            Esc
          </kbd>
        </div>

        <ul ref={listRef} id={listId} role="listbox" aria-label="Results" className="max-h-[min(60vh,420px)] overflow-y-auto p-2">
          {results.length === 0 && (
            <li className="px-3 py-10 text-center text-sm text-muted-foreground">
              No matches for &ldquo;{query}&rdquo;. Try a page name like &ldquo;members&rdquo;.
            </li>
          )}
          {results.map((cmd, index) => {
            const showHeading = index === 0 || results[index - 1].section !== cmd.section;
            const active = index === activeIndex;
            const Icon = cmd.icon;
            return (
              <li key={cmd.id} role="presentation">
                {showHeading && (
                  <p
                    role="presentation"
                    className="px-3 pb-1 pt-3 text-[11px] font-bold uppercase tracking-wider text-muted-foreground first:pt-1"
                  >
                    {cmd.section}
                  </p>
                )}
                <div
                  id={`${baseId}-opt-${index}`}
                  role="option"
                  aria-selected={active}
                  data-index={index}
                  onMouseMove={() => !active && setActiveIndex(index)}
                  onClick={() => runCommand(cmd)}
                  className={`flex cursor-pointer items-center gap-3 rounded-lg px-3 py-2.5 ${
                    active ? "bg-primary-soft text-foreground" : "text-foreground/90"
                  }`}
                >
                  <span
                    className={`grid h-8 w-8 shrink-0 place-items-center rounded-lg ${
                      active ? "bg-primary text-slate-950" : "bg-background-subtle text-muted-foreground"
                    }`}
                  >
                    <Icon className="h-4 w-4" aria-hidden="true" />
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-sm font-semibold">{cmd.label}</span>
                    {cmd.hint && <span className="block truncate text-xs text-muted-foreground">{cmd.hint}</span>}
                  </span>
                  {active && <CornerDownLeft className="h-4 w-4 shrink-0 text-muted-foreground" aria-hidden="true" />}
                </div>
              </li>
            );
          })}
        </ul>

        <div className="flex items-center gap-4 border-t border-border/60 bg-background-subtle/60 px-4 py-2 text-[11px] text-muted-foreground">
          <span><kbd className="font-sans font-semibold">↑ ↓</kbd> move</span>
          <span><kbd className="font-sans font-semibold">Enter</kbd> open</span>
          <span><kbd className="font-sans font-semibold">Esc</kbd> close</span>
        </div>
      </div>
    </ModalDialog>
  );
}
