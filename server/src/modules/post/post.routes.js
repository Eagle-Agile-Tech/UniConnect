const router = require("express").Router();
const postController = require("./post.controller");
const authenticate = require("../../middlewares/authMiddleware");
const upload = require("../../config/multer");

// ===== PUBLIC =====
router.get("/", postController.listPosts);
router.get("/:postId", postController.getPostById);

// ===== AUTH =====
router.use(authenticate);

// ===== CREATE =====
router.post("/", upload.array("media", 10), postController.createPost);

// ===== UPDATE / DELETE =====
router.patch("/:postId", postController.updatePost);
router.delete("/:postId", postController.deletePost);

module.exports = router;
