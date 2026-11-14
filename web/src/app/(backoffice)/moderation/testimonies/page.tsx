/**
 * src/app/(backoffice)/moderation/testimonies/page.tsx
 *
 * WHAT: B16 Moderation testimonies: review story and video, approve and publish, request changes, reject
 * REQUIREMENTS: FR-09
 * SPEC: docs/features/11-moderation.md
 * STATUS: implemented
 */

import { TestimonyQueue } from "@/features/moderation/components/TestimonyQueue";
import type { ModerationTestimony } from "@/features/moderation/schemas";

export default function ModerationTestimoniesPage() {
  const initialItems: ModerationTestimony[] = [];
  return <TestimonyQueue initialItems={initialItems} />;
}
