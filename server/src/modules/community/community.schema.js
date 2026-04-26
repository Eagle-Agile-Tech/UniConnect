const zod = require("zod");

const createCommunitySchema = zod.object({
  name: zod.string().trim().min(3).max(20),
  description: zod.string().trim().max(160).optional(),
  profileImage: zod.string().url().optional(),
  // Optional initial members to add at creation time (mobile client sends this).
  members: zod.array(zod.string().uuid()).max(100).optional().default([]),
  
});

const updateCommunitySchema = createCommunitySchema.partial();
const communityIdParamSchema = zod.object({
  communityId: zod.string().uuid(),
});

const getTopCommunitiesQuerySchema = zod.object({
  limit: zod.coerce.number().int().min(1).max(100).optional(),
});

const postToCommunityBaseSchema = zod.object({
  communityId: zod.string().uuid(),
  content: zod.string().trim().max(5000).optional().default(""),
  visibility: zod.enum(["PUBLIC", "PRIVATE"]).default("PUBLIC"),
  tags: zod.array(zod.string().max(50)).max(10).optional().default([]),
  category: zod.string().max(100).nullable().optional(),
  mediaIds: zod.array(zod.string().uuid()).max(10).optional().default([]),
});

const postToCommunitySchema = postToCommunityBaseSchema;

const updatePostInCommunitySchema = postToCommunityBaseSchema.partial();

const getCommunitiesQuerySchema = zod.object({
  page: zod.coerce.number().int().min(1).default(1),
  limit: zod.coerce.number().int().min(1).max(100).default(10),
  search: zod.string().trim().max(100).optional(),
});

const getCommunityPostsQuerySchema = getCommunitiesQuerySchema;

const addCommunityMemberSchema = zod.object({
  communityId: zod.string().uuid(),
  userId: zod.string().uuid(),
  role: zod.enum(["ADMIN", "MEMBER"]).default("MEMBER"),
});

const leaveCommunitySchema = zod.object({
  communityId: zod.string().uuid(),
});

const joinCommunitySchema = zod.object({
  communityId: zod.string().uuid(),
});

module.exports = {
    createCommunitySchema,
    updateCommunitySchema,
    communityIdParamSchema,
    getTopCommunitiesQuerySchema,
    postToCommunitySchema,
    updatePostInCommunitySchema,
    getCommunitiesQuerySchema,
    getCommunityPostsQuerySchema,
    addCommunityMemberSchema,
    leaveCommunitySchema,
    joinCommunitySchema,
}
