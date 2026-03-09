const Redis = require('ioredis');

const redisClient = new Redis(process.env.REDIS_URL || 'redis://127.0.0.1:6379', {
  maxRetriesPerRequest: 1,
  enableOfflineQueue: false,
  lazyConnect: true,
  retryStrategy: () => null,
});

redisClient.on('error', (err) => {
  console.error('Redis Client Error:', err.message);
});

module.exports = redisClient;
