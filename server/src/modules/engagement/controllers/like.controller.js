// server/src/modules/engagement/controllers/like.controller.js
const likeService = require("../services/like.service");

class LikeController {
  /**
   * Toggle like on a post
   * POST /api/v1/posts/likePost/:postId
   * Body: { "userId": "user-id", "type": "LIKE" }
   */
  async toggleLike(req, res, next) {
    try {
      const { postId } = req.params;
      const { userId, type = "LIKE" } = req.body;

      // Validate that userId matches authenticated user (security)
      if (userId !== req.user.id) {
        return res.status(403).json({
          error: "Cannot like on behalf of another user",
          code: "ERR_FORBIDDEN",
        });
      }

      const result = await likeService.toggleLike(userId, postId, type);

      res.json({
        message:
          result.action === "liked"
            ? "Post liked successfully"
            : "Post unliked successfully",
        data: {
          liked: result.liked,
          likeCount: result.likeCount,
        },
      });
    } catch (error) {
      if (error.message === "Post not found") {
        return res.status(404).json({
          error: error.message,
          code: "ERR_NOT_FOUND",
        });
      }
      next(error);
    }
  }

  /**
   * Get all reactions for a post
   * GET /api/v1/posts/:postId/reactions
   */
  async getPostReactions(req, res, next) {
    try {
      const { postId } = req.params;
      const { cursor, limit = 20 } = req.query;

      const result = await likeService.getPostLikes(
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
   * Check if current user liked the post
   * GET /api/v1/posts/:postId/hasLiked
   */
  async hasUserLiked(req, res, next) {
    try {
      const { postId } = req.params;
      const userId = req.user.id;

      const hasLiked = await likeService.hasUserLiked(userId, postId);

      res.json({
        data: { hasLiked },
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new LikeController();
