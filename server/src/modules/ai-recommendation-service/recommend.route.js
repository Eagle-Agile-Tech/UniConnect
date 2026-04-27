const express = require("express");

const authenticate = require("../../middlewares/authMiddleware");
const asyncHandler = require("../../middlewares/asyncHandler");
const recommendationController = require("./recommendation.controller");

// Thin router that exposes the "vector rank" recommendation endpoint:
// GET /api/v1/recommend/:userId
const router = express.Router();

router.use(authenticate);

// Alias path (matches product spec wording):
// GET /recommend/user/:id  (mounted at /recommend)
// GET /api/v1/recommend/user/:id (mounted at /api/v1/recommend)
router.get(
  "/user/:userId",
  asyncHandler(recommendationController.getVectorRankForUser),
);

router.get(
  "/:userId",
  asyncHandler(recommendationController.getVectorRankForUser),
);

router.get(
  "/",
  asyncHandler(recommendationController.getVectorRankForCurrentUser),
);

module.exports = router;
