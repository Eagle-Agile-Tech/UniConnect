const crypto = require('crypto');
const bcrypt = require('bcrypt');

const prisma = require('../../lib/prisma');
const authService = require('../auth/auth.service');
const mailer = require('../../config/mailer');
const { getAppUrl } = require('../../lib/appUrl');
const expertInvitationTemplate = require('../../templates/expertInvitationEmail');
const buildUserResponse = require('../../lib/userResponse');
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
const SECRET_CODE_TTL_DAYS = 30;

function normalizeEmail(email) {
  return (email || '').trim().toLowerCase();
}

function generateSecretCode() {
  return crypto.randomBytes(4).toString('hex').toUpperCase();
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

    if (!parsed.firstName || !parsed.lastName || !parsed.password) {
      throw new BadRequestError('firstName, lastName, and password are required');
    }

    const passwordHash = await bcrypt.hash(parsed.password, 12);
    const existingUser = await prisma.user.findUnique({
      where: { email: invitation.email },
      select: { id: true, role: true },
    });
    if (existingUser && existingUser.role !== 'EXPERT') {
      throw new ConflictError('Email already registered');
    }

    const user = existingUser
      ? await prisma.user.update({
          where: { id: existingUser.id },
          data: {
            firstName: parsed.firstName,
            lastName: parsed.lastName,
            passwordHash,
            role: 'EXPERT',
            verificationStatus: 'APPROVED',
          },
          select: { id: true, role: true },
        })
      : await prisma.user.create({
          data: {
            firstName: parsed.firstName,
            lastName: parsed.lastName,
            email: invitation.email,
            passwordHash,
            role: 'EXPERT',
            verificationStatus: 'APPROVED',
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

    const existingUserProfile = await prisma.userProfile.findUnique({
      where: { userId: user.id },
      select: { id: true },
    });
    if (!existingUserProfile) {
      await prisma.userProfile.create({
        data: { userId: user.id, username },
      });
    }

    const existingExpertProfile = await prisma.expertProfile.findUnique({
      where: { expertId: user.id },
      select: { id: true, invitedByInstitutionId: true },
    });

    if (!existingExpertProfile) {
      await prisma.expertProfile.create({
        data: {
          expertId: user.id,
          expertise: 'General',
          invitedByInstitutionId: invitation.institutionId,
        },
      });
    } else if (!existingExpertProfile.invitedByInstitutionId) {
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

    const userProfile = await prisma.userProfile.findUnique({
      where: { userId: user.id },
      include: { university: { select: { name: true } } },
    });

    const userResponse = buildUserResponse({
      user: profile?.expert,
      profile: userProfile,
      expertProfile: profile,
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      sessionId: tokens.sessionId,
    });

    return {
      ...userResponse,
      institution: profile?.institution || null,
    };
  }

  async joinInstitution(data) {
    const parsed = joinInstitutionSchema.parse(data);
    const email = normalizeEmail(parsed.email);

    const result = await prisma.$transaction(async (tx) => {
      const institution = await tx.institution.findFirst({
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

      const newSecretCode = generateSecretCode();
      const newSecretCodeExpiresAt = new Date(
        Date.now() + SECRET_CODE_TTL_DAYS * 24 * 60 * 60 * 1000
      );

      const rotated = await tx.institution.updateMany({
        where: {
          id: institution.id,
          secretCode: parsed.secretCode,
          secretCodeExpiresAt: { gt: new Date() },
        },
        data: {
          secretCode: newSecretCode,
          secretCodeExpiresAt: newSecretCodeExpiresAt,
        },
      });

      if (rotated.count === 0) {
        throw new BadRequestError('Invalid institution name or secret code');
      }

      const existingUser = await tx.user.findUnique({
        where: { email },
        select: { id: true, role: true },
      });
      if (existingUser && existingUser.role !== 'EXPERT') {
        throw new ConflictError('Email already registered');
      }

      const passwordHash = await bcrypt.hash(parsed.password, 12);
      const user = existingUser
        ? await tx.user.update({
            where: { id: existingUser.id },
            data: {
              firstName: parsed.firstName,
              lastName: parsed.lastName,
              passwordHash,
              role: 'EXPERT',
              verificationStatus: 'APPROVED',
            },
            select: { id: true },
          })
        : await tx.user.create({
            data: {
              firstName: parsed.firstName,
              lastName: parsed.lastName,
              email,
              passwordHash,
              role: 'EXPERT',
              verificationStatus: 'APPROVED',
            },
            select: { id: true },
          });

      const existingUserProfile = await tx.userProfile.findUnique({
        where: { userId: user.id },
        select: { id: true },
      });
      if (!existingUserProfile) {
        const username = await authService.resolveUniqueUsername(
          authService.getUsernameSeed({
            email,
            firstName: parsed.firstName,
            lastName: parsed.lastName,
          }),
          tx
        );

        await tx.userProfile.create({
          data: { userId: user.id, username },
        });
      }

      const existingExpertProfile = await tx.expertProfile.findUnique({
        where: { expertId: user.id },
        select: { id: true, invitedByInstitutionId: true },
      });
      if (!existingExpertProfile) {
        await tx.expertProfile.create({
          data: {
            expertId: user.id,
            expertise: 'General',
            invitedByInstitutionId: institution.id,
          },
        });
      } else if (!existingExpertProfile.invitedByInstitutionId) {
        await tx.expertProfile.update({
          where: { expertId: user.id },
          data: { invitedByInstitutionId: institution.id },
        });
      }

      return { userId: user.id };
    });

    const profile = await prisma.expertProfile.findUnique({
      where: { expertId: result.userId },
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

    const userProfile = await prisma.userProfile.findUnique({
      where: { userId: result.userId },
      include: { university: { select: { name: true } } },
    });

    const userResponse = buildUserResponse({
      user: profile?.expert,
      profile: userProfile,
      expertProfile: profile,
    });

    return {
      ...userResponse,
      institution: profile?.institution || null,
    };
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

    const userProfile = await prisma.userProfile.findUnique({
      where: { userId: expertId },
      include: { university: { select: { name: true } } },
    });

    const userResponse = buildUserResponse({
      user: profile.expert,
      profile: userProfile,
      expertProfile: profile,
    });

    return {
      ...userResponse,
      institution: profile.institution || null,
    };
  }

  async updateProfile(expertId, data) {
    if (!expertId) throw new BadRequestError('expertId is required');

    const parsed = updateExpertProfileSchema.parse(data);

    const existing = await prisma.expertProfile.findUnique({
      where: { expertId },
      select: { id: true },
    });

    if (!existing) {
      await prisma.expertProfile.create({
        data: {
          expertId,
          expertise: parsed.expertise ?? 'General',
          bio: parsed.bio,
          profileImage: parsed.profileImage,
        },
      });
    } else {
      await prisma.expertProfile.update({
        where: { expertId },
        data: {
          expertise: parsed.expertise,
          bio: parsed.bio,
          profileImage: parsed.profileImage,
        },
      });
    }

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

    const userProfile = await prisma.userProfile.findUnique({
      where: { userId: expertId },
      include: { university: { select: { name: true } } },
    });

    const userResponse = buildUserResponse({
      user: profile.expert,
      profile: userProfile,
      expertProfile: profile,
    });

    return {
      ...userResponse,
      institution: profile.institution || null,
    };
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
