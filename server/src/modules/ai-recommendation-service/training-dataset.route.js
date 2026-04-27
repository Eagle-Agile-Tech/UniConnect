const express = require("express");

const authenticate = require("../../middlewares/authMiddleware");
const adminAuthorization = require("../../middlewares/adminAuthorization");
const asyncHandler = require("../../middlewares/asyncHandler");
const trainingDatasetController = require("./training-dataset.controller");

const router = express.Router();

router.get(
  "/training-dataset",
  authenticate,
  adminAuthorization,
  asyncHandler(trainingDatasetController.generate),
);

module.exports = router;
