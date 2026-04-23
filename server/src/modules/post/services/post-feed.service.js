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
  getPostInclude() {
    return {
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
          favorites: true,
        },
      },
    };
  }

  formatPostWithCounts(post) {
    const formatted = formatPostResponse(post);
    formatted.reactionCount = post._count?.postReactions || 0;
    formatted.commentCount = post._count?.comments || 0;
    formatted.bookmarkCount = post._count?.favorites || 0;
    return formatted;
  }

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
        include: this.getPostInclude(),
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
        include: this.getPostInclude(),
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

  async getFeedForUser(userId, filters = {}) {
    if (!userId) {
      throw new Error("userId is required");
    }

    return this.listPosts(filters, userId);
  }

  async getComments(postId, filters = {}) {
    const limit = Math.min(parseInt(filters.limit || 20), 50);
    const cursor = filters.cursor;

    const where = {
      postId,
      isDeleted: false,
      moderationStatus: "APPROVED",
    };

    if (cursor) {
      const cursorComment = await prisma.postComment.findUnique({
        where: { id: cursor },
        select: { createdAt: true, id: true },
      });

      if (cursorComment) {
        where.OR = [
          { createdAt: { lt: cursorComment.createdAt } },
          { createdAt: cursorComment.createdAt, id: { lt: cursorComment.id } },
        ];
      }
    }

    const comments = await prisma.postComment.findMany({
      where,
      orderBy: [{ createdAt: "desc" }, { id: "desc" }],
      take: limit + 1,
      include: {
        commenter: {
          select: {
            id: true,
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
        _count: {
          select: {
            replies: true,
            commentReactions: true,
          },
        },
      },
    });

    const hasMore = comments.length > limit;
    if (hasMore) comments.pop();

    return {
      data: comments,
      meta: {
        nextCursor: hasMore ? comments[comments.length - 1].id : null,
        hasMore,
        limit,
      },
    };
  }

  async getUserFavorites(userId, filters = {}) {
    const limit = Math.min(parseInt(filters.limit || 20), 50);
    const cursor = filters.cursor;

    const favorites = await prisma.favorite.findMany({
      where: { userId },
      orderBy: [{ createdAt: "desc" }, { id: "desc" }],
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      take: limit + 1,
      include: {
        post: {
          include: this.getPostInclude(),
        },
      },
    });

    const hasMore = favorites.length > limit;
    if (hasMore) favorites.pop();

    return {
      data: favorites.map((item) => this.formatPostWithCounts(item.post)),
      meta: {
        nextCursor: hasMore ? favorites[favorites.length - 1].id : null,
        hasMore,
        limit,
      },
    };
  }

  async getTrendingPosts(filters = {}) {
    const limit = Math.min(parseInt(filters.limit || 20), 50);
    const windowMap = {
      day: 1,
      week: 7,
      month: 30,
    };

    const days = windowMap[filters.timeWindow] || 1;
    const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000);

    const posts = await prisma.post.findMany({
      where: {
        isDeleted: false,
        moderationStatus: "APPROVED",
        visibility: "PUBLIC",
        createdAt: { gte: since },
      },
      orderBy: [
        { postReactions: { _count: "desc" } },
        { comments: { _count: "desc" } },
        { createdAt: "desc" },
      ],
      take: limit,
      include: this.getPostInclude(),
    });

    return {
      data: posts.map((post) => this.formatPostWithCounts(post)),
      meta: {
        limit,
        timeWindow: filters.timeWindow || "day",
      },
    };
  }

  async searchPosts(filters = {}) {
    const limit = Math.min(parseInt(filters.limit || 20), 50);

    const where = {
      isDeleted: false,
      moderationStatus: "APPROVED",
      ...(filters.authorId ? { authorId: filters.authorId } : {}),
      ...(filters.category ? { category: filters.category } : {}),
      ...(filters.q ? { content: { contains: filters.q, mode: "insensitive" } } : {}),
      ...(filters.tags?.length ? { tags: { hasSome: filters.tags } } : {}),
      ...(filters.fromDate || filters.toDate
        ? {
            createdAt: {
              ...(filters.fromDate ? { gte: new Date(filters.fromDate) } : {}),
              ...(filters.toDate ? { lte: new Date(filters.toDate) } : {}),
            },
          }
        : {}),
      ...(filters.hasMedia ? { media: { some: {} } } : {}),
    };

    const posts = await prisma.post.findMany({
      where,
      orderBy: [{ createdAt: "desc" }, { id: "desc" }],
      take: limit,
      include: this.getPostInclude(),
    });

    return {
      data: posts.map((post) => this.formatPostWithCounts(post)),
      meta: { limit },
    };
  }

  async getPostAnalytics(postId, userId) {
    const post = await prisma.post.findUnique({
      where: { id: postId },
      select: { id: true, authorId: true, createdAt: true },
    });

    if (!post) {
      throw new Error("Post not found");
    }

    if (post.authorId !== userId) {
      throw new Error("Not authorized");
    }

    const [reactionCount, commentCount, bookmarkCount, reactionBreakdown] =
      await Promise.all([
        prisma.postReaction.count({ where: { postId } }),
        prisma.postComment.count({ where: { postId, isDeleted: false } }),
        prisma.favorite.count({ where: { postId } }),
        prisma.postReaction.groupBy({
          by: ["type"],
          where: { postId },
          _count: { _all: true },
        }),
      ]);

    return {
      data: {
        postId,
        createdAt: post.createdAt,
        reactionCount,
        commentCount,
        bookmarkCount,
        reactionBreakdown: reactionBreakdown.reduce((acc, item) => {
          acc[item.type] = item._count._all;
          return acc;
        }, {}),
      },
    };
  }
}

module.exports = new PostFeedService();
