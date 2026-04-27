const prisma = require("../../../lib/prisma");
const engagementCache = require("./engagement-cache.service");
const CommentMapper = require("../mappers/comment.mapper");

class CommentPaginationService {
  async getPaginatedComments(postId, userId, cursor, limit = 10) {
    const cacheKey = `comments:paginated:${postId}:${userId || "anon"}:${cursor || "start"}`;

    const cached = await engagementCache.get(cacheKey);
    if (cached) return cached;

    const totalCount = await prisma.postComment.count({
      where: {
        postId,
        parentCommentId: null,
        isDeleted: false,
        moderationStatus: "APPROVED",
      },
    });

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

    const enrichedComments = CommentMapper.toList(comments, userReactions);

    const result = {
      data: enrichedComments,
      pagination: {
        total: totalCount,
        nextCursor:
          comments.length === limit ? comments[comments.length - 1].id : null,
        hasMore: comments.length === limit,
        limit,
      },
    };

    await engagementCache.set(cacheKey, result, 120);

    return result;
  }

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

    const enrichedReplies = CommentMapper.toList(replies, userReactions);

    const result = {
      data: enrichedReplies,
      pagination: {
        total: totalCount,
        nextCursor:
          replies.length === limit ? replies[replies.length - 1].id : null,
        hasMore: replies.length === limit,
        limit,
      },
    };

    await engagementCache.set(cacheKey, result, 120);

    return result;
  }
}

module.exports = new CommentPaginationService();
