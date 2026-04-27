const express = require("express");
const controller = require("./network.controller");
const authMiddleware = require("../../middlewares/authMiddleware");

const router = express.Router();

router.use(authMiddleware);

// Requests
router.post("/request", controller.sendRequest);
router.post("/accept", controller.acceptRequest);
router.post("/reject", controller.rejectRequest);
router.post("/cancel", controller.cancelRequest);

// Network
router.delete("/", controller.removeNetwork);

// Fetch
router.get("/", controller.getMyNetwork);
router.get("/incoming", controller.getIncoming);
router.get("/outgoing", controller.getOutgoing);
router.get("/:userId", controller.getUserNetwork);

module.exports = router;
