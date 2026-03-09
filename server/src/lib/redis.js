const { createClient } = require('redis');
const logger = require('../utils/logger');

const redis = createClient({
  url: process.env.REDIS_URL || 'redis://localhost:6379',
});

redis.on('error', (err) => logger.error('Redis Client Error', err));
redis.on('connect', () => logger.info('Redis connected'));

(async () => {
  try {
    await redis.connect();
  } catch (err) {
    logger.error('Initial Redis connection failed – continuing without cache', err);
  }
})();

// Safe get — never crash the request
async function safeGet(key) {
  try {
    const data = await redis.get(key);
    return data ? JSON.parse(data) : null;
  } catch {
    return null;
  }
}

module.exports = { redis, safeGet };