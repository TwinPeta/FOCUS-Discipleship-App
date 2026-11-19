/**
 * src/features/content/components/DetailsFields.tsx
 *
 * WHAT: Shared content metadata fields (title, Bible character/text, language, tags, description)
 * REQUIREMENTS: FR-01
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

"use client";

import { BibleLinkSelect } from "@/features/bible/components/BibleLinkSelect";

interface DetailsFieldsProps {
  title: string;
  onTitleChange: (v: string) => void;
  bibleLink: string;
  onBibleLinkChange: (v: string) => void;
  language: string;
  onLanguageChange: (v: string) => void;
  tagsText: string;
  onTagsTextChange: (v: string) => void;
  description: string;
  onDescriptionChange: (v: string) => void;
}

export function DetailsFields({
  title,
  onTitleChange,
  bibleLink,
  onBibleLinkChange,
  language,
  onLanguageChange,
  tagsText,
  onTagsTextChange,
  description,
  onDescriptionChange,
}: DetailsFieldsProps) {
  return (
    <div className="space-y-4">
      <div className="space-y-1.5">
        <label htmlFor="content-title" className="block text-[13px] font-extrabold">
          Title
        </label>
        <input
          id="content-title"
          type="text"
          value={title}
          onChange={(e) => onTitleChange(e.target.value)}
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
        />
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <div className="space-y-1.5">
          <label htmlFor="bible-link-select" className="block text-[13px] font-extrabold">
            Linked Bible character or text
          </label>
          <BibleLinkSelect value={bibleLink} onChange={onBibleLinkChange} />
        </div>

        <div className="space-y-1.5">
          <label htmlFor="content-language" className="block text-[13px] font-extrabold">
            Language
          </label>
          <input
            id="content-language"
            type="text"
            value={language}
            onChange={(e) => onLanguageChange(e.target.value)}
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
          />
        </div>
      </div>

      <div className="space-y-1.5">
        <label htmlFor="content-tags" className="block text-[13px] font-extrabold">
          Tags (comma-separated)
        </label>
        <input
          id="content-tags"
          type="text"
          value={tagsText}
          onChange={(e) => onTagsTextChange(e.target.value)}
          placeholder="discipleship, prayer, leadership"
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
        />
      </div>

      <div className="space-y-1.5">
        <label htmlFor="content-description" className="block text-[13px] font-extrabold">
          Description
        </label>
        <textarea
          id="content-description"
          rows={3}
          value={description}
          onChange={(e) => onDescriptionChange(e.target.value)}
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
        />
      </div>
    </div>
  );
}
