require('./config/env');

const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

const { isProduction } = require('./config/env');
const redisClient = require('./config/redis');
const userRoutes = require('./modules/userManagement/user.route');
const authRoutes = require('./modules/auth/auth.routes');
const adminRoutes = require('./modules/admin/admin.route');
const userRoutes = require('./modules/userManagement/user.route');
const errorHandler = require('./middlewares/errorhHandler');
const initAdmin = require('./config/initAdmin');

const app = express();

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

app.use(errorHandler);

const PORT = process.env.PORT || 5000;

async function startServer() {
  try {

    await redisClient.connect();
    console.log('Redis connected');

    await initAdmin();

    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });

  } catch (err) {
    console.error('Startup failed:', err.message);
    process.exit(1);
  }
}

startServer();
