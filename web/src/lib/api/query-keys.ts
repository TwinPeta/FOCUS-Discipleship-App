/**
 * src/lib/api/query-keys.ts
 *
 * WHAT: Central TanStack Query key factory for all features
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

export const queryKeys = {
  session: ["session"] as const,
  dashboard: ["dashboard"] as const,
  reports: (filters?: Record<string, unknown>) => ["reports", filters] as const,
  communities: {
    all: ["communities"] as const,
    list: (filters?: Record<string, unknown>) => ["communities", "list", filters] as const,
    detail: (id: string) => ["communities", "detail", id] as const,
  },
  institutions: {
    all: ["institutions"] as const,
    list: (filters?: Record<string, unknown>) => ["institutions", "list", filters] as const,
  },
  members: {
    all: ["members"] as const,
    list: (filters?: Record<string, unknown>) => ["members", "list", filters] as const,
    detail: (id: string) => ["members", "detail", id] as const,
  },
  joinRequests: {
    all: ["join-requests"] as const,
    list: (status?: string) => ["join-requests", "list", status] as const,
  },
  content: {
    all: ["content"] as const,
    list: (filters?: Record<string, unknown>) => ["content", "list", filters] as const,
    detail: (id: string) => ["content", "detail", id] as const,
  },
  pathways: {
    all: ["pathways"] as const,
    list: (filters?: Record<string, unknown>) => ["pathways", "list", filters] as const,
    detail: (id: string) => ["pathways", "detail", id] as const,
  },
  badges: {
    all: ["badges"] as const,
    list: (status?: string) => ["badges", "list", status] as const,
  },
  announcements: {
    all: ["announcements"] as const,
  },
  stories: {
    all: ["stories"] as const,
  },
  moderation: {
    reports: (status?: string) => ["moderation", "reports", status] as const,
    testimonies: (status?: string) => ["moderation", "testimonies", status] as const,
    posts: (status?: string) => ["moderation", "posts", status] as const,
    sanctions: ["moderation", "sanctions"] as const,
  },
  notifications: {
    rules: ["notifications", "rules"] as const,
    inactivityThreshold: ["notifications", "inactivity"] as const,
  },
  auditLog: (filters?: Record<string, unknown>) => ["audit-log", filters] as const,
};
