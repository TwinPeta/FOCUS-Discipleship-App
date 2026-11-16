import Link from "next/link";
import { SiteHeader } from "@/components/SiteHeader";

export const metadata = { title: "Community charter" };

// Mirrors mobile/lib/features/auth/presentation/charter_screen.dart, where the section text is still marked as placeholder.
const SECTIONS: [string, string][] = [
  ["Respect", "We welcome every student. Disagree kindly, never insult, mock or exclude anyone."],
  ["Privacy", "Prayer requests, testimonies and messages stay inside the community. Do not share screenshots without permission."],
  ["Safety", "No harassment, bullying, hate speech or sexual content. Adults and minors follow FCU safeguarding rules."],
  ["Reporting", "Use Report on any post, comment or person. Moderators review every report; admins handle suspensions."],
];

export default function Charter() {
  return (
    <>
      <SiteHeader />
      <main className="auth wrap">
        <div className="auth-card" style={{ maxWidth: 720 }}>
          <h1>Community charter</h1>
          <p className="sub">How we look after one another.</p>
          <ul className="list" style={{ marginTop: 24 }}>
            <li>Treat everyone with kindness and respect.</li>
            <li>Keep what is shared in the community private.</li>
            <li>No harassment, hate or inappropriate content.</li>
            <li>Mentors guide; report anything that worries you.</li>
          </ul>
          {SECTIONS.map(([t, b]) => (
            <section key={t} style={{ marginTop: 22 }}>
              <h2 style={{ fontSize: 21, fontWeight: 800, marginBottom: 6 }}>{t}</h2>
              <p>{b}</p>
            </section>
          ))}
          <p className="alt"><Link href="/help">Help</Link></p>
        </div>
      </main>
    </>
  );
}
