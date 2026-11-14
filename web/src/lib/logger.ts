/**
 * src/lib/logger.ts
 *
 * WHAT: Structured logger with correlation id and level filtering
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

type LogLevel = "debug" | "info" | "warn" | "error";

interface LogPayload {
  message: string;
  correlationId?: string;
  context?: Record<string, unknown>;
  timestamp?: string;
}

function log(level: LogLevel, { message, correlationId, context }: LogPayload) {
  const timestamp = new Date().toISOString();
  const meta = {
    level,
    timestamp,
    correlationId: correlationId ?? "no-cid",
    ...context,
  };

  const formatted = `[${timestamp}] [${level.toUpperCase()}] ${correlationId ? `[${correlationId}] ` : ""}${message}`;

  switch (level) {
    case "error":
      console.error(formatted, meta);
      break;
    case "warn":
      console.warn(formatted, meta);
      break;
    case "debug":
      if (process.env.NODE_ENV !== "production") {
        console.debug(formatted, meta);
      }
      break;
    default:
      console.log(formatted, meta);
  }
}

export const logger = {
  debug: (message: string, context?: Record<string, unknown>, correlationId?: string) =>
    log("debug", { message, context, correlationId }),
  info: (message: string, context?: Record<string, unknown>, correlationId?: string) =>
    log("info", { message, context, correlationId }),
  warn: (message: string, context?: Record<string, unknown>, correlationId?: string) =>
    log("warn", { message, context, correlationId }),
  error: (message: string, context?: Record<string, unknown>, correlationId?: string) =>
    log("error", { message, context, correlationId }),
};
