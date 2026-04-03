// server/src/modules/engagement/repositories/like.repository.js
const prisma = require("../../../lib/prisma");

class LikeRepository {
  /**
   * Find a specific like by user and post
   */
  async findLike(userId, postId) {
    return prisma.postReaction.findUnique({
      where: {
        userId_postId: {
          userId,
          postId,
        },
      },
    });
  }

  /**
   * Create a new like
   */
  async createLike(userId, postId, type = "LIKE") {
    return prisma.postReaction.create({
      data: {
        userId,
        postId,
        type,
      },
      include: {
        user: {
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
      },
    });
  }

  /**
   * Delete a like
   */
  async deleteLike(id) {
    return prisma.postReaction.delete({
      where: { id },
    });
  }

  /**
   * Get all likes for a post with pagination
   */
  async getPostLikes(postId, cursor, limit = 20) {
    const likes = await prisma.postReaction.findMany({
      where: { postId },
      take: limit,
      skip: cursor ? 1 : 0,
      cursor: cursor ? { id: cursor } : undefined,
      orderBy: { createdAt: "desc" },
      include: {
        user: {
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
      },
    });

    return {
      data: likes,
      nextCursor: likes.length === limit ? likes[likes.length - 1].id : null,
    };
  }

  /**
   * Count likes for a post
   */
  async countPostLikes(postId) {
    return prisma.postReaction.count({
      where: { postId },
    });
  }

  /**
   * Check if user has liked a post
   */
  async hasUserLiked(userId, postId) {
    const like = await prisma.postReaction.findUnique({
      where: {
        userId_postId: {
          userId,
          postId,
        },
      },
      select: { id: true },
    });
    return !!like;
  }

  /**
   * Get likes count for multiple posts (batch)
   */
  async getBulkLikeCounts(postIds) {
    const counts = await prisma.postReaction.groupBy({
      by: ["postId"],
      where: {
        postId: { in: postIds },
      },
      _count: true,
    });

    // Convert to map for easy lookup
    const countMap = {};
    counts.forEach((item) => {
      countMap[item.postId] = item._count;
    });

    return countMap;
  }
}

module.exports = new LikeRepository();
