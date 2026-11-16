import { API_URL } from "./config";

/** Tokens live in this browser only. The API issues the same bearer tokens the mobile app uses. */
const KEY = "fcu.session";

export type Tokens = { access_token: string; refresh_token: string };
export type FieldError = { field: string; message: string };

export class ApiError extends Error {
  constructor(
    public status: number,
    message: string,
    public code?: string,
    public fields: FieldError[] = [],
  ) {
    super(message);
  }
}

export function readTokens(): Tokens | null {
  try {
    const raw = window.localStorage.getItem(KEY);
    return raw ? (JSON.parse(raw) as Tokens) : null;
  } catch {
    return null;
  }
}

export function writeTokens(t: Tokens | null) {
  try {
    if (t) window.localStorage.setItem(KEY, JSON.stringify({ access_token: t.access_token, refresh_token: t.refresh_token }));
    else window.localStorage.removeItem(KEY);
  } catch {
    /* private mode: the session lasts until the tab closes */
  }
  window.dispatchEvent(new Event("fcu:session"));
}

async function toError(res: Response): Promise<ApiError> {
  let body: Record<string, unknown> = {};
  try {
    body = await res.json();
  } catch {
    /* no body */
  }
  const err = (body.error && typeof body.error === "object" ? body.error : body) as Record<string, unknown>;
  const fields = (err.errors || err.fields || err.details || []) as FieldError[];
  const message =
    (err.detail as string) || (err.message as string) || (err.title as string) ||
    (res.status === 429 ? "Too many attempts. Please wait a little and try again." : "Something went wrong. Please try again.");
  return new ApiError(res.status, message, err.code as string | undefined, Array.isArray(fields) ? fields : []);
}

async function raw(path: string, init: RequestInit, token?: string): Promise<Response> {
  const headers = new Headers(init.headers);
  if (init.body) headers.set("Content-Type", "application/json");
  if (token) headers.set("Authorization", `Bearer ${token}`);
  try {
    return await fetch(`${API_URL}${path}`, { ...init, headers });
  } catch {
    throw new ApiError(0, "Cannot reach the server. Check your connection and try again.");
  }
}

let refreshing: Promise<Tokens | null> | null = null;

/** One refresh at a time: the server rotates refresh tokens, so two parallel refreshes would sign the student out. */
function refresh(): Promise<Tokens | null> {
  if (!refreshing) {
    refreshing = (async () => {
      const current = readTokens();
      if (!current) return null;
      const res = await raw("/auth/refresh", { method: "POST", body: JSON.stringify({ refresh_token: current.refresh_token }) });
      if (!res.ok) {
        if (res.status === 401) writeTokens(null);
        return null;
      }
      const next = (await res.json()) as Tokens;
      writeTokens(next);
      return next;
    })().finally(() => {
      refreshing = null;
    });
  }
  return refreshing;
}

export async function api<T>(path: string, init: RequestInit = {}, auth = true): Promise<T> {
  let tokens = auth ? readTokens() : null;
  if (auth && !tokens) throw new ApiError(401, "Please sign in.");
  let res = await raw(path, init, tokens?.access_token);
  if (auth && res.status === 401) {
    tokens = await refresh();
    if (!tokens) throw new ApiError(401, "Your session has ended. Please sign in again.");
    res = await raw(path, init, tokens.access_token);
  }
  if (!res.ok) throw await toError(res);
  if (res.status === 204) return undefined as T;
  return (await res.json().catch(() => undefined)) as T;
}

export const post = <T,>(path: string, body: unknown, auth = true) =>
  api<T>(path, { method: "POST", body: JSON.stringify(body) }, auth);

export const put = <T,>(path: string, body?: unknown) =>
  api<T>(path, { method: "PUT", ...(body === undefined ? {} : { body: JSON.stringify(body) }) });
export const patch = <T,>(path: string, body: unknown) => api<T>(path, { method: "PATCH", body: JSON.stringify(body) });
export const del = <T,>(path: string) => api<T>(path, { method: "DELETE" });

/** A POST that is safe to retry: the server replays the first answer for the same key. */
export const postOnce = <T,>(path: string, body: unknown) =>
  api<T>(path, { method: "POST", body: JSON.stringify(body), headers: { "Idempotency-Key": crypto.randomUUID() } });

export type Purpose = "profile_photo" | "post_photo" | "testimony_photo" | "testimony_video" | "report_evidence";

/** Uploads one image (or a testimony video) the way the mobile app does: ask for an upload slot, send the file, confirm. Returns the media id. */
export async function uploadImage(file: File, purpose: Purpose): Promise<string> {
  const slot = await post<{ media_id: string; upload_url: string; upload_headers: Record<string, string> }>("/media", {
    purpose, content_type: file.type, size_bytes: file.size,
  });
  const headers = new Headers();
  Object.entries(slot.upload_headers || {}).forEach(([k, v]) => {
    // The API marks where its own token goes; a storage bucket URL is already signed and takes none.
    if (k.toLowerCase() === "authorization") headers.set(k, `Bearer ${readTokens()?.access_token ?? ""}`);
    else headers.set(k, v);
  });
  let res: Response;
  try {
    res = await fetch(slot.upload_url, { method: "PUT", headers, body: file });
  } catch {
    throw new ApiError(0, "The file could not be uploaded. Check your connection and try again.");
  }
  if (!res.ok) throw new ApiError(res.status, "The file could not be uploaded. Please try again.");
  await post(`/media/${slot.media_id}/complete`, {}).catch(() => undefined); // also verified by the server when used
  return slot.media_id;
}

/** The message to show a person for any thrown error. */
export const messageOf = (e: unknown) =>
  e instanceof ApiError ? (e.fields[0]?.message ? `${e.message} (${e.fields[0].message})` : e.message) : "Something went wrong. Please try again.";
