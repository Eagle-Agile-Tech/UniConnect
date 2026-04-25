const prisma = require("../../../lib/prisma");
const postFeedService = require("./post-feed.service");
const aiModerationService = require("../../ai/ai-moderation.service");
const { verifyMediaOwnership } = require("../utils/post.helpers");

// ✅ USE YOUR EXISTING MEDIA SERVICE
const storageService = require("../../media/services/supabase-storage.service");

class PostCreateService {
  async createPost(userId, data, files = []) {
    const { content, tags, mediaIds = [] } = data;

    // =========================
    // VALIDATION
    // =========================
    if (!content && files.length === 0 && mediaIds.length === 0) {
      throw new Error("Post must have content or media");
    }
    // =========================
// AI MODERATION (NEW)
// =========================
const moderationResult = await aiModerationService.moderatePost({
  content,
  tags,
});

// REJECT → STOP EVERYTHING
if (moderationResult.moderationStatus === "REJECTED") {
  return {
    success: false,
    status: "REJECTED",
    message: "Post rejected by content moderation",
    details: moderationResult.details,
  };
}

// SAFETY CHECK (if API fails or returns unknown)
if (moderationResult.moderationStatus !== "APPROVED") {
  return {
    success: false,
    status: "PENDING",
    message: "Post could not be verified right now",
    details: moderationResult.details,
  };
}

    // =========================
    // UPLOAD MEDIA VIA MEDIA MODULE
    // =========================
    let uploadedMedia = [];
    let verifiedMedia = [];

    if (mediaIds.length > 0) {
      verifiedMedia = await verifyMediaOwnership(prisma, userId, mediaIds);
    }

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
              ...(verifiedMedia.length
                ? {
                    connect: verifiedMedia.map((media) => ({ id: media.id })),
                  }
                : {}),
            }
          : verifiedMedia.length
            ? {
                connect: verifiedMedia.map((media) => ({ id: media.id })),
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
