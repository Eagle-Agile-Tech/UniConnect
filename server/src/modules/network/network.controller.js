const service = require("./network.service");

// =========================
// SEND REQUEST
// =========================
async function sendRequest(req, res) {
  try {
    const senderId = req.user?.id; // 🔐 ONLY from auth token
    const { receiverId } = req.body;

    if (!senderId) {
      return res.status(401).json({
        success: false,
        message: "Unauthorized",
      });
    }

    if (!receiverId) {
      return res.status(400).json({
        success: false,
        message: "receiverId is required",
      });
    }

    const result = await service.sendRequest(senderId, receiverId);

    return res.status(201).json({
      success: true,
      data: result,
    });
  } catch (err) {
    return res.status(400).json({
      success: false,
      message: err.message,
    });
  }
}

// =========================
// ACCEPT REQUEST
// =========================
async function acceptRequest(req, res) {
  try {
    const userId = req.user?.id;
    const { requestId } = req.body;

    if (!userId) {
      return res.status(401).json({ success: false, message: "Unauthorized" });
    }

    if (!requestId) {
      return res.status(400).json({
        success: false,
        message: "requestId is required",
      });
    }

    const result = await service.acceptRequest(requestId, userId);

    return res.status(200).json({
      success: true,
      data: result,
    });
  } catch (err) {
    return res.status(400).json({
      success: false,
      message: err.message,
    });
  }
}

// =========================
// REJECT REQUEST
// =========================
async function rejectRequest(req, res) {
  try {
    const userId = req.user?.id;
    const { requestId } = req.body;

    if (!userId) {
      return res.status(401).json({ success: false, message: "Unauthorized" });
    }

    if (!requestId) {
      return res.status(400).json({
        success: false,
        message: "requestId is required",
      });
    }

    await service.rejectRequest(requestId, userId);

    return res.status(200).json({
      success: true,
      message: "Request rejected",
    });
  } catch (err) {
    return res.status(400).json({
      success: false,
      message: err.message,
    });
  }
}

// =========================
// REMOVE NETWORK
// =========================
async function removeNetwork(req, res) {
  try {
    const userId = req.user?.id;
    const { targetId } = req.body;

    if (!userId) {
      return res.status(401).json({ success: false, message: "Unauthorized" });
    }

    if (!targetId) {
      return res.status(400).json({
        success: false,
        message: "targetId is required",
      });
    }

    await service.removeNetwork(userId, targetId);

    return res.status(200).json({
      success: true,
      message: "Network removed",
    });
  } catch (err) {
    return res.status(400).json({
      success: false,
      message: err.message,
    });
  }
}

// =========================
// GETTERS
// =========================
async function getMyNetwork(req, res) {
  try {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({ success: false, message: "Unauthorized" });
    }

    const data = await service.getMyNetwork(userId);

    return res.status(200).json({
      success: true,
      data,
    });
  } catch (err) {
    return res.status(400).json({
      success: false,
      message: err.message,
    });
  }
}
async function cancelRequest(req, res) {
  try {
    const userId = req.user?.id;
    const { receiverId } = req.body;

    if (!userId) {
      return res.status(401).json({ success: false, message: "Unauthorized" });
    }

    if (!receiverId) {
      return res.status(400).json({
        success: false,
        message: "receiverId is required",
      });
    }

    await service.cancelRequest(userId, receiverId);

    return res.status(200).json({
      success: true,
      message: "Request cancelled",
    });
  } catch (err) {
    return res.status(400).json({
      success: false,
      message: err.message,
    });
  }
}
async function getUserNetwork(req, res) {
  try {
    const { userId } = req.params;

    const data = await service.getUserNetwork(userId);

    return res.status(200).json({
      success: true,
      data,
    });
  } catch (err) {
    return res.status(400).json({
      success: false,
      message: err.message,
    });
  }
}

async function getIncoming(req, res) {
  try {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({ success: false, message: "Unauthorized" });
    }

    const data = await service.getIncomingRequests(userId);

    return res.status(200).json({
      success: true,
      data,
    });
  } catch (err) {
    return res.status(400).json({
      success: false,
      message: err.message,
    });
  }
}

async function getOutgoing(req, res) {
  try {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({ success: false, message: "Unauthorized" });
    }

    const data = await service.getOutgoingRequests(userId);

    return res.status(200).json({
      success: true,
      data,
    });
  } catch (err) {
    return res.status(400).json({
      success: false,
      message: err.message,
    });
  }
}

module.exports = {
  sendRequest,
  acceptRequest,
  rejectRequest,
  removeNetwork,
  getMyNetwork,
  getIncoming,
  getOutgoing,
  cancelRequest,
  getUserNetwork,
};
