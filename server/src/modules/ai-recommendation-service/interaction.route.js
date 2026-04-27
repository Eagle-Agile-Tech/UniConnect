const express = require("express");

const authenticate = require("../../middlewares/authMiddleware");
const asyncHandler = require("../../middlewares/asyncHandler");
const interactionController = require("./interaction.controller");

const router = express.Router();

router.use(authenticate);

router.get("/", asyncHandler(interactionController.getMetadata));
router.post("/", asyncHandler(interactionController.create));

module.exports = router;
