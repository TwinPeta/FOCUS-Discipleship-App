/**
 * src/lib/api/client.ts
 *
 * WHAT: Typed API client pointed at the proxy with error normalisation
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import { ApiError } from "./errors";

interface FetchOptions extends RequestInit {
  params?: Record<string, string | number | boolean | undefined>;
}

export async function apiClient<T>(
  endpoint: string,
  options: FetchOptions = {},
): Promise<T> {
  const { params, headers, ...rest } = options;

  let url = endpoint.startsWith("/") ? endpoint : `/${endpoint}`;
  if (!url.startsWith("/api/proxy")) {
    url = `/api/proxy${url}`;
  }

  if (params) {
    const searchParams = new URLSearchParams();
    Object.entries(params).forEach(([key, val]) => {
      if (val !== undefined && val !== null) {
        searchParams.append(key, String(val));
      }
    });
    const queryString = searchParams.toString();
    if (queryString) {
      url += (url.includes("?") ? "&" : "?") + queryString;
    }
  }

  const response = await fetch(url, {
    headers: {
      "Content-Type": "application/json",
      ...headers,
    },
    ...rest,
  });

  if (!response.ok) {
    let errorMessage = `HTTP error ${response.status}`;
    let errorCode: string | undefined;
    let errorDetails: Record<string, unknown> | undefined;

    try {
      const data = await response.json();
      // The API speaks RFC 7807 (detail/title); older mocks used message
      if (typeof data.detail === "string") errorMessage = data.detail;
      else if (typeof data.message === "string") errorMessage = data.message;
      else if (typeof data.title === "string") errorMessage = data.title;
      if (typeof data.code === "string") errorCode = data.code;
      if (data.details) errorDetails = data.details;
      else if (Array.isArray(data.errors)) errorDetails = { errors: data.errors };
    } catch {
      // Non-JSON error payload
    }

    throw new ApiError(errorMessage, response.status, errorCode, errorDetails);
  }

  if (response.status === 204) {
    return {} as T;
  }

  return (await response.json()) as T;
}
