/*
  Warnings:

  - You are about to drop the column `affiliatedInstitutionId` on the `ExpertProfile` table. All the data in the column will be lost.
  - You are about to drop the column `isVerified` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `username` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `firstName` on the `UserProfile` table. All the data in the column will be lost.
  - You are about to drop the column `lastName` on the `UserProfile` table. All the data in the column will be lost.
  - You are about to drop the column `university` on the `UserProfile` table. All the data in the column will be lost.
  - Added the required column `firstName` to the `User` table without a default value. This is not possible if the table is not empty.
  - Added the required column `lastName` to the `User` table without a default value. This is not possible if the table is not empty.

*/
-- CreateEnum
CREATE TYPE "VerificationStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'EMAIL_VERIFIED');

-- CreateEnum
CREATE TYPE "VerificationMethod" AS ENUM ('UNIVERSITY_EMAIL', 'ID_DOCUMENT_ADMIN');

-- DropForeignKey
ALTER TABLE "ExpertProfile" DROP CONSTRAINT "ExpertProfile_affiliatedInstitutionId_fkey";

-- DropForeignKey
ALTER TABLE "UserProfile" DROP CONSTRAINT "UserProfile_userId_fkey";

-- DropIndex
DROP INDEX "ExpertProfile_affiliatedInstitutionId_idx";

-- DropIndex
DROP INDEX "User_username_idx";

-- DropIndex
DROP INDEX "User_username_key";

-- AlterTable
ALTER TABLE "ExpertProfile" DROP COLUMN "affiliatedInstitutionId",
ADD COLUMN     "invitedByInstitutionId" TEXT;

-- AlterTable
ALTER TABLE "Institution" ADD COLUMN     "isVerified" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "verificationDocument" TEXT;

-- AlterTable
ALTER TABLE "User" DROP COLUMN "isVerified",
DROP COLUMN "username",
ADD COLUMN     "firstName" TEXT NOT NULL,
ADD COLUMN     "lastName" TEXT NOT NULL,
ADD COLUMN     "verificationMethod" "VerificationMethod",
ADD COLUMN     "verificationStatus" "VerificationStatus" NOT NULL DEFAULT 'PENDING';

-- AlterTable
ALTER TABLE "UserProfile" DROP COLUMN "firstName",
DROP COLUMN "lastName",
DROP COLUMN "university",
ADD COLUMN     "universityId" TEXT;

-- CreateTable
CREATE TABLE "University" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "domains" TEXT[],
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "University_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "IdVerificationRequest" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "documentImage" TEXT NOT NULL,
    "documentType" TEXT,
    "submittedNotes" TEXT,
    "status" "VerificationStatus" NOT NULL DEFAULT 'PENDING',
    "reviewedById" TEXT,
    "reviewedAt" TIMESTAMP(3),
    "adminComment" TEXT,
    "submittedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "IdVerificationRequest_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ExpertInvitation" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "institutionId" TEXT NOT NULL,
    "status" "MembershipStatus" NOT NULL DEFAULT 'PENDING',
    "token" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ExpertInvitation_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "IdVerificationRequest_userId_key" ON "IdVerificationRequest"("userId");

-- CreateIndex
CREATE INDEX "IdVerificationRequest_userId_idx" ON "IdVerificationRequest"("userId");

-- CreateIndex
CREATE INDEX "IdVerificationRequest_status_idx" ON "IdVerificationRequest"("status");

-- CreateIndex
CREATE INDEX "IdVerificationRequest_reviewedAt_idx" ON "IdVerificationRequest"("reviewedAt");

-- CreateIndex
CREATE UNIQUE INDEX "ExpertInvitation_token_key" ON "ExpertInvitation"("token");

-- CreateIndex
CREATE INDEX "ExpertProfile_invitedByInstitutionId_idx" ON "ExpertProfile"("invitedByInstitutionId");

-- CreateIndex
CREATE INDEX "User_verificationStatus_idx" ON "User"("verificationStatus");

-- CreateIndex
CREATE INDEX "UserProfile_universityId_idx" ON "UserProfile"("universityId");

-- AddForeignKey
ALTER TABLE "UserProfile" ADD CONSTRAINT "UserProfile_universityId_fkey" FOREIGN KEY ("universityId") REFERENCES "University"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserProfile" ADD CONSTRAINT "UserProfile_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "IdVerificationRequest" ADD CONSTRAINT "IdVerificationRequest_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "IdVerificationRequest" ADD CONSTRAINT "IdVerificationRequest_reviewedById_fkey" FOREIGN KEY ("reviewedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ExpertProfile" ADD CONSTRAINT "ExpertProfile_invitedByInstitutionId_fkey" FOREIGN KEY ("invitedByInstitutionId") REFERENCES "Institution"("id") ON DELETE SET NULL ON UPDATE CASCADE;
