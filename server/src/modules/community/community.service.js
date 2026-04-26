const prisma = require('../../lib/prisma')
const communitySchema = require('./community.schema')
const postCreateService =
    require("../post/services/post-create.service").default ||
    require("../post/services/post-create.service");
const supabaseStorage =
    require("../media/services/supabase-storage.service").default ||
    require("../media/services/supabase-storage.service");
const notificationService = require('../notification/notification.service');
const buildUserResponse = require('../../lib/userResponse');
const { formatPostDTO } = require('../../utils/postDTO');
const {
    BadRequestError,
    ConflictError,
    NotFoundError,
    ValidationError,
} = require('../../errors')

function mapCommunityForMobile(community, currentUserId) {
    return {
        id: community.id,
        communityName: community.name,
        ownerId: community.createdById,
        description: community.description || "",
        profilePicture: community.profileImage || null,
        members: community._count?.members || 0,
        university: community.createdBy?.profile?.university?.name || "general",
        isMember: (community.members || []).some((member) => member.userId === currentUserId),
    };
}


const createCommunity = async (data , userId) => {
    // Check if community name is taken
    const existing = await prisma.Community.findFirst({
        where: { name: data.name },
        select: { id: true },
    });
    if (existing) {
        throw new ConflictError('Community name is already taken');
    }

    // Create community
    const community = await prisma.Community.create({
        data: {
            name: data.name,
            description: data.description,
            profileImage: data.profileImage,
            createdById: userId,
        },
    });

    // Add creator as admin member
    await prisma.CommunityMember.create({
        data: {
            communityId: community.id,
            userId,
            role: 'ADMIN',
        },
    });

    // Optional initial members (mobile creation flow sends this list).
    // We add only users that exist and are CONNECTED to the creator.
    const memberIds = Array.isArray(data?.members) ? data.members : [];
    const cleanedMemberIds = [...new Set(memberIds)]
        .filter((id) => typeof id === "string" && id && id !== userId);

    if (cleanedMemberIds.length > 0) {
        const existingUsers = await prisma.User.findMany({
            where: { id: { in: cleanedMemberIds } },
            select: { id: true },
        });
        const existingUserIds = new Set(existingUsers.map((u) => u.id));

        const networks = await prisma.Network.findMany({
            where: {
                status: "CONNECTED",
                OR: cleanedMemberIds.flatMap((targetId) => ([
                    { userAId: userId, userBId: targetId },
                    { userAId: targetId, userBId: userId },
                ])),
            },
            select: { userAId: true, userBId: true },
        });

        const connectedToCreator = new Set();
        for (const n of networks) {
            if (n.userAId === userId) connectedToCreator.add(n.userBId);
            if (n.userBId === userId) connectedToCreator.add(n.userAId);
        }

        const finalMemberIds = cleanedMemberIds
            .filter((id) => existingUserIds.has(id))
            .filter((id) => connectedToCreator.has(id));

        if (finalMemberIds.length > 0) {
            await prisma.CommunityMember.createMany({
                data: finalMemberIds.map((targetUserId) => ({
                    communityId: community.id,
                    userId: targetUserId,
                    role: "MEMBER",
                })),
                skipDuplicates: true,
            });

            await Promise.all(
                finalMemberIds.map(async (targetUserId) => {
                    try {
                        await notificationService.createAndSendNotification({
                            recipientId: targetUserId,
                            actorId: userId,
                            type: 'COMMUNITY',
                            referenceId: community.id,
                            referenceType: 'COMMUNITY',
                            title: 'Added to community',
                            body: `You've been added to ${community.name}`,
                            data: { communityId: community.id, role: 'MEMBER' },
                            io: null,
                            onlineUsers: null,
                        });
                    } catch (_err) {
                        // Best-effort: do not fail community creation due to notification issues.
                    }
                }),
            );
        }
    }

    const hydratedCommunity = await prisma.Community.findUnique({
        where: { id: community.id },
        include: {
            createdBy: {
                select: {
                    profile: {
                        select: {
                            university: { select: { name: true } },
                        },
                    },
                },
            },
            members: {
                where: { userId },
                select: { userId: true },
            },
            _count: {
                select: { members: true },
            },
        },
    });

    return mapCommunityForMobile(hydratedCommunity, userId);
}

function resolveMediaType(mimetype) {
    if (typeof mimetype === "string" && mimetype.startsWith("video/")) return "VIDEO";
    if (typeof mimetype === "string" && mimetype.startsWith("image/")) return "IMAGE";
    return "DOCUMENT";
}

const postToCommunity = async (data , userId, files = []) => {
    const { communityId } = data;

    if (!communityId) {
        throw new ValidationError("communityId is required");
    }

    const community = await prisma.Community.findUnique({
        where: { id: communityId },
        select: { id: true },
    });

    if (!community) {
        throw new NotFoundError("Community not found");
    }

    const membership = await prisma.CommunityMember.findUnique({
        where: {
            communityId_userId: { communityId, userId },
        },
        select: { role: true },
    });

    if (!membership || membership.role !== "ADMIN") {
        throw new BadRequestError("Only admins can post");
    }

    let uploadedMediaIds = [];
    let uploadedPaths = [];

    if (files.length > 0) {
        const uploadedFiles = await supabaseStorage.uploadMultipleFiles(files, userId);
        uploadedPaths = uploadedFiles.map((file) => file.path).filter(Boolean);

        const createdMedia = await prisma.$transaction(
            uploadedFiles.map((uploadedFile, index) =>
                prisma.media.create({
                    data: {
                        uploaderId: userId,
                        communityId,
                        fileUrl: uploadedFile.url,
                        fileType: resolveMediaType(files[index]?.mimetype),
                    },
                    select: { id: true },
                }),
            ),
        );

        uploadedMediaIds = createdMedia.map((media) => media.id);
    }

    const postPayload = {
        content: data.content,
        visibility: data.visibility,
        tags: data.tags,
        category: data.category,
        mediaIds: [...(data.mediaIds || []), ...uploadedMediaIds],
        communityId,
    };

    if (postPayload.mediaIds.length > 10) {
        throw new BadRequestError("A post can have up to 10 media files");
    }

    try {
        // postCreateService.createPost() can return:
        // - { post, moderationResult } on success
        // - { success:false, status:'REJECTED'|'PENDING', message, details } without throwing
        //
        // Previously we destructured { post, moderationResult }, which turns those non-success
        // responses into { post: undefined, moderationResult: undefined } -> serialized as {}.
        const createResult = await postCreateService.createPost(userId, postPayload);

        return createResult;
    } catch (error) {
        if (uploadedMediaIds.length > 0) {
            await prisma.media.deleteMany({
                where: { id: { in: uploadedMediaIds }, postId: null },
            });
        }

        if (uploadedPaths.length > 0) {
            await Promise.all(
                uploadedPaths.map(async (path) => {
                    try {
                        await supabaseStorage.deleteFile(path);
                    } catch (_cleanupError) {
                        // Best-effort cleanup.
                    }
                }),
            );
        }

        throw error;
    }
}

const updateCommunity = async (communityId, data, userId) => {
    if (!communityId) {
        throw new ValidationError("communityId is required");
    }

    const community = await prisma.Community.findUnique({
        where: { id: communityId },
        select: { id: true, isDeleted: true },
    });

    if (!community || community.isDeleted) {
        throw new NotFoundError("Community not found");
    }

    const membership = await prisma.CommunityMember.findUnique({
        where: {
            communityId_userId: { communityId, userId },
        },
        select: { role: true },
    });

    if (!membership || membership.role !== "ADMIN") {
        throw new BadRequestError("Only admins can update community");
    }

    const updateData = {};
    if (data.name !== undefined) updateData.name = data.name;
    if (data.description !== undefined) updateData.description = data.description;
    if (data.profileImage !== undefined) updateData.profileImage = data.profileImage;

    const updated = await prisma.Community.update({
        where: { id: communityId },
        data: updateData,
    });

    return updated;
};

const deleteCommunity = async (communityId, userId) => {
    if (!communityId) {
        throw new ValidationError("communityId is required");
    }

    const community = await prisma.Community.findUnique({
        where: { id: communityId },
        select: { id: true, isDeleted: true },
    });

    if (!community || community.isDeleted) {
        throw new NotFoundError("Community not found");
    }

    const membership = await prisma.CommunityMember.findUnique({
        where: {
            communityId_userId: { communityId, userId },
        },
        select: { role: true },
    });

    if (!membership || membership.role !== "ADMIN") {
        throw new BadRequestError("Only admins can delete community");
    }

    const deleted = await prisma.Community.update({
        where: { id: communityId },
        data: { isDeleted: true },
    });

    return deleted;
};

const addCommunityMember = async (data, userId) => {
    const { communityId, userId: targetUserId, role } = data;

    if (!communityId) {
        throw new ValidationError("communityId is required");
    }

    if (!targetUserId) {
        throw new ValidationError("userId is required");
    }

    const community = await prisma.Community.findUnique({
        where: { id: communityId },
        select: { id: true, name: true },
    });

    if (!community) {
        throw new NotFoundError("Community not found");
    }

    const requesterMembership = await prisma.CommunityMember.findUnique({
        where: {
            communityId_userId: { communityId, userId },
        },
        select: { role: true },
    });

    if (!requesterMembership) {
        throw new BadRequestError("Only community members can add members");
    }

    const targetUser = await prisma.User.findUnique({
        where: { id: targetUserId },
        select: { id: true },
    });

    if (!targetUser) {
        throw new NotFoundError("User not found");
    }

    const existingMember = await prisma.CommunityMember.findUnique({
        where: {
            communityId_userId: { communityId, userId: targetUserId },
        },
        select: { id: true },
    });

    if (existingMember) {
        throw new ConflictError("User is already a member of this community");
    }

    const network = await prisma.Network.findFirst({
        where: {
            status: "CONNECTED",
            OR: [
                { userAId: userId, userBId: targetUserId },
                { userAId: targetUserId, userBId: userId },
            ],
        },
        select: { id: true },
    });

    if (!network) {
        throw new BadRequestError("Users must be networked to add members");
    }

    const member = await prisma.CommunityMember.create({
        data: {
            communityId,
            userId: targetUserId,
            role: role || "MEMBER",
        },
    });

    if (targetUserId !== userId) {
        await notificationService.createAndSendNotification({
            recipientId: targetUserId,
            actorId: userId,
            type: 'COMMUNITY',
            referenceId: communityId,
            referenceType: 'COMMUNITY',
            title: 'Added to community',
            body: `You've been added to ${community.name}`,
            data: {
                communityId,
                role: role || 'MEMBER',
            },
            io: null,
            onlineUsers: null,
        });
    }

    return member;
};

const joinCommunity = async (communityId, userId) => {
    if (!communityId) {
        throw new ValidationError("communityId is required");
    }

    const community = await prisma.Community.findUnique({
        where: { id: communityId },
        select: { id: true, isDeleted: true },
    });

    if (!community || community.isDeleted) {
        throw new NotFoundError("Community not found");
    }

    const existingMember = await prisma.CommunityMember.findUnique({
        where: { communityId_userId: { communityId, userId } },
        select: { id: true },
    });

    if (existingMember) {
        return { joined: true };
    }

    await prisma.CommunityMember.create({
        data: {
            communityId,
            userId,
            role: "MEMBER",
        },
    });

    return { joined: true };
};

const leaveCommunity = async (communityId, userId) => {
    if (!communityId) {
        throw new ValidationError("communityId is required");
    }

    const membership = await prisma.CommunityMember.findUnique({
        where: {
            communityId_userId: { communityId, userId },
        },
        select: { id: true },
    });

    if (!membership) {
        throw new NotFoundError("Membership not found");
    }

    await prisma.CommunityMember.delete({
        where: {
            communityId_userId: { communityId, userId },
        },
    });

    return { success: true };
};

const getCommunityById = async (communityId, userId) => {
    if (!communityId) {
        throw new ValidationError("communityId is required");
    }

    const community = await prisma.Community.findUnique({
        where: { id: communityId },
        include: {
            createdBy: {
                select: {
                    profile: {
                        select: {
                            university: { select: { name: true } },
                        },
                    },
                },
            },
            members: {
                where: { userId },
                select: { userId: true },
            },
            _count: {
                select: { members: true },
            },
        },
    });

    if (!community || community.isDeleted) {
        throw new NotFoundError("Community not found");
    }

    return mapCommunityForMobile(community, userId);
};

const getTopCommunities = async (userId, limit = 10) => {
    const safeLimit = Math.min(100, Math.max(1, Number(limit) || 10));

    const communities = await prisma.Community.findMany({
        where: { isDeleted: false },
        include: {
            createdBy: {
                select: {
                    profile: {
                        select: {
                            university: { select: { name: true } },
                        },
                    },
                },
            },
            members: {
                where: { userId },
                select: { userId: true },
            },
            _count: {
                select: { members: true },
            },
        },
        orderBy: { createdAt: "desc" },
        take: 100,
    });

    return communities
        .sort((a, b) => (b._count?.members || 0) - (a._count?.members || 0))
        .slice(0, safeLimit)
        .map((community) => mapCommunityForMobile(community, userId));
};

const getCommunityMembers = async (communityId) => {
    if (!communityId) {
        throw new ValidationError("communityId is required");
    }

    const community = await prisma.Community.findUnique({
        where: { id: communityId },
        select: { id: true, isDeleted: true },
    });

    if (!community || community.isDeleted) {
        throw new NotFoundError("Community not found");
    }

    const members = await prisma.CommunityMember.findMany({
        where: { communityId },
        include: {
            user: {
                include: {
                    profile: {
                        include: {
                            university: { select: { name: true } },
                        },
                    },
                },
            },
        },
        orderBy: { createdAt: "asc" },
    });

    return members.map((member) =>
        buildUserResponse({
            user: member.user,
            profile: member.user.profile,
        }),
    );
};

const getCommunityPosts = async (communityId, userId, page = 1, limit = 20) => {
    if (!communityId) {
        throw new ValidationError("communityId is required");
    }

    const community = await prisma.Community.findUnique({
        where: { id: communityId },
        select: { id: true, isDeleted: true },
    });

    if (!community || community.isDeleted) {
        throw new NotFoundError("Community not found");
    }

    const safePage = Math.max(1, Number(page) || 1);
    const safeLimit = Math.min(100, Math.max(1, Number(limit) || 20));
    const skip = (safePage - 1) * safeLimit;

    const posts = await prisma.Post.findMany({
        where: {
            communityId,
            isDeleted: false,
            moderationStatus: "APPROVED",
        },
        include: {
            author: {
                include: {
                    profile: true,
                },
            },
            media: {
                orderBy: { createdAt: "asc" },
            },
            _count: {
                select: {
                    comments: true,
                    postReactions: true,
                },
            },
            postReactions: userId
                ? {
                    where: { userId },
                    select: { userId: true },
                }
                : false,
            favorites: userId
                ? {
                    where: { userId },
                    select: { userId: true },
                }
                : false,
        },
        orderBy: { createdAt: "desc" },
        skip,
        take: safeLimit,
    });

    return posts.map((post) => formatPostDTO(post, userId || null));
};

module.exports = {
    createCommunity,
    postToCommunity,
    updateCommunity,
    deleteCommunity,
    addCommunityMember,
    joinCommunity,
    leaveCommunity,
    getCommunityById,
    getTopCommunities,
    getCommunityMembers,
    getCommunityPosts,
};
