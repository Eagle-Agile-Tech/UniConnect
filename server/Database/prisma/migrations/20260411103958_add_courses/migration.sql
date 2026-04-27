/*
  Warnings:

  - You are about to drop the column `avatarUrl` on the `Chat` table. All the data in the column will be lost.
  - You are about to drop the column `createdById` on the `Chat` table. All the data in the column will be lost.
  - You are about to drop the column `name` on the `Chat` table. All the data in the column will be lost.
  - You are about to drop the column `profileUserId` on the `Institution` table. All the data in the column will be lost.
  - You are about to drop the column `secretCode` on the `Institution` table. All the data in the column will be lost.
  - You are about to drop the column `secretCodeExpiresAt` on the `Institution` table. All the data in the column will be lost.
  - You are about to drop the column `type` on the `Institution` table. All the data in the column will be lost.
  - You are about to drop the column `userId` on the `Institution` table. All the data in the column will be lost.
  - You are about to drop the column `verificationStatus` on the `Institution` table. All the data in the column will be lost.
  - You are about to drop the column `verifiedAt` on the `Institution` table. All the data in the column will be lost.
  - You are about to drop the column `verifiedById` on the `Institution` table. All the data in the column will be lost.
  - You are about to drop the column `clientMessageId` on the `Message` table. All the data in the column will be lost.
  - You are about to drop the column `fullName` on the `UserProfile` table. All the data in the column will be lost.
  - You are about to drop the `InstitutionVerificationRequest` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `MessageReceipt` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "ExpertInvitation" DROP CONSTRAINT "ExpertInvitation_institutionId_fkey";

-- DropForeignKey
ALTER TABLE "Institution" DROP CONSTRAINT "Institution_profileUserId_fkey";

-- DropForeignKey
ALTER TABLE "Institution" DROP CONSTRAINT "Institution_userId_fkey";

-- DropForeignKey
ALTER TABLE "Institution" DROP CONSTRAINT "Institution_verifiedById_fkey";

-- DropForeignKey
ALTER TABLE "InstitutionVerificationRequest" DROP CONSTRAINT "InstitutionVerificationRequest_institutionId_fkey";

-- DropForeignKey
ALTER TABLE "InstitutionVerificationRequest" DROP CONSTRAINT "InstitutionVerificationRequest_reviewedById_fkey";

-- DropForeignKey
ALTER TABLE "MessageReceipt" DROP CONSTRAINT "MessageReceipt_messageId_fkey";

-- DropForeignKey
ALTER TABLE "MessageReceipt" DROP CONSTRAINT "MessageReceipt_userId_fkey";

-- DropIndex
DROP INDEX "ExpertInvitation_institutionId_idx";

-- DropIndex
DROP INDEX "Institution_profileUserId_key";

-- DropIndex
DROP INDEX "Institution_secretCode_key";

-- DropIndex
DROP INDEX "Institution_userId_key";

-- DropIndex
DROP INDEX "Institution_verifiedById_idx";

-- DropIndex
DROP INDEX "Message_senderId_clientMessageId_key";

-- AlterTable
ALTER TABLE "Chat" DROP COLUMN "avatarUrl",
DROP COLUMN "createdById",
DROP COLUMN "name";

-- AlterTable
ALTER TABLE "Institution" DROP COLUMN "profileUserId",
DROP COLUMN "secretCode",
DROP COLUMN "secretCodeExpiresAt",
DROP COLUMN "type",
DROP COLUMN "userId",
DROP COLUMN "verificationStatus",
DROP COLUMN "verifiedAt",
DROP COLUMN "verifiedById",
ADD COLUMN     "isVerified" BOOLEAN NOT NULL DEFAULT false;

-- AlterTable
ALTER TABLE "Message" DROP COLUMN "clientMessageId";

-- AlterTable
ALTER TABLE "Post" ALTER COLUMN "embedding" DROP NOT NULL;

-- AlterTable
ALTER TABLE "UserProfile" DROP COLUMN "fullName";

-- DropTable
DROP TABLE "InstitutionVerificationRequest";

-- DropTable
DROP TABLE "MessageReceipt";

-- DropEnum
DROP TYPE "InstitutionType";

-- DropEnum
DROP TYPE "InstitutionVerificationStatus";
