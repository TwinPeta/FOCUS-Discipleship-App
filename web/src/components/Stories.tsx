"use client";

import { useEffect, useState } from "react";
import { api } from "@/lib/api";
import { youtubeEmbed } from "@/lib/sanitize";
import { Dialog } from "./ui";

type Story = { id: string; quote: string; student_name: string; institution_name: string; thumbnail_url: string | null; video_url: string | null };

// The same curated videos the mobile app falls back to (mobile/lib/core/config/landing_videos.dart) when a story has
// no real YouTube link of its own. The team may replace these with FOCUS Uganda's own videos.
const FALLBACK = [
  "https://www.youtube.com/watch?v=ZrOwUVdn8co",
  "https://www.youtube.com/watch?v=8Tbcofs6l3o",
  "https://www.youtube.com/watch?v=Vm1yEXM9u8w",
];

/** Student stories on the landing page. Shows nothing when the API has none or cannot be reached. */
export function Stories() {
  const [stories, setStories] = useState<Story[]>([]);
  const [playing, setPlaying] = useState<{ title: string; src: string } | null>(null);

  useEffect(() => {
    let live = true;
    api<{ stories: Story[] }>("/public/landing", {}, false).then((r) => live && setStories(r.stories || [])).catch(() => undefined);
    return () => { live = false; };
  }, []);

  if (!stories.length) return null;
  return (
    <section className="section" id="stories" style={{ paddingBottom: 0 }}>
      <div className="wrap">
        <h2>Student stories</h2>
        <p className="sub">Short video stories from students like you.</p>
        <div className="grid-3">
          {stories.map((s, i) => {
            const src = youtubeEmbed(s.video_url || "") || youtubeEmbed(FALLBACK[i % FALLBACK.length]);
            return (
              <article className="card story" key={s.id}>
                <p className="quote">“{s.quote}”</p>
                <p><b>{s.student_name}</b><br /><span className="meta">{s.institution_name}</span></p>
                {src ? <button className="btn btn-sm" onClick={() => setPlaying({ title: `${s.student_name}'s story`, src: `${src}?autoplay=1` })}><i className="bx bx-play" aria-hidden="true" /> Watch</button> : null}
              </article>
            );
          })}
        </div>
      </div>
      {playing ? (
        <Dialog title={playing.title} onClose={() => setPlaying(null)}>
          <iframe className="video-frame" src={playing.src} title={playing.title} allow="autoplay; encrypted-media; picture-in-picture; fullscreen" allowFullScreen referrerPolicy="strict-origin-when-cross-origin" />
        </Dialog>
      ) : null}
    </section>
  );
}
