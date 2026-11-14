/**
 * src/lib/hooks/useLookups.ts
 *
 * WHAT: Loads the institutions, communities and staff candidates that form dropdowns need, from the backend
 * REQUIREMENTS: FR-07
 * SPEC: docs/api-needs.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useState } from "react";
import { fetchCommunities } from "@/features/communities/queries";
import { fetchInstitutions } from "@/features/institutions/queries";
import { fetchMembers } from "@/features/members/queries";

export interface Option {
  id: string;
  name: string;
}
export interface StaffCandidate {
  id: string;
  fullName: string;
  email: string;
}

export interface Lookups {
  institutions: Option[];
  /** Specific (campus) communities only; general communities are created automatically per institution. */
  communities: Option[];
  staff: StaffCandidate[];
  loading: boolean;
}

/** Only requests what the caller asks for (staff candidates need the members list, which super-mentors cannot read). */
export function useLookups(
  want: { institutions?: boolean; communities?: boolean; staff?: boolean } = {
    institutions: true,
    communities: true,
  },
): Lookups {
  const [state, setState] = useState<Lookups>({
    institutions: [],
    communities: [],
    staff: [],
    loading: true,
  });

  useEffect(() => {
    let active = true;
    const none = <T,>(): Promise<T[]> => Promise.resolve([]);
    Promise.all([
      want.institutions ? fetchInstitutions().catch(none) : none(),
      want.communities ? fetchCommunities().catch(none) : none(),
      want.staff ? fetchMembers().catch(none) : none(),
    ]).then(([institutions, communities, members]) => {
      if (!active) return;
      setState({
        institutions: (institutions as Option[]).map((i) => ({ id: i.id, name: i.name })),
        communities: (communities as (Option & { kind?: string; institutionName?: string })[])
          .filter((c) => c.kind !== "GENERAL")
          .map((c) => ({
            id: c.id,
            name: c.institutionName ? `${c.name} (${c.institutionName})` : c.name,
          })),
        staff: (members as (StaffCandidate & { role?: string })[])
          .filter((m) => m.role === "SUPER_MENTOR" || m.role === "MENTOR")
          .map((m) => ({ id: m.id, fullName: m.fullName, email: m.email })),
        loading: false,
      });
    });
    return () => {
      active = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return state;
}
