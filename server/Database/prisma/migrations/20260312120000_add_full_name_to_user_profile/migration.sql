-- Add fullName to UserProfile and backfill from User first/last name
ALTER TABLE "UserProfile" ADD COLUMN "fullName" TEXT;

UPDATE "UserProfile" up
SET "fullName" = TRIM(COALESCE(u."firstName", '') || ' ' || COALESCE(u."lastName", ''))
FROM "User" u
WHERE up."userId" = u."id";
