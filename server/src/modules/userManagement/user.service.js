const prisma = require("./../../lib/prisma");
const { createUserSchema } = require("./user.schema");
const crypto = require("crypto");
const {
    BadRequestError,
    ConflictError,
    NotFoundError,
    ValidationError,
} = require("./../../errors");
const universityDomains = require("./../../lib/data/universities.json");
const usernameOnlySchema = createUserSchema.pick({ username: true });

class userService {
    normalizeUsername(username) {
        if (typeof username !== "string") return "";
        return username.trim().toLowerCase();
    }

    async resolveUniqueUsername(baseUsername, userId) {
        const normalized = this.normalizeUsername(baseUsername);
        if (!normalized) return "";

        const maxLength = 20;
        const base = normalized.slice(0, maxLength);

        const conflict = await prisma.userProfile.findFirst({
            where: {
                username: base,
                ...(userId ? { userId: { not: userId } } : {}),
            },
            select: { id: true },
        });
        if (!conflict) return base;

        const suffixLength = 5; // _ + 4 digits
        const baseMax = Math.max(1, maxLength - suffixLength);
        const trimmedBase = base.slice(0, baseMax);

        for (let i = 0; i < 5; i += 1) {
            const suffix = String(1000 + Math.floor(Math.random() * 9000));
            const candidate = `${trimmedBase}_${suffix}`;
            const existing = await prisma.userProfile.findFirst({
                where: {
                    username: candidate,
                    ...(userId ? { userId: { not: userId } } : {}),
                },
                select: { id: true },
            });
            if (!existing) return candidate;
        }

        const randomSuffix = crypto.randomBytes(4).toString("hex");
        const fallbackBase = base.slice(0, Math.max(1, maxLength - (1 + randomSuffix.length)));
        return `${fallbackBase}_${randomSuffix}`;
    }

    detectUniversity(email) {
        const domain = email?.split("@")[1]?.toLowerCase();
        if (!domain) return null;
        return universityDomains.find((u) => u.domains.some((d) => domain.endsWith(d)));
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

    async checkUsernameExists(username){
        const normalized = this.normalizeUsername(username);
        if (!normalized) {
            throw new BadRequestError("Username is required");
        }

        const userProfile = await prisma.userProfile.findFirst({
            where: { username: normalized },
            select: { id: true },
        });
        return !!userProfile;
    }


    async checkUsernameAvailability(username){
        
        const normalized = this.normalizeUsername(username);
        try {
            usernameOnlySchema.parse({ username: normalized });
        } catch (err) {
            throw new ValidationError("Invalid username");
        }

        const exists = await this.checkUsernameExists(normalized);
        return { available: !exists };
    }

    async assertUsernameAvailable(username) {
        const normalized = this.normalizeUsername(username);
        try {
            usernameOnlySchema.parse({ username: normalized });
        } catch (err) {
            throw new ValidationError("Invalid username");
        }

        const exists = await this.checkUsernameExists(normalized);
        if (exists) {
            throw new ConflictError("Username is already taken");
        }
        return true;
    }

    async createUser(userId, userData){
        if (!userId) {
            throw new BadRequestError("User id is required");
        }

        const data = createUserSchema.partial().parse(userData);
        const username = data.username ? this.normalizeUsername(data.username) : "";
        const {
            bio,
            profileImage,
            interests,
            department,
            level,
            universityId,
            universityName,
            yearOfStudy,
            graduationYear,
        } = data;

        const user = await prisma.user.findUnique({
            where: { id: userId },
            select: { email: true, firstName: true, lastName: true },
        });
        const fullName = user
            ? `${user.firstName || ""} ${user.lastName || ""}`.trim() || null
            : null;

        const existingProfile = await prisma.userProfile.findUnique({
            where: { userId },
            select: { id: true },
        });
        if (!existingProfile && !username) {
            throw new ValidationError("Username is required");
        }

        if (username) {
            if (existingProfile) {
                const usernameConflict = await prisma.userProfile.findFirst({
                    where: {
                        username,
                        userId: { not: userId },
                    },
                    select: { id: true },
                });
                if (usernameConflict) {
                    throw new ConflictError("Username is already taken");
                }
            } else {
                const usernameExists = await this.checkUsernameExists(username);
                if (usernameExists) {
                    throw new ConflictError("Username is already taken");
                }
            }
        }

        const detectedUniversity = this.detectUniversity(user?.email);

        if (existingProfile) {
            let resolvedUniversityId = universityId;
            if (detectedUniversity) {
                const universityRecord = await this.getOrCreateUniversity(detectedUniversity);
                resolvedUniversityId = universityRecord?.id || undefined;
            } else if (!resolvedUniversityId && universityName) {
                const universityRecord = await this.getOrCreateUniversity({
                    name: universityName,
                    domains: [],
                });
                resolvedUniversityId = universityRecord?.id || undefined;
            }

            const updatedProfile = await prisma.userProfile.update({
                where: { userId },
                data: {
                    username: username || undefined,
                    fullName: fullName || undefined,
                    bio,
                    profileImage,
                    interests,
                    department,
                    level,
                    universityId: resolvedUniversityId,
                    yearOfStudy,
                    graduationYear,
                },
            });

            return updatedProfile;
        }

        let resolvedUniversityId = universityId;
        if (detectedUniversity) {
            const universityRecord = await this.getOrCreateUniversity(detectedUniversity);
            resolvedUniversityId = universityRecord?.id || undefined;
        } else if (!resolvedUniversityId) {
            if (universityName) {
                const universityRecord = await this.getOrCreateUniversity({
                    name: universityName,
                    domains: [],
                });
                resolvedUniversityId = universityRecord?.id || undefined;
            } else {
                const universityRecord = await this.getOrCreateUniversity(detectedUniversity);
                resolvedUniversityId = universityRecord?.id || undefined;
            }
        }

        const userProfile = await prisma.userProfile.create({
            data: {
                userId,
                username,
                fullName,
                bio,
                profileImage,
                interests,
                department,
                level,
                universityId: resolvedUniversityId,
                yearOfStudy,
                graduationYear,
            },
        });

        return userProfile;
    }

    async getUserProfile(userId){
        if (!userId) {
            throw new BadRequestError("User id is required");
        }

        const userProfile = await prisma.userProfile.findUnique({
            where: { userId },
            include: {
                user: {
                    select: { role: true },
                },
                university: {
                    select: { name: true },
                },
            },
        });

        if (!userProfile) {
            throw new NotFoundError("User profile not found");
        }

        const universityName = userProfile.university?.name || null;
        const userRole = userProfile.user?.role || null;
        const { university, user, ...rest } = userProfile;
        return {
            ...rest,
            universityName,
            role: userRole,
        };
    }

   async searchUsernames(username, currentUserId) {

    const normalized = this.normalizeUsername(username);
    const safeCurrentUserId =
        typeof currentUserId === "string" && currentUserId.trim()
            ? currentUserId.trim()
            : undefined;

    if (!normalized) {
        throw new BadRequestError("Username is required");
    }

    // 1️ Exact matches
    const exactMatches = await prisma.userProfile.findMany({
        where: {
            username: {
                equals: normalized,
                mode: "insensitive"
            },
            ...(safeCurrentUserId ? { userId: { not: safeCurrentUserId } } : {})
        },
        select: {
            userId: true,
            username: true,
            profileImage: true
        },
        take: 5
    });

    // 2️ StartsWith matches
    const startsWithMatches = await prisma.userProfile.findMany({
        where: {
            username: {
                startsWith: normalized,
                mode: "insensitive"
            },
            userId: {
                notIn: [
                    ...exactMatches.map(u => u.userId),
                    ...(safeCurrentUserId ? [safeCurrentUserId] : [])
                ]
            }
        },
        select: {
            userId: true,
            username: true,
            profileImage: true
        },
        take: 5
    });

    // 3️Contains matches
    const containsMatches = await prisma.userProfile.findMany({
        where: {
            username: {
                contains: normalized,
                mode: "insensitive"
            },
            userId: {
                notIn: [
                    ...exactMatches.map(u => u.userId),
                    ...startsWithMatches.map(u => u.userId),
                    ...(safeCurrentUserId ? [safeCurrentUserId] : [])
                ]
            }
        },
        select: {
            userId: true,
            username: true,
            profileImage: true
        },
        take: 5
    });

    return [
        ...exactMatches,
        ...startsWithMatches,
        ...containsMatches
    ].slice(0, 8);
}


    async updateUserProfile(userId, updateData){
        if (!userId) {
            throw new BadRequestError("User id is required");
        }

        const data = createUserSchema.partial().parse(updateData);
        const user = await prisma.user.findUnique({
            where: { id: userId },
            select: { firstName: true, lastName: true },
        });
        const fullName = user
            ? `${user.firstName || ""} ${user.lastName || ""}`.trim() || null
            : null;
        const {
            username,
            bio,
            profileImage,
            interests,
            department,
            level,
            universityId,
            universityName,
            yearOfStudy,
            graduationYear,
        } = data;

        if (data.username) {
            const normalizedUsername = this.normalizeUsername(data.username);
            const existingProfile = await prisma.userProfile.findFirst({
                where: {
                    username: normalizedUsername,
                    userId: { not: userId },
                },
                select: { id: true },
            });
            if (existingProfile) {
                throw new ConflictError("Username is already taken");
            }
                data.username = normalizedUsername;
        }

        let resolvedUniversityId = universityId;
        if (!resolvedUniversityId && universityName) {
            const universityRecord = await this.getOrCreateUniversity({
                name: universityName,
                domains: [],
            });
            resolvedUniversityId = universityRecord?.id || undefined;
        }

        const updatedProfile = await prisma.userProfile.update({
            where: { userId },
            data: {
                ...data,
                universityId: resolvedUniversityId,
                fullName: fullName || undefined,
            }
        });

        return updatedProfile;
    }

    async updateProfileImage(userId, profileImage){
        if (!userId) {
            throw new BadRequestError("User id is required");
        }
        if (!profileImage) {
            throw new ValidationError("Profile image is required");
        }

        const updatedProfile = await prisma.userProfile.update({
            where: { userId },
            data: { profileImage },
        });

        return updatedProfile;
    }

    async deleteUserProfile(userId){
        if (!userId) {
            throw new BadRequestError("User id is required");
        }

        await prisma.userProfile.delete({
            where: { userId },
        });
        return { message: "User profile deleted successfully" };
    }

}
module.exports = new userService();
