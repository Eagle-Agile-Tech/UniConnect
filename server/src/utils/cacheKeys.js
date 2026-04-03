// src/utils/cacheKeys.js
/**
 * Standardized cache key generation
 * This ensures consistency across your app
 */
const cacheKeys = {
  // Post keys
  post: (postId) => `post:${postId}`,
  posts: (filters) => {
    const hash = Buffer.from(JSON.stringify(filters)).toString("base64");
    return `posts:${hash}`;
  },
  userPosts: (userId, cursor) => `user:${userId}:posts:${cursor || "start"}`,

  // User keys
  user: (userId) => `user:${userId}`,
  userProfile: (userId) => `user:${userId}:profile`,

  // Feed keys
  feed: (userId, cursor, limit) =>
    `feed:${userId || "public"}:${cursor || "start"}:${limit}`,
  trending: (timeWindow) => `trending:${timeWindow}`,

  // Community keys
  community: (communityId) => `community:${communityId}`,
  communityMembers: (communityId) => `community:${communityId}:members`,

  // Session keys
  session: (token) => `session:${token}`,
  rateLimit: (ip, endpoint) => `ratelimit:${ip}:${endpoint}`,

  // Cache invalidation patterns
  patterns: {
    user: (userId) => `user:${userId}:*`,
    post: (postId) => `post:${postId}:*`,
    all: "*",
  },
};

module.exports = cacheKeys;
