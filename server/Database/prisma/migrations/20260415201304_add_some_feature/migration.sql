-- Restore the Institution/Chat/Message schema pieces that were removed in an
-- earlier migration, while keeping the migration safe for databases that have
-- already partially evolved.

DROP TYPE IF EXISTS "InstitutionVerificationStatus";
CREATE TYPE "InstitutionVerificationStatus" AS ENUM ('PENDING', 'UNVERIFIED', 'VERIFIED', 'REJECTED');

DROP TYPE IF EXISTS "InstitutionType";
CREATE TYPE "InstitutionType" AS ENUM ('UNIVERSITY', 'COMPANY', 'NGO', 'RESEARCH_CENTER', 'TRAINING_CENTER', 'GOVERNMENT', 'OTHER');

ALTER TABLE "Chat"
  ADD COLUMN IF NOT EXISTS "avatarUrl" TEXT,
  ADD COLUMN IF NOT EXISTS "createdById" TEXT,
  ADD COLUMN IF NOT EXISTS "name" TEXT;

ALTER TABLE "Community" DROP COLUMN IF EXISTS "type";
ALTER TABLE "CommunityMember" DROP COLUMN IF EXISTS "status";

ALTER TABLE "Institution"
  ADD COLUMN IF NOT EXISTS "profileUserId" TEXT,
  ADD COLUMN IF NOT EXISTS "secretCode" TEXT,
  ADD COLUMN IF NOT EXISTS "secretCodeExpiresAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "type" "InstitutionType",
  ADD COLUMN IF NOT EXISTS "userId" TEXT,
  ADD COLUMN IF NOT EXISTS "verificationStatus" "InstitutionVerificationStatus" NOT NULL DEFAULT 'UNVERIFIED',
  ADD COLUMN IF NOT EXISTS "verifiedAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "verifiedById" TEXT;

UPDATE "Institution"
SET "type" = 'OTHER'
WHERE "type" IS NULL;

UPDATE "Institution"
SET "verificationStatus" = CASE
  WHEN COALESCE("isVerified", false) THEN 'VERIFIED'::"InstitutionVerificationStatus"
  ELSE 'UNVERIFIED'::"InstitutionVerificationStatus"
END
WHERE "verificationStatus" IS NULL
   OR "verificationStatus" = 'UNVERIFIED';

ALTER TABLE "Institution"
  ALTER COLUMN "type" SET NOT NULL;

ALTER TABLE "Institution" DROP COLUMN IF EXISTS "isVerified";

ALTER TABLE "Message"
  ADD COLUMN IF NOT EXISTS "clientMessageId" TEXT;

ALTER TABLE "Notification"
  ALTER COLUMN "title" DROP DEFAULT,
  ALTER COLUMN "body" DROP DEFAULT;

ALTER TABLE "UserProfile"
  ADD COLUMN IF NOT EXISTS "fullName" TEXT;

CREATE TABLE IF NOT EXISTS "InstitutionVerificationRequest" (
    "id" TEXT NOT NULL,
    "institutionId" TEXT NOT NULL,
    "documentUrl" TEXT NOT NULL,
    "status" "ModerationStatus" NOT NULL DEFAULT 'PENDING',
    "reviewedById" TEXT,
    "reviewedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "InstitutionVerificationRequest_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "MessageReceipt" (
    "id" TEXT NOT NULL,
    "messageId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "deliveredAt" TIMESTAMP(3),
    "readAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "MessageReceipt_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "InstitutionVerificationRequest_institutionId_idx" ON "InstitutionVerificationRequest"("institutionId");
CREATE INDEX IF NOT EXISTS "InstitutionVerificationRequest_status_idx" ON "InstitutionVerificationRequest"("status");
CREATE INDEX IF NOT EXISTS "InstitutionVerificationRequest_reviewedById_idx" ON "InstitutionVerificationRequest"("reviewedById");
CREATE INDEX IF NOT EXISTS "MessageReceipt_userId_idx" ON "MessageReceipt"("userId");
CREATE INDEX IF NOT EXISTS "MessageReceipt_messageId_idx" ON "MessageReceipt"("messageId");
CREATE UNIQUE INDEX IF NOT EXISTS "MessageReceipt_messageId_userId_key" ON "MessageReceipt"("messageId", "userId");
CREATE INDEX IF NOT EXISTS "ExpertInvitation_institutionId_idx" ON "ExpertInvitation"("institutionId");

CREATE UNIQUE INDEX IF NOT EXISTS "Institution_userId_key" ON "Institution"("userId");
CREATE UNIQUE INDEX IF NOT EXISTS "Institution_secretCode_key" ON "Institution"("secretCode");
CREATE UNIQUE INDEX IF NOT EXISTS "Institution_profileUserId_key" ON "Institution"("profileUserId");
CREATE INDEX IF NOT EXISTS "Institution_verifiedById_idx" ON "Institution"("verifiedById");
CREATE UNIQUE INDEX IF NOT EXISTS "Message_senderId_clientMessageId_key" ON "Message"("senderId", "clientMessageId");

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'Institution_userId_fkey'
  ) THEN
    ALTER TABLE "Institution"
      ADD CONSTRAINT "Institution_userId_fkey"
      FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'Institution_verifiedById_fkey'
  ) THEN
    ALTER TABLE "Institution"
      ADD CONSTRAINT "Institution_verifiedById_fkey"
      FOREIGN KEY ("verifiedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'Institution_profileUserId_fkey'
  ) THEN
    ALTER TABLE "Institution"
      ADD CONSTRAINT "Institution_profileUserId_fkey"
      FOREIGN KEY ("profileUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'InstitutionVerificationRequest_institutionId_fkey'
  ) THEN
    ALTER TABLE "InstitutionVerificationRequest"
      ADD CONSTRAINT "InstitutionVerificationRequest_institutionId_fkey"
      FOREIGN KEY ("institutionId") REFERENCES "Institution"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'InstitutionVerificationRequest_reviewedById_fkey'
  ) THEN
    ALTER TABLE "InstitutionVerificationRequest"
      ADD CONSTRAINT "InstitutionVerificationRequest_reviewedById_fkey"
      FOREIGN KEY ("reviewedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'ExpertInvitation_institutionId_fkey'
  ) THEN
    ALTER TABLE "ExpertInvitation"
      ADD CONSTRAINT "ExpertInvitation_institutionId_fkey"
      FOREIGN KEY ("institutionId") REFERENCES "Institution"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'MessageReceipt_messageId_fkey'
  ) THEN
    ALTER TABLE "MessageReceipt"
      ADD CONSTRAINT "MessageReceipt_messageId_fkey"
      FOREIGN KEY ("messageId") REFERENCES "Message"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'MessageReceipt_userId_fkey'
  ) THEN
    ALTER TABLE "MessageReceipt"
      ADD CONSTRAINT "MessageReceipt_userId_fkey"
      FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
END $$;
