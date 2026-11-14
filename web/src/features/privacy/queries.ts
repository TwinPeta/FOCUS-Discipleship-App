/**
 * src/features/privacy/queries.ts
 *
 * WHAT: Guardian consents and data requests queries and mutations
 * REQUIREMENTS: FR-10
 * SPEC: docs/features/12-privacy-consents.md
 * STATUS: implemented
 */

import type {
  DataRequestType,
  GuardianConsentStatus,
  RequestStatus,
} from "@/types/enums";

export interface GuardianConsentRecord {
  id: string;
  studentName: string;
  guardianName: string;
  guardianContact: string;
  status: GuardianConsentStatus;
  updatedAt: string;
}

export interface DataRequestRecord {
  id: string;
  memberName: string;
  memberEmail: string;
  type: DataRequestType;
  requestedAt: string;
  deadlineAt: string;
  status: RequestStatus;
}

export async function fetchGuardianConsents(): Promise<GuardianConsentRecord[]> {
  const res = await fetch("/api/proxy/privacy/guardian-consents", {
    cache: "no-store",
  });
  if (!res.ok) throw new Error("Failed to load guardian consents");
  const data = (await res.json()) as { items?: GuardianConsentRecord[] };
  return data.items ?? [];
}

export async function sendGuardianReminder(id: string): Promise<void> {
  const res = await fetch(`/api/proxy/privacy/guardian-consents/${id}/remind`, {
    method: "POST",
  });
  if (!res.ok) throw new Error("Failed to send reminder");
}

export async function fetchDataRequests(): Promise<DataRequestRecord[]> {
  const res = await fetch("/api/proxy/privacy/data-requests", {
    cache: "no-store",
  });
  if (!res.ok) throw new Error("Failed to load data requests");
  const data = (await res.json()) as { items?: DataRequestRecord[] };
  return data.items ?? [];
}

export async function processDataRequest(id: string): Promise<void> {
  const res = await fetch(`/api/proxy/privacy/data-requests/${id}/process`, {
    method: "POST",
  });
  if (!res.ok) throw new Error("Failed to process data request");
}
