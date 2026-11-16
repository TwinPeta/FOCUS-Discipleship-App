"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { SiteHeader } from "@/components/SiteHeader";
import { ApiError, api } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import type { Institution } from "@/lib/types";

const COUNTRIES = [
  { code: "UG", name: "Uganda" },
  { code: "KE", name: "Kenya" },
  { code: "RW", name: "Rwanda" },
];

type Errors = Record<string, string>;

const LABELS: Record<string, string> = {
  username_taken: "username",
  email_taken: "email",
  phone_taken: "phone",
};

export default function SignupPage() {
  const { status, register } = useAuth();
  const router = useRouter();
  const [f, setF] = useState({
    full_name: "", username: "", birthdate: "", country: "UG", email: "", phone: "",
    institution_type: "university", institution_id: "", password: "",
    accepted_terms: false, accepted_code_of_conduct: false,
  });
  const [institutions, setInstitutions] = useState<Institution[] | null>(null);
  const [errors, setErrors] = useState<Errors>({});
  const [formError, setFormError] = useState("");
  const [busy, setBusy] = useState(false);

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
    setF((p) => ({ ...p, [k]: v, ...(k === "country" || k === "institution_type" ? { institution_id: "" } : {}) }));
    setErrors((p) => ({ ...p, [k]: "" }));
  };

  function validate(): Errors {
    const e: Errors = {};
    if (f.full_name.trim().length < 2) e.full_name = "Enter your full name.";
    if (!/^[a-z0-9_.]{3,30}$/i.test(f.username)) e.username = "3 to 30 letters, numbers, dots or underscores.";
    if (!f.birthdate) e.birthdate = "Enter your date of birth.";
    else if (new Date(f.birthdate) > new Date()) e.birthdate = "That date is in the future.";
    if (!f.email.trim() && !f.phone.trim()) e.email = "Enter an email or a phone number.";
    if (f.email.trim() && !/^\S+@\S+\.\S+$/.test(f.email.trim())) e.email = "Enter a valid email address.";
    if (f.phone.trim() && !/^\+?[0-9 -]{9,16}$/.test(f.phone.trim())) e.phone = "Enter a valid phone number, for example +256 700 000000.";
    if (!f.institution_id) e.institution_id = "Choose your school or university.";
    if (f.password.length < 8) e.password = "Use at least 8 characters.";
    if (!f.accepted_terms) e.accepted_terms = "You need to accept the terms.";
    if (!f.accepted_code_of_conduct) e.accepted_code_of_conduct = "You need to accept the code of conduct.";
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
    try {
      await register({
        full_name: f.full_name.trim(), username: f.username.trim(), birthdate: f.birthdate, country: f.country,
        ...(f.email.trim() ? { email: f.email.trim() } : {}),
        ...(f.phone.trim() ? { phone: f.phone.trim() } : {}),
        institution_type: f.institution_type, institution_id: f.institution_id, password: f.password,
        accepted_terms: true, accepted_code_of_conduct: true,
      });
    } catch (err) {
      const e2 = err as ApiError;
      const next: Errors = {};
      e2.fields.forEach((x) => { next[x.field] = x.message.charAt(0).toUpperCase() + x.message.slice(1) + "."; });
      if (e2.code && LABELS[e2.code]) next[LABELS[e2.code]] = e2.message + ".";
      setErrors(next);
      if (!Object.keys(next).length) setFormError(e2.message);
      else document.getElementById(Object.keys(next)[0])?.focus();
      setBusy(false);
    }
  }

  const field = (k: keyof typeof f) => ({
    id: k, name: k, "aria-invalid": !!errors[k], "aria-describedby": errors[k] ? `${k}-err` : undefined,
  });
  const Err = ({ k }: { k: string }) => (errors[k] ? <span className="err" id={`${k}-err`}>{errors[k]}</span> : null);

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
                  onChange={(e) => set("username", e.target.value)} />
                <Err k="username" />
              </div>
              <div className="field">
                <label htmlFor="birthdate">Date of birth</label>
                <input {...field("birthdate")} type="date" autoComplete="bday" value={f.birthdate}
                  onChange={(e) => set("birthdate", e.target.value)} />
                <Err k="birthdate" />
              </div>
            </div>
            <div className="row-2">
              <div className="field">
                <label htmlFor="email">Email</label>
                <input {...field("email")} type="email" autoComplete="email" value={f.email} onChange={(e) => set("email", e.target.value)} />
                <Err k="email" />
              </div>
              <div className="field">
                <label htmlFor="phone">Phone</label>
                <input {...field("phone")} type="tel" autoComplete="tel" value={f.phone} onChange={(e) => set("phone", e.target.value)} />
                <Err k="phone" />
              </div>
            </div>
            <span className="hint">Give an email, a phone number, or both.</span>
            <div className="field">
              <label htmlFor="country">Country</label>
              <select {...field("country")} value={f.country} onChange={(e) => set("country", e.target.value)}>
                {COUNTRIES.map((c) => <option key={c.code} value={c.code}>{c.name}</option>)}
              </select>
            </div>
            <div className="field" role="group" aria-labelledby="inst-type">
              <span className="legend" id="inst-type">I study at a</span>
              <div className="seg">
                {[["university", "University"], ["high_school", "High school"]].map(([v, l]) => (
                  <label key={v}>
                    <input type="radio" name="institution_type" value={v} checked={f.institution_type === v}
                      onChange={() => set("institution_type", v)} />
                    {l}
                  </label>
                ))}
              </div>
            </div>
            <div className="field">
              <label htmlFor="institution_id">{f.institution_type === "university" ? "University" : "School"}</label>
              <select {...field("institution_id")} value={f.institution_id} disabled={!institutions}
                onChange={(e) => set("institution_id", e.target.value)}>
                <option value="">{institutions ? (institutions.length ? "Choose…" : "None listed for this country yet") : "Loading…"}</option>
                {(institutions || []).map((i) => <option key={i.id} value={i.id}>{i.name}</option>)}
              </select>
              <Err k="institution_id" />
            </div>
            <div className="field">
              <label htmlFor="password">Password</label>
              <input {...field("password")} type="password" autoComplete="new-password" value={f.password}
                onChange={(e) => set("password", e.target.value)} />
              {errors.password ? <Err k="password" /> : <span className="hint">At least 8 characters.</span>}
            </div>
            <label className="check">
              <input type="checkbox" id="accepted_terms" checked={f.accepted_terms} onChange={(e) => set("accepted_terms", e.target.checked)} />
              <span>I accept the terms of use.<br /><Err k="accepted_terms" /></span>
            </label>
            <label className="check">
              <input type="checkbox" id="accepted_code_of_conduct" checked={f.accepted_code_of_conduct}
                onChange={(e) => set("accepted_code_of_conduct", e.target.checked)} />
              <span>I will follow the community code of conduct.<br /><Err k="accepted_code_of_conduct" /></span>
            </label>
            <span className="hint">If you are under 18, a parent or guardian will need to give consent before you can use everything.</span>
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
