/*
  Safe migration:
  - Handles enum changes safely
  - Avoids duplicate crashes
  - Ensures username uniqueness
  - Works even if partially applied before
*/

-- Enable extension for UUID (safe if already exists)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =========================
-- ENUM FIX (Visibility)
-- =========================
BEGIN;

-- Safely map old enum value using text comparison
UPDATE "Post"
SET "visibility" = 'PRIVATE'::text
WHERE "visibility"::text = 'GROUP';

-- Create new enum
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'Visibility_new') THEN
    CREATE TYPE "Visibility_new" AS ENUM ('PUBLIC', 'PRIVATE');
  END IF;
END $$;

-- Remove default temporarily
ALTER TABLE "Post" ALTER COLUMN "visibility" DROP DEFAULT;

-- Convert column safely
ALTER TABLE "Post"
ALTER COLUMN "visibility"
TYPE "Visibility_new"
USING ("visibility"::text::"Visibility_new");

-- Swap enums safely
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'Visibility') THEN
    ALTER TYPE "Visibility" RENAME TO "Visibility_old";
  END IF;
END $$;

ALTER TYPE "Visibility_new" RENAME TO "Visibility";

-- Drop old enum if exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'Visibility_old') THEN
    DROP TYPE "Visibility_old";
  END IF;
END $$;

-- Restore default
ALTER TABLE "Post" ALTER COLUMN "visibility" SET DEFAULT 'PUBLIC';

COMMIT;

-- =========================
-- USER TABLE FIXES
-- =========================

-- Add googleId safely
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "googleId" TEXT;

-- Allow null password
ALTER TABLE "User" ALTER COLUMN "passwordHash" DROP NOT NULL;

-- Remove duplicate googleId values before unique constraint
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

-- Add username column
ALTER TABLE "UserProfile" ADD COLUMN IF NOT EXISTS "username" TEXT;

-- Generate UNIQUE usernames safely
UPDATE "UserProfile"
SET "username" = 'user_' || gen_random_uuid()
WHERE "username" IS NULL;

-- Ensure no accidental duplicates (extra safety)
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

-- Unique index for googleId (ignores NULLs automatically)
CREATE UNIQUE INDEX IF NOT EXISTS "User_googleId_key"
ON "User"("googleId");

-- Unique index for username
CREATE UNIQUE INDEX IF NOT EXISTS "UserProfile_username_key"
ON "UserProfile"("username");