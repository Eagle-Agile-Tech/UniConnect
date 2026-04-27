// server/src/modules/engagement/controllers/bookmark.controller.js
const bookmarkService = require("../services/bookmark.service");

class BookmarkController {
  /**
   * Toggle bookmark on a post
   * POST /api/v1/posts/bookmarkPost/:postId
   * Body: {}
   */
  async toggleBookmark(req, res, next) {
    try {
      const { postId } = req.params;
      const userId = req.user.id;

      const result = await bookmarkService.toggleBookmark(userId, postId);

      res.json({
        message:
          result.action === "added"
            ? "Post bookmarked successfully"
            : "Bookmark removed successfully",
        data: {
          bookmarked: result.bookmarked,
          bookmarkId: result.bookmark?.id,
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
   * Get user's bookmarked posts
   * GET /api/v1/posts/bookmarks/:userId
   */
  async getUserBookmarks(req, res, next) {
    try {
      const { userId } = req.params;
      const { cursor, limit = 10 } = req.query;

      // Security check - users can only see their own bookmarks
      if (userId !== req.user.id) {
        return res.status(403).json({
          error: "Not authorized to view these bookmarks",
          code: "ERR_FORBIDDEN",
        });
      }

      const result = await bookmarkService.getUserBookmarks(
        userId,
        cursor,
        parseInt(limit),
      );

      res.json(result.data);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Remove a bookmark
   * DELETE /api/v1/posts/bookmarkPost/:postId
   */
  async removeBookmark(req, res, next) {
    try {
      const { postId } = req.params;
      const userId = req.user.id;

      await bookmarkService.removeBookmark(userId, postId);

      res.status(204).send();
    } catch (error) {
      if (error.message === "Bookmark not found") {
        return res.status(404).json({
          error: error.message,
          code: "ERR_NOT_FOUND",
        });
      }
      next(error);
    }
  }
}

module.exports = new BookmarkController();
