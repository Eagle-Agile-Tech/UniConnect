const path = require("path");
const fs = require("fs");

const localEnv = path.resolve(__dirname, ".env");
const rootEnv = path.resolve(__dirname, "../../.env");
const envPath = fs.existsSync(localEnv) ? localEnv : rootEnv;
require("dotenv").config({ path: envPath });

const { defineConfig, env } = require("@prisma/config");

module.exports = defineConfig({
  schema: path.resolve(__dirname, "prisma/schema.prisma"),
  datasource: {
    url: env("DATABASE_URL"),
    shadowDatabaseUrl: env("SHADOW_DATABASE_URL"),
  },
});
