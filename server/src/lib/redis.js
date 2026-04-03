const { createClient } = require('redis');
const logger = require('../utils/logger');

class RedisClient {
  constructor() {
    this.client = null;
    this.isConnected = false;
  }

  async connect() {
    try {
      this.client = createClient({
        url: process.env.REDIS_URL || 'redis://localhost:6379',
        socket: {
          reconnectStrategy: (retries) => {
            if (retries > 10) {
              logger.error('❌ Too many Redis retries');
              return new Error('Too many retries');
            }
            return Math.min(retries * 100, 3000);
          },
        },
      });

      this.client.on('error', (err) => {
        logger.error('Redis Error:', err);
        this.isConnected = false;
      });

      this.client.on('connect', () => {
        logger.info('✅ Redis connected');
        this.isConnected = true;
      });

      this.client.on('end', () => {
        logger.warn('📴 Redis disconnected');
        this.isConnected = false;
      });

      await this.client.connect();
    } catch (error) {
      logger.error('❌ Redis connection failed:', error.message);
      this.isConnected = false;
    }
  }

  // ✅ Safe get (from main branch idea)
  async get(key) {
    if (!this.isConnected) return null;
    try {
      const value = await this.client.get(key);
      return value ? JSON.parse(value) : null;
    } catch (error) {
      logger.error('Redis GET error:', error.message);
      return null;
    }
  }

  async set(key, value, ttlSeconds = 3600) {
    if (!this.isConnected) return false;
    try {
      await this.client.setEx(key, ttlSeconds, JSON.stringify(value));
      return true;
    } catch (error) {
      logger.error('Redis SET error:', error.message);
      return false;
    }
  }

  async del(key) {
    if (!this.isConnected) return false;
    try {
      await this.client.del(key);
      return true;
    } catch (error) {
      logger.error('Redis DEL error:', error.message);
      return false;
    }
  }

  async flushAll() {
    if (!this.isConnected) return false;
    try {
      await this.client.flushAll();
      logger.info('🧹 Redis cache cleared');
      return true;
    } catch (error) {
      logger.error('Redis FLUSH error:', error.message);
      return false;
    }
  }

  async disconnect() {
    if (this.client && this.isConnected) {
      await this.client.quit();
      logger.info('👋 Redis disconnected');
    }
  }
}

// Singleton
const redisClient = new RedisClient();

// Auto-connect
if (process.env.NODE_ENV !== 'test') {
  redisClient.connect().catch(() => {
    logger.error('Redis init failed — continuing without cache');
  });
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  await redisClient.disconnect();
  process.exit(0);
});

process.on('SIGINT', async () => {
  await redisClient.disconnect();
  process.exit(0);
});

module.exports = redisClient;