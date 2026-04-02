const express = require('express');
const router = express.Router();

const userController = require('./user.controller');
const validateRequest = require('../../middlewares/validateRequest');
const authenticate = require('../../middlewares/authMiddleware');
const {
  uploadProfileImage,
  attachUploadedProfileImage,
} = require('../../middlewares/profileImageUpload');

const {
  createUserSchema,
  updateUserSchema,
  upsertUserSchema,
  checkUsernameSchema,
  checkUsernameParamsSchema,
  
} = require('./user.schema');

// ======================
//  ROUTES
// ======================

router.use(authenticate);

router.get(
  '/username-availability',
  validateRequest(checkUsernameSchema, 'query'),
  userController.checkUsernameAvailability
);

router.get(
  '/username/:username/available',
  validateRequest(checkUsernameParamsSchema, 'params'),
  userController.checkUsernameAvailableSimple
);

router.get('/profiles/username/:username', userController.searchUsernames);

router.post(
  '/profile',
  uploadProfileImage,
  attachUploadedProfileImage,
  validateRequest(upsertUserSchema),
  userController.createUserProfile
);

router.get('/profile', userController.getUserProfile);

router.patch(
  '/profile',
  uploadProfileImage,
  attachUploadedProfileImage,
  validateRequest(updateUserSchema),
  userController.updateUserProfile
);

router.post(
  '/profile/image',
  uploadProfileImage,
  attachUploadedProfileImage,
  userController.updateProfileImage
);

router.delete('/profile', userController.deleteUserProfile);

module.exports = router;
