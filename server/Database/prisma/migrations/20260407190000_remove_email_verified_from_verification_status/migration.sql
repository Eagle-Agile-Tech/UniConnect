-- =========================
-- SAFE ENUM MIGRATION
-- =========================

-- Step 1: Normalize existing data safely (works even if enum changed)
UPDATE "User"
SET "verificationStatus" = 'APPROVED'
WHERE "verificationStatus"::text = 'EMAIL_VERIFIED';

UPDATE "IdVerificationRequest"
SET "status" = 'APPROVED'
WHERE "status"::text = 'EMAIL_VERIFIED';

-- Step 2: Rename old enum if it still exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'VerificationStatus') THEN
    ALTER TYPE "VerificationStatus" RENAME TO "VerificationStatus_old";
  END IF;
END $$;

-- Step 3: Create new enum if not exists
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'VerificationStatus') THEN
    CREATE TYPE "VerificationStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');
  END IF;
END $$;

-- Step 4: Update columns safely
ALTER TABLE "User"
  ALTER COLUMN "verificationStatus" DROP DEFAULT,
  ALTER COLUMN "verificationStatus"
  TYPE "VerificationStatus"
  USING ("verificationStatus"::text::"VerificationStatus");

ALTER TABLE "IdVerificationRequest"
  ALTER COLUMN "status" DROP DEFAULT,
  ALTER COLUMN "status"
  TYPE "VerificationStatus"
  USING ("status"::text::"VerificationStatus");

-- Step 5: Drop old enum if exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'VerificationStatus_old') THEN
    DROP TYPE "VerificationStatus_old";
  END IF;
END $$;

-- Step 6: Restore default (optional but recommended)
ALTER TABLE "User"
  ALTER COLUMN "verificationStatus" SET DEFAULT 'PENDING';

ALTER TABLE "IdVerificationRequest"
  ALTER COLUMN "status" SET DEFAULT 'PENDING';
