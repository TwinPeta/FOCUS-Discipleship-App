import { HeroActions } from "@/components/HeroActions";
import { SiteHeader } from "@/components/SiteHeader";

const FEATURES = [
  { icon: "🤝", title: "Connect", text: "Meet students on your campus who share your values." },
  { icon: "📚", title: "Learn", text: "Videos, guides and quizzes to grow, in class and beyond." },
  { icon: "🌱", title: "Succeed", text: "Mentors who cheer you on toward your goals." },
];

const MARQUEE = "CONNECT   •   LEARN   •   GROW   •   SUCCEED   •   ".repeat(6);

export default function Landing() {
  return (
    <>
      <SiteHeader />
      <main>
        <section className="hero">
          <div className="wrap">
            <div>
              <span className="eyebrow">Fellowship of Christian Unions</span>
              <h1>Campus life is better together</h1>
              <p className="lead">
                Connect with students on your campus who share your values, learn together and build the future you want.
              </p>
              <HeroActions />
              <p className="hero-note">For students in Uganda, Kenya and Rwanda. Use it on your phone or right here in your browser.</p>
            </div>
            <div className="phone" aria-hidden="true">
              <div className="phone-screen">
                <div className="phone-top">
                  <small>Good morning</small>
                  <strong>Your community</strong>
                </div>
                <div className="phone-body">
                  <div className="mini honey"><b>Campus General</b>Everyone on your campus, open to all.</div>
                  <div className="mini"><b>Your small group</b>Meets Thursday with your super-mentor.</div>
                  <div className="mini"><b>Pathway: First steps</b>3 of 5 steps done<div className="bar"><span style={{ width: "60%" }} /></div></div>
                  <div className="mini"><b>Prayer wall</b>Share a request. Pray for a friend.</div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <div className="marquee" aria-hidden="true"><span>{MARQUEE}</span><span>{MARQUEE}</span></div>

        <section className="section" id="about">
          <div className="wrap">
            <h2>What the app is for</h2>
            <p className="sub">
              FCU Student Community is the home of your Christian Union online: one place for your campus fellowship, your small
              group and the mentors walking with you.
            </p>
            <div className="grid-3">
              {FEATURES.map((f) => (
                <article className="card" key={f.title}>
                  <div className="icon" aria-hidden="true">{f.icon}</div>
                  <h3>{f.title}</h3>
                  <p>{f.text}</p>
                </article>
              ))}
            </div>
          </div>
        </section>

        <section className="section band" id="how">
          <div className="wrap split">
            <div>
              <h2>Join in three steps</h2>
              <ol className="steps">
                <li><div><b>Create your profile</b><span>Add your details in a minute.</span></div></li>
                <li><div><b>Enter your campus</b><span>You join the general community automatically.</span></div></li>
                <li><div><b>Pick one specific community</b><span>A smaller group with mentors. One per student.</span></div></li>
              </ol>
            </div>
            <div className="card">
              <h3>Inside your community</h3>
              <ul className="list">
                <li>A feed for news, encouragement and testimonies</li>
                <li>A prayer wall where friends pray with you</li>
                <li>Discipleship pathways you complete step by step</li>
                <li>Resources and quizzes from your mentors</li>
                <li>Meeting times, check-in and messages</li>
              </ul>
            </div>
          </div>
        </section>

        <section className="section" id="download">
          <div className="wrap split">
            <div>
              <h2>Best on your phone</h2>
              <p className="sub">
                The mobile app keeps you close to your group with notifications from your community, wherever
                you are.
              </p>
              <HeroActions dark={false} />
            </div>
            <div className="card">
              <h3>No phone nearby?</h3>
              <p>
                Sign up or log in here and use the web app. It is the same account, so what you see in your browser matches the app on
                your phone.
              </p>
            </div>
          </div>
        </section>

        <section className="section final">
          <div className="wrap">
            <h2>Ready to meet your people?</h2>
            <p className="sub">Changing Students, Transforming Societies.</p>
            <HeroActions />
          </div>
        </section>
      </main>
      <footer className="site-footer">
        <div className="wrap">
          <span>© {new Date().getFullYear()} Fellowship of Christian Unions</span>
          <span>FCU Student Community</span>
        </div>
      </footer>
    </>
  );
}
