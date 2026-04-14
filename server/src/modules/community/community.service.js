const prisma = require('../../lib/prisma')
const communitySchema = require('./community.schema')
const postCreateService =
    require("../post/services/post-create.service").default ||
    require("../post/services/post-create.service");
const {
    BadRequestError,
    ConflictError,
    NotFoundError,
    ValidationError,
} = require('../../errors')


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

    return community;
}

const postToCommunity = async (data , userId) => {
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

    const postPayload = {
        content: data.content,
        visibility: data.visibility,
        tags: data.tags,
        category: data.category,
        mediaIds: data.mediaIds,
        communityId,
    };

    const { post, moderationResult } = await postCreateService.createPost(
        userId,
        postPayload,
    );

    return { post, moderationResult };
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
        select: { id: true },
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

    return member;
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

module.exports = {
    createCommunity,
    postToCommunity,
    updateCommunity,
    deleteCommunity,
    addCommunityMember,
    leaveCommunity,
};
