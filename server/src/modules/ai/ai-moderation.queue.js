// server/src/modules/ai/ai-moderation.queue.js
const { Queue, Worker } = require("bullmq");
const IORedis = require("ioredis");

// Make sure maxRetriesPerRequest is null
const connection = new IORedis({
  host: process.env.REDIS_HOST || "127.0.0.1",
  port: process.env.REDIS_PORT || 6379,
  password: process.env.REDIS_PASSWORD || undefined,
  maxRetriesPerRequest: null, // ✅ critical fix
});

const moderationQueue = new Queue("ai-moderation", { connection });

const worker = new Worker(
  "ai-moderation",
  async (job) => {
    // handle moderation job here
    console.log("Processing moderation job", job.data);
  },
  { connection },
);

module.exports = { moderationQueue, worker };
