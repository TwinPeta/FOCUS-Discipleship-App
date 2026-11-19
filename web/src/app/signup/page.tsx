"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { CodeInput } from "@/components/CodeInput";
import { SiteHeader } from "@/components/SiteHeader";
import { ApiError, api, post } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import type { Institution } from "@/lib/types";

const COUNTRIES = [
  { code: "UG", name: "Uganda" },
  { code: "KE", name: "Kenya" },
  { code: "RW", name: "Rwanda" },
];

const TYPES: [string, string][] = [["university", "University"], ["institute", "Institute"], ["high_school", "High school"]];
const NOT_LISTED = "__other__";

type Errors = Record<string, string>;

/** The server's field names, mapped to the ids of the inputs on this page. */
const FIELD_ID: Record<string, string> = {
  "home_church.name": "church_name", "home_church.location": "church_location", "home_church.pastor": "church_pastor",
  "guardian.name": "guardian_name", "guardian.phone": "guardian_phone", "guardian.email": "guardian_email",
};

const CODE_LABELS: Record<string, string> = { username_taken: "username", email_taken: "email", phone_taken: "phone" };

function ageOf(birthdate: string): number | null {
  const d = new Date(birthdate);
  if (!birthdate || Number.isNaN(d.getTime())) return null;
  const now = new Date();
  let age = now.getFullYear() - d.getFullYear();
  if (now.getMonth() < d.getMonth() || (now.getMonth() === d.getMonth() && now.getDate() < d.getDate())) age--;
  return age;
}

const EMAIL = /^\S+@\S+\.\S+$/;

/** Sign up. Asks for what the API requires, and what the mobile app asks, so both create the same kind of account. */
export default function SignupPage() {
  const { status, register } = useAuth();
  const router = useRouter();
  const [f, setF] = useState({
    full_name: "", username: "", birthdate: "", country: "UG", email: "", phone: "",
    institution_type: "university", institution_id: "", institution_name: "", year_of_study: "",
    church_name: "", church_location: "", church_pastor: "",
    guardian_name: "", guardian_relationship: "", guardian_phone: "", guardian_email: "",
    password: "", accepted_terms: false, accepted_code_of_conduct: false, accepted_national_activities: false,
  });
  const [institutions, setInstitutions] = useState<Institution[] | null>(null);
  const [errors, setErrors] = useState<Errors>({});
  const [formError, setFormError] = useState("");
  const [busy, setBusy] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  // Email: checked for an existing account, then confirmed with a code, like the app does.
  const [verified, setVerified] = useState("");
  const [codeSent, setCodeSent] = useState(false);
  const [code, setCode] = useState("");
  const [mailBusy, setMailBusy] = useState(false);
  const [mailMsg, setMailMsg] = useState("");

  const age = ageOf(f.birthdate);
  const minor = age !== null && age < 18;
  const university = f.institution_type === "university";
  const email = f.email.trim().toLowerCase();
  const emailVerified = !!email && verified === email;

  useEffect(() => {
    if (status === "signedIn") router.replace("/dashboard");
  }, [status, router]);

  useEffect(() => {
    let live = true;
    setInstitutions(null);
    api<{ items: Institution[] }>(`/lookups/institutions?type=${f.institution_type}&country=${f.country}&limit=100`, {}, false)
      .then((r) => live && setInstitutions(r.items))
      .catch(() => live && setInstitutions([]));
    return () => {
      live = false;
    };
  }, [f.institution_type, f.country]);

  const set = (k: keyof typeof f, v: string | boolean) => {
    setF((p) => ({
      ...p, [k]: v,
      ...(k === "country" || k === "institution_type" ? { institution_id: "", institution_name: "" } : {}),
      ...(k === "institution_type" && v !== "university" ? { year_of_study: "" } : {}),
    }));
    setErrors((p) => ({ ...p, [k]: "" }));
    if (k === "email") { setCodeSent(false); setCode(""); setMailMsg(""); }
  };

  async function checkUsername() {
    const u = f.username.trim();
    if (!/^[a-z0-9_.]{3,30}$/i.test(u)) return;
    try {
      const r = await api<{ available: boolean }>(`/auth/username-available?username=${encodeURIComponent(u.toLowerCase())}`, {}, false);
      if (!r.available) setErrors((p) => ({ ...p, username: "That username is taken. Try another." }));
    } catch {
      /* the server checks again when the account is created */
    }
  }

  async function checkEmail() {
    if (!EMAIL.test(email)) return;
    try {
      const r = await api<{ available: boolean }>(`/auth/email-available?email=${encodeURIComponent(email)}`, {}, false);
      if (!r.available) setErrors((p) => ({ ...p, email: "This email already has an account. Log in instead." }));
    } catch {
      /* the server checks again when the account is created */
    }
  }

  async function sendCode() {
    if (!EMAIL.test(email)) return setErrors((p) => ({ ...p, email: "Enter a valid email address." }));
    setMailBusy(true);
    setMailMsg("");
    try {
      await post("/auth/otp/request", { channel: "email", destination: email, purpose: "verify_contact" }, false);
      setCodeSent(true);
      setMailMsg(`We sent a 6-digit code to ${email}. It works for 10 minutes.`);
    } catch (e) {
      const err = e as ApiError;
      setMailMsg(err.status === 429 ? "You asked for several codes. Please wait a few minutes and try again." : err.message);
    } finally {
      setMailBusy(false);
    }
  }

  async function verifyCode() {
    setMailBusy(true);
    setMailMsg("");
    try {
      await post("/auth/otp/verify", { destination: email, code, purpose: "verify_contact" }, false);
      setVerified(email);
      setErrors((p) => ({ ...p, email: "" }));
    } catch (e) {
      const err = e as ApiError;
      setMailMsg(
        err.code === "otp_invalid" ? "That code is not right or has expired. Check it, or send a new one."
          : err.status === 429 ? "Too many attempts. Please wait a few minutes and try again." : err.message,
      );
    } finally {
      setMailBusy(false);
    }
  }

  function validate(): Errors {
    const e: Errors = {};
    if (f.full_name.trim().length < 2) e.full_name = "Enter your full name.";
    if (!/^[a-z0-9_.]{3,30}$/i.test(f.username)) e.username = "3 to 30 letters, numbers, dots or underscores.";
    if (!f.birthdate) e.birthdate = "Enter your date of birth.";
    else if (age === null || new Date(f.birthdate) > new Date()) e.birthdate = "Enter a valid date of birth.";
    if (!EMAIL.test(email)) e.email = "Enter a valid email address.";
    else if (!emailVerified) e.email = "Confirm your email with the code we send you.";
    if (f.phone.trim() && !/^\+?[0-9 -]{9,16}$/.test(f.phone.trim())) e.phone = "Enter a valid phone number, for example +256 700 000000.";
    if (f.institution_type === "institute" && f.institution_id === NOT_LISTED) {
      if (f.institution_name.trim().length < 2) e.institution_name = "Enter the name of your institute.";
    } else if (!f.institution_id) e.institution_id = "Choose your school or university.";
    if (university && !f.year_of_study) e.year_of_study = "Choose your year of study.";
    const church = [f.church_name, f.church_location, f.church_pastor].map((x) => x.trim());
    if (church.some(Boolean)) {
      if (church[0].length < 2) e.church_name = "Enter the church name.";
      if (church[1].length < 2) e.church_location = "Enter where the church is.";
      if (church[2].length < 2) e.church_pastor = "Enter the pastor's name.";
    }
    if (minor) {
      if (f.guardian_name.trim().length < 2) e.guardian_name = "Enter your parent or guardian's name.";
      if (!f.guardian_phone.trim() && !f.guardian_email.trim()) e.guardian_phone = "Give a phone number or an email for your guardian.";
      if (f.guardian_email.trim() && !EMAIL.test(f.guardian_email.trim())) e.guardian_email = "Enter a valid email address.";
      if (f.guardian_email.trim().toLowerCase() === email) e.guardian_email = "Use your guardian's email, not your own.";
    }
    if (f.password.length < 8) e.password = "Use at least 8 characters.";
    if (!f.accepted_terms) e.accepted_terms = "You need to agree to take part in community spaces.";
    if (!f.accepted_code_of_conduct) e.accepted_code_of_conduct = "You need to accept the community charter.";
    if (!f.accepted_national_activities) e.accepted_national_activities = "You need to agree to take part in national activities.";
    return e;
  }

  async function onSubmit(ev: React.FormEvent) {
    ev.preventDefault();
    setFormError("");
    const e = validate();
    setErrors(e);
    if (Object.keys(e).length) {
      document.getElementById(Object.keys(e)[0])?.focus();
      return;
    }
    setBusy(true);
    const listed = f.institution_id !== NOT_LISTED;
    try {
      await register({
        full_name: f.full_name.trim(), username: f.username.trim().toLowerCase(), birthdate: f.birthdate, country: f.country,
        email,
        ...(f.phone.trim() ? { phone: f.phone.trim() } : {}),
        institution_type: f.institution_type,
        ...(listed ? { institution_id: f.institution_id } : { institution_name: f.institution_name.trim() }),
        ...(university ? { year_of_study: Number(f.year_of_study) } : {}),
        ...(f.church_name.trim() ? { home_church: { name: f.church_name.trim(), location: f.church_location.trim(), pastor: f.church_pastor.trim() } } : {}),
        ...(minor ? {
          guardian: {
            name: f.guardian_name.trim(), relationship: f.guardian_relationship.trim() || undefined,
            ...(f.guardian_phone.trim() ? { phone: f.guardian_phone.trim() } : {}),
            ...(f.guardian_email.trim() ? { email: f.guardian_email.trim().toLowerCase() } : {}),
          },
        } : {}),
        password: f.password,
        accepted_terms: true, accepted_code_of_conduct: true, accepted_national_activities: true,
      });
    } catch (err) {
      const e2 = err as ApiError;
      const next: Errors = {};
      e2.fields.forEach((x) => {
        const id = FIELD_ID[x.field] || x.field;
        next[id] = x.message.charAt(0).toUpperCase() + x.message.slice(1) + ".";
      });
      if (e2.code && CODE_LABELS[e2.code]) next[CODE_LABELS[e2.code]] = e2.message + ".";
      setErrors(next);
      if (!Object.keys(next).length) setFormError(e2.status === 429 ? "Too many attempts. Please wait a little and try again." : e2.message);
      else document.getElementById(Object.keys(next)[0])?.focus();
      setBusy(false);
    }
  }

  const field = (k: keyof typeof f) => ({
    id: k, name: k, "aria-invalid": !!errors[k], "aria-describedby": errors[k] ? `${k}-err` : undefined,
  });
  const Err = ({ k }: { k: string }) => (errors[k] ? <span className="err" id={`${k}-err`}>{errors[k]}</span> : null);
  const typeLabel = TYPES.find(([v]) => v === f.institution_type)?.[1] ?? "";

  return (
    <>
      <SiteHeader />
      <main className="auth wrap">
        <div className="auth-card">
          <h1>Create your account</h1>
          <p className="sub">One account for the web app and the mobile app.</p>
          <form onSubmit={onSubmit} noValidate>
            {formError ? <div className="alert" role="alert">{formError}</div> : null}
            <div className="field">
              <label htmlFor="full_name">Full name</label>
              <input {...field("full_name")} autoComplete="name" value={f.full_name} onChange={(e) => set("full_name", e.target.value)} />
              <Err k="full_name" />
            </div>
            <div className="row-2">
              <div className="field">
                <label htmlFor="username">Username</label>
                <input {...field("username")} autoComplete="username" autoCapitalize="none" value={f.username}
                  onChange={(e) => set("username", e.target.value)} onBlur={checkUsername} />
                <Err k="username" />
              </div>
              <div className="field">
                <label htmlFor="birthdate">Date of birth</label>
                <input {...field("birthdate")} type="date" autoComplete="bday" value={f.birthdate}
                  onChange={(e) => set("birthdate", e.target.value)} />
                <Err k="birthdate" />
              </div>
            </div>
            <div className="field">
              <label htmlFor="email">Email</label>
              <input {...field("email")} type="email" autoComplete="email" value={f.email} onChange={(e) => set("email", e.target.value)} onBlur={checkEmail} />
              <Err k="email" />
              {emailVerified ? <span className="ok-text">Email confirmed.</span> : (
                <>
                  <span className="hint">We email you a code to confirm it. It is also where password reset codes go.</span>
                  {codeSent ? (
                    <div className="row-2" style={{ alignItems: "end" }}>
                      <CodeInput id="email_code" value={code} onChange={setCode} />
                      <button type="button" className="btn btn-sm" disabled={mailBusy || code.length !== 6} onClick={verifyCode}>Confirm email</button>
                    </div>
                  ) : null}
                  <div>
                    <button type="button" className="btn btn-sm" disabled={mailBusy || !EMAIL.test(email)} onClick={sendCode}>
                      {mailBusy ? "Please wait…" : codeSent ? "Send a new code" : "Send me a code"}
                    </button>
                  </div>
                  {mailMsg ? <span className="hint" role="status">{mailMsg}</span> : null}
                </>
              )}
            </div>
            <div className="field">
              <label htmlFor="phone">Phone (optional)</label>
              <input {...field("phone")} type="tel" autoComplete="tel" value={f.phone} onChange={(e) => set("phone", e.target.value)} />
              <Err k="phone" />
            </div>
            <div className="field">
              <label htmlFor="country">Country</label>
              <select {...field("country")} value={f.country} onChange={(e) => set("country", e.target.value)}>
                {COUNTRIES.map((c) => <option key={c.code} value={c.code}>{c.name}</option>)}
              </select>
            </div>
            <div className="field" role="group" aria-labelledby="inst-type">
              <span className="legend" id="inst-type">I study at a</span>
              <div className="seg" style={{ gridTemplateColumns: "repeat(3, 1fr)" }}>
                {TYPES.map(([v, l]) => (
                  <label key={v}>
                    <input type="radio" name="institution_type" value={v} checked={f.institution_type === v}
                      onChange={() => set("institution_type", v)} />
                    {l}
                  </label>
                ))}
              </div>
            </div>
            <div className="field">
              <label htmlFor="institution_id">{typeLabel}</label>
              <select {...field("institution_id")} value={f.institution_id} disabled={!institutions}
                onChange={(e) => set("institution_id", e.target.value)}>
                <option value="">{institutions ? (institutions.length ? "Choose…" : "None listed for this country yet") : "Loading…"}</option>
                {(institutions || []).map((i) => <option key={i.id} value={i.id}>{i.name}</option>)}
                {f.institution_type === "institute" ? <option value={NOT_LISTED}>My institute is not listed</option> : null}
              </select>
              <Err k="institution_id" />
            </div>
            {f.institution_type === "institute" && f.institution_id === NOT_LISTED ? (
              <div className="field">
                <label htmlFor="institution_name">Name of your institute</label>
                <input {...field("institution_name")} value={f.institution_name} onChange={(e) => set("institution_name", e.target.value)} />
                <Err k="institution_name" />
              </div>
            ) : null}
            {university ? (
              <div className="field">
                <label htmlFor="year_of_study">Year of study</label>
                <select {...field("year_of_study")} value={f.year_of_study} onChange={(e) => set("year_of_study", e.target.value)}>
                  <option value="">Choose…</option>
                  {[1, 2, 3, 4, 5, 6, 7].map((y) => <option key={y} value={y}>Year {y}</option>)}
                </select>
                <Err k="year_of_study" />
              </div>
            ) : null}

            <fieldset className="group">
              <legend>Your home church (optional)</legend>
              <div className="field">
                <label htmlFor="church_name">Church name</label>
                <input {...field("church_name")} value={f.church_name} onChange={(e) => set("church_name", e.target.value)} />
                <Err k="church_name" />
              </div>
              <div className="row-2">
                <div className="field">
                  <label htmlFor="church_location">Where is it?</label>
                  <input {...field("church_location")} value={f.church_location} onChange={(e) => set("church_location", e.target.value)} />
                  <Err k="church_location" />
                </div>
                <div className="field">
                  <label htmlFor="church_pastor">Pastor</label>
                  <input {...field("church_pastor")} value={f.church_pastor} onChange={(e) => set("church_pastor", e.target.value)} />
                  <Err k="church_pastor" />
                </div>
              </div>
            </fieldset>

            {minor ? (
              <fieldset className="group">
                <legend>Parent or guardian</legend>
                <span className="hint">You are under 18, so the FCU team confirms consent with a parent or guardian before your account is fully open.</span>
                <div className="field">
                  <label htmlFor="guardian_name">Their name</label>
                  <input {...field("guardian_name")} value={f.guardian_name} onChange={(e) => set("guardian_name", e.target.value)} />
                  <Err k="guardian_name" />
                </div>
                <div className="field">
                  <label htmlFor="guardian_relationship">Relationship (optional)</label>
                  <input {...field("guardian_relationship")} value={f.guardian_relationship} onChange={(e) => set("guardian_relationship", e.target.value)} />
                </div>
                <div className="row-2">
                  <div className="field">
                    <label htmlFor="guardian_phone">Their phone</label>
                    <input {...field("guardian_phone")} type="tel" value={f.guardian_phone} onChange={(e) => set("guardian_phone", e.target.value)} />
                    <Err k="guardian_phone" />
                  </div>
                  <div className="field">
                    <label htmlFor="guardian_email">Their email</label>
                    <input {...field("guardian_email")} type="email" value={f.guardian_email} onChange={(e) => set("guardian_email", e.target.value)} />
                    <Err k="guardian_email" />
                  </div>
                </div>
                <span className="hint">A phone number or an email is enough.</span>
              </fieldset>
            ) : null}

            <div className="field">
              <label htmlFor="password">Password</label>
              <div style={{ display: "flex", gap: 8 }}>
                <input {...field("password")} type={showPassword ? "text" : "password"} autoComplete="new-password" value={f.password}
                  style={{ flex: 1 }} onChange={(e) => set("password", e.target.value)} />
                <button type="button" className="btn btn-sm" aria-pressed={showPassword} onClick={() => setShowPassword((s) => !s)}>{showPassword ? "Hide" : "Show"}</button>
              </div>
              {errors.password ? <Err k="password" /> : <span className="hint">At least 8 characters.</span>}
            </div>
            <label className="check">
              <input type="checkbox" id="accepted_code_of_conduct" checked={f.accepted_code_of_conduct}
                onChange={(e) => set("accepted_code_of_conduct", e.target.checked)} />
              <span>I accept the <Link href="/charter" target="_blank">community charter</Link>.<br /><Err k="accepted_code_of_conduct" /></span>
            </label>
            <label className="check">
              <input type="checkbox" id="accepted_terms" checked={f.accepted_terms} onChange={(e) => set("accepted_terms", e.target.checked)} />
              <span>I agree to take part in community spaces.<br /><Err k="accepted_terms" /></span>
            </label>
            <label className="check">
              <input type="checkbox" id="accepted_national_activities" checked={f.accepted_national_activities}
                onChange={(e) => set("accepted_national_activities", e.target.checked)} />
              <span>I agree to take part in FOCUS national activities.<br /><Err k="accepted_national_activities" /></span>
            </label>
            <button className="btn btn-primary btn-block" type="submit" disabled={busy}>
              {busy ? "Creating your account…" : "Create account"}
            </button>
          </form>
          <p className="alt">Already have an account? <Link href="/login">Log in</Link></p>
        </div>
      </main>
    </>
  );
}
