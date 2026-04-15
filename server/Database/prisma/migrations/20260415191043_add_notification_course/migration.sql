-- Add missing notification fields, notification enum values, and course tables

ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'EVENT';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'COMMUNITY';

ALTER TABLE "Notification"
  ADD COLUMN "title" TEXT NOT NULL DEFAULT '';

ALTER TABLE "Notification"
  ADD COLUMN "body" TEXT NOT NULL DEFAULT '';

ALTER TABLE "Notification"
  ADD COLUMN "data" JSONB;

ALTER TABLE "Notification"
  ADD COLUMN "isDelivered" BOOLEAN NOT NULL DEFAULT false;

CREATE TABLE "Course" (
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

CREATE TABLE "SavedCourse" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "courseId" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "SavedCourse_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "Purchase" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "courseId" TEXT NOT NULL,
  "paid" BOOLEAN NOT NULL DEFAULT false,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Purchase_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "Course"
  ADD CONSTRAINT "Course_expertId_fkey" FOREIGN KEY ("expertId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "SavedCourse"
  ADD CONSTRAINT "SavedCourse_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "SavedCourse"
  ADD CONSTRAINT "SavedCourse_courseId_fkey" FOREIGN KEY ("courseId") REFERENCES "Course"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "Purchase"
  ADD CONSTRAINT "Purchase_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "Purchase"
  ADD CONSTRAINT "Purchase_courseId_fkey" FOREIGN KEY ("courseId") REFERENCES "Course"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

CREATE INDEX "Course_expertId_idx" ON "Course"("expertId");
CREATE INDEX "SavedCourse_userId_idx" ON "SavedCourse"("userId");
CREATE INDEX "SavedCourse_courseId_idx" ON "SavedCourse"("courseId");
CREATE UNIQUE INDEX "SavedCourse_userId_courseId_key" ON "SavedCourse"("userId", "courseId");
CREATE INDEX "Purchase_userId_idx" ON "Purchase"("userId");
CREATE INDEX "Purchase_courseId_idx" ON "Purchase"("courseId");
CREATE UNIQUE INDEX "Purchase_userId_courseId_key" ON "Purchase"("userId", "courseId");
