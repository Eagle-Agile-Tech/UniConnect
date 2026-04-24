const postCreateService = require("./services/post-create.service");
const postFeedService = require("./services/post-feed.service");
const postUpdateService = require("./services/post-update.service");
const { formatPostDTO } = require("../../utils/postDTO");

// ================= CREATE POST =================
async function createPost(req, res, next) {
  try {
    const userId = req.user.id;

    const data = {
      content: req.body.content,
      tags: req.body.tags ? JSON.parse(req.body.tags) : [],
      // ❌ REMOVE createdAt completely (let DB handle it)
    };

    const files = req.files || [];

    const result = await postCreateService.createPost(userId, data, files);

    return res.status(201).json(formatPostDTO(result.post, userId));
  } catch (err) {
    next(err);
  }
}
// ================= LIST POSTS =================
async function listPosts(req, res, next) {
  try {
    const result = await postFeedService.listPosts(
      {
        cursor: req.query.cursor,
        limit: req.query.limit,
        authorId: req.query.authorId,
      },
      req.user?.id,
    );

    return res.json(result.data.map((p) => formatPostDTO(p, req.user?.id))); // ✅ RAW ARRAY
  } catch (err) {
    next(err);
  }
}

// ================= SINGLE POST =================
async function getPostById(req, res, next) {
  try {
    const post = await postFeedService.getPostById(
      req.params.postId,
      req.user?.id,
    );

    if (!post) {
      return res.status(404).json({ error: "Post not found" });
    }

    return res.json(formatPostDTO(post, req.user?.id)); // ✅ RAW OBJECT
  } catch (err) {
    next(err);
  }
}

// ================= UPDATE POST =================
async function updatePost(req, res, next) {
  try {
    const result = await postUpdateService.updatePost(
      req.params.postId,
      req.user.id,
      req.body,
    );

    return res.json(result); // ✅ RAW OBJECT
  } catch (err) {
    next(err);
  }
}

// ================= DELETE POST =================
async function deletePost(req, res, next) {
  try {
    await postUpdateService.deletePost(req.params.postId, req.user.id);

    return res.json({
      success: true,
      message: "Post deleted successfully",
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  createPost,
  listPosts,
  getPostById,
  updatePost,
  deletePost,
};
