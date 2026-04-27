const zod = require("zod");

const createNotificationSchema = zod.object({
  recipientId: zod.string(),
  actorId: zod.string().optional(),
  type: zod.string(),
  referenceId: zod.string().optional(),
  referenceType: zod.string().optional(),
  title: zod.string(),
  body: zod.string(),
  data: zod.any().optional()
});

const listNotificationsQuerySchema = zod.object({
  limit: zod.coerce.number().int().min(1).max(100).optional(),
  unreadOnly: zod
    .union([zod.boolean(), zod.enum(["true", "false"])])
    .optional()
    .transform((value) => value === true || value === "true"),
});

const notificationIdParamSchema = zod.object({
  id: zod.string().uuid(),
});

const updateDeviceTokenSchema = zod.object({
  fcmToken: zod.string().trim().min(1).max(4096).nullable(),
});

module.exports = {
  createNotificationSchema,
  listNotificationsQuerySchema,
  notificationIdParamSchema,
  updateDeviceTokenSchema,
};
