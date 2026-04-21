import prisma from "../../../lib/prisma.js";
import supabaseStorage from "../../media/services/supabase-storage.service.js";
import aiModerationService from "../../ai/ai-moderation.service.js";
import notificationService from "../../notification/notification.service.js";

class PostCreateService {
  /**
   * Format post response (STANDARDIZED)
   */
  formatPost(post, currentUserId) {
    return {
      id: post.id,
      content: post.content,
      authorId: post.authorId,
      authorProfilePicture: post.author?.profile?.profileImage || null,
      authorName: `${post.author?.firstName || ""} ${post.author?.lastName || ""}`.trim(),
      mediaUrls: post.media?.map((m) => m.fileUrl) || [],
      createdAt: post.createdAt,
      tags: post.tags || [],
      likeCount: post._count?.postReactions || 0,
      commentCount: post._count?.comments || 0,
      isLikedByMe: post.postReactions?.some(
        (r) => r.userId === currentUserId
      ) || false,
      isBookmarkedByMe: post.favorites?.some(
        (f) => f.userId === currentUserId
      ) || false,
    };
  }

  /**
   * CREATE POST (TOKEN BASED USER)
   * endpoint: /posts/createPost
   */
  async createPost(userId, data, files = []) {
    const { content, tags, createdAt } = data;

    if (!content && files.length === 0) {
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
      const createdPost = await tx.post.create({
        data: {
          authorId: userId,
          content,
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

    if (initialModerationStatus === "APPROVED") {
      await this.notifyNetworkedUsers(userId, post);
    }

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

  async notifyNetworkedUsers(userId, post) {
    const connections = await prisma.network.findMany({
      where: {
        status: "CONNECTED",
        OR: [{ userAId: userId }, { userBId: userId }],
      },
      select: { userAId: true, userBId: true },
    });

    const recipientIds = [...new Set(
      connections
        .map((connection) =>
          connection.userAId === userId ? connection.userBId : connection.userAId,
        )
        .filter(Boolean),
    )];

    if (recipientIds.length === 0) {
      return;
    }

    const title = `${post.author?.profile?.username || post.author?.firstName || 'Someone'} posted a new update`;
    const body = post.content
      ? post.content.slice(0, 120)
      : 'A network connection shared a new post.';

    await Promise.all(
      recipientIds.map((recipientId) =>
        notificationService.createAndSendNotification({
          recipientId,
          actorId: userId,
          type: 'SYSTEM',
          referenceId: post.id,
          referenceType: 'POST',
          title,
          body,
          data: {
            postId: post.id,
            authorId: userId,
          },
          io: null,
          onlineUsers: null,
        }),
      ),
    );
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

      // Upload media
      if (files.length > 0) {
        const uploadedFiles = await supabaseStorage.uploadMultipleFiles(
          files,
          userId
        );

        for (const file of uploadedFiles) {
          await tx.media.create({
            data: {
              uploaderId: userId,
              postId: createdPost.id,
              fileUrl: file.url,
              fileType: "IMAGE",
            },
          });
        }
      }

      const completePost = await tx.post.findUnique({
        where: { id: createdPost.id },
        include: {
          media: true,
          author: {
            include: { profile: true },
          },
          postReactions: true,
          favorites: true,
          _count: {
            select: { comments: true, postReactions: true },
          },
        },
      });

      return completePost;
    });

    if (initialModerationStatus === "APPROVED") {
      await this.notifyNetworkedUsers(userId, post);
    }

    // 🔥 AI MODERATION (unchanged logic)
    if (shouldModerate) {
      moderationResult = await aiModerationService.enqueuePostModeration({
        postId: post.id,
        userId,
        content: content || "",
        tags: tags || [],
      });

      // ❗ HANDLE REJECTED CASE
      if (moderationResult.moderationStatus === "REJECTED") {
        await prisma.post.update({
          where: { id: post.id },
          data: {
            isDeleted: true,
            moderationStatus: "REJECTED",
          },
        });

        return {
          message: "Post rejected due to content policy",
          rejected: true,
        };
      }

      const refreshedPost = await prisma.post.findUnique({
        where: { id: post.id },
        include: {
          media: true,
          author: { include: { profile: true } },
          postReactions: true,
          favorites: true,
          _count: {
            select: { comments: true, postReactions: true },
          },
        },
      });

      return {
        post: this.formatPost(refreshedPost, userId),
        moderationResult,
      };
    }

    return {
      post: this.formatPost(post, userId),
      moderationResult,
    };
  }

  /**
   * GET SINGLE POST
   */
  async getSinglePost(postId, currentUserId) {
    const post = await prisma.post.findFirst({
      where: {
        id: postId,
        isDeleted: false,
        moderationStatus: "APPROVED",
      },
      include: {
        media: true,
        author: { include: { profile: true } },
        postReactions: true,
        favorites: true,
        _count: {
          select: { comments: true, postReactions: true },
        },
      },
    });

    if (!post) throw new Error("Post not found");

    return this.formatPost(post, currentUserId);
  }

  /**
   * FEED (PAGINATION)
   */
  async getFeed(currentUserId, page = 1, limit = 10) {
    const posts = await prisma.post.findMany({
      where: {
        isDeleted: false,
        moderationStatus: "APPROVED",
      },
      orderBy: { createdAt: "desc" },
      skip: (page - 1) * limit,
      take: limit,
      include: {
        media: true,
        author: { include: { profile: true } },
        postReactions: true,
        favorites: true,
        _count: {
          select: { comments: true, postReactions: true },
        },
      },
    });

    return posts.map((p) => this.formatPost(p, currentUserId));
  }

  /**
   * GET USER POSTS
   * endpoint: /posts/fetch/:userId
   */
  async getUserPosts(targetUserId, currentUserId, page = 1, limit = 10) {
    const isOwner = targetUserId === currentUserId;

    const posts = await prisma.post.findMany({
      where: {
        authorId: targetUserId,
        ...(isOwner
          ? {}
          : {
              isDeleted: false,
              moderationStatus: "APPROVED",
            }),
      },
      orderBy: { createdAt: "desc" },
      skip: (page - 1) * limit,
      take: limit,
      include: {
        media: true,
        author: { include: { profile: true } },
        postReactions: true,
        favorites: true,
        _count: {
          select: { comments: true, postReactions: true },
        },
      },
    });

    return posts.map((p) => this.formatPost(p, currentUserId));
  }

  /**
   * DELETE (SOFT)
   */
  async deletePostWithMedia(postId, userId) {
    return await prisma.$transaction(async (tx) => {
      const post = await tx.post.findFirst({
        where: { id: postId, authorId: userId, isDeleted: false },
        include: { media: true },
      });

      if (!post) throw new Error("Post not found or no permission");

      const deletedPost = await tx.post.update({
        where: { id: postId },
        data: { isDeleted: true },
      });

      for (const media of post.media) {
        try {
          const filePath = supabaseStorage.extractFilePathFromUrl(
            media.fileUrl
          );
          if (filePath) await supabaseStorage.deleteFile(filePath);
        } catch (err) {
          console.error("Media delete failed:", err);
        }
      }

      return deletedPost;
    });
  }
}

export default new PostCreateService();