/**
 * src/features/roles/components/RoleForm.tsx
 *
 * WHAT: Create a custom role or edit a role's permissions (B32). Built-in roles keep their name; System admin, Student,
 *       Alumni and Mentor are shown read-only. Custom roles can be renamed and deleted when nobody holds them.
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createRole, deleteRole, resetRole, updateRole, type RoleDef, type RoleMatrix } from "../api";
import { MatrixEditor } from "./MatrixEditor";
import { ROUTES } from "@/lib/constants/routes";

interface RoleFormProps {
  modules: string[];
  /** Omit to create a new custom role */
  role?: RoleDef;
}

const BASES = [
  { value: "CONTENT_ADMIN", label: "Backoffice only", hint: "Signs in to the Backoffice, like a content admin." },
  { value: "SUPER_MENTOR", label: "App + Backoffice (limited)", hint: "Leads a caregroup in the app and uses the Backoffice, like a super-mentor." },
] as const;

export function RoleForm({ modules, role }: RoleFormProps) {
  const router = useRouter();
  const creating = !role;
  const [name, setName] = useState(role?.name ?? "");
  const [description, setDescription] = useState(role?.description ?? "");
  const [base, setBase] = useState<"CONTENT_ADMIN" | "SUPER_MENTOR">((role?.base as "CONTENT_ADMIN" | "SUPER_MENTOR") ?? "CONTENT_ADMIN");
  const [matrix, setMatrix] = useState<RoleMatrix>(role?.matrix ?? { Dashboard: { codes: ["V"] } });
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);
  const [busy, setBusy] = useState(false);

  const readOnly = Boolean(role && !role.editable);

  async function run(action: () => Promise<void>) {
    setBusy(true);
    setError(null);
    setSaved(false);
    try {
      await action();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Something went wrong.");
    } finally {
      setBusy(false);
    }
  }

  const save = () =>
    run(async () => {
      if (creating) {
        if (name.trim().length < 2) throw new Error("Give the role a name.");
        const made = await createRole({ name: name.trim(), description: description.trim(), base, matrix });
        router.push(ROUTES.roleDetail(made.id));
      } else {
        const updated = await updateRole(role.id, {
          ...(role.renamable ? { name: name.trim(), description: description.trim() } : {}),
          matrix,
        });
        setMatrix(updated.matrix);
        setSaved(true);
      }
    });

  const reset = () =>
    run(async () => {
      if (!role) return;
      const r = await resetRole(role.id);
      setMatrix(r.matrix);
      setSaved(true);
    });

  const remove = () =>
    run(async () => {
      if (!role || !window.confirm(`Delete the role “${role.name}”?`)) return;
      await deleteRole(role.id);
      router.push(ROUTES.roles);
    });

  return (
    <div className="flex flex-wrap items-start gap-4">
      <section className="card flex min-w-0 flex-[1_1_320px] flex-col gap-4 lg:max-w-[420px]">
        {error && (
          <p role="alert" className="rounded-lg bg-danger-soft px-3.5 py-2.5 text-sm font-semibold text-danger">
            {error}
          </p>
        )}
        {saved && (
          <p role="status" className="notice">
            <span>Saved. Changes apply the next time people sign in or reload, and are recorded in the audit log.</span>
          </p>
        )}

        <div className="flex flex-col gap-1.5">
          <label htmlFor="role-name" className="text-[13px] font-extrabold">
            Role name
          </label>
          <input
            id="role-name"
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            disabled={!creating && !role?.renamable}
            maxLength={60}
            className="w-full px-3.5"
          />
        </div>

        <div className="flex flex-col gap-1.5">
          <label htmlFor="role-description" className="text-[13px] font-extrabold">
            Description
          </label>
          <textarea
            id="role-description"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            disabled={!creating && !role?.renamable}
            maxLength={400}
            className="w-full px-3.5 py-2"
          />
        </div>

        <div className="flex flex-col gap-2">
          <p className="text-[13px] font-extrabold">Where this role signs in</p>
          {creating ? (
            <div role="radiogroup" className="flex flex-col gap-2">
              {BASES.map((b) => (
                <label key={b.value} className="flex items-start gap-2.5 text-[15px] font-semibold">
                  <input type="radio" name="role-base" checked={base === b.value} onChange={() => setBase(b.value)} className="mt-1" />
                  <span>
                    {b.label}
                    <span className="block text-xs font-normal opacity-80">{b.hint}</span>
                  </span>
                </label>
              ))}
            </div>
          ) : (
            <p className="text-[15px] font-extrabold">{role?.where}</p>
          )}
        </div>

        {role && (
          <p className="text-[15px]">
            <b>{role.people.toLocaleString("en-US")}</b> {role.people === 1 ? "person has" : "people have"} this role.
          </p>
        )}

        {readOnly && (
          <p className="notice">
            <span>
              {role?.base === "SYSTEM_ADMIN"
                ? "System admin always has full access, so its permissions are fixed."
                : "This role has no Backoffice access. See the mobile app matrix for what it can do in the app."}
            </span>
          </p>
        )}
      </section>

      <section className="card flex min-w-0 flex-[999_1_480px] flex-col gap-3">
        <p className="eyebrow">Backoffice permissions</p>
        {readOnly && role?.base !== "SYSTEM_ADMIN" && Object.keys(matrix).length === 0 ? (
          <p className="text-[15px]">None.</p>
        ) : (
          <MatrixEditor modules={modules} value={matrix} onChange={setMatrix} disabled={readOnly} />
        )}
        <p className="text-sm">
          <b>Delete</b> and <b>Export</b> are sensitive: every use is recorded in the audit log. You can only give a role
          what the pages it needs allow: a role without View on a module cannot open it.
        </p>

        {!readOnly && (
          <div className="flex flex-wrap gap-2.5">
            <button type="button" onClick={save} disabled={busy} className="btn btn-primary">
              {busy ? "Saving…" : creating ? "Create role" : "Save role"}
            </button>
            <Link href={ROUTES.roles} className="btn btn-secondary">
              {creating ? "Cancel" : "Back to roles"}
            </Link>
            {role?.builtIn && role.edited && (
              <button type="button" onClick={reset} disabled={busy} className="btn btn-secondary">
                Reset to proposed
              </button>
            )}
            {role?.deletable && (
              <button type="button" onClick={remove} disabled={busy || role.people > 0} className="btn btn-danger" title={role.people > 0 ? "Change these people's role first" : undefined}>
                Delete role
              </button>
            )}
          </div>
        )}
      </section>
    </div>
  );
}
