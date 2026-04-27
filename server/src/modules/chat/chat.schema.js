const zod = require('zod');

const uuidSchema = zod.string().uuid();

const chatTypeEnum = zod.enum(['DIRECT', 'GROUP']);
const reactionTypeEnum = zod.enum([
  'LIKE',
  'LOVE',
  'INSIGHTFUL',
  'SUPPORT',
  'CELEBRATE',
]);

const createDirectChatSchema = zod
  .object({
    type: zod.literal('DIRECT'),
    participantId: uuidSchema,
  })
  .strict();

const createGroupChatSchema = zod
  .object({
    type: zod.literal('GROUP'),
    name: zod.string().min(1).max(100),
    participantIds: zod.array(uuidSchema).min(1).max(50),
    avatarUrl: zod.string().url().optional(),
  })
  .strict();

const createChatSchema = zod.discriminatedUnion('type', [
  createDirectChatSchema,
  createGroupChatSchema,
]);

const createSendMessageSchema = zod
  .object({
    chatId: uuidSchema,
    content: zod.string().min(1).max(2000).optional(),
    mediaIds: zod.array(uuidSchema).min(1).max(10).optional(),
    clientMessageId: zod.string().min(8).max(64).optional(),
  })
  .strict()
  .superRefine((data, ctx) => {
    if (!data.content && !data.mediaIds) {
      ctx.addIssue({
        code: zod.ZodIssueCode.custom,
        message: 'content or mediaIds is required',
        path: ['content'],
      });
    }
  });

const updateMessageSchema = zod
  .object({
    messageId: uuidSchema,
    content: zod.string().min(1).max(2000),
  })
  .strict();

const deleteMessageSchema = zod
  .object({
    messageId: uuidSchema,
  })
  .strict();

const typingSchema = zod
  .object({
    chatId: uuidSchema,
    isTyping: zod.boolean(),
  })
  .strict();

const typingStateSchema = zod
  .object({
    chatId: uuidSchema,
  })
  .strict();

const markAsReadSchema = zod
  .object({
    chatId: uuidSchema,
    messageId: uuidSchema.optional(),
  })
  .strict();

const markAsDeliveredSchema = zod
  .object({
    chatId: uuidSchema,
    messageId: uuidSchema.optional(),
  })
  .strict();

const addParticipantSchema = zod
  .object({
    chatId: uuidSchema,
    userId: uuidSchema,
  })
  .strict();

const removeParticipantSchema = zod
  .object({
    chatId: uuidSchema,
    userId: uuidSchema,
  })
  .strict();

const updateGroupChatSchema = zod
  .object({
    chatId: uuidSchema,
    name: zod.string().min(1).max(100).optional(),
    avatarUrl: zod.string().url().optional(),
  })
  .strict()
  .superRefine((data, ctx) => {
    if (!data.name && !data.avatarUrl) {
      ctx.addIssue({
        code: zod.ZodIssueCode.custom,
        message: 'name or avatarUrl is required',
        path: ['name'],
      });
    }
  });

const listChatsSchema = zod
  .object({
    limit: zod.coerce.number().int().min(1).max(50).default(20),
    offset: zod.coerce.number().int().min(0).default(0),
    type: chatTypeEnum.optional(),
  })
  .strict();

const listMessagesSchema = zod
  .object({
    chatId: uuidSchema,
    limit: zod.coerce.number().int().min(1).max(100).default(50),
    offset: zod.coerce.number().int().min(0).default(0),
    search: zod.string().min(1).max(200).optional(),
  })
  .strict();

const historySchema = zod
  .object({
    chatId: uuidSchema,
    limit: zod.coerce.number().int().min(1).max(100).default(50),
    offset: zod.coerce.number().int().min(0).default(0),
    search: zod.string().min(1).max(200).optional(),
  })
  .strict();

const presenceSchema = zod
  .object({
    chatId: uuidSchema.optional(),
  })
  .strict();

const reactToMessageSchema = zod
  .object({
    messageId: uuidSchema,
    type: reactionTypeEnum,
  })
  .strict();

module.exports = {
  createChatSchema,
  createDirectChatSchema,
  createGroupChatSchema,
  createSendMessageSchema,
  updateMessageSchema,
  deleteMessageSchema,
  typingSchema,
  typingStateSchema,
  markAsReadSchema,
  markAsDeliveredSchema,
  addParticipantSchema,
  removeParticipantSchema,
  updateGroupChatSchema,
  listChatsSchema,
  listMessagesSchema,
  historySchema,
  reactToMessageSchema,
  presenceSchema,
};
