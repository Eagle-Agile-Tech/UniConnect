const test = require("node:test");
const assert = require("node:assert/strict");
const Module = require("node:module");
const path = require("node:path");

const errors = require("../errors");

function createSocketServer(roomSize = 1) {
  const emittedEvents = [];

  return {
    emittedEvents,
    sockets: {
      adapter: {
        rooms: {
          get(roomName) {
            if (roomSize <= 0) return undefined;
            return new Set(Array.from({ length: roomSize }, (_, index) => `${roomName}:${index}`));
          },
        },
      },
    },
    to(roomName) {
      return {
        emit(event, payload) {
          emittedEvents.push({ roomName, event, payload });
        },
      };
    },
  };
}

function loadNotificationService({
  prisma,
  io,
  pushEnabled = false,
  sendResult = "message-id",
  loggerWarn = () => {},
}) {
  const servicePath = path.resolve(__dirname, "../modules/notification/notification.service.js");
  delete require.cache[servicePath];

  const originalLoad = Module._load;
  const firebaseAdmin = {
    apps: [],
    credential: {
      cert(value) {
        return value;
      },
    },
    initializeApp() {
      firebaseAdmin.apps.push({ initialized: true });
    },
    messaging() {
      return {
        send: async () => sendResult,
      };
    },
  };

  Module._load = function mockLoad(request, parent, isMain) {
    if (request === "firebase-admin") return firebaseAdmin;
    if (request === "../../lib/prisma") return prisma;
    if (request === "../../config/push-notification-key") {
      return pushEnabled ? { project_id: "demo-project" } : null;
    }
    if (request === "../../utils/logger") return { warn: loggerWarn };
    if (request === "../../errors") return errors;
    if (request === "../../Sockets/io") return { getIO: () => io };
    return originalLoad.call(this, request, parent, isMain);
  };

  try {
    return require(servicePath);
  } finally {
    Module._load = originalLoad;
  }
}

test("createAndSendNotification emits socket events for online recipients", async () => {
  const createdNotification = {
    id: "notification-1",
    recipientId: "recipient-1",
    actorId: "actor-1",
    title: "New comment",
    body: "Someone replied to your post",
    isDelivered: false,
  };
  const notificationUpdates = [];
  const prisma = {
    notification: {
      create: async ({ data }) => ({ ...createdNotification, ...data }),
      update: async ({ data }) => {
        notificationUpdates.push(data);
        return { ...createdNotification, ...data };
      },
      count: async () => 3,
    },
    user: {
      findUnique: async () => null,
    },
  };
  const io = createSocketServer(1);
  const service = loadNotificationService({ prisma, io });

  const notification = await service.createAndSendNotification({
    recipientId: "recipient-1",
    actorId: "actor-1",
    type: "SYSTEM",
    title: "New comment",
    body: "Someone replied to your post",
    data: { postId: "post-1" },
  });

  assert.equal(notification.isDelivered, true);
  assert.deepEqual(notificationUpdates, [{ isDelivered: true }]);
  assert.deepEqual(io.emittedEvents.map((event) => event.event), [
    "notification",
    "notification:unread-count",
  ]);
  assert.equal(io.emittedEvents[0].roomName, "user:recipient-1");
  assert.equal(io.emittedEvents[1].payload.unreadCount, 3);
});

test("createAndSendNotification falls back to FCM for offline recipients with a device token", async () => {
  const createdNotification = {
    id: "notification-2",
    recipientId: "recipient-2",
    title: "New message",
    body: "You have a new message",
    isDelivered: false,
  };
  const prisma = {
    notification: {
      create: async ({ data }) => ({ ...createdNotification, ...data }),
      update: async ({ data }) => ({ ...createdNotification, ...data }),
      count: async () => 1,
    },
    user: {
      findUnique: async () => ({ fcmToken: "valid-device-token" }),
    },
  };
  const io = createSocketServer(0);
  const service = loadNotificationService({
    prisma,
    io,
    pushEnabled: true,
    sendResult: "firebase-message-id",
  });

  const notification = await service.createAndSendNotification({
    recipientId: "recipient-2",
    type: "SYSTEM",
    title: "New message",
    body: "You have a new message",
  });

  assert.equal(notification.isDelivered, true);
  assert.deepEqual(io.emittedEvents, [
    {
      roomName: "user:recipient-2",
      event: "notification:unread-count",
      payload: { unreadCount: 1 },
    },
  ]);
});

test("markAsRead updates the notification and broadcasts the new unread count", async () => {
  const prisma = {
    notification: {
      findUnique: async () => ({
        id: "notification-3",
        recipientId: "recipient-3",
        isRead: false,
      }),
      update: async () => ({
        id: "notification-3",
        recipientId: "recipient-3",
        isRead: true,
      }),
      count: async () => 4,
    },
  };
  const io = createSocketServer(1);
  const service = loadNotificationService({ prisma, io });

  const updated = await service.markAsRead("notification-3", "recipient-3");

  assert.equal(updated.isRead, true);
  assert.deepEqual(io.emittedEvents, [
    {
      roomName: "user:recipient-3",
      event: "notification:unread-count",
      payload: { unreadCount: 4 },
    },
  ]);
});

test("markAsRead rejects users trying to modify someone else's notification", async () => {
  const prisma = {
    notification: {
      findUnique: async () => ({
        id: "notification-4",
        recipientId: "recipient-4",
        isRead: false,
      }),
    },
  };
  const service = loadNotificationService({ prisma, io: createSocketServer(0) });

  await assert.rejects(
    () => service.markAsRead("notification-4", "another-user"),
    (error) => error instanceof errors.ForbiddenError
  );
});

test("markAllAsRead marks all unread notifications and emits zero unread count", async () => {
  const prisma = {
    notification: {
      updateMany: async () => ({ count: 5 }),
    },
  };
  const io = createSocketServer(1);
  const service = loadNotificationService({ prisma, io });

  const updatedCount = await service.markAllAsRead("recipient-5");

  assert.equal(updatedCount, 5);
  assert.deepEqual(io.emittedEvents, [
    {
      roomName: "user:recipient-5",
      event: "notification:unread-count",
      payload: { unreadCount: 0 },
    },
  ]);
});
