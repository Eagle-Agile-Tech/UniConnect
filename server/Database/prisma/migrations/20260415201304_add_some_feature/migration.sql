/*
  Warnings:

  - You are about to drop the column `type` on the `Community` table. All the data in the column will be lost.
  - You are about to drop the column `status` on the `CommunityMember` table. All the data in the column will be lost.
  - You are about to drop the column `isVerified` on the `Institution` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[userId]` on the table `Institution` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[secretCode]` on the table `Institution` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[profileUserId]` on the table `Institution` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[senderId,clientMessageId]` on the table `Message` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `type` to the `Institution` table without a default value. This is not possible if the table is not empty.

*/
-- CreateEnum
DO $$
BEGIN
  CREATE TYPE "InstitutionVerificationStatus" AS ENUM ('PENDING', 'UNVERIFIED', 'VERIFIED', 'REJECTED');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- CreateEnum
DO $$
BEGIN
  CREATE TYPE "InstitutionType" AS ENUM ('UNIVERSITY', 'COMPANY', 'NGO', 'RESEARCH_CENTER', 'TRAINING_CENTER', 'GOVERNMENT', 'OTHER');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- AlterTable
ALTER TABLE "Chat" ADD COLUMN IF NOT EXISTS "avatarUrl" TEXT,
ADD COLUMN IF NOT EXISTS "createdById" TEXT,
ADD COLUMN IF NOT EXISTS "name" TEXT;

-- AlterTable
ALTER TABLE "Community" DROP COLUMN IF EXISTS "type";

-- AlterTable
ALTER TABLE "CommunityMember" DROP COLUMN IF EXISTS "status";

-- AlterTable
ALTER TABLE "Institution" DROP COLUMN IF EXISTS "isVerified",
ADD COLUMN     "profileUserId" TEXT,
ADD COLUMN     "secretCode" TEXT,
ADD COLUMN     "secretCodeExpiresAt" TIMESTAMP(3),
ADD COLUMN     "type" "InstitutionType" NOT NULL DEFAULT 'OTHER',
ADD COLUMN     "userId" TEXT,
ADD COLUMN     "verificationStatus" "InstitutionVerificationStatus" NOT NULL DEFAULT 'UNVERIFIED',
ADD COLUMN     "verifiedAt" TIMESTAMP(3),
ADD COLUMN     "verifiedById" TEXT;

-- AlterTable
ALTER TABLE "Message" ADD COLUMN     "clientMessageId" TEXT;

-- AlterTable
ALTER TABLE "Notification" ALTER COLUMN "title" DROP DEFAULT,
ALTER COLUMN "body" DROP DEFAULT;

-- AlterTable
ALTER TABLE "UserProfile" ADD COLUMN     "fullName" TEXT;

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

-- CreateTable
CREATE TABLE "MessageReceipt" (
    "id" TEXT NOT NULL,
    "messageId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "deliveredAt" TIMESTAMP(3),
    "readAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "MessageReceipt_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "InstitutionVerificationRequest_institutionId_idx" ON "InstitutionVerificationRequest"("institutionId");

-- CreateIndex
CREATE INDEX "InstitutionVerificationRequest_status_idx" ON "InstitutionVerificationRequest"("status");

-- CreateIndex
CREATE INDEX "InstitutionVerificationRequest_reviewedById_idx" ON "InstitutionVerificationRequest"("reviewedById");

-- CreateIndex
CREATE INDEX "MessageReceipt_userId_idx" ON "MessageReceipt"("userId");

-- CreateIndex
CREATE INDEX "MessageReceipt_messageId_idx" ON "MessageReceipt"("messageId");

-- CreateIndex
CREATE UNIQUE INDEX "MessageReceipt_messageId_userId_key" ON "MessageReceipt"("messageId", "userId");

-- CreateIndex
CREATE INDEX "ExpertInvitation_institutionId_idx" ON "ExpertInvitation"("institutionId");

-- CreateIndex
CREATE UNIQUE INDEX "Institution_userId_key" ON "Institution"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "Institution_secretCode_key" ON "Institution"("secretCode");

-- CreateIndex
CREATE UNIQUE INDEX "Institution_profileUserId_key" ON "Institution"("profileUserId");

-- CreateIndex
CREATE INDEX "Institution_verifiedById_idx" ON "Institution"("verifiedById");

-- CreateIndex
CREATE UNIQUE INDEX "Message_senderId_clientMessageId_key" ON "Message"("senderId", "clientMessageId");

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

-- AddForeignKey
ALTER TABLE "MessageReceipt" ADD CONSTRAINT "MessageReceipt_messageId_fkey" FOREIGN KEY ("messageId") REFERENCES "Message"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MessageReceipt" ADD CONSTRAINT "MessageReceipt_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
