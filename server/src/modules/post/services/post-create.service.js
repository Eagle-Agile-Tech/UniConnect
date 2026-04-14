// server/src/modules/post/services/post-create.service.js
import prisma from "../../../lib/prisma.js";
import supabaseStorage from "../../media/services/supabase-storage.service.js";
import aiModerationService from "../../ai/ai-moderation.service.js";

class PostCreateService {
  /**
   * Create post with media IDs (OpenAPI compliant)
   */
  async createPost(userId, data) {
    const { content, visibility, tags, category, mediaIds, communityId } = data;

    if (!content && (!mediaIds || mediaIds.length === 0)) {
      throw new Error("Post must have either content or media");
    }

    const shouldModerate =
      (content && content.trim().length > 0) || (tags && tags.length > 0);

    const initialModerationStatus = shouldModerate ? "PENDING" : "APPROVED";

    let moderationResult = {
      moderationStatus: initialModerationStatus,
      queued: shouldModerate,
    };

    const post = await prisma.$transaction(async (tx) => {
      // Verify media ownership if mediaIds provided
      if (mediaIds && mediaIds.length > 0) {
        const media = await tx.media.findMany({
          where: {
            id: { in: mediaIds },
            uploaderId: userId,
          },
        });

        if (media.length !== mediaIds.length) {
          throw new Error(
            "Some media files don't exist or don't belong to you",
          );
        }

        const attachedMedia = await tx.media.findMany({
          where: {
            id: { in: mediaIds },
            postId: { not: null },
          },
        });

        if (attachedMedia.length > 0) {
          throw new Error(
            "Some media files are already attached to another post",
          );
        }
      }

      // Create post
      const createdPost = await tx.post.create({
        data: {
          authorId: userId,
          communityId: communityId || null,
          content,
          visibility: visibility || "PUBLIC",
          tags: tags || [],
          category,
          moderationStatus: initialModerationStatus,
        },
      });

      // Attach media
      if (mediaIds && mediaIds.length > 0) {
        await tx.media.updateMany({
          where: { id: { in: mediaIds } },
          data: { postId: createdPost.id },
        });
      }

      // Audit log
      await tx.auditLog.create({
        data: {
          userId,
          actionType: "CREATE",
          entityType: "Post",
          entityId: createdPost.id,
          metadata: {
            moderationStatus: initialModerationStatus,
            contentLength: content?.length || 0,
            mediaCount: mediaIds?.length || 0,
            moderationQueued: shouldModerate,
          },
        },
      });

      const completePost = await tx.post.findUnique({
        where: { id: createdPost.id },
        include: {
          media: { orderBy: { createdAt: "asc" } },
          author: {
            select: {
              id: true,
              email: true,
              role: true,
              firstName: true,
              lastName: true,
              profile: { select: { username: true, profileImage: true } },
            },
          },
          _count: { select: { comments: true } },
        },
      });

      return completePost;
    });

    // Perform moderation (synchronous)
    if (shouldModerate) {
      moderationResult = await aiModerationService.enqueuePostModeration({
        postId: post.id,
        userId,
        content: content || "",
        tags: tags || [],
      });

      const refreshedPost = await prisma.post.findUnique({
        where: { id: post.id },
        include: {
          media: { orderBy: { createdAt: "asc" } },
          author: {
            select: {
              id: true,
              email: true,
              role: true,
              firstName: true,
              lastName: true,
              profile: { select: { username: true, profileImage: true } },
            },
          },
          _count: { select: { comments: true } },
        },
      });

      return { post: refreshedPost || post, moderationResult };
    }

    return { post, moderationResult };
  }

  /**
   * Create post with direct file uploads (Flutter app)
   */
  async createPostFromFlutter(userId, postData, files = []) {
    const { content, hashtags, createdAt } = postData;

    if (!content && files.length === 0) {
      throw new Error("Post must have either content or media");
    }

    let tags = [];
    if (hashtags) {
      try {
        tags = JSON.parse(hashtags);
      } catch (e) {
        console.error("Error parsing hashtags:", e);
      }
    }

    const shouldModerate =
      (content && content.trim().length > 0) || tags.length > 0;

    const initialModerationStatus = shouldModerate ? "PENDING" : "APPROVED";

    let moderationResult = {
      moderationStatus: initialModerationStatus,
      queued: shouldModerate,
    };

    const post = await prisma.$transaction(async (tx) => {
      const createdPost = await tx.post.create({
        data: {
          authorId: userId,
          content,
          visibility: "PUBLIC",
          tags,
          moderationStatus: initialModerationStatus,
          createdAt: createdAt ? new Date(createdAt) : new Date(),
        },
      });

      if (files.length > 0) {
        const uploadedFiles = await supabaseStorage.uploadMultipleFiles(
          files,
          userId,
        );

        for (const uploadedFile of uploadedFiles) {
          await tx.media.create({
            data: {
              uploaderId: userId,
              postId: createdPost.id,
              fileUrl: uploadedFile.url,
              fileType: "IMAGE",
            },
          });
        }
      }

      await tx.auditLog.create({
        data: {
          userId,
          actionType: "CREATE",
          entityType: "Post",
          entityId: createdPost.id,
          metadata: {
            moderationStatus: initialModerationStatus,
            contentLength: content?.length || 0,
            mediaCount: files.length,
            source: "flutter",
            moderationQueued: shouldModerate,
          },
        },
      });

      const completePost = await tx.post.findUnique({
        where: { id: createdPost.id },
        include: {
          media: { orderBy: { createdAt: "asc" } },
          author: {
            select: {
              id: true,
              email: true,
              role: true,
              firstName: true,
              lastName: true,
              profile: { select: { username: true, profileImage: true } },
            },
          },
          _count: { select: { comments: true } },
        },
      });

      return completePost;
    });

    if (shouldModerate) {
      moderationResult = await aiModerationService.enqueuePostModeration({
        postId: post.id,
        userId,
        content: content || "",
        tags,
      });

      const refreshedPost = await prisma.post.findUnique({
        where: { id: post.id },
        include: {
          media: { orderBy: { createdAt: "asc" } },
          author: {
            select: {
              id: true,
              email: true,
              role: true,
              firstName: true,
              lastName: true,
              profile: { select: { username: true, profileImage: true } },
            },
          },
          _count: { select: { comments: true } },
        },
      });

      return { post: refreshedPost || post, moderationResult };
    }

    return { post, moderationResult };
  }

  /**
   * Delete post with media
   */
  async deletePostWithMedia(postId, userId) {
    return await prisma.$transaction(async (tx) => {
      const post = await tx.post.findFirst({
        where: { id: postId, authorId: userId, isDeleted: false },
        include: { media: true },
      });

      if (!post) throw new Error("Post not found or you don't have permission");

      const deletedPost = await tx.post.update({
        where: { id: postId },
        data: { isDeleted: true },
      });

      for (const media of post.media) {
        try {
          const filePath = supabaseStorage.extractFilePathFromUrl(
            media.fileUrl,
          );
          if (filePath) await supabaseStorage.deleteFile(filePath);
        } catch (error) {
          console.error(`Failed to delete media ${media.id}:`, error);
        }
      }

      return deletedPost;
    });
  }

  /**
   * Restore soft-deleted post
   */
  async restorePost(postId, userId) {
    const post = await prisma.post.updateMany({
      where: { id: postId, authorId: userId, isDeleted: true },
      data: { isDeleted: false },
    });

    if (post.count === 0) throw new Error("Post not found or already restored");

    return await prisma.post.findUnique({
      where: { id: postId },
      include: {
        media: true,
        author: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            profile: { select: { username: true, profileImage: true } },
          },
        },
      },
    });
  }
}

// NEW ESM
export default new PostCreateService();
