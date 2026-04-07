const crypto = require('crypto');
const bcrypt = require('bcrypt');

const prisma = require('../../lib/prisma');
const authService = require('../auth/auth.service');
const mailer = require('../../config/mailer');
const { getAppUrl } = require('../../lib/appUrl');
const buildUserResponse = require('../../lib/userResponse');
const expertInvitationTemplate = require('../../templates/expertInvitationEmail');
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

    return {
      ...result,
      institution: institution || null,
    };
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

      const existingInstitutionByName = await prisma.institution.findFirst({
        where: { name: { equals: name, mode: 'insensitive' } },
        select: { id: true, userId: true },
      });
      if (existingInstitutionByName && existingInstitutionByName.userId !== existingUser.id) {
        throw new ConflictError('Institution name already exists. Please use a different name.');
      }

      const hashedPassword = await bcrypt.hash(parsed.password, 12);

      const { user, institution } = await prisma.$transaction(async (tx) => {
        const user = await tx.user.update({
          where: { id: existingUser.id },
          data: {
            firstName: name,
            lastName: 'Institution',
            passwordHash: hashedPassword,
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

        const managedInstitution = await tx.institution.findFirst({
          where: { userId: user.id },
          select: { id: true },
        });

        let institution;
        if (managedInstitution) {
          institution = await tx.institution.update({
            where: { id: managedInstitution.id },
            data: {
              name,
              type: parsed.type,
              description: parsed.description,
              website: parsed.website,
              logoUri: parsed.logoUri,
            },
          });
        } else {
          institution = await tx.institution.create({
            data: {
              name,
              type: parsed.type,
              description: parsed.description,
              website: parsed.website,
              logoUri: parsed.logoUri,
              userId: user.id,
            },
          });
        }

        return { user, institution };
      });

      await authService.issueEmailOtp(email);

      const sessionId = crypto.randomUUID();
      const refreshToken = authService.signRefreshToken(user, sessionId);
      const accessToken = authService.signAccessToken(user);
      await authService.createSession({ userId: user.id, refreshToken, deviceInfo, sessionId });

      const userResponse = buildUserResponse({
        user,
        accessToken,
        refreshToken,
        sessionId,
      });

      return {
        message: 'Registration successful. Please verify email with the OTP sent.',
        ...userResponse,
        institution,
      };
    }

    const existingInstitution = await prisma.institution.findFirst({
      where: { name: { equals: name, mode: 'insensitive' } },
      select: { id: true },
    });
    if (existingInstitution) {
      throw new ConflictError('Institution name already exists. Please use a different name.');
    }

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

    const userResponse = buildUserResponse({
      user,
      accessToken,
      refreshToken,
      sessionId,
    });

    return {
      message: 'Registration successful. Please verify email with the OTP sent.',
      ...userResponse,
      institution,
    };
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

    const [items, total] = await prisma.$transaction([
      prisma.institution.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: offset,
        take: safeLimit,
      }),
      prisma.institution.count({ where }),
    ]);

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
        affiliatedExperts: true,
      },
    });

    if (!institution) throw new NotFoundError('Institution not found');

    return institution;
  }

  async updateInstitution(institutionId, data) {
    if (!institutionId) throw new BadRequestError('institutionId is required');

    const parsed = updateInstitutionSchema.parse(data);

    const existing = await prisma.institution.findUnique({
      where: { id: institutionId },
      select: { id: true },
    });

    if (!existing) throw new NotFoundError('Institution not found');

    return prisma.institution.update({
      where: { id: institutionId },
      data: parsed,
    });
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
    return { ...auth, institution };
  }

  async submitVerification(institutionId, data) {
    if (!institutionId) throw new BadRequestError('institutionId is required');

    const parsed = submitInstitutionVerificationSchema.parse(data);
    const documentUrl = parsed.documentUrl || parsed.verificationDocument;

    const existing = await prisma.institution.findUnique({
      where: { id: institutionId },
      select: { id: true },
    });

    if (!existing) throw new NotFoundError('Institution not found');

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

    return { institution: updatedInstitution, request };
  }

  async verifyInstitution(institutionId, data, adminId) {
    if (!institutionId) throw new BadRequestError('institutionId is required');

    const parsed = verifyInstitutionSchema.parse(data);
    if (!adminId) {
      throw new AppError('Unauthorized: Admin access required', 403, true, 'FORBIDDEN');
    }

    const existing = await prisma.institution.findUnique({
      where: { id: institutionId },
      select: { id: true },
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

    return {
      institution: updated,
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
      institution: updated,
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
