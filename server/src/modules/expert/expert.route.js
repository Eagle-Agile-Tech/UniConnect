const express = require('express');

const expertController = require('./expert.controller');
const validateRequest = require('../../middlewares/validateRequest');
const authenticate = require('../../middlewares/authMiddleware');
const {
  uploadProfileImage,
  attachUploadedProfileImage,
} = require('../../middlewares/profileImageUpload');
const { loginSchema } = require('../auth/auth.schema');
const {
  acceptExpertInvitationSchema,
  joinInstitutionSchema,
  updateExpertProfileSchema,
} = require('./expert.schema');

const router = express.Router();

// Support token being sent via query string (e.g. /expert/invite/accept?token=...)
// while other fields (firstName/lastName/password) are sent in the request body.
function attachTokenFromQuery(req, res, next) {
  if (!req.body?.token && req.query?.token) {
    req.body = { ...req.body, token: req.query.token };
  }
  next();
}

router.post(
  '/login',
  validateRequest(loginSchema),
  expertController.login
);

router.post(
  '/invite/accept',
  attachTokenFromQuery,
  validateRequest(acceptExpertInvitationSchema),
  expertController.acceptInvitation
);

router.post(
  '/join',
  validateRequest(joinInstitutionSchema),
  expertController.joinInstitution
);

router.use(authenticate);

router.get('/profile', expertController.getProfile);

router.patch(
  '/profile',
  uploadProfileImage,
  attachUploadedProfileImage,
  validateRequest(updateExpertProfileSchema),
  expertController.updateProfile
);

router.delete('/profile', expertController.deleteProfile);

module.exports = router;
