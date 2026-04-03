// server/src/modules/engagement/utils/notification.helper.js
class NotificationHelper {
  /**
   * Create a notification
   */
  async createNotification({
    recipientId,
    actorId,
    type,
    referenceId,
    referenceType,
    tx,
  }) {
    // Use the transaction if provided, otherwise use regular prisma
    const prisma = tx || require("../../../lib/prisma");

    // Don't notify if actor is the same as recipient
    if (recipientId === actorId) {
      return null;
    }

    return prisma.notification.create({
      data: {
        recipientId,
        actorId,
        type,
        referenceId,
        referenceType,
      },
    });
  }

  /**
   * Create bulk notifications (e.g., for mentions)
   */
  async createBulkNotifications(notifications, tx) {
    const prisma = tx || require("../../../lib/prisma");

    const validNotifications = notifications.filter(
      (n) => n.recipientId !== n.actorId,
    );

    if (validNotifications.length === 0) {
      return [];
    }

    return prisma.notification.createMany({
      data: validNotifications,
    });
  }
}

module.exports = new NotificationHelper();
