const express = require('express');
const router = express.Router();

const authController = require('./auth.controller');
const validateRequest = require('../../middlewares/validateRequest');
const authenticate = require('../../middlewares/authMiddleware');
const { uploadIdVerificationDocument, attachUploadedDocumentImage } = require('../../middlewares/idVerificationUpload');
const {
  registerSchema,
  loginSchema,
  verifyOtpSchema,
  resendOtpSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  refreshTokenSchema,
  googleLoginSchema,
  microsoftLoginSchema,
  submitIdVerificationSchema,
  logoutSchema,
} = require('./auth.schema');

// ======================
// AUTH ROUTES
// ======================

// Register with university email
router.post('/register', validateRequest(registerSchema), authController.register);

// Login with email/password
router.post('/login', validateRequest(loginSchema), authController.login);

// Google OAuth login
router.post('/google', validateRequest(googleLoginSchema), authController.googleLogin);

// Microsoft OAuth login
router.post('/microsoft', validateRequest(microsoftLoginSchema), authController.microsoftLogin);

// Verify OTP
router.post('/verify-otp', validateRequest(verifyOtpSchema), authController.verifyOtp);

// Resend OTP
router.post(
  '/resend-otp',
  validateRequest(resendOtpSchema),
  authController.resendOtp
);

// Forgot password (issue reset OTP)
router.post('/forgot-password', validateRequest(forgotPasswordSchema), authController.forgotPassword);

// Reset password with OTP
router.post('/reset-password', validateRequest(resetPasswordSchema), authController.resetPassword);

// Refresh access token
router.post('/refresh', validateRequest(refreshTokenSchema), authController.refresh);

// Logout (invalidate session)
router.post('/logout', validateRequest(logoutSchema, 'query'), authController.logout);


// ======================
// MANUAL STUDENT VERIFICATION
// ======================

// Submit university ID for verification
router.post(
  '/verify-id',
  authenticate,
  uploadIdVerificationDocument,
  attachUploadedDocumentImage,
  validateRequest(submitIdVerificationSchema),
  authController.submitIdVerification
);


// ======================
// ADMIN ROUTES
// ======================

// Get pending ID verification requests
// router.get('/admin/verifications', authController.getPendingVerifications);

// // Approve or reject verification
// router.post('/admin/verifications/review', authController.reviewVerification);


module.exports = router;
