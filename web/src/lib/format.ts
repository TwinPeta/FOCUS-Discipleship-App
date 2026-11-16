export function timeAgo(iso: string | null | undefined): string {
  if (!iso) return "";
  const s = Math.max(0, (Date.now() - new Date(iso).getTime()) / 1000);
  if (s < 60) return "just now";
  if (s < 3600) return `${Math.floor(s / 60)} min ago`;
  if (s < 86400) return `${Math.floor(s / 3600)} h ago`;
  if (s < 7 * 86400) return `${Math.floor(s / 86400)} d ago`;
  return new Date(iso).toLocaleDateString(undefined, { day: "numeric", month: "short", year: "numeric" });
}

export const dateTime = (iso: string) =>
  new Date(iso).toLocaleString(undefined, { weekday: "short", day: "numeric", month: "short", hour: "numeric", minute: "2-digit" });

export const initialsOf = (name: string | null | undefined) =>
  (name || "?").split(/\s+/).filter(Boolean).slice(0, 2).map((w) => w[0]!.toUpperCase()).join("") || "?";

export const plural = (n: number, one: string, many = `${one}s`) => `${n} ${n === 1 ? one : many}`;

export const ROLE_LABEL: Record<string, string> = { super_mentor: "Super-mentor", mentor: "Mentor", member: "Member" };

/** Where a notification leads on the web. The API sends the mobile app's route; most are the same here. */
export function webRoute(target: string | null | undefined): string | null {
  if (!target) return null;
  if (/^\/(post|prayer|testimony|community|messages|pathways|quiz|resources)\/[^/]+/.test(target)) {
    const m = /^\/community\/([^/]+)\/pathways\/([^/]+)/.exec(target);
    return m ? `/pathways/${m[2]}` : target.replace(/^\/resources\/video\//, "/resources/");
  }
  if (target.startsWith("/request/") || target === "/communities") return "/community";
  if (/^\/(devotional|document)\//.test(target)) return target.replace(/^\/(devotional|document)\//, "/resources/");
  if (target === "/notifications" || target === "/messages" || target === "/activity") return target === "/activity" ? "/profile" : target;
  return null;
}

const DAYS: Record<string, string> = { mon: "Mondays", tue: "Tuesdays", wed: "Wednesdays", thu: "Thursdays", fri: "Fridays", sat: "Saturdays", sun: "Sundays" };

export const meetingText = (m: { weekday?: string; start_time?: string; location?: string } | null | undefined) =>
  m ? [m.weekday ? DAYS[m.weekday.slice(0, 3).toLowerCase()] || m.weekday : "", m.start_time || "", m.location || ""].filter(Boolean).join(" · ") : "";
