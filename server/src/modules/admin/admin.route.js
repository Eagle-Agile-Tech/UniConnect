const express = require('express');

const adminController = require('./admin.controller');
const validateRequest = require('../../middlewares/validateRequest');
const authenticate = require('../../middlewares/authMiddleware');
const adminAuthorization = require('../../middlewares/adminAuthorization');
const asyncHandler = require('../../middlewares/asyncHandler');
const { uploadProfileImage } = require('../../middlewares/profileImageUpload');
const {
  createAdminSchema,
  loginAdminSchema,
  refreshTokenSchema,
  logoutSchema,
  moderateContentSchema,
  updateAdminProfileSchema,
  moderationQueueSchema,
  listUserProfilesSchema,
  paginationSchema,
  verifyAccountSchema,
} = require('./admin.schema');

const router = express.Router();

router.post('/login', validateRequest(loginAdminSchema), asyncHandler(adminController.loginAdmin));
router.post('/refresh', validateRequest(refreshTokenSchema), asyncHandler(adminController.refreshToken));
router.post('/logout', validateRequest(logoutSchema), asyncHandler(adminController.logout));

router.post(
  '/create',
  authenticate,
  adminAuthorization,
  uploadProfileImage,
  validateRequest(createAdminSchema),
  asyncHandler(adminController.createAdmin)
);
router.patch(
  '/users/:userId/verify',
  authenticate,
  adminAuthorization,
  validateRequest(verifyAccountSchema),
  asyncHandler(adminController.verifyAccount)
);

router.get('/profile', authenticate, adminAuthorization, asyncHandler(adminController.getProfile));
router.patch(
  '/profile',
  authenticate,
  adminAuthorization,
  uploadProfileImage,
  validateRequest(updateAdminProfileSchema),
  asyncHandler(adminController.updateProfile)
);

router.post(
  '/moderation',
  authenticate,
  adminAuthorization,
  validateRequest(moderateContentSchema),
  asyncHandler(adminController.moderateContent)
);
router.get(
  '/moderation/queue',
  authenticate,
  adminAuthorization,
  validateRequest(moderationQueueSchema, 'query'),
  asyncHandler(adminController.getModerationQueue)
);

router.get(
  '/users/unverified',
  authenticate,
  adminAuthorization,
  validateRequest(paginationSchema, 'query'),
  asyncHandler(adminController.getUnverifiedUsers)
);
router.get(
  '/profiles',
  authenticate,
  adminAuthorization,
  validateRequest(listUserProfilesSchema, 'query'),
  asyncHandler(adminController.listUserProfiles)
);
router.get(
  '/dashboard/stats',
  authenticate,
  adminAuthorization,
  asyncHandler(adminController.getDashboardStats)
);

module.exports = router;
