const zod = require('zod');

const createUserSchema = zod.object({
  username: zod
    .string()
    .min(3, 'Username must be at least 3 characters')
    .max(20, 'Username must be at most 20 characters')
    .regex(/^[a-zA-Z0-9_]+$/, 'Username can only contain letters, numbers, and underscores'),
  bio: zod.string().max(160, 'Bio must be at most 160 characters').optional(),
  profileImage: zod.string().url('Profile image must be a valid URL').optional(),
  interests: zod.array(zod.string()).optional(),
  department: zod.string().optional(),
  level: zod.enum(['UNDERGRADUATE', 'POSTGRADUATE', 'GRADUATED']).optional(),
  universityId: zod.string().uuid('University id must be a valid UUID').optional(),
  universityName: zod.string().min(2, 'University name must be at least 2 characters').max(120).optional(),
  yearOfStudy: zod.coerce.number().int().min(1).max(10).optional(),
  graduationYear: zod.coerce.number().int().min(1900).max(2100).optional(),
});

const updateUserSchema = createUserSchema.partial();
const upsertUserSchema = createUserSchema.partial();

const checkUsernameSchema = zod.object({
  username: zod
    .string()
    .min(3, 'Username must be at least 3 characters')
    .max(20, 'Username must be at most 20 characters')
    .regex(/^[a-zA-Z0-9_]+$/, 'Username can only contain letters, numbers, and underscores'),
});

const checkUsernameParamsSchema = zod.object({
  username: zod
    .string()
    .min(3, 'Username must be at least 3 characters')
    .max(20, 'Username must be at most 20 characters')
    .regex(/^[a-zA-Z0-9_]+$/, 'Username can only contain letters, numbers, and underscores'),
});


module.exports = {
  createUserSchema,
  updateUserSchema,
  upsertUserSchema,
  checkUsernameSchema,
  checkUsernameParamsSchema,
  
};
