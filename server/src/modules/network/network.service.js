const repo = require("./network.repository");
const prisma = require("../../lib/prisma");

async function syncProfileNetworkState(userId) {
  if (!userId) return null;

  const [networkCount, incomingCount, outgoingCount] = await Promise.all([
    repo.countUserNetworks(userId),
    repo.countIncomingRequests(userId),
    repo.countOutgoingRequests(userId),
  ]);

  const isNetworkedBy = networkCount > 0 || incomingCount > 0;
  const networkStatus =
    networkCount > 0
      ? "CONNECTED"
      : incomingCount > 0 || outgoingCount > 0
        ? "PENDING"
        : null;

  await prisma.userProfile.updateMany({
    where: { userId },
    data: {
      networkCount,
      isNetworkedBy,
    },
  });

  return {
    networkCount,
    networkStatus,
  };
}

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

  const request = await repo.createRequest(senderId, receiverId);
  const senderState = await syncProfileNetworkState(senderId);
  const receiverState = await syncProfileNetworkState(receiverId);

  return {
    request,
    networkState: {
      sender: senderState,
      receiver: receiverState,
    },
    status: "PENDING",
  };
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
  const network = await repo.createNetwork(request.senderId, request.receiverId);
  const senderState = await syncProfileNetworkState(request.senderId);
  const receiverState = await syncProfileNetworkState(request.receiverId);

  return {
    network,
    networkState: {
      sender: senderState,
      receiver: receiverState,
    },
    status: "CONNECTED",
  };
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

  const deleted = await repo.deleteRequest(requestId);
  const senderState = await syncProfileNetworkState(request.senderId);
  const receiverState = await syncProfileNetworkState(request.receiverId);

  return {
    request: deleted,
    networkState: {
      sender: senderState,
      receiver: receiverState,
    },
    status: "REJECTED",
  };
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

  const removed = await repo.deleteNetwork(userId, targetId);
  const userState = await syncProfileNetworkState(userId);
  const targetState = await syncProfileNetworkState(targetId);

  return {
    removed,
    networkState: {
      user: userState,
      target: targetState,
    },
    status: "REMOVED",
  };
}

// ========================
// FETCHERS
// ========================
async function getMyNetwork(userId) {
  if (!userId) throw new Error("userId is required");
  const [connected, incoming, outgoing, profileState] = await Promise.all([
    repo.getMyNetwork(userId),
    repo.getIncomingRequests(userId),
    repo.getOutgoingRequests(userId),
    syncProfileNetworkState(userId),
  ]);

  return {
    connected,
    pending: {
      incoming,
      outgoing,
      total: incoming.length + outgoing.length,
    },
    summary: profileState,
  };
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
