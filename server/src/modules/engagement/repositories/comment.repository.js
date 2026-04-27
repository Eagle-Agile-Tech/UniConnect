// server/src/modules/engagement/repositories/comment.repository.js
const prisma = require("../../../lib/prisma");

class CommentRepository {
  /**
   * Create a new comment
   */
  async createComment(data) {
    return prisma.postComment.create({
      data,
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
      },
    });
  }

  /**
   * Find comment by ID
   */
  async findCommentById(id) {
    return prisma.postComment.findUnique({
      where: { id },
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
      },
    });
  }

  /**
   * Get comments for a post with pagination
   */
  async getPostComments(postId, cursor, limit = 20) {
    const comments = await prisma.postComment.findMany({
      where: {
        postId,
        parentCommentId: null, // Get top-level comments only
        isDeleted: false,
      },
      take: limit,
      skip: cursor ? 1 : 0,
      cursor: cursor ? { id: cursor } : undefined,
      orderBy: { createdAt: "desc" },
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

    return {
      data: comments,
      nextCursor:
        comments.length === limit ? comments[comments.length - 1].id : null,
    };
  }

  /**
   * Get replies for a comment
   */
  async getCommentReplies(commentId) {
    return prisma.postComment.findMany({
      where: {
        parentCommentId: commentId,
        isDeleted: false,
      },
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
  }

  /**
   * Soft delete a comment
   */
  async deleteComment(id) {
    return prisma.postComment.update({
      where: { id },
      data: { isDeleted: true },
    });
  }

  /**
   * Count comments for a post
   */
  async countPostComments(postId) {
    return prisma.postComment.count({
      where: {
        postId,
        isDeleted: false,
      },
    });
  }

  /**
   * Check if user owns the comment
   */
  async isCommentOwner(commentId, userId) {
    const comment = await prisma.postComment.findUnique({
      where: { id: commentId },
      select: { commenterId: true },
    });
    return comment?.commenterId === userId;
  }
}

module.exports = new CommentRepository();
