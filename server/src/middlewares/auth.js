// src/middlewares/auth.js
// MOCK VERSION - Replace with real implementation when auth is ready

/**
 * Mock authentication middleware
 * Simulates an authenticated user for development
 */
const authenticate = (req, res, next) => {
  // Mock user for testing post features
  // You can change this user ID to test different scenarios
  req.user = {
    id: "123e4567-e89b-12d3-a456-426614174000", // Fixed test UUID
    email: "test@uniconnect.edu",
    role: "STUDENT",
    username: "teststudent",
  };

  console.log("🔐 Mock auth: User authenticated as", req.user.id);
  next();
};

/**
 * Mock optional authentication middleware
 * Adds user if available, but doesn't require it
 */
const optionalAuth = (req, res, next) => {
  // For now, always add the mock user
  // Later this will check for a valid token
  req.user = {
    id: "123e4567-e89b-12d3-a456-426614174000",
    email: "test@uniconnect.edu",
    role: "STUDENT",
    username: "teststudent",
  };

  console.log("🔓 Mock optional auth: User available");
  next();
};

module.exports = {
  authenticate,
  optionalAuth,
};
