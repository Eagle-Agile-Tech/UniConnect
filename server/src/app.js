require('./config/env');

const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const http = require('http');
const initSocket = require('./Sockets/socket');


const { isProduction } = require('./config/env');
const redisClient = require('./config/redis');
const userRoutes = require('./modules/userManagement/user.route');
const authRoutes = require('./modules/auth/auth.routes');
const adminRoutes = require('./modules/admin/admin.route');
const institutionRoutes = require('./modules/institution/institution.route');
const expertRoutes = require('./modules/expert/expert.route');
const chatRoutes = require('./modules/chat/chat.route');
const errorHandler = require('./middlewares/errorhHandler');
const initAdmin = require('./config/initAdmin');

const app = express();

const server = http.createServer(app);
initSocket(server);

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan(isProduction ? 'combined' : 'dev'));

app.use(
  cors({
    origin: ['http://localhost:3000', 'http://localhost:5173'],
    credentials: true,
  })
);

app.get('/', (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'UniConnect API is running',
  });
});

app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/users', userRoutes);
app.use('/api/institutions', institutionRoutes);
app.use('/api/experts', expertRoutes);
app.use('/api/chats', chatRoutes);

app.use(errorHandler);

const PORT = process.env.PORT || 5000;

async function startServer() {
  try {

    await redisClient.connect();
    console.log('Redis connected');

    await initAdmin();

    server.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });

  } catch (err) {
    console.error('Startup failed:', err.message);
    process.exit(1);
  }
}

startServer();
