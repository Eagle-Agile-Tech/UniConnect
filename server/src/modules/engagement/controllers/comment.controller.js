const commentService = require("../services/comment.service");
const commentPaginationService = require("../services/comment-pagination.service");
const commentReactionService = require("../services/comment-reaction.service");
const CommentMapper = require("../mappers/comment.mapper");

class CommentController {
  async addComment(req, res, next) {
    try {
      const { postId } = req.params;
      const { comment, parentCommentId, createdAt } = req.body;

      const result = await commentService.addComment(
        postId,
        req.user.id,
        comment,
        parentCommentId,
        createdAt,
      );

      res.status(201).json({
        message: "Comment added successfully",
        data: CommentMapper.toDTO(result.comment),
        commentCount: result.commentCount,
      });
    } catch (error) {
      next(error);
    }
  }

  async getComments(req, res, next) {
    try {
      const { postId } = req.params;
      const { cursor, limit } = req.query;

      const result = await commentService.getComments(
        postId,
        cursor,
        parseInt(limit || 20),
      );

      res.json({
        data: CommentMapper.toList(result.data),
        nextCursor: result.nextCursor,
      });
    } catch (error) {
      next(error);
    }
  }

  async getPaginatedComments(req, res, next) {
    try {
      const { postId } = req.params;
      const { cursor, limit } = req.query;

      const result = await commentPaginationService.getPaginatedComments(
        postId,
        req.user.id,
        cursor,
        parseInt(limit || 10),
      );

      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async getCommentReplies(req, res, next) {
    try {
      const { commentId } = req.params;
      const { cursor, limit } = req.query;

      const result = await commentPaginationService.getPaginatedReplies(
        commentId,
        req.user.id,
        cursor,
        parseInt(limit || 5),
      );

      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async toggleCommentReaction(req, res, next) {
    try {
      const { commentId } = req.params;
      const { type } = req.body;

      const result = await commentReactionService.toggleReaction(
        commentId,
        req.user.id,
        type || "LIKE",
      );

      res.json({
        message:
          result.action === "reacted" ? "Comment reacted" : "Reaction removed",
        data: {
          reacted: result.reacted,
          reactionCount: result.reactionCount,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  async getCommentReactions(req, res, next) {
    try {
      const { commentId } = req.params;
      const { cursor, limit } = req.query;

      const result = await commentReactionService.getCommentReactions(
        commentId,
        cursor,
        parseInt(limit || 20),
      );

      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async hasUserReacted(req, res, next) {
    try {
      const { commentId } = req.params;

      const result = await commentReactionService.hasUserReacted(
        req.user.id,
        commentId,
      );

      res.json({ data: result });
    } catch (error) {
      next(error);
    }
  }

  async deleteComment(req, res, next) {
    try {
      const { commentId } = req.params;

      await commentService.deleteComment(commentId, req.user.id);

      res.status(204).send();
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new CommentController();
