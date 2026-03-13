require('./config/env');

const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

const { isProduction } = require('./config/env');
const redisClient = require('./config/redis');
const authRoutes = require('./modules/auth/auth.routes');
const userRoutes = require('./modules/userManagement/user.route');
const errorHandler = require('./middlewares/errorhHandler');

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
app.use('/api/users', userRoutes);
app.use(errorHandler);

redisClient.on('connect', () => {
  console.log('Redis connected');
});

redisClient.on('error', (err) => {
  console.error('Redis error:', err.message);
});

redisClient.connect().catch((err) => {
  console.error('Redis connection failed:', err.message);
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
