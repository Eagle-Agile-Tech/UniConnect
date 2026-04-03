const zod = require('zod');

const acceptExpertInvitationSchema = zod.object({
  token: zod.string().min(1, 'token is required'),
  firstName: zod.string().min(1).max(100).optional(),
  lastName: zod.string().min(1).max(100).optional(),
  password: zod.string().min(8).max(100).optional(),
}).strict();

const joinInstitutionSchema = zod.object({
  institutionName: zod.string().min(2, 'institutionName is required').max(150),
  secretCode: zod.string().min(4, 'secretCode is required').max(32),
  firstName: zod.string().min(1, 'firstName is required').max(100),
  lastName: zod.string().min(1, 'lastName is required').max(100),
  email: zod.string().email('Invalid email address').trim().toLowerCase(),
  password: zod.string().min(8, 'Password must be at least 8 characters long').max(100),
}).strict();

const updateExpertProfileSchema = zod
  .object({
    expertise: zod.string().max(100).optional(),
    bio: zod.string().max(1000).optional(),
    profileImage: zod.string().url('Profile image must be a valid URL').optional(),
  })
  .strict()
  .superRefine((data, ctx) => {
    if (!data.expertise && !data.bio && !data.profileImage) {
      ctx.addIssue({
        code: zod.ZodIssueCode.custom,
        message: 'At least one field must be provided',
        path: ['expertise'],
      });
    }
  });

module.exports = {
  acceptExpertInvitationSchema,
  joinInstitutionSchema,
  updateExpertProfileSchema,
};
