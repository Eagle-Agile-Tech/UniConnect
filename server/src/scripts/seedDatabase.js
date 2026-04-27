require("../config/env");

const bcrypt = require("bcrypt");
let prisma;

const SEED_DOMAIN = "seed.uniconnect.local";
const DEFAULT_PASSWORD = "SeedPass123!";
const INTERACTION_COUNT = 24;

function uuid(num) {
  return `00000000-0000-4000-8000-${String(num).padStart(12, "0")}`;
}

function parseArgs(argv) {
  const tables = [];
  let listOnly = false;

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--list") {
      listOnly = true;
      continue;
    }

    if (arg === "--table" || arg === "-t") {
      const next = argv[i + 1];
      if (!next) {
        throw new Error("Missing value for --table");
      }
      tables.push(...next.split(",").map((item) => item.trim()).filter(Boolean));
      i += 1;
      continue;
    }

    if (arg.startsWith("--table=")) {
      const value = arg.slice("--table=".length);
      tables.push(...value.split(",").map((item) => item.trim()).filter(Boolean));
      continue;
    }
  }

  return {
    tables,
    listOnly,
  };
}

function normalizeName(name) {
  return name.toLowerCase().replace(/[^a-z0-9]/g, "");
}

function inferModelName(model) {
  for (const [key, value] of Object.entries(prisma)) {
    if (value === model) {
      return key.charAt(0).toUpperCase() + key.slice(1);
    }
  }

  throw new Error("Unable to infer Prisma model name for delegate.");
}

function getAllowedScalarFields(modelName) {
  const modelDefinition = prisma._runtimeDataModel?.models?.[modelName];
  if (!modelDefinition) {
    throw new Error(`Prisma runtime model '${modelName}' was not found.`);
  }

  return new Set(
    modelDefinition.fields
      .filter((field) => field.kind !== "object")
      .map((field) => field.name),
  );
}

function sanitizeRowForModel(modelName, row, whereKey) {
  const allowedFields = getAllowedScalarFields(modelName);
  const sanitized = {};

  Object.entries(row).forEach(([key, value]) => {
    if (allowedFields.has(key)) {
      sanitized[key] = value;
    }
  });

  if (!(whereKey in sanitized)) {
    throw new Error(
      `Cannot seed ${modelName}: required where key '${whereKey}' is not available in the current Prisma model.`,
    );
  }

  return sanitized;
}

async function upsertMany(model, rows, whereKey = "id") {
  const modelName = inferModelName(model);

  for (const row of rows) {
    const sanitizedRow = sanitizeRowForModel(modelName, row, whereKey);
    try {
      await model.upsert({
        where: { [whereKey]: sanitizedRow[whereKey] },
        update: sanitizedRow,
        create: sanitizedRow,
      });
    } catch (error) {
      console.error(`Upsert failed for model ${modelName}`, {
        whereKey,
        whereValue: sanitizedRow[whereKey],
        row: sanitizedRow,
      });
      throw error;
    }
  }
}

const ids = {
  universities: {
    addis: uuid(1),
    adh: uuid(2),
    bdu: uuid(3),
  },
  users: {
    admin: uuid(101),
    institutionAdmin: uuid(102),
    expertOne: uuid(103),
    expertTwo: uuid(104),
    studentOne: uuid(105),
    studentTwo: uuid(106),
    studentThree: uuid(107),
    studentFour: uuid(108),
    studentFive: uuid(109),
    studentSix: uuid(110),
    studentSeven: uuid(111),
    studentEight: uuid(112),
  },
  institutions: {
    alpha: uuid(201),
    beta: uuid(202),
  },
  communities: {
    ai: uuid(301),
    careers: uuid(302),
    robotics: uuid(303),
  },
  chats: {
    directA: uuid(401),
    directB: uuid(402),
    group: uuid(403),
  },
  events: {
    one: uuid(501),
    two: uuid(502),
    three: uuid(503),
    four: uuid(504),
    five: uuid(505),
    six: uuid(506),
  },
  posts: {
    one: uuid(601),
    two: uuid(602),
    three: uuid(603),
    four: uuid(604),
    five: uuid(605),
    six: uuid(606),
    seven: uuid(607),
    eight: uuid(608),
    nine: uuid(609),
    ten: uuid(610),
    eleven: uuid(611),
    twelve: uuid(612),
  },
  courses: {
    one: uuid(901),
    two: uuid(902),
    three: uuid(903),
    four: uuid(904),
    five: uuid(905),
    six: uuid(906),
  },
};

const helpers = {
  async passwordHash() {
    return bcrypt.hash(DEFAULT_PASSWORD, 12);
  },
  dateDaysAgo(days) {
    return new Date(Date.now() - days * 24 * 60 * 60 * 1000);
  },
  dateDaysAhead(days) {
    return new Date(Date.now() + days * 24 * 60 * 60 * 1000);
  },
};

const seeds = {
  University: async () => {
    const rows = [
      {
        id: ids.universities.addis,
        name: "Addis Ababa Science University",
        domains: ["aasu.edu.et"],
      },
      {
        id: ids.universities.adh,
        name: "Adama Digital Hub University",
        domains: ["adhu.edu"],
      },
      {
        id: ids.universities.bdu,
        name: "Blue Nile Technology Institute",
        domains: ["bnti.edu"],
      },
    ];

    await upsertMany(prisma.university, rows);
    return rows.length;
  },

  User: async () => {
    const passwordHash = await helpers.passwordHash();

    const rows = [
      {
        id: ids.users.admin,
        firstName: "System",
        lastName: "Admin",
        email: `admin@${SEED_DOMAIN}`,
        passwordHash,
        role: "ADMIN",
        verificationStatus: "APPROVED",
        verificationMethod: "ID_DOCUMENT_ADMIN",
      },
      {
        id: ids.users.institutionAdmin,
        firstName: "Ivy",
        lastName: "Registrar",
        email: `institution.admin@${SEED_DOMAIN}`,
        passwordHash,
        role: "INSTITUTION",
        verificationStatus: "APPROVED",
        verificationMethod: "UNIVERSITY_EMAIL",
      },
      {
        id: ids.users.expertOne,
        firstName: "Marta",
        lastName: "Solomon",
        email: `expert.marta@${SEED_DOMAIN}`,
        passwordHash,
        role: "EXPERT",
        verificationStatus: "APPROVED",
        verificationMethod: "UNIVERSITY_EMAIL",
      },
      {
        id: ids.users.expertTwo,
        firstName: "Noah",
        lastName: "Kassa",
        email: `expert.noah@${SEED_DOMAIN}`,
        passwordHash,
        role: "EXPERT",
        verificationStatus: "APPROVED",
      },
      {
        id: ids.users.studentOne,
        firstName: "Abel",
        lastName: "Mekonnen",
        email: `student.abel@${SEED_DOMAIN}`,
        passwordHash,
        googleId: "seed-google-abel",
        role: "STUDENT",
        verificationStatus: "APPROVED",
        verificationMethod: "UNIVERSITY_EMAIL",
      },
      {
        id: ids.users.studentTwo,
        firstName: "Beth",
        lastName: "Tadesse",
        email: `student.beth@${SEED_DOMAIN}`,
        passwordHash,
        role: "STUDENT",
        verificationStatus: "PENDING",
        verificationMethod: "ID_DOCUMENT_ADMIN",
      },
      {
        id: ids.users.studentThree,
        firstName: "Caleb",
        lastName: "Yosef",
        email: `student.caleb@${SEED_DOMAIN}`,
        passwordHash,
        role: "STUDENT",
        verificationStatus: "REJECTED",
      },
      {
        id: ids.users.studentFour,
        firstName: "Dina",
        lastName: "Alemu",
        email: `student.dina@${SEED_DOMAIN}`,
        passwordHash,
        role: "STUDENT",
        verificationStatus: "APPROVED",
        isDeleted: true,
      },
      {
        id: ids.users.studentFive,
        firstName: "Eden",
        lastName: "Gebru",
        email: `student.eden@${SEED_DOMAIN}`,
        passwordHash,
        role: "STUDENT",
        verificationStatus: "APPROVED",
      },
      {
        id: ids.users.studentSix,
        firstName: "Fikru",
        lastName: "Belay",
        email: `student.fikru@${SEED_DOMAIN}`,
        passwordHash,
        role: "STUDENT",
        verificationStatus: "PENDING",
      },
      {
        id: ids.users.studentSeven,
        firstName: "Gelila",
        lastName: "Tesfaye",
        email: `student.gelila@${SEED_DOMAIN}`,
        passwordHash,
        role: "STUDENT",
        verificationStatus: "APPROVED",
      },
      {
        id: ids.users.studentEight,
        firstName: "Henok",
        lastName: "Dawit",
        email: `student.henok@${SEED_DOMAIN}`,
        passwordHash,
        role: "STUDENT",
        verificationStatus: "APPROVED",
      },
    ];

    await upsertMany(prisma.user, rows);
    return rows.length;
  },

  UserProfile: async () => {
    const rows = [
      {
        id: uuid(1001),
        userId: ids.users.admin,
        username: "seed-admin",
        fullName: "System Admin",
        bio: "Seeded admin account for moderation workflows.",
        interests: ["moderation", "ops"],
      },
      {
        id: uuid(1002),
        userId: ids.users.institutionAdmin,
        username: "ivy.registrar",
        fullName: "Ivy Registrar",
        bio: "Institution manager for seed data.",
        universityId: ids.universities.addis,
        department: "Academic Affairs",
        level: "GRADUATED",
      },
      {
        id: uuid(1003),
        userId: ids.users.expertOne,
        username: "marta.sol",
        fullName: "Marta Solomon",
        bio: "Expert in AI product design.",
        interests: ["ai", "design", "mentorship"],
        universityId: ids.universities.adh,
        department: "Computer Science",
        level: "POSTGRADUATE",
      },
      {
        id: uuid(1004),
        userId: ids.users.expertTwo,
        username: "noah.kassa",
        fullName: "Noah Kassa",
        bio: "Data engineering mentor.",
        interests: ["data", "mlops"],
        universityId: ids.universities.bdu,
        department: "Data Systems",
        level: "GRADUATED",
      },
      {
        id: uuid(1005),
        userId: ids.users.studentOne,
        username: "abel.m",
        fullName: "Abel Mekonnen",
        bio: "Building community projects.",
        interests: ["robotics", "backend"],
        universityId: ids.universities.addis,
        department: "Software Engineering",
        level: "UNDERGRADUATE",
        yearOfStudy: 3,
      },
      {
        id: uuid(1006),
        userId: ids.users.studentTwo,
        username: "beth.t",
        fullName: "Beth Tadesse",
        bio: "Interested in data visualization.",
        interests: ["data", "visualization"],
        universityId: ids.universities.adh,
        department: "Information Systems",
        level: "UNDERGRADUATE",
        yearOfStudy: 2,
      },
      {
        id: uuid(1007),
        userId: ids.users.studentThree,
        username: "caleb.y",
        fullName: "Caleb Yosef",
        bio: "Currently waiting to resolve verification.",
        interests: ["networking"],
        universityId: ids.universities.addis,
        department: "Computer Science",
        level: "UNDERGRADUATE",
        yearOfStudy: 1,
      },
      {
        id: uuid(1008),
        userId: ids.users.studentFour,
        username: "dina.a",
        fullName: "Dina Alemu",
        bio: "Soft deleted user for edge-case testing.",
        interests: ["events"],
      },
      {
        id: uuid(1009),
        userId: ids.users.studentFive,
        username: "eden.g",
        fullName: "Eden Gebru",
        bio: "Exploring mobile engineering.",
        interests: ["flutter", "community"],
        universityId: ids.universities.bdu,
        department: "Computer Engineering",
        level: "UNDERGRADUATE",
        yearOfStudy: 4,
      },
      {
        id: uuid(1010),
        userId: ids.users.studentSix,
        username: "fikru.b",
        fullName: "Fikru Belay",
        bio: "New member in the network.",
        interests: ["ai", "events"],
        universityId: ids.universities.adh,
        department: "Applied Math",
        level: "POSTGRADUATE",
      },
      {
        id: uuid(1011),
        userId: ids.users.studentSeven,
        username: "gelila.t",
        fullName: "Gelila Tesfaye",
        bio: "Focused on social impact products.",
        interests: ["ngo", "community", "product"],
        universityId: ids.universities.addis,
        department: "Business Informatics",
        level: "GRADUATED",
      },
      {
        id: uuid(1012),
        userId: ids.users.studentEight,
        username: "henok.d",
        fullName: "Henok Dawit",
        bio: "Starting out in cloud systems.",
        interests: ["cloud", "devops"],
        universityId: ids.universities.bdu,
        department: "Information Technology",
        level: "UNDERGRADUATE",
        yearOfStudy: 2,
      },
    ];

    await upsertMany(prisma.userProfile, rows);
    return rows.length;
  },

  Institution: async () => {
    const rows = [
      {
        id: ids.institutions.alpha,
        username: "alpha-university",
        name: "Alpha University",
        type: "UNIVERSITY",
        description: "Seeded university institution profile",
        website: "https://alpha.example.edu",
        verificationStatus: "VERIFIED",
        verificationDocument: "https://files.example.edu/institutions/alpha-verify.pdf",
        userId: ids.users.institutionAdmin,
        profileUserId: ids.users.institutionAdmin,
        secretCode: "ALPHA-SEED-CODE",
        secretCodeExpiresAt: helpers.dateDaysAhead(30),
        verifiedAt: helpers.dateDaysAgo(18),
        verifiedById: ids.users.admin,
      },
      {
        id: ids.institutions.beta,
        username: "beta-research",
        name: "Beta Research Center",
        type: "RESEARCH_CENTER",
        description: "Seeded research center with pending verification",
        website: "https://beta.example.org",
        verificationStatus: "PENDING",
        verificationDocument: "https://files.example.edu/institutions/beta-verify.pdf",
        secretCode: "BETA-SEED-CODE",
        secretCodeExpiresAt: helpers.dateDaysAhead(7),
      },
    ];

    await upsertMany(prisma.institution, rows);
    return rows.length;
  },

  InstitutionVerificationRequest: async () => {
    const rows = [
      {
        id: uuid(2101),
        institutionId: ids.institutions.alpha,
        documentUrl: "https://files.example.edu/institutions/alpha-request.pdf",
        status: "APPROVED",
        reviewedById: ids.users.admin,
        reviewedAt: helpers.dateDaysAgo(17),
      },
      {
        id: uuid(2102),
        institutionId: ids.institutions.beta,
        documentUrl: "https://files.example.edu/institutions/beta-request.pdf",
        status: "PENDING",
      },
    ];

    await upsertMany(prisma.institutionVerificationRequest, rows);
    return rows.length;
  },

  IdVerificationRequest: async () => {
    const rows = [
      {
        id: uuid(2201),
        userId: ids.users.studentTwo,
        documentImage: "https://files.example.edu/id/beth-id.png",
        documentType: "STUDENT_ID",
        submittedNotes: "Need verification for internship application.",
        status: "PENDING",
      },
      {
        id: uuid(2202),
        userId: ids.users.studentThree,
        documentImage: "https://files.example.edu/id/caleb-id.png",
        documentType: "NATIONAL_ID",
        submittedNotes: "Resubmitting with better image quality.",
        status: "REJECTED",
        reviewedById: ids.users.admin,
        reviewedAt: helpers.dateDaysAgo(4),
        adminComment: "Document text was unreadable.",
      },
      {
        id: uuid(2203),
        userId: ids.users.studentSix,
        documentImage: "https://files.example.edu/id/fikru-id.png",
        documentType: "PASSPORT",
        submittedNotes: "Verification for event access.",
        status: "APPROVED",
        reviewedById: ids.users.admin,
        reviewedAt: helpers.dateDaysAgo(1),
        adminComment: "Approved.",
      },
    ];

    await upsertMany(prisma.idVerificationRequest, rows);
    return rows.length;
  },

  ExpertProfile: async () => {
    const rows = [
      {
        id: uuid(2301),
        expertId: ids.users.expertOne,
        expertise: "AI Product Strategy",
        bio: "Helping students validate AI startup ideas.",
        invitedByInstitutionId: ids.institutions.alpha,
      },
      {
        id: uuid(2302),
        expertId: ids.users.expertTwo,
        expertise: "Data Engineering",
        bio: "Works on scalable analytics systems.",
        invitedByInstitutionId: ids.institutions.beta,
      },
    ];

    await upsertMany(prisma.expertProfile, rows);
    return rows.length;
  },

  ExpertInvitation: async () => {
    const rows = [
      {
        id: uuid(2401),
        email: `invite.pending@${SEED_DOMAIN}`,
        institutionId: ids.institutions.alpha,
        status: "PENDING",
        token: "seed-invite-token-pending",
        expiresAt: helpers.dateDaysAhead(10),
      },
      {
        id: uuid(2402),
        email: `invite.approved@${SEED_DOMAIN}`,
        institutionId: ids.institutions.alpha,
        status: "APPROVED",
        token: "seed-invite-token-approved",
        expiresAt: helpers.dateDaysAhead(5),
      },
      {
        id: uuid(2403),
        email: `invite.rejected@${SEED_DOMAIN}`,
        institutionId: ids.institutions.beta,
        status: "REJECTED",
        token: "seed-invite-token-rejected",
        expiresAt: helpers.dateDaysAhead(2),
      },
    ];

    await upsertMany(prisma.expertInvitation, rows);
    return rows.length;
  },

  Community: async () => {
    const rows = [
      {
        id: ids.communities.ai,
        name: "AI Builders Circle",
        description: "Sharing practical AI projects and critique sessions.",
        createdById: ids.users.studentOne,
      },
      {
        id: ids.communities.careers,
        name: "Career Launchpad",
        description: "Resume reviews and mock interviews.",
        createdById: ids.users.expertOne,
      },
      {
        id: ids.communities.robotics,
        name: "Robotics Lab",
        description: "Prototype robots and hardware demos.",
        createdById: ids.users.studentFive,
      },
    ];

    await upsertMany(prisma.community, rows);
    return rows.length;
  },

  CommunityMember: async () => {
    const rows = [
      { id: uuid(3201), communityId: ids.communities.ai, userId: ids.users.studentOne, role: "ADMIN" },
      { id: uuid(3202), communityId: ids.communities.ai, userId: ids.users.studentTwo, role: "MEMBER" },
      { id: uuid(3203), communityId: ids.communities.ai, userId: ids.users.expertOne, role: "MEMBER" },
      { id: uuid(3204), communityId: ids.communities.careers, userId: ids.users.expertOne, role: "ADMIN" },
      { id: uuid(3205), communityId: ids.communities.careers, userId: ids.users.studentThree, role: "MEMBER" },
      { id: uuid(3206), communityId: ids.communities.careers, userId: ids.users.studentSeven, role: "MEMBER" },
      { id: uuid(3207), communityId: ids.communities.robotics, userId: ids.users.studentFive, role: "ADMIN" },
      { id: uuid(3208), communityId: ids.communities.robotics, userId: ids.users.studentEight, role: "MEMBER" },
      { id: uuid(3209), communityId: ids.communities.robotics, userId: ids.users.expertTwo, role: "MEMBER" },
    ];

    await upsertMany(prisma.communityMember, rows);
    return rows.length;
  },

  Chat: async () => {
    const rows = [
      {
        id: ids.chats.directA,
        type: "DIRECT",
        uniqueKey: "seed-direct-abel-beth",
      },
      {
        id: ids.chats.directB,
        type: "DIRECT",
        uniqueKey: "seed-direct-marta-noah",
      },
      {
        id: ids.chats.group,
        type: "GROUP",
        name: "Seed Product Guild",
        avatarUrl: "https://images.example.edu/chats/product-guild.png",
        createdById: ids.users.expertOne,
      },
    ];

    await upsertMany(prisma.chat, rows);
    return rows.length;
  },

  ChatParticipant: async () => {
    const rows = [
      { id: uuid(4201), chatId: ids.chats.directA, userId: ids.users.studentOne, lastReadAt: helpers.dateDaysAgo(1) },
      { id: uuid(4202), chatId: ids.chats.directA, userId: ids.users.studentTwo, lastReadAt: helpers.dateDaysAgo(2) },
      { id: uuid(4203), chatId: ids.chats.directB, userId: ids.users.expertOne, lastReadAt: helpers.dateDaysAgo(1) },
      { id: uuid(4204), chatId: ids.chats.directB, userId: ids.users.expertTwo, lastReadAt: helpers.dateDaysAgo(1) },
      { id: uuid(4205), chatId: ids.chats.group, userId: ids.users.expertOne, lastReadAt: helpers.dateDaysAgo(1) },
      { id: uuid(4206), chatId: ids.chats.group, userId: ids.users.studentOne, lastReadAt: helpers.dateDaysAgo(1) },
      { id: uuid(4207), chatId: ids.chats.group, userId: ids.users.studentFive, lastReadAt: helpers.dateDaysAgo(3) },
      { id: uuid(4208), chatId: ids.chats.group, userId: ids.users.studentEight },
    ];

    await upsertMany(prisma.chatParticipant, rows);
    return rows.length;
  },

  Message: async () => {
    const rows = [
      { id: uuid(4301), chatId: ids.chats.directA, senderId: ids.users.studentOne, content: "Hey Beth, are you joining the hackathon?", clientMessageId: "seed-dm-1" },
      { id: uuid(4302), chatId: ids.chats.directA, senderId: ids.users.studentTwo, content: "Yes, still finalizing my team.", clientMessageId: "seed-dm-2" },
      { id: uuid(4303), chatId: ids.chats.directA, senderId: ids.users.studentOne, content: "Great, lets sync after class.", clientMessageId: "seed-dm-3" },
      { id: uuid(4304), chatId: ids.chats.directB, senderId: ids.users.expertOne, content: "Can you review the data pipeline draft?", clientMessageId: "seed-expert-dm-1" },
      { id: uuid(4305), chatId: ids.chats.directB, senderId: ids.users.expertTwo, content: "Sure, send me the repository link.", clientMessageId: "seed-expert-dm-2" },
      { id: uuid(4306), chatId: ids.chats.group, senderId: ids.users.expertOne, content: "Welcome to Product Guild. Share your weekly wins.", clientMessageId: "seed-group-1" },
      { id: uuid(4307), chatId: ids.chats.group, senderId: ids.users.studentOne, content: "Shipped onboarding updates this week.", clientMessageId: "seed-group-2" },
      { id: uuid(4308), chatId: ids.chats.group, senderId: ids.users.studentFive, content: "Working on chatbot analytics dashboard.", clientMessageId: "seed-group-3" },
      { id: uuid(4309), chatId: ids.chats.group, senderId: ids.users.studentEight, content: "Can someone review my API schema?", clientMessageId: "seed-group-4" },
    ];

    await upsertMany(prisma.message, rows);
    return rows.length;
  },

  MessageReceipt: async () => {
    const rows = [
      { id: uuid(4401), messageId: uuid(4301), userId: ids.users.studentTwo, deliveredAt: helpers.dateDaysAgo(2), readAt: helpers.dateDaysAgo(2) },
      { id: uuid(4402), messageId: uuid(4302), userId: ids.users.studentOne, deliveredAt: helpers.dateDaysAgo(2), readAt: helpers.dateDaysAgo(2) },
      { id: uuid(4403), messageId: uuid(4306), userId: ids.users.studentOne, deliveredAt: helpers.dateDaysAgo(1), readAt: helpers.dateDaysAgo(1) },
      { id: uuid(4404), messageId: uuid(4306), userId: ids.users.studentFive, deliveredAt: helpers.dateDaysAgo(1) },
      { id: uuid(4405), messageId: uuid(4306), userId: ids.users.studentEight, deliveredAt: helpers.dateDaysAgo(1) },
      { id: uuid(4406), messageId: uuid(4309), userId: ids.users.expertOne, deliveredAt: helpers.dateDaysAgo(1), readAt: helpers.dateDaysAgo(1) },
      { id: uuid(4407), messageId: uuid(4309), userId: ids.users.studentOne, deliveredAt: helpers.dateDaysAgo(1) },
    ];

    await upsertMany(prisma.messageReceipt, rows);
    return rows.length;
  },

  Event: async () => {
    const rows = [
      {
        id: ids.events.one,
        title: "AI Startup Pitch Night",
        description: "Students pitch AI startup ideas.",
        starts: helpers.dateDaysAhead(5),
        ends: helpers.dateDaysAhead(5),
        eventDay: helpers.dateDaysAhead(5),
        authorId: ids.users.expertOne,
        university: "Addis Ababa Science University",
        location: "Innovation Hall",
        views: 44,
        registrations: 15,
      },
      {
        id: ids.events.two,
        title: "Backend Interview Workshop",
        description: "Mock interviews and system design drills.",
        starts: helpers.dateDaysAhead(8),
        ends: helpers.dateDaysAhead(8),
        eventDay: helpers.dateDaysAhead(8),
        authorId: ids.users.expertTwo,
        university: "Adama Digital Hub University",
        location: "Tech Center 2",
        views: 29,
        registrations: 10,
      },
      {
        id: ids.events.three,
        title: "Career Week Resume Clinic",
        description: "Resume and portfolio reviews.",
        starts: helpers.dateDaysAhead(2),
        ends: helpers.dateDaysAhead(2),
        eventDay: helpers.dateDaysAhead(2),
        authorId: ids.users.studentSeven,
        university: "Alpha University",
        location: "Career Lab",
      },
      {
        id: ids.events.four,
        title: "Cloud Bootcamp",
        description: "Hands-on cloud architecture exercises.",
        starts: helpers.dateDaysAgo(3),
        ends: helpers.dateDaysAgo(3),
        eventDay: helpers.dateDaysAgo(3),
        authorId: ids.users.studentEight,
        university: "Blue Nile Technology Institute",
        location: "Room B4",
      },
      {
        id: ids.events.five,
        title: "Community Builders Summit",
        description: "Meetup for student community leaders.",
        starts: helpers.dateDaysAhead(14),
        ends: helpers.dateDaysAhead(14),
        eventDay: helpers.dateDaysAhead(14),
        authorId: ids.users.studentOne,
        university: "Addis Ababa Science University",
        location: "Main Auditorium",
      },
      {
        id: ids.events.six,
        title: "Research Poster Session",
        description: "Present current lab research.",
        starts: helpers.dateDaysAhead(21),
        ends: helpers.dateDaysAhead(21),
        eventDay: helpers.dateDaysAhead(21),
        authorId: ids.users.institutionAdmin,
        university: "Alpha University",
        location: "Research Wing",
      },
    ];

    await upsertMany(prisma.event, rows);
    return rows.length;
  },

  EventView: async () => {
    const rows = [
      { id: uuid(5201), eventId: ids.events.one, userId: ids.users.studentOne },
      { id: uuid(5202), eventId: ids.events.one, userId: ids.users.studentTwo },
      { id: uuid(5203), eventId: ids.events.one, userId: ids.users.studentFive },
      { id: uuid(5204), eventId: ids.events.two, userId: ids.users.studentSeven },
      { id: uuid(5205), eventId: ids.events.three, userId: ids.users.studentThree },
      { id: uuid(5206), eventId: ids.events.four, userId: ids.users.expertOne },
      { id: uuid(5207), eventId: ids.events.five, userId: ids.users.expertTwo },
      { id: uuid(5208), eventId: ids.events.six, userId: ids.users.studentEight },
    ];

    await upsertMany(prisma.eventView, rows);
    return rows.length;
  },

  EventRegistration: async () => {
    const rows = [
      { id: uuid(5401), eventId: ids.events.one, userId: ids.users.studentOne },
      { id: uuid(5402), eventId: ids.events.one, userId: ids.users.studentTwo },
      { id: uuid(5403), eventId: ids.events.two, userId: ids.users.studentFive },
      { id: uuid(5404), eventId: ids.events.three, userId: ids.users.studentThree },
      { id: uuid(5405), eventId: ids.events.five, userId: ids.users.studentSeven },
      { id: uuid(5406), eventId: ids.events.six, userId: ids.users.expertOne },
    ];

    await upsertMany(prisma.eventRegistration, rows);
    return rows.length;
  },

  Post: async () => {
    const rows = [
      {
        id: ids.posts.one,
        authorId: ids.users.studentOne,
        communityId: ids.communities.ai,
        content: "We deployed our first AI moderation pipeline in staging.",
        visibility: "PUBLIC",
        tags: ["ai", "backend"],
        category: "Engineering",
        moderationStatus: "APPROVED",
        moderatedById: ids.users.admin,
      },
      {
        id: ids.posts.two,
        authorId: ids.users.studentTwo,
        communityId: ids.communities.ai,
        content: "Any tips for improving recommendation quality with sparse data?",
        visibility: "PUBLIC",
        tags: ["ml", "question"],
        category: "Learning",
        moderationStatus: "PENDING",
      },
      {
        id: ids.posts.three,
        authorId: ids.users.studentThree,
        content: "Test post that should remain private for profile checks.",
        visibility: "PRIVATE",
        tags: ["private"],
        category: "Journal",
        moderationStatus: "APPROVED",
      },
      {
        id: ids.posts.four,
        authorId: ids.users.expertOne,
        communityId: ids.communities.careers,
        content: "Interview prep checklist for backend roles.",
        visibility: "PUBLIC",
        tags: ["career", "backend"],
        category: "Career",
        moderationStatus: "APPROVED",
        moderatedById: ids.users.admin,
      },
      {
        id: ids.posts.five,
        authorId: ids.users.expertTwo,
        communityId: ids.communities.robotics,
        content: "Rejected sample post for moderation dashboards.",
        visibility: "PUBLIC",
        tags: ["rejected"],
        category: "Moderation",
        moderationStatus: "REJECTED",
        moderatedById: ids.users.admin,
      },
      {
        id: ids.posts.six,
        authorId: ids.users.studentFive,
        content: "Built a tiny robot arm this weekend.",
        visibility: "PUBLIC",
        tags: ["robotics", "hardware"],
        category: "Projects",
        moderationStatus: "APPROVED",
      },
      {
        id: ids.posts.seven,
        authorId: ids.users.studentSix,
        content: "Looking for teammates for a civic-tech challenge.",
        visibility: "PUBLIC",
        tags: ["teamup"],
        category: "Community",
        moderationStatus: "PENDING",
      },
      {
        id: ids.posts.eight,
        authorId: ids.users.studentSeven,
        content: "Sharing event notes from the product workshop.",
        visibility: "PUBLIC",
        tags: ["notes", "product"],
        category: "Events",
        moderationStatus: "APPROVED",
      },
      {
        id: ids.posts.nine,
        authorId: ids.users.studentEight,
        content: "Cloud study resources that helped me this month.",
        visibility: "PUBLIC",
        tags: ["cloud", "study"],
        category: "Learning",
        moderationStatus: "APPROVED",
      },
      {
        id: ids.posts.ten,
        authorId: ids.users.studentOne,
        content: "Reposting backend checklist for my network.",
        visibility: "PUBLIC",
        tags: ["repost"],
        category: "Career",
        moderationStatus: "APPROVED",
        originalPostId: ids.posts.four,
        originalAuthorId: ids.users.expertOne,
      },
      {
        id: ids.posts.eleven,
        authorId: ids.users.institutionAdmin,
        content: "Institution announcement for research mini-grants.",
        visibility: "PUBLIC",
        tags: ["institution", "announcement"],
        category: "Notice",
        moderationStatus: "APPROVED",
      },
      {
        id: ids.posts.twelve,
        authorId: ids.users.studentFour,
        content: "Deleted-account authored post for edge-case reads.",
        visibility: "PUBLIC",
        tags: ["edge-case"],
        category: "Testing",
        moderationStatus: "APPROVED",
        isDeleted: true,
      },
    ];

    await upsertMany(prisma.post, rows);
    return rows.length;
  },

  PostComment: async () => {
    const rows = [
      { id: uuid(6501), postId: ids.posts.one, commenterId: ids.users.studentTwo, content: "Nice work. Did you log false positives?", moderationStatus: "APPROVED" },
      { id: uuid(6502), postId: ids.posts.one, commenterId: ids.users.expertOne, content: "Please share metrics next sprint.", moderationStatus: "PENDING" },
      { id: uuid(6503), postId: ids.posts.two, commenterId: ids.users.studentOne, content: "Try blending collaborative and content signals.", moderationStatus: "APPROVED" },
      { id: uuid(6504), postId: ids.posts.three, commenterId: ids.users.studentEight, content: "Private notes are useful for retrospectives.", moderationStatus: "APPROVED" },
      { id: uuid(6505), postId: ids.posts.four, commenterId: ids.users.studentSeven, content: "Can we do a mock interview session?", moderationStatus: "APPROVED" },
      { id: uuid(6506), postId: ids.posts.five, commenterId: ids.users.studentThree, content: "Rejected comment sample.", moderationStatus: "REJECTED", moderatedById: ids.users.admin },
      { id: uuid(6507), postId: ids.posts.six, commenterId: ids.users.expertTwo, content: "Add safety checks on the actuator.", moderationStatus: "APPROVED" },
      { id: uuid(6508), postId: ids.posts.seven, commenterId: ids.users.studentFive, content: "I can join if schedule matches.", moderationStatus: "PENDING" },
      { id: uuid(6509), postId: ids.posts.eight, commenterId: ids.users.studentOne, content: "These notes are super clear.", moderationStatus: "APPROVED" },
      { id: uuid(6510), postId: ids.posts.nine, commenterId: ids.users.studentSix, content: "Thanks for sharing these links.", moderationStatus: "APPROVED" },
      { id: uuid(6511), postId: ids.posts.ten, commenterId: ids.users.expertOne, content: "Appreciate the repost.", moderationStatus: "APPROVED" },
      { id: uuid(6512), postId: ids.posts.eleven, commenterId: ids.users.studentTwo, content: "Where can we apply for grants?", moderationStatus: "APPROVED" },
      { id: uuid(6513), postId: ids.posts.one, commenterId: ids.users.studentOne, parentCommentId: uuid(6501), content: "Yes, precision improved by 8 percent.", moderationStatus: "APPROVED" },
      { id: uuid(6514), postId: ids.posts.one, commenterId: ids.users.studentTwo, parentCommentId: uuid(6513), content: "Great result. Thanks for sharing.", moderationStatus: "APPROVED" },
      { id: uuid(6515), postId: ids.posts.four, commenterId: ids.users.expertOne, parentCommentId: uuid(6505), content: "Yes, I will host one this Friday.", moderationStatus: "APPROVED" },
      { id: uuid(6516), postId: ids.posts.twelve, commenterId: ids.users.admin, content: "Admin note on deleted-user content.", moderationStatus: "APPROVED" },
    ];

    await upsertMany(prisma.postComment, rows);
    return rows.length;
  },

  PostReaction: async () => {
    const rows = [
      { id: uuid(7001), type: "LIKE", userId: ids.users.studentTwo, postId: ids.posts.one },
      { id: uuid(7002), type: "LOVE", userId: ids.users.expertOne, postId: ids.posts.one },
      { id: uuid(7003), type: "INSIGHTFUL", userId: ids.users.studentFive, postId: ids.posts.one },
      { id: uuid(7004), type: "SUPPORT", userId: ids.users.studentSeven, postId: ids.posts.one },
      { id: uuid(7005), type: "CELEBRATE", userId: ids.users.studentEight, postId: ids.posts.one },
      { id: uuid(7006), type: "LIKE", userId: ids.users.studentOne, postId: ids.posts.two },
      { id: uuid(7007), type: "LOVE", userId: ids.users.expertTwo, postId: ids.posts.two },
      { id: uuid(7008), type: "INSIGHTFUL", userId: ids.users.studentThree, postId: ids.posts.two },
      { id: uuid(7009), type: "SUPPORT", userId: ids.users.studentSix, postId: ids.posts.three },
      { id: uuid(7010), type: "CELEBRATE", userId: ids.users.studentOne, postId: ids.posts.four },
      { id: uuid(7011), type: "LIKE", userId: ids.users.studentTwo, postId: ids.posts.four },
      { id: uuid(7012), type: "LOVE", userId: ids.users.studentSeven, postId: ids.posts.four },
      { id: uuid(7013), type: "INSIGHTFUL", userId: ids.users.studentEight, postId: ids.posts.five },
      { id: uuid(7014), type: "SUPPORT", userId: ids.users.expertOne, postId: ids.posts.six },
      { id: uuid(7015), type: "CELEBRATE", userId: ids.users.studentFive, postId: ids.posts.six },
      { id: uuid(7016), type: "LIKE", userId: ids.users.studentSix, postId: ids.posts.seven },
      { id: uuid(7017), type: "LOVE", userId: ids.users.studentSeven, postId: ids.posts.eight },
      { id: uuid(7018), type: "INSIGHTFUL", userId: ids.users.expertTwo, postId: ids.posts.nine },
      { id: uuid(7019), type: "SUPPORT", userId: ids.users.admin, postId: ids.posts.ten },
      { id: uuid(7020), type: "CELEBRATE", userId: ids.users.studentOne, postId: ids.posts.eleven },
    ];

    await upsertMany(prisma.postReaction, rows);
    return rows.length;
  },

  CommentReaction: async () => {
    const rows = [
      { id: uuid(7101), type: "LIKE", userId: ids.users.studentOne, commentId: uuid(6501) },
      { id: uuid(7102), type: "LOVE", userId: ids.users.studentTwo, commentId: uuid(6503) },
      { id: uuid(7103), type: "INSIGHTFUL", userId: ids.users.expertOne, commentId: uuid(6505) },
      { id: uuid(7104), type: "SUPPORT", userId: ids.users.studentSeven, commentId: uuid(6510) },
      { id: uuid(7105), type: "CELEBRATE", userId: ids.users.studentEight, commentId: uuid(6511) },
    ];

    await upsertMany(prisma.commentReaction, rows);
    return rows.length;
  },

  MessageReaction: async () => {
    const rows = [
      { id: uuid(7201), type: "LIKE", userId: ids.users.studentTwo, messageId: uuid(4301) },
      { id: uuid(7202), type: "LOVE", userId: ids.users.studentOne, messageId: uuid(4302) },
      { id: uuid(7203), type: "INSIGHTFUL", userId: ids.users.expertTwo, messageId: uuid(4304) },
      { id: uuid(7204), type: "SUPPORT", userId: ids.users.studentFive, messageId: uuid(4306) },
      { id: uuid(7205), type: "CELEBRATE", userId: ids.users.expertOne, messageId: uuid(4309) },
    ];

    await upsertMany(prisma.messageReaction, rows);
    return rows.length;
  },

  Favorite: async () => {
    const rows = [
      { id: uuid(7301), userId: ids.users.studentOne, postId: ids.posts.four },
      { id: uuid(7302), userId: ids.users.studentTwo, postId: ids.posts.one },
      { id: uuid(7303), userId: ids.users.studentFive, postId: ids.posts.nine },
      { id: uuid(7304), userId: ids.users.studentSeven, postId: ids.posts.eight },
      { id: uuid(7305), userId: ids.users.expertOne, postId: ids.posts.two },
      { id: uuid(7306), userId: ids.users.expertTwo, postId: ids.posts.one },
    ];

    await upsertMany(prisma.favorite, rows);
    return rows.length;
  },

  Media: async () => {
    const rows = [
      {
        id: uuid(7401),
        uploaderId: ids.users.studentOne,
        postId: ids.posts.one,
        fileUrl: "https://cdn.example.edu/posts/moderation-dashboard.png",
        fileType: "IMAGE",
      },
      {
        id: uuid(7402),
        uploaderId: ids.users.expertOne,
        postId: ids.posts.four,
        fileUrl: "https://cdn.example.edu/posts/interview-checklist.pdf",
        fileType: "DOCUMENT",
      },
      {
        id: uuid(7403),
        uploaderId: ids.users.studentFive,
        communityId: ids.communities.robotics,
        fileUrl: "https://cdn.example.edu/communities/robotics-showcase.mp4",
        fileType: "VIDEO",
      },
      {
        id: uuid(7404),
        uploaderId: ids.users.studentEight,
        messageId: uuid(4309),
        fileUrl: "https://cdn.example.edu/messages/api-schema.png",
        fileType: "IMAGE",
      },
    ];

    await upsertMany(prisma.media, rows);
    return rows.length;
  },

  NetworkRequest: async () => {
    const rows = [
      { id: uuid(7501), senderId: ids.users.studentOne, receiverId: ids.users.studentTwo },
      { id: uuid(7502), senderId: ids.users.studentThree, receiverId: ids.users.expertOne },
      { id: uuid(7503), senderId: ids.users.studentEight, receiverId: ids.users.expertTwo },
    ];

    await upsertMany(prisma.networkRequest, rows);
    return rows.length;
  },

  Network: async () => {
    const rows = [
      { id: uuid(7601), userAId: ids.users.studentOne, userBId: ids.users.studentFive },
      { id: uuid(7602), userAId: ids.users.studentTwo, userBId: ids.users.studentSeven },
      { id: uuid(7603), userAId: ids.users.expertOne, userBId: ids.users.studentEight },
      { id: uuid(7604), userAId: ids.users.expertTwo, userBId: ids.users.studentSix },
      { id: uuid(7605), userAId: ids.users.admin, userBId: ids.users.institutionAdmin },
    ];

    await upsertMany(prisma.network, rows);
    return rows.length;
  },

  Session: async () => {
    const rows = [
      {
        id: uuid(8001),
        userId: ids.users.admin,
        token: "seed-token-admin-1",
        refreshToken: "seed-refresh-admin-1",
        deviceInfo: { device: "SeedBot", platform: "web" },
        ipAddress: "127.0.0.10",
        userAgent: "seed-script/1.0",
        expiresAt: helpers.dateDaysAhead(14),
      },
      {
        id: uuid(8002),
        userId: ids.users.studentOne,
        token: "seed-token-student1-1",
        refreshToken: "seed-refresh-student1-1",
        deviceInfo: { device: "Pixel 8", platform: "android" },
        ipAddress: "127.0.0.11",
        userAgent: "flutter-app/2.0",
        lastActiveAt: helpers.dateDaysAgo(1),
        expiresAt: helpers.dateDaysAhead(7),
      },
      {
        id: uuid(8003),
        userId: ids.users.studentTwo,
        token: "seed-token-student2-1",
        refreshToken: "seed-refresh-student2-1",
        deviceInfo: { device: "iPhone", platform: "ios" },
        ipAddress: "127.0.0.12",
        userAgent: "flutter-app/2.0",
        lastActiveAt: helpers.dateDaysAgo(2),
        expiresAt: helpers.dateDaysAhead(7),
      },
      {
        id: uuid(8004),
        userId: ids.users.expertOne,
        token: "seed-token-expert1-1",
        refreshToken: "seed-refresh-expert1-1",
        deviceInfo: { device: "MacBook", platform: "web" },
        ipAddress: "127.0.0.13",
        userAgent: "chrome/seed",
        expiresAt: helpers.dateDaysAhead(21),
      },
      {
        id: uuid(8005),
        userId: ids.users.expertTwo,
        token: "seed-token-expert2-1",
        refreshToken: "seed-refresh-expert2-1",
        deviceInfo: { device: "Linux", platform: "web" },
        ipAddress: "127.0.0.14",
        userAgent: "firefox/seed",
        expiresAt: helpers.dateDaysAhead(21),
      },
      {
        id: uuid(8006),
        userId: ids.users.studentFive,
        token: "seed-token-student5-1",
        refreshToken: "seed-refresh-student5-1",
        deviceInfo: { device: "Galaxy", platform: "android" },
        ipAddress: "127.0.0.15",
        userAgent: "flutter-app/2.0",
        expiresAt: helpers.dateDaysAhead(4),
      },
    ];

    await upsertMany(prisma.session, rows);
    return rows.length;
  },

  AuditLog: async () => {
    const rows = [
      {
        id: uuid(8201),
        userId: ids.users.admin,
        actionType: "APPROVE",
        entityType: "Post",
        entityId: ids.posts.one,
        status: "SUCCESS",
      },
      {
        id: uuid(8202),
        userId: ids.users.admin,
        actionType: "REJECT",
        entityType: "Post",
        entityId: ids.posts.five,
        status: "SUCCESS",
      },
      {
        id: uuid(8203),
        userId: ids.users.studentOne,
        actionType: "CREATE",
        entityType: "Post",
        entityId: ids.posts.one,
        status: "SUCCESS",
      },
      {
        id: uuid(8204),
        userId: ids.users.studentTwo,
        actionType: "CREATE",
        entityType: "Comment",
        entityId: uuid(6501),
        status: "SUCCESS",
      },
      {
        id: uuid(8205),
        userId: ids.users.expertOne,
        actionType: "LOGIN",
        entityType: "Session",
        entityId: uuid(8004),
        status: "SUCCESS",
      },
      {
        id: uuid(8206),
        userId: ids.users.expertTwo,
        actionType: "UPDATE",
        entityType: "Course",
        entityId: ids.courses.two,
        status: "SUCCESS",
      },
      {
        id: uuid(8207),
        userId: ids.users.studentThree,
        actionType: "LOGIN",
        entityType: "Session",
        status: "FAILED",
        errorMessage: "Verification pending",
      },
      {
        id: uuid(8208),
        userId: ids.users.studentFive,
        actionType: "JOIN",
        entityType: "Community",
        entityId: ids.communities.robotics,
        status: "SUCCESS",
      },
      {
        id: uuid(8209),
        userId: ids.users.studentFour,
        actionType: "SOFT_DELETE",
        entityType: "User",
        entityId: ids.users.studentFour,
        status: "SUCCESS",
      },
      {
        id: uuid(8210),
        userId: ids.users.admin,
        actionType: "ROLE_CHANGE",
        entityType: "User",
        entityId: ids.users.institutionAdmin,
        status: "PENDING",
      },
    ];

    await upsertMany(prisma.auditLog, rows);
    return rows.length;
  },

  Course: async () => {
    const rows = [
      {
        id: ids.courses.one,
        title: "Practical Backend Architecture",
        description: "Design reliable APIs and data models.",
        videoId: "yt-backend-101",
        price: 0,
        expertId: ids.users.expertOne,
      },
      {
        id: ids.courses.two,
        title: "Data Engineering Foundations",
        description: "Pipelines, warehousing, and analytics.",
        videoId: "yt-data-201",
        price: 29.99,
        expertId: ids.users.expertTwo,
      },
      {
        id: ids.courses.three,
        title: "AI Product Discovery",
        description: "Validate user pain points and prototype quickly.",
        videoId: "yt-ai-301",
        price: 49.99,
        expertId: ids.users.expertOne,
      },
      {
        id: ids.courses.four,
        title: "Cloud Basics for Students",
        description: "Deploy and monitor student projects.",
        videoId: "yt-cloud-101",
        price: 19.99,
        expertId: ids.users.expertTwo,
      },
      {
        id: ids.courses.five,
        title: "Interview Readiness Sprint",
        description: "Practice coding and system design interviews.",
        videoId: "yt-career-401",
        price: 9.99,
        expertId: ids.users.expertOne,
      },
      {
        id: ids.courses.six,
        title: "Community Leadership",
        description: "Grow and sustain technical communities.",
        videoId: "yt-community-501",
        price: 0,
        expertId: ids.users.expertOne,
      },
    ];

    await upsertMany(prisma.course, rows);
    return rows.length;
  },

  SavedCourse: async () => {
    const rows = [
      { id: uuid(9301), userId: ids.users.studentOne, courseId: ids.courses.two },
      { id: uuid(9302), userId: ids.users.studentTwo, courseId: ids.courses.one },
      { id: uuid(9303), userId: ids.users.studentFive, courseId: ids.courses.three },
      { id: uuid(9304), userId: ids.users.studentSix, courseId: ids.courses.four },
      { id: uuid(9305), userId: ids.users.studentSeven, courseId: ids.courses.five },
      { id: uuid(9306), userId: ids.users.studentEight, courseId: ids.courses.six },
    ];

    await upsertMany(prisma.savedCourse, rows);
    return rows.length;
  },

  Purchase: async () => {
    const rows = [
      { id: uuid(9501), userId: ids.users.studentOne, courseId: ids.courses.two, paid: true },
      { id: uuid(9502), userId: ids.users.studentTwo, courseId: ids.courses.one, paid: false },
      { id: uuid(9503), userId: ids.users.studentFive, courseId: ids.courses.three, paid: true },
      { id: uuid(9504), userId: ids.users.studentSeven, courseId: ids.courses.five, paid: true },
      { id: uuid(9505), userId: ids.users.studentEight, courseId: ids.courses.four, paid: false },
    ];

    await upsertMany(prisma.purchase, rows);
    return rows.length;
  },

  UserInteraction: async () => {
    const baseRows = [
      [ids.users.studentOne, "POST", ids.posts.one, "VIEW", 1],
      [ids.users.studentOne, "POST", ids.posts.one, "LIKE", 2],
      [ids.users.studentOne, "COURSE", ids.courses.two, "SAVE", 2],
      [ids.users.studentTwo, "POST", ids.posts.two, "VIEW", 1],
      [ids.users.studentTwo, "POST", ids.posts.two, "COMMENT", 3],
      [ids.users.studentTwo, "EVENT", ids.events.one, "CLICK", 1],
      [ids.users.studentThree, "POST", ids.posts.five, "VIEW", 1],
      [ids.users.studentThree, "USER", ids.users.expertOne, "CLICK", 1],
      [ids.users.studentFour, "POST", ids.posts.twelve, "VIEW", 1],
      [ids.users.studentFive, "COURSE", ids.courses.three, "SAVE", 2],
      [ids.users.studentFive, "POST", ids.posts.six, "LIKE", 2],
      [ids.users.studentSix, "EVENT", ids.events.two, "VIEW", 1],
      [ids.users.studentSix, "EVENT", ids.events.two, "CLICK", 1],
      [ids.users.studentSeven, "POST", ids.posts.eight, "COMMENT", 3],
      [ids.users.studentSeven, "COURSE", ids.courses.five, "VIEW", 1],
      [ids.users.studentEight, "POST", ids.posts.nine, "LIKE", 2],
      [ids.users.studentEight, "USER", ids.users.expertTwo, "CLICK", 1],
      [ids.users.expertOne, "POST", ids.posts.one, "VIEW", 1],
      [ids.users.expertOne, "EVENT", ids.events.three, "CLICK", 1],
      [ids.users.expertTwo, "POST", ids.posts.four, "VIEW", 1],
      [ids.users.expertTwo, "COURSE", ids.courses.one, "CLICK", 1],
      [ids.users.institutionAdmin, "EVENT", ids.events.six, "VIEW", 1],
      [ids.users.admin, "POST", ids.posts.two, "VIEW", 1],
      [ids.users.admin, "USER", ids.users.studentThree, "CLICK", 1],
    ];

    const rows = baseRows.slice(0, INTERACTION_COUNT).map((entry, index) => ({
      id: uuid(10001 + index),
      userId: entry[0],
      targetType: entry[1],
      targetId: entry[2],
      interactionType: entry[3],
      value: entry[4],
      metadata: {
        seeded: true,
        sequence: index + 1,
      },
      createdAt: helpers.dateDaysAgo((index % 10) + 1),
    }));

    await upsertMany(prisma.userInteraction, rows);
    return rows.length;
  },

  UserProfileML: async () => {
    const rows = [
      {
        userId: ids.users.studentOne,
        interests: ["ai", "backend", "community"],
        skills: ["node", "postgres"],
        preferredCategories: ["Engineering", "Career"],
      },
      {
        userId: ids.users.studentTwo,
        interests: ["data", "visualization"],
        skills: ["sql", "python"],
        preferredCategories: ["Learning", "Events"],
      },
      {
        userId: ids.users.studentFive,
        interests: ["robotics", "embedded"],
        skills: ["c++", "cad"],
        preferredCategories: ["Projects", "Engineering"],
      },
      {
        userId: ids.users.expertOne,
        interests: ["product", "ai", "mentorship"],
        skills: ["strategy", "ux"],
        preferredCategories: ["Career", "Community"],
      },
      {
        userId: ids.users.expertTwo,
        interests: ["data", "infra"],
        skills: ["etl", "warehousing"],
        preferredCategories: ["Engineering", "Learning"],
      },
    ];

    await upsertMany(prisma.userProfileML, rows, "userId");
    return rows.length;
  },

  ContentEmbedding: async () => {
    const rows = [
      { id: uuid(11001), contentType: "POST", contentId: ids.posts.one },
      { id: uuid(11002), contentType: "POST", contentId: ids.posts.four },
      { id: uuid(11003), contentType: "EVENT", contentId: ids.events.one },
      { id: uuid(11004), contentType: "EVENT", contentId: ids.events.two },
      { id: uuid(11005), contentType: "COURSE", contentId: ids.courses.two },
      { id: uuid(11006), contentType: "COURSE", contentId: ids.courses.three },
    ];

    await upsertMany(prisma.contentEmbedding, rows);
    return rows.length;
  },

  Notification: async () => {
    const rows = [
      { id: uuid(12001), recipientId: ids.users.studentOne, actorId: ids.users.studentTwo, type: "REACTION", referenceId: ids.posts.one, referenceType: "POST", title: "New reaction", body: "Beth reacted to your post.", isRead: true, isDelivered: true },
      { id: uuid(12002), recipientId: ids.users.studentOne, actorId: ids.users.expertOne, type: "COMMENT", referenceId: uuid(6502), referenceType: "COMMENT", title: "New comment", body: "Marta commented on your post.", isRead: false, isDelivered: true },
      { id: uuid(12003), recipientId: ids.users.studentTwo, actorId: ids.users.studentOne, type: "FOLLOW", referenceId: ids.users.studentOne, referenceType: "USER", title: "New connection", body: "Abel connected with you.", isRead: false, isDelivered: true },
      { id: uuid(12004), recipientId: ids.users.studentTwo, actorId: ids.users.expertOne, type: "MESSAGE", referenceId: uuid(4306), referenceType: "MESSAGE", title: "New group message", body: "You have a new message in Product Guild.", isRead: false, isDelivered: true },
      { id: uuid(12005), recipientId: ids.users.studentThree, actorId: ids.users.admin, type: "SYSTEM", title: "Verification update", body: "Your verification request was reviewed.", isRead: true, isDelivered: true },
      { id: uuid(12006), recipientId: ids.users.studentFive, actorId: ids.users.studentOne, type: "REPOST", referenceId: ids.posts.ten, referenceType: "POST", title: "Post reposted", body: "Your post was reposted.", isRead: false, isDelivered: true },
      { id: uuid(12007), recipientId: ids.users.studentSeven, actorId: ids.users.expertTwo, type: "EVENT", referenceId: ids.events.two, referenceType: "EVENT", title: "Event reminder", body: "Backend Interview Workshop starts soon.", isRead: false, isDelivered: true },
      { id: uuid(12008), recipientId: ids.users.studentEight, actorId: ids.users.studentFive, type: "COMMUNITY", referenceId: ids.communities.robotics, referenceType: "COMMUNITY", title: "Community update", body: "New media was posted in Robotics Lab.", isRead: false, isDelivered: true },
      { id: uuid(12009), recipientId: ids.users.studentOne, actorId: ids.users.admin, type: "SYSTEM", title: "Policy update", body: "Community policy has been updated.", isRead: true, isDelivered: true },
      { id: uuid(12010), recipientId: ids.users.studentTwo, actorId: ids.users.admin, type: "SYSTEM", title: "Welcome", body: "Your account is ready to use.", isRead: true, isDelivered: true },
      { id: uuid(12011), recipientId: ids.users.studentThree, actorId: ids.users.admin, type: "SYSTEM", title: "Action required", body: "Please resubmit your ID image.", isRead: false, isDelivered: true },
      { id: uuid(12012), recipientId: ids.users.studentFour, actorId: ids.users.admin, type: "SYSTEM", title: "Account status", body: "Your account is marked as deleted in seed data.", isRead: true, isDelivered: true },
      { id: uuid(12013), recipientId: ids.users.studentFive, actorId: ids.users.expertOne, type: "COMMENT", referenceId: uuid(6507), referenceType: "COMMENT", title: "Comment reply", body: "Noah replied to your robotics post.", isRead: false, isDelivered: true },
      { id: uuid(12014), recipientId: ids.users.studentSix, actorId: ids.users.studentSeven, type: "FOLLOW", referenceId: ids.users.studentSeven, referenceType: "USER", title: "New follower", body: "Gelila is now in your network.", isRead: false, isDelivered: true },
      { id: uuid(12015), recipientId: ids.users.studentSeven, actorId: ids.users.studentSix, type: "FOLLOW", referenceId: ids.users.studentSix, referenceType: "USER", title: "Connection accepted", body: "Fikru accepted your request.", isRead: true, isDelivered: true },
      { id: uuid(12016), recipientId: ids.users.studentEight, actorId: ids.users.expertOne, type: "MESSAGE", referenceId: uuid(4309), referenceType: "MESSAGE", title: "Message feedback", body: "Marta reviewed your API schema request.", isRead: false, isDelivered: true },
      { id: uuid(12017), recipientId: ids.users.expertOne, actorId: ids.users.studentOne, type: "COMMENT", referenceId: uuid(6511), referenceType: "COMMENT", title: "New reply", body: "Abel replied to your repost.", isRead: false, isDelivered: true },
      { id: uuid(12018), recipientId: ids.users.expertTwo, actorId: ids.users.studentEight, type: "REACTION", referenceId: ids.posts.nine, referenceType: "POST", title: "Post reaction", body: "Henok reacted to your post.", isRead: true, isDelivered: true },
      { id: uuid(12019), recipientId: ids.users.admin, actorId: ids.users.studentTwo, type: "SYSTEM", referenceId: ids.posts.five, referenceType: "POST", title: "Moderation report", body: "A new report needs review.", isRead: false, isDelivered: true },
      { id: uuid(12020), recipientId: ids.users.admin, actorId: ids.users.studentThree, type: "SYSTEM", referenceId: ids.users.studentFour, referenceType: "USER", title: "User report", body: "A user report was submitted.", isRead: false, isDelivered: true },
      { id: uuid(12021), recipientId: ids.users.institutionAdmin, actorId: ids.users.admin, type: "SYSTEM", title: "Institution verified", body: "Alpha University verification approved.", isRead: false, isDelivered: true },
      { id: uuid(12022), recipientId: ids.users.institutionAdmin, actorId: ids.users.studentSeven, type: "EVENT", referenceId: ids.events.six, referenceType: "EVENT", title: "Event registration", body: "A participant registered for your event.", isRead: false, isDelivered: true },
      { id: uuid(12023), recipientId: ids.users.studentFive, actorId: ids.users.admin, type: "COMMUNITY", referenceId: ids.communities.robotics, referenceType: "COMMUNITY", title: "Community moderation", body: "Your community post was reviewed.", isRead: true, isDelivered: true },
      { id: uuid(12024), recipientId: ids.users.studentSix, actorId: ids.users.admin, type: "SYSTEM", title: "Verification approved", body: "Your ID verification has been approved.", isRead: false, isDelivered: true },
      { id: uuid(12025), recipientId: ids.users.studentOne, actorId: ids.users.expertTwo, type: "MESSAGE", referenceId: uuid(4305), referenceType: "MESSAGE", title: "Direct message", body: "Noah sent you a direct message.", isRead: false, isDelivered: true },
      { id: uuid(12026), recipientId: ids.users.studentTwo, actorId: ids.users.expertTwo, type: "EVENT", referenceId: ids.events.two, referenceType: "EVENT", title: "Event starts tomorrow", body: "Backend Interview Workshop starts tomorrow.", isRead: false, isDelivered: true },
    ];

    await upsertMany(prisma.notification, rows);
    return rows.length;
  },

  Report: async () => {
    const rows = [
      {
        id: uuid(13001),
        reporterId: ids.users.studentTwo,
        targetType: "POST",
        targetId: ids.posts.five,
        reason: "SPAM",
        message: "Looks like promotional spam content.",
        status: "PENDING",
      },
      {
        id: uuid(13002),
        reporterId: ids.users.studentThree,
        targetType: "USER",
        targetId: ids.users.studentFour,
        reason: "FAKE_ACCOUNT",
        message: "This account appears inactive and suspicious.",
        status: "PENDING",
      },
      {
        id: uuid(13003),
        reporterId: ids.users.studentFive,
        targetType: "POST",
        targetId: ids.posts.seven,
        reason: "HARASSMENT",
        message: "Potentially aggressive language.",
        status: "APPROVED",
        reviewedById: ids.users.admin,
        reviewedAt: helpers.dateDaysAgo(2),
        isFlagged: true,
      },
      {
        id: uuid(13004),
        reporterId: ids.users.studentSix,
        targetType: "POST",
        targetId: ids.posts.twelve,
        reason: "INAPPROPRIATE_CONTENT",
        message: "Looks off-topic for this feed.",
        status: "REJECTED",
        reviewedById: ids.users.admin,
        reviewedAt: helpers.dateDaysAgo(1),
      },
      {
        id: uuid(13005),
        reporterId: ids.users.studentSeven,
        targetType: "USER",
        targetId: ids.users.studentThree,
        reason: "OTHER",
        message: "Needs manual review.",
        status: "PENDING",
      },
    ];

    await upsertMany(prisma.report, rows);
    return rows.length;
  },
};

const dependencies = {
  User: ["University"],
  UserProfile: ["User", "University"],
  Institution: ["User"],
  InstitutionVerificationRequest: ["Institution", "User"],
  IdVerificationRequest: ["User"],
  ExpertProfile: ["User", "Institution"],
  ExpertInvitation: ["Institution"],
  Community: ["User"],
  CommunityMember: ["Community", "User"],
  Chat: ["User"],
  ChatParticipant: ["Chat", "User"],
  Message: ["Chat", "User"],
  MessageReceipt: ["Message", "User"],
  Event: ["User"],
  EventView: ["Event", "User"],
  EventRegistration: ["Event", "User"],
  Post: ["User", "Community"],
  PostComment: ["Post", "User"],
  PostReaction: ["Post", "User"],
  CommentReaction: ["PostComment", "User"],
  MessageReaction: ["Message", "User"],
  Favorite: ["Post", "User"],
  Media: ["User", "Post", "Community", "Message"],
  NetworkRequest: ["User"],
  Network: ["User"],
  Session: ["User"],
  AuditLog: ["User", "Post", "Course", "Session"],
  Course: ["User"],
  SavedCourse: ["Course", "User"],
  Purchase: ["Course", "User"],
  UserInteraction: ["User", "Post", "Event", "Course"],
  UserProfileML: ["User"],
  ContentEmbedding: ["Post", "Event", "Course"],
  Notification: ["User", "Post", "Event", "Message", "Community"],
  Report: ["User", "Post"],
};

const orderedTables = [
  "University",
  "User",
  "UserProfile",
  "Institution",
  "InstitutionVerificationRequest",
  "IdVerificationRequest",
  "ExpertProfile",
  "ExpertInvitation",
  "Community",
  "CommunityMember",
  "Chat",
  "ChatParticipant",
  "Message",
  "MessageReceipt",
  "Event",
  "EventView",
  "EventRegistration",
  "Post",
  "PostComment",
  "PostReaction",
  "CommentReaction",
  "MessageReaction",
  "Favorite",
  "Media",
  "NetworkRequest",
  "Network",
  "Session",
  "Course",
  "SavedCourse",
  "Purchase",
  "UserInteraction",
  "UserProfileML",
  "ContentEmbedding",
  "Notification",
  "Report",
  "AuditLog",
];

function resolveTableSelection(requestedRaw) {
  if (!requestedRaw.length || requestedRaw.some((value) => normalizeName(value) === "all")) {
    return [...orderedTables];
  }

  const nameMap = new Map(orderedTables.map((name) => [normalizeName(name), name]));
  const selected = new Set();

  function addWithDependencies(tableName) {
    const deps = dependencies[tableName] || [];
    for (const dep of deps) {
      addWithDependencies(dep);
    }
    selected.add(tableName);
  }

  for (const raw of requestedRaw) {
    const normalized = normalizeName(raw);
    const tableName = nameMap.get(normalized);
    if (!tableName) {
      throw new Error(`Unknown table '${raw}'. Use --list to view supported tables.`);
    }
    addWithDependencies(tableName);
  }

  return orderedTables.filter((name) => selected.has(name));
}

async function main() {
  const parsed = parseArgs(process.argv.slice(2));

  if (parsed.listOnly) {
    console.log("Supported tables:");
    orderedTables.forEach((table) => console.log(`- ${table}`));
    return;
  }

  prisma = require("../lib/prisma");

  const tablesToRun = resolveTableSelection(parsed.tables);

  console.log(`Seeding ${tablesToRun.length} table(s)...`);
  console.log(`Database: ${process.env.DATABASE_URL ? "configured" : "missing DATABASE_URL"}`);

  let totalRows = 0;

  for (const tableName of tablesToRun) {
    const runner = seeds[tableName];
    if (!runner) {
      throw new Error(`Seeder implementation missing for table ${tableName}`);
    }

    const count = await runner();
    totalRows += count;
    console.log(`- ${tableName}: upserted ${count} row(s)`);
  }

  console.log("Seed complete.");
  console.log(`Total upserted rows: ${totalRows}`);
  console.log(`Default seed user password: ${DEFAULT_PASSWORD}`);
}

main()
  .catch((error) => {
    console.error("Seed failed:", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    if (prisma) {
      await prisma.$disconnect();
    }
  });
