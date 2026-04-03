const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../../.env") });

const { defineConfig, env } = require("@prisma/config");

module.exports = defineConfig({
  schema: path.resolve(__dirname, "prisma/schema.prisma"),
  datasource: {
    url: env("DATABASE_URL"),
    shadowDatabaseUrl: env("SHADOW_DATABASE_URL"),
  },
});
