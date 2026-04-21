/*
  Warnings:

  - You are about to drop the column `status` on the `Network` table. All the data in the column will be lost.
  - You are about to drop the column `updatedAt` on the `Network` table. All the data in the column will be lost.

*/
-- DropIndex
DROP INDEX "Network_userAId_status_idx";

-- DropIndex
DROP INDEX "Network_userBId_status_idx";

-- AlterTable
ALTER TABLE "Network" DROP COLUMN "status",
DROP COLUMN "updatedAt";

-- CreateTable
CREATE TABLE "NetworkRequest" (
    "id" TEXT NOT NULL,
    "senderId" TEXT NOT NULL,
    "receiverId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "NetworkRequest_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "NetworkRequest_receiverId_idx" ON "NetworkRequest"("receiverId");

-- CreateIndex
CREATE INDEX "NetworkRequest_senderId_idx" ON "NetworkRequest"("senderId");

-- CreateIndex
CREATE UNIQUE INDEX "NetworkRequest_senderId_receiverId_key" ON "NetworkRequest"("senderId", "receiverId");

-- CreateIndex
CREATE INDEX "Network_userAId_idx" ON "Network"("userAId");

-- CreateIndex
CREATE INDEX "Network_userBId_idx" ON "Network"("userBId");

-- AddForeignKey
ALTER TABLE "NetworkRequest" ADD CONSTRAINT "NetworkRequest_senderId_fkey" FOREIGN KEY ("senderId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "NetworkRequest" ADD CONSTRAINT "NetworkRequest_receiverId_fkey" FOREIGN KEY ("receiverId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
