const path = require("path");
const fs = require("fs");

const localEnv = path.resolve(__dirname, ".env");
const rootEnv = path.resolve(__dirname, "../.env");
const envPath = fs.existsSync(localEnv) ? localEnv : rootEnv;

function loadEnvFallback(filePath) {
  if (!fs.existsSync(filePath)) return;
  const lines = fs.readFileSync(filePath, "utf8").split(/\r?\n/);
  for (const raw of lines) {
    const line = raw.trim();
    if (!line || line.startsWith("#")) continue;
    const eq = line.indexOf("=");
    if (eq <= 0) continue;

    const key = line.slice(0, eq).trim();
    let value = line.slice(eq + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }

    if (process.env[key] === undefined) {
      process.env[key] = value;
    }
  }
}

try {
  require("dotenv").config({ path: envPath });
} catch (_err) {
  loadEnvFallback(envPath);
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
