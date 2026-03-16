const prisma = require('../lib/prisma');
const bcrypt = require('bcrypt');
const { ADMIN_EMAIL , ADMIN_PASSWORD} = process.env;

async function initAdmin() {
    if (!ADMIN_EMAIL || !ADMIN_PASSWORD) {
        console.warn("Admin credentials not set. Skipping admin initialization.");
        return;
    }

    try {
        const existingAdmin = await prisma.user.findUnique({
            where: { email: ADMIN_EMAIL }
        });

        if (existingAdmin) {
            console.log("Admin already exists. Skipping initialization.");
            return;
        }

        const hashedPassword = await bcrypt.hash(ADMIN_PASSWORD, 12);

        const emailLocal = ADMIN_EMAIL.split('@')[0] || 'Admin';
        const firstName = emailLocal || 'Admin';
        const lastName = 'User';

        await prisma.user.create({
            data: {
                email: ADMIN_EMAIL,
                passwordHash: hashedPassword,
                role: "ADMIN",
                verificationStatus: 'APPROVED',
                firstName,
                lastName,
            }
        });

        console.log("Initial admin created successfully.");
    } catch (error) {
        console.error("Error initializing admin:", error);
    }
}

module.exports = initAdmin;

