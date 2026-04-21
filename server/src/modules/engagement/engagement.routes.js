const router = require("express").Router();
const authenticate = require("../../middlewares/authMiddleware");

const commentController = require("./controllers/comment.controller");
const likeController = require("./controllers/like.controller");
const bookmarkController = require("./controllers/bookmark.controller");

const { validate } = require("../../middlewares/validate");
const { validateComment } = require("./validations/comment.validation");
const { validateLike } = require("./validations/like.validation");
const { validateBookmark } = require("./validations/bookmark.validation");

router.use(authenticate);

// LIKE
router.post(
  "/posts/likePost/:postId",
  validate(validateLike),
  likeController.toggleLike,
);
router.get("/posts/:postId/reactions", likeController.getPostReactions);
router.get("/posts/:postId/hasLiked", likeController.hasUserLiked);

// COMMENTS
router.post(
  "/posts/commentPost/:postId",
  validate(validateComment),
  commentController.addComment,
);

router.get("/posts/comments/:postId", commentController.getComments);

router.get(
  "/posts/comments/:postId/paginated",
  commentController.getPaginatedComments,
);

router.get(
  "/posts/comments/:commentId/replies",
  commentController.getCommentReplies,
);

router.post(
  "/posts/comments/:commentId/reactions",
  commentController.toggleCommentReaction,
);

router.get(
  "/posts/comments/:commentId/reactions",
  commentController.getCommentReactions,
);

router.get(
  "/posts/comments/:commentId/hasReacted",
  commentController.hasUserReacted,
);

router.delete("/comments/:commentId", commentController.deleteComment);

// BOOKMARKS
router.post(
  "/posts/bookmarkPost/:postId",
  validate(validateBookmark),
  bookmarkController.toggleBookmark,
);

router.get("/posts/bookmarks/:userId", bookmarkController.getUserBookmarks);
router.delete("/posts/bookmarkPost/:postId", bookmarkController.removeBookmark);

module.exports = router;
