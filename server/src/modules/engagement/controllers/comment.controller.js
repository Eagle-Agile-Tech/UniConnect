// server/src/modules/engagement/controllers/comment.controller.js
const commentService = require("../services/comment.service");

class CommentController {
  /**
   * Add a comment to a post
   * POST /api/v1/posts/commentPost/:postId
   * Body: {
   *   "postId": "post-id",
   *   "comment": "Great post!",
   *   "createdAt": "2024-03-10T12:00:00.000Z",
   *   "authorId": "user-id"
   * }
   */
  async addComment(req, res, next) {
    try {
      const { postId } = req.params;
      const { comment, authorId, createdAt, parentCommentId } = req.body;

      // Security check
      if (authorId !== req.user.id) {
        return res.status(403).json({
          error: "Cannot comment on behalf of another user",
          code: "ERR_FORBIDDEN",
        });
      }

      const result = await commentService.addComment(
        postId,
        authorId,
        comment,
        parentCommentId,
        createdAt,
      );

      res.status(201).json({
        message: "Comment added successfully",
        data: result.comment,
      });
    } catch (error) {
      if (error.message.includes("not found")) {
        return res.status(404).json({
          error: error.message,
          code: "ERR_NOT_FOUND",
        });
      }
      next(error);
    }
  }

  /**
   * Get comments for a post
   * GET /api/v1/posts/comments/:postId
   */
  async getComments(req, res, next) {
    try {
      const { postId } = req.params;
      const { cursor, limit = 20 } = req.query;

      const result = await commentService.getComments(
        postId,
        cursor,
        parseInt(limit),
      );

      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Delete a comment
   * DELETE /api/v1/posts/comments/:commentId
   */
  async deleteComment(req, res, next) {
    try {
      const { commentId } = req.params;
      const userId = req.user.id;

      await commentService.deleteComment(commentId, userId);

      res.status(204).send();
    } catch (error) {
      if (error.message === "Not authorized to delete this comment") {
        return res.status(403).json({
          error: error.message,
          code: "ERR_FORBIDDEN",
        });
      }
      if (error.message === "Comment not found") {
        return res.status(404).json({
          error: error.message,
          code: "ERR_NOT_FOUND",
        });
      }
      next(error);
    }
  }
  // Add these methods to your existing comment.controller.js
  // Place them before the last closing bracket of the class

  /**
   * Get paginated comments with user interaction status
   * GET /api/v1/posts/comments/:postId/paginated?cursor=&limit=10
   */
  async getPaginatedComments(req, res, next) {
    try {
      const { postId } = req.params;
      const { cursor, limit = 10 } = req.query;
      const userId = req.user.id;

      const commentPaginationService = require("../services/comment-pagination.service");

      const result = await commentPaginationService.getPaginatedComments(
        postId,
        userId,
        cursor,
        parseInt(limit),
      );

      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get paginated replies for a comment
   * GET /api/v1/posts/comments/:commentId/replies?cursor=&limit=5
   */
  async getCommentReplies(req, res, next) {
    try {
      const { commentId } = req.params;
      const { cursor, limit = 5 } = req.query;
      const userId = req.user.id;

      const commentPaginationService = require("../services/comment-pagination.service");

      const result = await commentPaginationService.getPaginatedReplies(
        commentId,
        userId,
        cursor,
        parseInt(limit),
      );

      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Toggle reaction on a comment (like/unlike)
   * POST /api/v1/posts/comments/:commentId/reactions
   */
  async toggleCommentReaction(req, res, next) {
    try {
      const { commentId } = req.params;
      const { type = "LIKE" } = req.body;
      const userId = req.user.id;

      const commentReactionService = require("../services/comment-reaction.service");

      const result = await commentReactionService.toggleReaction(
        commentId,
        userId,
        type,
      );

      res.json({
        message:
          result.action === "reacted"
            ? "Comment reacted successfully"
            : "Reaction removed successfully",
        data: {
          reacted: result.reacted,
          reactionCount: result.reactionCount,
        },
      });
    } catch (error) {
      if (error.message === "Comment not found") {
        return res.status(404).json({
          error: error.message,
          code: "ERR_NOT_FOUND",
        });
      }
      next(error);
    }
  }

  /**
   * Get all reactions for a comment
   * GET /api/v1/posts/comments/:commentId/reactions
   */
  async getCommentReactions(req, res, next) {
    try {
      const { commentId } = req.params;
      const { cursor, limit = 20 } = req.query;

      const commentReactionService = require("../services/comment-reaction.service");

      const result = await commentReactionService.getCommentReactions(
        commentId,
        cursor,
        parseInt(limit),
      );

      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Check if user has reacted to a comment
   * GET /api/v1/posts/comments/:commentId/hasReacted
   */
  async hasUserReacted(req, res, next) {
    try {
      const { commentId } = req.params;
      const userId = req.user.id;

      const commentReactionService = require("../services/comment-reaction.service");

      const result = await commentReactionService.hasUserReacted(
        userId,
        commentId,
      );

      res.json({ data: result });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new CommentController();
