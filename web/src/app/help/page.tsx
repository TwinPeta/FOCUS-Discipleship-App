import Link from "next/link";
import { SiteHeader } from "@/components/SiteHeader";
import { SUPPORT_EMAIL } from "@/lib/config";

export const metadata = { title: "Help" };

// Same questions as the mobile app's Help screen, worded for the web.
const FAQ: [string, string][] = [
  ["Why can I join only one specific community?",
    "A smaller group lets mentors know you well. You stay in your general campus community, and you can change by leaving your specific one first."],
  ["How do I join a specific community?",
    "Open Community, choose a community at your campus and select Ask to join. Its super-mentor approves or declines, and you get a notification either way."],
  ["How do I report a post or a person?",
    "Select Report on a post, comment, prayer request, testimony, member or conversation. Pick a reason; a super-mentor reviews it. Reports are private."],
  ["How do I change my photo?", "Go to Profile, then Settings, and select Change photo."],
];

export default function Help() {
  return (
    <>
      <SiteHeader />
      <main className="auth wrap">
        <div className="auth-card" style={{ maxWidth: 720 }}>
          <h1>Help</h1>
          <p className="sub">Answers to common questions.</p>
          <div style={{ display: "grid", gap: 12, marginTop: 24 }}>
            {FAQ.map(([q, a], i) => (
              <details key={q} className="faq" open={i === 0}>
                <summary>{q}</summary>
                <p>{a}</p>
              </details>
            ))}
          </div>
          <p className="alt">
            {SUPPORT_EMAIL ? <>Still need help? Write to <a href={`mailto:${SUPPORT_EMAIL}`}>{SUPPORT_EMAIL}</a>. </> : null}
            Read the <Link href="/charter">community charter</Link>.
          </p>
        </div>
      </main>
    </>
  );
}
