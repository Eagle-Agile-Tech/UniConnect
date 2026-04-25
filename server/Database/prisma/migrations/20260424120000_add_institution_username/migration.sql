-- Add mandatory username to Institution and backfill existing rows.
ALTER TABLE "Institution"
ADD COLUMN IF NOT EXISTS "username" TEXT;

UPDATE "Institution"
SET "username" = COALESCE(
  NULLIF(lower(regexp_replace("name", '[^a-zA-Z0-9._-]+', '', 'g')), ''),
  'institution'
) || '-' || substr("id", 1, 8)
WHERE "username" IS NULL;

ALTER TABLE "Institution"
ALTER COLUMN "username" SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS "Institution_username_key"
ON "Institution"("username");
