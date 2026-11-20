/**
 * src/app/(backoffice)/content/new/page.tsx
 *
 * WHAT: B12 New content (video, devotional, document) and B13 Quiz builder (?type=quiz)
 * REQUIREMENTS: FR-01, FR-08
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

"use client";

import { use, useState } from "react";
import { PageHeader } from "@/components/layout/PageHeader";
import { useRouter } from "next/navigation";
import { useSession } from "@/features/auth/hooks/useSession";
import { ContentTypeSwitch } from "@/features/content/components/ContentTypeSwitch";
import { DetailsFields } from "@/features/content/components/DetailsFields";
import { DevotionalForm } from "@/features/content/components/DevotionalForm";
import { DocumentForm } from "@/features/content/components/DocumentForm";
import { PublishingCard } from "@/features/content/components/PublishingCard";
import { VideoForm } from "@/features/content/components/VideoForm";
import { createContent } from "@/features/content/queries";
import { QuizBuilder } from "@/features/quiz/components/QuizBuilder";
import { ROUTES } from "@/lib/constants/routes";
import { ContentStatus, ContentType } from "@/types/enums";

export default function NewContentPage({
  searchParams,
}: {
  searchParams: Promise<{ type?: string }>;
}) {
  const params = use(searchParams);
  const router = useRouter();
  const { user } = useSession();

  const initialType =
    params.type?.toLowerCase() === "quiz" ? ContentType.Quiz : ContentType.Video;

  const [type, setType] = useState<ContentType>(initialType);
  const [title, setTitle] = useState("");
  const [bibleLink, setBibleLink] = useState("");
  const [language, setLanguage] = useState("English");
  const [tagsText, setTagsText] = useState("");
  const [description, setDescription] = useState("");
  const [validatorName, setValidatorName] = useState("");
  const [pathwayIds, setPathwayIds] = useState<string[]>([]);
  const [videoUrl, setVideoUrl] = useState("");
  const [thumbnailUrl, setThumbnailUrl] = useState("");
  const [body, setBody] = useState("");
  const [documentUrl, setDocumentUrl] = useState("");
  const [submitting, setSubmitting] = useState(false);

  async function handleSave(submitForReview: boolean) {
    setSubmitting(true);
    try {
      await createContent({
        title,
        type,
        bibleLink,
        language,
        tags: tagsText
          .split(",")
          .map((t) => t.trim())
          .filter(Boolean),
        description,
        validatorName,
        pathwayIds,
        videoUrl,
        thumbnailUrl,
        body,
        documentUrl,
        submitForReview,
      });
      router.push(ROUTES.content);
      router.refresh();
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="flex flex-col gap-5">
      <PageHeader
        title={type === ContentType.Quiz ? "Quiz builder" : "New content"}
        description="All content requires validation before it is published to students."
        backHref={ROUTES.content}
        backLabel="Back to content"
      />

      <ContentTypeSwitch value={type} onChange={setType} />

      {type === ContentType.Quiz ? (
        <QuizBuilder />
      ) : (
        <div className="flex flex-wrap items-start gap-4">
          <div className="card flex min-w-0 flex-[999_1_520px] flex-col gap-6">
            <DetailsFields
              title={title}
              onTitleChange={setTitle}
              bibleLink={bibleLink}
              onBibleLinkChange={setBibleLink}
              language={language}
              onLanguageChange={setLanguage}
              tagsText={tagsText}
              onTagsTextChange={setTagsText}
              description={description}
              onDescriptionChange={setDescription}
            />

            {type === ContentType.Video && (
              <VideoForm
                videoUrl={videoUrl}
                onVideoUrlChange={setVideoUrl}
                thumbnailUrl={thumbnailUrl}
                onThumbnailUrlChange={setThumbnailUrl}
              />
            )}

            {type === ContentType.Devotional && (
              <DevotionalForm body={body} onChange={setBody} />
            )}

            {type === ContentType.Document && (
              <DocumentForm documentUrl={documentUrl} onChange={setDocumentUrl} />
            )}
          </div>

          <div className="flex min-w-0 flex-[1_1_300px] flex-col gap-4 lg:max-w-[380px]">
          <PublishingCard
            status={ContentStatus.Draft}
            authorName={user?.fullName ?? "Staff author"}
            validatorName={validatorName}
            onValidatorChange={setValidatorName}
            pathwayIds={pathwayIds}
            onPathwaysChange={setPathwayIds}
            isSubmitting={submitting}
            onSaveDraft={() => handleSave(false)}
            onSubmitForReview={() => handleSave(true)}
          />
          <aside className="card flex flex-col gap-2">
            <h2 className="eyebrow">Shown in the app</h2>
            <ul className="flex flex-col gap-2 text-[15px]">
              <li>Resources, under the content type and the linked Bible character or text.</li>
              <li>Pathway steps, if you add it to a pathway.</li>
            </ul>
          </aside>
          </div>
        </div>
      )}
    </div>
  );
}
