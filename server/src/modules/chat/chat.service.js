const prisma = require('../../lib/prisma');
const {
  BadRequestError,
  ConflictError,
  ForbiddenError,
  NotFoundError,
} = require('../../errors');

const userSelect = {
  id: true,
  firstName: true,
  lastName: true,
  profile: {
    select: {
      username: true,
      fullName: true,
      profileImage: true,
    },
  },
};

const chatInclude = {
  participants: {
    include: {
      user: {
        select: userSelect,
      },
    },
  },
  messages: {
    orderBy: { createdAt: 'asc' },
    include: {
      sender: { select: userSelect },
      media: true,
      receipts: {
        select: {
          userId: true,
          deliveredAt: true,
          readAt: true,
        },
      },
    },
  },
};

function getDisplayName(user) {
  const profileName = user?.profile?.fullName?.trim();
  if (profileName) return profileName;

  const derivedName = [user?.firstName, user?.lastName]
    .filter(Boolean)
    .join(' ')
    .trim();
  if (derivedName) return derivedName;

  const username = user?.profile?.username?.trim();
  if (username) return username;

  return user?.id ?? '';
}

function formatChatUser(user) {
  if (!user) return user;

  return {
    ...user,
    name: getDisplayName(user),
    avatarUrl: user.profile?.profileImage ?? null,
  };
}

function formatChatMessage(message) {
  if (!message) return message;

  return {
    ...message,
    sender: formatChatUser(message.sender),
  };
}

function formatChat(chat, { latestFirst = false } = {}) {
  if (!chat) return chat;

  const participants = (chat.participants || []).map((participant) => ({
    ...participant,
    user: formatChatUser(participant.user),
  }));

  const messages = (chat.messages || []).map(formatChatMessage);
  if (latestFirst) {
    messages.sort(
      (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
    );
  }

  return {
    ...chat,
    participants,
    messages,
    _count: {
      messages: messages.length,
    },
  };
}

function normalizePagination(data, defaults = { limit: 50, offset: 0 }) {
  const limit = Number.isInteger(data.limit)
    ? data.limit
    : Number(data.limit ?? defaults.limit);
  const offset = Number.isInteger(data.offset)
    ? data.offset
    : Number(data.offset ?? defaults.offset);

  if (!Number.isInteger(limit) || limit < 1) {
    throw new BadRequestError('Invalid pagination limit');
  }
  if (!Number.isInteger(offset) || offset < 0) {
    throw new BadRequestError('Invalid pagination offset');
  }

  return { limit, offset };
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
    throw new ForbiddenError('You are not a participant of this chat');
  }

  return participant;
}

async function ensureUserExists(userId) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { id: true },
  });

  if (!user) {
    throw new NotFoundError('User not found');
  }

  return user;
}

class ChatService {
  async createChat(userId, data) {
    if (data.type === 'DIRECT') {
      if (data.participantId === userId) {
        throw new BadRequestError('Cannot start a direct chat with yourself');
      }

      await ensureUserExists(data.participantId);

      const [a, b] = [userId, data.participantId].sort();
      const uniqueKey = `direct:${a}:${b}`;

      const existing = await prisma.chat.findUnique({
        where: { uniqueKey },
        include: chatInclude,
      });
      if (existing) return formatChat(existing, { latestFirst: true });

      const chat = await prisma.chat.create({
        data: {
          type: 'DIRECT',
          uniqueKey,
          participants: {
            createMany: {
              data: [{ userId }, { userId: data.participantId }],
            },
          },
        },
        include: chatInclude,
      });

      return formatChat(chat, { latestFirst: true });
    }

    if (data.type === 'GROUP') {
      const name = data.name?.trim();
      if (!name) {
        throw new BadRequestError('Group name is required');
      }
      const existingGroup = await prisma.chat.findFirst({
        where: {
          type: 'GROUP',
          name: {
            equals: name,
            mode: 'insensitive',
          },
        },
        select: { id: true },
      });
      if (existingGroup) {
        throw new ConflictError('Group name already exists');
      }

      const participantIds = Array.from(
        new Set([userId, ...(data.participantIds || [])])
      );

      const chat = await prisma.chat.create({
        data: {
          type: 'GROUP',
          name,
          avatarUrl: data.avatarUrl,
          createdById: userId,
          participants: {
            createMany: {
              data: participantIds.map((participantId) => ({
                userId: participantId,
              })),
            },
          },
        },
        include: chatInclude,
      });

      return formatChat(chat, { latestFirst: true });
    }

    throw new BadRequestError('Invalid chat type');
  }

async getChatIdFromUserIds(userId, otherUserId, query = {}) {
  if (!otherUserId) {
    throw new BadRequestError('otherUserId is required');
  }

  if (otherUserId === userId) {
    throw new BadRequestError('Cannot create or fetch a direct chat with yourself');
  }

  // Ensure the other user exists
  await ensureUserExists(otherUserId);

  // Create unique key
  const [a, b] = [userId, otherUserId].sort();
  const uniqueKey = `direct:${a}:${b}`;

  // Find or create chat
  let chat = await prisma.chat.findUnique({
    where: { uniqueKey },
    include: {
      participants: {
        include: {
          user: { select: userSelect },
        },
      },
    },
  });

  if (!chat) {
    chat = await prisma.chat.create({
      data: {
        type: 'DIRECT',
        uniqueKey,
        participants: {
          createMany: {
            data: [{ userId }, { userId: otherUserId }],
          },
        },
      },
      include: {
        participants: {
          include: {
            user: { select: userSelect },
          },
        },
      },
    });
  }

  //  Pagination
  const { limit, offset } = normalizePagination(query, {
    limit: 50,
    offset: 0,
  });

  //  Fetch messages separately
  const messages = await prisma.message.findMany({
    where: { chatId: chat.id },
    orderBy: { createdAt: 'desc' }, // latest first
    skip: offset,
    take: limit,
    include: {
      sender: { select: userSelect },
      media: true,
      receipts: {
        select: {
          userId: true,
          deliveredAt: true,
          readAt: true,
        },
      },
    },
  });

  return {
    chatId: chat.id,

    participants: chat.participants.map((p) => ({
      ...p,
      user: formatChatUser(p.user),
    })),

    messages: messages.map(formatChatMessage),

    pagination: {
      limit,
      offset,
      hasMore: messages.length === limit,
    },
  };
}
  async getChatIdFromUserId(userId, otherUserId) {
    return this.getChatIdFromUserIds(userId, otherUserId);
  }

  async listChats(userId, query) {
    const where = {
      participants: {
        some: { userId },
      },
    };

    if (query.type) {
      where.type = query.type;
    }

    const { limit, offset } = normalizePagination(query, { limit: 20, offset: 0 });

    const chats = await prisma.chat.findMany({
      where,
      skip: offset,
      take: limit,
      orderBy: { updatedAt: 'desc' },
      include: chatInclude,
    });

    return { chats: chats.map((chat) => formatChat(chat, { latestFirst: true })) };
  }

  async updateGroupChat(userId, data) {
    const chat = await prisma.chat.findUnique({
      where: { id: data.chatId },
    });

    if (!chat) throw new NotFoundError('Chat not found');
    if (chat.type !== 'GROUP') {
      throw new BadRequestError('Only group chats can be updated');
    }
    if (chat.createdById && chat.createdById !== userId) {
      throw new ForbiddenError('Only the group creator can update the chat');
    }

    const updated = await prisma.chat.update({
      where: { id: chat.id },
      data: {
        name: data.name ?? undefined,
        avatarUrl: data.avatarUrl ?? undefined,
      },
      include: chatInclude,
    });

    return formatChat(updated, { latestFirst: true });
  }

  async addParticipant(userId, data) {
    const chat = await prisma.chat.findUnique({
      where: { id: data.chatId },
    });
    if (!chat) throw new NotFoundError('Chat not found');
    if (chat.type !== 'GROUP') {
      throw new BadRequestError('Participants can only be added to group chats');
    }

    if (chat.createdById && chat.createdById !== userId) {
      throw new ForbiddenError('Only the group creator can add participants');
    }

    if (data.userId === userId) {
      throw new BadRequestError('You are already a participant');
    }

    const existing = await prisma.chatParticipant.findUnique({
      where: {
        chatId_userId: {
          chatId: data.chatId,
          userId: data.userId,
        },
      },
    });

    if (existing) {
      throw new ConflictError('User is already a participant');
    }

    await prisma.chatParticipant.create({
      data: {
        chatId: data.chatId,
        userId: data.userId,
      },
    });

    const updatedChat = await prisma.chat.findUnique({
      where: { id: data.chatId },
      include: chatInclude,
    });

    return formatChat(updatedChat, { latestFirst: true });
  }

  async removeParticipant(userId, data) {
    const chat = await prisma.chat.findUnique({
      where: { id: data.chatId },
    });
    if (!chat) throw new NotFoundError('Chat not found');
    if (chat.type !== 'GROUP') {
      throw new BadRequestError('Participants can only be removed from group chats');
    }

    const isSelfRemoval = data.userId === userId;
    if (!isSelfRemoval && chat.createdById && chat.createdById !== userId) {
      throw new ForbiddenError('Only the group creator can remove participants');
    }

    const existing = await prisma.chatParticipant.findUnique({
      where: {
        chatId_userId: {
          chatId: data.chatId,
          userId: data.userId,
        },
      },
    });

    if (!existing) {
      throw new NotFoundError('Participant not found');
    }

    await prisma.chatParticipant.delete({
      where: {
        chatId_userId: {
          chatId: data.chatId,
          userId: data.userId,
        },
      },
    });

    const refreshedChat = await prisma.chat.findUnique({
      where: { id: data.chatId },
      include: chatInclude,
    });

    return formatChat(refreshedChat, { latestFirst: true });
  }

  async listMessages(userId, data) {
    await ensureParticipant(data.chatId, userId);

    const { limit, offset } = normalizePagination(data, { limit: 50, offset: 0 });

    const messages = await prisma.message.findMany({
      where: {
        chatId: data.chatId,
        ...(data.search
          ? {
              content: {
                contains: data.search,
                mode: 'insensitive',
              },
            }
          : {}),
      },
      orderBy: { createdAt: 'desc' },
      skip: offset,
      take: limit,
      include: {
        sender: { select: userSelect },
        media: true,
        receipts: {
          select: {
            userId: true,
            deliveredAt: true,
            readAt: true,
          },
        },
        messageReactions: {
          include: {
            user: { select: userSelect },
          },
        },
      },
    });

    return { messages };
  }

  async sendMessage(userId, data) {
    await ensureParticipant(data.chatId, userId);

    if (data.mediaIds && data.mediaIds.length > 0) {
      const mediaCount = await prisma.media.count({
        where: {
          id: { in: data.mediaIds },
          uploaderId: userId,
        },
      });
      if (mediaCount !== data.mediaIds.length) {
        throw new ForbiddenError('One or more attachments are not available');
      }
    }

    if (data.clientMessageId) {
      const existing = await prisma.message.findFirst({
        where: {
          senderId: userId,
          clientMessageId: data.clientMessageId,
        },
        include: {
          sender: { select: userSelect },
          media: true,
          receipts: {
            select: {
              userId: true,
              deliveredAt: true,
              readAt: true,
            },
          },
        },
      });
      if (existing) {
        return { ...existing, duplicate: true };
      }
    }

    const message = await prisma.$transaction(async (tx) => {
      const created = await tx.message.create({
        data: {
          chatId: data.chatId,
          senderId: userId,
          content: data.content || '',
          clientMessageId: data.clientMessageId || null,
          media: data.mediaIds
            ? {
                connect: data.mediaIds.map((id) => ({ id })),
              }
            : undefined,
        },
        include: {
          sender: { select: userSelect },
          media: true,
        },
      });

      const participants = await tx.chatParticipant.findMany({
        where: { chatId: data.chatId },
        select: { userId: true },
      });

      const receiptData = participants
        .filter((participant) => participant.userId !== userId)
        .map((participant) => ({
          messageId: created.id,
          userId: participant.userId,
        }));

      if (receiptData.length > 0) {
        await tx.messageReceipt.createMany({ data: receiptData });
      }

      await tx.chat.update({
        where: { id: data.chatId },
        data: { updatedAt: new Date() },
      });

      return created;
    });

    const withReceipts = await prisma.message.findUnique({
      where: { id: message.id },
      include: {
        sender: { select: userSelect },
        media: true,
        receipts: {
          select: {
            userId: true,
            deliveredAt: true,
            readAt: true,
          },
        },
      },
    });

    return withReceipts;
  }

  async updateMessage(userId, data) {
    const message = await prisma.message.findUnique({
      where: { id: data.messageId },
    });

    if (!message) throw new NotFoundError('Message not found');
    if (message.senderId !== userId) {
      throw new ForbiddenError('You can only edit your own messages');
    }

    return prisma.message.update({
      where: { id: data.messageId },
      data: { content: data.content },
      include: {
        sender: { select: userSelect },
        media: true,
      },
    });
  }

  async deleteMessage(userId, data) {
    const message = await prisma.message.findUnique({
      where: { id: data.messageId },
    });

    if (!message) throw new NotFoundError('Message not found');
    if (message.senderId !== userId) {
      const user = await prisma.user.findUnique({
        where: { id: userId },
        select: { role: true },
      });
      if (!user || user.role !== 'ADMIN') {
        throw new ForbiddenError('You can only delete your own messages');
      }
    }

    await prisma.message.update({
      where: { id: data.messageId },
      data: { isDeleted: true },
    });

    return { message: 'Message deleted' };
  }

  async markAsRead(userId, data) {
    await ensureParticipant(data.chatId, userId);

    let readAt = new Date();
    if (data.messageId) {
      const message = await prisma.message.findFirst({
        where: { id: data.messageId, chatId: data.chatId },
        select: { createdAt: true },
      });
      if (!message) throw new NotFoundError('Message not found');
      readAt = message.createdAt;
    }

    await prisma.chatParticipant.update({
      where: {
        chatId_userId: {
          chatId: data.chatId,
          userId,
        },
      },
      data: { lastReadAt: readAt },
    });

    await prisma.messageReceipt.updateMany({
      where: {
        userId,
        readAt: null,
        message: {
          chatId: data.chatId,
          createdAt: { lte: readAt },
        },
      },
      data: { readAt },
    });

    return { message: 'Chat marked as read' };
  }

  async markAsDelivered(userId, data) {
    await ensureParticipant(data.chatId, userId);

    let deliveredAt = new Date();
    if (data.messageId) {
      const message = await prisma.message.findFirst({
        where: { id: data.messageId, chatId: data.chatId },
        select: { createdAt: true },
      });
      if (!message) throw new NotFoundError('Message not found');
      deliveredAt = message.createdAt;
    }

    const receipts = await prisma.messageReceipt.findMany({
      where: {
        userId,
        deliveredAt: null,
        message: {
          chatId: data.chatId,
          createdAt: { lte: deliveredAt },
        },
      },
      select: { messageId: true },
    });

    await prisma.messageReceipt.updateMany({
      where: {
        userId,
        deliveredAt: null,
        message: {
          chatId: data.chatId,
          createdAt: { lte: deliveredAt },
        },
      },
      data: { deliveredAt },
    });

    return {
      messageIds: receipts.map((receipt) => receipt.messageId),
      deliveredAt,
    };
  }

  async reactToMessage(userId, data) {
    const message = await prisma.message.findUnique({
      where: { id: data.messageId },
      select: { id: true, chatId: true },
    });

    if (!message) throw new NotFoundError('Message not found');
    await ensureParticipant(message.chatId, userId);

    const reaction = await prisma.messageReaction.upsert({
      where: {
        userId_messageId: {
          userId,
          messageId: data.messageId,
        },
      },
      create: {
        userId,
        messageId: data.messageId,
        type: data.type,
      },
      update: {
        type: data.type,
      },
      include: {
        user: { select: userSelect },
      },
    });

    return reaction;
  }
}

module.exports = new ChatService();
