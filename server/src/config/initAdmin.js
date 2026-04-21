const prisma = require("../lib/prisma");
const bcrypt = require("bcrypt");
const { ADMIN_EMAIL, ADMIN_PASSWORD } = process.env;
const { isProduction } = require("./env");

async function createUserIfMissing(userData) {
  const existing = await prisma.user.findUnique({
    where: { email: userData.email },
  });
  if (existing) return false;

  const hashedPassword = await bcrypt.hash(userData.password, 12);
  await prisma.user.create({
    data: {
      email: userData.email,
      passwordHash: hashedPassword,
      role: userData.role,
      verificationStatus: "APPROVED",
      verificationMethod: "UNIVERSITY_EMAIL",
      firstName: userData.firstName,
      lastName: userData.lastName,
    },
  });
  return true;
}

async function initAdmin() {
  if (!ADMIN_EMAIL || !ADMIN_PASSWORD) {
    console.warn("Admin credentials not set. Skipping admin initialization.");
  } else {
    try {
      const created = await createUserIfMissing({
        email: ADMIN_EMAIL,
        password: ADMIN_PASSWORD,
        role: "ADMIN",
        firstName: ADMIN_EMAIL.split("@")[0] || "Admin",
        lastName: "User",
      });

      if (created) {
        console.log("Initial admin created successfully.");
      } else {
        console.log("Admin already exists. Skipping initialization.");
      }
    } catch (error) {
      console.error("Error initializing admin:", error);
    }
  }

  if (!isProduction) {
    const devUsers = [
      {
        email: "tsega@gmail.com",
        password: "expert123",
        role: "EXPERT",
        firstName: "Tsega",
        lastName: "Bogale",
      },
      {
        email: "tinademelash@gmail.com",
        password: "student123",
        role: "STUDENT",
        firstName: "Tinsae",
        lastName: "Demelash",
      },
    ];

    for (const user of devUsers) {
      try {
        const created = await createUserIfMissing(user);
        if (created) {
          console.log(`Dev user created: ${user.email}`);
        }
      } catch (error) {
        console.error(`Error creating dev user ${user.email}:`, error);
      }
    }
  }
}

module.exports = initAdmin;
