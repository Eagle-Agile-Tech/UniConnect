const envPath = require("path").join(__dirname, "..", "..", ".env");
require("dotenv").config({
  path: envPath,
  override: true,
});
console.log(`[env] loaded ${envPath} override=true`);
const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");
require("./modules/ai/ai-moderation.queue");
const prisma = require("./lib/prisma"); // Import shared prisma instance

// Import routes
const postRoutes = require("./modules/post/post.routes");
const engagementRoutes = require("./modules/engagement/engagement.routes");

const app = express();
const PORT = process.env.PORT || 3000;


// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan("dev"));
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

// Health check
app.get("/health", (req, res) => {
  res.json({ status: "OK", timestamp: new Date().toISOString() });
});

// Routes
app.use("/api/v1/posts", postRoutes);
app.use("/api/v1", engagementRoutes);
app.get("/api/v1/test-auth", (req, res) => {
  res.json({
    message: "Auth test",
    user: req.user, // Should show your mock user
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: `Route ${req.method} ${req.url} not found`,
    code: "ERR_NOT_FOUND",
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error("Error:", err.message);

  if (err.statusCode) {
    return res.status(err.statusCode).json({
      error: err.message,
      code: err.code || "ERR_BAD_REQUEST",
      ...(err.details && { details: err.details }),
    });
  }

  // Handle specific errors
  if (err.message === "Post not found") {
    return res
      .status(404)
      .json({ error: err.message, code: "ERR_POST_NOT_FOUND" });
  }
  if (err.message.includes("Not authorized")) {
    return res.status(403).json({ error: err.message, code: "ERR_FORBIDDEN" });
  }

  // Default error
  res.status(500).json({
    error: "Internal server error",
    code: "ERR_INTERNAL",
    ...(process.env.NODE_ENV === "development" && { details: err.message }),
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`📝 Environment: ${process.env.NODE_ENV || "development"}`);
});

// Graceful shutdown
process.on("SIGTERM", () => {
  console.log("SIGTERM received. Closing gracefully...");
  prisma.$disconnect();
  process.exit(0);
});

process.on("SIGINT", () => {
  console.log("SIGINT received. Closing gracefully...");
  prisma.$disconnect();
  process.exit(0);
});
