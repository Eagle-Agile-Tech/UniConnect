const repo = require("./network.repository");

// ========================
// SEND REQUEST
// ========================
async function sendRequest(senderId, receiverId) {
  if (!senderId || !receiverId) {
    throw new Error("senderId and receiverId are required");
  }

  if (senderId === receiverId) {
    throw new Error("You cannot send a request to yourself");
  }

  // Check existing connection (both directions)
  const existingNetwork = await repo.findNetwork(senderId, receiverId);
  if (existingNetwork) {
    throw new Error("You are already connected");
  }

  // Check existing request (both directions)
  const existingRequest = await repo.findRequest(senderId, receiverId);
  if (existingRequest) {
    throw new Error("Request already exists");
  }

  return repo.createRequest(senderId, receiverId);
}

// ========================
// ACCEPT REQUEST
// ========================
async function acceptRequest(requestId, userId) {
  if (!requestId) {
    throw new Error("requestId is required");
  }

  const request = await repo.getRequestById(requestId);

  if (!request) {
    throw new Error("Request not found");
  }

  // 🔐 security check: only receiver can accept
  if (request.receiverId !== userId) {
    throw new Error("Not authorized to accept this request");
  }

  await repo.deleteRequest(requestId);

  return repo.createNetwork(request.senderId, request.receiverId);
}
async function getUserNetwork(userId) {
  if (!userId) throw new Error("userId is required");

  return repo.getUserNetwork(userId);
}

// ========================
// REJECT REQUEST
// ========================
async function rejectRequest(requestId, userId) {
  if (!requestId) {
    throw new Error("requestId is required");
  }

  const request = await repo.getRequestById(requestId);

  if (!request) {
    throw new Error("Request not found");
  }

  if (request.receiverId !== userId) {
    throw new Error("Not authorized to reject this request");
  }

  return repo.deleteRequest(requestId);
}
async function cancelRequest(senderId, receiverId) {
  if (!senderId || !receiverId) {
    throw new Error("senderId and receiverId are required");
  }

  const request = await repo.findRequest(senderId, receiverId);

  if (!request) {
    throw new Error("Request not found");
  }

  // ✅ make sure it's actually sent by this user
  if (request.senderId !== senderId) {
    throw new Error("You can only cancel your own request");
  }

  return repo.deleteRequest(request.id);
}
// ========================
// REMOVE CONNECTION
// ========================
async function removeNetwork(userId, targetId) {
  if (!userId || !targetId) {
    throw new Error("userId and targetId are required");
  }

  const existing = await repo.findNetwork(userId, targetId);

  if (!existing) {
    throw new Error("Network does not exist");
  }

  return repo.deleteNetwork(userId, targetId);
}

// ========================
// FETCHERS
// ========================
async function getMyNetwork(userId) {
  if (!userId) throw new Error("userId is required");
  return repo.getMyNetwork(userId);
}

async function getIncomingRequests(userId) {
  if (!userId) throw new Error("userId is required");
  return repo.getIncomingRequests(userId);
}

async function getOutgoingRequests(userId) {
  if (!userId) throw new Error("userId is required");
  return repo.getOutgoingRequests(userId);
}

module.exports = {
  sendRequest,
  acceptRequest,
  rejectRequest,
  removeNetwork,
  getMyNetwork,
  getIncomingRequests,
  getOutgoingRequests,
  cancelRequest,
  getUserNetwork,
};
