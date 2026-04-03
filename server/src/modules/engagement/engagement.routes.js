// server/src/modules/engagement/engagement.routes.js
const router = require("express").Router();
const { authenticate } = require("../../middlewares/auth");

// Import controllers
const likeController = require("./controllers/like.controller");
const commentController = require("./controllers/comment.controller");
const bookmarkController = require("./controllers/bookmark.controller");

// Import validations
const { validateLike } = require("./validations/like.validation");
const { validateComment } = require("./validations/comment.validation");
const { validateBookmark } = require("./validations/bookmark.validation");
const { validate } = require("../../middlewares/validate");

// All engagement routes require authentication
router.use(authenticate);

// ===== LIKE/REACTION ROUTES =====
// POST /api/v1/posts/likePost/:postId - Like/unlike a post (matches frontend)
router.post(
  "/posts/likePost/:postId",
  validate(validateLike),
  likeController.toggleLike,
);

// GET /api/v1/posts/:postId/reactions - Get all reactions for a post
router.get("/posts/:postId/reactions", likeController.getPostReactions);

// GET /api/v1/posts/:postId/hasLiked - Check if user liked a post
router.get("/posts/:postId/hasLiked", likeController.hasUserLiked);
// GET /api/v1/posts/comments/:postId/paginated - Paginated comments with user interaction
router.get(
  "/posts/comments/:postId/paginated",
  commentController.getPaginatedComments
);
// GET /api/v1/posts/comments/:commentId/replies - Paginated replies
router.get(
  "/posts/comments/:commentId/replies",
  commentController.getCommentReplies
);
router.get(
  "/posts/comments/:commentId/reactions",
  commentController.getCommentReactions,
);
// GET /api/v1/posts/comments/:commentId/reactions - Get comment reactions
router.get(
  "/posts/comments/:commentId/reactions",
  commentController.getCommentReactions
);

// GET /api/v1/posts/comments/:commentId/hasReacted - Check user reaction
router.get(
  "/posts/comments/:commentId/hasReacted",
  commentController.hasUserReacted
);

// ===== COMMENT ROUTES =====
// POST /api/v1/posts/commentPost/:postId - Add comment (matches frontend)
router.post(
  "/posts/commentPost/:postId",
  validate(validateComment),
  commentController.addComment,
);

// GET /api/v1/posts/comments/:postId - Get comments (matches frontend)
router.get("/posts/comments/:postId", commentController.getComments);

// DELETE /api/v1/posts/comments/:commentId - Delete comment
router.delete("/posts/comments/:commentId", commentController.deleteComment);

// ===== BOOKMARK ROUTES =====
// POST /api/v1/posts/bookmarkPost/:postId - Bookmark a post (matches frontend)
router.post(
  "/posts/bookmarkPost/:postId",
  validate(validateBookmark),
  bookmarkController.toggleBookmark,
);

// GET /api/v1/posts/bookmarks/:userId - Get user's bookmarks (matches frontend)
router.get("/posts/bookmarks/:userId", bookmarkController.getUserBookmarks);

// DELETE /api/v1/posts/bookmarkPost/:postId - Remove bookmark
router.delete("/posts/bookmarkPost/:postId", bookmarkController.removeBookmark);

module.exports = router;
