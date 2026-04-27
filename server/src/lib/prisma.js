require("../config/env");

const { PrismaClient } = require("../node_modules/.prisma/client");
const { PrismaPg } = require("@prisma/adapter-pg");
const { Pool } = require("pg");
const { isProduction } = require("../config/env");

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error(
    "DATABASE_URL is not set. Prisma client cannot be initialized.",
  );
}

let prisma;

function createPrismaClient() {
  const adapter = new PrismaPg(
    new Pool({
      connectionString,
    }),
  );

  return new PrismaClient({
    adapter,
    log: isProduction ? ["error"] : ["query", "info", "warn", "error"],
  });
}

// ✅ Singleton pattern (prevents multiple instances in dev)
if (process.env.NODE_ENV === "production") {
  prisma = createPrismaClient();
} else {
  if (!global.prisma) {
    global.prisma = createPrismaClient();
  }
  prisma = global.prisma;
}

// ✅ Test connection (good for debugging startup issues)
(async () => {
  try {
    await prisma.$connect();
    console.log("✅ Database connected successfully");
  } catch (error) {
    console.error("❌ Database connection failed:", error.message);
    process.exit(1);
  }
})();

// ✅ Graceful shutdown
process.on("SIGINT", async () => {
  await prisma.$disconnect();
  process.exit(0);
});

process.on("SIGTERM", async () => {
  await prisma.$disconnect();
  process.exit(0);
});

module.exports = prisma;
