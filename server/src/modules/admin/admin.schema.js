const zod = require('zod');

const createAdminSchema = zod.object({
    email: zod.string().email().trim().toLowerCase(),
    password: zod.string()
    .min(8)
    .max(100)
    .regex(/[A-Z]/, "Must contain an uppercase letter")
    .regex(/[a-z]/, "Must contain a lowercase letter")
    .regex(/[0-9]/, "Must contain a number")
    .regex(/[\W_]/, "Must contain a special character"),
   firstName: zod.string().min(1).max(50).optional(),
   lastName: zod.string().min(1).max(50).optional(),
   name: zod.string().min(2).max(100).optional(),
   isActive: zod.coerce.boolean().optional().default(true),
   profileImage: zod.string().url().optional(),
}).strict()

const loginAdminSchema = zod.object({
    email: zod.string().email().trim().toLowerCase(),
    password: zod.string().min(8).max(100),
}).strict()

const refreshTokenSchema = zod.object({
    refreshToken: zod.string().min(1, 'Refresh token is required'),
}).strict()

const logoutSchema = zod.object({
    refreshToken: zod.string().min(1, 'Refresh token is required'),
}).strict()

const verifyAccountSchema = zod.object({
    status: zod.enum(['APPROVED','REJECTED']),
    rejectionReason: zod.string().max(300).optional()
}).strict().superRefine((data, ctx) => {
    if (data.status === 'REJECTED' && !data.rejectionReason?.trim()) {
        ctx.addIssue({
            code: zod.ZodIssueCode.custom,
            message: 'rejectionReason is required when status is REJECTED',
            path: ['rejectionReason'],
        });
    }
})

const moderationSchema = zod.object({
    action: zod.enum(['APPROVE','REJECT','PENDING']),
    reason: zod.string().max(500).optional()
}).strict()

const moderateContentSchema = zod.object({
    contentId: zod.string().min(1, 'Content id is required'),
    contentType: zod.enum(['POST', 'COMMENT']),
    action: zod.enum(['APPROVE','REJECT','PENDING']),
    reason: zod.string().max(500).optional()
}).strict()

const updateAdminProfileSchema = zod.object({
    name: zod.string().min(2).max(100).optional(),
    firstName: zod.string().min(1).max(50).optional(),
    lastName: zod.string().min(1).max(50).optional(),
    username: zod.string().min(3).max(30).optional(),
    bio: zod.string().max(500).optional(),
    profileImage: zod.string().url().optional(),
}).strict()

const moderationQueueSchema = zod.object({
    contentType: zod.enum(['POST', 'COMMENT']).optional(),
    status: zod.string().min(1).optional(),
    page: zod.string().regex(/^\\d+$/).optional(),
    limit: zod.coerce.number().int().positive().optional(),
}).strict()

const paginationSchema = zod.object({
    page: zod.coerce.number().int().positive().optional(),
    limit: zod.coerce.number().int().positive().optional(),
}).strict()

const listUserProfilesSchema = zod.object({
  search: zod.string().max(100, 'Search must be at most 100 characters').optional(),
  limit: zod.coerce.number().int().min(1).max(100).default(20),
  offset: zod.coerce.number().int().min(0).default(0),
});

module.exports = {
    createAdminSchema,
    loginAdminSchema,
    refreshTokenSchema,
    logoutSchema,
    verifyAccountSchema,
    moderationSchema,
    listUserProfilesSchema,
    moderateContentSchema,
    updateAdminProfileSchema,
    moderationQueueSchema,
    paginationSchema
}
