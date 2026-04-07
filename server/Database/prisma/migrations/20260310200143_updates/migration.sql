/*
  Safe Prisma/Postgres migration:
  - Fixes Visibility enum safely
  - Handles old GROUP values
  - Adds googleId to User safely
  - Adds username to UserProfile safely and ensures uniqueness
  - Idempotent: safe if partially applied
*/

-- Enable pgcrypto for UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =========================
-- ENUM FIX (Visibility)
-- =========================

-- Map old enum value to new enum safely using new enum type
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'Visibility') AND NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'Visibility_new') THEN
    CREATE TYPE "Visibility_new" AS ENUM ('PUBLIC', 'PRIVATE');
  END IF;
END $$;

-- Convert old GROUP values to PRIVATE using current enum
UPDATE "Post"
SET "visibility" = 'PRIVATE'::"Visibility"
WHERE "visibility"::text = 'GROUP';

-- Remove default temporarily
ALTER TABLE "Post" ALTER COLUMN "visibility" DROP DEFAULT;

-- Convert column to new enum type
ALTER TABLE "Post"
ALTER COLUMN "visibility"
TYPE "Visibility_new"
USING ("visibility"::text::"Visibility_new");

-- Swap enums
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'Visibility') THEN
    ALTER TYPE "Visibility" RENAME TO "Visibility_old";
  END IF;
END $$;

ALTER TYPE "Visibility_new" RENAME TO "Visibility";

-- Drop old enum safely
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'Visibility_old') THEN
    DROP TYPE "Visibility_old";
  END IF;
END $$;

-- Restore default
ALTER TABLE "Post" ALTER COLUMN "visibility" SET DEFAULT 'PUBLIC';

-- =========================
-- USER TABLE FIXES
-- =========================
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "googleId" TEXT;

ALTER TABLE "User" ALTER COLUMN "passwordHash" DROP NOT NULL;

-- Remove duplicates to safely apply unique index
UPDATE "User"
SET "googleId" = NULL
WHERE "id" NOT IN (
  SELECT MIN("id")
  FROM "User"
  WHERE "googleId" IS NOT NULL
  GROUP BY "googleId"
);

-- =========================
-- USERPROFILE FIXES
-- =========================
ALTER TABLE "UserProfile" ADD COLUMN IF NOT EXISTS "username" TEXT;

-- Backfill usernames using UUIDs
UPDATE "UserProfile"
SET "username" = 'user_' || gen_random_uuid()
WHERE "username" IS NULL;

-- Ensure no accidental duplicates
UPDATE "UserProfile" up
SET "username" = 'user_' || gen_random_uuid()
WHERE EXISTS (
  SELECT 1 FROM "UserProfile" up2
  WHERE up."username" = up2."username"
  AND up."userId" <> up2."userId"
);

-- Enforce NOT NULL
ALTER TABLE "UserProfile" ALTER COLUMN "username" SET NOT NULL;

-- =========================
-- INDEXES (SAFE)
-- =========================
CREATE UNIQUE INDEX IF NOT EXISTS "User_googleId_key"
ON "User"("googleId");

CREATE UNIQUE INDEX IF NOT EXISTS "UserProfile_username_key"
ON "UserProfile"("username");
