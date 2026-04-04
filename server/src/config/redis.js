const Redis = require('ioredis');

const isDocker = process.env.PRISMA_ENV === 'docker';
const defaultUrl = isDocker ? 'redis://redis:6379' : 'redis://127.0.0.1:6379';

const redisClient = new Redis(process.env.REDIS_URL || defaultUrl, {
  maxRetriesPerRequest: 1,
  enableOfflineQueue: false,
  lazyConnect: true,
  retryStrategy: () => null,
});

redisClient.on('error', (err) => {
  console.error('Redis Client Error:', err.message);
});

module.exports = redisClient;
