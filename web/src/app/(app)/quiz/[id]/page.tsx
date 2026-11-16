"use client";

import Link from "next/link";
import { useParams, useSearchParams } from "next/navigation";
import { Suspense, useState } from "react";
import { ErrorText, Load, PageTitle, Panel } from "@/components/ui";
import { post } from "@/lib/api";
import { useAction, useGet } from "@/lib/hooks";
import type { Badge, Quiz } from "@/lib/types";

type Result = { score: number; total: number; passed: boolean; badges_awarded: Badge[] };

function View() {
  const { id } = useParams<{ id: string }>();
  const params = useSearchParams();
  const pathway = params.get("pathway");
  const step = params.get("step");
  const got = useGet<Quiz>(`/quizzes/${id}`);
  const [answers, setAnswers] = useState<Record<string, string>>({});
  const [result, setResult] = useState<Result | null>(null);
  const send = useAction();
  const backHref = pathway ? `/pathways/${pathway}` : "/community";

  return (
    <>
      <PageTitle title={got.data?.title || "Quiz"} back={{ href: backHref, label: pathway ? "Back to the pathway" : "Community" }}
        sub={got.data ? `${got.data.questions.length} questions · pass mark ${got.data.pass_mark_percent}%` : undefined} />
      <Load got={got} rows={6}>
        {(quiz) => result ? (
          <Panel title={result.passed ? "You passed" : "Not quite yet"}>
            <p style={{ fontSize: 22, fontWeight: 800 }}>{result.score} of {result.total} correct</p>
            <p className="meta" style={{ margin: "8px 0 16px" }}>
              {result.passed ? "Well done." : `You need ${quiz.pass_mark_percent}% to pass. You can try again.`}
              {result.badges_awarded?.length ? ` You earned: ${result.badges_awarded.map((b) => b.name).join(", ")}.` : ""}
            </p>
            <div className="btn-row" style={{ justifyContent: "flex-start" }}>
              {result.passed ? null : <button className="btn btn-primary" onClick={() => { setResult(null); setAnswers({}); }}>Try again</button>}
              <Link className="btn" href={backHref}>{pathway ? "Back to the pathway" : "Done"}</Link>
            </div>
          </Panel>
        ) : (
          <form className="inline-form" onSubmit={async (e) => {
            e.preventDefault();
            await send.run(async () => {
              const r = await post<Result>(`/quizzes/${id}/attempts`, { answers: quiz.questions.map((q) => ({ question_id: q.id, option_id: answers[q.id] })) });
              if (r.passed && pathway && step) await post(`/pathways/${pathway}/steps/${step}/complete`, {}).catch(() => undefined);
              setResult(r);
              window.scrollTo({ top: 0 });
            });
          }}>
            {quiz.questions.map((q, i) => (
              <Panel key={q.id}>
                <fieldset className="radios">
                  <legend>{i + 1}. {q.text}</legend>
                  {q.options.map((o) => (
                    <label key={o.id}>
                      <input type="radio" name={q.id} value={o.id} checked={answers[q.id] === o.id} onChange={() => setAnswers({ ...answers, [q.id]: o.id })} /> {o.text}
                    </label>
                  ))}
                </fieldset>
              </Panel>
            ))}
            <ErrorText>{send.error}</ErrorText>
            <button className="btn btn-primary" disabled={send.busy || quiz.questions.some((q) => !answers[q.id])}>{send.busy ? "Checking…" : "Submit answers"}</button>
          </form>
        )}
      </Load>
    </>
  );
}

export default function QuizPage() {
  return <Suspense><View /></Suspense>;
}
