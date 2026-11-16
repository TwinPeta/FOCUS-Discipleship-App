export const API_URL = (process.env.NEXT_PUBLIC_API_URL || "http://localhost:4000/v1").replace(/\/$/, "");
export const ANDROID_URL =
  process.env.NEXT_PUBLIC_ANDROID_URL ??
  "https://github.com/TwinPeta/FOCUS-Discipleship-App/releases/latest/download/fcu.apk";
export const IOS_URL = process.env.NEXT_PUBLIC_IOS_URL || "";
/** Shown on the Help page when set. */
export const SUPPORT_EMAIL = process.env.NEXT_PUBLIC_SUPPORT_EMAIL || "";
