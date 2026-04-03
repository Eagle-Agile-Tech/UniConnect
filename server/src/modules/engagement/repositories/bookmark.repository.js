// server/src/modules/engagement/repositories/bookmark.repository.js
const prisma = require("../../../lib/prisma");

class BookmarkRepository {
  /**
   * Create a bookmark
   */
  async createBookmark(userId, postId) {
    return prisma.favorite.create({
      data: {
        userId,
        postId,
      },
    });
  }

  /**
   * Find a bookmark
   */
  async findBookmark(userId, postId) {
    return prisma.favorite.findUnique({
      where: {
        userId_postId: {
          userId,
          postId,
        },
      },
    });
  }

  /**
   * Delete a bookmark
   */
  async deleteBookmark(id) {
    return prisma.favorite.delete({
      where: { id },
    });
  }

  /**
   * Get user's bookmarks with pagination
   */
  async getUserBookmarks(userId, cursor, limit = 10) {
    const bookmarks = await prisma.favorite.findMany({
      where: { userId },
      take: limit,
      skip: cursor ? 1 : 0,
      cursor: cursor ? { id: cursor } : undefined,
      orderBy: { createdAt: "desc" },
      include: {
        post: {
          include: {
            media: true,
            author: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                profile: {
                  select: {
                    username: true,
                    profileImage: true,
                  },
                },
              },
            },
            _count: {
              select: {
                comments: true,
                postReactions: true,
              },
            },
          },
        },
      },
    });

    // Filter out deleted posts
    const validBookmarks = bookmarks.filter(
      (b) => b.post !== null && !b.post.isDeleted,
    );

    return {
      data: validBookmarks.map((b) => ({
        ...b.post,
        bookmarkedAt: b.createdAt,
        bookmarkId: b.id,
      })),
      nextCursor:
        validBookmarks.length === limit
          ? validBookmarks[validBookmarks.length - 1].id
          : null,
    };
  }

  /**
   * Count user's bookmarks
   */
  async countUserBookmarks(userId) {
    return prisma.favorite.count({
      where: { userId },
    });
  }

  /**
   * Check if post is bookmarked by user
   */
  async isBookmarked(userId, postId) {
    const bookmark = await prisma.favorite.findUnique({
      where: {
        userId_postId: {
          userId,
          postId,
        },
      },
      select: { id: true },
    });
    return !!bookmark;
  }

  /**
   * Get bookmark status for multiple posts (batch)
   */
  async getBulkBookmarkStatus(userId, postIds) {
    const bookmarks = await prisma.favorite.findMany({
      where: {
        userId,
        postId: { in: postIds },
      },
      select: {
        postId: true,
      },
    });

    const bookmarkMap = {};
    bookmarks.forEach((b) => {
      bookmarkMap[b.postId] = true;
    });

    return bookmarkMap;
  }
}

module.exports = new BookmarkRepository();
