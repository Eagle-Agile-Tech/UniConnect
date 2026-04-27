SET search_path TO public;

-- Ensure network fields exist on UserProfile (safe if already present)
ALTER TABLE "UserProfile" ADD COLUMN IF NOT EXISTS "networkCount" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "UserProfile" ADD COLUMN IF NOT EXISTS "isNetworkedBy" BOOLEAN NOT NULL DEFAULT false;
