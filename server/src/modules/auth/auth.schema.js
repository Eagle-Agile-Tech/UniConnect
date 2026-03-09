const zod = require('zod');

const registerSchema = zod
  .object({
    firstName: zod.string().min(1, 'First name is required'),
    lastName: zod.string().min(1, 'Last name is required'),
    email: zod.string().email('Invalid email address'),
    password: zod
      .string()
      .min(8, 'Password must be at least 8 characters long')
      .max(32, 'Password must be less than 32 characters long')
      .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
      .regex(/[a-z]/, 'Password must contain at least one lowercase letter')
      .regex(/[0-9]/, 'Password must contain at least one number')
      .regex(/[^A-Za-z0-9]/, 'Password must contain at least one special character'),
    passwordConfirm: zod.string(),
  })
  .refine((data) => data.password === data.passwordConfirm, {
    message: 'Passwords do not match',
    path: ['passwordConfirm'],
  });

const loginSchema = zod.object({
  email: zod.string().email('Invalid email address'),
  password: zod
    .string()
    .min(8, 'Password must be at least 8 characters long')
    .max(32, 'Password must be less than 32 characters long'),
});

const verifyOtpSchema = zod.object({
  email: zod.string().email('Invalid email address'),
  otp: zod.string().regex(/^\d{4}$/, 'OTP must be a 4-digit code'),
});

const resendOtpSchema = zod.object({
  email: zod.string().email('Invalid email address'),
});

const forgotPasswordSchema = zod.object({
  email: zod.string().email('Invalid email address'),
});

const resetPasswordSchema = zod
  .object({
    email: zod.string().email('Invalid email address'),
    otp: zod.string().regex(/^\d{4}$/, 'OTP must be a 4-digit code'),
    newPassword: zod
      .string()
      .min(8, 'Password must be at least 8 characters long')
      .max(32, 'Password must be less than 32 characters long')
      .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
      .regex(/[a-z]/, 'Password must contain at least one lowercase letter')
      .regex(/[0-9]/, 'Password must contain at least one number')
      .regex(/[^A-Za-z0-9]/, 'Password must contain at least one special character'),
    passwordConfirm: zod.string(),
  })
  .refine((data) => data.newPassword === data.passwordConfirm, {
    message: 'Passwords do not match',
    path: ['passwordConfirm'],
  });

const logoutSchema = zod.object({
  sessionId: zod.string().uuid('Valid sessionId is required'),
});

const refreshTokenSchema = zod.object({
  refreshToken: zod.string().min(1, 'Refresh token is required'),
});

const googleLoginSchema = zod.object({
  idToken: zod.string().min(1, 'ID token is required'),
});

const submitIdVerificationSchema = zod.object({
  userId: zod.string().uuid('Valid userId is required').optional(),
  firstName: zod.string().min(1, 'First name is required').optional(),
  lastName: zod.string().min(1, 'Last name is required').optional(),
  email: zod.string().email('Invalid email address').optional(),
  password: zod
    .string()
    .min(8, 'Password must be at least 8 characters long')
    .max(32, 'Password must be less than 32 characters long')
    .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
    .regex(/[a-z]/, 'Password must contain at least one lowercase letter')
    .regex(/[0-9]/, 'Password must contain at least one number')
    .regex(/[^A-Za-z0-9]/, 'Password must contain at least one special character')
    .optional(),
  passwordConfirm: zod.string().optional(),
  documentImage: zod.string().min(1, 'Document image URL is required'),
  documentType: zod.string().optional(),
  submittedNotes: zod.string().optional(),
}).superRefine((data, ctx) => {
  if (data.userId) return;

  if (!data.firstName) {
    ctx.addIssue({ code: zod.ZodIssueCode.custom, path: ['firstName'], message: 'First name is required when userId is not provided' });
  }
  if (!data.lastName) {
    ctx.addIssue({ code: zod.ZodIssueCode.custom, path: ['lastName'], message: 'Last name is required when userId is not provided' });
  }
  if (!data.email) {
    ctx.addIssue({ code: zod.ZodIssueCode.custom, path: ['email'], message: 'Email is required when userId is not provided' });
  }
  if (!data.password) {
    ctx.addIssue({ code: zod.ZodIssueCode.custom, path: ['password'], message: 'Password is required when userId is not provided' });
  }
  if (!data.passwordConfirm) {
    ctx.addIssue({ code: zod.ZodIssueCode.custom, path: ['passwordConfirm'], message: 'Password confirmation is required when userId is not provided' });
  }
  if (data.password && data.passwordConfirm && data.password !== data.passwordConfirm) {
    ctx.addIssue({ code: zod.ZodIssueCode.custom, path: ['passwordConfirm'], message: 'Passwords do not match' });
  }
});

module.exports = {
  registerSchema,
  loginSchema,
  verifyOtpSchema,
  resendOtpSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  logoutSchema,
  refreshTokenSchema,
  googleLoginSchema,
  submitIdVerificationSchema,
};
