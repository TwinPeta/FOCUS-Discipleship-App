/**
 * src/types/enums.ts
 *
 * WHAT: Role, MemberStatus, ContentType, ContentStatus, ReportStatus, SanctionType, RequestStatus enums
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: placeholder, not implemented
 */

// TEMPORARY: replace with types generated from the backend OpenAPI schema.

export const Role = {
  Student: "STUDENT",
  Mentor: "MENTOR",
  SuperMentor: "SUPER_MENTOR",
  Alumni: "ALUMNI",
  ContentAdmin: "CONTENT_ADMIN",
  SystemAdmin: "SYSTEM_ADMIN",
} as const;
export type Role = (typeof Role)[keyof typeof Role];

/** Roles allowed to sign in to the backoffice */
export const StaffRoles: Role[] = [Role.SuperMentor, Role.ContentAdmin, Role.SystemAdmin];

export const MemberStatus = {
  Invited: "INVITED",
  Active: "ACTIVE",
  Inactive: "INACTIVE",
  Suspended: "SUSPENDED",
} as const;
export type MemberStatus = (typeof MemberStatus)[keyof typeof MemberStatus];

export const ContentType = {
  Video: "VIDEO",
  Devotional: "DEVOTIONAL",
  Quiz: "QUIZ",
  Document: "DOCUMENT",
} as const;
export type ContentType = (typeof ContentType)[keyof typeof ContentType];

export const ContentStatus = {
  Draft: "DRAFT",
  InReview: "IN_REVIEW",
  Published: "PUBLISHED",
  Archived: "ARCHIVED",
} as const;
export type ContentStatus = (typeof ContentStatus)[keyof typeof ContentStatus];

export const CommunityKind = { General: "GENERAL", Specific: "SPECIFIC" } as const;
export type CommunityKind = (typeof CommunityKind)[keyof typeof CommunityKind];

export const JoinRequestStatus = {
  Pending: "PENDING",
  Approved: "APPROVED",
  Declined: "DECLINED",
} as const;
export type JoinRequestStatus = (typeof JoinRequestStatus)[keyof typeof JoinRequestStatus];

export const ReportStatus = { Open: "OPEN", InReview: "IN_REVIEW", Resolved: "RESOLVED" } as const;
export type ReportStatus = (typeof ReportStatus)[keyof typeof ReportStatus];

export const SanctionType = { Warning: "WARNING", Suspension: "SUSPENSION" } as const;
export type SanctionType = (typeof SanctionType)[keyof typeof SanctionType];

export const DataRequestType = { Export: "EXPORT", Deletion: "DELETION" } as const;
export type DataRequestType = (typeof DataRequestType)[keyof typeof DataRequestType];

export const RequestStatus = { Open: "OPEN", InProgress: "IN_PROGRESS", Done: "DONE" } as const;
export type RequestStatus = (typeof RequestStatus)[keyof typeof RequestStatus];

export const GuardianConsentStatus = { Pending: "PENDING", Received: "RECEIVED" } as const;
export type GuardianConsentStatus = (typeof GuardianConsentStatus)[keyof typeof GuardianConsentStatus];
