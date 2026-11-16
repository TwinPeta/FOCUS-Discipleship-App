"use client";

import { useParams } from "next/navigation";
import { MediaGrid } from "@/components/community/PostCard";
import { Byline, Load, PageTitle, ReportButton } from "@/components/ui";
import { useAuth } from "@/lib/auth";
import { useGet } from "@/lib/hooks";
import type { Testimony } from "@/lib/types";

export default function TestimonyPage() {
  const { id } = useParams<{ id: string }>();
  const { user } = useAuth();
  const got = useGet<Testimony>(`/testimonies/${id}`);
  return (
    <>
      <PageTitle title="Testimony" back={{ href: got.data ? `/community/${got.data.community_id}?tab=testimonies` : "/community", label: "Back to testimonies" }} />
      <Load got={got}>
        {(t) => (
          <article className="card-item">
            <Byline user={t.author} at={t.published_at || t.created_at} extra={t.institution_name ? ` · ${t.institution_name}` : ""} />
            {t.status === "published" ? null : <p className="notice">This story is waiting for a mentor to review it. Only you can see it for now.</p>}
            <h3>{t.title}</h3>
            <MediaGrid media={t.media} />
            <p className="text">{t.body}</p>
            <div className="actions">
              {t.approved_by ? <span className="meta">Reviewed by {t.approved_by}</span> : null}
              <span className="spacer" />
              {t.author?.id === user?.id ? null : <ReportButton type="testimony" id={t.id} />}
            </div>
          </article>
        )}
      </Load>
    </>
  );
}
