const prisma = require("../../../lib/prisma");
const engagementCache = require("./engagement-cache.service");
const notificationHelper = require("../utils/notification.helper");
const aiModerationService = require("../../ai/ai-moderation.service");

class CommentService {
  async addComment(postId, userId, content, parentCommentId, createdAt) {
    const moderation = await aiModerationService.moderateContent(content || "");

    const moderationStatus =
      moderation?.moderationStatus === "APPROVED" ? "APPROVED" : "PENDING";

    return prisma.$transaction(async (tx) => {
      const post = await tx.post.findUnique({
        where: { id: postId },
        select: { id: true, authorId: true },
      });

      if (!post) throw new Error("Post not found");

      const comment = await tx.postComment.create({
        data: {
          postId,
          commenterId: userId,
          parentCommentId,
          content,
          createdAt: createdAt ? new Date(createdAt) : new Date(),
          moderationStatus,
        },
      });

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

      await engagementCache.invalidatePostComments(postId);

      const commentCount = await tx.postComment.count({
        where: {
          postId,
          isDeleted: false,
          moderationStatus: "APPROVED",
        },
      });

      return { comment, commentCount };
    });
  }

  async getComments(postId, cursor, limit = 20) {
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
      orderBy: { createdAt: "desc" },
    });

    return {
      data: comments,
      nextCursor: comments.length === limit ? comments.at(-1).id : null,
    };
  }

  async deleteComment(commentId, userId) {
    const comment = await prisma.postComment.findUnique({
      where: { id: commentId },
    });

    if (!comment) throw new Error("Comment not found");
    if (comment.commenterId !== userId) throw new Error("Not authorized");

    await prisma.postComment.update({
      where: { id: commentId },
      data: { isDeleted: true },
    });

    await engagementCache.invalidatePostComments(comment.postId);

    return { success: true };
  }
}

module.exports = new CommentService();
