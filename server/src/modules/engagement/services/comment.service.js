// server/src/modules/engagement/services/comment.service.js
const prisma = require("../../../lib/prisma");
const commentRepository = require("../repositories/comment.repository");
const engagementCache = require("./engagement-cache.service");
const notificationHelper = require("../utils/notification.helper");
const aiModerationService = require("../../ai/ai-moderation.service");

class CommentService {
  /**
   * Add a comment to a post
   */
  async addComment(postId, userId, content, parentCommentId = null, createdAt) {
    const moderationResult = await aiModerationService.moderateContent(
      content || "",
    );
    const moderationStatus =
      moderationResult?.moderationStatus === "APPROVED" ||
      moderationResult?.moderationStatus === "REJECTED"
        ? moderationResult.moderationStatus
        : "PENDING";

    return await prisma.$transaction(async (tx) => {
      // Check if post exists
      const post = await tx.post.findUnique({
        where: { id: postId },
        select: { id: true, authorId: true },
      });

      if (!post) {
        throw new Error("Post not found");
      }

      // If replying to a comment, check if parent comment exists
      if (parentCommentId) {
        const parentComment = await tx.postComment.findUnique({
          where: { id: parentCommentId },
          select: { id: true },
        });

        if (!parentComment) {
          throw new Error("Parent comment not found");
        }
      }

      // Create comment
      const comment = await commentRepository.createComment({
        postId,
        commenterId: userId,
        parentCommentId,
        content,
        createdAt: createdAt ? new Date(createdAt) : new Date(),
        moderationStatus,
      });

      // Create notification for post author (if not self-comment)
      if (post.authorId !== userId) {
        await notificationHelper.createNotification({
          recipientId: post.authorId,
          actorId: userId,
          type: "COMMENT",
          referenceId: postId,
          referenceType: "POST",
          tx,
        });
      }

      // Invalidate cache
      await engagementCache.invalidatePostComments(postId);

      // Get updated comment count
      const commentCount = await commentRepository.countPostComments(postId);

      return {
        comment,
        commentCount,
      };
    });
  }

  /**
   * Get comments for a post with replies
   */
  async getComments(postId, cursor, limit = 20) {
    // Try cache first
    const cacheKey = `post:comments:${postId}:${cursor || "start"}`;
    const cached = await engagementCache.get(cacheKey);

    if (cached) {
      return cached;
    }

    // Get top-level comments
    const result = await commentRepository.getPostComments(
      postId,
      cursor,
      limit,
    );

    // Load replies for each comment
    const commentsWithReplies = await Promise.all(
      result.data.map(async (comment) => {
        const replies = await commentRepository.getCommentReplies(comment.id);
        return {
          ...comment,
          replies,
        };
      }),
    );

    const finalResult = {
      data: commentsWithReplies,
      nextCursor: result.nextCursor,
    };

    // Cache for 2 minutes (comments change frequently)
    await engagementCache.set(cacheKey, finalResult, 120);

    return finalResult;
  }

  /**
   * Delete a comment (soft delete)
   */
  async deleteComment(commentId, userId) {
    // Check if user owns the comment
    const isOwner = await commentRepository.isCommentOwner(commentId, userId);

    if (!isOwner) {
      throw new Error("Not authorized to delete this comment");
    }

    const comment = await commentRepository.findCommentById(commentId);

    if (!comment) {
      throw new Error("Comment not found");
    }

    await commentRepository.deleteComment(commentId);

    // Invalidate cache
    await engagementCache.invalidatePostComments(comment.postId);

    return { success: true };
  }

  /**
   * Get comment count for multiple posts (batch)
   */
  async getBulkCommentCounts(postIds) {
    const counts = await prisma.postComment.groupBy({
      by: ["postId"],
      where: {
        postId: { in: postIds },
        isDeleted: false,
      },
      _count: true,
    });

    const countMap = {};
    counts.forEach((item) => {
      countMap[item.postId] = item._count;
    });

    return countMap;
  }
}

module.exports = new CommentService();
