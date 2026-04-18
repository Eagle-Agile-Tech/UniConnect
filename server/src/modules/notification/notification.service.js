const admin = require("firebase-admin");
const prisma = require("../../lib/prisma");
const serviceAccount = require("../../config/push-notification-key");
const logger = require("../../utils/logger");
const { NotFoundError, ForbiddenError } = require("../../errors");
const { getIO } = require("../../Sockets/io");

const pushEnabled = Boolean(serviceAccount);

if (pushEnabled && !admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

async function sendFCM(token, payload) {
  if (!pushEnabled || !token) {
    return null;
  }

  const message = {
    token,
    notification: {
      title: payload.title,
      body: payload.body,
    },
    data: payload.data || {},
  };

  return admin.messaging().send(message);
}

async function createNotification(data) {
  return prisma.notification.create({ data });
}

async function createAndSendNotification({
  recipientId,
  actorId,
  type,
  referenceId,
  referenceType,
  title,
  body,
  data,
  io,
  onlineUsers,
  tx,
}) {
  const db = tx || prisma;
  const socketServer = io || getIO();
  const notification = await db.notification.create({
    data: {
      recipientId,
      actorId,
      type,
      referenceId,
      referenceType,
      title,
      body,
      data,
    },
  });

  let isDelivered = false;
  const roomName = `user:${recipientId}`;
  const room = socketServer?.sockets?.adapter?.rooms?.get(roomName);
  const recipientOnline = typeof onlineUsers?.get === "function"
    ? Boolean(onlineUsers.get(recipientId))
    : Boolean(room?.size);

  if (recipientOnline && socketServer) {
    socketServer.to(roomName).emit("notification", notification);
    isDelivered = true;
  } else {
    const user = await prisma.user.findUnique({
      where: { id: recipientId },
      select: { fcmToken: true },
    });

    if (user?.fcmToken) {
      try {
        await sendFCM(user.fcmToken, {
          title,
          body,
          data,
        });
        isDelivered = true;
      } catch (error) {
        logger.warn({
          message: "Failed to send FCM notification",
          recipientId,
          notificationId: notification.id,
          error: error.message,
        });
      }
    }
  }

  if (isDelivered) {
    await db.notification.update({
      where: { id: notification.id },
      data: { isDelivered: true },
    });
    notification.isDelivered = true;
  }

  const unreadCount = await prisma.notification.count({
    where: {
      recipientId,
      isRead: false,
    },
  });

  if (socketServer) {
    socketServer.to(roomName).emit("notification:unread-count", {
      unreadCount,
    });
  }

  return notification;
}

async function getNotificationsForUser(userId, options = {}) {
  const { limit = 20, unreadOnly = false } = options;

  return prisma.notification.findMany({
    where: {
      recipientId: userId,
      ...(unreadOnly ? { isRead: false } : {}),
    },
    take: limit,
    orderBy: { createdAt: "desc" },
    include: {
      actor: {
        select: {
          id: true,
          firstName: true,
          lastName: true,
          profile: {
            select: {
              username: true,
              profileImage: true,
            },
          },
        },
      },
    },
  });
}

async function getUnreadCount(userId) {
  return prisma.notification.count({
    where: {
      recipientId: userId,
      isRead: false,
    },
  });
}

async function markAsRead(id, userId) {
  const notification = await prisma.notification.findUnique({
    where: { id },
    select: { id: true, recipientId: true, isRead: true },
  });

  if (!notification) {
    throw new NotFoundError("Notification not found");
  }

  if (notification.recipientId !== userId) {
    throw new ForbiddenError("You can only update your own notifications");
  }

  if (notification.isRead) {
    return notification;
  }

  const updatedNotification = await prisma.notification.update({
    where: { id },
    data: { isRead: true },
  });

  const unreadCount = await getUnreadCount(userId);
  const socketServer = getIO();
  socketServer?.to(`user:${userId}`).emit("notification:unread-count", {
    unreadCount,
  });

  return updatedNotification;
}

async function markAllAsRead(userId) {
  const result = await prisma.notification.updateMany({
    where: {
      recipientId: userId,
      isRead: false,
    },
    data: { isRead: true },
  });

  const socketServer = getIO();
  socketServer?.to(`user:${userId}`).emit("notification:unread-count", {
    unreadCount: 0,
  });

  return result.count;
}

async function updateDeviceToken(userId, fcmToken) {
  return prisma.user.update({
    where: { id: userId },
    data: { fcmToken },
    select: { id: true, fcmToken: true },
  });
}

module.exports = {
  sendFCM,
  createNotification,
  createAndSendNotification,
  getNotificationsForUser,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
  updateDeviceToken,
};
