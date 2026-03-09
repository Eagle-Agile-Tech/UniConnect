const path = require('path');
const dotenv = require('dotenv');

dotenv.config({ quiet: true });
dotenv.config({ path: path.resolve(__dirname, '../../Database/.env'), quiet: true });

const nodeEnv = process.env.NODE_ENV || 'development';
const isProduction = nodeEnv === 'production';
const isDevelopment = !isProduction;

module.exports = {
  nodeEnv,
  isProduction,
  isDevelopment,
};
