require('../config/env');

const { PrismaClient } = require('../../Database/node_modules/@prisma/client');
const { PrismaPg } = require('../../Database/node_modules/@prisma/adapter-pg');
const { Pool } = require('../../Database/node_modules/pg');
const { isProduction } = require('../config/env');

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error('DATABASE_URL is not set. Prisma client cannot be initialized.');
}

const adapter = new PrismaPg(
  new Pool({
    connectionString,
  })
);

const prisma = new PrismaClient({
  adapter,
  log: isProduction ? ['error'] : ['query', 'info', 'warn', 'error'],
});

module.exports = prisma;
module.exports.prisma = prisma;
