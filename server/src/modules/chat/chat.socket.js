const zod = require('zod');
const prisma = require('../../lib/prisma');
const redisClient = require('../../config/redis');
const chatService = require('./chat.service');
const notificationService = require('../notification/notification.service');
const {
  createSendMessageSchema,
  deleteMessageSchema,
  markAsReadSchema,
  markAsDeliveredSchema,
  reactToMessageSchema,
  typingSchema,
  typingStateSchema,
  updateMessageSchema,
  addParticipantSchema,
  removeParticipantSchema,
  updateGroupChatSchema,
  historySchema,
  presenceSchema,
} = require('./chat.schema');

const joinLeaveSchema = zod
  .object({
    chatId: zod.string().uuid(),
  })
  .strict();

const presenceState = new Map();
const rateBuckets = new Map();
const TYPING_TTL_SECONDS = 8;

async function setTypingState(chatId, userId, isTyping) {
  const redisKey = `typing:${chatId}:${userId}`;
  try {
    if (isTyping) {
      await redisClient.set(redisKey, '1', 'EX', TYPING_TTL_SECONDS);
    } else {
      await redisClient.del(redisKey);
    }
    return;
  } catch (err) {
    // Redis unavailable -> skip typing TTL persistence
  }
}

async function getTypingUsers(chatId, userIds) {
  const keys = userIds.map((id) => `typing:${chatId}:${id}`);
  try {
    const results = await redisClient.mget(keys);
    const typingUsers = [];
    results.forEach((value, index) => {
      if (value) typingUsers.push(userIds[index]);
    });
    return typingUsers;
  } catch (err) {
    return [];
  }
}

async function allowRate(userId, key, limit, windowMs) {
  const redisKey = `rate:${userId}:${key}`;
  try {
    const current = await redisClient.incr(redisKey);
    if (current === 1) {
      await redisClient.expire(redisKey, Math.ceil(windowMs / 1000));
    }
    return current <= limit;
  } catch (err) {
    // Redis unavailable -> fallback to in-memory limiter
  }
  const bucketKey = `${userId}:${key}`;
  const now = Date.now();
  const bucket = rateBuckets.get(bucketKey);
  if (!bucket || bucket.resetAt <= now) {
    rateBuckets.set(bucketKey, { count: 1, resetAt: now + windowMs });
    return true;
  }
  if (bucket.count >= limit) {
    return false;
  }
  bucket.count += 1;
  return true;
}

async function setPresence(userId, isOnline) {
  const redisKey = `presence:${userId}`;
  try {
    if (isOnline) {
      const count = await redisClient.hincrby(redisKey, 'count', 1);
      await redisClient.hset(redisKey, 'status', 'ONLINE');
      await redisClient.expire(redisKey, 86400);
      const lastSeenAt = await redisClient.hget(redisKey, 'lastSeenAt');
      return {
        sockets: Number(count),
        lastSeenAt: lastSeenAt ? new Date(lastSeenAt) : null,
      };
    }

    const count = await redisClient.hincrby(redisKey, 'count', -1);
    if (count <= 0) {
      const lastSeenAt = new Date();
      await redisClient.hset(redisKey, {
        count: 0,
        status: 'OFFLINE',
        lastSeenAt: lastSeenAt.toISOString(),
      });
      await redisClient.expire(redisKey, 86400);
      return { sockets: 0, lastSeenAt };
    }
    await redisClient.hset(redisKey, 'status', 'ONLINE');
    await redisClient.expire(redisKey, 86400);
    const lastSeenAt = await redisClient.hget(redisKey, 'lastSeenAt');
    return {
      sockets: Number(count),
      lastSeenAt: lastSeenAt ? new Date(lastSeenAt) : null,
    };
  } catch (err) {
    // Redis unavailable -> fallback to in-memory presence
  }
  const existing = presenceState.get(userId) || {
    sockets: 0,
    lastSeenAt: null,
  };
  if (isOnline) {
    existing.sockets += 1;
  } else {
    existing.sockets = Math.max(0, existing.sockets - 1);
    if (existing.sockets === 0) {
      existing.lastSeenAt = new Date();
    }
  }
  presenceState.set(userId, existing);
  return existing;
}

async function getPresence(userId) {
  const redisKey = `presence:${userId}`;
  try {
    const data = await redisClient.hgetall(redisKey);
    if (data && Object.keys(data).length > 0) {
      return {
        sockets: Number(data.count || 0),
        lastSeenAt: data.lastSeenAt ? new Date(data.lastSeenAt) : null,
        status: data.status || (Number(data.count || 0) > 0 ? 'ONLINE' : 'OFFLINE'),
      };
    }
  } catch (err) {
    // Redis unavailable -> fallback to in-memory presence
  }
  const existing = presenceState.get(userId);
  return {
    sockets: existing?.sockets || 0,
    lastSeenAt: existing?.lastSeenAt || null,
    status: existing && existing.sockets > 0 ? 'ONLINE' : 'OFFLINE',
  };
}

async function isUserOnline(userId) {
  const presence = await getPresence(userId);
  return presence.sockets > 0;
}

function emitError(socket, event, error) {
  const { payload, log } = buildErrorPayload(event, error, socket.user?.id);
  console.error('[socket] chat:error', log);
  socket.emit('chat:error', payload);
}

function buildErrorPayload(event, error, userId) {
  const timestamp = new Date().toISOString();
  const code = normalizeErrorCode(error);
  const type = normalizeErrorType(error, code);
  const message = normalizeErrorMessage(error, code);

  const payload = {
    event,
    code,
    type,
    message,
    timestamp,
  };

  if (
    (code === 'VALIDATION_ERROR' || code === 'BAD_REQUEST') &&
    Array.isArray(error.details)
  ) {
    payload.details = error.details;
  }

  return {
    payload,
    log: {
      event,
      userId,
      code,
      type,
      message,
      originalMessage: error.message,
      stack: error.stack,
      details: error.details,
    },
  };
}

function normalizeErrorCode(error) {
  if (error?.code) return error.code;
  if (error?.name === 'ZodError') return 'VALIDATION_ERROR';
  if (typeof error?.message === 'string') {
    const message = error.message.toLowerCase();
    if (message.includes('rate limit')) return 'RATE_LIMITED';
    if (message.includes('not found')) return 'NOT_FOUND';
  }
  if (error?.name && error.name.startsWith('Prisma')) return 'DB_ERROR';
  if (error?.code && typeof error.code === 'string' && error.code.startsWith('P')) {
    return 'DB_ERROR';
  }
  return 'INTERNAL_ERROR';
}

function normalizeErrorType(error, code) {
  if (error?.type) return error.type;
  switch (code) {
    case 'VALIDATION_ERROR':
    case 'BAD_REQUEST':
      return 'VALIDATION';
    case 'FORBIDDEN':
      return 'AUTH';
    case 'RATE_LIMITED':
      return 'RATE_LIMIT';
    case 'NOT_FOUND':
      return 'NOT_FOUND';
    case 'DB_ERROR':
      return 'DATABASE';
    default:
      return 'INTERNAL';
  }
}

function normalizeErrorMessage(error, code) {
  if (error?.expose === true) return error.message;
  if (code === 'VALIDATION_ERROR' || code === 'BAD_REQUEST') {
    return error.message || 'Invalid payload';
  }
  if (code === 'FORBIDDEN') {
    return error.message || 'Forbidden';
  }
  if (code === 'RATE_LIMITED') {
    return error.message || 'Rate limit exceeded';
  }
  if (code === 'NOT_FOUND') {
    return error.message || 'Resource not found';
  }
  return 'Chat socket error';
}

function makeError(message, code, type) {
  const err = new Error(message);
  if (code) err.code = code;
  if (type) err.type = type;
  return err;
}

function parseOrThrow(schema, payload) {
  const result = schema.safeParse(payload);
  if (!result.success) {
    const err = new Error('Invalid payload');
    err.code = 'VALIDATION_ERROR';
    err.type = 'VALIDATION';
    err.details = result.error.issues.map((issue) => ({
      path: issue.path.join('.'),
      message: issue.message,
    }));
    throw err;
  }

  return result.data;
}

function normalizePayloadOrThrow(payload, { allowMessageAlias = false } = {}) {
  let normalizedPayload = payload;

  if (typeof normalizedPayload === 'string') {
    try {
      normalizedPayload = JSON.parse(normalizedPayload);
    } catch (err) {
      const parseErr = new Error('Invalid payload');
      parseErr.code = 'BAD_REQUEST';
      parseErr.type = 'VALIDATION';
      parseErr.details = [{ path: '', message: 'Payload must be valid JSON' }];
      throw parseErr;
    }
  }

  if (
    allowMessageAlias &&
    normalizedPayload &&
    typeof normalizedPayload === 'object' &&
    normalizedPayload.message &&
    !normalizedPayload.content
  ) {
    const { message, ...rest } = normalizedPayload;
    normalizedPayload = {
      ...rest,
      content: message,
    };
  }

  return normalizedPayload;
}

function logEvent(event, userId, payload) {
  console.log(`[socket] ${event}`, { userId, payload });
}

async function ensureParticipant(chatId, userId) {
  const participant = await prisma.chatParticipant.findUnique({
    where: {
      chatId_userId: {
        chatId,
        userId,
      },
    },
  });

  if (!participant) {
    const err = new Error('You are not a participant of this chat');
    err.code = 'FORBIDDEN';
    err.type = 'AUTH';
    throw err;
  }

  return participant;
}

async function getChatIdForMessage(messageId) {
  const message = await prisma.message.findUnique({
    where: { id: messageId },
    select: { chatId: true },
  });
  return message?.chatId || null;
}

async function emitToChatParticipants(io, chatId, event, payload) {
  const participants = await prisma.chatParticipant.findMany({
    where: { chatId },
    select: { userId: true },
  });

  const targetUsers = participants.map((p) => p.userId);
  const sockets = io.sockets.adapter.rooms.get(`chat:${chatId}`);
  console.log('[socket] emitToChatParticipants', {
    chatId,
    event,
    targetUsers,
    roomSocketCount: sockets ? sockets.size : 0,
  });

  participants.forEach((participant) => {
    io.to(`user:${participant.userId}`).emit(event, payload);
  });
}

async function emitPresenceToChat(io, chatId, userId, status, lastSeenAt) {
  const payload = {
    chatId,
    userId,
    status,
    lastSeenAt: lastSeenAt || null,
  };
  io.to(`chat:${chatId}`).emit('chat:presence', payload);
  await emitToChatParticipants(io, chatId, 'chat:presence', payload);
}

async function emitPresenceToUserChats(io, userId, status, lastSeenAt) {
  const chats = await prisma.chatParticipant.findMany({
    where: { userId },
    select: { chatId: true },
  });

  await Promise.all(
    chats.map((chat) =>
      emitPresenceToChat(io, chat.chatId, userId, status, lastSeenAt)
    )
  );
}

async function emitDeliveryForOnlineRecipients(io, chatId, messageId, senderId) {
  const participants = await prisma.chatParticipant.findMany({
    where: { chatId },
    select: { userId: true },
  });

  const deliveredAt = new Date();
  await Promise.all(
    participants.map(async (participant) => {
      if (participant.userId === senderId) return;
      if (!(await isUserOnline(participant.userId))) return;
      const payload = {
        chatId,
        messageId,
        userId: participant.userId,
        deliveredAt,
      };
      io.to(`user:${senderId}`).emit('chat:message:delivered', payload);
      io.to(`chat:${chatId}`).emit('chat:message:delivered', payload);
    })
  );
}

async function notifyOfflineParticipants(chatId, senderId, message) {
  const participants = await prisma.chatParticipant.findMany({
    where: { chatId },
    select: { userId: true },
  });

  const offlineRecipients = participants
    .map((participant) => participant.userId)
    .filter((participantId) => participantId !== senderId);

  const statuses = await Promise.all(
    offlineRecipients.map(async (participantId) => ({
      participantId,
      isOnline: await isUserOnline(participantId),
    }))
  );

  const resolvedRecipients = statuses
    .filter((status) => status.isOnline === false)
    .map((status) => status.participantId);

  if (resolvedRecipients.length === 0) return;

  await Promise.all(
    resolvedRecipients.map((recipientId) =>
      notificationService.createAndSendNotification({
        recipientId,
        actorId: senderId,
        type: 'MESSAGE',
        referenceId: message.id,
        referenceType: 'MESSAGE',
        title: 'New message',
        body: 'You have a new chat message',
        data: {
          chatId,
          messageId: message.id,
          senderId,
        },
        io,
        onlineUsers: null,
      }),
    ),
  );
}

function registerChatHandlers(io, socket) {
  const userId = socket.user?.id;
  if (!userId) {
    socket.disconnect(true);
    return;
  }

  setPresence(userId, true)
    .then((presence) =>
      emitPresenceToUserChats(io, userId, 'ONLINE', presence.lastSeenAt)
    )
    .catch(() => {});

  socket.on('disconnect', () => {
    setPresence(userId, false)
      .then((updated) => {
        if (updated.sockets === 0) {
          emitPresenceToUserChats(io, userId, 'OFFLINE', updated.lastSeenAt).catch(
            () => {}
          );
        }
      })
      .catch(() => {});
  });

  socket.on('chat:join', async (payload) => {
    try {
      logEvent('chat:join', userId, payload);
      const data = parseOrThrow(joinLeaveSchema, normalizePayloadOrThrow(payload));
      await ensureParticipant(data.chatId, userId);
      socket.join(`chat:${data.chatId}`);
      socket.emit('chat:joined', { chatId: data.chatId });
      const presence = await getPresence(userId);
      await emitPresenceToChat(
        io,
        data.chatId,
        userId,
        'ONLINE',
        presence.lastSeenAt || null
      );
      const delivered = await chatService.markAsDelivered(userId, {
        chatId: data.chatId,
      });
      if (delivered.messageIds.length > 0) {
        const payload = {
          chatId: data.chatId,
          userId,
          messageIds: delivered.messageIds,
          deliveredAt: delivered.deliveredAt,
        };
        io.to(`chat:${data.chatId}`).emit('chat:messages:delivered', payload);
        await emitToChatParticipants(
          io,
          data.chatId,
          'chat:messages:delivered',
          payload
        );
      }
      console.log('✅ Joined room:', data);
    } catch (error) {
      emitError(socket, 'chat:join', error);
    }
  });

  socket.on('chat:leave', async (payload) => {
    try {
      logEvent('chat:leave', userId, payload);
      const data = parseOrThrow(joinLeaveSchema, normalizePayloadOrThrow(payload));
      socket.leave(`chat:${data.chatId}`);
      socket.emit('chat:left', { chatId: data.chatId });
      const presence = await getPresence(userId);
      if (presence.sockets === 0) {
        await emitPresenceToChat(
          io,
          data.chatId,
          userId,
          'OFFLINE',
          presence.lastSeenAt || null
        );
      }
    } catch (error) {
      emitError(socket, 'chat:leave', error);
    }
  });

  socket.on('chat:typing', async (payload) => {
    try {
      if (!(await allowRate(userId, 'typing', 10, 5000))) {
        throw makeError('Typing rate limit exceeded', 'RATE_LIMITED', 'RATE_LIMIT');
      }
      logEvent('chat:typing', userId, payload);
      const data = parseOrThrow(typingSchema, normalizePayloadOrThrow(payload));
      await ensureParticipant(data.chatId, userId);
      await setTypingState(data.chatId, userId, data.isTyping);
      socket.to(`chat:${data.chatId}`).emit('chat:typing', {
        chatId: data.chatId,
        userId,
        isTyping: data.isTyping,
      });
    } catch (error) {
      emitError(socket, 'chat:typing', error);
    }
  });

  socket.on('chat:send', async (payload) => {
    try {
      if (!(await allowRate(userId, 'send', 20, 10000))) {
        throw makeError('Message rate limit exceeded', 'RATE_LIMITED', 'RATE_LIMIT');
      }
      logEvent('chat:send', userId, payload);
      const normalizedPayload = normalizePayloadOrThrow(payload, {
        allowMessageAlias: true,
      });
      const data = parseOrThrow(createSendMessageSchema, normalizedPayload);
      const message = await chatService.sendMessage(userId, data);

      if (message?.duplicate) {
        if (data.clientMessageId) {
          socket.emit('chat:message:ack', {
            chatId: data.chatId,
            clientMessageId: data.clientMessageId,
            messageId: message.id,
            duplicate: true,
          });
        }
        socket.emit('chat:message:existing', message);
        return;
      }

      io.to(`chat:${data.chatId}`).emit('chat:message:new', message);
      await emitToChatParticipants(io, data.chatId, 'chat:message:new', message);
      await emitDeliveryForOnlineRecipients(io, data.chatId, message.id, userId);
      await notifyOfflineParticipants(data.chatId, userId, message);
      if (data.clientMessageId) {
        socket.emit('chat:message:ack', {
          chatId: data.chatId,
          clientMessageId: data.clientMessageId,
          messageId: message.id,
        });
      }
    } catch (error) {
      emitError(socket, 'chat:send', error);
    }
  });

  socket.on('chat:message:update', async (payload) => {
    try {
      logEvent('chat:message:update', userId, payload);
      const data = parseOrThrow(updateMessageSchema, normalizePayloadOrThrow(payload));
      const message = await chatService.updateMessage(userId, data);

      io.to(`chat:${message.chatId}`).emit('chat:message:updated', message);
      await emitToChatParticipants(io, message.chatId, 'chat:message:updated', message);
    } catch (error) {
      emitError(socket, 'chat:message:update', error);
    }
  });

  socket.on('chat:message:delete', async (payload) => {
    try {
      logEvent('chat:message:delete', userId, payload);
      const data = parseOrThrow(deleteMessageSchema, normalizePayloadOrThrow(payload));
      const chatId = await getChatIdForMessage(data.messageId);
      if (!chatId) throw makeError('Message not found', 'NOT_FOUND', 'NOT_FOUND');

      await chatService.deleteMessage(userId, data);

      io.to(`chat:${chatId}`).emit('chat:message:deleted', {
        messageId: data.messageId,
      });
      await emitToChatParticipants(io, chatId, 'chat:message:deleted', {
        messageId: data.messageId,
      });
    } catch (error) {
      emitError(socket, 'chat:message:delete', error);
    }
  });

  socket.on('chat:read', async (payload) => {
    try {
      logEvent('chat:read', userId, payload);
      const data = parseOrThrow(markAsReadSchema, normalizePayloadOrThrow(payload));
      await chatService.markAsRead(userId, data);

      socket.to(`chat:${data.chatId}`).emit('chat:read', {
        chatId: data.chatId,
        userId,
        messageId: data.messageId || null,
      });
      await emitToChatParticipants(io, data.chatId, 'chat:read', {
        chatId: data.chatId,
        userId,
        messageId: data.messageId || null,
      });
    } catch (error) {
      emitError(socket, 'chat:read', error);
    }
  });

  socket.on('chat:delivered', async (payload) => {
    try {
      logEvent('chat:delivered', userId, payload);
      const data = parseOrThrow(markAsDeliveredSchema, normalizePayloadOrThrow(payload));
      const delivered = await chatService.markAsDelivered(userId, data);
      if (delivered.messageIds.length === 0) return;
      const deliveryPayload = {
        chatId: data.chatId,
        userId,
        messageIds: delivered.messageIds,
        deliveredAt: delivered.deliveredAt,
      };
      io.to(`chat:${data.chatId}`).emit('chat:messages:delivered', deliveryPayload);
      await emitToChatParticipants(
        io,
        data.chatId,
        'chat:messages:delivered',
        deliveryPayload
      );
    } catch (error) {
      emitError(socket, 'chat:delivered', error);
    }
  });

  socket.on('chat:reaction', async (payload) => {
    try {
      if (!(await allowRate(userId, 'reaction', 30, 10000))) {
        throw makeError('Reaction rate limit exceeded', 'RATE_LIMITED', 'RATE_LIMIT');
      }
      logEvent('chat:reaction', userId, payload);
      const data = parseOrThrow(reactToMessageSchema, normalizePayloadOrThrow(payload));
      const chatId = await getChatIdForMessage(data.messageId);
      if (!chatId) throw makeError('Message not found', 'NOT_FOUND', 'NOT_FOUND');

      const reaction = await chatService.reactToMessage(userId, data);

      io.to(`chat:${chatId}`).emit('chat:message:reaction', reaction);
      await emitToChatParticipants(io, chatId, 'chat:message:reaction', reaction);
    } catch (error) {
      emitError(socket, 'chat:reaction', error);
    }
  });

  socket.on('chat:history', async (payload) => {
    try {
      logEvent('chat:history', userId, payload);
      const data = parseOrThrow(historySchema, normalizePayloadOrThrow(payload));
      await ensureParticipant(data.chatId, userId);
      const result = await chatService.listMessages(userId, data);
      socket.emit('chat:history', { chatId: data.chatId, ...result });
    } catch (error) {
      emitError(socket, 'chat:history', error);
    }
  });

  socket.on('chat:participants:add', async (payload) => {
    try {
      logEvent('chat:participants:add', userId, payload);
      const data = parseOrThrow(addParticipantSchema, normalizePayloadOrThrow(payload));
      const chat = await chatService.addParticipant(userId, data);
      io.to(`chat:${data.chatId}`).emit('chat:participants:updated', chat);
      await emitToChatParticipants(
        io,
        data.chatId,
        'chat:participants:updated',
        chat
      );
      io.to(`user:${data.userId}`).emit('chat:invited', {
        chatId: data.chatId,
      });
    } catch (error) {
      emitError(socket, 'chat:participants:add', error);
    }
  });

  socket.on('chat:participants:remove', async (payload) => {
    try {
      logEvent('chat:participants:remove', userId, payload);
      const data = parseOrThrow(removeParticipantSchema, normalizePayloadOrThrow(payload));
      const result = await chatService.removeParticipant(userId, data);
      io.to(`chat:${data.chatId}`).emit('chat:participants:removed', {
        chatId: data.chatId,
        userId: data.userId,
      });
      await emitToChatParticipants(
        io,
        data.chatId,
        'chat:participants:removed',
        { chatId: data.chatId, userId: data.userId }
      );
      io.to(`user:${data.userId}`).emit('chat:removed', {
        chatId: data.chatId,
      });
      socket.emit('chat:participants:remove:ok', result);
      io.to(`user:${data.userId}`).socketsLeave(`chat:${data.chatId}`);
    } catch (error) {
      emitError(socket, 'chat:participants:remove', error);
    }
  });

  socket.on('chat:group:update', async (payload) => {
    try {
      logEvent('chat:group:update', userId, payload);
      const data = parseOrThrow(updateGroupChatSchema, normalizePayloadOrThrow(payload));
      const chat = await chatService.updateGroupChat(userId, data);
      io.to(`chat:${data.chatId}`).emit('chat:updated', chat);
      await emitToChatParticipants(io, data.chatId, 'chat:updated', chat);
    } catch (error) {
      emitError(socket, 'chat:group:update', error);
    }
  });

  socket.on('chat:presence:query', async (payload) => {
    try {
      logEvent('chat:presence:query', userId, payload);
      const data = parseOrThrow(presenceSchema, normalizePayloadOrThrow(payload));
      if (data.chatId) {
        await ensureParticipant(data.chatId, userId);
        const participants = await prisma.chatParticipant.findMany({
          where: { chatId: data.chatId },
          select: { userId: true },
        });
        const statuses = await Promise.all(
          participants.map(async (participant) => {
            const presence = await getPresence(participant.userId);
            return {
              userId: participant.userId,
              status: presence.sockets > 0 ? 'ONLINE' : 'OFFLINE',
              lastSeenAt: presence.lastSeenAt || null,
            };
          })
        );
        socket.emit('chat:presence:state', {
          chatId: data.chatId,
          users: statuses,
        });
        return;
      }
      socket.emit('chat:presence:state', { chatId: null, users: [] });
    } catch (error) {
      emitError(socket, 'chat:presence:query', error);
    }
  });

  socket.on('chat:typing:query', async (payload) => {
    try {
      logEvent('chat:typing:query', userId, payload);
      const data = parseOrThrow(typingStateSchema, normalizePayloadOrThrow(payload));
      await ensureParticipant(data.chatId, userId);
      const participants = await prisma.chatParticipant.findMany({
        where: { chatId: data.chatId },
        select: { userId: true },
      });
      const userIds = participants.map((participant) => participant.userId);
      const typingUsers = await getTypingUsers(data.chatId, userIds);
      socket.emit('chat:typing:state', {
        chatId: data.chatId,
        users: typingUsers,
      });
    } catch (error) {
      emitError(socket, 'chat:typing:query', error);
    }
  });
}

module.exports = registerChatHandlers;
