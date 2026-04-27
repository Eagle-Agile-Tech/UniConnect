-- Add missing notification fields and enum values.
-- Course/SavedCourse/Purchase are already created by 20260411104732_courses,
-- so this migration only adjusts Course.price type.

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

ALTER TABLE "Course"
  ALTER COLUMN "price" TYPE DOUBLE PRECISION USING "price"::DOUBLE PRECISION;
