// ENV setup (keep ONE approach)
require('./config/env');

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const http = require('http');

const initSocket = require('./Sockets/socket');
const { isProduction } = require('./config/env');
const redisClient = require('./config/redis');
const prisma = require('./lib/prisma');

// Background jobs
require('./modules/ai/ai-moderation.queue');

// Routes
const postRoutes = require('./modules/post/post.routes');
const engagementRoutes = require('./modules/engagement/engagement.routes');
const userRoutes = require('./modules/userManagement/user.route');
const authRoutes = require('./modules/auth/auth.routes');
const adminRoutes = require('./modules/admin/admin.route');
const institutionRoutes = require('./modules/institution/institution.route');
const expertRoutes = require('./modules/expert/expert.route');
const chatRoutes = require('./modules/chat/chat.route');
const eventRoutes = require('./modules/event/event.route');
const communityRoutes = require('./modules/community/community.route');

const recommendationRoutes = require('./modules/ai-recommendation-service/recommendation.route');
const errorHandler = require('./middlewares/errorhHandler');
const initAdmin = require('./config/initAdmin');
const courseRoutes = require('./modules/course/course.routes');
const savedCourseRoutes = require('./modules/course/savedCourse.routes');
const paymentRoutes = require('./modules/payment/payment.routes');
const networkRoutes = require('./modules/network/network.routes');
const notificationRoutes = require('./modules/notification/notification.route');
const trainingDatasetRoutes = require('./modules/ai-recommendation-service/training-dataset.route');

const app = express();
const server = http.createServer(app);

// Init socket
initSocket(server);

// Middleware
app.use(helmet());
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));
app.use(morgan(isProduction ? 'combined' : 'dev'));

app.use(
  cors({
    origin(origin, callback) {
      const allowedOrigins = new Set([
        'http://localhost:3000',
        'http://localhost:5173',
        'http://localhost:5175',
      ]);

      const isLocalhostDevOrigin = typeof origin === 'string'
        && /^http:\/\/localhost:\d+$/.test(origin);

      if (!origin || allowedOrigins.has(origin) || isLocalhostDevOrigin) {
        return callback(null, true);
      }

      return callback(new Error(`CORS blocked for origin: ${origin}`));
    },
    credentials: true,
  })
);

// Health / base route
app.get('/', (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'API running',
  });
});

// Routes (combine both systems)
app.use('/api/v1/posts', postRoutes);
app.use('/api/v1', engagementRoutes);

app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/users', userRoutes);
app.use('/api/institutions', institutionRoutes);
app.use('/api/experts', expertRoutes);
app.use('/api/chats', chatRoutes);
app.use('/api/events', eventRoutes);
app.use('/api/communities', communityRoutes);
app.use('/api/courses', courseRoutes);
app.use('/api/saved-courses', savedCourseRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/network', networkRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/v1/recommendations', recommendationRoutes);
app.use('/api/admin/recommendations', trainingDatasetRoutes);

// Error handler
app.use(errorHandler);

const PORT = process.env.PORT || 5000;

async function startServer() {
  try {
    await redisClient.connect();
    console.log('Redis connected');

    await initAdmin();

    server.listen(PORT, () => {
      console.log(`🚀 Server running on port ${PORT}`);
    });

  } catch (err) {
    console.error('Startup failed:', err.message);
    process.exit(1);
  }
}

if (require.main === module) {
  startServer();
}

// Graceful shutdown (from your branch)
process.on("SIGTERM", async () => {
  await prisma.$disconnect();
  process.exit(0);
});

process.on("SIGINT", async () => {
  await prisma.$disconnect();
  process.exit(0);
});

module.exports = {
  app,
  server,
  startServer,
};
