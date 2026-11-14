/**
 * src/features/auth/schemas.ts
 *
 * WHAT: Zod schemas for login, forgot and reset password
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

import { z } from "zod";
import { hasLetter, hasMinLength, hasNumber } from "./password-rules";

export const passwordSchema = z
  .string()
  .refine(hasMinLength, { message: "Password must be at least 10 characters" })
  .refine(hasLetter, { message: "Password must contain at least one letter" })
  .refine(hasNumber, { message: "Password must contain at least one number" });

export const loginSchema = z.object({
  email: z
    .string()
    .trim()
    .min(1, "Work email is required")
    .email("Enter a valid work email address"),
  password: z.string().min(1, "Password is required"),
  rememberMe: z.boolean().default(false),
});

export type LoginInput = z.infer<typeof loginSchema>;

export const forgotPasswordSchema = z.object({
  email: z
    .string()
    .trim()
    .min(1, "Work email is required")
    .email("Enter a valid work email address"),
});

export type ForgotPasswordInput = z.infer<typeof forgotPasswordSchema>;

export const resetPasswordSchema = z
  .object({
    token: z.string().min(1, "Reset token is missing"),
    password: passwordSchema,
    confirmPassword: z.string().min(1, "Confirm your new password"),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: "Passwords do not match",
    path: ["confirmPassword"],
  });

export type ResetPasswordInput = z.infer<typeof resetPasswordSchema>;
