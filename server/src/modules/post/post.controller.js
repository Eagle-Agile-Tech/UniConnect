// server/src/modules/post/post.controller.js
const postCreateService =
  require("./services/post-create.service").default ||
  require("./services/post-create.service");
const postFeedService = require("./services/post-feed.service");
const postCacheService = require("./services/post-cache.service");
const {
  interactionService,
} = require("../ai-recommendation-service/interaction.service");

class PostController {
  // ===== CREATE =====
  async createPost(req, res, next) {
    try {
      const userId = req.params.userId || req.user.id;
      const postData = req.body;

      const { post, moderationResult } = await postCreateService.createPost(
        userId,
        postData,
      );

      await postCacheService.cachePost(post.id, post);
      await postCacheService.invalidateFeedCache();

      if (moderationResult.moderationStatus === "PENDING") {
        return res.status(202).json({
          success: true,
          message: "Post submitted for review and is pending admin approval",
          data: post,
          moderation: { status: "PENDING", details: moderationResult.details },
        });
      }

      if (moderationResult.moderationStatus === "REJECTED") {
        return res.status(201).json({
          success: true,
          message: "Post created but rejected by content moderation",
          data: post,
          moderation: { status: "REJECTED", details: moderationResult.details },
        });
      }

      res.status(201).json({
        success: true,
        message: "Post created successfully",
        data: post,
        moderation: { status: "APPROVED" },
      });
    } catch (error) {
      console.error("Create post error:", error);
      next(error);
    }
  }

  async createPostFromFlutter(req, res, next) {
    try {
      console.log("📸 createPostFromFlutter called");
      const userId = req.params.userId || req.user?.id;

      const postData = {
        content: req.body.content,
        hashtags: req.body.hashtags,
        createdAt: req.body.createdAt,
      };

      const files = req.files || [];

      const { post, moderationResult } =
        await postCreateService.createPostFromFlutter(userId, postData, files);

      await postCacheService.cachePost(post.id, post);
      await postCacheService.invalidateFeedCache();

      if (moderationResult.moderationStatus === "PENDING") {
        return res.status(202).json({
          success: true,
          message: "Post submitted for review and is pending admin approval",
          data: post,
          moderation: { status: "PENDING", details: moderationResult.details },
        });
      }

      if (moderationResult.moderationStatus === "REJECTED") {
        return res.status(201).json({
          success: true,
          message: "Post created but rejected by content moderation",
          data: post,
          moderation: { status: "REJECTED", details: moderationResult.details },
        });
      }

      res.status(201).json({
        success: true,
        message: "Post created successfully",
        data: post,
        moderation: { status: "APPROVED" },
      });
    } catch (error) {
      console.error("Error in createPostFromFlutter:", error);
      next(error);
    }
  }

  // ==================== ALL YOUR ORIGINAL METHODS (100% UNCHANGED) ====================

  async getPostById(req, res, next) {
    try {
      const { postId } = req.params;
      const userId = req.user?.id;

      const cachedPost = await postCacheService.getCachedPost(postId);
      if (cachedPost) {
        if (userId) {
          await interactionService.logPostView(userId, postId, {
            source: "post_detail",
            cached: true,
          });
        }
        return res.json({ data: cachedPost });
      }

      const post = await postFeedService.getPostById(postId, userId);
      if (!post)
        return res
          .status(404)
          .json({ error: "Post not found", code: "ERR_NOT_FOUND" });

      await postCacheService.cachePost(postId, post);
      if (userId) {
        await interactionService.logPostView(userId, postId, {
          source: "post_detail",
          cached: false,
        });
      }
      res.json({ data: post });
    } catch (error) {
      next(error);
    }
  }

  async listPosts(req, res, next) {
    try {
      const userId = req.user?.id;
      const limit = req.query.limit ? parseInt(req.query.limit) : 15;

      const filters = {
        cursor: req.query.cursor,
        limit,
        authorId: req.query.authorId,
      };

      const result = await postFeedService.listPosts(filters, userId);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async getFeed(req, res, next) {
    try {
      const { userId } = req.params;
      const filters = {
        cursor: req.query.cursor,
        limit: req.query.limit ? parseInt(req.query.limit) : 10,
      };

      const result = await postFeedService.getFeedForUser(userId, filters);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async getComments(req, res, next) {
    try {
      const { postId } = req.params;
      const filters = {
        cursor: req.query.cursor,
        limit: req.query.limit ? parseInt(req.query.limit) : 20,
      };

      const result = await postFeedService.getComments(postId, filters);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async getBookmarks(req, res, next) {
    try {
      const { userId } = req.params;
      const currentUserId = req.user.id;

      if (userId !== currentUserId) {
        return res
          .status(403)
          .json({ error: "Not authorized", code: "ERR_FORBIDDEN" });
      }

      const filters = {
        cursor: req.query.cursor,
        limit: req.query.limit ? parseInt(req.query.limit) : 20,
      };

      const result = await postFeedService.getUserFavorites(userId, filters);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async getTrendingPosts(req, res, next) {
    try {
      const { timeWindow = "day", limit = 20 } = req.query;
      const filters = {
        timeWindow,
        limit: parseInt(limit),
        cursor: req.query.cursor,
      };
      const result = await postFeedService.getTrendingPosts(filters);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async searchPosts(req, res, next) {
    try {
      const filters = {
        q: req.query.q,
        tags: req.query.tags ? req.query.tags.split(",") : undefined,
        authorId: req.query.authorId,
        category: req.query.category,
        fromDate: req.query.fromDate,
        toDate: req.query.toDate,
        hasMedia: req.query.hasMedia === "true",
        sortBy: req.query.sortBy || "createdAt",
        sortOrder: req.query.sortOrder || "desc",
        cursor: req.query.cursor,
        limit: req.query.limit ? parseInt(req.query.limit) : 20,
      };

      const result = await postFeedService.searchPosts(filters);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  async getPostAnalytics(req, res, next) {
    try {
      const { postId } = req.params;
      const userId = req.user.id;
      const analytics = await postFeedService.getPostAnalytics(postId, userId);
      res.json(analytics);
    } catch (error) {
      next(error);
    }
  }

  async likePost(req, res, next) {
    try {
      const { postId } = req.params;
      const userId = req.user.id;
      const { type = "LIKE" } = req.body;
      const result = await postCreateService.toggleReaction(
        postId,
        userId,
        type,
      );

      await postCacheService.invalidatePost(postId);
      await postCacheService.invalidateFeedCache();

      res.status(200).json({ message: "Reaction updated", data: result });
    } catch (error) {
      next(error);
    }
  }

  async commentOnPost(req, res, next) {
    try {
      const { postId } = req.params;
      const userId = req.user.id;
      const { content, parentCommentId } = req.body;

      if (!content)
        return res.status(400).json({ error: "Comment content is required" });

      const comment = await postCreateService.addComment(
        postId,
        userId,
        content,
        parentCommentId,
      );
      await postCacheService.invalidatePost(postId);
      res.status(201).json({ message: "Comment added", data: comment });
    } catch (error) {
      next(error);
    }
  }

  async bookmarkPost(req, res, next) {
    try {
      const { postId } = req.params;
      const userId = req.user.id;
      const favorite = await postCreateService.addFavorite(postId, userId);
      await postCacheService.invalidatePost(postId);
      res.status(201).json({ message: "Post bookmarked", data: favorite });
    } catch (error) {
      if (error.code === "P2002")
        return res.status(409).json({ error: "Already bookmarked" });
      next(error);
    }
  }

  async updatePost(req, res, next) {
    try {
      const { postId } = req.params;
      const userId = req.user.id;
      const updateData = req.body;
      const updatedPost = await postCreateService.updatePost(
        postId,
        userId,
        updateData,
      );

      await postCacheService.invalidatePost(postId);
      await postCacheService.invalidateFeedCache();

      res.json({ message: "Post updated successfully", data: updatedPost });
    } catch (error) {
      next(error);
    }
  }

  async deletePost(req, res, next) {
    try {
      const { postId } = req.params;
      const userId = req.user.id;
      await postCreateService.deletePostWithMedia(postId, userId);
      await postCacheService.invalidatePost(postId);
      await postCacheService.invalidateFeedCache();
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  }

  async restorePost(req, res, next) {
    try {
      const { postId } = req.params;
      const userId = req.user.id;
      const post = await postCreateService.restorePost(postId, userId);
      await postCacheService.cachePost(postId, post);
      await postCacheService.invalidateFeedCache();
      res.json({ message: "Post restored successfully", data: post });
    } catch (error) {
      next(error);
    }
  }

  async clearCache(req, res, next) {
    try {
      if (process.env.NODE_ENV === "production") {
        return res.status(403).json({ error: "Not allowed in production" });
      }
      await postCacheService.clearAllCache();
      res.json({ message: "Cache cleared successfully" });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new PostController();
