const pino = require('pino');
const { isDevelopment, isProduction } = require('../config/env');

const prettyEnabled = isDevelopment && (() => {
  try {
    require.resolve('pino-pretty');
    return true;
  } catch {
    return false;
  }
})();

const logger = pino({
  level: isProduction ? 'info' : 'debug',
  ...(prettyEnabled
    ? {
        transport: {
          target: 'pino-pretty',
          options: {
            colorize: true,
            translateTime: 'SYS:standard',
          },
        },
      }
    : {}),
});

module.exports = logger;
