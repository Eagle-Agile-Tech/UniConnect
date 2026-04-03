// server/src/lib/prisma.js
const { PrismaClient } = require("@prisma/client");

// Create a singleton PrismaClient instance
// Prisma client here is generated in driver-adapter mode, so we must use adapter-pg.
let prisma;

function createPrismaClient() {
  const { Pool } = require("pg");
  const { PrismaPg } = require("@prisma/adapter-pg");
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const adapter = new PrismaPg(pool);
  return new PrismaClient({ adapter, log: ["error", "warn"] });
}

if (process.env.NODE_ENV === "production") {
  prisma = createPrismaClient();
} else {
  // In development, prevent multiple instances due to hot reload
  if (!global.prisma) {
    global.prisma = createPrismaClient();
  }
  prisma = global.prisma;
}

// Test the connection immediately
(async () => {
  try {
    await prisma.$connect();
    console.log("✅ Database connected successfully");
  } catch (error) {
    console.error("❌ Database connection failed:", error.message);
    console.error("Please check your DATABASE_URL in .env file");
    process.exit(1);
  }
})();

// Handle cleanup
process.on("SIGINT", async () => {
  await prisma.$disconnect();
  process.exit(0);
});

process.on("SIGTERM", async () => {
  await prisma.$disconnect();
  process.exit(0);
});

module.exports = prisma;
