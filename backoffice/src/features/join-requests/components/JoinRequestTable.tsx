/**
 * src/features/join-requests/components/JoinRequestTable.tsx
 *
 * WHAT: Join requests table with status tabs, search, conflict badges, single & bulk actions
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/04-join-requests.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import Link from "next/link";
import { ROUTES } from "@/lib/constants/routes";
import { Search } from "lucide-react";
import { useSession } from "@/features/auth/hooks/useSession";
import {
  hasCommunityConflict,
  partitionBulkApprove,
  type JoinRequestItem,
} from "@/features/join-requests/conflicts";
import {
  approveJoinRequest,
  bulkApproveJoinRequests,
  declineJoinRequest,
  sayHelloToMember,
} from "@/features/join-requests/queries";
import { shouldHideCrossCommunityControls } from "@/lib/permissions/scope";
import { JoinRequestStatus } from "@/types/enums";
import { BulkApproveBar } from "./BulkApproveBar";
import { ConflictBadge } from "./ConflictBadge";
import { DeclineDialog } from "./DeclineDialog";
import { useRemoteItems } from "@/lib/hooks/useRemoteItems";
import { fetchJoinRequests } from "@/features/join-requests/queries";

interface JoinRequestTableProps {
  initialItems: JoinRequestItem[];
}

export function JoinRequestTable({ initialItems }: JoinRequestTableProps) {
  const { user } = useSession();
  const hideCommunityFilter = shouldHideCrossCommunityControls(user);

  const [items, setItems] = useRemoteItems<JoinRequestItem>(initialItems, fetchJoinRequests);
  const [activeTab, setActiveTab] = useState<JoinRequestStatus>(JoinRequestStatus.Pending);
  const [search, setSearch] = useState("");
  const [communityFilter, setCommunityFilter] = useState("ALL");
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [bulkSubmitting, setBulkSubmitting] = useState(false);
  const [declineTarget, setDeclineTarget] = useState<JoinRequestItem | null>(null);

  const counts = {
    [JoinRequestStatus.Pending]: items.filter((i) => i.status === JoinRequestStatus.Pending).length,
    [JoinRequestStatus.Approved]: items.filter((i) => i.status === JoinRequestStatus.Approved).length,
    [JoinRequestStatus.Declined]: items.filter((i) => i.status === JoinRequestStatus.Declined).length,
  };

  const communities = Array.from(new Set(items.map((i) => i.requestedCommunityName)));

  const filtered = items.filter((item) => {
    if (item.status !== activeTab) return false;
    if (!hideCommunityFilter && communityFilter !== "ALL" && item.requestedCommunityName !== communityFilter) {
      return false;
    }
    if (search.trim()) {
      const q = search.toLowerCase();
      return (
        item.studentUsername.toLowerCase().includes(q) ||
        item.institutionName.toLowerCase().includes(q) ||
        item.requestedCommunityName.toLowerCase().includes(q)
      );
    }
    return true;
  });

  const selectedRequests = filtered.filter((i) => selectedIds.includes(i.id));
  const { approvable, skippedConflicts } = partitionBulkApprove(selectedRequests);

  function toggleSelect(id: string) {
    setSelectedIds((prev) =>
      prev.includes(id) ? prev.filter((item) => item !== id) : [...prev, id],
    );
  }

  async function handleApprove(id: string) {
    await approveJoinRequest(id);
    setItems((prev) =>
      prev.map((i) => (i.id === id ? { ...i, status: JoinRequestStatus.Approved } : i)),
    );
    setSelectedIds((prev) => prev.filter((item) => item !== id));
  }

  async function handleDecline(id: string, reason?: string) {
    await declineJoinRequest(id, reason);
    setItems((prev) =>
      prev.map((i) => (i.id === id ? { ...i, status: JoinRequestStatus.Declined } : i)),
    );
    setSelectedIds((prev) => prev.filter((item) => item !== id));
  }

  async function handleHello(id: string) {
    const { welcomedAt } = await sayHelloToMember(id);
    setItems((prev) => prev.map((i) => (i.id === id ? { ...i, welcomedAt } : i)));
  }

  async function handleBulkApprove() {
    if (approvable.length === 0) return;
    setBulkSubmitting(true);
    try {
      const ids = approvable.map((i) => i.id);
      await bulkApproveJoinRequests(ids);
      setItems((prev) =>
        prev.map((i) => (ids.includes(i.id) ? { ...i, status: JoinRequestStatus.Approved } : i)),
      );
      setSelectedIds([]);
    } finally {
      setBulkSubmitting(false);
    }
  }

  return (
    <div className="flex flex-col gap-5">
      <div className="flex flex-wrap gap-2" role="tablist">
        {(
          [
            { key: JoinRequestStatus.Pending, label: "Pending" },
            { key: JoinRequestStatus.Approved, label: "Approved" },
            { key: JoinRequestStatus.Declined, label: "Declined" },
          ] as const
        ).map((tab) => (
          <button
            key={tab.key}
            type="button"
            role="tab"
            aria-selected={activeTab === tab.key}
            onClick={() => {
              setActiveTab(tab.key);
              setSelectedIds([]);
            }}
          >
            {tab.label} <span className="opacity-80">{counts[tab.key]}</span>
          </button>
        ))}
      </div>

      <section className="card flex flex-col gap-2">
      <div className="mb-1.5 flex flex-wrap items-center gap-2.5">
        <div className="relative min-w-[220px] flex-1">
          <Search className="pointer-events-none absolute left-3.5 top-3.5 h-[18px] w-[18px] text-muted" aria-hidden="true" />
          <input
            type="search"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search a student"
            aria-label="Search new members"
            className="field-soft w-full pl-10 pr-3"
          />
        </div>
        {!hideCommunityFilter && (
          <select
            value={communityFilter}
            onChange={(e) => setCommunityFilter(e.target.value)}
            aria-label="Filter by caregroup"
            className="pill-select"
          >
            <option value="ALL">All caregroups</option>
            {communities.map((name) => (
              <option key={name} value={name}>
                {name}
              </option>
            ))}
          </select>
        )}
      </div>

      {activeTab === JoinRequestStatus.Pending && (
        <BulkApproveBar
          selectedCount={selectedRequests.length}
          approvableCount={approvable.length}
          skippedConflictCount={skippedConflicts.length}
          isSubmitting={bulkSubmitting}
          onApproveSelected={handleBulkApprove}
          onClearSelection={() => setSelectedIds([])}
        />
      )}

      <div className="overflow-x-auto">
        <table className="w-full text-left text-sm">
          <thead className="border-b border-border bg-surface text-xs uppercase text-muted-foreground">
            <tr>
              {activeTab === JoinRequestStatus.Pending && <th className="w-10 px-4 py-3" />}
              <th className="px-4 py-3">Applicant</th>
              <th className="px-4 py-3">Campus</th>
              <th className="px-4 py-3">Requested caregroup</th>
              <th className="px-4 py-3">Requested</th>
              <th className="px-4 py-3">Conflict</th>
              {activeTab !== JoinRequestStatus.Declined && (
                <th className="px-4 py-3 text-right">Actions</th>
              )}
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {filtered.length === 0 ? (
              <tr>
                <td
                  colSpan={activeTab === JoinRequestStatus.Pending ? 7 : activeTab === JoinRequestStatus.Approved ? 6 : 5}
                  className="px-4 py-8 text-center text-muted-foreground"
                >
                  No {activeTab.toLowerCase()} join requests.
                </td>
              </tr>
            ) : (
              filtered.map((req) => {
                const conflict = hasCommunityConflict(req);
                return (
                  <tr key={req.id} className="hover:bg-surface/60">
                    {activeTab === JoinRequestStatus.Pending && (
                      <td className="px-4 py-3">
                        <input
                          type="checkbox"
                          aria-label={`Select ${req.studentUsername}`}
                          checked={selectedIds.includes(req.id)}
                          onChange={() => toggleSelect(req.id)}
                          
                        />
                      </td>
                    )}
                    <td className="px-4 py-3 font-medium text-foreground">
                      {req.studentUsername}
                    </td>
                    <td className="px-4 py-3 text-muted-foreground">
                      {req.institutionName}
                    </td>
                    <td className="px-4 py-3 text-foreground">
                      {req.requestedCommunityName}
                    </td>
                    <td className="px-4 py-3 text-muted-foreground">{req.requestedAt}</td>
                    <td className="px-4 py-3">
                      {conflict && req.currentSpecificCommunityName ? (
                        <ConflictBadge communityName={req.currentSpecificCommunityName} />
                      ) : (
                        <span className="text-xs text-muted-foreground">—</span>
                      )}
                    </td>
                    {activeTab === JoinRequestStatus.Approved && (
                      <td className="px-4 py-3 text-right space-x-2">
                        <button
                          type="button"
                          disabled={Boolean(req.welcomedAt)}
                          onClick={() => handleHello(req.id)}
                          className="rounded-md bg-primary px-2.5 py-1 text-xs font-semibold text-foreground"
                        >
                          {req.welcomedAt ? "Welcomed" : "Say hello"}
                        </button>
                        <Link
                          href={ROUTES.memberDetail(req.studentId)}
                          className="rounded-md border border-border px-2.5 py-1 text-xs font-medium"
                        >
                          View
                        </Link>
                      </td>
                    )}
                    {activeTab === JoinRequestStatus.Pending && (
                      <td className="px-4 py-3 text-right space-x-2">
                        <button
                          type="button"
                          onClick={() => handleApprove(req.id)}
                          className="rounded-md bg-primary px-2.5 py-1 text-xs font-semibold text-foreground hover:brightness-95"
                        >
                          Approve
                        </button>
                        <button
                          type="button"
                          onClick={() => setDeclineTarget(req)}
                          className="rounded-md border border-border px-2.5 py-1 text-xs font-medium hover:bg-surface"
                        >
                          Decline
                        </button>
                      </td>
                    )}
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      <DeclineDialog
        open={Boolean(declineTarget)}
        studentName={declineTarget?.studentUsername ?? ""}
        onConfirm={async (reason) => {
          if (declineTarget) {
            await handleDecline(declineTarget.id, reason);
          }
        }}
        onClose={() => setDeclineTarget(null)}
      />
      </section>
    </div>
  );
}
