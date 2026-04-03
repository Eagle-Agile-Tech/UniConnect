// src/lib/redis.js
const redis = require("redis");

class RedisClient {
  constructor() {
    this.client = null;
    this.isConnected = false;
  }

  /**
   * Connect to Redis
   */
  async connect() {
    try {
      this.client = redis.createClient({
        url: process.env.REDIS_URL || "redis://localhost:6379",
        socket: {
          reconnectStrategy: (retries) => {
            if (retries > 10) {
              console.log("❌ Too many Redis connection attempts");
              return new Error("Too many retries");
            }
            return Math.min(retries * 100, 3000);
          },
        },
      });

      // Event handlers
      this.client.on("error", (err) => {
        console.error("❌ Redis Error:", err.message);
        this.isConnected = false;
      });

      this.client.on("connect", () => {
        console.log("✅ Redis connected successfully");
        this.isConnected = true;
      });

      this.client.on("end", () => {
        console.log("📴 Redis connection closed");
        this.isConnected = false;
      });

      await this.client.connect();
    } catch (error) {
      console.error("❌ Failed to connect to Redis:", error.message);
      this.isConnected = false;
    }
  }

  /**
   * Get value from cache
   */
  async get(key) {
    if (!this.isConnected) return null;
    try {
      const value = await this.client.get(key);
      return value ? JSON.parse(value) : null;
    } catch (error) {
      console.error("❌ Redis get error:", error.message);
      return null;
    }
  }

  /**
   * Set value in cache with expiration
   */
  async set(key, value, ttlSeconds = 3600) {
    if (!this.isConnected) return false;
    try {
      await this.client.setEx(key, ttlSeconds, JSON.stringify(value));
      return true;
    } catch (error) {
      console.error("❌ Redis set error:", error.message);
      return false;
    }
  }

  /**
   * Delete key from cache
   */
  async del(key) {
    if (!this.isConnected) return false;
    try {
      await this.client.del(key);
      return true;
    } catch (error) {
      console.error("❌ Redis del error:", error.message);
      return false;
    }
  }

  /**
   * Clear all cache (use carefully!)
   */
  async flushAll() {
    if (!this.isConnected) return false;
    try {
      await this.client.flushAll();
      console.log("🧹 Redis cache cleared");
      return true;
    } catch (error) {
      console.error("❌ Redis flush error:", error.message);
      return false;
    }
  }

  /**
   * Get cache stats
   */
  async getStats() {
    if (!this.isConnected) return null;
    try {
      const info = await this.client.info();
      return {
        connected: this.isConnected,
        memory: info.match(/used_memory_human:(.*)/)?.[1]?.trim(),
        uptime: info.match(/uptime_in_seconds:(.*)/)?.[1]?.trim(),
        total_connections: info
          .match(/total_connections_received:(.*)/)?.[1]
          ?.trim(),
      };
    } catch (error) {
      return { connected: this.isConnected };
    }
  }

  /**
   * Gracefully disconnect
   */
  async disconnect() {
    if (this.client && this.isConnected) {
      await this.client.quit();
      console.log("👋 Redis disconnected");
    }
  }
}

// Export a single instance (singleton)
const redisClient = new RedisClient();

// Auto-connect in development
if (process.env.NODE_ENV !== "test") {
  redisClient.connect().catch(console.error);
}

// Handle graceful shutdown
process.on("SIGTERM", async () => {
  await redisClient.disconnect();
  process.exit(0);
});

process.on("SIGINT", async () => {
  await redisClient.disconnect();
  process.exit(0);
});

module.exports = redisClient;
