const express = require('express');
const router = express.Router();

const chatController = require('./chat.controller');
const validateRequest = require('../../middlewares/validateRequest');
const authenticate = require('../../middlewares/authMiddleware');

const {
  createChatSchema,
  createSendMessageSchema,
  updateMessageSchema,
  deleteMessageSchema,
  typingSchema,
  markAsReadSchema,
  markAsDeliveredSchema,
  addParticipantSchema,
  removeParticipantSchema,
  updateGroupChatSchema,
  listChatsSchema,
  listMessagesSchema,
  reactToMessageSchema,
} = require('./chat.schema');

router.use(authenticate);

router.post('/', validateRequest(createChatSchema), chatController.createChat);
router.get('/', validateRequest(listChatsSchema, 'query'), chatController.listChats);
router.patch('/', validateRequest(updateGroupChatSchema), chatController.updateGroupChat);

router.post(
  '/participants',
  validateRequest(addParticipantSchema),
  chatController.addParticipant
);
router.delete(
  '/participants',
  validateRequest(removeParticipantSchema),
  chatController.removeParticipant
);

router.get(
  '/messages',
  validateRequest(listMessagesSchema, 'query'),
  chatController.listMessages
);
router.post(
  '/messages',
  validateRequest(createSendMessageSchema),
  chatController.sendMessage
);
router.patch(
  '/messages',
  validateRequest(updateMessageSchema),
  chatController.updateMessage
);
router.delete(
  '/messages',
  validateRequest(deleteMessageSchema),
  chatController.deleteMessage
);

router.post(
  '/messages/reactions',
  validateRequest(reactToMessageSchema),
  chatController.reactToMessage
);

router.post('/read', validateRequest(markAsReadSchema), chatController.markAsRead);
router.post(
  '/delivered',
  validateRequest(markAsDeliveredSchema),
  chatController.markAsDelivered
);
router.post('/typing', validateRequest(typingSchema), chatController.typing);
router.get('/:otherUserId', chatController.getChatIdFromUserIds);
 

module.exports = router;
