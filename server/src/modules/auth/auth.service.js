const prisma = require('../../lib/prisma');
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const redisClient = require('../../config/redis');
const jwt = require('jsonwebtoken');

const { AppError } = require('../../errors');
const mailer = require('../../config/mailer');
const verificationTemplate = require('../../templates/verificationEmail');
const passwordResetTemplate = require('../../templates/passwordResetEmail');
const universityDomains = require('../../lib/data/universities.json');
const verifyGoogleToken = require('../../lib/googleAuth');

class AuthError extends AppError {
  constructor(message, statusCode = 401, isOperational = true, errorCode = 'AUTH_ERROR') {
    super(message, statusCode, isOperational, errorCode);
  }
}

class AuthService {
  OTP_TTL_SECONDS = 300;
  OTP_RESEND_COOLDOWN_SECONDS = 60;
  OTP_MAX_ATTEMPTS = 5;
  SESSION_TTL_SECONDS = 7 * 24 * 60 * 60;

  normalizeEmail(email) {
    return email.trim().toLowerCase();
  }


  hashToken(token) {
    return crypto.createHash('sha256').update(token).digest('hex');
  }

  generateOtpCode() {
    return String(crypto.randomInt(0, 10000)).padStart(4, '0');
  }

  otpKey(email) {
    return `verify_otp:${email}`;
  }

  otpAttemptsKey(email) {
    return `verify_otp_attempts:${email}`;
  }

  otpResendKey(email) {
    return `verify_otp_resend:${email}`;
  }

  resetOtpKey(email) {
    return `reset_otp:${email}`;
  }

  resetOtpAttemptsKey(email) {
    return `reset_otp_attempts:${email}`;
  }

  resetOtpResendKey(email) {
    return `reset_otp_resend:${email}`;
  }

  sessionKey(sessionId) {
    return `session:${sessionId}`;
  }

  async cacheSessionIndex({ sessionId, userId, expiresAt }) {
    const ttlSeconds = Math.max(
      1,
      Math.floor((new Date(expiresAt).getTime() - Date.now()) / 1000)
    );

    try {
      await redisClient.set(this.sessionKey(sessionId), userId, 'EX', ttlSeconds || this.SESSION_TTL_SECONDS);
    } catch {
      // Redis unavailable: DB remains source of truth.
    }
  }

  async getCachedSessionUserId(sessionId) {
    try {
      return await redisClient.get(this.sessionKey(sessionId));
    } catch {
      return null;
    }
  }

  async clearSessionIndex(sessionId) {
    try {
      await redisClient.del(this.sessionKey(sessionId));
    } catch {
      // Redis unavailable: DB remains source of truth.
    }
  }

  async issueEmailOtp(email) {
    const otpCode = this.generateOtpCode();

    try {
      await redisClient.set(this.otpKey(email), this.hashToken(otpCode), 'EX', this.OTP_TTL_SECONDS);
      await redisClient.del(this.otpAttemptsKey(email));
      await redisClient.set(this.otpResendKey(email), '1', 'EX', this.OTP_RESEND_COOLDOWN_SECONDS);
    } catch {
      throw new AuthError('Unable to issue OTP. Try again.', 503);
    }

    await this.sendVerificationEmail(email, otpCode);
  }

  detectUniversity(email) {
    const domain = email.split('@')[1]?.toLowerCase();
    if (!domain) return null;
    return universityDomains.find(u => u.domains.some(d => domain.endsWith(d)));
  }

  async getOrCreateUniversity(universityData) {
    if (!universityData?.name) return null;

    const existing = await prisma.university.findFirst({
      where: { name: universityData.name },
    });

    if (existing) return existing;

    return prisma.university.create({
      data: {
        name: universityData.name,
        domains: universityData.domains || [],
      },
    });
  }

  signAccessToken(user) {
    return jwt.sign({ sub: user.id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '15m' });
  }

  signRefreshToken(user, sessionId) {
    return jwt.sign({ sub: user.id, sid: sessionId }, process.env.JWT_REFRESH_SECRET, { expiresIn: '7d' });
  }

  async createSession({ userId, refreshToken, deviceInfo, sessionId = crypto.randomUUID() }) {
    const token = this.hashToken(`${sessionId}:${Date.now()}:${crypto.randomUUID()}`);
    const expiresAt = new Date(Date.now() + this.SESSION_TTL_SECONDS * 1000);

    await prisma.session.create({
      data: {
        id: sessionId,
        userId,
        token,
        refreshToken: this.hashToken(refreshToken),
        deviceInfo: deviceInfo ? { device: deviceInfo.device || 'Unknown' } : undefined,
        ipAddress: deviceInfo?.ip,
        userAgent: deviceInfo?.userAgent,
        expiresAt,
      },
    });

    // console.log(`Created session ${sessionId} for user ${userId} with device info:`, deviceInfo);

    await this.cacheSessionIndex({ sessionId, userId, expiresAt });

    return sessionId;
  }

  async checkLoginRateLimit(email) {
    const key = `login_attempts:${email}`;
    try {
      const attempts = await redisClient.incr(key);
      if (attempts === 1) await redisClient.expire(key, 900);
      if (attempts > 5) throw new AuthError('Too many login attempts. Try again later.', 429);
    } catch (err) {
      if (err instanceof AuthError) throw err;
      // Redis unavailable → allow login
    }
  }

  // ==========================
  // EMAIL REGISTRATION FLOW
  // ==========================
  async register(data) {
    const email = this.normalizeEmail(data.email);
    const university = this.detectUniversity(email);

    if (!university) {
      throw new AuthError('No university detected. Please use ID verification.', 400, true, 'NON_UNIVERSITY_EMAIL');
    }

    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) throw new AuthError('Email already registered', 409);

    const hashedPassword = await bcrypt.hash(data.password, 12);

    await prisma.user.create({
      data: {
        firstName: data.firstName,
        lastName: data.lastName,
        email,
        passwordHash: hashedPassword,
        role: 'STUDENT',
        verificationStatus: 'PENDING',
        verificationMethod: 'UNIVERSITY_EMAIL',
      },
    });

    await this.issueEmailOtp(email);

    return {
      message: 'Registration successful. Please verify email with the OTP sent.',
      universityDetected: university.name,
    
    };
  }

  async verifyOtp(emailInput, otp) {
    const email = this.normalizeEmail(emailInput);
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) throw new AuthError('User not found', 404);
    if (user.verificationStatus === 'EMAIL_VERIFIED') throw new AuthError('Email already verified', 400);
    if (user.verificationMethod && user.verificationMethod !== 'UNIVERSITY_EMAIL') {
      throw new AuthError('This account is not using email OTP verification', 400);
    }

    const storedOtpHash = await redisClient.get(this.otpKey(email));
    if (!storedOtpHash) throw new AuthError('Invalid or expired OTP', 400);

    if (this.hashToken(otp) !== storedOtpHash) {
      const attempts = await redisClient.incr(this.otpAttemptsKey(email));
      if (attempts === 1) await redisClient.expire(this.otpAttemptsKey(email), this.OTP_TTL_SECONDS);
      if (attempts >= this.OTP_MAX_ATTEMPTS) {
        await redisClient.del(this.otpKey(email), this.otpAttemptsKey(email));
        throw new AuthError('Too many invalid OTP attempts. Request a new OTP.', 429);
      }

      throw new AuthError('Invalid OTP', 400);
    }

    await prisma.user.update({ where: { id: user.id }, data: { verificationStatus: 'EMAIL_VERIFIED' } });
    user.verificationStatus = 'EMAIL_VERIFIED';
    await redisClient.del(this.otpKey(email), this.otpAttemptsKey(email), this.otpResendKey(email));

    if (user.verificationMethod === 'UNIVERSITY_EMAIL') {
      const detectedUniversity = this.detectUniversity(email);
      const universityRecord = await this.getOrCreateUniversity(detectedUniversity);
      if (universityRecord?.id) {
        await prisma.userProfile.updateMany({
          where: {
            userId: user.id,
            universityId: null,
          },
          data: {
            universityId: universityRecord.id,
          },
        });
      }
    }

   const sessionId = crypto.randomUUID();

   const refreshToken = this.signRefreshToken(user, sessionId);

await this.createSession({
  userId: user.id,
  refreshToken,
  sessionId
});

const accessToken = this.signAccessToken(user);

return {
  message: 'Email verified successfully',
  user: {
    id: user.id,
    email: user.email,
    verificationStatus: user.verificationStatus
  },
  accessToken,
  refreshToken
};
  }

  async resendOtp(emailInput) {
    const email = this.normalizeEmail(emailInput);
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) throw new AuthError('User not found', 404);
    if (user.verificationStatus === 'EMAIL_VERIFIED') throw new AuthError('Email already verified', 400);
    if (user.verificationMethod && user.verificationMethod !== 'UNIVERSITY_EMAIL') throw new AuthError('This account is not using email OTP verification', 400);

    const cooldown = await redisClient.get(this.otpResendKey(email));
    if (cooldown) {
      throw new AuthError('Please wait before requesting another OTP', 429);
    }

    await this.issueEmailOtp(email);

    return { message: 'OTP resent successfully' };
  }

  async sendVerificationEmail(email, otpCode) {
    const template = verificationTemplate(otpCode);

    await mailer.sendEmail({
      to: email,
      subject: template.subject,
      text: template.text,
      html: template.html,
    });
  }

  async issuePasswordResetOtp(email) {
    const otpCode = this.generateOtpCode();

    try {
      await redisClient.set(this.resetOtpKey(email), this.hashToken(otpCode), 'EX', this.OTP_TTL_SECONDS);
      await redisClient.del(this.resetOtpAttemptsKey(email));
      await redisClient.set(this.resetOtpResendKey(email), '1', 'EX', this.OTP_RESEND_COOLDOWN_SECONDS);
    } catch {
      throw new AuthError('Unable to issue password reset OTP. Try again.', 503);
    }

    await this.sendPasswordResetEmail(email, otpCode);
  }

  async forgotPassword(emailInput) {
    const email = this.normalizeEmail(emailInput);
    const user = await prisma.user.findUnique({ where: { email } });

    // Return a generic response to avoid account enumeration.
    if (!user || !user.passwordHash) {
      return { message: 'If the account exists, a password reset OTP has been sent.' };
    }

    const cooldown = await redisClient.get(this.resetOtpResendKey(email));
    if (cooldown) {
      throw new AuthError('Please wait before requesting another password reset OTP', 429);
    }

    await this.issuePasswordResetOtp(email);
    return { message: 'If the account exists, a password reset OTP has been sent.' };
  }

  async resetPassword(emailInput, otp, newPassword) {
    const email = this.normalizeEmail(emailInput);
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user || !user.passwordHash) throw new AuthError('Invalid or expired OTP', 400);

    const storedOtpHash = await redisClient.get(this.resetOtpKey(email));
    if (!storedOtpHash) throw new AuthError('Invalid or expired OTP', 400);

    if (this.hashToken(otp) !== storedOtpHash) {
      const attempts = await redisClient.incr(this.resetOtpAttemptsKey(email));
      if (attempts === 1) await redisClient.expire(this.resetOtpAttemptsKey(email), this.OTP_TTL_SECONDS);
      if (attempts >= this.OTP_MAX_ATTEMPTS) {
        await redisClient.del(this.resetOtpKey(email), this.resetOtpAttemptsKey(email));
        throw new AuthError('Too many invalid OTP attempts. Request a new OTP.', 429);
      }
      throw new AuthError('Invalid OTP', 400);
    }

    const passwordHash = await bcrypt.hash(newPassword, 12);
    const userSessions = await prisma.session.findMany({
      where: { userId: user.id },
      select: { id: true },
    });

    await prisma.user.update({ where: { id: user.id }, data: { passwordHash } });
    await prisma.session.deleteMany({ where: { userId: user.id } });
    await Promise.all(userSessions.map((session) => this.clearSessionIndex(session.id)));

    await redisClient.del(this.resetOtpKey(email), this.resetOtpAttemptsKey(email), this.resetOtpResendKey(email));

    return { message: 'Password reset successful. Please login again.' };
  }

  async sendPasswordResetEmail(email, otpCode) {
    const template = passwordResetTemplate(otpCode);

    await mailer.sendEmail({
      to: email,
      subject: template.subject,
      text: template.text,
      html: template.html,
    });
  }

  // ==========================
  // LOGIN FLOW
  // ==========================
  async login(data, deviceInfo) {
    const email = this.normalizeEmail(data.email);
    await this.checkLoginRateLimit(email);

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) throw new AuthError('Invalid email or password');

    if (!user.passwordHash) throw new AuthError('Use Google login');

    const valid = await bcrypt.compare(data.password, user.passwordHash);
    if (!valid) throw new AuthError('Invalid email or password');
    if (user.verificationStatus === 'PENDING') throw new AuthError('Email not verified', 403);

    const sessionId = crypto.randomUUID();
    const accessToken = this.signAccessToken(user);
    const refreshToken = this.signRefreshToken(user, sessionId);

    await this.createSession({ userId: user.id, refreshToken, deviceInfo, sessionId });

    return { accessToken, refreshToken };
  }

  async refreshToken(token) {
    let decoded;
    try { decoded = jwt.verify(token, process.env.JWT_REFRESH_SECRET); } catch { throw new AuthError('Invalid refresh token'); }

    const { sub: userId, sid: sessionId } = decoded;
    const cachedUserId = await this.getCachedSessionUserId(sessionId);
    const session = await prisma.session.findUnique({ where: { id: sessionId } });
    if (!session || session.isRevoked || session.expiresAt < new Date()) throw new AuthError('Session not found', 401);
    if (this.hashToken(token) !== session.refreshToken) throw new AuthError('Invalid refresh token');
    if (!cachedUserId || cachedUserId !== session.userId) {
      await this.cacheSessionIndex({ sessionId: session.id, userId: session.userId, expiresAt: session.expiresAt });
    }

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new AuthError('User not found', 404);

    const newSessionId = crypto.randomUUID();
    const accessToken = this.signAccessToken(user);
    const refreshToken = this.signRefreshToken(user, newSessionId);

    await prisma.session.delete({ where: { id: sessionId } });
    await this.clearSessionIndex(sessionId);
    await this.createSession({ userId, refreshToken, sessionId: newSessionId });

    return { accessToken, refreshToken };
  }

  async logout(sessionId) {
    if (!sessionId) throw new AuthError('sessionId is required', 400);
    await prisma.session.delete({ where: { id: sessionId } });
    await this.clearSessionIndex(sessionId);
    return { message: 'Logged out successfully' };
  }

  // ==========================
  // GOOGLE AUTH
  // ==========================
  async googleAuth(idToken, deviceInfo) {
    let googleUser;
    try { googleUser = await verifyGoogleToken(idToken); } catch { throw new AuthError('Invalid Google ID token'); }
    if (!googleUser.emailVerified) throw new AuthError('Google email not verified');

    const email = this.normalizeEmail(googleUser.email);
    const university = this.detectUniversity(email);
    if (!university) throw new AuthError('Only university emails allowed for Google login', 403);

    const universityRecord = await this.getOrCreateUniversity(university);

    let user = await prisma.user.findUnique({ where: { email } });

    if (!user) {
      user = await prisma.$transaction(async (tx) => {
        const newUser = await tx.user.create({
          data: {
            firstName: googleUser.firstName || '',
            lastName: googleUser.lastName || '',
            email,
            googleId: googleUser.googleId,
            verificationStatus: 'EMAIL_VERIFIED',
            verificationMethod: 'UNIVERSITY_EMAIL',
          },
        });

        await tx.userProfile.create({
          data: { userId: newUser.id, universityId: universityRecord?.id, profileImage: googleUser.picture },
        });

        return newUser;
      });
    }

    if (user.googleId && user.googleId !== googleUser.googleId) throw new AuthError('Google account does not match this user', 403);

    if (!user.googleId) {
      user = await prisma.user.update({ where: { id: user.id }, data: { googleId: googleUser.googleId } });
    }

    const sessionId = crypto.randomUUID();
    const accessToken = this.signAccessToken(user);
    const refreshToken = this.signRefreshToken(user, sessionId);
    await this.createSession({ userId: user.id, refreshToken, deviceInfo, sessionId });

    return {
      accessToken,
      refreshToken,
      user: {
        id: user.id,
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        role: user.role,
        verificationStatus: user.verificationStatus,
        verificationMethod: user.verificationMethod,
        googleId: user.googleId,
      },
    };
  }

  // ==========================
  // ID DOCUMENT VERIFICATION FLOW
  // ==========================
  async submitIdVerification(data) {
    const {
      userId: providedUserId,
      firstName,
      lastName,
      email: rawEmail,
      password,
      passwordConfirm,
      documentImage,
      documentType,
      submittedNotes,
    } = data;

    if (!documentImage) throw new AuthError('documentImage is required', 400);

    let userId = providedUserId;

    if (!userId) {
      if (!rawEmail || !firstName || !lastName || !password || !passwordConfirm) {
        throw new AuthError('firstName, lastName, email, password and passwordConfirm are required when userId is not provided', 400);
      }
      if (password !== passwordConfirm) throw new AuthError('Passwords do not match', 400);

      const email = this.normalizeEmail(rawEmail);
      const detectedUniversity = this.detectUniversity(email);
      if (detectedUniversity) {
        throw new AuthError('University email detected. Use standard registration instead.', 400);
      }

      const existingUser = await prisma.user.findUnique({ where: { email } });
      if (existingUser && existingUser.verificationMethod !== 'ID_DOCUMENT_ADMIN') {
        throw new AuthError('Email already registered', 409);
      }

      if (existingUser) {
        userId = existingUser.id;
      } else {
        const hashedPassword = await bcrypt.hash(password, 12);
        const createdUser = await prisma.$transaction(async (tx) => {
          const newUser = await tx.user.create({
            data: {
              firstName,
              lastName,
              email,
              passwordHash: hashedPassword,
              role: 'STUDENT',
              verificationStatus: 'PENDING',
              verificationMethod: 'ID_DOCUMENT_ADMIN',
            },
          });

          await tx.userProfile.create({
            data: { userId: newUser.id },
          });

          return newUser;
        });
        userId = createdUser.id;
      }
    } else {
      const user = await prisma.user.findUnique({ where: { id: userId } });
      if (!user) throw new AuthError('User not found', 404);
    }

    const existingRequest = await prisma.idVerificationRequest.findUnique({ where: { userId } });

    const request = existingRequest
      ? await prisma.idVerificationRequest.update({
          where: { userId },
          data: {
            documentImage,
            documentType,
            submittedNotes,
            status: 'PENDING',
            reviewedById: null,
            reviewedAt: null,
            adminComment: null,
          },
        })
      : await prisma.idVerificationRequest.create({
          data: { userId, documentImage, documentType, submittedNotes },
        });

    await prisma.user.update({
      where: { id: userId },
      data: { verificationMethod: 'ID_DOCUMENT_ADMIN', verificationStatus: 'PENDING' },
    });

    return { message: 'ID verification submitted successfully', request };
  }
}

module.exports = new AuthService();
