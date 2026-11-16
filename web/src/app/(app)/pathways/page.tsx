"use client";

import Link from "next/link";
import { Load, PageTitle } from "@/components/ui";
import { useGet } from "@/lib/hooks";
import type { PathwaySummary } from "@/lib/types";

const STATUS: Record<string, string> = { completed: "Completed", in_progress: "In progress", available: "Ready to start", locked: "Locked" };

export default function Pathways() {
  const got = useGet<{ current: PathwaySummary | null; items: PathwaySummary[] }>("/pathways");
  return (
    <>
      <PageTitle title="Learn" sub="Discipleship pathways you complete step by step. Resources are inside each community." />
      <Load got={got} empty={(d) => (d.items.length ? null : "No pathways yet.")}>
        {(d) => (
          <div className="list-stack">
            {d.items.map((p) => {
              const body = (
                <>
                  <div className="panel-head" style={{ marginBottom: 0 }}>
                    <h3>{p.title}</h3>
                    <span className={p.status === "completed" ? "pill ok" : "pill"}>{STATUS[p.status]}</span>
                  </div>
                  <p className="meta">{p.status === "locked" ? p.unlock_hint : `${p.steps_completed} of ${p.steps_total} steps done`}</p>
                  <div className="bar" style={{ marginTop: 0 }}><span style={{ width: `${p.steps_total ? (100 * p.steps_completed) / p.steps_total : 0}%` }} /></div>
                </>
              );
              return p.status === "locked"
                ? <div className="card-item" key={p.id} style={{ opacity: 0.7 }}>{body}</div>
                : <Link className="card-item" key={p.id} href={`/pathways/${p.id}`}>{body}</Link>;
            })}
          </div>
        )}
      </Load>
    </>
  );
}
