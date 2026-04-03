// server/src/modules/engagement/utils/engagement.helpers.js
const prisma = require("../../../lib/prisma");

class EngagementHelpers {
  /**
   * Build reaction counts for a post
   * @param {string} postId - Post ID
   * @returns {Promise<Object>} Reaction counts by type
   */
  async getReactionCounts(postId) {
    const reactions = await prisma.postReaction.groupBy({
      by: ["type"],
      where: { postId },
      _count: true,
    });

    const counts = {
      LIKE: 0,
      LOVE: 0,
      INSIGHTFUL: 0,
      SUPPORT: 0,
      CELEBRATE: 0,
    };

    reactions.forEach((r) => {
      counts[r.type] = r._count;
    });

    return counts;
  }

  /**
   * Get engagement metrics for multiple posts (batch operation)
   * @param {string[]} postIds - Array of post IDs
   * @param {string} [userId] - Optional user ID to check personal engagement
   * @returns {Promise<Object>} Engagement metrics mapped by post ID
   */
  async getBulkEngagementMetrics(postIds, userId = null) {
    const metrics = {};

    // Get reaction counts for all posts
    const reactionCounts = await prisma.postReaction.groupBy({
      by: ["postId", "type"],
      where: {
        postId: { in: postIds },
      },
      _count: true,
    });

    // Get comment counts for all posts
    const commentCounts = await prisma.postComment.groupBy({
      by: ["postId"],
      where: {
        postId: { in: postIds },
        isDeleted: false,
      },
      _count: true,
    });

    // Get bookmark counts for all posts
    const bookmarkCounts = await prisma.favorite.groupBy({
      by: ["postId"],
      where: {
        postId: { in: postIds },
      },
      _count: true,
    });

    // Get user's reactions if userId provided
    let userReactions = [];
    if (userId) {
      userReactions = await prisma.postReaction.findMany({
        where: {
          userId,
          postId: { in: postIds },
        },
        select: {
          postId: true,
          type: true,
        },
      });
    }

    // Get user's bookmarks if userId provided
    let userBookmarks = [];
    if (userId) {
      userBookmarks = await prisma.favorite.findMany({
        where: {
          userId,
          postId: { in: postIds },
        },
        select: {
          postId: true,
        },
      });
    }

    // Build metrics map
    postIds.forEach((postId) => {
      // Initialize metrics for this post
      metrics[postId] = {
        reactionCounts: {
          LIKE: 0,
          LOVE: 0,
          INSIGHTFUL: 0,
          SUPPORT: 0,
          CELEBRATE: 0,
        },
        totalReactions: 0,
        commentCount: 0,
        bookmarkCount: 0,
        userReacted: false,
        userReactionType: null,
        userBookmarked: false,
      };

      // Add reaction counts
      reactionCounts
        .filter((r) => r.postId === postId)
        .forEach((r) => {
          metrics[postId].reactionCounts[r.type] = r._count;
          metrics[postId].totalReactions += r._count;
        });

      // Add comment count
      const commentCount = commentCounts.find((c) => c.postId === postId);
      if (commentCount) {
        metrics[postId].commentCount = commentCount._count;
      }

      // Add bookmark count
      const bookmarkCount = bookmarkCounts.find((b) => b.postId === postId);
      if (bookmarkCount) {
        metrics[postId].bookmarkCount = bookmarkCount._count;
      }

      // Add user reaction info
      if (userId) {
        const userReaction = userReactions.find((r) => r.postId === postId);
        if (userReaction) {
          metrics[postId].userReacted = true;
          metrics[postId].userReactionType = userReaction.type;
        }

        const userBookmark = userBookmarks.find((b) => b.postId === postId);
        if (userBookmark) {
          metrics[postId].userBookmarked = true;
        }
      }
    });

    return metrics;
  }

  /**
   * Format comment for response
   * @param {Object} comment - Raw comment from database
   * @param {Array} [replies] - Optional replies to include
   * @returns {Object} Formatted comment
   */
  formatCommentResponse(comment, replies = []) {
    return {
      id: comment.id,
      postId: comment.postId,
      content: comment.content,
      createdAt: comment.createdAt,
      updatedAt: comment.updatedAt,
      author: comment.commenter
        ? {
            id: comment.commenter.id,
            firstName: comment.commenter.firstName,
            lastName: comment.commenter.lastName,
            username: comment.commenter.profile?.username || null,
            profileImage: comment.commenter.profile?.profileImage || null,
          }
        : null,
      replyCount: comment._count?.replies || replies.length,
      reactionCount: comment._count?.commentReactions || 0,
      replies: replies.map((reply) => this.formatCommentResponse(reply)),
    };
  }

  /**
   * Format bookmark for response
   * @param {Object} bookmark - Raw bookmark from database
   * @returns {Object} Formatted bookmark with post details
   */
  formatBookmarkResponse(bookmark) {
    return {
      id: bookmark.id,
      bookmarkedAt: bookmark.createdAt,
      post: bookmark.post
        ? {
            id: bookmark.post.id,
            content: bookmark.post.content,
            createdAt: bookmark.post.createdAt,
            media: bookmark.post.media || [],
            author: bookmark.post.author
              ? {
                  id: bookmark.post.author.id,
                  firstName: bookmark.post.author.firstName,
                  lastName: bookmark.post.author.lastName,
                  username: bookmark.post.author.profile?.username || null,
                  profileImage: bookmark.post.author.profile?.profileImage || null,
                }
              : null,
            _count: bookmark.post._count || { comments: 0, postReactions: 0 },
          }
        : null,
    };
  }

  /**
   * Generate cache key for engagement data
   * @param {string} type - Type of cache (likes, comments, bookmarks)
   * @param {string} id - Related ID (postId or userId)
   * @param {string} [cursor] - Pagination cursor
   * @returns {string} Cache key
   */
  generateCacheKey(type, id, cursor = "start") {
    return `engagement:${type}:${id}:${cursor}`;
  }

  /**
   * Validate reaction type
   * @param {string} type - Reaction type to validate
   * @returns {boolean} True if valid
   */
  isValidReactionType(type) {
    const validTypes = ["LIKE", "LOVE", "INSIGHTFUL", "SUPPORT", "CELEBRATE"];
    return validTypes.includes(type);
  }

  /**
   * Check if user can comment (not banned, post exists, etc.)
   * @param {string} userId - User ID
   * @param {string} postId - Post ID
   * @returns {Promise<Object>} Validation result
   */
  async canUserComment(userId, postId) {
    // Check if user exists and is not deleted
    const user = await prisma.user.findUnique({
      where: { id: userId, isDeleted: false },
      select: { id: true },
    });

    if (!user) {
      return { allowed: false, reason: "User not found or deleted" };
    }

    // Check if post exists and is not deleted
    const post = await prisma.post.findUnique({
      where: { id: postId, isDeleted: false },
      select: { id: true, moderationStatus: true },
    });

    if (!post) {
      return { allowed: false, reason: "Post not found or deleted" };
    }

    if (post.moderationStatus !== "APPROVED") {
      return { allowed: false, reason: "Post is not approved for comments" };
    }

    return { allowed: true };
  }

  /**
   * Create engagement notification data
   * @param {string} type - Notification type
   * @param {Object} data - Notification data
   * @returns {Object} Formatted notification data
   */
  createNotificationData(type, data) {
    const base = {
      actorId: data.actorId,
      recipientId: data.recipientId,
      referenceId: data.referenceId,
      referenceType: "POST",
    };

    switch (type) {
      case "LIKE":
        return {
          ...base,
          type: "REACTION",
          metadata: {
            reactionType: data.reactionType || "LIKE",
            message: `${data.actorName} liked your post`,
          },
        };

      case "COMMENT":
        return {
          ...base,
          type: "COMMENT",
          metadata: {
            commentPreview: data.comment?.substring(0, 100),
            message: `${data.actorName} commented on your post`,
          },
        };

      case "REPLY":
        return {
          ...base,
          type: "COMMENT",
          metadata: {
            commentPreview: data.comment?.substring(0, 100),
            message: `${data.actorName} replied to your comment`,
          },
        };

      default:
        return base;
    }
  }
}

module.exports = new EngagementHelpers();
