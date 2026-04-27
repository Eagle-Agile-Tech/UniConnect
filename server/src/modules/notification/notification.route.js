const express = require('express');
const router = express.Router();

const notificationController = require('./notification.controller');
const validateRequest = require('../../middlewares/validateRequest');
const authenticate = require('../../middlewares/authMiddleware');
const {
  createNotificationSchema,
  listNotificationsQuerySchema,
  notificationIdParamSchema,
  updateDeviceTokenSchema,
} = require('./notification.schema');

router.use(authenticate);

router.get(
  '/',
  validateRequest(listNotificationsQuerySchema, 'query'),
  notificationController.getNotifications
);
router.get('/unread-count', notificationController.getUnreadCount);
router.post(
  '/',
  validateRequest(createNotificationSchema),
  notificationController.sendNotification
);
router.put(
  '/device-token',
  validateRequest(updateDeviceTokenSchema),
  notificationController.updateDeviceToken
);
router.patch('/read-all', notificationController.markAllAsRead);
router.patch(
  '/:id/read',
  validateRequest(notificationIdParamSchema, 'params'),
  notificationController.markAsRead
);

module.exports = router;
