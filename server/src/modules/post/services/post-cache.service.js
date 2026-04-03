// src/modules/post/services/post-cache.service.js
const redisClient = require("../../../lib/redis");

class PostCacheService {
  /**
   * Cache a single post
   * @param {string} postId - Post ID
   * @param {object} postData - Post data to cache
   * @param {number} ttl - Time to live in seconds (default: 1 hour)
   */
  async cachePost(postId, postData, ttl = 3600) {
    try {
      const key = `post:${postId}`;
      await redisClient.set(key, postData, ttl);
      console.log(`💾 Cached post: ${key} (TTL: ${ttl}s)`);
      return true;
    } catch (error) {
      console.error("❌ Error caching post:", error.message);
      return false;
    }
  }

  /**
   * Get cached post
   * @param {string} postId - Post ID
   * @returns {object|null} Cached post or null
   */
  async getCachedPost(postId) {
    try {
      const key = `post:${postId}`;
      const cached = await redisClient.get(key);

      if (cached) {
        console.log(`📦 Cache hit: ${key}`);
        return cached;
      }

      console.log(`❌ Cache miss: ${key}`);
      return null;
    } catch (error) {
      console.error("❌ Error getting cached post:", error.message);
      return null;
    }
  }

  /**
   * Cache a feed/list of posts
   * @param {string} cacheKey - Cache key for the feed
   * @param {object} feedData - Feed data to cache
   * @param {number} ttl - Time to live in seconds (default: 5 minutes)
   */
  async cacheFeed(cacheKey, feedData, ttl = 300) {
    try {
      await redisClient.set(cacheKey, feedData, ttl);
      console.log(`💾 Cached feed: ${cacheKey} (TTL: ${ttl}s)`);
      return true;
    } catch (error) {
      console.error("❌ Error caching feed:", error.message);
      return false;
    }
  }

  /**
   * Get cached feed
   * @param {string} cacheKey - Cache key for the feed
   * @returns {object|null} Cached feed or null
   */
  async getCachedFeed(cacheKey) {
    try {
      const cached = await redisClient.get(cacheKey);

      if (cached) {
        console.log(`📦 Cache hit: ${cacheKey}`);
        return cached;
      }

      console.log(`❌ Cache miss: ${cacheKey}`);
      return null;
    } catch (error) {
      console.error("❌ Error getting cached feed:", error.message);
      return null;
    }
  }

  /**
   * Invalidate a single post cache
   * @param {string} postId - Post ID
   */
  async invalidatePost(postId) {
    try {
      const key = `post:${postId}`;
      await redisClient.del(key);
      console.log(`🧹 Invalidated post cache: ${key}`);
      return true;
    } catch (error) {
      console.error("❌ Error invalidating post cache:", error.message);
      return false;
    }
  }

  /**
   * Invalidate all feed caches
   * When a new post is created/deleted, feeds become stale
   */
  async invalidateFeedCache() {
    try {
      // In a production app, you'd use SCAN to find all feed keys
      // For simplicity, we'll just increment a version counter
      const version = await redisClient.get("feed:version");
      await redisClient.set(
        "feed:version",
        (parseInt(version || "0") + 1).toString(),
      );
      console.log("🧹 Invalidated all feed caches (version bumped)");

      // Alternative: Delete all feed keys (use carefully!)
      // await redisClient.delByPattern('feed:*');

      return true;
    } catch (error) {
      console.error("❌ Error invalidating feed cache:", error.message);
      return false;
    }
  }

  /**
   * Clear all cache (use in development only)
   */
  async clearAllCache() {
    try {
      await redisClient.flushAll();
      console.log("🧹 Cleared all Redis cache");
      return true;
    } catch (error) {
      console.error("❌ Error clearing cache:", error.message);
      return false;
    }
  }

  /**
   * Get cache stats
   */
  async getCacheStats() {
    return await redisClient.getStats();
  }
}

module.exports = new PostCacheService();
