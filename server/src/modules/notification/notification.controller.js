const notificationService = require("./notification.service");
const asyncHandler = require("../../middlewares/asyncHandler");

const sendNotification = asyncHandler(async (req, res) => {
  const { recipientId, actorId, type, referenceId, referenceType, title, body, data } = req.body;
  const notification = await notificationService.createAndSendNotification({
    recipientId,
    actorId,
    type,
    referenceId,
    referenceType,
    title,
    body,
    data,
  });

  res.status(201).json({ success: true, notification });
});

const getNotifications = asyncHandler(async (req, res) => {
  const notifications = await notificationService.getNotificationsForUser(req.user.id, req.query);
  const unreadCount = await notificationService.getUnreadCount(req.user.id);
  res.json({ success: true, notifications, unreadCount });
});

const getUnreadCount = asyncHandler(async (req, res) => {
  const unreadCount = await notificationService.getUnreadCount(req.user.id);
  res.json({ success: true, unreadCount });
});

const markAsRead = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const notification = await notificationService.markAsRead(id, req.user.id);
  res.json({ success: true, notification });
});

const markAllAsRead = asyncHandler(async (req, res) => {
  const updatedCount = await notificationService.markAllAsRead(req.user.id);
  res.json({ success: true, updatedCount });
});

const updateDeviceToken = asyncHandler(async (req, res) => {
  const device = await notificationService.updateDeviceToken(req.user.id, req.body.fcmToken);
  res.json({
    success: true,
    device: {
      id: device.id,
      hasToken: Boolean(device.fcmToken),
    },
  });
});

module.exports = {
  sendNotification,
  getNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
  updateDeviceToken,
};
