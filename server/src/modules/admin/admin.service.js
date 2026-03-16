const prisma = require('../../lib/prisma');
const { createAdminSchema, loginAdminSchema, listUserProfilesSchema} = require('../admin/admin.schema');
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const redisClient = require('../../config/redis');
const mailer = require('../../config/mailer');
const idVerificationApprovedTemplate = require('../../templates/idVerificationApproved');
const idVerificationRejectedTemplate = require('../../templates/idVerificationRejected');
const { buildLoginUrl } = require('../../lib/appUrl');
const {
    AppError,
    BadRequestError,
    ConflictError,
    NotFoundError,
} = require('../../errors');

const MAX_LIMIT = 50;

// ---------------------------
// Helper: Ensure Admin
// ---------------------------
const SESSION_TTL_SECONDS = 7 * 24 * 60 * 60;

function normalizeEmail(email) {
    return email.trim().toLowerCase();
}

async function ensureAdmin(adminId) {
    const admin = await prisma.user.findUnique({
        where: { id: adminId },
        select: { id: true, role: true }
    });

    if (!admin || admin.role !== 'ADMIN') {
        throw new AppError('Unauthorized: Admin access required', 403, true, 'FORBIDDEN');
    }
}

function deriveNameParts({ firstName, lastName, name, email }) {
    if (firstName || lastName) {
        return {
            firstName: firstName || 'Admin',
            lastName: lastName || 'User',
        };
    }

    if (name) {
        const tokens = name.trim().split(/\s+/).filter(Boolean);
        if (tokens.length === 1) {
            return { firstName: tokens[0], lastName: 'Admin' };
        }
        return { firstName: tokens[0], lastName: tokens.slice(1).join(' ') };
    }

    const localPart = email?.split('@')[0]?.replace(/[^a-z0-9]+/gi, '') || 'admin';
    return { firstName: localPart || 'Admin', lastName: 'User' };
}

function sanitizeUsername(value) {
    return (value || '')
        .toLowerCase()
        .replace(/\s+/g, '')
        .replace(/[^a-z0-9._-]/g, '')
        .slice(0, 30) || 'admin';
}

async function resolveUniqueUsername(baseValue) {
    const baseUsername = sanitizeUsername(baseValue);
    for (let i = 0; i < 5; i += 1) {
        const candidate = i === 0
            ? baseUsername
            : `${baseUsername}-${Math.floor(1000 + Math.random() * 9000)}`;
        const existing = await prisma.userProfile.findUnique({
            where: { username: candidate },
            select: { id: true }
        });
        if (!existing) {
            return candidate;
        }
    }
    return `${baseUsername}-${crypto.randomUUID().slice(0, 8)}`;
}

function sessionKey(sessionId) {
    return `admin_session:${sessionId}`;
}

function userSessionKey(sessionId) {
    return `session:${sessionId}`;
}

async function cacheSessionIndex({ sessionId, userId, expiresAt }) {
    const ttlSeconds = Math.max(
        1,
        Math.floor((new Date(expiresAt).getTime() - Date.now()) / 1000)
    );

    try {
        await redisClient.set(sessionKey(sessionId), userId, 'EX', ttlSeconds || SESSION_TTL_SECONDS);
    } catch {
        // Redis unavailable: DB remains source of truth.
    }
}

async function getCachedSessionUserId(sessionId) {
    try {
        return await redisClient.get(sessionKey(sessionId));
    } catch {
        return null;
    }
}

async function clearSessionIndex(sessionId) {
    try {
        await redisClient.del(sessionKey(sessionId));
    } catch {
        // Redis unavailable: DB remains source of truth.
    }
}

async function clearUserSessionIndex(sessionId) {
    try {
        await redisClient.del(userSessionKey(sessionId));
    } catch {
        // Redis unavailable: DB remains source of truth.
    }
}

function hashToken(token) {
    return crypto.createHash('sha256').update(token).digest('hex');
}

function signAccessToken(user) {
    return jwt.sign({ sub: user.id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '15m' });
}

function signRefreshToken(user, sessionId) {
    return jwt.sign({ sub: user.id, sid: sessionId }, process.env.JWT_REFRESH_SECRET, { expiresIn: '7d' });
}

async function createSession({ userId, refreshToken, deviceInfo, sessionId = crypto.randomUUID() }) {
    const token = hashToken(`${sessionId}:${Date.now()}:${crypto.randomUUID()}`);
    const expiresAt = new Date(Date.now() + SESSION_TTL_SECONDS * 1000);

    await prisma.session.create({
        data: {
            id: sessionId,
            userId,
            token,
            refreshToken: hashToken(refreshToken),
            deviceInfo: deviceInfo ? { device: deviceInfo.device || 'Unknown' } : undefined,
            ipAddress: deviceInfo?.ip,
            userAgent: deviceInfo?.userAgent,
            expiresAt,
        },
    });

    await cacheSessionIndex({ sessionId, userId, expiresAt });

    return sessionId;
}

async function checkLoginRateLimit(email) {
    const key = `admin_login_attempts:${email}`;
    try {
        const attempts = await redisClient.incr(key);
        if (attempts === 1) await redisClient.expire(key, 900);
        if (attempts > 5) {
            throw new AppError('Too many login attempts. Try again later.', 429, true, 'RATE_LIMITED');
        }
    } catch (err) {
        if (err instanceof AppError) throw err;
        // Redis unavailable -> allow login
    }
}

// ---------------------------
// Create Admin
// ---------------------------
async function createAdmin(data, adminId) {
    if (adminId) {
        await ensureAdmin(adminId);
    }

    const parsedData = createAdminSchema.parse(data);
    const { email, password, name, profileImage, firstName, lastName, isActive } = parsedData;
    const normalizedEmail = normalizeEmail(email);

    const existingAdmin = await prisma.user.findUnique({
        where: { email: normalizedEmail }
    });

    if (existingAdmin) {
        throw new ConflictError('Admin with this email already exists');
    }

    const hashedPassword = await bcrypt.hash(password, 12);
    const nameParts = deriveNameParts({ firstName, lastName, name, email: normalizedEmail });

    const username = await resolveUniqueUsername(normalizedEmail.split('@')[0] || 'admin');
    const fullName = `${nameParts.firstName} ${nameParts.lastName}`.trim() || undefined;

    const newAdmin = await prisma.user.create({
        data: {
            email: normalizedEmail,
            passwordHash: hashedPassword,
            role: 'ADMIN',
            verificationStatus: 'APPROVED',
            firstName: nameParts.firstName,
            lastName: nameParts.lastName,
            isDeleted: isActive === false,
            profile: {
                create: {
                    username,
                    fullName,
                    profileImage,
                }
            }
        },
        include: {
            profile: true
        }
    });

    return newAdmin;
}

// ---------------------------
// Admin Login
// ---------------------------
async function loginAdmin(data, deviceInfo) {
    const parsedData = loginAdminSchema.parse(data);
    const email = normalizeEmail(parsedData.email);

    await checkLoginRateLimit(email);

    const admin = await prisma.user.findUnique({
        where: { email },
    });

    if (!admin || admin.role !== 'ADMIN') {
        throw new AppError('Invalid email or password', 401, true, 'INVALID_CREDENTIALS');
    }

    if (!admin.passwordHash) {
        throw new AppError('Password login not available for this admin', 401, true, 'INVALID_CREDENTIALS');
    }

    const valid = await bcrypt.compare(parsedData.password, admin.passwordHash);
    if (!valid) {
        throw new AppError('Invalid email or password', 401, true, 'INVALID_CREDENTIALS');
    }

    const sessionId = crypto.randomUUID();
    const accessToken = signAccessToken(admin);
    const refreshToken = signRefreshToken(admin, sessionId);

    await createSession({ userId: admin.id, refreshToken, deviceInfo, sessionId });

    return { accessToken, refreshToken, sessionId };
}

// ---------------------------
// Refresh Admin Token
// ---------------------------
async function refreshAdminToken(token) {
    if (!token) {
        throw new BadRequestError('Refresh token is required');
    }

    let decoded;
    try {
        decoded = jwt.verify(token, process.env.JWT_REFRESH_SECRET);
    } catch {
        throw new AppError('Invalid refresh token', 401, true, 'INVALID_REFRESH');
    }

    const { sub: userId, sid: sessionId } = decoded;
    const cachedUserId = await getCachedSessionUserId(sessionId);
    const session = await prisma.session.findUnique({ where: { id: sessionId } });
    if (!session || session.isRevoked || session.expiresAt < new Date()) {
        throw new AppError('Session not found', 401, true, 'SESSION_NOT_FOUND');
    }
    if (hashToken(token) !== session.refreshToken) {
        throw new AppError('Invalid refresh token', 401, true, 'INVALID_REFRESH');
    }
    if (!cachedUserId || cachedUserId !== session.userId) {
        await cacheSessionIndex({ sessionId: session.id, userId: session.userId, expiresAt: session.expiresAt });
    }

    const admin = await prisma.user.findUnique({ where: { id: userId } });
    if (!admin) {
        throw new NotFoundError('Admin not found');
    }
    if (admin.role !== 'ADMIN') {
        throw new AppError('Unauthorized: Admin access required', 403, true, 'FORBIDDEN');
    }

    const newSessionId = crypto.randomUUID();
    const accessToken = signAccessToken(admin);
    const refreshToken = signRefreshToken(admin, newSessionId);

    await prisma.session.delete({ where: { id: sessionId } });
    await clearSessionIndex(sessionId);
    await createSession({ userId, refreshToken, sessionId: newSessionId });

    return { accessToken, refreshToken };
}

// ---------------------------
// Admin Logout
// ---------------------------
async function logoutAdmin(token) {
    if (!token) {
        throw new BadRequestError('Refresh token is required');
    }

    let decoded;
    try {
        decoded = jwt.verify(token, process.env.JWT_REFRESH_SECRET);
    } catch {
        throw new AppError('Invalid refresh token', 401, true, 'INVALID_REFRESH');
    }

    const { sub: userId, sid: sessionId } = decoded;
    const session = await prisma.session.findUnique({ where: { id: sessionId } });
    if (!session || session.isRevoked || session.expiresAt < new Date()) {
        throw new AppError('Session not found', 401, true, 'SESSION_NOT_FOUND');
    }
    if (hashToken(token) !== session.refreshToken) {
        throw new AppError('Invalid refresh token', 401, true, 'INVALID_REFRESH');
    }

    const admin = await prisma.user.findUnique({ where: { id: userId } });
    if (!admin || admin.role !== 'ADMIN') {
        throw new AppError('Unauthorized: Admin access required', 403, true, 'FORBIDDEN');
    }

    await prisma.session.delete({ where: { id: sessionId } });
    await clearSessionIndex(sessionId);

    return { message: 'Logged out successfully' };
}

// ---------------------------
// Get Admin Profile
// ---------------------------
async function adminProfile(adminId) {

    await ensureAdmin(adminId);

    const admin = await prisma.user.findUnique({
        where: { id: adminId },
        select: {
            id: true,
            email: true,
            role: true,
            createdAt: true,
            profile: true
        }
    });

    if (!admin) {
        throw new NotFoundError('Admin not found');
    }

    return admin;
}

// ---------------------------
// Update Admin Profile
// ---------------------------
async function updateAdminProfile(adminId, data) {

    await ensureAdmin(adminId);

    const { name, profileImage, bio, username, firstName, lastName } = data;
    if (!name && !profileImage && !bio && !username && !firstName && !lastName) {
        throw new BadRequestError('No profile updates provided');
    }

    const admin = await prisma.user.findUnique({
        where: { id: adminId },
        select: { email: true, profile: { select: { username: true } } }
    });

    if (!admin) {
        throw new NotFoundError('Admin not found');
    }

    const nameParts = deriveNameParts({ firstName, lastName, name, email: admin.email });
    const fullName = `${nameParts.firstName} ${nameParts.lastName}`.trim() || undefined;
    const sanitizedUsername = username ? sanitizeUsername(username) : undefined;
    const baseUsername = sanitizedUsername || admin.profile?.username || admin.email.split('@')[0] || 'admin';
    const resolvedUsername = !admin.profile?.username && !sanitizedUsername
        ? await resolveUniqueUsername(baseUsername)
        : sanitizeUsername(baseUsername);

    const updatedAdmin = await prisma.user.update({
        where: { id: adminId },
        data: {
            firstName: firstName || (name ? nameParts.firstName : undefined),
            lastName: lastName || (name ? nameParts.lastName : undefined),
            profile: {
                upsert: {
                    update: {
                        fullName: name ? name : fullName,
                        profileImage,
                        bio,
                        ...(sanitizedUsername && { username: sanitizedUsername })
                    },
                    create: {
                        username: resolvedUsername,
                        fullName: name ? name : fullName,
                        profileImage,
                        bio
                    }
                }
            }
        },
        include: {
            profile: true
        }
    });

    return updatedAdmin;
}

// ---------------------------
// Verify User Account
// ---------------------------
async function verifyAccount(adminId, userId, status, rejectionReason) {

    await ensureAdmin(adminId);

    if (!userId) {
        throw new BadRequestError('User id is required');
    }

    const updatedUser = await prisma.user.update({
        where: { id: userId },
        data: {
            verificationStatus: status
        }
    });

    await prisma.idVerificationRequest.updateMany({
        where: { userId },
        data: {
            status,
            reviewedById: adminId,
            reviewedAt: new Date(),
            adminComment: rejectionReason || null,
        }
    });

    if (updatedUser.verificationMethod === 'ID_DOCUMENT_ADMIN') {
        const name = `${updatedUser.firstName || ''} ${updatedUser.lastName || ''}`.trim() || undefined;
        if (status === 'APPROVED') {
            const template = idVerificationApprovedTemplate(name, buildLoginUrl());
            await mailer.sendEmail({
                to: updatedUser.email,
                subject: template.subject,
                text: template.text,
                html: template.html,
            });
        }
        if (status === 'REJECTED') {
            const template = idVerificationRejectedTemplate(name, rejectionReason);
            await mailer.sendEmail({
                to: updatedUser.email,
                subject: template.subject,
                text: template.text,
                html: template.html,
            });

            const sessions = await prisma.session.findMany({
                where: { userId: updatedUser.id, isRevoked: false },
                select: { id: true },
            });
            await prisma.session.updateMany({
                where: { userId: updatedUser.id, isRevoked: false },
                data: { isRevoked: true, revokedAt: new Date() },
            });
            await Promise.all(sessions.map((session) => clearUserSessionIndex(session.id)));
        }
    }

    return updatedUser;
}

// ---------------------------
// Moderate Content
// ---------------------------
async function moderateContent(adminId, contentId, contentType, action, reason) {

    await ensureAdmin(adminId);

    if (!contentId) {
        throw new BadRequestError('contentId is required');
    }

    const validTypes = ['POST', 'COMMENT'];

    if (!validTypes.includes(contentType)) {
        throw new BadRequestError('Invalid content type');
    }

    if (contentType === 'POST') {

        const updatedPost = await prisma.post.update({
            where: { id: contentId },
            data: {
                moderationStatus: action,
                moderatedById: adminId
            }
        });

        return updatedPost;
    }

    if (contentType === 'COMMENT') {

        const updatedComment = await prisma.postComment.update({
            where: { id: contentId },
            data: {
                moderationStatus: action,
                moderatedById: adminId
            }
        });

        return updatedComment;
    }
}

// ---------------------------
// Moderation Queue
// ---------------------------
async function getModerationQueue(adminId, contentType, status, page = 1, limit = 20) {

    await ensureAdmin(adminId);

    limit = Math.min(limit, MAX_LIMIT);
    const offset = (page - 1) * limit;

    if (contentType === 'POST') {

        const posts = await prisma.post.findMany({
            where: { moderationStatus: status },
            include: {
                author: {
                    select: { id: true, email: true }
                }
            },
            skip: offset,
            take: limit,
            orderBy: { createdAt: 'desc' }
        });

        return posts;
    }

    if (contentType === 'COMMENT') {

        const comments = await prisma.postComment.findMany({
            where: { moderationStatus: status },
            include: {
                commenter: {
                    select: { id: true, email: true }
                }
            },
            skip: offset,
            take: limit,
            orderBy: { createdAt: 'desc' }
        });

        return comments;
    }
}

// ---------------------------
// Unverified Users
// ---------------------------
async function getUnverifiedUsers(adminId, page = 1, limit = 20) {

    await ensureAdmin(adminId);

    limit = Math.min(limit, MAX_LIMIT);
    const offset = (page - 1) * limit;

    const users = await prisma.user.findMany({
        where: {
            verificationStatus: 'PENDING'
        },
        skip: offset,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
            profile: true
        }
    });

    if(users.length === 0) {
        let message = 'No unverified users found';
        return message
    }

    return users;
}

async function listUserProfiles(adminId, { search, limit = 20, offset = 0 } = {})  {

    await ensureAdmin(adminId);

    const safeLimit = Math.min(Number(limit) || 20, 50);
    const safeOffset = Math.max(Number(offset) || 0, 0);
    const query = typeof search === "string" ? search.trim() : "";

    const searchWhere = query
        ? {
              OR: [
                  { username: { contains: query, mode: "insensitive" } },
                  { fullName: { contains: query, mode: "insensitive" } },
                  { department: { contains: query, mode: "insensitive" } },
              ],
          }
        : {};

    const where = searchWhere;

    const [profiles, total] = await Promise.all([
        prisma.userProfile.findMany({
            where,
            take: safeLimit,
            skip: safeOffset,
            orderBy: { updatedAt: "desc" },
            select: {
                userId: true,
                username: true,
                fullName: true,
                profileImage: true,
                department: true,
                level: true,
                universityId: true,
                updatedAt: true,
                university: {
                    select: { name: true },
                },
            }
        }),
        prisma.userProfile.count({ where })
    ]);

    const items = profiles.map((profile) => {
        const universityName = profile.university?.name || null;
        const { university, ...rest } = profile;
        return {
            ...rest,
            universityName,
        };
    });

    return {
        items,
        meta: {
            total,
            limit: safeLimit,
            offset: safeOffset,
            hasMore: safeOffset + safeLimit < total
        }
    };
}



// ---------------------------
// Dashboard Stats
// ---------------------------
async function getDashboardStats(adminId) {

    await ensureAdmin(adminId);

    const [
        totalUsers,
        totalPosts,
        totalComments,
        totalCommunities,
        verifiedUsers,
        pendingVerifications,
        pendingPosts,
        pendingComments,
        deletedUsers,
        activeUsersToday
    ] = await Promise.all([

        prisma.user.count(),

        prisma.post.count(),

        prisma.postComment.count(),

        prisma.community.count(),

        prisma.user.count({
            where: { verificationStatus: 'APPROVED' }
        }),

        prisma.user.count({
            where: { verificationStatus: 'PENDING' }
        }),

        prisma.post.count({
            where: { moderationStatus: 'PENDING' }
        }),

        prisma.postComment.count({
            where: { moderationStatus: 'PENDING' }
        }),

        prisma.user.count({
            where: { isDeleted: true }
        }),

        prisma.session.count({
            where: {
                lastActiveAt: {
                    gte: new Date(Date.now() - 24 * 60 * 60 * 1000)
                }
            }
        })
    ]);

    return {

        platformOverview: {
            totalUsers,
            totalPosts,
            totalComments,
            totalCommunities
        },

        moderation: {
            pendingPosts,
            pendingComments
        },

        verification: {
            verifiedUsers,
            pendingVerifications
        },

        activity: {
            activeUsersToday
        },

        safety: {
            deletedUsers
        }
    };
}

module.exports = {
    createAdmin,
    loginAdmin,
    refreshAdminToken,
    logoutAdmin,
    adminProfile,
    updateAdminProfile,
    verifyAccount,
    moderateContent,
    listUserProfiles,
    getModerationQueue,
    getUnverifiedUsers,
    getDashboardStats
};
