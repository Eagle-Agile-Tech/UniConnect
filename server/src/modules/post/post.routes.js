const router = require("express").Router();
const postController = require("./post.controller");
const authenticate = require("../../middlewares/authMiddleware");
const upload = require("../../config/multer");
const jwt = require("jsonwebtoken");

function optionalAuthenticate(req, _res, next) {
  const authHeader = req.headers.authorization;
  const token = authHeader && authHeader.split(" ")[1];

  if (!token) return next();

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userId = decoded.id || decoded.sub || decoded.userId;
    req.user = {
      ...decoded,
      id: userId,
    };
  } catch (_error) {
    // Keep public feed endpoints accessible even when token is missing/invalid.
  }

  return next();
}

// ===== PUBLIC ROUTES (SPECIFIC ROUTES FIRST) =====
router.get("/", optionalAuthenticate, postController.listPosts);
router.get("/me", authenticate, postController.getMyPosts);
router.get("/user/:userId", optionalAuthenticate, postController.getUserPosts);
router.get("/:postId", optionalAuthenticate, postController.getPostById);

// ===== AUTHENTICATED ROUTES =====
router.use(authenticate);

// ===== CREATE =====
router.post("/", upload.array("media", 10), postController.createPost);

// ===== UPDATE / DELETE =====
router.patch("/:postId", postController.updatePost);
router.delete("/:postId", postController.deletePost);

module.exports = router;
