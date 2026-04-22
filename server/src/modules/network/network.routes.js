const express = require("express");
const controller = require("./network.controller");

const router = express.Router();

// Requests
router.post("/request", controller.sendRequest);
router.post("/accept", controller.acceptRequest);
router.post("/reject", controller.rejectRequest);

// Network
router.delete("/", controller.removeNetwork);

// Fetch
router.get("/", controller.getMyNetwork);
router.get("/incoming", controller.getIncoming);
router.get("/outgoing", controller.getOutgoing);

module.exports = router;
