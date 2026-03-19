const crypto = require('crypto');
const bcrypt = require('bcrypt');

const prisma = require('../../lib/prisma');
const authService = require('../auth/auth.service');
const mailer = require('../../config/mailer');
const { getAppUrl } = require('../../lib/appUrl');
const expertInvitationTemplate = require('../../templates/expertInvitationEmail');
const {
  acceptExpertInvitationSchema,
  joinInstitutionSchema,
  updateExpertProfileSchema,
} = require('./expert.schema');
const {
  AppError,
  BadRequestError,
  ConflictError,
  NotFoundError,
} = require('../../errors');

const INVITE_TTL_DAYS = 7;

function normalizeEmail(email) {
  return (email || '').trim().toLowerCase();
}

class ExpertService {
  async acceptInvitation(data) {
    const parsed = acceptExpertInvitationSchema.parse(data);

    const invitation = await prisma.expertInvitation.findUnique({
      where: { token: parsed.token },
      select: {
        id: true,
        token: true,
        email: true,
        status: true,
        expiresAt: true,
        institutionId: true,
      },
    });

    if (!invitation) throw new NotFoundError('Invitation not found');
    if (invitation.status !== 'PENDING') {
      throw new BadRequestError('Invitation is no longer valid');
    }
    if (invitation.expiresAt < new Date()) {
      throw new BadRequestError('Invitation has expired');
    }

    const existingUser = await prisma.user.findUnique({
      where: { email: invitation.email },
      select: { id: true },
    });
    if (existingUser) {
      throw new ConflictError('Email already registered');
    }

    if (!parsed.firstName || !parsed.lastName || !parsed.password) {
      throw new BadRequestError('firstName, lastName, and password are required');
    }

    const passwordHash = await bcrypt.hash(parsed.password, 12);
    const user = await prisma.user.create({
      data: {
        firstName: parsed.firstName,
        lastName: parsed.lastName,
        email: invitation.email,
        passwordHash,
        role: 'EXPERT',
        verificationStatus: 'EMAIL_VERIFIED',
      },
      select: { id: true, role: true },
    });

    const username = await authService.resolveUniqueUsername(
      authService.getUsernameSeed({
        email: invitation.email,
        firstName: parsed.firstName,
        lastName: parsed.lastName,
      })
    );

    await prisma.userProfile.create({
      data: { userId: user.id, username },
    });

    const existingProfile = await prisma.expertProfile.findUnique({
      where: { expertId: user.id },
      select: { id: true, invitedByInstitutionId: true },
    });

    if (!existingProfile) {
      await prisma.expertProfile.create({
        data: {
          expertId: user.id,
          expertise: 'General',
          invitedByInstitutionId: invitation.institutionId,
        },
      });
    } else if (!existingProfile.invitedByInstitutionId) {
      await prisma.expertProfile.update({
        where: { expertId: user.id },
        data: { invitedByInstitutionId: invitation.institutionId },
      });
    }

    return prisma.expertInvitation.update({
      where: { token: parsed.token },
      data: { status: 'APPROVED' },
    });
  }

  async login(data, deviceInfo) {
    const tokens = await authService.login(data, deviceInfo);

    const email = normalizeEmail(data.email);
    const user = await prisma.user.findUnique({
      where: { email },
      select: { id: true, role: true },
    });

    if (!user || user.role !== 'EXPERT') {
      throw new AppError('Unauthorized: Expert account required', 403, true, 'FORBIDDEN');
    }

    const profile = await prisma.expertProfile.findUnique({
      where: { expertId: user.id },
      include: {
        expert: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            email: true,
            role: true,
          },
        },
        institution: true,
      },
    });

    return { ...tokens, profile };
  }

  async joinInstitution(data) {
    const parsed = joinInstitutionSchema.parse(data);

    const institution = await prisma.institution.findFirst({
      where: {
        name: { equals: parsed.institutionName.trim(), mode: 'insensitive' },
        verificationStatus: 'VERIFIED',
        secretCode: parsed.secretCode,
        secretCodeExpiresAt: { gt: new Date() },
      },
      select: { id: true },
    });

    if (!institution) {
      throw new BadRequestError('Invalid institution name or secret code');
    }

    const email = normalizeEmail(parsed.email);
    const existingUser = await prisma.user.findUnique({
      where: { email },
      select: { id: true },
    });
    if (existingUser) {
      throw new ConflictError('Email already registered');
    }

    const passwordHash = await bcrypt.hash(parsed.password, 12);
    const user = await prisma.user.create({
      data: {
        firstName: parsed.firstName,
        lastName: parsed.lastName,
        email,
        passwordHash,
        role: 'EXPERT',
        verificationStatus: 'EMAIL_VERIFIED',
      },
      select: { id: true },
    });

    const username = await authService.resolveUniqueUsername(
      authService.getUsernameSeed({
        email,
        firstName: parsed.firstName,
        lastName: parsed.lastName,
      })
    );

    await prisma.userProfile.create({
      data: { userId: user.id, username },
    });

    return prisma.expertProfile.create({
      data: {
        expertId: user.id,
        expertise: 'General',
        invitedByInstitutionId: institution.id,
      },
    });
  }

  async getProfile(expertId) {
    if (!expertId) throw new BadRequestError('expertId is required');

    const profile = await prisma.expertProfile.findUnique({
      where: { expertId },
      include: {
        expert: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            email: true,
            role: true,
          },
        },
        institution: true,
      },
    });

    if (!profile) {
      throw new NotFoundError('Expert profile not found');
    }

    return profile;
  }

  async updateProfile(expertId, data) {
    if (!expertId) throw new BadRequestError('expertId is required');

    const parsed = updateExpertProfileSchema.parse(data);

    const existing = await prisma.expertProfile.findUnique({
      where: { expertId },
      select: { id: true },
    });

    if (!existing) {
      return prisma.expertProfile.create({
        data: {
          expertId,
          expertise: parsed.expertise ?? 'General',
          bio: parsed.bio,
          profileImage: parsed.profileImage,
        },
      });
    }

    return prisma.expertProfile.update({
      where: { expertId },
      data: {
        expertise: parsed.expertise,
        bio: parsed.bio,
        profileImage: parsed.profileImage,
      },
    });
  }

  async deleteProfile(expertId) {
    if (!expertId) throw new BadRequestError('expertId is required');

    const existing = await prisma.expertProfile.findUnique({
      where: { expertId },
      select: { id: true },
    });

    if (!existing) {
      throw new NotFoundError('Expert profile not found');
    }

    return prisma.expertProfile.delete({
      where: { expertId },
    });
  }
}

module.exports = new ExpertService();
