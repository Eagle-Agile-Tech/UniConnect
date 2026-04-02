-- Add missing chat metadata columns
ALTER TABLE "Chat" ADD COLUMN "name" TEXT;
ALTER TABLE "Chat" ADD COLUMN "avatarUrl" TEXT;
ALTER TABLE "Chat" ADD COLUMN "createdById" TEXT;
