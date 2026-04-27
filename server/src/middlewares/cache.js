// src/middlewares/cache.js
const redisClient = require("../lib/redis");
const cacheKeys = require("../utils/cacheKeys");

/**
 * Cache middleware for GET requests
 * @param {number} ttlSeconds - Time to live in seconds
 * @param {Function} keyGenerator - Function to generate cache key from request
 */
const cache = (ttlSeconds = 300, keyGenerator) => {
  return async (req, res, next) => {
    // Skip caching for non-GET requests
    if (req.method !== "GET") {
      return next();
    }

    // Generate cache key
    const key = keyGenerator ? keyGenerator(req) : `${req.originalUrl}`;

    try {
      // Try to get from cache
      const cachedData = await redisClient.get(key);

      if (cachedData) {
        console.log(`📦 Cache hit: ${key}`);
        return res.json(cachedData);
      }

      // If not in cache, store the original res.json function
      const originalJson = res.json;

      // Override res.json to cache the response
      res.json = function (data) {
        // Store in cache
        redisClient.set(key, data, ttlSeconds).catch(console.error);
        console.log(`💾 Cache set: ${key} (TTL: ${ttlSeconds}s)`);

        // Call original json
        return originalJson.call(this, data);
      };

      next();
    } catch (error) {
      console.error("❌ Cache middleware error:", error.message);
      next(); // Continue even if cache fails
    }
  };
};

/**
 * Clear cache for specific patterns
 */
const clearCache = (patterns) => {
  return async (req, res, next) => {
    // Store original send function
    const originalSend = res.send;

    // Override send to clear cache after successful response
    res.send = async function (data) {
      // Only clear cache on success (2xx status)
      if (res.statusCode >= 200 && res.statusCode < 300) {
        try {
          for (const pattern of patterns) {
            // You'll need to implement this based on your Redis version
            // For Redis 6+, you can use SCAN
            console.log(`🧹 Clearing cache pattern: ${pattern}`);
          }
        } catch (error) {
          console.error("❌ Cache clear error:", error.message);
        }
      }

      return originalSend.call(this, data);
    };

    next();
  };
};

module.exports = { cache, clearCache };
