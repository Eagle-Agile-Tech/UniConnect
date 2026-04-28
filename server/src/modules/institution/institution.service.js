const crypto = require('crypto');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const prisma = require('../../lib/prisma');
const authService = require('../auth/auth.service');
const mailer = require('../../config/mailer');
const { getAppUrl } = require('../../lib/appUrl');
const buildUserResponse = require('../../lib/userResponse');
const notificationService = require('../notification/notification.service');
const expertInvitationTemplate = require('../../templates/expertInvitationEmail');
const institutionVerificationApprovedTemplate = require('../../templates/institutionVerificationApproved');
const institutionVerificationRejectedTemplate = require('../../templates/institutionVerificationRejected');
const {
  registerInstitutionSchema,
  updateInstitutionSchema,
  listInstitutionsSchema,
  submitInstitutionVerificationSchema,
  verifyInstitutionSchema,
  inviteExpertSchema,
} = require('./institution.schema');
const {
  AppError,
  BadRequestError,
  ConflictError,
  ForbiddenError,
  NotFoundError,
} = require('../../errors');

const MAX_LIMIT = 50;
const INVITE_TTL_DAYS = 7;
const SECRET_CODE_TTL_DAYS = 30;
const PERSONAL_EMAIL_DOMAINS = new Set([
  'gmail.com',
  'yahoo.com',
  'yahoo.co.uk',
  'outlook.com',
  'hotmail.com',
]);

function normalizeEmail(email) {
  return (email || '').trim().toLowerCase();
}

function isPersonalEmail(email) {
  const domain = email?.split('@')[1]?.toLowerCase();
  if (!domain) return false;
  if (PERSONAL_EMAIL_DOMAINS.has(domain)) return true;
  return false;
}

function generateSecretCode() {
  return crypto.randomBytes(4).toString('hex').toUpperCase();
}

function normalizeInstitutionUsername(username) {
  return (username || '').trim().toLowerCase();
}

function stripKeysDeep(value, keysToRemove) {
  if (Array.isArray(value)) {
    return value.map((item) => stripKeysDeep(item, keysToRemove));
  }

  if (!value || typeof value !== 'object') {
    return value;
  }

  return Object.entries(value).reduce((acc, [key, nestedValue]) => {
    if (keysToRemove.has(key)) return acc;
    acc[key] = stripKeysDeep(nestedValue, keysToRemove);
    return acc;
  }, {});
}

async function ensureInstitutionNameAvailable(name, options = {}) {
  const {
    excludeInstitutionId = null,
    excludeUserId = null,
  } = options;

  const existingInstitution = await prisma.institution.findFirst({
    where: {
      name: { equals: name, mode: 'insensitive' },
    },
    select: { id: true, userId: true },
  });

  if (!existingInstitution) return;
  if (excludeInstitutionId && existingInstitution.id === excludeInstitutionId) return;
  if (excludeUserId && existingInstitution.userId === excludeUserId) return;

  throw new ConflictError('Institution name already exists. Please use a different name.');
}

async function ensureInstitutionUsernameAvailable(username, options = {}) {
  const {
    excludeInstitutionId = null,
    excludeUserId = null,
  } = options;

  const normalized = normalizeInstitutionUsername(username);
  const existingInstitution = await prisma.institution.findFirst({
    where: {
      username: { equals: normalized, mode: 'insensitive' },
    },
    select: { id: true, userId: true },
  });

  if (!existingInstitution) return;
  if (excludeInstitutionId && existingInstitution.id === excludeInstitutionId) return;
  if (excludeUserId && existingInstitution.userId === excludeUserId) return;

  throw new ConflictError('Institution username already exists. Please use a different username.');
}

async function formatInstitutionResponse(institution, options = {}) {
  const {
    rootId = institution?.id ?? null,
    email = null,
    includeExperts = false,
  } = options;

  let affiliatedExperts = [];
  if (includeExperts && Array.isArray(institution?.affiliatedExperts) && institution.affiliatedExperts.length > 0) {
    const expertIds = institution.affiliatedExperts.map((expertProfile) => expertProfile.expertId);
    const userProfiles = await prisma.userProfile.findMany({
      where: { userId: { in: expertIds } },
      include: { university: { select: { name: true } } },
    });
    const profileByUserId = new Map(userProfiles.map((profile) => [profile.userId, profile]));

    affiliatedExperts = institution.affiliatedExperts.map((expertProfile) =>
      buildUserResponse({
        user: expertProfile.expert,
        profile: profileByUserId.get(expertProfile.expertId),
        expertProfile,
      })
    );
  }

  return stripKeysDeep({
    id: rootId,
    firstName: institution?.name ?? null,
    lastName: '',
    role: 'INSTITUTION',
    email,
    username: institution?.username ?? null,
    university: institution?.name ?? null,
    networkCount: affiliatedExperts.length || (institution?.affiliatedExperts?.length ?? 0),
    bio: institution?.description ?? null,
    profilePicture: institution?.logoUri ?? null,
    areWe: institution?.verificationStatus === 'VERIFIED',
    INSTITUTION: {
      id: institution?.id ?? null,
      type: institution?.type ?? null,
      username: institution?.username ?? null,
      website: institution?.website ?? null,
      verificationStatus: institution?.verificationStatus ?? null,
      verificationDocument: institution?.verificationDocument ?? null,
      userId: institution?.userId ?? null,
      secretCode: institution?.secretCode ?? null,
      secretCodeExpiresAt: institution?.secretCodeExpiresAt ?? null,
      createdAt: institution?.createdAt ?? null,
      updatedAt: institution?.updatedAt ?? null,
      verifiedAt: institution?.verifiedAt ?? null,
      verifiedById: institution?.verifiedById ?? null,
      profileUserId: institution?.profileUserId ?? null,
      affiliatedExperts,
    },
  }, new Set(['name']));
}

async function buildInstitutionAuthResponse({ user, institution, auth, message }) {
  const institutionResponse = await formatInstitutionResponse(institution, {
    rootId: user?.id ?? null,
    email: user?.email ?? null,
  });

  const response = {
    message,
    ...institutionResponse,
  };

  if (auth?.accessToken) {
    try {
      const decodedAccessToken = jwt.decode(auth.accessToken, { complete: true });
      const accessPayload = decodedAccessToken?.payload;
      if (accessPayload) {
        response.issuedAt = accessPayload.iat ?? null;
        response.expiredAt = accessPayload.exp ?? null;
        response.accessTokenIssuedAt = accessPayload.iat ?? null;
        response.accessTokenExpiresIn =
          accessPayload.iat && accessPayload.exp ? accessPayload.exp - accessPayload.iat : null;
      }
    } catch {
      // Fall back to the explicit auth fields below.
    }
  }

  if (auth?.accessToken !== undefined) response.accessToken = auth.accessToken ?? null;
  if (auth?.refreshToken !== undefined) response.refreshToken = auth.refreshToken ?? null;
  if (auth?.sessionId !== undefined) response.sessionId = auth.sessionId ?? null;
  if (auth?.accessTokenExpiresIn !== undefined) {
    response.accessTokenExpiresIn = auth.accessTokenExpiresIn ?? null;
  }
  if (auth?.accessTokenIssuedAt !== undefined) {
    response.accessTokenIssuedAt = auth.accessTokenIssuedAt ?? null;
  }
  if (auth?.refreshTokenExpiresIn !== undefined) {
    response.refreshTokenExpiresIn = auth.refreshTokenExpiresIn ?? null;
  }
  if (auth?.refreshTokenIssuedAt !== undefined) {
    response.refreshTokenIssuedAt = auth.refreshTokenIssuedAt ?? null;
  }

  return response;
}

class InstitutionService {
  async verifyInstitutionOtp(data) {
    const email = normalizeEmail(data.email);
    if (!email) throw new BadRequestError('Email is required');

    const user = await prisma.user.findUnique({
      where: { email },
      select: { id: true, role: true },
    });
    if (!user) throw new NotFoundError('Institution account not found');
    if (user.role !== 'INSTITUTION') {
      throw new BadRequestError('This account is not an institution');
    }

    const result = await authService.verifyOtp(email, data.otp);

    const institution = await prisma.institution.findUnique({
      where: { userId: user.id },
    });

    return await buildInstitutionAuthResponse({
      message: result.message,
      user: {
        id: result.id,
        role: result.role,
        firstName: result.firstName,
        lastName: result.lastName,
        email: result.email,
      },
      institution: institution || null,
      auth: {
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        sessionId: result.sessionId,
        accessTokenExpiresIn: result.accessTokenExpiresIn,
        accessTokenIssuedAt: result.accessTokenIssuedAt,
        refreshTokenExpiresIn: result.refreshTokenExpiresIn,
        refreshTokenIssuedAt: result.refreshTokenIssuedAt,
      },
    });
  }

  async resendInstitutionOtp(data) {
    const email = normalizeEmail(data.email);
    if (!email) throw new BadRequestError('Email is required');

    const user = await prisma.user.findUnique({
      where: { email },
      select: { id: true, role: true },
    });
    if (!user) throw new NotFoundError('Institution account not found');
    if (user.role !== 'INSTITUTION') {
      throw new BadRequestError('This account is not an institution');
    }

    return authService.resendOtp(email);
  }

  async registerInstitution(data, deviceInfo) {
    const parsed = registerInstitutionSchema.parse(data);
    const email = normalizeEmail(parsed.email);
    const username = normalizeInstitutionUsername(parsed.username);
    const name = parsed.name.trim();

    if (isPersonalEmail(email)) {
      throw new BadRequestError('Please use your institution email address');
    }

    const existingUser = await prisma.user.findUnique({
      where: { email },
      select: { id: true, role: true },
    });
    if (existingUser) {
      if (existingUser.role !== 'INSTITUTION') {
        throw new ConflictError('Email already registered. Please log in or reset your password.');
      }

      const existingInstitution = await prisma.institution.findUnique({
        where: { userId: existingUser.id },
        select: { id: true },
      });

      await ensureInstitutionNameAvailable(name, {
        excludeInstitutionId: existingInstitution?.id ?? null,
        excludeUserId: existingUser.id,
      });
      await ensureInstitutionUsernameAvailable(username, {
        excludeInstitutionId: existingInstitution?.id ?? null,
        excludeUserId: existingUser.id,
      });

      const hashedPassword = await bcrypt.hash(parsed.password, 12);

      let user, institution;
      try {
        const result = await prisma.$transaction(async (tx) => {
          const user = await tx.user.update({
            where: { id: existingUser.id },
            data: {
              firstName: name,
              lastName: 'Institution',
              passwordHash: hashedPassword,
              role: 'INSTITUTION',
              verificationStatus: 'PENDING',
            },
            select: {
              id: true,
              firstName: true,
              lastName: true,
              email: true,
              role: true,
              verificationStatus: true,
            },
          });

          const institution = existingInstitution
            ? await tx.institution.update({
                where: { id: existingInstitution.id },
                data: {
                  username,
                  name,
                  type: parsed.type,
                  description: parsed.description,
                  website: parsed.website,
                  logoUri: parsed.logoUri,
                },
              })
            : await tx.institution.create({
                data: {
                  username,
                  name,
                  type: parsed.type,
                  description: parsed.description,
                  website: parsed.website,
                  logoUri: parsed.logoUri,
                  userId: user.id,
                },
              });

          return { user, institution };
        });

        user = result.user;
        institution = result.institution;
      } catch (error) {
        if (error.code === 'P2002') {
          throw new ConflictError('Institution information conflicts with existing records.');
        }
        throw error;
      }

      await authService.issueEmailOtp(email);

      const sessionId = crypto.randomUUID();
      const refreshToken = authService.signRefreshToken(user, sessionId);
      const accessToken = authService.signAccessToken(user);
      await authService.createSession({ userId: user.id, refreshToken, deviceInfo, sessionId });

      return await buildInstitutionAuthResponse({
        message: 'Registration successful. Please verify email with the OTP sent.',
        user,
        institution,
        auth: {
          accessToken,
          refreshToken,
          sessionId,
        },
      });
    }

    const existingInstitution = await prisma.institution.findFirst({
      where: { name: { equals: name, mode: 'insensitive' } },
      select: { id: true },
    });
    if (existingInstitution) {
      throw new ConflictError('Institution name already exists. Please use a different name.');
    }

    await ensureInstitutionUsernameAvailable(username);

    const hashedPassword = await bcrypt.hash(parsed.password, 12);

    const { user, institution } = await prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          firstName: name,
          lastName: 'Institution',
          email,
          passwordHash: hashedPassword,
          role: 'INSTITUTION',
          verificationStatus: 'PENDING',
        },
        select: {
          id: true,
          firstName: true,
          lastName: true,
          email: true,
          role: true,
          verificationStatus: true,
        },
      });

      const institution = await tx.institution.create({
        data: {
          username,
          name,
          type: parsed.type,
          description: parsed.description,
          website: parsed.website,
          logoUri: parsed.logoUri,
          userId: user.id,
        },
      });

      return { user, institution };
    });

    await authService.issueEmailOtp(email);

    const sessionId = crypto.randomUUID();
    const refreshToken = authService.signRefreshToken(user, sessionId);
    const accessToken = authService.signAccessToken(user);
    await authService.createSession({ userId: user.id, refreshToken, deviceInfo, sessionId });

    return await buildInstitutionAuthResponse({
      message: 'Registration successful. Please verify email with the OTP sent.',
      user,
      institution,
      auth: {
        accessToken,
        refreshToken,
        sessionId,
      },
    });
  }

  async listInstitutions(query) {
    const parsed = listInstitutionsSchema.parse(query);
    const page = parsed.page ? Number(parsed.page) : 1;
    const limit = parsed.limit ? Number(parsed.limit) : 20;
    const safeLimit = Math.min(limit, MAX_LIMIT);
    const offset = (page - 1) * safeLimit;

    const where = {};
    if (parsed.search) {
      where.name = { contains: parsed.search, mode: 'insensitive' };
    }
    if (parsed.verified !== undefined) {
      where.verificationStatus = parsed.verified ? 'VERIFIED' : { not: 'VERIFIED' };
    }
    if (parsed.type) {
      where.type = parsed.type;
    }

    const [itemsRaw, total] = await prisma.$transaction([
      prisma.institution.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: offset,
        take: safeLimit,
      }),
      prisma.institution.count({ where }),
    ]);

    const items = [];
    for (const item of itemsRaw) {
      items.push(await formatInstitutionResponse(item));
    }

    return {
      items,
      total,
      page,
      limit: safeLimit,
      hasMore: offset + safeLimit < total,
    };
  }

  async getInstitution(institutionId) {
    if (!institutionId) throw new BadRequestError('institutionId is required');

    const institution = await prisma.institution.findUnique({
      where: { id: institutionId },
      include: {
        affiliatedExperts: {
          include: {
            expert: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                email: true,
                role: true,
                verificationStatus: true,
              },
            },
          },
        },
      },
    });

    if (!institution) throw new NotFoundError('Institution not found');

    return formatInstitutionResponse(institution, { includeExperts: true });
  }

  async updateInstitution(institutionId, data, actorId, isAdmin = false) {
    if (!institutionId) throw new BadRequestError('institutionId is required');
    if (!actorId && !isAdmin) {
      throw new AppError('Unauthorized: Institution account required', 403, true, 'FORBIDDEN');
    }

    const parsed = updateInstitutionSchema.parse(data);
    const username = parsed.username ? normalizeInstitutionUsername(parsed.username) : null;

    const existing = await prisma.institution.findUnique({
      where: { id: institutionId },
      select: { id: true, userId: true },
    });

    if (!existing) throw new NotFoundError('Institution not found');
    if (!isAdmin && existing.userId !== actorId) {
      throw new ForbiddenError('You do not have permission to update this institution');
    }

    if (parsed.name) {
      await ensureInstitutionNameAvailable(parsed.name.trim(), { excludeInstitutionId: institutionId });
    }
    if (username) {
      await ensureInstitutionUsernameAvailable(username, { excludeInstitutionId: institutionId });
    }

    const updated = await prisma.institution.update({
      where: { id: institutionId },
      data: {
        ...parsed,
        ...(username ? { username } : {}),
      },
    });

    return formatInstitutionResponse(updated);
  }

  async loginInstitution(data, deviceInfo) {
    const email = normalizeEmail(data.email);
    if (!email) throw new BadRequestError('Email is required');

    const user = await prisma.user.findUnique({
      where: { email },
      select: { id: true, role: true },
    });
    if (!user || user.role !== 'INSTITUTION') {
      throw new AppError('Institution account not found', 404, true, 'NOT_FOUND');
    }

    const institution = await prisma.institution.findUnique({
      where: { userId: user.id },
    });
    if (!institution) {
      throw new AppError('Institution account not found', 404, true, 'NOT_FOUND');
    }

    const auth = await authService.login(data, deviceInfo);
    return await buildInstitutionAuthResponse({
      message: 'Login successful',
      user: {
        id: auth.id,
        role: auth.role,
        firstName: auth.firstName,
        lastName: auth.lastName,
        email: auth.email,
      },
      institution,
      auth: {
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
        sessionId: auth.sessionId,
        accessTokenExpiresIn: auth.accessTokenExpiresIn,
        accessTokenIssuedAt: auth.accessTokenIssuedAt,
        refreshTokenExpiresIn: auth.refreshTokenExpiresIn,
        refreshTokenIssuedAt: auth.refreshTokenIssuedAt,
      },
    });
  }

  async submitVerification(institutionId, data, actorId, isAdmin = false) {
    if (!institutionId) throw new BadRequestError('institutionId is required');
    if (!actorId && !isAdmin) {
      throw new AppError('Unauthorized: Institution account required', 403, true, 'FORBIDDEN');
    }

    const parsed = submitInstitutionVerificationSchema.parse(data);
    const documentUrl = parsed.documentUrl || parsed.verificationDocument;

    const existing = await prisma.institution.findUnique({
      where: { id: institutionId },
      select: { id: true, userId: true },
    });

    if (!existing) throw new NotFoundError('Institution not found');
    if (!isAdmin && existing.userId !== actorId) {
      throw new ForbiddenError('You do not have permission to verify this institution');
    }

    const updatedInstitution = await prisma.institution.update({
      where: { id: institutionId },
      data: {
        verificationDocument: documentUrl,
        verificationStatus: 'PENDING',
      },
    });

    const request = await prisma.institutionVerificationRequest.create({
      data: {
        institutionId,
        documentUrl,
        status: 'PENDING',
      },
    });

    return {
      institution: await formatInstitutionResponse(updatedInstitution),
      request,
    };
  }

  async verifyInstitution(institutionId, data, adminId) {
    if (!institutionId) throw new BadRequestError('institutionId is required');

    const parsed = verifyInstitutionSchema.parse(data);
    if (!adminId) {
      throw new AppError('Unauthorized: Admin access required', 403, true, 'FORBIDDEN');
    }

    const existing = await prisma.institution.findUnique({
      where: { id: institutionId },
      select: {
        id: true,
        name: true,
        userId: true,
        managedBy: { select: { id: true, email: true } },
      },
    });

    if (!existing) throw new NotFoundError('Institution not found');

    const isApproved = parsed.status === 'APPROVED';

    const secretCode = isApproved ? generateSecretCode() : null;
    const secretCodeExpiresAt = isApproved
      ? new Date(Date.now() + SECRET_CODE_TTL_DAYS * 24 * 60 * 60 * 1000)
      : null;

    const updated = await prisma.institution.update({
      where: { id: institutionId },
      data: {
        verificationStatus: isApproved ? 'VERIFIED' : 'REJECTED',
        verifiedAt: isApproved ? new Date() : null,
        verifiedById: isApproved ? adminId : null,
        secretCode,
        secretCodeExpiresAt,
      },
    });

    await prisma.institutionVerificationRequest.updateMany({
      where: { institutionId, status: 'PENDING' },
      data: {
        status: isApproved ? 'APPROVED' : 'REJECTED',
        reviewedById: adminId,
        reviewedAt: new Date(),
      },
    });

    // Notify institution manager (best effort).
    if (existing.userId) {
      try {
        await notificationService.createAndSendNotification({
          recipientId: existing.userId,
          actorId: adminId,
          type: 'SYSTEM',
          title: isApproved
            ? 'Institution verified'
            : 'Institution verification rejected',
          body: isApproved
            ? 'Your institution has been verified. Your secret code is ready.'
            : 'Your institution verification request was rejected.',
          data: {
            institutionId: existing.id,
            institutionName: existing.name,
            status: parsed.status,
            ...(isApproved
              ? { secretCode, secretCodeExpiresAt }
              : { rejectionReason: parsed.rejectionReason || null }),
          },
        });
      } catch (_err) {
        // best-effort
      }
    }

    // Email the institution manager with the secret code after approval (best effort).
    // If rejected, email the rejection reason (also best effort).
    const institutionEmail = existing.managedBy?.email || null;
    if (institutionEmail) {
      try {
        const template = isApproved
          ? institutionVerificationApprovedTemplate({
              institutionName: existing.name,
              secretCode,
              secretCodeExpiresAt,
            })
          : institutionVerificationRejectedTemplate({
              institutionName: existing.name,
              rejectionReason: parsed.rejectionReason || null,
            });

        await mailer.sendEmail({
          to: institutionEmail,
          subject: template.subject,
          text: template.text,
          html: template.html,
        });
      } catch (_err) {
        // best-effort
      }
    }

    return {
      institution: await formatInstitutionResponse(updated),
      status: parsed.status,
      rejectionReason: parsed.rejectionReason || null,
      secretCode: secretCode || undefined,
      secretCodeExpiresAt: secretCodeExpiresAt || undefined,
    };
  }

  async regenerateSecretCode(institutionId, managerId) {
    if (!institutionId) throw new BadRequestError('institutionId is required');
    if (!managerId) {
      throw new AppError('Unauthorized: Institution account required', 403, true, 'FORBIDDEN');
    }

    const institution = await prisma.institution.findUnique({
      where: { id: institutionId },
      select: {
        id: true,
        userId: true,
        verificationStatus: true,
        secretCodeExpiresAt: true,
      },
    });

    if (!institution) throw new NotFoundError('Institution not found');
    if (institution.userId !== managerId) {
      throw new AppError('Unauthorized: Institution account required', 403, true, 'FORBIDDEN');
    }
    if (institution.verificationStatus !== 'VERIFIED') {
      throw new BadRequestError('Institution must be verified to regenerate secret code');
    }
    if (institution.secretCodeExpiresAt && institution.secretCodeExpiresAt > new Date()) {
      throw new ConflictError('Secret code has not expired yet');
    }

    const secretCode = generateSecretCode();
    const secretCodeExpiresAt = new Date(
      Date.now() + SECRET_CODE_TTL_DAYS * 24 * 60 * 60 * 1000
    );

    const updated = await prisma.institution.update({
      where: { id: institutionId },
      data: {
        secretCode,
        secretCodeExpiresAt,
      },
    });

    return {
      institution: await formatInstitutionResponse(updated),
      secretCode,
      secretCodeExpiresAt,
    };
  }

  async inviteExpert(data, managerId) {
    const parsed = inviteExpertSchema.parse(data);
    if (!managerId) {
      throw new AppError('Unauthorized: Institution account required', 403, true, 'FORBIDDEN');
    }
    const email = normalizeEmail(parsed.email);

    const institution = await prisma.institution.findUnique({
      where: { id: parsed.institutionId },
      select: { id: true, name: true, userId: true },
    });

    if (!institution) throw new NotFoundError('Institution not found');
    if (institution.userId !== managerId) {
      throw new AppError('Unauthorized: Institution account required', 403, true, 'FORBIDDEN');
    }

    const existingUser = await prisma.user.findUnique({
      where: { email },
      select: { id: true },
    });
    if (existingUser) {
      throw new ConflictError('Email already registered');
    }

    const existingInvitation = await prisma.expertInvitation.findFirst({
      where: {
        email,
        institutionId: parsed.institutionId,
        status: 'PENDING',
        expiresAt: { gt: new Date() },
      },
      select: { id: true },
    });
    if (existingInvitation) {
      throw new ConflictError('An active invitation already exists for this email');
    }

    const token = crypto.randomUUID();
    const expiresAt = new Date(Date.now() + INVITE_TTL_DAYS * 24 * 60 * 60 * 1000);

    const invitation = await prisma.expertInvitation.create({
      data: {
        email,
        institutionId: parsed.institutionId,
        status: 'PENDING',
        token,
        expiresAt,
      },
    });

    const inviteUrl = `${getAppUrl()}/experts/invite/accept?token=${token}`;
    const template = expertInvitationTemplate({
      institutionName: institution.name,
      inviteUrl,
      expiresAt,
    });

    await mailer.sendEmail({
      to: email,
      subject: template.subject,
      text: template.text,
      html: template.html,
    });

    return { ...invitation, inviteUrl };
  }

}

module.exports = new InstitutionService();
