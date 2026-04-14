const { z } = require("zod");

const postCreateSchema = z.object({
  body: z.object({
    content: z
      .string()
      .min(1, "Content is required")
      .max(5000, "Content cannot exceed 5000 characters"),
    visibility: z.enum(["PUBLIC", "PRIVATE"]).default("PUBLIC"),
    tags: z.array(z.string().max(50)).max(10).optional().default([]),
    category: z.string().max(100).nullable().optional(),
    mediaIds: z.array(z.string().uuid()).max(10).optional().default([]),
    communityId: z.string().uuid().optional(),
  }),
});

module.exports = { postCreateSchema };
