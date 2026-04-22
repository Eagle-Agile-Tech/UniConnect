require("../config/env");

const crypto = require("crypto");
const bcrypt = require("bcrypt");
const prisma = require("../lib/prisma");

const DEMO_DOMAIN = "demo.uniconnect.local";
const DEFAULT_PASSWORD = "Admin123!";

function hashToken(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

function sessionRecord(userId, index, lastActiveHoursAgo = 2) {
  const sessionId = crypto.randomUUID();
  const refreshToken = `demo-refresh-${userId}-${index}-${Date.now()}`;
  return {
    id: sessionId,
    userId,
    token: hashToken(`demo-token-${sessionId}`),
    refreshToken: hashToken(refreshToken),
    deviceInfo: { device: "Seed Script" },
    ipAddress: "127.0.0.1",
    userAgent: "admin-demo-seed",
    lastActiveAt: new Date(Date.now() - lastActiveHoursAgo * 60 * 60 * 1000),
    expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
  };
}

async function ensureUniversity() {
  return prisma.university.upsert({
    where: { id: "demo-university-aa" },
    update: {
      name: "Addis Ababa Demo University",
      domains: ["demo.uniconnect.local"],
    },
    create: {
      id: "demo-university-aa",
      name: "Addis Ababa Demo University",
      domains: ["demo.uniconnect.local"],
    },
  });
}

async function ensureUser({
  email,
  firstName,
  lastName,
  role = "STUDENT",
  verificationStatus = "PENDING",
  verificationMethod = null,
  isDeleted = false,
  department = "Computer Science",
  level = "UNDERGRADUATE",
  yearOfStudy = 3,
  bio,
  username,
  universityId,
  password = DEFAULT_PASSWORD,
}) {
  const passwordHash = await bcrypt.hash(password, 12);

  return prisma.user.upsert({
    where: { email },
    update: {
      firstName,
      lastName,
      role,
      verificationStatus,
      verificationMethod,
      isDeleted,
      passwordHash,
      profile: {
        upsert: {
          update: {
            username,
            fullName: `${firstName} ${lastName}`,
            bio,
            department,
            level,
            yearOfStudy,
            universityId,
          },
          create: {
            username,
            fullName: `${firstName} ${lastName}`,
            bio,
            department,
            level,
            yearOfStudy,
            universityId,
          },
        },
      },
    },
    create: {
      email,
      firstName,
      lastName,
      role,
      verificationStatus,
      verificationMethod,
      isDeleted,
      passwordHash,
      profile: {
        create: {
          username,
          fullName: `${firstName} ${lastName}`,
          bio,
          department,
          level,
          yearOfStudy,
          universityId,
        },
      },
    },
    include: {
      profile: true,
    },
  });
}

async function ensureAdmin() {
  const configuredAdminEmail = process.env.ADMIN_EMAIL;
  if (configuredAdminEmail) {
    const existing = await prisma.user.findUnique({
      where: { email: configuredAdminEmail },
    });
    if (existing && existing.role === "ADMIN") {
      return existing;
    }
  }

  return ensureUser({
    email: `admin@${DEMO_DOMAIN}`,
    firstName: "Demo",
    lastName: "Admin",
    role: "ADMIN",
    verificationStatus: "APPROVED",
    verificationMethod: "ID_DOCUMENT_ADMIN",
    username: "demo-admin",
    bio: "Seeded admin for dashboard verification and moderation testing.",
    department: "Operations",
    universityId: null,
  });
}

async function cleanupDemoData(demoUserIds) {
  await prisma.messageReceipt.deleteMany({
    where: { userId: { in: demoUserIds } },
  });
  await prisma.session.deleteMany({
    where: { userId: { in: demoUserIds } },
  });
  await prisma.eventRegistration.deleteMany({
    where: { userId: { in: demoUserIds } },
  });
  await prisma.favorite.deleteMany({
    where: { userId: { in: demoUserIds } },
  });
  await prisma.postReaction.deleteMany({
    where: { userId: { in: demoUserIds } },
  });
  await prisma.commentReaction.deleteMany({
    where: { userId: { in: demoUserIds } },
  });
  await prisma.communityMember.deleteMany({
    where: { userId: { in: demoUserIds } },
  });
  await prisma.postComment.deleteMany({
    where: {
      OR: [
        { commenterId: { in: demoUserIds } },
        { post: { authorId: { in: demoUserIds } } },
      ],
    },
  });
  await prisma.post.deleteMany({
    where: { authorId: { in: demoUserIds } },
  });
  await prisma.idVerificationRequest.deleteMany({
    where: { userId: { in: demoUserIds } },
  });
  await prisma.community.deleteMany({
    where: {
      OR: [
        { createdById: { in: demoUserIds } },
        { name: { startsWith: "Demo Community" } },
      ],
    },
  });
}

async function main() {
  console.log("Seeding admin demo data...");

  const university = await ensureUniversity();
  const admin = await ensureAdmin();

  const demoUsers = await Promise.all([
    ensureUser({
      email: `pending.one@${DEMO_DOMAIN}`,
      firstName: "Hana",
      lastName: "Bekele",
      verificationStatus: "PENDING",
      verificationMethod: "ID_DOCUMENT_ADMIN",
      username: "hana.pending",
      bio: "Waiting for ID verification.",
      department: "Software Engineering",
      universityId: university.id,
    }),
    ensureUser({
      email: `pending.two@${DEMO_DOMAIN}`,
      firstName: "Samuel",
      lastName: "Tadesse",
      verificationStatus: "PENDING",
      verificationMethod: "ID_DOCUMENT_ADMIN",
      username: "samuel.pending",
      bio: "Second pending verification account.",
      department: "Information Systems",
      universityId: university.id,
    }),
    ensureUser({
      email: `verified.one@${DEMO_DOMAIN}`,
      firstName: "Rahel",
      lastName: "Mekonnen",
      verificationStatus: "APPROVED",
      verificationMethod: "UNIVERSITY_EMAIL",
      username: "rahel.verified",
      bio: "Verified student used for community and approved content.",
      department: "Architecture",
      universityId: university.id,
    }),
    ensureUser({
      email: `verified.two@${DEMO_DOMAIN}`,
      firstName: "Abel",
      lastName: "Kiros",
      verificationStatus: "APPROVED",
      verificationMethod: "UNIVERSITY_EMAIL",
      username: "abel.verified",
      bio: "Verified user for moderation coverage.",
      department: "Mechanical Engineering",
      universityId: university.id,
    }),
    ensureUser({
      email: `deleted.user@${DEMO_DOMAIN}`,
      firstName: "Liya",
      lastName: "Demisse",
      verificationStatus: "APPROVED",
      verificationMethod: "UNIVERSITY_EMAIL",
      username: "liya.deleted",
      bio: "Deleted account so safety metrics are non-zero.",
      department: "Business",
      universityId: university.id,
      isDeleted: true,
    }),
  ]);

  const demoUserIds = demoUsers.map((user) => user.id);
  await cleanupDemoData(demoUserIds);

  const [pendingOne, pendingTwo, verifiedOne, verifiedTwo, deletedUser] = demoUsers;

  await prisma.idVerificationRequest.createMany({
    data: [
      {
        userId: pendingOne.id,
        documentImage: "https://example.com/docs/hana-id.png",
        documentType: "STUDENT_ID",
        submittedNotes: "Demo pending verification request 1",
        status: "PENDING",
      },
      {
        userId: pendingTwo.id,
        documentImage: "https://example.com/docs/samuel-id.png",
        documentType: "NATIONAL_ID",
        submittedNotes: "Demo pending verification request 2",
        status: "PENDING",
      },
    ],
    skipDuplicates: true,
  });

  const community = await prisma.community.create({
    data: {
      name: "Demo Community Builders",
      description: "Seeded community for admin dashboard coverage.",
      createdById: verifiedOne.id,
    },
  });

  await prisma.communityMember.createMany({
    data: [
      {
        communityId: community.id,
        userId: verifiedOne.id,
        role: "ADMIN",
      },
      {
        communityId: community.id,
        userId: verifiedTwo.id,
        role: "MEMBER",
      },
      {
        communityId: community.id,
        userId: pendingOne.id,
        role: "MEMBER",
      },
    ],
    skipDuplicates: true,
  });

  const approvedPost = await prisma.post.create({
    data: {
      authorId: verifiedOne.id,
      communityId: community.id,
      content: "Approved demo post about community study circles and weekly reviews.",
      visibility: "PUBLIC",
      tags: ["demo", "approved"],
      category: "Community",
      moderationStatus: "APPROVED",
      moderatedById: admin.id,
    },
  });

  const pendingPost = await prisma.post.create({
    data: {
      authorId: verifiedTwo.id,
      content: "Pending demo post that should appear in the moderation queue.",
      visibility: "PUBLIC",
      tags: ["demo", "pending"],
      category: "General",
      moderationStatus: "PENDING",
    },
  });

  const rejectedPost = await prisma.post.create({
    data: {
      authorId: pendingOne.id,
      content: "Rejected demo post for moderation history and edge-case testing.",
      visibility: "PUBLIC",
      tags: ["demo", "rejected"],
      category: "Spam",
      moderationStatus: "REJECTED",
      moderatedById: admin.id,
    },
  });

  await prisma.postComment.createMany({
    data: [
      {
        postId: approvedPost.id,
        commenterId: pendingOne.id,
        content: "Approved comment on the seeded approved post.",
        moderationStatus: "APPROVED",
        moderatedById: admin.id,
      },
      {
        postId: approvedPost.id,
        commenterId: verifiedTwo.id,
        content: "Pending comment that should also appear in moderation.",
        moderationStatus: "PENDING",
      },
      {
        postId: pendingPost.id,
        commenterId: deletedUser.id,
        content: "Rejected comment added for moderation totals.",
        moderationStatus: "REJECTED",
        moderatedById: admin.id,
      },
      {
        postId: rejectedPost.id,
        commenterId: verifiedOne.id,
        content: "Another pending comment linked to a rejected post for demo coverage.",
        moderationStatus: "PENDING",
      },
    ],
  });

  await prisma.session.createMany({
    data: [
      sessionRecord(admin.id, 1, 1),
      sessionRecord(verifiedOne.id, 1, 3),
      sessionRecord(verifiedTwo.id, 1, 6),
      sessionRecord(pendingOne.id, 1, 12),
    ],
    skipDuplicates: true,
  });

  console.log("Admin demo data seeded successfully.");
  console.log("Demo admin login:", process.env.ADMIN_EMAIL || `admin@${DEMO_DOMAIN}`);
  console.log("Demo password:", DEFAULT_PASSWORD);
}

main()
  .catch((error) => {
    console.error("Admin demo seed failed:", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
