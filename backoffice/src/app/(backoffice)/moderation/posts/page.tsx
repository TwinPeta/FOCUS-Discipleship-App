/**
 * src/app/(backoffice)/moderation/posts/page.tsx
 *
 * WHAT: B17 Moderation prayer and posts: inspect reported prayer requests, feed posts and comments
 * REQUIREMENTS: FR-09
 * SPEC: docs/features/11-moderation.md
 * STATUS: implemented
 */

import { PostQueue } from "@/features/moderation/components/PostQueue";
import type { ModerationPost } from "@/features/moderation/schemas";

export default function ModerationPostsPage() {
  const initialItems: ModerationPost[] = [];
  return <PostQueue initialItems={initialItems} />;
}
