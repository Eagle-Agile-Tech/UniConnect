const express = require("express");

const authenticate = require("../../middlewares/authMiddleware");
const asyncHandler = require("../../middlewares/asyncHandler");
const recommendationController = require("./recommendation.controller");

const router = express.Router();

router.use(authenticate);
router.get("/status", asyncHandler(recommendationController.getStatus));
router.get("/", asyncHandler(recommendationController.getForCurrentUser));
router.get("/:userId", asyncHandler(recommendationController.getForCurrentUser));

module.exports = router;
