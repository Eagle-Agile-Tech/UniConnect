const path = require("path");
const fs = require("fs");

const localEnv = path.resolve(__dirname, ".env");
const rootEnv = path.resolve(__dirname, "../.env");
const isDocker = process.env.PRISMA_ENV === "docker";

// In Docker, the compose env_file already injects the correct DATABASE_URL.
// Avoid loading Database/.env there, because it points at localhost and would
// send Prisma to the wrong host inside the container.
if (!isDocker && fs.existsSync(localEnv)) {
  require("dotenv").config({ path: localEnv });
} else if (fs.existsSync(rootEnv)) {
  require("dotenv").config({ path: rootEnv });
}

const { defineConfig, env } = require("@prisma/config");

module.exports = defineConfig({
  schema: path.resolve(__dirname, "prisma/schema.prisma"),
  datasource: {
    url: env("DATABASE_URL"),
    shadowDatabaseUrl: env("SHADOW_DATABASE_URL"),
  },
});
