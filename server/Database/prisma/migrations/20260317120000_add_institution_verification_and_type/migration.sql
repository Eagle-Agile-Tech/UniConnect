-- CreateEnum
CREATE TYPE "InstitutionVerificationStatus" AS ENUM ('PENDING', 'UNVERIFIED', 'VERIFIED', 'REJECTED');

-- CreateEnum
CREATE TYPE "InstitutionType" AS ENUM ('UNIVERSITY', 'COMPANY', 'NGO', 'RESEARCH_CENTER', 'TRAINING_CENTER', 'GOVERNMENT', 'OTHER');

-- AlterTable
ALTER TABLE "Institution"
ADD COLUMN     "type" "InstitutionType",
ADD COLUMN     "verificationStatus" "InstitutionVerificationStatus" NOT NULL DEFAULT 'UNVERIFIED',
ADD COLUMN     "userId" TEXT,
ADD COLUMN     "secretCode" TEXT,
ADD COLUMN     "secretCodeExpiresAt" TIMESTAMP(3),
ADD COLUMN     "verifiedAt" TIMESTAMP(3),
ADD COLUMN     "verifiedById" TEXT,
ADD COLUMN     "profileUserId" TEXT;

-- Backfill required fields
UPDATE "Institution"
SET "type" = 'OTHER'
WHERE "type" IS NULL;

UPDATE "Institution"
SET "verificationStatus" = CASE
  WHEN "isVerified" THEN 'VERIFIED'::"InstitutionVerificationStatus"
  ELSE 'UNVERIFIED'::"InstitutionVerificationStatus"
END;

-- Enforce NOT NULL for required field
ALTER TABLE "Institution" ALTER COLUMN "type" SET NOT NULL;

-- Drop obsolete column
ALTER TABLE "Institution" DROP COLUMN "isVerified";

-- CreateTable
CREATE TABLE "InstitutionVerificationRequest" (
    "id" TEXT NOT NULL,
    "institutionId" TEXT NOT NULL,
    "documentUrl" TEXT NOT NULL,
    "status" "ModerationStatus" NOT NULL DEFAULT 'PENDING',
    "reviewedById" TEXT,
    "reviewedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "InstitutionVerificationRequest_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Institution_userId_key" ON "Institution"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "Institution_secretCode_key" ON "Institution"("secretCode");

-- CreateIndex
CREATE UNIQUE INDEX "Institution_profileUserId_key" ON "Institution"("profileUserId");

-- CreateIndex
CREATE INDEX "Institution_verifiedById_idx" ON "Institution"("verifiedById");

-- CreateIndex
CREATE INDEX "InstitutionVerificationRequest_institutionId_idx" ON "InstitutionVerificationRequest"("institutionId");

-- CreateIndex
CREATE INDEX "InstitutionVerificationRequest_status_idx" ON "InstitutionVerificationRequest"("status");

-- CreateIndex
CREATE INDEX "InstitutionVerificationRequest_reviewedById_idx" ON "InstitutionVerificationRequest"("reviewedById");

-- CreateIndex
CREATE INDEX "ExpertInvitation_institutionId_idx" ON "ExpertInvitation"("institutionId");

-- AddForeignKey
ALTER TABLE "Institution" ADD CONSTRAINT "Institution_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Institution" ADD CONSTRAINT "Institution_verifiedById_fkey" FOREIGN KEY ("verifiedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Institution" ADD CONSTRAINT "Institution_profileUserId_fkey" FOREIGN KEY ("profileUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InstitutionVerificationRequest" ADD CONSTRAINT "InstitutionVerificationRequest_institutionId_fkey" FOREIGN KEY ("institutionId") REFERENCES "Institution"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InstitutionVerificationRequest" ADD CONSTRAINT "InstitutionVerificationRequest_reviewedById_fkey" FOREIGN KEY ("reviewedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ExpertInvitation" ADD CONSTRAINT "ExpertInvitation_institutionId_fkey" FOREIGN KEY ("institutionId") REFERENCES "Institution"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
