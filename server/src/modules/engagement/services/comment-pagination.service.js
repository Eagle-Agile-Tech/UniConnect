// server/src/modules/engagement/services/comment-pagination.service.js
const prisma = require("../../../lib/prisma");
const engagementCache = require("./engagement-cache.service");

class CommentPaginationService {
  /**
   * Get comments with full pagination metadata
   * Includes: total count, hasMore, nextCursor, page info
   */
  async getPaginatedComments(postId, userId, cursor, limit = 10) {
    const cacheKey = `comments:paginated:${postId}:${userId || "anon"}:${cursor || "start"}`;
    const cached = await engagementCache.get(cacheKey);
    if (cached) return cached;

    // Get total comment count for the post
    const totalCount = await prisma.postComment.count({
      where: {
        postId,
        parentCommentId: null,
        isDeleted: false,
        moderationStatus: "APPROVED",
      },
    });

    // Get paginated comments
    const comments = await prisma.postComment.findMany({
      where: {
        postId,
        parentCommentId: null,
        isDeleted: false,
        moderationStatus: "APPROVED",
      },
      take: limit,
      skip: cursor ? 1 : 0,
      cursor: cursor ? { id: cursor } : undefined,
      orderBy: [{ createdAt: "desc" }, { id: "asc" }],
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

    // Get user's reactions to comments (if logged in)
    let userReactions = new Map();
    if (userId && comments.length > 0) {
      const commentIds = comments.map((c) => c.id);
      const reactions = await prisma.commentReaction.findMany({
        where: {
          userId,
          commentId: { in: commentIds },
        },
        select: {
          commentId: true,
          type: true,
        },
      });

      reactions.forEach((r) => {
        userReactions.set(r.commentId, {
          hasReacted: true,
          reactionType: r.type,
        });
      });
    }

    // Enrich comments with user interaction data
    const enrichedComments = comments.map((comment) => ({
      ...comment,
      userInteraction: userId
        ? {
            hasReacted: userReactions.has(comment.id),
            reactionType: userReactions.get(comment.id)?.reactionType || null,
          }
        : null,
      replyCount: comment._count.replies,
      reactionCount: comment._count.commentReactions,
    }));

    const result = {
      data: enrichedComments,
      pagination: {
        total: totalCount,
        currentPage: cursor ? "paginated" : "first",
        nextCursor:
          comments.length === limit ? comments[comments.length - 1].id : null,
        hasMore: comments.length === limit,
        limit: limit,
      },
    };

    // Cache for 2 minutes
    await engagementCache.set(cacheKey, result, 120);

    return result;
  }

  /**
   * Get replies for a comment with pagination
   */
  async getPaginatedReplies(commentId, userId, cursor, limit = 5) {
    const cacheKey = `replies:paginated:${commentId}:${userId || "anon"}:${cursor || "start"}`;
    const cached = await engagementCache.get(cacheKey);
    if (cached) return cached;

    const totalCount = await prisma.postComment.count({
      where: {
        parentCommentId: commentId,
        isDeleted: false,
        moderationStatus: "APPROVED",
      },
    });

    const replies = await prisma.postComment.findMany({
      where: {
        parentCommentId: commentId,
        isDeleted: false,
        moderationStatus: "APPROVED",
      },
      take: limit,
      skip: cursor ? 1 : 0,
      cursor: cursor ? { id: cursor } : undefined,
      orderBy: { createdAt: "asc" },
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
            commentReactions: true,
          },
        },
      },
    });

    // Get user's reactions to replies
    let userReactions = new Map();
    if (userId && replies.length > 0) {
      const replyIds = replies.map((r) => r.id);
      const reactions = await prisma.commentReaction.findMany({
        where: {
          userId,
          commentId: { in: replyIds },
        },
        select: {
          commentId: true,
          type: true,
        },
      });

      reactions.forEach((r) => {
        userReactions.set(r.commentId, {
          hasReacted: true,
          reactionType: r.type,
        });
      });
    }

    const enrichedReplies = replies.map((reply) => ({
      ...reply,
      userInteraction: userId
        ? {
            hasReacted: userReactions.has(reply.id),
            reactionType: userReactions.get(reply.id)?.reactionType || null,
          }
        : null,
      reactionCount: reply._count.commentReactions,
    }));

    const result = {
      data: enrichedReplies,
      pagination: {
        total: totalCount,
        nextCursor:
          replies.length === limit ? replies[replies.length - 1].id : null,
        hasMore: replies.length === limit,
        limit: limit,
      },
    };

    await engagementCache.set(cacheKey, result, 120);

    return result;
  }
}

module.exports = new CommentPaginationService();
