// server/src/modules/engagement/services/like.service.js
const prisma = require("../../../lib/prisma");
const likeRepository = require("../repositories/like.repository");
const engagementCache = require("./engagement-cache.service");
const notificationHelper = require("../utils/notification.helper");

class LikeService {
  /**
   * Toggle like on a post (like/unlike)
   */
  async toggleLike(userId, postId, type = "LIKE") {
    // Use transaction to ensure data consistency
    return await prisma.$transaction(async (tx) => {
      // Check if post exists
      const post = await tx.post.findUnique({
        where: { id: postId },
        select: { id: true, authorId: true },
      });

      if (!post) {
        throw new Error("Post not found");
      }

      // Check if already liked
      const existingLike = await likeRepository.findLike(userId, postId);

      let result;
      if (existingLike) {
        // Unlike
        await likeRepository.deleteLike(existingLike.id);
        result = { liked: false, action: "unliked" };
      } else {
        // Like
        const like = await likeRepository.createLike(userId, postId, type);

        // Create notification for post author (if not self-like)
        if (post.authorId !== userId) {
          await notificationHelper.createNotification({
            recipientId: post.authorId,
            actorId: userId,
            type: "REACTION",
            referenceId: postId,
            referenceType: "POST",
            tx,
          });
        }

        result = { liked: true, action: "liked", like };
      }

      // Get updated like count
      const likeCount = await likeRepository.countPostLikes(postId);

      // Invalidate cache
      await engagementCache.invalidatePostLikes(postId);

      return {
        ...result,
        likeCount,
      };
    });
  }

  /**
   * Get all likes for a post
   */
  async getPostLikes(postId, cursor, limit = 20) {
    // Try cache first
    const cacheKey = `post:likes:${postId}:${cursor || "start"}`;
    const cached = await engagementCache.get(cacheKey);

    if (cached) {
      return cached;
    }

    const result = await likeRepository.getPostLikes(postId, cursor, limit);

    // Cache for 5 minutes
    await engagementCache.set(cacheKey, result, 300);

    return result;
  }

  /**
   * Check if user has liked a post
   */
  async hasUserLiked(userId, postId) {
    return likeRepository.hasUserLiked(userId, postId);
  }

  /**
   * Get like status for multiple posts (for feed)
   */
  async getBulkLikeStatus(userId, postIds) {
    if (!userId || !postIds.length) return {};

    const likes = await prisma.postReaction.findMany({
      where: {
        userId,
        postId: { in: postIds },
      },
      select: {
        postId: true,
      },
    });

    const likedMap = {};
    likes.forEach((like) => {
      likedMap[like.postId] = true;
    });

    return likedMap;
  }

  /**
   * Get like counts for multiple posts (for feed)
   */
  async getBulkLikeCounts(postIds) {
    return likeRepository.getBulkLikeCounts(postIds);
  }
}

module.exports = new LikeService();
