/**
 * src/app/(my-community)/my-community/page.tsx
 *
 * WHAT: B29 Super-mentor home: KPIs, join requests, next meeting, members to follow up
 * REQUIREMENTS: FR-03,FR-04,FR-05
 * SPEC: docs/features/15-super-mentor-view.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useState } from "react";
import { CommunityKpis } from "@/features/my-community/components/CommunityKpis";
import { FollowUpList } from "@/features/my-community/components/FollowUpList";
import { NextMeetingCard } from "@/features/my-community/components/NextMeetingCard";
import { PendingRequestsMini } from "@/features/my-community/components/PendingRequestsMini";
import { WriteToGroupDialog } from "@/features/my-community/components/WriteToGroupDialog";
import {
  approveOwnJoinRequest,
  declineOwnJoinRequest,
  fetchMyCommunityOverview,
  MOCK_MY_COMMUNITY,
  type MyCommunityOverview,
  type NextMeetingDetails,
} from "@/features/my-community/queries";

export default function MyCommunityHomePage() {
  const [data, setData] = useState<MyCommunityOverview>(MOCK_MY_COMMUNITY);

  useEffect(() => {
    let active = true;
    fetchMyCommunityOverview().then((res) => {
      if (active) setData(res);
    });
    return () => {
      active = false;
    };
  }, []);

  async function handleApprove(id: string) {
    await approveOwnJoinRequest(id);
    setData((prev) => ({
      ...prev,
      pendingRequests: prev.pendingRequests.filter((r) => r.id !== id),
      kpis: {
        ...prev.kpis,
        members: prev.kpis.members + 1,
        pendingRequests: Math.max(0, prev.kpis.pendingRequests - 1),
      },
    }));
  }

  async function handleDecline(id: string) {
    await declineOwnJoinRequest(id);
    setData((prev) => ({
      ...prev,
      pendingRequests: prev.pendingRequests.filter((r) => r.id !== id),
      kpis: {
        ...prev.kpis,
        pendingRequests: Math.max(0, prev.kpis.pendingRequests - 1),
      },
    }));
  }

  function handleMeetingUpdated(nextMeeting: NextMeetingDetails) {
    setData((prev) => ({ ...prev, nextMeeting }));
  }

  return (
    <main className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold text-foreground">
            {data.communityName}
          </h1>
          <p className="mt-1 text-sm text-muted">
            {data.campus} · Cover photos and community creation are managed by the admin team.
          </p>
        </div>

        <WriteToGroupDialog communityName={data.communityName} />
      </div>

      <CommunityKpis kpis={data.kpis} />

      <div className="grid gap-6 lg:grid-cols-2">
        <PendingRequestsMini
          requests={data.pendingRequests}
          onApprove={handleApprove}
          onDecline={handleDecline}
        />
        <NextMeetingCard
          meeting={data.nextMeeting}
          onUpdated={handleMeetingUpdated}
        />
      </div>

      <FollowUpList members={data.followUpMembers} />
    </main>
  );
}
