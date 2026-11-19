/**
 * src/app/(backoffice)/announcements/page.tsx
 *
 * WHAT: B8 Announcements and landing stories: composer, recent list, story videos
 * REQUIREMENTS: -
 * SPEC: docs/features/09-announcements-stories.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useState } from "react";
import { AnnouncementForm } from "@/features/announcements/components/AnnouncementForm";
import { AnnouncementList } from "@/features/announcements/components/AnnouncementList";
import {
  fetchAnnouncements,
  type Announcement,
} from "@/features/announcements/queries";
import { StoryList } from "@/features/stories/components/StoryList";
import { StoryUploader } from "@/features/stories/components/StoryUploader";
import {
  fetchLandingStories,
  saveLandingStories,
  type LandingStory,
} from "@/features/stories/queries";
import { ErrorState } from "@/components/feedback/ErrorState";

export default function AnnouncementsPage() {
  const [activeTab, setActiveTab] = useState<"announcements" | "stories">("announcements");
  const [announcements, setAnnouncements] = useState<Announcement[]>([]);
  const [stories, setStories] = useState<LandingStory[]>([]);

  const [loadError, setLoadError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    fetchAnnouncements()
      .then((res) => {
        if (active) setAnnouncements(res);
      })
      .catch((e: unknown) => {
      if (active) setLoadError(e instanceof Error ? e.message : "Failed to load");
    });
    fetchLandingStories()
      .then((res) => {
        if (active) setStories(res);
      })
      .catch((e: unknown) => {
      if (active) setLoadError(e instanceof Error ? e.message : "Failed to load");
    });
    return () => {
      active = false;
    };
  }, []);

  function handleAnnouncementCreated(ann: Announcement) {
    setAnnouncements((prev) => [ann, ...prev]);
  }

  function handleStoryCreated(story: LandingStory) {
    setStories((prev) => [...prev, story]);
  }

  async function handleStoriesChange(updated: LandingStory[]) {
    setStories(updated);
    await saveLandingStories(updated);
  }

  return (
    <div className="flex flex-col gap-5">
      {loadError && <ErrorState message={loadError} />}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-[34px] leading-[1.05]">
            Announcements &amp; stories
          </h1>
          <p className="mt-1 text-sm text-muted">
            Broadcast updates to fellowships and showcase student testimonial videos on the mobile app landing page.
          </p>
        </div>

        {activeTab === "stories" && (
          <StoryUploader onStoryCreated={handleStoryCreated} />
        )}
      </div>

      <div className="flex flex-wrap gap-2" role="tablist">
        <button type="button" role="tab" aria-selected={activeTab === "announcements"} onClick={() => setActiveTab("announcements")}>
          Announcements <span className="opacity-80">{announcements.length}</span>
        </button>
        <button type="button" role="tab" aria-selected={activeTab === "stories"} onClick={() => setActiveTab("stories")}>
          Landing page stories <span className="opacity-80">{stories.length}</span>
        </button>
      </div>

      {activeTab === "announcements" ? (
        <div className="flex flex-col gap-5">
          <AnnouncementForm onCreated={handleAnnouncementCreated} />
          <AnnouncementList announcements={announcements} />
        </div>
      ) : (
        <div className="space-y-4">
          <div className="text-xs text-muted">
            Reorder the story videos below to configure how they appear in the &quot;Hear it from students&quot; carousel.
          </div>
          <StoryList stories={stories} onChange={handleStoriesChange} />
        </div>
      )}
    </div>
  );
}
