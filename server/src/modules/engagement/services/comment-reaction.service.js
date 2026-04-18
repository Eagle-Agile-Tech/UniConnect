// server/src/modules/engagement/services/comment-reaction.service.js
const prisma = require("../../../lib/prisma");
const engagementCache = require("./engagement-cache.service");
const notificationService = require("../../notification/notification.service");
const {
  interactionService,
} = require("../../ai-recommendation-service/interaction.service");

class CommentReactionService {
  /**
   * Toggle reaction on a comment (like/unlike)
   */
  async toggleReaction(commentId, userId, type = "LIKE") {
    return await prisma.$transaction(async (tx) => {
      // Check if comment exists
      const comment = await tx.postComment.findUnique({
        where: { id: commentId },
        select: {
          id: true,
          commenterId: true,
          post: {
            select: { id: true },
          },
        },
      });

      if (!comment) {
        throw new Error("Comment not found");
      }

      // Check if already reacted
      const existingReaction = await tx.commentReaction.findUnique({
        where: {
          userId_commentId: {
            userId,
            commentId,
          },
        },
      });

      let result;
      if (existingReaction) {
        // Remove reaction
        await tx.commentReaction.delete({
          where: { id: existingReaction.id },
        });
        result = { reacted: false, action: "unreacted" };
      } else {
        // Add reaction
        const reaction = await tx.commentReaction.create({
          data: {
            userId,
            commentId,
            type,
          },
        });

        await interactionService.logPostLike(
          userId,
          comment.post.id,
          {
            reactionType: type,
            commentId,
            source: "comment_reaction_toggle",
          },
          tx,
        );

        // Create notification for comment author (if not self-reaction)
        if (comment.commenterId !== userId) {
          await notificationService.createAndSendNotification({
            recipientId: comment.commenterId,
            actorId: userId,
            type: "REACTION",
            referenceId: comment.post.id,
            referenceType: "COMMENT",
            title: "New comment reaction",
            body: "Someone reacted to your comment",
            data: {
              reactionType: type,
              commentId: comment.id,
              postId: comment.post.id,
            },
            io: null,
            onlineUsers: null,
            tx,
          });
        }

        result = { reacted: true, action: "reacted", reaction };
      }

      // Get updated reaction count
      const reactionCount = await tx.commentReaction.count({
        where: { commentId },
      });

      // Invalidate caches
      await engagementCache.invalidateCommentReactions(commentId);
      await engagementCache.invalidatePostComments(comment.post.id);

      return {
        ...result,
        reactionCount,
      };
    });
  }

  /**
   * Get all reactions for a comment
   */
  async getCommentReactions(commentId, cursor, limit = 20) {
    const cacheKey = `comment:reactions:${commentId}:${cursor || "start"}`;
    const cached = await engagementCache.get(cacheKey);
    if (cached) return cached;

    const reactions = await prisma.commentReaction.findMany({
      where: { commentId },
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

    const result = {
      data: reactions,
      pagination: {
        nextCursor:
          reactions.length === limit
            ? reactions[reactions.length - 1].id
            : null,
        hasMore: reactions.length === limit,
      },
    };

    await engagementCache.set(cacheKey, result, 300);

    return result;
  }

  /**
   * Check if user has reacted to a comment
   */
  async hasUserReacted(userId, commentId) {
    const reaction = await prisma.commentReaction.findUnique({
      where: {
        userId_commentId: {
          userId,
          commentId,
        },
      },
      select: { type: true },
    });

    return {
      hasReacted: !!reaction,
      reactionType: reaction?.type || null,
    };
  }

  /**
   * Get reaction counts for multiple comments (batch)
   */
  async getBulkReactionCounts(commentIds) {
    const counts = await prisma.commentReaction.groupBy({
      by: ["commentId"],
      where: {
        commentId: { in: commentIds },
      },
      _count: true,
    });

    const countMap = {};
    counts.forEach((item) => {
      countMap[item.commentId] = item._count;
    });

    return countMap;
  }
}

module.exports = new CommentReactionService();
