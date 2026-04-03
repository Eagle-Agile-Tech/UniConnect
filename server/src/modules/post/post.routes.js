// server/src/modules/post/post.routes.js
const router = require("express").Router();
const postController = require("./post.controller"); // ← NO .default here
const authMiddleware = require("../../middlewares/auth");
const upload = require("../../config/multer");

// ===== PUBLIC ROUTES =====
router.get("/", postController.listPosts);
router.get("/trending", postController.getTrendingPosts);
router.get("/search", postController.searchPosts);
router.get("/:postId", postController.getPostById);
router.get("/:postId/comments", postController.getComments);
router.get("/feed/:userId", postController.getFeed);

// Protected routes
router.use(authMiddleware.authenticate);

// Create routes
router.post("/", postController.createPost);
router.post("/:userId", postController.createPost);
router.post(
  "/createPost/:userId",
  upload.array("media", 10),
  postController.createPostFromFlutter,
);

// Interactions
router.post("/:postId/reactions", postController.likePost);
router.post("/:postId/comments", postController.commentOnPost);
router.post("/:postId/favorite", postController.bookmarkPost);

// Management
router.patch("/:postId", postController.updatePost);
router.delete("/:postId", postController.deletePost);
router.post("/:postId/restore", postController.restorePost);

// Analytics
router.get("/:postId/analytics", postController.getPostAnalytics);
router.get("/users/:userId/favorites", postController.getBookmarks);

module.exports = router;
