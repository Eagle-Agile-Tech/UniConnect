const authService = require('./auth.service');

class AuthController {

  // ========================
  // REGISTER
  // ========================
  async register(req, res, next) {
    try {

      const result = await authService.register(req.body);

      res.status(201).json(result);

    } catch (err) {
      next(err);
    }
  }

  // ========================
  // LOGIN
  // ========================
  async login(req, res, next) {
    try {

      const deviceInfo = {
        ip: req.ip,
        userAgent: req.headers['user-agent'],
        device: req.headers['sec-ch-ua-platform'] || "Unknown"
      };

      const tokens = await authService.login(
        req.body,
        deviceInfo
      );

      res.status(200).json(tokens);

    } catch (err) {
      next(err);
    }
  }

  // ========================
  // VERIFY OTP
  // ========================
  async verifyOtp(req, res, next) {
    try {

      const { email, otp } = req.body;

      const result = await authService.verifyOtp(email, otp);

      res.status(200).json(result);

    } catch (err) {
      next(err);
    }
  }

  // ========================
  // RESEND OTP
  // ========================
  async resendOtp(req, res, next) {
    try {

      const { email } = req.body;

      const result = await authService.resendOtp(email);

      res.status(200).json(result);

    } catch (err) {
      next(err);
    }
  }

  // ========================
  // FORGOT PASSWORD
  // ========================
  async forgotPassword(req, res, next) {
    try {
      const { email } = req.body;
      const result = await authService.forgotPassword(email);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  // ========================
  // RESET PASSWORD
  // ========================
  async resetPassword(req, res, next) {
    try {
      const { email, otp, newPassword } = req.body;
      const result = await authService.resetPassword(email, otp, newPassword);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }

  // ========================
  // REFRESH TOKEN
  // ========================
  async refresh(req, res, next) {
    try {

      const { refreshToken } = req.body;

      const tokens = await authService.refreshToken(refreshToken);

      res.status(200).json(tokens);

    } catch (err) {
      next(err);
    }
  }

  // ========================
  // LOGOUT
  // ========================
  async logout(req, res, next) {
    try {

      const { sessionId } = req.query;

      const result = await authService.logout(sessionId);

      res.status(200).json(result);

    } catch (err) {
      next(err);
    }
  }

  // ========================
  // GOOGLE LOGIN
  // ========================
  async googleLogin(req, res, next) {
    try {

      const { idToken, fcmToken } = req.body;

      const result = await authService.googleAuth(
        idToken,
        {
          ip: req.ip,
          userAgent: req.headers["user-agent"],
          device: req.headers['sec-ch-ua-platform'] || "Unknown"
        },
        fcmToken
      );

      res.status(200).json(result);

    } catch (err) {
      next(err);
    }
  }

  // ========================
  // SUBMIT ID VERIFICATION
  // ========================
  async submitIdVerification(req, res, next) {
    try {
      const userId = req.user?.id || req.user?.sub;
      if (!userId) {
        return res.status(401).json({
          message: 'Access denied. No authenticated user found.',
        });
      }

      const result = await authService.submitIdVerification({
        ...req.body,
        userId,
      });

      res.status(201).json(result);

    } catch (err) {
      next(err);
    }
  }

  // ========================
  // ADMIN: GET VERIFICATION QUEUE
  // ========================
  // async getPendingVerifications(req, res, next) {
  //   try {

  //     const adminId = req.user.id;

  //     const requests = await authService.getPendingVerifications(
  //       adminId
  //     );

  //     res.status(200).json(requests);

  //   } catch (err) {
  //     next(err);
  //   }
  // }

  // ========================
  // ADMIN: REVIEW VERIFICATION
  // ========================
  // async reviewVerification(req, res, next) {
  //   try {

  //     const adminId = req.user.id;

  //     const { requestId, action, comment } = req.body;

  //     const result = await authService.reviewIdVerification(
  //       adminId,
  //       requestId,
  //       action,
  //       comment
  //     );

  //     res.status(200).json(result);

  //   } catch (err) {
  //     next(err);
  //   }
  // }

}

module.exports = new AuthController();
