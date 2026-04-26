const postCreateService = require("./services/post-create.service");
const postFeedService = require("./services/post-feed.service");
const postUpdateService = require("./services/post-update.service");
const { formatPostDTO } = require("../../utils/postDTO");

// ================= CREATE POST =================
// post.controller.js
async function createPost(req, res, next) {
  try {
    const userId = req.user.id;

    let tags = req.body.tags;
    if (typeof tags === "string") {
      try {
        tags = JSON.parse(tags);
      } catch (e) {
        tags = tags.split(",").map((t) => t.trim());
      }
    } else if (!tags) {
      tags = [];
    }

    const data = {
      content: req.body.content || "",
      tags: tags,
    };

    const files = req.files || [];

    const result = await postCreateService.createPost(userId, data, files);

    // 🔥 CHECK THE STATUS FIRST
    if (result.status === "REJECTED") {
      return res.status(403).json({
        success: false,
        status: "REJECTED",
        message: result.message,
        details: result.details,
      });
    }

    if (result.status === "PENDING") {
      return res.status(202).json({
        success: false,
        status: "PENDING",
        message: result.message,
        details: result.details,
      });
    }

    // Only APPROVED posts have the 'post' property
    if (!result.post) {
      throw new Error("Invalid response from post creation service");
    }

    const formattedPost = formatPostDTO(result.post, userId);
    return res.status(201).json(formattedPost);
  } catch (err) {
    console.error("Create post error:", err);
    next(err);
  }
}

// ================= GET MY POSTS =================
async function getMyPosts(req, res, next) {
  try {
    const userId = req.user.id; // Get logged-in user's ID
    
    const result = await postFeedService.listPosts(
      {
        cursor: req.query.cursor,
        limit: req.query.limit,
        authorId: userId, // Filter by current user
      },
      userId,
    );

    return res.json(result.data.map((p) => formatPostDTO(p, userId)));
  } catch (err) {
    next(err);
  }
}

// ================= GET USER'S POSTS =================
async function getUserPosts(req, res, next) {
  try {
     console.log("✅ getMyPosts called"); 
    const { userId } = req.params; // Get userId from URL parameter
    
    const result = await postFeedService.listPosts(
      {
        cursor: req.query.cursor,
        limit: req.query.limit,
        authorId: userId, // Filter by specified user
      },
      req.user?.id, // Pass current user for reactions (if logged in)
    );

    return res.json(result.data.map((p) => formatPostDTO(p, req.user?.id)));
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

// ================= FEED =================
// Public-ish feed endpoint used by system tests and some clients.
// If authenticated, we use the token user id for per-user include fields.
// Otherwise we accept the path param user id to keep a stable API surface.
async function getFeed(req, res, next) {
  try {
    const viewerId = req.user?.id || req.params.userId || null;

    const result = await postFeedService.listPosts(
      {
        cursor: req.query.cursor,
        limit: req.query.limit,
      },
      viewerId,
    );

    return res.json(result.data.map((p) => formatPostDTO(p, viewerId)));
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
  getFeed,
  listPosts,
  getPostById,
  updatePost,
  deletePost,
   getMyPosts,      
  getUserPosts,
};
