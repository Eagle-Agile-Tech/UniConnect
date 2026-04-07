-- Add username column to UserProfile and backfill (idempotent)
ALTER TABLE "UserProfile" ADD COLUMN IF NOT EXISTS "username" TEXT;

UPDATE "UserProfile"
SET "username" = 'user_' || substr("id", 1, 8)
WHERE "username" IS NULL;

ALTER TABLE "UserProfile" ALTER COLUMN "username" SET NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS "UserProfile_username_key" ON "UserProfile"("username");

-- Remove GROUP from Visibility enum (ensure existing rows are remapped)
UPDATE "Post" SET "visibility" = 'PUBLIC' WHERE "visibility"::text = 'GROUP';

ALTER TABLE "Post" ALTER COLUMN "visibility" DROP DEFAULT;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_enum e
    JOIN pg_type t ON t.oid = e.enumtypid
    WHERE t.typname = 'Visibility' AND e.enumlabel = 'GROUP'
  ) THEN
    ALTER TYPE "Visibility" RENAME TO "Visibility_old";
    CREATE TYPE "Visibility" AS ENUM ('PUBLIC', 'PRIVATE');
    ALTER TABLE "Post" ALTER COLUMN "visibility" TYPE "Visibility" USING ("visibility"::text::"Visibility");
    ALTER TABLE "Post" ALTER COLUMN "visibility" SET DEFAULT 'PUBLIC';
    DROP TYPE "Visibility_old";
  ELSE
    -- Ensure default remains consistent even if the enum already matches
    ALTER TABLE "Post" ALTER COLUMN "visibility" SET DEFAULT 'PUBLIC';
  END IF;
END $$;
