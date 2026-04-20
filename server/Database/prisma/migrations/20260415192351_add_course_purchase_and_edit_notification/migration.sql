-- Add course purchase tables and update notification/community schema

ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'EVENT';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'COMMUNITY';

ALTER TABLE "Notification"
  ADD COLUMN IF NOT EXISTS "title" TEXT NOT NULL DEFAULT '';

ALTER TABLE "Notification"
  ADD COLUMN IF NOT EXISTS "body" TEXT NOT NULL DEFAULT '';

ALTER TABLE "Notification"
  ADD COLUMN IF NOT EXISTS "data" JSONB;

ALTER TABLE "Notification"
  ADD COLUMN IF NOT EXISTS "isDelivered" BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE "Community" DROP COLUMN IF EXISTS "type";
ALTER TABLE "CommunityMember" DROP COLUMN IF EXISTS "status";

CREATE TABLE IF NOT EXISTS "Course" (
  "id" TEXT NOT NULL,
  "title" TEXT NOT NULL,
  "description" TEXT NOT NULL,
  "videoId" TEXT NOT NULL,
  "price" DOUBLE PRECISION NOT NULL,
  "expertId" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "Course_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "SavedCourse" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "courseId" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "SavedCourse_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "Purchase" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "courseId" TEXT NOT NULL,
  "paid" BOOLEAN NOT NULL DEFAULT false,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Purchase_pkey" PRIMARY KEY ("id")
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'Course_expertId_fkey'
  ) THEN
    ALTER TABLE "Course"
      ADD CONSTRAINT "Course_expertId_fkey"
      FOREIGN KEY ("expertId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'SavedCourse_userId_fkey'
  ) THEN
    ALTER TABLE "SavedCourse"
      ADD CONSTRAINT "SavedCourse_userId_fkey"
      FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'SavedCourse_courseId_fkey'
  ) THEN
    ALTER TABLE "SavedCourse"
      ADD CONSTRAINT "SavedCourse_courseId_fkey"
      FOREIGN KEY ("courseId") REFERENCES "Course"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'Purchase_userId_fkey'
  ) THEN
    ALTER TABLE "Purchase"
      ADD CONSTRAINT "Purchase_userId_fkey"
      FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'Purchase_courseId_fkey'
  ) THEN
    ALTER TABLE "Purchase"
      ADD CONSTRAINT "Purchase_courseId_fkey"
      FOREIGN KEY ("courseId") REFERENCES "Course"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS "Course_expertId_idx" ON "Course"("expertId");
CREATE INDEX IF NOT EXISTS "SavedCourse_userId_idx" ON "SavedCourse"("userId");
CREATE INDEX IF NOT EXISTS "SavedCourse_courseId_idx" ON "SavedCourse"("courseId");
CREATE UNIQUE INDEX IF NOT EXISTS "SavedCourse_userId_courseId_key" ON "SavedCourse"("userId", "courseId");
CREATE INDEX IF NOT EXISTS "Purchase_userId_idx" ON "Purchase"("userId");
CREATE INDEX IF NOT EXISTS "Purchase_courseId_idx" ON "Purchase"("courseId");
CREATE UNIQUE INDEX IF NOT EXISTS "Purchase_userId_courseId_key" ON "Purchase"("userId", "courseId");
