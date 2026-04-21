const express = require("express");
const router = express.Router();

const {
  startPayment,
  verifyPaymentController,
  getMyCoursesController,
} = require("./payment.controller");

const authMiddleware = require("../../middlewares/authMiddleware");

// Start payment
router.post("/start", authMiddleware, startPayment);

// Verify payment
router.get("/verify", authMiddleware, verifyPaymentController);
router.get("/my-courses", authMiddleware, getMyCoursesController);

module.exports = router;
