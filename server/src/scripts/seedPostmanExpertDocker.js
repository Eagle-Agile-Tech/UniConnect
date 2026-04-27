const crypto = require("crypto");
const bcrypt = require("bcrypt");
const { Client } = require("pg");

const connectionString =
  process.env.DOCKER_DATABASE_URL ||
  "postgresql://postgres:postgres@127.0.0.1:5434/uniconnect?schema=public";

async function main() {
  const client = new Client({ connectionString });
  await client.connect();

  const institutionId = crypto.randomUUID();
  const userId = crypto.randomUUID();
  const profileId = crypto.randomUUID();
  const expertProfileId = crypto.randomUUID();
  const passwordHash = await bcrypt.hash("Test@12345", 12);

  await client.query("BEGIN");

  try {
    const institutionLookup = await client.query(
      'SELECT id FROM "Institution" WHERE name = $1 LIMIT 1',
      ["Jimma University"]
    );

    let liveInstitutionId = institutionLookup.rows[0]?.id ?? null;

    if (liveInstitutionId) {
      await client.query(
        'UPDATE "Institution" SET username = $1, type = $2, description = $3, website = $4, "verificationStatus" = $5, "secretCode" = $6, "secretCodeExpiresAt" = $7, "updatedAt" = NOW() WHERE id = $8',
        [
          "jimma_university",
          "UNIVERSITY",
          "Institution created for expert Postman testing.",
          "https://www.ju.edu.et",
          "VERIFIED",
          "POSTMAN01",
          new Date("2026-12-31T23:59:59.000Z"),
          liveInstitutionId,
        ]
      );
    } else {
      liveInstitutionId = institutionId;
      await client.query(
        'INSERT INTO "Institution" (id, username, name, type, description, website, "verificationStatus", "secretCode", "secretCodeExpiresAt", "createdAt", "updatedAt") VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW())',
        [
          liveInstitutionId,
          "jimma_university",
          "Jimma University",
          "UNIVERSITY",
          "Institution created for expert Postman testing.",
          "https://www.ju.edu.et",
          "VERIFIED",
          "POSTMAN01",
          new Date("2026-12-31T23:59:59.000Z"),
        ]
      );
    }

    const userLookup = await client.query(
      'SELECT id FROM "User" WHERE email = $1 LIMIT 1',
      ["expert.postman@uniconnect.dev"]
    );

    let liveUserId = userLookup.rows[0]?.id ?? null;

    if (liveUserId) {
      await client.query(
        'UPDATE "User" SET "firstName" = $1, "lastName" = $2, role = $3, "passwordHash" = $4, "isDeleted" = $5, "verificationStatus" = $6, "updatedAt" = NOW() WHERE id = $7',
        [
          "Postman",
          "Expert",
          "EXPERT",
          passwordHash,
          false,
          "APPROVED",
          liveUserId,
        ]
      );
    } else {
      liveUserId = userId;
      await client.query(
        'INSERT INTO "User" (id, email, "passwordHash", role, "createdAt", "updatedAt", "isDeleted", "firstName", "lastName", "verificationStatus") VALUES ($1, $2, $3, $4, NOW(), NOW(), $5, $6, $7, $8)',
        [
          liveUserId,
          "expert.postman@uniconnect.dev",
          passwordHash,
          "EXPERT",
          false,
          "Postman",
          "Expert",
          "APPROVED",
        ]
      );
    }

    const profileLookup = await client.query(
      'SELECT id FROM "UserProfile" WHERE "userId" = $1 LIMIT 1',
      [liveUserId]
    );

    if (profileLookup.rows[0]?.id) {
      await client.query(
        'UPDATE "UserProfile" SET username = $1, "fullName" = $2, bio = $3, "updatedAt" = NOW() WHERE id = $4',
        [
          "expert_postman",
          "Postman Expert",
          "Expert account for Postman testing",
          profileLookup.rows[0].id,
        ]
      );
    } else {
      await client.query(
        'INSERT INTO "UserProfile" (id, "userId", username, "fullName", bio, interests, "networkCount", "isNetworkedBy", "createdAt", "updatedAt") VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW())',
        [
          profileId,
          liveUserId,
          "expert_postman",
          "Postman Expert",
          "Expert account for Postman testing",
          [],
          0,
          false,
        ]
      );
    }

    const expertLookup = await client.query(
      'SELECT id FROM "ExpertProfile" WHERE "expertId" = $1 LIMIT 1',
      [liveUserId]
    );

    if (expertLookup.rows[0]?.id) {
      await client.query(
        'UPDATE "ExpertProfile" SET expertise = $1, bio = $2, "invitedByInstitutionId" = $3, "updatedAt" = NOW() WHERE id = $4',
        [
          "Computer Science",
          "Expert account for Postman testing",
          liveInstitutionId,
          expertLookup.rows[0].id,
        ]
      );
    } else {
      await client.query(
        'INSERT INTO "ExpertProfile" (id, "expertId", expertise, bio, "invitedByInstitutionId", "createdAt", "updatedAt") VALUES ($1, $2, $3, $4, $5, NOW(), NOW())',
        [
          expertProfileId,
          liveUserId,
          "Computer Science",
          "Expert account for Postman testing",
          liveInstitutionId,
        ]
      );
    }

    await client.query("COMMIT");

    console.log(
      JSON.stringify(
        {
          institution: {
            id: liveInstitutionId,
            name: "Jimma University",
            username: "jimma_university",
            secretCode: "POSTMAN01",
          },
          user: {
            id: liveUserId,
            email: "expert.postman@uniconnect.dev",
            role: "EXPERT",
          },
          login: {
            email: "expert.postman@uniconnect.dev",
            password: "Test@12345",
          },
        },
        null,
        2
      )
    );
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    await client.end();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
