const prisma = require("../../../lib/prisma");
const postFeedService = require("./post-feed.service");

// ✅ USE YOUR EXISTING MEDIA SERVICE
const storageService = require("../../media/services/supabase-storage.service");

class PostCreateService {
  async createPost(userId, data, files = []) {
    const { content, tags } = data;

    // =========================
    // VALIDATION
    // =========================
    if (!content && files.length === 0) {
      throw new Error("Post must have content or media");
    }

    // =========================
    // UPLOAD MEDIA VIA MEDIA MODULE
    // =========================
    let uploadedMedia = [];

    if (files.length > 0) {
      const results = await storageService.uploadMultipleFiles(files, userId);

      uploadedMedia = results.map((file) => ({
        uploaderId: userId,
        fileUrl: file.url,
        fileType: file.mimetype.startsWith("image") ? "IMAGE" : "DOCUMENT",
      }));
    }

    // =========================
    // CREATE POST
    // =========================
    const post = await prisma.post.create({
      data: {
        authorId: userId,
        content: content || "",
        tags: tags || [],
        moderationStatus: "APPROVED",

        media: uploadedMedia.length
          ? {
              create: uploadedMedia,
            }
          : undefined,
      },

      include: postFeedService.getPostInclude(userId),
    });

    return {
      post,
      moderationResult: {
        status: "APPROVED",
      },
    };
  }
}

module.exports = new PostCreateService();
