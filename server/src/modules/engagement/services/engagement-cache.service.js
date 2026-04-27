// server/src/modules/engagement/services/engagement-cache.service.js
const redis = require("../../../lib/redis");
const cacheKeys = require("../../../utils/cacheKeys");

class EngagementCacheService {
  /**
   * Get cached data
   */
  async get(key) {
    try {
      return await redis.get(key);
    } catch (error) {
      console.error("Redis get error:", error);
      return null;
    }
  }

  /**
   * Set cached data
   */
  async set(key, value, ttl = 300) {
    try {
      await redis.set(key, value, ttl);
    } catch (error) {
      console.error("Redis set error:", error);
    }
  }

  /**
   * Delete cached data
   */
  async del(key) {
    try {
      await redis.del(key);
    } catch (error) {
      console.error("Redis del error:", error);
    }
  }

  /**
   * Invalidate all caches related to a post's likes
   */
  async invalidatePostLikes(postId) {
    const pattern = `post:likes:${postId}:*`;
    await this.invalidatePattern(pattern);
  }

  /**
   * Invalidate all caches related to a post's comments
   */
  async invalidatePostComments(postId) {
    const pattern = `post:comments:${postId}:*`;
    await this.invalidatePattern(pattern);
  }

  /**
   * Invalidate all caches related to a user's bookmarks
   */
  async invalidateUserBookmarks(userId) {
    const pattern = `user:bookmarks:${userId}:*`;
    await this.invalidatePattern(pattern);
  }

  /**
   * Invalidate all keys matching a pattern
   */
  async invalidatePattern(pattern) {
    try {
      if (!redis?.isConnected || !redis?.client) {
        return;
      }

      const keys = [];
      for await (const key of redis.client.scanIterator({
        MATCH: pattern,
        COUNT: 100,
      })) {
        keys.push(key);
      }

      if (keys.length > 0) {
        await redis.client.del(keys);
      }
    } catch (error) {
      console.error("Redis pattern invalidation error:", error);
    }
  }
 

  /**
   * Invalidate all caches related to a comment's reactions
   */
  async invalidateCommentReactions(commentId) {
    const patterns = [
      `comment:reactions:${commentId}:*`,
      `replies:paginated:*`,
    ];

    for (const pattern of patterns) {
      await this.invalidatePattern(pattern);
    }
  }

  /**
   * Invalidate all comment pagination caches for a post
   */
  async invalidatePostCommentPagination(postId) {
    const pattern = `comments:paginated:${postId}:*`;
    await this.invalidatePattern(pattern);
  }
}

module.exports = new EngagementCacheService();
