const prisma = require("../../lib/prisma");

// ========================
// NETWORK REQUESTS
// ========================

async function findRequest(senderId, receiverId) {
  return prisma.networkRequest.findFirst({
    where: {
      OR: [
        { senderId, receiverId },
        { senderId: receiverId, receiverId: senderId },
      ],
    },
  });
}

async function createRequest(senderId, receiverId) {
  return prisma.networkRequest.create({
    data: { senderId, receiverId },
  });
}

async function deleteRequest(requestId) {
  return prisma.networkRequest.delete({
    where: { id: requestId },
  });
}

async function getIncomingRequests(userId) {
  return prisma.networkRequest.findMany({
    where: { receiverId: userId },
  });
}

async function getOutgoingRequests(userId) {
  return prisma.networkRequest.findMany({
    where: { senderId: userId },
  });
}

// ========================
// NETWORK (FRIENDS)
// ========================

async function findNetwork(userAId, userBId) {
  return prisma.network.findFirst({
    where: {
      OR: [
        { userAId, userBId },
        { userAId: userBId, userBId: userAId },
      ],
    },
  });
}
async function getRequestById(requestId) {
  return prisma.networkRequest.findUnique({
    where: { id: requestId },
  });
}
async function getUserNetwork(userId) {
  return prisma.network.findMany({
    where: {
      OR: [{ userAId: userId }, { userBId: userId }],
    },
  });
}
async function createNetwork(userAId, userBId) {
  // normalize ordering to avoid duplicates
  const sorted = [userAId, userBId].sort();

  return prisma.network.create({
    data: {
      userAId: sorted[0],
      userBId: sorted[1],
    },
  });
}

async function deleteNetwork(userId, targetId) {
  return prisma.network.deleteMany({
    where: {
      OR: [
        { userAId: userId, userBId: targetId },
        { userAId: targetId, userBId: userId },
      ],
    },
  });
}

async function getMyNetwork(userId) {
  return prisma.network.findMany({
    where: {
      OR: [{ userAId: userId }, { userBId: userId }],
    },
  });
}

module.exports = {
  findRequest,
  createRequest,
  deleteRequest,
  getIncomingRequests,
  getOutgoingRequests,

  findNetwork,
  createNetwork,
  deleteNetwork,
  getMyNetwork,
  getRequestById,
  getUserNetwork,
};
