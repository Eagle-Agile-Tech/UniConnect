-- Create the course purchase tables if they do not already exist.
-- Some environments already have "Course" from an earlier manual or baseline state,
-- so this migration is written to be safe when re-run against that schema.

CREATE TABLE IF NOT EXISTS "Course" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "videoId" TEXT NOT NULL,
    "price" INTEGER NOT NULL,
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

CREATE INDEX IF NOT EXISTS "Course_expertId_idx" ON "Course"("expertId");

CREATE INDEX IF NOT EXISTS "SavedCourse_userId_idx" ON "SavedCourse"("userId");
CREATE INDEX IF NOT EXISTS "SavedCourse_courseId_idx" ON "SavedCourse"("courseId");
CREATE UNIQUE INDEX IF NOT EXISTS "SavedCourse_userId_courseId_key" ON "SavedCourse"("userId", "courseId");

CREATE INDEX IF NOT EXISTS "Purchase_userId_idx" ON "Purchase"("userId");
CREATE INDEX IF NOT EXISTS "Purchase_courseId_idx" ON "Purchase"("courseId");
CREATE UNIQUE INDEX IF NOT EXISTS "Purchase_userId_courseId_key" ON "Purchase"("userId", "courseId");

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'Course_expertId_fkey'
  ) THEN
    ALTER TABLE "Course"
      ADD CONSTRAINT "Course_expertId_fkey"
      FOREIGN KEY ("expertId") REFERENCES "User"("id")
      ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'SavedCourse_userId_fkey'
  ) THEN
    ALTER TABLE "SavedCourse"
      ADD CONSTRAINT "SavedCourse_userId_fkey"
      FOREIGN KEY ("userId") REFERENCES "User"("id")
      ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'SavedCourse_courseId_fkey'
  ) THEN
    ALTER TABLE "SavedCourse"
      ADD CONSTRAINT "SavedCourse_courseId_fkey"
      FOREIGN KEY ("courseId") REFERENCES "Course"("id")
      ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'Purchase_userId_fkey'
  ) THEN
    ALTER TABLE "Purchase"
      ADD CONSTRAINT "Purchase_userId_fkey"
      FOREIGN KEY ("userId") REFERENCES "User"("id")
      ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'Purchase_courseId_fkey'
  ) THEN
    ALTER TABLE "Purchase"
      ADD CONSTRAINT "Purchase_courseId_fkey"
      FOREIGN KEY ("courseId") REFERENCES "Course"("id")
      ON DELETE RESTRICT ON UPDATE CASCADE;
  END IF;
END $$;
