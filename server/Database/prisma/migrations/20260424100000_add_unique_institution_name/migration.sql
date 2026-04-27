-- Add unique constraint for institution names
-- This keeps the database in sync with the Prisma schema and service-level checks.
CREATE UNIQUE INDEX "Institution_name_key" ON "Institution"("name");
