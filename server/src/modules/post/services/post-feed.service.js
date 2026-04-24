const prisma = require("../../../lib/prisma");

class PostFeedService {
  getPostInclude(userId = null) {
    return {
      author: {
        include: {
          profile: true,
        },
      },

      media: {
        select: {
          fileUrl: true, // ✅ FIXED for your schema
        },
      },

      postReactions: userId
        ? {
            where: { userId },
            select: { userId: true },
          }
        : false,

      favorites: userId
        ? {
            where: { userId },
            select: { userId: true },
          }
        : false,

      _count: {
        select: {
          comments: true,
          postReactions: true,
        },
      },
    };
  }

  // ================= LIST POSTS =================
  async listPosts(filters = {}, userId = null) {
    const { cursor, limit = 15, authorId } = filters;

    const take = Math.min(limit, 20);

    const where = {
      isDeleted: false,
      moderationStatus: "APPROVED",
      ...(authorId && { authorId }),
      ...(cursor && {
        createdAt: { lt: new Date(cursor) },
      }),
    };

    const posts = await prisma.post.findMany({
      where,
      orderBy: { createdAt: "desc" },
      take: take + 1,
      include: this.getPostInclude(userId),
    });

    const hasMore = posts.length > take;
    if (hasMore) posts.pop();

    const nextCursor = hasMore ? posts[posts.length - 1].createdAt : null;

    return {
      data: posts,
      meta: {
        nextCursor,
        hasMore,
        limit: take,
      },
    };
  }

  // ================= SINGLE POST =================
  async getPostById(postId, userId = null) {
    return prisma.post.findUnique({
      where: { id: postId },
      include: this.getPostInclude(userId),
    });
  }

  // ================= TRENDING =================
  async getTrendingPosts(limit = 20) {
    return prisma.post.findMany({
      where: {
        isDeleted: false,
        moderationStatus: "APPROVED",
      },
      orderBy: {
        postReactions: {
          _count: "desc",
        },
      },
      take: Math.min(limit, 50),
      include: this.getPostInclude(null),
    });
  }

  // ================= SEARCH =================
  async searchPosts(q, limit = 20) {
    return prisma.post.findMany({
      where: {
        isDeleted: false,
        moderationStatus: "APPROVED",
        ...(q && {
          content: {
            contains: q,
            mode: "insensitive",
          },
        }),
      },
      take: Math.min(limit, 50),
      orderBy: { createdAt: "desc" },
      include: this.getPostInclude(null),
    });
  }
}

module.exports = new PostFeedService();
