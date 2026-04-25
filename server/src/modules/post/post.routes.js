const router = require("express").Router();
const postController = require("./post.controller");
const authenticate = require("../../middlewares/authMiddleware");
const upload = require("../../config/multer");

// ===== PUBLIC ROUTES (SPECIFIC ROUTES FIRST) =====
router.get("/", postController.listPosts);
router.get("/me", authenticate, postController.getMyPosts); // ✅ MUST be before /:postId
router.get("/user/:userId", postController.getUserPosts); // ✅ MUST be before /:postId
router.get("/:postId", postController.getPostById); // ⚠️ This MUST be LAST

// ===== AUTHENTICATED ROUTES =====
router.use(authenticate);

// ===== CREATE =====
router.post("/", upload.array("media", 10), postController.createPost);

// ===== UPDATE / DELETE =====
router.patch("/:postId", postController.updatePost);
router.delete("/:postId", postController.deletePost);

module.exports = router;
