const express = require("express");
const controller = require("./report.controller");
const authMiddleware = require("../../middlewares/authMiddleware");

const router = express.Router();

/**
 * Create report
 */
router.post("/", authMiddleware, controller.createReport);

/**
 * Cancel report
 */
router.delete("/", authMiddleware, controller.cancelReport);

/**
 * Flagged reports (admin)
 */
router.get("/flagged", authMiddleware, controller.getFlaggedReports);

/**
 * Reports for specific target
 */
router.get("/:targetType/:targetId", authMiddleware, controller.getReportsByTarget);
module.exports = router;
