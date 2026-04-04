-- Add username column to UserProfile and backfill
ALTER TABLE "UserProfile" ADD COLUMN "username" TEXT;

UPDATE "UserProfile"
SET "username" = 'user_' || substr("id", 1, 8)
WHERE "username" IS NULL;

ALTER TABLE "UserProfile" ALTER COLUMN "username" SET NOT NULL;
CREATE UNIQUE INDEX "UserProfile_username_key" ON "UserProfile"("username");

-- Remove GROUP from Visibility enum (ensure existing rows are remapped)
UPDATE "Post" SET "visibility" = 'PUBLIC' WHERE "visibility"::text = 'GROUP';

ALTER TABLE "Post" ALTER COLUMN "visibility" DROP DEFAULT;

ALTER TYPE "Visibility" RENAME TO "Visibility_old";
CREATE TYPE "Visibility" AS ENUM ('PUBLIC', 'PRIVATE');
ALTER TABLE "Post" ALTER COLUMN "visibility" TYPE "Visibility" USING ("visibility"::text::"Visibility");
ALTER TABLE "Post" ALTER COLUMN "visibility" SET DEFAULT 'PUBLIC';
DROP TYPE "Visibility_old";
