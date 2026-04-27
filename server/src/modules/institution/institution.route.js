const express = require('express');

const institutionController = require('./institution.controller');
const validateRequest = require('../../middlewares/validateRequest');
const authenticate = require('../../middlewares/authMiddleware');
const adminAuthorization = require('../../middlewares/adminAuthorization');
const {
  uploadInstitutionVerificationDocument,
  attachUploadedInstitutionDocument,
} = require('../../middlewares/institutionVerificationUpload');

const {
  registerInstitutionSchema,
  verifyInstitutionOtpSchema,
  resendInstitutionOtpSchema,
  updateInstitutionSchema,
  institutionIdParamSchema,
  loginInstitutionSchema,
  submitInstitutionVerificationSchema,
  verifyInstitutionSchema,
  regenerateSecretCodeSchema,
  inviteExpertSchema,
  acceptExpertInvitationSchema,
  joinInstitutionSchema,
  listInstitutionsSchema,
} = require('./institution.schema');

const router = express.Router();

router.post(
  '/',
  validateRequest(registerInstitutionSchema),
  institutionController.registerInstitution
);
router.post(
  '/verify-otp',
  validateRequest(verifyInstitutionOtpSchema),
  institutionController.verifyInstitutionOtp
);
router.post(
  '/resend-otp',
  validateRequest(resendInstitutionOtpSchema),
  institutionController.resendInstitutionOtp
);
router.get('/', validateRequest(listInstitutionsSchema, 'query'), institutionController.listInstitutions);
router.get(
  '/:institutionId',
  validateRequest(institutionIdParamSchema, 'params'),
  institutionController.getInstitution
);
router.patch(
  '/:institutionId',
  authenticate,
  validateRequest(institutionIdParamSchema, 'params'),
  validateRequest(updateInstitutionSchema),
  institutionController.updateInstitution
);

router.post('/login', validateRequest(loginInstitutionSchema), institutionController.loginInstitution);

router.post(
  '/:institutionId/verification',
  authenticate,
  uploadInstitutionVerificationDocument,
  attachUploadedInstitutionDocument,
  validateRequest(institutionIdParamSchema, 'params'),
  validateRequest(submitInstitutionVerificationSchema),
  institutionController.submitVerification
);

router.patch(
  '/:institutionId/verification',
  authenticate,
  adminAuthorization,
  validateRequest(institutionIdParamSchema, 'params'),
  validateRequest(verifyInstitutionSchema),
  institutionController.verifyInstitution
);

router.post(
  '/:institutionId/secret-code',
  authenticate,
  validateRequest(institutionIdParamSchema, 'params'),
  validateRequest(regenerateSecretCodeSchema),
  institutionController.regenerateSecretCode
);

router.post(
  '/experts/invite',
  authenticate,
  validateRequest(inviteExpertSchema),
  institutionController.inviteExpert
);


module.exports = router;
