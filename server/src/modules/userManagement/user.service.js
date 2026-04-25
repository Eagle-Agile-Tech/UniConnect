const prisma = require("./../../lib/prisma");
const { createUserSchema } = require("./user.schema");
const crypto = require("crypto");
const buildUserResponse = require("../../lib/userResponse");
const networkRepo = require("../network/network.repository");

function normalizeFullName(profile) {
    const directFullName =
        typeof profile?.fullName === "string" ? profile.fullName.trim() : "";
    if (directFullName) return directFullName;

    const firstName =
        typeof profile?.user?.firstName === "string" ? profile.user.firstName.trim() : "";
    const lastName =
        typeof profile?.user?.lastName === "string" ? profile.user.lastName.trim() : "";
    const combined = `${firstName} ${lastName}`.trim();
    return combined || null;
}

function mapSearchProfile(profile) {
    return {
        userId: profile.userId,
        username: profile.username,
        profileImage: profile.profileImage,
        fullName: normalizeFullName(profile),
    };
}
const {
    BadRequestError,
    ConflictError,
    NotFoundError,
    ValidationError,
} = require("./../../errors");
const universityDomains = require("./../../lib/data/universities.json");
const usernameOnlySchema = createUserSchema.pick({ username: true });

function parseGraduationYear(value) {
    if (value === null || value === undefined || value === "") return undefined;
    if (typeof value === "number" && Number.isInteger(value)) {
        return new Date(Date.UTC(value, 0, 1));
    }
    if (typeof value === "string") {
        const trimmed = value.trim();
        if (/^\d{4}$/.test(trimmed)) {
            return new Date(Date.UTC(Number(trimmed), 0, 1));
        }
        const parsedDate = new Date(trimmed);
        if (!Number.isNaN(parsedDate.getTime())) {
            return parsedDate;
        }
    }
    if (value instanceof Date && !Number.isNaN(value.getTime())) return value;
    return null;
}

function parseYearOfStudy(value) {
    if (value === null || value === undefined || value === "") return undefined;
    if (typeof value === "number" && Number.isInteger(value)) return value;
    if (typeof value === "string") {
        const trimmed = value.trim().toLowerCase();
        if (/^\d+$/.test(trimmed)) return Number(trimmed);
        const wordMap = {
            first: 1,
            second: 2,
            third: 3,
            fourth: 4,
            fifth: 5,
            sixth: 6,
            seventh: 7,
            eighth: 8,
            ninth: 9,
            tenth: 10,
        };
        if (wordMap[trimmed]) return wordMap[trimmed];
    }
    return null;
}

function mapStudentFields(input) {
    const student = input?.student || {};
    const degree = input?.degree ?? student?.degree;
    const currentYear = input?.currentYear ?? student?.currentYear;
    const expectedGraduationYear =
        input?.expectedGraduationYear ??
        input?.graduationYear ??
        student?.expectedGraduationYear ??
        student?.graduationYear;
    const interests = input?.interests ?? student?.interests;

    const mapped = {};

    if (degree !== undefined) mapped.department = degree;

    const yearOfStudy = parseYearOfStudy(currentYear);
    if (yearOfStudy === null) {
        const err = new ValidationError("Invalid currentYear format");
        err.source = "body";
        throw err;
    }
    if (yearOfStudy !== undefined) mapped.yearOfStudy = yearOfStudy;

    const graduationYear = parseGraduationYear(expectedGraduationYear);
    if (graduationYear === null) {
        const err = new ValidationError("Invalid expectedGraduationYear format");
        err.source = "body";
        throw err;
    }
    if (graduationYear !== undefined) mapped.expectedGraduationYear = graduationYear;

    if (interests !== undefined) mapped.interests = interests;

    return mapped;
}

async function loadNetworkStatus(userId) {
    if (!userId) {
        return {
            networkCount: 0,
            isNetworkedBy: false,
            pendingNetworks: {
                incoming: 0,
                outgoing: 0,
                total: 0,
            },
        };
    }

    const [networkCount, incoming, outgoing] = await Promise.all([
        networkRepo.countUserNetworks(userId),
        networkRepo.countIncomingRequests(userId),
        networkRepo.countOutgoingRequests(userId),
    ]);

    return {
        networkCount,
        isNetworkedBy: networkCount > 0 || incoming > 0,
        pendingNetworks: {
            incoming,
            outgoing,
            total: incoming + outgoing,
        },
    };
}

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

        const mappedStudent = mapStudentFields(userData || {});
        const data = createUserSchema.partial().parse({ ...mappedStudent, ...userData });
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
            expectedGraduationYear,
        } = data;

        const user = await prisma.user.findUnique({
            where: { id: userId },
            select: { email: true, firstName: true, lastName: true },
        });

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

            await prisma.userProfile.update({
                where: { userId },
                data: {
                    username: username || undefined,
                    bio,
                    profileImage,
                    interests,
                    department,
                    level,
                    universityId: resolvedUniversityId,
                    yearOfStudy,
                    graduationYear: expectedGraduationYear,
                },
            });
            const freshUser = await prisma.user.findUnique({
                where: { id: userId },
                select: { id: true, firstName: true, lastName: true, email: true, role: true },
            });
            const profile = await prisma.userProfile.findUnique({
                where: { userId },
                include: { university: { select: { name: true } } },
            });
            const networkStatus = await loadNetworkStatus(userId);
            return buildUserResponse({
                user: freshUser,
                profile,
                networkStatus,
            });
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

        await prisma.userProfile.create({
            data: {
                userId,
                username,
                bio,
                profileImage,
                interests,
                department,
                level,
                universityId: resolvedUniversityId,
                yearOfStudy,
                graduationYear: expectedGraduationYear,
            },
        });
        const freshUser = await prisma.user.findUnique({
            where: { id: userId },
            select: { id: true, firstName: true, lastName: true, email: true, role: true },
        });
        const profile = await prisma.userProfile.findUnique({
            where: { userId },
            include: { university: { select: { name: true } } },
        });
        const networkStatus = await loadNetworkStatus(userId);
        return buildUserResponse({
            user: freshUser,
            profile,
            networkStatus,
        });
    }

    async getUserProfile(userId){
        if (!userId) {
            throw new BadRequestError("User id is required");
        }

        const userProfile = await prisma.userProfile.findUnique({
            where: { userId },
            include: {
                user: {
                    select: {
                        id: true,
                        firstName: true,
                        lastName: true,
                        email: true,
                        role: true,
                    },
                },
                university: {
                    select: { name: true },
                },
            },
        });

        if (!userProfile) {
            throw new NotFoundError("User profile not found");
        }

        const { university, user, ...restProfile } = userProfile;
        const networkStatus = await loadNetworkStatus(userId);
        return buildUserResponse({
            user,
            profile: {
                ...restProfile,
                university,
            },
            networkStatus,
        });
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
            profileImage: true,
            fullName: true,
            user: {
                select: {
                    firstName: true,
                    lastName: true,
                }
            }
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
            profileImage: true,
            fullName: true,
            user: {
                select: {
                    firstName: true,
                    lastName: true,
                }
            }
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
            profileImage: true,
            fullName: true,
            user: {
                select: {
                    firstName: true,
                    lastName: true,
                }
            }
        },
        take: 5
    });

    return [
        ...exactMatches,
        ...startsWithMatches,
        ...containsMatches
    ].slice(0, 8).map(mapSearchProfile);
}


    async updateUserProfile(userId, updateData){
        if (!userId) {
            throw new BadRequestError("User id is required");
        }

        const mappedStudent = mapStudentFields(updateData || {});
        const data = createUserSchema.partial().parse({ ...mappedStudent, ...updateData });
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
            expectedGraduationYear,
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

        await prisma.userProfile.update({
            where: { userId },
            data: {
                username: data.username,
                bio,
                profileImage,
                interests,
                department,
                level,
                yearOfStudy,
                graduationYear: expectedGraduationYear,
                universityId: resolvedUniversityId,
            }
        });
        const freshUser = await prisma.user.findUnique({
            where: { id: userId },
            select: { id: true, firstName: true, lastName: true, email: true, role: true },
        });
            const profile = await prisma.userProfile.findUnique({
                where: { userId },
                include: { university: { select: { name: true } } },
            });
            const networkStatus = await loadNetworkStatus(userId);
            return buildUserResponse({
                user: freshUser,
                profile,
                networkStatus,
            });
    }

    async updateProfileImage(userId, profileImage){
        if (!userId) {
            throw new BadRequestError("User id is required");
        }
        if (!profileImage) {
            throw new ValidationError("Profile image is required");
        }

        await prisma.userProfile.update({
            where: { userId },
            data: { profileImage },
        });
        const freshUser = await prisma.user.findUnique({
            where: { id: userId },
            select: { id: true, firstName: true, lastName: true, email: true, role: true },
        });
        const profile = await prisma.userProfile.findUnique({
            where: { userId },
            include: { university: { select: { name: true } } },
        });
        const networkStatus = await loadNetworkStatus(userId);
        return buildUserResponse({
            user: freshUser,
            profile,
            networkStatus,
        });
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

    async getUserProfileById(userId) {
        if(userId === undefined || userId === null) {
            throw new BadRequestError("User id is required");
        }

        const userProfile = await prisma.userProfile.findUnique({
            where: { userId },
            include: {
                user: {
                    select: {
                        id: true,
                        firstName: true,
                        lastName: true,
                        email: true,
                        role: true,
                    },
                },
                university: {
                    select: { name: true },
                },
            },
        });

        if (!userProfile) {
            throw new NotFoundError("User profile not found");
        }

        const { university, user, ...restProfile } = userProfile;
        const networkStatus = await loadNetworkStatus(userId);
        return buildUserResponse({
            user,
            profile: {
                ...restProfile,
                university,
            },
            networkStatus,
        });
    }

}
module.exports = new userService();
