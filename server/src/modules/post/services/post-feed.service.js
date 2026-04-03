// src/modules/post/services/post-feed.service.js
const prisma = require("../../../lib/prisma");
const redisClient = require("../../../lib/redis");
const cacheKeys = require("../../../utils/cacheKeys");
const engagementHelpers = require("../../engagement/utils/engagement.helpers");
const {
  getConnectedUserIds,
  formatPostResponse,
} = require("../utils/post.helpers");

class PostFeedService {
  async listPosts(filters = {}, userId = null) {
    const startTime = Date.now();
    let { cursor, limit = 15, authorId } = filters;

    // Prevent abuse (someone requesting 1000 posts)
    const MAX_LIMIT = 20;
    limit = Math.min(limit, MAX_LIMIT);

    const cacheKey = cacheKeys.posts({
      userId: userId || "public",
      cursor: cursor || "start",
      limit,
      authorId: authorId || null,
    });

    const cached = await redisClient.get(cacheKey);
    if (cached) {
      return cached;
    }

    try {
      const baseWhere = {
        isDeleted: false,
        moderationStatus: "APPROVED",
      };

      if (authorId) {
        baseWhere.authorId = authorId;
      }

      // Visibility logic
      let visibilityWhere;
      if (userId) {
        const connectedUserIds = await getConnectedUserIds(prisma, userId);

        visibilityWhere = {
          OR: [
            { visibility: "PUBLIC" },
            { authorId: userId },
            {
              AND: [
                { visibility: "PRIVATE" },
                { authorId: { in: connectedUserIds } },
              ],
            },
          ],
        };
      } else {
        visibilityWhere = { visibility: "PUBLIC" };
      }

      const where = {
        AND: [baseWhere, visibilityWhere],
      };

      // Keyset pagination using (createdAt, id) for better index usage
      if (cursor) {
        const cursorPost = await prisma.post.findUnique({
          where: { id: cursor },
          select: { id: true, createdAt: true },
        });

        if (cursorPost) {
          where.AND.push({
            OR: [
              { createdAt: { lt: cursorPost.createdAt } },
              {
                createdAt: cursorPost.createdAt,
                id: { lt: cursorPost.id },
              },
            ],
          });
        }
      }

      const queryOptions = {
        take: limit + 1,
        where,
        orderBy: [
          { createdAt: "desc" },
          { id: "desc" }, // stable ordering
        ],
        include: {
          author: {
            select: {
              id: true,
              email: true,
              role: true,
              firstName: true,
              lastName: true,
              profile: {
                select: {
                  username: true,
                  profileImage: true,
                },
              },
            },
          },
          media: true,
          _count: {
            select: {
              comments: true,
              postReactions: true,
            },
          },
        },
      };

      const posts = await prisma.post.findMany(queryOptions);

      const hasMore = posts.length > limit;

      if (hasMore) {
        posts.pop();
      }

      const nextCursor = hasMore ? posts[posts.length - 1].id : null;

      const postIds = posts.map((post) => post.id);
      const engagementMetrics =
        postIds.length > 0
          ? await engagementHelpers.getBulkEngagementMetrics(postIds, userId)
          : {};

      const formattedPosts = posts.map((post) => {
        const metrics = engagementMetrics[post.id];
        const formatted = formatPostResponse(
          post,
          metrics?.userReactionType || null,
        );

        if (metrics) {
          formatted.reactionCount = metrics.totalReactions;
          formatted.reactionBreakdown = metrics.reactionCounts;
          formatted.commentCount = metrics.commentCount;
          formatted.bookmarkCount = metrics.bookmarkCount;
          formatted.userReacted = metrics.userReacted;
          formatted.userReaction = metrics.userReactionType || null;
          formatted.userBookmarked = metrics.userBookmarked;
        }

        return formatted;
      });

      const response = {
        data: formattedPosts,
        meta: {
          nextCursor,
          hasMore,
          limit,
          cachedAt: new Date().toISOString(),
          queryMs: Date.now() - startTime,
        },
      };

      await redisClient.set(cacheKey, response, 30); // short TTL for feed freshness

      return response;
    } catch (error) {
      console.error("PostFeedService.listPosts failed:", error?.message || error);
      throw new Error("Failed to load posts");
    }
  }

  async getPostById(postId, userId = null) {
    const cacheKey = `post:${postId}:${userId || "public"}`;
    const cached = await redisClient.get(cacheKey);
    if (cached) {
      return cached;
    }

    try {
      const post = await prisma.post.findUnique({
        where: { id: postId },
        include: {
          author: {
            select: {
              id: true,
              email: true,
              role: true,
              firstName: true,
              lastName: true,
              profile: {
                select: {
                  username: true,
                  profileImage: true,
                  bio: true,
                },
              },
            },
          },
          media: true,
          _count: {
            select: {
              comments: true,
              postReactions: true,
            },
          },
        },
      });

      if (!post || post.isDeleted) return null;

      if (post.visibility === "PRIVATE") {
        if (!userId) {
          throw new Error("Authentication required to view this post");
        }

        if (post.authorId !== userId) {
          const connectedUserIds = await getConnectedUserIds(prisma, userId);

          if (!connectedUserIds.includes(post.authorId)) {
            throw new Error("Not authorized to view this post");
          }
        }
      }

      const engagementMetrics = await engagementHelpers.getBulkEngagementMetrics(
        [post.id],
        userId,
      );

      const metrics = engagementMetrics[post.id];
      const formatted = formatPostResponse(
        post,
        metrics?.userReactionType || null,
      );

      if (metrics) {
        formatted.reactionCount = metrics.totalReactions;
        formatted.reactionBreakdown = metrics.reactionCounts;
        formatted.commentCount = metrics.commentCount;
        formatted.bookmarkCount = metrics.bookmarkCount;
        formatted.userReacted = metrics.userReacted;
        formatted.userReaction = metrics.userReactionType || null;
        formatted.userBookmarked = metrics.userBookmarked;
      }

      await redisClient.set(cacheKey, formatted, 60);

      return formatted;
    } catch (error) {
      console.error("PostFeedService.getPostById failed:", error?.message || error);
      throw new Error("Failed to load post");
    }
  }
}

module.exports = new PostFeedService();
