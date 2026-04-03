// server/src/modules/engagement/services/bookmark.service.js
const prisma = require("../../../lib/prisma");
const bookmarkRepository = require("../repositories/bookmark.repository");
const engagementCache = require("./engagement-cache.service");

class BookmarkService {
  /**
   * Toggle bookmark on a post
   */
  async toggleBookmark(userId, postId) {
    return await prisma.$transaction(async (tx) => {
      // Check if post exists
      const post = await tx.post.findUnique({
        where: { id: postId, isDeleted: false },
        select: { id: true },
      });

      if (!post) {
        throw new Error("Post not found");
      }

      // Check if already bookmarked
      const existingBookmark = await bookmarkRepository.findBookmark(
        userId,
        postId,
      );

      let result;
      if (existingBookmark) {
        // Remove bookmark
        await bookmarkRepository.deleteBookmark(existingBookmark.id);
        result = { bookmarked: false, action: "removed" };
      } else {
        // Add bookmark
        const bookmark = await bookmarkRepository.createBookmark(
          userId,
          postId,
        );
        result = { bookmarked: true, action: "added", bookmark };
      }

      // Get updated bookmark count
      const bookmarkCount = await bookmarkRepository.countUserBookmarks(userId);

      // Invalidate cache
      await engagementCache.invalidateUserBookmarks(userId);

      return {
        ...result,
        bookmarkCount,
      };
    });
  }

  /**
   * Get user's bookmarked posts
   */
  async getUserBookmarks(userId, cursor, limit = 10) {
    // Try cache first
    const cacheKey = `user:bookmarks:${userId}:${cursor || "start"}`;
    const cached = await engagementCache.get(cacheKey);

    if (cached) {
      return cached;
    }

    const result = await bookmarkRepository.getUserBookmarks(
      userId,
      cursor,
      limit,
    );

    // Cache for 5 minutes
    await engagementCache.set(cacheKey, result, 300);

    return result;
  }

  /**
   * Remove a specific bookmark
   */
  async removeBookmark(userId, postId) {
    const bookmark = await bookmarkRepository.findBookmark(userId, postId);

    if (!bookmark) {
      throw new Error("Bookmark not found");
    }

    await bookmarkRepository.deleteBookmark(bookmark.id);

    // Invalidate cache
    await engagementCache.invalidateUserBookmarks(userId);

    return { success: true };
  }

  /**
   * Check if post is bookmarked by user
   */
  async isBookmarked(userId, postId) {
    return bookmarkRepository.isBookmarked(userId, postId);
  }

  /**
   * Get bookmark status for multiple posts (for feed)
   */
  async getBulkBookmarkStatus(userId, postIds) {
    if (!userId || !postIds.length) return {};
    return bookmarkRepository.getBulkBookmarkStatus(userId, postIds);
  }
}

module.exports = new BookmarkService();
